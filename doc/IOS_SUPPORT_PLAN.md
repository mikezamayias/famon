# Implementation Plan: iOS Support for Firebase Analytics Monitor

## Executive Summary

This plan details how to add iOS support to the existing Firebase Analytics Monitor CLI tool. The implementation will introduce a platform abstraction layer for log sources, iOS-specific log parsers, and platform detection/selection mechanisms while maintaining backward compatibility with the existing Android implementation.

## Research Findings

### iOS Firebase Analytics Log Format

Based on research from Firebase iOS SDK issues and Firebase documentation, iOS Firebase Analytics logs follow this format:

```
[SDK Version] - [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params: app, screen_view (_vs), {
    _mst = 1;
    ga_event_origin (_o) = app;
    ga_previous_class (_pc) = _TtGC7SwiftUI19UIHostingControllerV6MyApp11AppRootView_;
    ga_screen (_sn) = Dashboard;
    ga_screen_class (_sc) = _TtGC7SwiftUI19UIHostingControllerV6MyApp11AppRootView_;
    ga_screen_id (_si) = 3141985946458986836;
}
```

Key characteristics:
- Timestamp format: `YYYY-MM-DD HH:MM:SS.milliseconds+timezone` (for Xcode console)
- Module identifier: `[FirebaseAnalytics]`
- Log codes: `[I-ACS023051]` (I = Info level)
- Parameters use `=` separator with `;` terminators
- Parameter abbreviations in parentheses (e.g., `(_vs)`, `(_sn)`)

### iOS Log Source Options

1. **Simulator**: `xcrun simctl spawn booted log stream --predicate 'subsystem contains "firebase"'`
2. **Physical Device**: `idevicesyslog -m "FirebaseAnalytics"` from libimobiledevice
   - Requires libimobiledevice installed via Homebrew

---

## Architecture Design

### 1. Platform Abstraction Layer

Create an abstraction for log sources that allows the same monitoring logic to work with both Android and iOS.

#### New Interface: `LogSourceInterface`

```dart
// lib/src/services/interfaces/log_source_interface.dart
abstract class LogSourceInterface {
  /// Platform identifier (android, ios-simulator, ios-device)
  String get platform;

  /// Start the log stream process
  Future<Process> startLogStream({bool verbose = false});

  /// Enable debug mode for analytics (platform-specific)
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage);

  /// Get troubleshooting tips specific to this platform
  List<String> getTroubleshootingTips();

  /// Check if the platform tools are available
  Future<bool> checkToolsAvailable();
}
```

#### Platform Enum

```dart
// lib/src/models/platform_type.dart
enum PlatformType {
  android,
  iosSimulator,
  iosDevice,
  auto; // Auto-detect based on connected devices

  String get displayName => switch (this) {
    android => 'Android',
    iosSimulator => 'iOS Simulator',
    iosDevice => 'iOS Device',
    auto => 'Auto-detect',
  };
}
```

### 2. Log Source Implementations

#### Android Log Source (Refactor existing)

```dart
// lib/src/services/log_sources/android_log_source.dart
@Injectable(as: LogSourceInterface, env: ['android'])
class AndroidLogSource implements LogSourceInterface {
  // Move existing adb logic from MonitorCommand
  // - startLogStream: adb logcat -v time -s FA FA-SVC...
  // - enableAnalyticsDebug: adb shell setprop debug.firebase.analytics.app
  // - raiseFaLogLevels: adb shell setprop log.tag.FA VERBOSE
}
```

#### iOS Simulator Log Source

```dart
// lib/src/services/log_sources/ios_simulator_log_source.dart
@Injectable(as: LogSourceInterface, env: ['ios-simulator'])
class IosSimulatorLogSource implements LogSourceInterface {
  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    // xcrun simctl spawn booted log stream
    //   --level debug
    //   --predicate 'subsystem contains "firebase" OR eventMessage contains "FirebaseAnalytics"'
  }

  @override
  Future<void> enableAnalyticsDebug(String? bundleId) async {
    // Note: iOS debug mode is enabled via Xcode scheme arguments
    // -FIRAnalyticsDebugEnabled or -FIRDebugEnabled
    // This method will log instructions rather than execute commands
  }
}
```

#### iOS Device Log Source

```dart
// lib/src/services/log_sources/ios_device_log_source.dart
@Injectable(as: LogSourceInterface, env: ['ios-device'])
class IosDeviceLogSource implements LogSourceInterface {
  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    // idevicesyslog -m "FirebaseAnalytics"
    // With optional -p to filter by process name
  }

  @override
  Future<bool> checkToolsAvailable() async {
    // Check if idevicesyslog is installed (which idevicesyslog)
    // Provide installation instructions if missing
  }
}
```

