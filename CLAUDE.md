# Firebase Analytics Monitor - Development Guidelines

This document provides context and guidelines for AI assistants and developers working on this codebase.

## Project Overview

Firebase Analytics Monitor (`famon`) is a Dart CLI tool that monitors Firebase Analytics events in real-time by parsing platform log output (Android logcat, iOS Simulator via xcrun simctl, and physical iOS devices via idevicesyslog). It provides filtering, formatting, and persistence capabilities.

## Cross-Platform Parity

**All supported platforms must behave identically from the user's perspective.**

When fixing a bug or adding a feature in one platform's log parser, always verify and apply the same fix/feature to every other platform parser. The CLI must produce consistent output regardless of whether the log source is Android, iOS Simulator, or iOS Device.

Key rules:

1. **Bug fixes are cross-platform by default.** A parsing fix in `LogParserService` (Android) must be mirrored in `IosLogParserService` (iOS), and vice versa.
2. **Test coverage must match.** If a test case is added for one parser (e.g. items array truncation), an equivalent test must exist for the other parser(s).
3. **Output format is platform-agnostic.** `EventFormatterService` receives `AnalyticsEvent` objects — the same fields (`eventName`, `parameters`, `items`, `rawTimestamp`) must be populated consistently regardless of source platform.
4. **New parsing capabilities require all-platform implementation.** Do not ship a feature (e.g. items array parsing) for only one platform.

Platform parsers and their responsibilities:

| Parser                | Platform               | Log format                                    |
| --------------------- | ---------------------- | --------------------------------------------- |
| `LogParserService`    | Android                | `Bundle[{key=value, items=[Bundle[{...}]]}]`  |
| `IosLogParserService` | iOS Simulator / Device | `{ key (_abbrev) = value; items = [{...}]; }` |

## Architecture

```text
lib/src/
├── cli/commands/          # CLI-specific command implementations
├── commands/              # Core command implementations
├── core/domain/entities/  # Domain models (AnalyticsEvent, etc.)
├── database/              # Isar database for persistence
├── di/                    # Dependency injection setup
├── models/                # Data models
├── services/              # Business logic services
│   └── interfaces/        # Service interfaces for DI
├── shared/                # Shared utilities
└── utils/                 # Utility functions
```

## Performance Guidelines

This CLI tool processes a continuous stream of logcat data. Efficient resource usage is critical for long-running sessions.

### RegExp Patterns: Always Static Final

**NEVER** compile regex patterns inside methods that are called frequently. Always use `static final`:

```dart
// CORRECT
class LogParserService {
  static final _eventPattern = RegExp(r'Logging event: name=([^,]+)');

  String? parse(String line) {
    final match = _eventPattern.firstMatch(line);
    // ...
  }
}

// WRONG - compiles regex on every call
class LogParserService {
  String? parse(String line) {
    final pattern = RegExp(r'Logging event: name=([^,]+)'); // BAD!
    final match = pattern.firstMatch(line);
    // ...
  }
}
```

Hot paths where this matters:

- `LogParserService.parse()` - called for every logcat line
- `LogParserService._parseParams()` - called for every event
- `LogParserService._cleanValue()` - called for every parameter value
- `LogTimestampParser.parseTimestamp()` - called for every event

### Stream Processing

When processing logcat streams:

1. **Consume stderr** to prevent buffer overflow:

   ```dart
   final process = await processManager.start(['adb', 'logcat']);
   process.stderr.drain<void>(); // Prevent buffer buildup
   ```

2. **Use broadcast streams carefully** - prefer single listeners when possible

3. **Add signal handlers** for graceful shutdown:

   ```dart
   ProcessSignal.sigint.watch().listen((_) async {
     await cleanup();
     process.kill();
   });
   ```

### Memory Management

1. **Bound cache sizes** in long-running services:

   ```dart
   static const _maxCacheSize = 10000;

   void addItem(String item) {
     if (_cache.length >= _maxCacheSize) {
       _evictOldest();
     }
     _cache.add(item);
   }
   ```

2. **Close database connections** when done:

   ```dart
   @disposeMethod
   Future<void> dispose() async {
     await _isar?.close();
   }
   ```

