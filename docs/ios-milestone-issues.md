# v1.4.0 — iOS Support: Milestone Issues

> **Milestone:** v1.4.0 — iOS Support
> **Description:** Full iOS log source support: simulator, USB device, wireless. See `doc/IOS_SUPPORT_PLAN.md`
> **Due:** 2026-07-01

---

## Issue 1: Create `PlatformType` enum

**Labels:** enhancement, ios

**Description:**
Create `lib/src/models/platform_type.dart` with the `PlatformType` enum (`android`, `iosSimulator`, `iosDevice`, `auto`) and `displayName` getter as specified in `doc/IOS_SUPPORT_PLAN.md` § Architecture > Platform Abstraction.

**Acceptance Criteria:**
- [ ] `PlatformType` enum exists at `lib/src/models/platform_type.dart`
- [ ] Enum values: `android`, `iosSimulator`, `iosDevice`, `auto`
- [ ] `displayName` getter returns human-readable strings
- [ ] Enum is importable and usable from other modules

---

## Issue 2: Create `LogSourceInterface` abstraction

**Labels:** enhancement, ios

**Description:**
Create `lib/src/services/interfaces/log_source_interface.dart` defining the platform-agnostic log source contract. See `doc/IOS_SUPPORT_PLAN.md` § Architecture > Platform Abstraction.

**Acceptance Criteria:**
- [ ] `LogSourceInterface` abstract class exists
- [ ] Declares: `platform` getter, `startLogStream()`, `enableAnalyticsDebug()`, `getTroubleshootingTips()`, `checkToolsAvailable()`
- [ ] All method signatures match the plan spec

---

## Issue 3: Create `LogSourceFactory` and `LogParserFactory`

**Labels:** enhancement, ios

**Description:**
Create `lib/src/services/log_source_factory.dart` and `lib/src/services/log_parser_factory.dart` to instantiate platform-specific log sources and parsers. The factory should support auto-detection (Android > iOS Simulator > iOS Device) and prompt when multiple platforms are detected. See `doc/IOS_SUPPORT_PLAN.md` § Architecture > Factory.

**Acceptance Criteria:**
- [ ] `LogSourceFactory.create(PlatformType)` returns the correct `LogSourceInterface` implementation
- [ ] `LogParserFactory` returns the correct parser per platform
- [ ] Auto-detection checks: `adb devices`, `xcrun simctl list booted`, `idevice_id -l` in order
- [ ] Prompts user when multiple platforms are detected

---

## Issue 4: Add `platform` getter to `LogParserInterface`

**Labels:** enhancement, ios

**Description:**
Extend `LogParserInterface` with a `String get platform` property so parsers self-identify their target platform. See `doc/IOS_SUPPORT_PLAN.md` § Phase 1: Foundation, step 4.

**Acceptance Criteria:**
- [ ] `LogParserInterface` declares `String get platform`
- [ ] Existing `LogParserService` (Android) implements the getter returning `'android'`

---

## Issue 5: Extract Android logic into `AndroidLogSource`

**Labels:** refactor, ios

**Description:**
Extract Android-specific log streaming and debug-mode logic from `MonitorCommand` into `lib/src/services/log_sources/android_log_source.dart` implementing `LogSourceInterface`. See `doc/IOS_SUPPORT_PLAN.md` § Phase 2: Refactor Android.

**Acceptance Criteria:**
- [ ] `AndroidLogSource` implements `LogSourceInterface`
- [ ] `adb logcat` streaming logic moved out of `MonitorCommand`
- [ ] `adb shell setprop debug.firebase.analytics.app` logic encapsulated in `enableAnalyticsDebug()`
- [ ] All existing tests continue to pass
- [ ] `MonitorCommand` uses the factory to obtain the log source

---

## Issue 6: Update `LogParserService` with platform getter

**Labels:** refactor, ios

**Description:**
Add the `platform` getter (returning `'android'`) to the existing `LogParserService`. See `doc/IOS_SUPPORT_PLAN.md` § Phase 2, step 2.

