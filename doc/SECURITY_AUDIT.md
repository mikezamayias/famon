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
| SEC-001 | Command injection via package name | Medium | **Fixed** |
| SEC-002 | Path traversal partially mitigated | Low | Partial |
| SEC-003 | Unbounded JSON import | Medium | **Fixed** |
| SEC-004 | ReDoS in search patterns | Low | Mitigated |
| SEC-005 | Log injection from logcat | Low | Accepted Risk |
| SEC-006 | Memory exhaustion via large imports | Medium | **Fixed** |

---

## Detailed Findings

### SEC-001: Command Injection via Package Name - FIXED

**Location:** `lib/src/services/log_source_factory.dart:136-199`

**Description:**
The `enableAnalyticsDebug()` method now validates user-supplied package names before passing to `adb shell setprop`.

**Fix Applied:**
- Added `_validPackageNamePattern` regex requiring proper Android package format
- Added `_maxPackageNameLength` constant (256 chars)
- Validation rejects invalid names with helpful error messages

**Implementation:**
```dart
static final _validPackageNamePattern =
    RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
static const _maxPackageNameLength = 256;

Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
  if (bundleIdOrPackage == null || bundleIdOrPackage.isEmpty) return;

  // Security: Validate package name format
  if (bundleIdOrPackage.length > _maxPackageNameLength) {
    _logger.warn('Package name too long...');
    return;
  }

  if (!_validPackageNamePattern.hasMatch(bundleIdOrPackage)) {
    _logger.warn('Invalid package name format...');
    return;
  }
  // Proceed with validated input
}
```

**Status:** Fixed

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

### SEC-003: Unbounded JSON Import - FIXED

**Location:**
- `lib/src/core/application/use_cases/import_data_use_case.dart`

**Description:**
JSON import operations now validate file size and schema before processing.

**Fix Applied:**
- Added 100MB file size limit (`maxImportFileSize`)
- Added comprehensive schema validation (`_validateImportSchema`)
- Validates required fields: version, data section
- Validates nested structure: events, metadata, sessions sections
- Sample validation of first 10 events for required `eventName` field
- Improved error messages with specific validation failures

**Implementation:**
```dart
static const int maxImportFileSize = 100 * 1024 * 1024;

Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
  final file = File(filePath);

  // Security: Check file size before reading
  final fileSize = await file.length();
  if (fileSize > maxImportFileSize) {
    throw ArgumentError('Import file too large...');
  }

  final content = await file.readAsString();
  final decoded = jsonDecode(content);

  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Invalid import file: expected JSON object');
  }

  // Validate schema structure
  final validationError = _validateImportSchema(decoded);
  if (validationError != null) {
    throw FormatException('Invalid import file structure: $validationError');
  }

  await _repository.importAllData(decoded, overwrite: overwrite);
}
```

**Status:** Fixed

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

### SEC-006: Memory Exhaustion via Large Imports - FIXED

**Location:** `lib/src/core/infrastructure/repositories/isar_data_export_repository.dart`

**Description:**
Import methods now process data in chunks to bound memory usage.

**Fix Applied:**
- Added `_importChunkSize` constant (1000 records per transaction)
- Chunked processing applied to `importEvents`, `importEventMetadata`, and `importSessions`
- Separate clear transaction from import for overwrite mode
- Each chunk processed in its own transaction to bound memory

**Implementation:**
```dart
static const int _importChunkSize = 1000;

Future<void> importEvents(Map<String, dynamic> data, {bool overwrite = false}) async {
  final isar = await database.db;
  final eventsList = data['events'] as List<dynamic>?;
  if (eventsList == null || eventsList.isEmpty) return;

  if (overwrite) {
    await isar.writeTxn(() => isar.isarAnalyticsEvents.clear());
  }

  // Process in chunks to bound memory usage
  final totalEvents = eventsList.length;
  for (var offset = 0; offset < totalEvents; offset += _importChunkSize) {
    final endIndex = (offset + _importChunkSize < totalEvents)
        ? offset + _importChunkSize
        : totalEvents;
    final chunk = eventsList.sublist(offset, endIndex);

    await isar.writeTxn(() async {
      for (final eventData in chunk) {
        final event = AnalyticsEvent.fromJson(eventData as Map<String, dynamic>);
        await isar.isarAnalyticsEvents.put(IsarAnalyticsEvent.fromDomain(event));
      }
    });
  }
}
```

**Status:** Fixed

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