### 3. Log Parser Enhancements

#### iOS Log Parser Service

```dart
// lib/src/services/ios_log_parser_service.dart
@Injectable(as: LogParserInterface, env: ['ios'])
class IosLogParserService implements LogParserInterface {
  @override
  String get platform => 'ios';

  // iOS-specific patterns
  static final List<RegExp> _logPatterns = [
    // Pattern 1: Standard iOS Firebase Analytics format
    // [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params: app, EVENT_NAME
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\] Logging event:.*name.*params:\s*\w+,\s*(\w+).*\{([^}]+)\}',
      multiLine: true,
    ),

    // Pattern 2: Event logged confirmation
    // [FirebaseAnalytics][I-ACS023072] Event logged. Event name, event params: EVENT_NAME
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\] Event logged\.\s*Event name.*:\s*(\w+)',
    ),

    // Pattern 3: Debug mode event with parameters
    RegExp(
      r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+[+-]\d+).*\[FirebaseAnalytics\].*Logging event.*,\s*(\w+)\s*\([^)]*\),\s*\{([^}]+)\}',
      multiLine: true,
    ),
  ];
}
```

### 4. Factory Pattern for Platform Selection

```dart
// lib/src/services/log_source_factory.dart
@injectable
class LogSourceFactory {
  Future<LogSourceInterface> create(PlatformType platform) async {
    return switch (platform) {
      PlatformType.android => AndroidLogSource(_processManager, _logger),
      PlatformType.iosSimulator => IosSimulatorLogSource(_processManager, _logger),
      PlatformType.iosDevice => IosDeviceLogSource(_processManager, _logger),
      PlatformType.auto => await _autoDetect(),
    };
  }

  Future<LogSourceInterface> _autoDetect() async {
    // 1. Check for connected Android devices (adb devices)
    // 2. Check for booted iOS simulator (xcrun simctl list booted)
    // 3. Check for connected iOS device (idevice_id -l)
    // Return appropriate log source or prompt user
  }
}
```

### 5. Command Modifications

#### MonitorCommand Changes

```dart
// lib/src/commands/monitor_command.dart
argParser
  ..addOption(
    'platform',
    abbr: 'p',
    allowed: ['android', 'ios-simulator', 'ios-device', 'auto'],
    defaultsTo: 'auto',
    help: 'Target platform for monitoring.',
  )
  ..addOption(
    'device',
    abbr: 'd',
    help: 'Device identifier (UDID for iOS, serial for Android).',
  );
```

---

## File Structure

### New Files to Create

```
lib/src/
├── models/
│   └── platform_type.dart                    # Platform enum
├── services/
│   ├── interfaces/
│   │   └── log_source_interface.dart         # Log source abstraction
│   ├── log_sources/
│   │   ├── android_log_source.dart           # Android adb implementation
│   │   ├── ios_simulator_log_source.dart     # iOS Simulator implementation
│   │   └── ios_device_log_source.dart        # iOS physical device implementation
│   ├── ios_log_parser_service.dart           # iOS-specific log parser
│   ├── log_source_factory.dart               # Factory for log sources
│   └── log_parser_factory.dart               # Factory for parsers
├── shared/
│   └── ios_log_timestamp_parser.dart         # iOS timestamp parsing
```

### Files to Modify

```
lib/src/
├── commands/
│   └── monitor_command.dart                  # Add --platform flag, use factories
├── cli/commands/
│   └── filtered_monitor_command.dart         # Add --platform flag, use factories
├── services/
│   └── log_parser_service.dart               # Add platform getter
├── di/
│   └── register_module.dart                  # Register new factories
├── constants.dart                            # Add iOS-specific constants
```

---

## Implementation Phases

### Phase 1: Foundation (Core Abstractions)
1. Create `PlatformType` enum
2. Create `LogSourceInterface` abstract class
3. Create `LogSourceFactory`
4. Create `LogParserFactory`
5. Add `platform` getter to existing `LogParserInterface`

### Phase 2: Refactor Android Implementation
1. Extract Android logic from `MonitorCommand` into `AndroidLogSource`
2. Update `LogParserService` to implement platform getter
3. Ensure all existing tests pass
4. Update `MonitorCommand` to use factory pattern

### Phase 3: iOS Implementation
1. Create `ios_log_timestamp_parser.dart`
2. Create `IosLogParserService` with iOS regex patterns
3. Create `IosSimulatorLogSource` (xcrun simctl)
4. Create `IosDeviceLogSource` (idevicesyslog)
5. Implement auto-detection in `LogSourceFactory`