**Acceptance Criteria:**
- [ ] `LogParserService.platform` returns `'android'`
- [ ] No behavioral changes to existing parsing logic
- [ ] All existing tests pass

---

## Issue 7: Create iOS timestamp parser

**Labels:** enhancement, ios

**Description:**
Create `lib/src/shared/ios_log_timestamp_parser.dart` to parse iOS log timestamps (`YYYY-MM-DD HH:MM:SS.milliseconds+offset`). See `doc/IOS_SUPPORT_PLAN.md` § iOS-Specific Details.

**Acceptance Criteria:**
- [ ] Parses Xcode console timestamp format correctly
- [ ] Returns `DateTime` objects
- [ ] Handles time zone offsets
- [ ] Unit tests cover standard and edge-case timestamps

---

## Issue 8: Create `IosLogParserService`

**Labels:** enhancement, ios

**Description:**
Create `lib/src/services/ios_log_parser_service.dart` implementing `LogParserInterface` for iOS Firebase Analytics log lines. Must handle the three regex patterns specified in the plan and parse `=`/`;` parameter format. See `doc/IOS_SUPPORT_PLAN.md` § Architecture > iOS Log Parser.

**Acceptance Criteria:**
- [ ] Parses standard iOS Firebase Analytics log format (event name + parameters)
- [ ] Handles `[FirebaseAnalytics][I-ACS...]` prefix
- [ ] Extracts parameter abbreviations in parentheses
- [ ] Produces `AnalyticsEvent` with `eventName`, `parameters`, `items`, and `rawTimestamp` populated consistently with Android parser
- [ ] `platform` getter returns `'ios'`
- [ ] Unit tests cover all three regex patterns from the plan

---

## Issue 9: Create `IosSimulatorLogSource`

**Labels:** enhancement, ios

**Description:**
Create `lib/src/services/log_sources/ios_simulator_log_source.dart` implementing `LogSourceInterface`. Uses `xcrun simctl spawn booted log stream` with the predicate filtering for Firebase subsystem/messages. See `doc/IOS_SUPPORT_PLAN.md` § iOS-Specific Details > Simulator command.

**Acceptance Criteria:**
- [ ] `startLogStream()` spawns `xcrun simctl spawn booted log stream` with correct `--level`, `--style`, and `--predicate` flags
- [ ] `enableAnalyticsDebug()` logs instructions for Xcode scheme `-FIRAnalyticsDebugEnabled` argument
- [ ] `checkToolsAvailable()` verifies `xcrun simctl` is available
- [ ] `getTroubleshootingTips()` includes Xcode Command Line Tools install instructions
- [ ] Unit tests with mocked process manager

---

## Issue 10: Create `IosDeviceLogSource`

**Labels:** enhancement, ios

**Description:**
Create `lib/src/services/log_sources/ios_device_log_source.dart` implementing `LogSourceInterface`. Uses `idevicesyslog -m "FirebaseAnalytics"` for USB/wireless devices. See `doc/IOS_SUPPORT_PLAN.md` § iOS-Specific Details > Device command.

**Acceptance Criteria:**
- [ ] `startLogStream()` spawns `idevicesyslog -m "FirebaseAnalytics"`
- [ ] Supports `--device` UDID option via `-u DEVICE_UDID`
- [ ] `checkToolsAvailable()` checks `which idevicesyslog`
- [ ] `getTroubleshootingTips()` includes `brew install libimobiledevice` instructions
- [ ] Unit tests with mocked process manager

---

## Issue 11: Implement auto-detection in `LogSourceFactory`

**Labels:** enhancement, ios

**Description:**
Wire up the auto-detection logic in `LogSourceFactory._autoDetect()`: check Android first, then iOS Simulator, then iOS Device, and prompt if multiple are found. Respect `FAMON_DEFAULT_PLATFORM` env var. See `doc/IOS_SUPPORT_PLAN.md` § Architecture > Factory and § Backward Compatibility.

