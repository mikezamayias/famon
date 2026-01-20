# Firebase Analytics Monitor - Development Guidelines

This document provides context and guidelines for AI assistants and developers working on this codebase.

## Project Overview

Firebase Analytics Monitor (`famon`) is a Dart CLI tool that monitors Firebase Analytics events in real-time by parsing Android logcat output. It provides filtering, formatting, and persistence capabilities.

## Architecture

```
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

```
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

## Related Documentation

- `doc/RELEASE_FLOW.md` - Release process
- `doc/IOS_SUPPORT_PLAN.md` - Future iOS support plan
- `doc/KEYBOARD_SHORTCUTS_PLAN.md` - Planned keyboard shortcuts feature
- `doc/PERFORMANCE_AUDIT_PLAN.md` - Performance audit findings
