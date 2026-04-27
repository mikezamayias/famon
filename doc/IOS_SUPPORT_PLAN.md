# iOS Support Plan

## iOS Firebase Analytics Log Format

iOS Firebase Analytics logs:

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
- Timestamp: `YYYY-MM-DD HH:MM:SS.milliseconds+offset` (Xcode console)
- Module identifier: `[FirebaseAnalytics]`
- Log codes: `[I-ACS023051]`
- Parameters: `=` separator, `;` terminators
- Parameter abbreviations in parentheses: `(_vs)`, `(_sn)`

## Log Sources

- **Simulator:** `xcrun simctl spawn booted log stream --predicate 'subsystem contains "firebase"'`
- **Physical device:** `idevicesyslog -m "FirebaseAnalytics"` (requires libimobiledevice via Homebrew)

---

## Architecture

### Platform Abstraction

```dart
// lib/src/services/interfaces/log_source_interface.dart
abstract class LogSourceInterface {
  String get platform; // android, ios-simulator, ios-device

  Future<Process> startLogStream({bool verbose = false});
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage);
  List<String> getTroubleshootingTips();
  Future<bool> checkToolsAvailable();
}
```

```dart
// lib/src/models/platform_type.dart
enum PlatformType {
  android,
  iosSimulator,
  iosDevice,
  auto;

  String get displayName => switch (this) {
    android => 'Android',
    iosSimulator => 'iOS Simulator',
    iosDevice => 'iOS Device',
    auto => 'Auto-detect',
  };
}
```

### Log Sources

```dart
// lib/src/services/log_sources/android_log_source.dart
@Injectable(as: LogSourceInterface, env: ['android'])
class AndroidLogSource implements LogSourceInterface {
  // adb logcat -v time -s FA FA-SVC...
  // adb shell setprop debug.firebase.analytics.app
}
```

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
    // iOS debug mode is set via Xcode scheme args: -FIRAnalyticsDebugEnabled
    // This method logs instructions rather than running commands.
  }
}
```

```dart
// lib/src/services/log_sources/ios_device_log_source.dart
@Injectable(as: LogSourceInterface, env: ['ios-device'])
class IosDeviceLogSource implements LogSourceInterface {
  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    // idevicesyslog -m "FirebaseAnalytics"
  }

  @override
  Future<bool> checkToolsAvailable() async {
    // which idevicesyslog
  }
}
```

### iOS Log Parser

```dart
// lib/src/services/ios_log_parser_service.dart
@Injectable(as: LogParserInterface, env: ['ios'])
class IosLogParserService implements LogParserInterface {
  @override
  String get platform => 'ios';

  static final List<RegExp> _logPatterns = [
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\] Logging event:.*name.*params:\s*\w+,\s*(\w+).*\{([^}]+)\}',
      multiLine: true,
    ),
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\] Event logged\.\s*Event name.*:\s*(\w+)',
    ),
    RegExp(
      r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+[+-]\d+).*\[FirebaseAnalytics\].*Logging event.*,\s*(\w+)\s*\([^)]*\),\s*\{([^}]+)\}',
      multiLine: true,
    ),
  ];
}
```

### Factory

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
    // 1. Check adb devices (Android)
    // 2. Check xcrun simctl list booted (iOS Simulator)
    // 3. Check idevice_id -l (iOS Device)
    // Prompt if multiple detected.
  }
}
```

### Command Changes

```dart
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

## File Layout

### New Files

```
lib/src/
├── models/
│   └── platform_type.dart
├── services/
│   ├── interfaces/
│   │   └── log_source_interface.dart
│   ├── log_sources/
│   │   ├── android_log_source.dart
│   │   ├── ios_simulator_log_source.dart
│   │   └── ios_device_log_source.dart
│   ├── ios_log_parser_service.dart
│   ├── log_source_factory.dart
│   └── log_parser_factory.dart
├── shared/
│   └── ios_log_timestamp_parser.dart
```

### Modified Files

```
lib/src/
├── commands/monitor_command.dart
├── cli/commands/filtered_monitor_command.dart
├── services/log_parser_service.dart
├── di/register_module.dart
└── constants.dart
```

---

## Implementation Phases

### Phase 1: Foundation
1. Create `PlatformType` enum
2. Create `LogSourceInterface`
3. Create `LogSourceFactory` and `LogParserFactory`
4. Add `platform` getter to `LogParserInterface`

### Phase 2: Refactor Android
1. Extract Android logic from `MonitorCommand` into `AndroidLogSource`
2. Update `LogParserService` with platform getter
3. Verify all existing tests pass
4. Update `MonitorCommand` to use factory

### Phase 3: iOS Implementation
1. Create `ios_log_timestamp_parser.dart`
2. Create `IosLogParserService`
3. Create `IosSimulatorLogSource`
4. Create `IosDeviceLogSource`
5. Implement auto-detection in `LogSourceFactory`

### Phase 4: Command Integration
1. Add `--platform` and `--device` flags to `MonitorCommand` and `FilteredMonitorCommand`
2. Update troubleshooting messages per platform

### Phase 5: Testing
1. Unit tests for iOS log parser
2. Unit tests for iOS log sources
3. Mock-based integration tests
4. Update README with iOS instructions

---

## iOS-Specific Details

### Simulator command

```bash
xcrun simctl spawn booted log stream \
  --level debug \
  --style compact \
  --predicate 'subsystem CONTAINS "firebase" OR eventMessage CONTAINS "FirebaseAnalytics" OR eventMessage CONTAINS "FIRAnalytics"'
```

### Device command

```bash
idevicesyslog -m "FirebaseAnalytics"
idevicesyslog -u DEVICE_UDID -m "FirebaseAnalytics"
idevicesyslog -m "FirebaseAnalytics" -e "kernel|locationd|symptomsd"
```

### Debug mode requirements

Users must enable Firebase Analytics debug mode in their iOS app:

1. Xcode Scheme Arguments: add `-FIRAnalyticsDebugEnabled` under Run > Arguments
2. Alternative: `-FIRDebugEnabled` for all Firebase debug logging
3. Programmatic (UserDefaults):
   ```swift
   UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
   UserDefaults.standard.set(true, forKey: "/google/measurement/debug_mode")
   ```

### Tool availability checks

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

### Installation

```
iOS Simulator: requires Xcode Command Line Tools
  xcode-select --install

iOS Device: requires libimobiledevice
  brew install libimobiledevice
```

---

## Backward Compatibility

- Default: `--platform auto`
- Auto-detection order: Android → iOS Simulator → iOS Device → prompt if multiple
- `FAMON_DEFAULT_PLATFORM` env var respected for user preference

---

## Testing

```dart
group('IosLogParserService', () {
  test('parses standard iOS Firebase Analytics log format', () {
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

test('starts log stream with correct arguments', () async {
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

## References

- [Firebase iOS SDK - Debug Mode](https://firebase.google.com/docs/analytics/debugview)
- [libimobiledevice - idevicesyslog](https://libimobiledevice.org/)
- [iOS Dev Recipes - Simulator Logging](https://www.iosdev.recipes/simulator/os_log/)
- [Firebase iOS SDK GitHub Issues](https://github.com/firebase/firebase-ios-sdk/issues/14258)
