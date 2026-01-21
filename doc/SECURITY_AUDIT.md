# Security Audit Report

**Date:** January 2026
**Scope:** Full codebase security and performance review
**Tool Version:** 1.0.1

## Executive Summary

This audit identified several security considerations in the Firebase Analytics Monitor codebase. While the tool operates in a relatively trusted environment (local CLI with user-initiated commands), some areas require attention to prevent potential abuse scenarios.

**Risk Level:** Low-Medium (CLI tool with local-only scope)

### Key Findings

| ID | Finding | Severity | Status |
|----|---------|----------|--------|
| SEC-001 | Command injection via package name | Medium | Open |
| SEC-002 | Path traversal partially mitigated | Low | Partial |
| SEC-003 | Unbounded JSON import | Medium | Open |
| SEC-004 | ReDoS in search patterns | Low | Mitigated |
| SEC-005 | Log injection from logcat | Low | Accepted Risk |
| SEC-006 | Memory exhaustion via large imports | Medium | Open |

---

## Detailed Findings

### SEC-001: Command Injection via Package Name

**Location:** `lib/src/services/log_source_factory.dart:156-162`

**Description:**
The `enableAnalyticsDebug()` method passes user-supplied package names directly to `adb shell setprop` without validation. While the Dart `ProcessManager.start()` uses argument arrays (avoiding shell interpretation), specially crafted package names could still cause issues.

**Code:**
```dart
final proc = await _processManager.start([
  'adb',
  'shell',
  'setprop',
  'debug.firebase.analytics.app',
  bundleIdOrPackage,  // User input, not validated
]);
```

**Risk:** Low-Medium
- Dart's `Process.start()` with argument list prevents shell metacharacter injection
- However, malformed package names could cause unexpected behavior
- Future refactoring might introduce shell interpolation

**Recommendation:**
```dart
static final _validPackageNamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]*$');

Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
  if (bundleIdOrPackage == null || bundleIdOrPackage.isEmpty) return;

  // Validate Android package name format
  if (bundleIdOrPackage.length > 256 ||
      !_validPackageNamePattern.hasMatch(bundleIdOrPackage)) {
    _logger.warn('Invalid package name format: $bundleIdOrPackage');
    return;
  }

  // Proceed with validated input
  ...
}
```

---

### SEC-002: Path Traversal Partially Mitigated

**Location:** `lib/src/cli/commands/database_command.dart:15-45`

**Description:**
The `_validateFilePath()` and `_validateDirectoryPath()` functions provide good basic protection:
- Null byte detection
- Path canonicalization via `p.canonicalize()`
- File existence checks

**Current Protection:**
```dart
String? _validateFilePath(String? filePath, {bool mustExist = false}) {
  if (filePath == null || filePath.isEmpty) return null;
  final canonicalPath = p.canonicalize(filePath);
  if (filePath.contains('\x00')) return null;
  if (mustExist && !File(canonicalPath).existsSync()) return null;
  return canonicalPath;
}
```

**Gaps:**
1. Symlink attacks not handled - canonical path may resolve through symlinks to unexpected locations
2. No directory containment check - user could specify paths outside expected directories

