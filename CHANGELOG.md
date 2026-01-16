# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2026-01-16

### Security

- Fixed command injection vulnerability in ClipboardService (Windows) by using stdin instead of command arguments
- Fixed command injection vulnerability in FileDialogService (macOS) by escaping AppleScript strings
- Added ReDoS protection in EventCacheService.searchEvents() with pattern length limits and dangerous pattern detection

### Performance

- Extracted RegExp patterns to static final in IosLogParserService for `_extractTimestamp()` and `_cleanValue()` methods
- Added fallback substring search when regex patterns are deemed unsafe

### Removed

- Removed unused `ActionResult` class from shortcut_action.dart

## [1.3.0] - 2026-01-16

### Added

- Interactive keyboard shortcuts for monitoring sessions:
  - `s` - Copy recent events to clipboard
  - `f` - Save events to file
  - `p` - Toggle pause/resume monitoring
  - `t` - Show session statistics
  - `c` - Clear screen
  - `?` - Show help overlay
  - `q` - Quit monitoring
- Customizable keyboard shortcuts via `~/.famon/shortcuts.yaml`
- `ShortcutManager` for handling key bindings and action execution
- `ActionRegistry` for registering and managing keyboard actions
- `KeyboardInputService` for raw terminal input handling

## [1.2.0] - 2026-01-15

### Added

- **iOS Support**: Monitor Firebase Analytics events from iOS simulators and physical devices
  - iOS Simulator support via `xcrun simctl spawn`
  - Physical iOS device support via `idevicesyslog`
  - New `--platform` option to select target platform (android, ios-simulator, ios-device)
  - iOS-specific log parsing with support for various timestamp formats
  - Troubleshooting tips for iOS tool installation
- Documentation for iOS monitoring setup in README

### Performance

- Made all regex patterns static final across the codebase
- Added memory bounds to EventCacheService with LRU eviction (max 10,000 events)
- Added graceful shutdown and resource management for long-running sessions
- Improved stderr handling to prevent buffer overflow

### Changed

- Refactored Android log handling into dedicated services for better separation of concerns
- Introduced `LogSourceFactory` and `LogParserFactory` for platform-specific implementations
- Added `PlatformType` enum for type-safe platform selection

## [1.1.0] - 2026-01-13

### Security

- Added input validation for custom parameters and frequency options
- Added file path validation to prevent path traversal attacks
- Added explicit null handling for stdin.readLineSync()
- Added safe type casting for argResults in DatabaseCommand
- Added validation to DateTimeRange constructor

### Changed

- Replaced overly broad exception handling with specific types
- Extracted MonitorCommand.run() into smaller focused methods
- Consolidated event filtering logic in EventFilterUtils
- Introduced FilteredMonitorDependencies container for better DI
- Extracted FaWarningBuffer from EventFormatterService (SRP)
- Extracted DatabaseDirectoryResolver from IsarDatabase
- Replaced hardcoded magic numbers with named constants
- Used consistent DI for UpdateCommand
- Optimized log parser regex evaluation order
- Pushed event filtering to database level for better performance
- Optimized list creation in EventCacheService

### Added

- Warning for malformed UTF-8 data in logcat output
- Visible warnings for parameter parsing failures
- Comprehensive tests for FilteredMonitorCommand

### Fixed

- Corrected branch name in static analysis workflow
- Increased minimum test coverage threshold to 30%

## [1.0.2] - 2026-01-12

### Fixed

- Fixed package installation from pub.dev by including generated files (`*.g.dart`, `*.config.dart`)
- Package can now be properly installed via `dart pub global activate firebase_analytics_monitor`

## [1.0.1] - 2025-12-19

### Changed

- Replaced specific event examples with generic event names in documentation
- Improved example output in README to be more generic

### Added

- MIT LICENSE file
- CHANGELOG.md following Keep a Changelog format
- GitHub Actions workflow for static analysis on PRs to dev branch

## [1.0.0] - 2025-12-19

### Added

- Real-time Firebase Analytics event monitoring via `adb logcat`
- Smart filtering with `--hide` and `--show-only` options
- Beautiful colorized output for events
- Session statistics and smart suggestions for filtering
- Event parsing with support for parameters and item arrays
- `famon monitor` command for real-time event streaming
- `famon help` command with detailed usage examples
- Shell completion support
- Persistent event storage with Isar database
- Export/import functionality for event data
