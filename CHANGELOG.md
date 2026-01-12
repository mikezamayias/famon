# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