**Risk:** Low (CLI tool runs with user's permissions)

**Recommendation:**
```dart
String? _validateFilePath(String? filePath, {
  bool mustExist = false,
  String? containingDirectory,
}) {
  if (filePath == null || filePath.isEmpty) return null;
  if (filePath.contains('\x00')) return null;

  final canonicalPath = p.canonicalize(filePath);

  // Resolve symlinks for sensitive operations
  if (mustExist) {
    final file = File(canonicalPath);
    if (!file.existsSync()) return null;

    try {
      final resolvedPath = file.resolveSymbolicLinksSync();

      // Verify path stays within expected directory
      if (containingDirectory != null) {
        final resolvedDir = p.canonicalize(containingDirectory);
        if (!p.isWithin(resolvedDir, resolvedPath)) {
          return null; // Path escapes containment
        }
      }

      return resolvedPath;
    } on FileSystemException {
      return null;
    }
  }

  return canonicalPath;
}
```

---

### SEC-003: Unbounded JSON Import

**Location:**
- `lib/src/core/application/use_cases/import_data_use_case.dart`
- `lib/src/core/infrastructure/repositories/isar_data_export_repository.dart`

**Description:**
JSON import operations read entire files into memory without size limits or schema validation:

```dart
Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
  final file = File(filePath);
  final content = await file.readAsString();  // Entire file in memory
  final data = jsonDecode(content) as Map<String, dynamic>;  // No validation
  await _repository.importAllData(data, overwrite: overwrite);
}
```

**Risks:**
1. **Memory exhaustion:** Large malicious files could crash the application
2. **Malformed data:** No schema validation means corrupted data could be imported
3. **Type confusion:** Casting without validation could throw unexpected exceptions

**Risk:** Medium

**Recommendation:**
```dart
static const int maxImportFileSize = 100 * 1024 * 1024; // 100MB limit

Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
  final file = File(filePath);

  // Check file size before reading
  final fileSize = await file.length();
  if (fileSize > maxImportFileSize) {
    throw ArgumentError(
      'Import file too large: ${fileSize ~/ 1024 ~/ 1024}MB '
      '(max: ${maxImportFileSize ~/ 1024 ~/ 1024}MB)',
    );
  }

  final content = await file.readAsString();
  final data = jsonDecode(content);

  // Validate schema
  if (data is! Map<String, dynamic>) {
    throw FormatException('Invalid import file: expected JSON object');
  }

  if (!_validateImportSchema(data)) {
    throw FormatException('Invalid import file structure');
  }

  await _repository.importAllData(data, overwrite: overwrite);
}

bool _validateImportSchema(Map<String, dynamic> data) {
  // Required fields
  if (!data.containsKey('version')) return false;
  if (!data.containsKey('data')) return false;

  final dataSection = data['data'];
  if (dataSection is! Map<String, dynamic>) return false;

  // Validate events structure if present
  if (dataSection.containsKey('events')) {
    final events = dataSection['events'];
    if (events is! Map<String, dynamic>) return false;
    if (events['events'] is! List) return false;
  }

  return true;
}
```

---

### SEC-004: ReDoS in Search Patterns - MITIGATED

**Location:** `lib/src/services/event_cache_service.dart:124-165`

**Description:**
The `searchEvents()` method accepts user-provided regex patterns. This has been properly mitigated with:

1. Pattern length limit (100 characters)
2. Dangerous pattern detection (nested quantifiers, etc.)
3. Fallback to substring search for rejected patterns

**Current Protection:**
```dart
static const int _maxPatternLength = 100;
static final RegExp _dangerousPatternIndicators = RegExp(
  r'(\+\+|\*\*|\{\d+,\d*\}\{|\(\?\:.*\)\+|\(\?\:.*\)\*)',
);

List<String> searchEvents(String pattern) {
  if (pattern.length > _maxPatternLength) {
    return _substringSearch(pattern);
  }
  if (_dangerousPatternIndicators.hasMatch(pattern)) {
    return _substringSearch(pattern);
  }
  // ... proceed with regex
}
```

**Status:** Mitigated - No action required

---

### SEC-005: Log Injection from Logcat - Accepted Risk

**Location:** `lib/src/services/log_parser_service.dart`

**Description:**
Event names and parameter values parsed from logcat are stored as-is without sanitization. A malicious app on the monitored device could log specially crafted events.

**Risks:**
- If data is ever displayed in a web UI: potential XSS
- Log injection could create misleading audit trails
- Control characters could corrupt terminal output

**Risk:** Low (CLI-only display, limited attack surface)

**Mitigation Applied:**
- Terminal output handles control characters reasonably
- No web UI component
- Data is from user's own connected device

**Status:** Accepted Risk - Document limitation for users

**Future Consideration:**
If adding web UI or sharing features, sanitize stored data:
```dart
String _sanitizeForStorage(String value) {
  // Remove control characters except newline
  return value.replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'), '');
}
```

---

### SEC-006: Memory Exhaustion via Large Imports

**Location:** `lib/src/core/infrastructure/repositories/isar_data_export_repository.dart:144-165`

**Description:**
The `importEvents()` method processes all events in a single transaction, loading them all into memory:

```dart
await isar.writeTxn(() async {
  for (final eventData in eventsList) {  // All events iterated
    final event = AnalyticsEvent.fromJson(eventData as Map<String, dynamic>);
    final isarEvent = IsarAnalyticsEvent.fromDomain(event);
    await isar.isarAnalyticsEvents.put(isarEvent);
  }
});
```

**Risk:** Medium

**Recommendation:** Use chunked processing:
```dart
static const int _importChunkSize = 1000;

Future<void> importEvents(Map<String, dynamic> data, {bool overwrite = false}) async {
  final isar = await database.db;
  final eventsList = data['events'] as List<dynamic>?;
  if (eventsList == null) return;

  if (overwrite) {
    await isar.writeTxn(() => isar.isarAnalyticsEvents.clear());
  }

  // Process in chunks to bound memory usage
  for (var i = 0; i < eventsList.length; i += _importChunkSize) {
    final chunk = eventsList.skip(i).take(_importChunkSize);

    await isar.writeTxn(() async {
      for (final eventData in chunk) {
        final event = AnalyticsEvent.fromJson(eventData as Map<String, dynamic>);
        await isar.isarAnalyticsEvents.put(IsarAnalyticsEvent.fromDomain(event));
      }
    });
  }
}
```

---

## Performance-Related Security Issues

### PERF-001: Timer Resource Leaks

**Location:** `lib/src/commands/monitor_command.dart`

**Description:**
If an exception occurs during monitoring, timers may not be cancelled:

```dart
Timer? statsTimer;
if (showStats) {
  statsTimer = Timer.periodic(statsDisplayInterval, (_) => _showSessionStats());
}
// ... if exception thrown here, statsTimer is never cancelled
```

**Recommendation:** Use try-finally:
```dart
Timer? statsTimer;
Timer? suggestionsTimer;

try {
  if (showStats) {
    statsTimer = Timer.periodic(statsDisplayInterval, (_) => _showSessionStats());
  }
  // ... main logic
} finally {
  statsTimer?.cancel();
  suggestionsTimer?.cancel();
  _keyboardInput?.dispose();
}
```

### PERF-002: Terminal State Restoration

**Location:** `lib/src/keyboard/keyboard_input_service.dart`

**Description:**
If `dispose()` is not called (e.g., crash), terminal remains in raw mode. The code handles this in `dispose()` but a crash could leave terminal in bad state.

**Current Mitigation:** Signal handlers call cleanup which calls dispose.

**Recommendation:** Consider adding a finalizer or documenting terminal recovery.

---

## Recommendations Summary

### High Priority
1. Add package name validation in `enableAnalyticsDebug()`
2. Add file size limits to JSON import
3. Add schema validation to import operations

### Medium Priority
4. Implement chunked import for large files
5. Enhance path validation with symlink resolution
6. Add try-finally for timer cleanup

### Low Priority
7. Document log injection limitation
8. Consider data sanitization for future web features

---

## Testing Recommendations

Add security-focused tests:

```dart
group('Security', () {
  test('rejects invalid package names', () {
    expect(() => logSource.enableAnalyticsDebug('valid.package'), returnsNormally);
    expect(() => logSource.enableAnalyticsDebug('invalid;rm -rf'), throwsArgumentError);
    expect(() => logSource.enableAnalyticsDebug('../../../etc/passwd'), throwsArgumentError);
  });

  test('rejects oversized import files', () async {
    final largeFile = await createTempFile(size: 200 * 1024 * 1024);
    expect(() => importUseCase.importFromFile(largeFile.path), throwsArgumentError);
  });

  test('rejects ReDoS patterns', () {
    final cache = EventCacheService();
    cache.addEvent('test_event');

    // These should not hang
    expect(() => cache.searchEvents('a' * 200), returnsNormally);
    expect(() => cache.searchEvents('(a+)+b'), returnsNormally);
  });

  test('validates path traversal', () {
    expect(_validateFilePath('../../../etc/passwd'), isNull);
    expect(_validateFilePath('/normal/path.json'), isNotNull);
  });
});
```

---

## Appendix: Secure Coding Checklist

When adding new features, verify:

- [ ] User input validated before shell commands
- [ ] File paths canonicalized and validated
- [ ] JSON parsing has size limits and schema validation
- [ ] Regex patterns from users have ReDoS protection
- [ ] Resources (timers, streams, processes) cleaned up in finally blocks
- [ ] Sensitive data not logged at INFO level
- [ ] New CLI arguments validated for format and length