**Acceptance Criteria:**
- [ ] Detection order: Android > iOS Simulator > iOS Device
- [ ] Returns single detected platform automatically
- [ ] Prompts user when multiple platforms are detected
- [ ] `FAMON_DEFAULT_PLATFORM` env var overrides auto-detection
- [ ] Default behavior (`--platform auto`) is backward-compatible

---

## Issue 12: Add `--platform` and `--device` CLI flags

**Labels:** enhancement, ios

**Description:**
Add `--platform` (`-p`) and `--device` (`-d`) options to `MonitorCommand` and `FilteredMonitorCommand`. Allowed values for `--platform`: `android`, `ios-simulator`, `ios-device`, `auto` (default). See `doc/IOS_SUPPORT_PLAN.md` § Command Changes.

**Acceptance Criteria:**
- [ ] `--platform` flag with allowed values and `auto` default
- [ ] `--device` flag for UDID/serial specification
- [ ] Both `MonitorCommand` and `FilteredMonitorCommand` support the new flags
- [ ] Troubleshooting messages are platform-appropriate
- [ ] Help text (`--help`) documents the new options

---

## Issue 13: Unit tests for iOS log parser

**Labels:** test, ios

**Description:**
Write comprehensive unit tests for `IosLogParserService` covering all three regex patterns, parameter extraction, timestamp parsing, and edge cases. See `doc/IOS_SUPPORT_PLAN.md` § Testing.

**Acceptance Criteria:**
- [ ] Test: parses standard iOS Firebase Analytics log format (event name + params)
- [ ] Test: parses "Event logged" short format
- [ ] Test: parses full timestamp format with offset
- [ ] Test: handles malformed/partial log lines gracefully
- [ ] Test: parameter values with special characters
- [ ] Test parity with Android parser test cases (cross-platform parity rule)

---

## Issue 14: Unit tests for iOS log sources

**Labels:** test, ios

**Description:**
Write unit tests for `IosSimulatorLogSource` and `IosDeviceLogSource` using mocked process managers. Verify correct command arguments, tool availability checks, and troubleshooting tips. See `doc/IOS_SUPPORT_PLAN.md` § Testing.

**Acceptance Criteria:**
- [ ] Test: simulator starts log stream with correct `xcrun simctl` arguments
- [ ] Test: device starts log stream with correct `idevicesyslog` arguments
- [ ] Test: device passes UDID when specified
- [ ] Test: `checkToolsAvailable()` returns false when tools missing
- [ ] Test: troubleshooting tips are platform-specific

---

## Issue 15: Mock-based integration tests

**Labels:** test, ios

**Description:**
Write integration tests that exercise the full pipeline: `LogSourceFactory` > platform-specific `LogSource` > platform-specific `LogParser` > `EventFormatterService`. Use mocked processes to simulate log output from each platform.

**Acceptance Criteria:**
- [ ] Test: end-to-end Android pipeline with mocked adb output
- [ ] Test: end-to-end iOS Simulator pipeline with mocked xcrun output
- [ ] Test: end-to-end iOS Device pipeline with mocked idevicesyslog output
- [ ] Test: auto-detection selects correct platform
- [ ] Test: formatted output is identical regardless of source platform (cross-platform parity)

---

## Issue 16: Update README with iOS instructions

**Labels:** documentation, ios

**Description:**
Update `README.md` with iOS support documentation: prerequisites (Xcode CLI tools, libimobiledevice), usage examples for simulator and device, debug mode setup instructions, and the new `--platform`/`--device` flags.

**Acceptance Criteria:**
- [ ] Prerequisites section lists Xcode CLI tools and libimobiledevice
- [ ] Usage examples for `--platform ios-simulator` and `--platform ios-device`
- [ ] Debug mode instructions (Xcode scheme argument `-FIRAnalyticsDebugEnabled`)
- [ ] `--device` flag documented with UDID example
- [ ] Auto-detection behavior explained