3. **Avoid creating intermediate collections** unnecessarily:

   ```dart
   // Prefer
   entries.where((e) => e.value > threshold).map((e) => e.key)

   // Over
   entries.toList()..sort()..where(...).map(...).toList()
   ```

### String Operations

1. **Avoid chained replaceAll** when possible:

   ```dart
   // If cleaning multiple patterns, consider single-pass:
   String clean(String value) {
     final buffer = StringBuffer();
     for (var i = 0; i < value.length; i++) {
       final char = value[i];
       if (!_skipChars.contains(char)) {
         buffer.write(char);
       }
     }
     return buffer.toString();
   }
   ```

2. **Use StringBuffer** for building strings in loops

## Testing Guidelines

### Test Structure

```text
test/
├── src/                   # Unit tests mirroring lib/src structure
│   ├── commands/
│   ├── services/
│   └── ...
├── helpers/
│   └── test_helpers.dart  # DI setup for tests
└── integration/           # Integration tests
```

### Running Tests

```bash
# Run all tests with coverage
dart test --coverage=coverage

# Generate coverage report
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov.info \
  --report-on=lib
```

### Test Helpers

Use `registerTestDependencies()` from `test/helpers/test_helpers.dart` for consistent DI setup in tests.

## Dependency Injection

Uses `injectable` and `get_it`. After modifying DI registrations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `very_good_analysis` lint rules
- Run `dart analyze` before commits

## Git Workflow

- Main branch: `development`
- Feature branches: `feature/<name>`
- Release branches: merge `development` to `main`, tag with version

## Security Guidelines

This section documents security considerations and mitigations for the codebase. Follow these guidelines when adding new features to prevent security vulnerabilities.

### Command Injection Prevention

When spawning external processes (adb, xcrun, idevicesyslog, clipboard tools), validate all user-provided arguments:

```dart
// CORRECT - Validate package names before shell commands
static final _validPackageNamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]*$');

Future<void> enableAnalyticsDebug(String? packageName) async {
  if (packageName == null || packageName.isEmpty) return;

  // Validate: alphanumeric, dots, underscores only; max 256 chars
  if (packageName.length > 256 || !_validPackageNamePattern.hasMatch(packageName)) {
    throw ArgumentError('Invalid package name format');
  }

  await _processManager.start(['adb', 'shell', 'setprop', '...', packageName]);
}

// WRONG - Passing unvalidated user input to shell
await _processManager.start(['adb', 'shell', 'setprop', '...', userInput]); // Dangerous!
```

**Known risk areas:**

- `LogSourceFactory.enableAnalyticsDebug()` - accepts package name from CLI
- Any future feature accepting app identifiers, file names, or paths

### Path Traversal Prevention

Always validate and canonicalize file paths from user input:

```dart
// CORRECT - Use validation helpers
String? _validateFilePath(String? filePath, {bool mustExist = false}) {
  if (filePath == null || filePath.isEmpty) return null;

  // Check for null bytes (path truncation attack)
  if (filePath.contains('\x00')) return null;

  // Canonicalize to resolve . and .. segments
  final canonicalPath = p.canonicalize(filePath);

  // For files that must exist, verify they do
  if (mustExist && !File(canonicalPath).existsSync()) return null;

  return canonicalPath;
}
```

**Additional considerations:**

- Symlink attacks: Consider using `file.resolveSymbolicLinksSync()` for sensitive operations
- Directory containment: Verify resolved paths stay within expected directories
- Existing validation in `database_command.dart` - extend this pattern to new features

### Input Validation for External Data

#### JSON Import/Deserialization

When importing JSON data from files, validate structure and apply limits:

```dart
// CORRECT - Validate before processing
Future<void> importFromFile(String filePath) async {
  final file = File(filePath);

  // Check file size before reading (prevent memory exhaustion)
  if (file.lengthSync() > maxImportFileSize) {
    throw ArgumentError('Import file exceeds maximum size');
  }

  final content = await file.readAsString();
  final data = jsonDecode(content) as Map<String, dynamic>;

  // Validate schema before processing
  if (!_validateImportSchema(data)) {
    throw FormatException('Invalid import file structure');
  }

  // Validate individual records
  for (final event in data['events'] ?? []) {
    _validateEventData(event);
  }
}
```

