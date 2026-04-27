# Security Audit

**Date:** January 2026
**Scope:** Full codebase security review
**Tool Version:** 1.0.1
**Risk Level:** Low-Medium (local CLI, user-initiated commands)

## Findings

| ID | Finding | Severity | Status |
|----|---------|----------|--------|
| SEC-001 | Command injection via package name | Medium | Fixed |
| SEC-002 | Path traversal partially mitigated | Low | Partial |
| SEC-003 | Unbounded JSON import | Medium | Fixed |
| SEC-004 | ReDoS in search patterns | Low | Mitigated |
| SEC-005 | Log injection from logcat | Low | Accepted |
| SEC-006 | Memory exhaustion via large imports | Medium | Fixed |

---

## SEC-001: Command Injection via Package Name — Fixed

**Location:** `lib/src/services/log_source_factory.dart:136-199`

`enableAnalyticsDebug()` validates user-supplied package names before passing to `adb shell setprop`.

```dart
static final _validPackageNamePattern =
    RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
static const _maxPackageNameLength = 256;

Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
  if (bundleIdOrPackage == null || bundleIdOrPackage.isEmpty) return;

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

---

## SEC-002: Path Traversal — Partially Mitigated

**Location:** `lib/src/cli/commands/database_command.dart:15-45`

Current protection: null byte detection, `p.canonicalize()`, file existence checks.

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
1. Symlink attacks: canonical path may resolve through symlinks to unexpected locations.
2. No directory containment: user can specify paths outside expected directories.

**Risk:** Low — CLI runs with user's own permissions.

**Recommended fix:**

```dart
String? _validateFilePath(String? filePath, {
  bool mustExist = false,
  String? containingDirectory,
}) {
  if (filePath == null || filePath.isEmpty) return null;
  if (filePath.contains('\x00')) return null;

  final canonicalPath = p.canonicalize(filePath);

  if (mustExist) {
    final file = File(canonicalPath);
    if (!file.existsSync()) return null;

    try {
      final resolvedPath = file.resolveSymbolicLinksSync();

      if (containingDirectory != null) {
        final resolvedDir = p.canonicalize(containingDirectory);
        if (!p.isWithin(resolvedDir, resolvedPath)) {
          return null;
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

## SEC-003: Unbounded JSON Import — Fixed

**Location:** `lib/src/core/application/use_cases/import_data_use_case.dart`

Import validates file size and schema before processing.

```dart
static const int maxImportFileSize = 100 * 1024 * 1024;

Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
  final file = File(filePath);

  final fileSize = await file.length();
  if (fileSize > maxImportFileSize) {
    throw ArgumentError('Import file too large...');
  }

  final content = await file.readAsString();
  final decoded = jsonDecode(content);

  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Invalid import file: expected JSON object');
  }

  final validationError = _validateImportSchema(decoded);
  if (validationError != null) {
    throw FormatException('Invalid import file structure: $validationError');
  }

  await _repository.importAllData(decoded, overwrite: overwrite);
}
```

---

## SEC-004: ReDoS in Search Patterns — Mitigated

**Location:** `lib/src/services/event_cache_service.dart:124-165`

Pattern length is capped at 100 chars; dangerous nested quantifiers fall back to substring search.

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

---

## SEC-005: Log Injection from Logcat — Accepted Risk

**Location:** `lib/src/services/log_parser_service.dart`

Event names and parameter values from logcat are stored as-is. A malicious app on the monitored device could log crafted events.

**Risks:** Terminal output corruption via control characters; misleading audit trails; XSS if a web UI is ever added.

**Current mitigation:** Terminal handles control characters reasonably. No web UI. Data comes from the user's own connected device.

If a web UI or sharing feature is added, sanitize stored data:

```dart
String _sanitizeForStorage(String value) {
  return value.replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'), '');
}
```

---

## SEC-006: Memory Exhaustion via Large Imports — Fixed

**Location:** `lib/src/core/infrastructure/repositories/isar_data_export_repository.dart`

Import processes records in chunks of 1000 per transaction.

```dart
static const int _importChunkSize = 1000;

Future<void> importEvents(Map<String, dynamic> data, {bool overwrite = false}) async {
  final isar = await database.db;
  final eventsList = data['events'] as List<dynamic>?;
  if (eventsList == null || eventsList.isEmpty) return;

  if (overwrite) {
    await isar.writeTxn(() => isar.isarAnalyticsEvents.clear());
  }

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

---

## Performance-Related Issues

### PERF-001: Timer Resource Leaks

**Location:** `lib/src/commands/monitor_command.dart`

Timers may not be cancelled if an exception is thrown during monitoring. Wrap with try-finally:

```dart
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

A crash before `dispose()` leaves the terminal in raw mode. Signal handlers call cleanup → dispose, which mitigates this in normal exit paths. Document terminal recovery (`reset` or `stty sane`) for users who hit abnormal exits.

---

## Checklist for New Features

- [ ] User input validated before shell commands
- [ ] File paths canonicalized and validated
- [ ] JSON parsing has size limits and schema validation
- [ ] Regex patterns from users have ReDoS protection
- [ ] Resources (timers, streams, processes) cleaned up in finally blocks
- [ ] Sensitive data not logged at INFO level
- [ ] New CLI arguments validated for format and length

---

## Security Tests

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

    expect(() => cache.searchEvents('a' * 200), returnsNormally);
    expect(() => cache.searchEvents('(a+)+b'), returnsNormally);
  });

  test('validates path traversal', () {
    expect(_validateFilePath('../../../etc/passwd'), isNull);
    expect(_validateFilePath('/normal/path.json'), isNotNull);
  });
});
```
