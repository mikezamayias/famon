# Changelog

All notable changes to this package will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1](https://github.com/mikezamayias/famon/compare/v1.4.0...v1.4.1) (2026-05-07)


### Bug Fixes

* restore pub.dev publish pipeline for monorepo ([39d4a66](https://github.com/mikezamayias/famon/commit/39d4a664fcae2855a71c32cbf14e77385e5c8a7a))

## [1.4.0] - 2026-05-06

### Added

- First independent release of `famon_core` on pub.dev.
- Domain entities: `AnalyticsEvent`, `EventMetadata`, `MonitoringSession`.
- Log parsers: `LogParserService` (Android logcat), `IosLogParserService` (iOS Simulator and physical device logs).
- Event formatting via `EventFormatterService`, including `--show-only-params` filtering.
- Isar-backed persistence: `IsarEventRepository`, `IsarEventMetadataRepository`, `IsarDataExportRepository`.
- Use cases: `MonitorEventsUseCase`, `ExportDataUseCase`, `ImportDataUseCase`, `AddManualParametersUseCase`, `DataExportImportUseCase`.
- `FamonCorePackageModule` for `injectable` integration in consumer packages.

### Notes

This package was extracted from the [`famon`](https://pub.dev/packages/famon) CLI in version 1.4.0 to enable reuse across CLIs, GUIs, and other Dart tooling. Earlier history (1.0.x – 1.3.x) lives in the parent `famon` package's CHANGELOG.