#### Event Name and Parameter Validation

Data from logcat may contain malformed or malicious content:

```dart
// CORRECT - Validate Firebase naming conventions
static final _validFirebaseNamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

bool _isValidFirebaseName(String name) {
  if (name.isEmpty || name.length > 40) return false;
  return _validFirebaseNamePattern.hasMatch(name);
}

// Validate parameter values (length limits, sanitization)
String _sanitizeParameterValue(String value) {
  if (value.length > 100) return value.substring(0, 100);
  // Remove control characters
  return value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
}
```

### ReDoS (Regular Expression Denial of Service) Prevention

User-provided patterns for search/filter must be validated:

```dart
// CORRECT - Existing protection in EventCacheService
static const int _maxPatternLength = 100;
static final RegExp _dangerousPatternIndicators = RegExp(
  r'(\+\+|\*\*|\{\d+,\d*\}\{|\(\?\:.*\)\+|\(\?\:.*\)\*)',
);

List<String> searchEvents(String pattern) {
  // Reject overly long patterns
  if (pattern.length > _maxPatternLength) {
    return _substringSearch(pattern); // Fallback to safe search
  }

  // Reject patterns with exponential backtracking potential
  if (_dangerousPatternIndicators.hasMatch(pattern)) {
    return _substringSearch(pattern);
  }

  try {
    final regex = RegExp(pattern, caseSensitive: false);
    return _uniqueEventNames.where(regex.hasMatch).toList();
  } on FormatException {
    return []; // Invalid regex
  }
}
```

### Resource Cleanup (Memory Leak Prevention)

Ensure all resources are properly cleaned up, especially in long-running operations:

```dart
// CORRECT - Use try-finally for guaranteed cleanup
Future<int> run() async {
  Timer? statsTimer;
  StreamSubscription? subscription;

  try {
    statsTimer = Timer.periodic(duration, callback);
    subscription = stream.listen(handler);

    // ... main logic
  } finally {
    // Guaranteed cleanup even on exceptions
    statsTimer?.cancel();
    await subscription?.cancel();
    _keyboardInput?.dispose();
  }
}

// CORRECT - Restore terminal state in keyboard service
void dispose() {
  if (!_isStarted) return;

  _subscription?.cancel();

  // Always restore terminal settings
  if (isInteractive) {
    try {
      stdin.lineMode = _originalLineMode;
      stdin.echoMode = _originalEchoMode;
    } on StdinException {
      // Terminal might be gone, ignore
    }
  }

  _controller?.close();
  _isStarted = false;
}
```

### Sensitive Data Handling

- **Clipboard**: Currently uses stdin to pass data to clipboard tools (good)
- **Logs**: Avoid logging sensitive parameter values in verbose mode
- **Database**: Analytics events may contain PII - consider encryption for stored data
- **Export files**: Backup files contain all stored events - warn users about sensitive data

### Attack Vector Summary

| Vector                            | Severity | Location                           | Status              |
| --------------------------------- | -------- | ---------------------------------- | ------------------- |
| Command Injection (package name)  | Medium   | `log_source_factory.dart`          | Mitigated           |
| Path Traversal                    | Low      | `database_command.dart`            | Partially mitigated |
| Malicious JSON Import             | Medium   | `import_data_use_case.dart`        | Mitigated           |
| ReDoS                             | Low      | `event_cache_service.dart`         | Mitigated           |
| Memory Exhaustion (large imports) | Medium   | `isar_data_export_repository.dart` | Mitigated           |
| Log Injection                     | Low      | `log_parser_service.dart`          | Low risk (CLI only) |

## Related Documentation

- `doc/RELEASE_FLOW.md` - Release process
- `doc/IOS_SUPPORT_PLAN.md` - iOS support implementation plan
- `doc/KEYBOARD_SHORTCUTS_PLAN.md` - Planned keyboard shortcuts feature
- `doc/PERFORMANCE_AUDIT_PLAN.md` - Performance audit findings
- `doc/SECURITY_AUDIT.md` - Security audit findings and recommendations
