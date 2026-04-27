# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-04-02

### Added
- `--show-only-params` / `-P` flag to filter which parameter keys are displayed (applies to `parameters` and `items`, in formatted and raw modes, on both `monitor` and `filter` commands)
- 16 unit tests for `IssueCommand` template builder (`_generateIssueBody`)
- 7 unit tests for `EventFormatterService` show-only-params filtering

### Fixed
- Orphaned "Items:" header no longer appears when all items are filtered by `--show-only-params`
- Consistent feedback message for `--show-only-params` across `monitor` and `filter` commands

## [1.2.0] - 2026-03-13

### Added
- `famon issue` command for bug reporting with system info and log collection

### Fixed
- `q` and Ctrl+C now quit without delay
- Native Firebase events in `Logging event (FE)` format now parsed correctly

## [1.1.1] - 2026-03-02

### Added
- Codecov integration; coverage badge now links to live report

## [1.1.0] - 2026-03-02

### Added
- Separate global (session-level) parameters from event-specific parameters in output
- `toggle_event_params` and `toggle_global_params` keyboard actions
- Formatter support for global vs. event parameter distinction

### Fixed
- Items array parsing for nested bundles on Android (`LogParserService`) and iOS (`IosLogParserService`)

## [1.0.3] - 2026-01-24

### Security
- SEC-001: Package name validation in `enableAnalyticsDebug()` to prevent command injection
- SEC-003: File size limits (100MB) and schema validation for JSON imports
- SEC-006: Chunked import processing (1000 records/transaction) to prevent memory exhaustion

### Added
- Security audit documentation (`doc/SECURITY_AUDIT.md`)
- Input validation patterns for external data handling

### Changed
- Import operations validate JSON structure before processing

## [1.0.2] - 2026-01-24

### Added
- pub.dev badge and link in README

## [1.0.1] - 2026-01-20

### Added
- Example file for pub.dev documentation

### Fixed
- Static analysis warnings in generated files

## [1.0.0] - 2026-01-20

### Changed
- Package renamed from `firebase_analytics_monitor` to `famon`
- Install: `dart pub global activate famon`
- Repository: `github.com/mikezamayias/famon`
- Internal class names updated (e.g. `FamonCommandRunner`)

**Migrating from firebase_analytics_monitor:**
```bash
dart pub global deactivate firebase_analytics_monitor
dart pub global activate famon
```

---

## Previous releases (as firebase_analytics_monitor)

## [1.3.3] - 2026-01-20

### Fixed
- Update message showed wrong command (`firebase_analytics_monitor update` instead of `famon update`)
- Version display always showed `1.1.0` regardless of installed version

### Added
- `tool/update_version.dart` script to keep pubspec.yaml and version.dart in sync

## [1.3.2] - 2026-01-16

### Changed
- Added `firebase-debug.log` to `.gitignore`

## [1.3.1] - 2026-01-16

### Security
- Fixed command injection in ClipboardService (Windows) — use stdin instead of command arguments
- Fixed command injection in FileDialogService (macOS) — escape AppleScript strings
- Added ReDoS protection in `EventCacheService.searchEvents()` with pattern length limits and dangerous pattern detection

### Performance
- RegExp patterns in `IosLogParserService._extractTimestamp()` and `_cleanValue()` moved to `static final`
- Fallback substring search when regex is deemed unsafe

### Removed
- Unused `ActionResult` class from `shortcut_action.dart`

## [1.3.0] - 2026-01-16

### Added
- Interactive keyboard shortcuts during monitoring sessions:
  - `s` — copy recent events to clipboard
  - `f` — save events to file
  - `p` — toggle pause/resume
  - `t` — show session statistics
  - `c` — clear screen
  - `?` — show help overlay
  - `q` — quit
- Customizable shortcuts via `~/.famon/shortcuts.yaml`
- `ShortcutManager`, `ActionRegistry`, `KeyboardInputService`

## [1.2.0] - 2026-01-15

### Added
- iOS support: simulators via `xcrun simctl spawn`, physical devices via `idevicesyslog`
- `--platform` flag (`android`, `ios-simulator`, `ios-device`)
- iOS log parsing with multiple timestamp format support

### Performance
- All regex patterns moved to `static final` across the codebase
- `EventCacheService` memory bound with LRU eviction (max 10,000 events)
- Graceful shutdown and resource cleanup for long-running sessions
- stderr consumed to prevent buffer overflow

### Changed
- Android log handling refactored into dedicated services
- `LogSourceFactory` and `LogParserFactory` for platform-specific implementations
- `PlatformType` enum for type-safe platform selection

## [1.1.0] - 2026-01-13

### Security
- Input validation for custom parameters and frequency options
- File path validation to prevent path traversal
- Null handling for `stdin.readLineSync()`
- Safe type casting in `DatabaseCommand`
- Validation added to `DateTimeRange` constructor

### Changed
- Replaced broad exception handling with specific types
- `MonitorCommand.run()` split into focused methods
- Event filtering logic consolidated in `EventFilterUtils`
- `FilteredMonitorDependencies` container for DI
- `FaWarningBuffer` extracted from `EventFormatterService`
- `DatabaseDirectoryResolver` extracted from `IsarDatabase`
- Magic numbers replaced with named constants
- Consistent DI for `UpdateCommand`
- Log parser regex evaluation order optimized
- Event filtering pushed to database level

### Added
- Warning for malformed UTF-8 in logcat output
- Visible warnings for parameter parsing failures
- Tests for `FilteredMonitorCommand`

### Fixed
- Branch name in static analysis workflow
- Minimum test coverage threshold raised to 30%

## [1.0.2] - 2026-01-12

### Fixed
- Generated files (`*.g.dart`, `*.config.dart`) now included so `dart pub global activate firebase_analytics_monitor` works correctly

## [1.0.1] - 2025-12-19

### Added
- MIT LICENSE file
- CHANGELOG.md
- GitHub Actions workflow for static analysis on PRs to dev

### Changed
- Example output in README uses generic event names

## [1.0.0] - 2025-12-19

### Added
- Real-time Firebase Analytics monitoring via `adb logcat`
- `--hide` and `--show-only` filtering
- Colorized output
- Session statistics and filter suggestions
- Parameter and item array parsing
- `famon monitor` and `famon help` commands
- Shell completion
- Isar-backed persistent event storage
- Export/import functionality
