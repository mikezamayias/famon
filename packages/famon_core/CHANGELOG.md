# Changelog

All notable changes to this package will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.5.0) (2026-05-17)

### Added

- `LogEventProcessor` — host-agnostic primitive that combines log-line parsing and event filtering. Pair with `LogParserService` (Android) or `IosLogParserService` (iOS).
- Sealed `LogEventProcessResult` family with three variants: `LogEventResult`, `LogVerboseResult`, `LogDiscardedResult`. Pattern-match on results in any host (CLI, GUI, server, CI lint).
- `ItemArrayParser` — shared `items=[...]` depth-tracking + strip / extract helpers used by both Android and iOS parsers internally, exposed as Stable public API for downstream tooling that needs to mirror the same truncation contract.
- `MonitoringPipeline` — host-agnostic stream pipeline. Consumes a child process's `stdout` / `stderr`, drains stderr, decodes UTF-8 with malformed-aware rate-limited warnings, and emits structured `LogEventProcessResult` values to a callback. Free of `mason_logger`, terminal, ANSI, clipboard, and process-lifecycle dependencies.

### Changed

- README now classifies every export from `package:famon_core/famon_core.dart` as **Stable**, **Public but needs hardening**, or **Internal / legacy candidate**, with each row stating what compatibility guarantees it carries within the `1.x` line.

### Internal

- Widened the `injectable` constraint to `>=2.3.5 <4.0.0`. Local solver still resolves to 2.7.x because `isar_generator` pins `source_gen ^1.2.2`. The concrete `injectable` 3.x upgrade arrives with the Isar → Drift migration.

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