### Phase 4: Command Integration
1. Add `--platform` flag to `MonitorCommand`
2. Add `--platform` flag to `FilteredMonitorCommand`
3. Add `--device` flag for device selection
4. Update troubleshooting messages per platform
5. Update help text and descriptions

### Phase 5: Testing and Documentation
1. Create unit tests for iOS log parser
2. Create unit tests for iOS log sources
3. Create integration tests (mock-based)
4. Update README.md with iOS instructions
5. Add iOS prerequisites section
6. Document iOS debug mode setup

---

## iOS-Specific Implementation Details

### iOS Simulator Command

```bash
xcrun simctl spawn booted log stream \
  --level debug \
  --style compact \
  --predicate 'subsystem CONTAINS "firebase" OR eventMessage CONTAINS "FirebaseAnalytics" OR eventMessage CONTAINS "FIRAnalytics"'
```

### iOS Device Command

```bash
# Basic
idevicesyslog -m "FirebaseAnalytics"

# With specific device
idevicesyslog -u DEVICE_UDID -m "FirebaseAnalytics"

# Exclude noisy processes
idevicesyslog -m "FirebaseAnalytics" -e "kernel|locationd|symptomsd"
```

### iOS Debug Mode Requirements

Users must enable Firebase Analytics debug mode in their iOS app:

1. **Xcode Scheme Arguments**: Add `-FIRAnalyticsDebugEnabled` to Run > Arguments
2. **Alternative**: Add `-FIRDebugEnabled` for all Firebase debug logging
3. **UserDefaults method** (programmatic):
   ```swift
   UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
   UserDefaults.standard.set(true, forKey: "/google/measurement/debug_mode")
   ```

---

## Backward Compatibility

1. **Default Behavior**: If `--platform` is not specified, use `auto` detection
2. **Auto-Detection Priority**:
   - Check for connected Android device first (existing behavior)
   - Then check for booted iOS Simulator
   - Then check for connected iOS device
   - Prompt user if multiple platforms detected
3. **Existing Commands**: All existing command patterns continue to work
4. **Environment Variable**: Support `FAMON_DEFAULT_PLATFORM` for user preference

---

## Error Handling and User Guidance

### Tool Availability Checks

```dart
Future<bool> checkIosSimulatorTools() async {
  try {
    final result = await Process.run('xcrun', ['simctl', 'list', 'booted']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<bool> checkIdevicesyslog() async {
  try {
    final result = await Process.run('which', ['idevicesyslog']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
```

### Installation Instructions

```
iOS Simulator: Requires Xcode Command Line Tools
  Install: xcode-select --install

iOS Device: Requires libimobiledevice
  Install: brew install libimobiledevice
```

---

## Testing Strategy

### Unit Tests for iOS Parser

```dart
// test/src/services/ios_log_parser_service_test.dart
group('IosLogParserService', () {
  test('should parse standard iOS Firebase Analytics log format', () {
    const logLine = '''
11.5.0 - [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params: app, purchase, {
    currency = USD;
    value = 29.99;
    transaction_id = txn_123;
}''';

    final result = parser.parse(logLine);
    expect(result?.eventName, equals('purchase'));
    expect(result?.parameters['currency'], equals('USD'));
  });
});
```

### Integration Tests (Mock Process)

```dart
// test/src/services/log_sources/ios_simulator_log_source_test.dart
test('should start log stream with correct arguments', () async {
  when(() => mockProcessManager.start(any())).thenAnswer((_) async => mockProcess);

  await logSource.startLogStream();

  verify(() => mockProcessManager.start([
    'xcrun', 'simctl', 'spawn', 'booted', 'log', 'stream',
    '--level', 'debug',
    '--predicate', contains('firebase'),
  ])).called(1);
});
```

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Foundation | Low |
| Phase 2: Refactor Android | Medium |
| Phase 3: iOS Implementation | High |
| Phase 4: Command Integration | Medium |
| Phase 5: Testing & Docs | Medium |
| **Total** | **Medium-High** |

---

## References

- [Firebase iOS SDK - Debug Mode](https://firebase.google.com/docs/analytics/debugview)
- [libimobiledevice - idevicesyslog](https://libimobiledevice.org/)
- [iOS Dev Recipes - Simulator Logging](https://www.iosdev.recipes/simulator/os_log/)
- [Firebase iOS SDK GitHub Issues](https://github.com/firebase/firebase-ios-sdk/issues/14258)
