# famon_core

[![pub package](https://img.shields.io/pub/v/famon_core.svg)](https://pub.dev/packages/famon_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![style: very_good_analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

Core library for Firebase Analytics event parsing, formatting, and persistence. Powers the [`famon`](https://pub.dev/packages/famon) CLI and is reusable in other Dart and Flutter applications.

## What's included

- **Domain and value objects** — `AnalyticsEvent`, `EventMetadata`, `MonitoringSession`, filter criteria, and statistics types
- **Log parsers** — `LogParserService` for Android logcat and `IosLogParserService` for iOS Simulator and physical device logs
- **Event formatting** — `EventFormatterService` for human-readable output
- **Use cases and repositories** — monitoring, import/export, manual parameters, repository interfaces, and Isar-backed implementations
- **Filtering and caching** — `EventFilterService`, `EventCacheService`, and `EventFilterUtils`
- **Supporting APIs** — log sources, parser interfaces, timestamp parsing, warning buffering, platform/session models, and parsing exceptions
- **DI module** — `FamonCorePackageModule` for `injectable` integration

## Installation

```bash
dart pub add famon_core
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  famon_core: ^1.4.1
```

## Stability

`famon_core` is published as a reusable package. Public exports are treated as compatibility-sensitive: APIs will not be removed or renamed within the `1.x` line without a documented migration path. Breaking changes are reserved for a future `2.0.0`.

`famon_core` intentionally avoids terminal UI concerns. Keep argument parsing, ANSI rendering, keyboard shortcuts, clipboard integration, file dialogs, and command-specific logging in the [`famon`](https://pub.dev/packages/famon) package. Put reusable parsing, filtering, persistence, and monitoring behavior here.

### API stability classification

Every name listed below is exported from `package:famon_core/famon_core.dart`. The classification reflects current implementation maturity, not import path.

#### Stable

These APIs have a stable contract within `1.x`. Behavior may evolve but signatures will not break.

| API | Purpose |
|---|---|
| `LogParserService` | Android logcat parser |
| `IosLogParserService` | iOS Simulator / device log parser |
| `LogParserFactory` | Platform-aware parser construction |
| `EventFormatterService` | Human-readable event rendering |
| `AnalyticsEvent` | Parsed event domain model |
| `EventMetadata` | Per-event-name metadata aggregate |
| `EventRepository` / `IsarEventRepository` | Event persistence contract + Isar impl |
| `EventMetadataRepository` / `IsarEventMetadataRepository` | Metadata persistence contract + Isar impl |
| `DataExportRepository` / `IsarDataExportRepository` | Backup / restore contract + Isar impl |
| `ImportDataUseCase`, `ExportDataUseCase`, `DataExportImportUseCase` | Import / export orchestration |
| `EventFilterService`, `EventFilterUtils`, `FilterCriteria` | Filter pipeline |
| `LogEventProcessor` + `LogEventProcessResult` (sealed: `LogEventResult`, `LogVerboseResult`, `LogDiscardedResult`) | Host-agnostic parse + filter primitive |
| `ItemArrayParser` | Shared `items=[...]` depth-tracking + strip / extract helpers for both platforms' parsers |
| `EventCacheService` / `EventCacheInterface` | In-memory event cache |
| `EventStatistics`, `SessionStats`, `PlatformType` | Value objects |
| `LogSourceFactory` / `LogSourceInterface` / `LogParserInterface` | Log source abstractions |
| `LogTimestampParser` | Shared timestamp parsing helper |
| `FaWarningBuffer` | Firebase Analytics warning aggregation |
| `ParsingException` | Domain exception type |
| `DatabaseDirectoryResolver`, `IsarDatabase`, `IsarAnalyticsEvent`, `IsarEventMetadata`, `IsarSessionData` | Persistence wiring |
| `FamonCorePackageModule` (via `core_injection.dart`) | `injectable` DI module |

#### Public but needs hardening

These APIs are exported and consumers may depend on them, but the implementations are incomplete or under-tested. Public signatures will be preserved within `1.x`; semantics will be tightened in follow-up releases.

| API | Hardening needed |
|---|---|
| `AddManualParametersUseCase` | Manual-parameter persistence is currently a no-op. Will be backed by `EventMetadataRepository` (or a dedicated store) and gain integration tests in a follow-up. |
| `MonitorEventsUseCase` | Not currently consumed by the CLI; lacks integration tests against real log streams. |
| `MonitoringSession`, `SessionStatistics` | Session domain types are stable in shape but persistence is incomplete (no `SessionRepository` implementation yet). |
| `SessionRepository` | Interface defined; no concrete implementation ships with `1.x`. Either an `IsarSessionRepository` will land or the interface will be marked experimental in `1.x` and removed in `2.0`. |

#### Internal / legacy candidates

These exports are slated for removal in `2.0`. They remain exported in `1.x` for compatibility; new code should not rely on them.

| API | Reason |
|---|---|
| `EventSummary` | Orphan Isar `@collection` model — not referenced by any repository, use case, or command. Tracked for removal in PLAN.md Phase 0. |

### Short-term priorities

- Implement or formally retire `SessionRepository`.
- Make `AddManualParametersUseCase` truthful (persist + retrieve).
- Strengthen parser and filtering tests across Android and iOS log formats.
- Keep persistence and import / export behavior usable outside the CLI.

## Usage

```dart
import 'package:famon_core/famon_core.dart';

void main() {
  final parser = LogParserService();
  final event = parser.parse(
    '11-15 10:23:45.123 12345 12345 V FA      : Logging event: '
    'origin=app,name=screen_view,params=Bundle[{firebase_screen_class=HomeScreen}]',
  );

  if (event != null) {
    print('Event: ${event.eventName}');
    print('Params: ${event.parameters}');
  }
}
```

For full CLI usage, see [`famon`](https://pub.dev/packages/famon).

## Architecture

`famon_core` follows a layered domain-driven design. The main top-level groupings under `lib/src/`:

```text
lib/src/
├── constants.dart      # Shared constants
├── core/
│   ├── domain/         # Entities, value objects, repository interfaces
│   ├── application/    # Use cases, application services
│   └── infrastructure/ # Isar implementations
├── core_injection.dart # injectable module entry point
├── exceptions/         # Domain-specific exceptions
├── models/             # Plain data classes
├── services/           # Parsers, formatters, caches
├── shared/             # Cross-cutting utilities
└── utils/              # Pure helpers (filtering, etc.)
```

The CLI in [`famon`](https://pub.dev/packages/famon) is a thin frontend; all business logic lives here.

## Cross-platform parity

Android and iOS log parsers must produce identical `AnalyticsEvent` output for the same logical event. Bug fixes and feature additions ship across all platforms simultaneously. See `CLAUDE.md` in the repository for details.

## License

MIT — see [LICENSE](LICENSE).
