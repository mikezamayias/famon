# famon_core

[![pub package](https://img.shields.io/pub/v/famon_core.svg)](https://pub.dev/packages/famon_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![style: very_good_analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

Core library for Firebase Analytics event parsing, formatting, and persistence. Powers the [`famon`](https://pub.dev/packages/famon) CLI and is reusable in other Dart and Flutter applications (for example a future GUI client).

## What's included

- **Domain entities** — `AnalyticsEvent`, `EventMetadata`, `MonitoringSession`
- **Log parsers** — `LogParserService` (Android logcat), `IosLogParserService` (iOS Simulator and physical device logs)
- **Event formatting** — `EventFormatterService` for human-readable output
- **Persistence** — Isar-backed repositories for events, metadata, and exports
- **Filtering and caching** — `EventFilterService`, `EventCacheService`
- **Use cases** — `MonitorEventsUseCase`, `ExportDataUseCase`, `ImportDataUseCase`, `AddManualParametersUseCase`, `DataExportImportUseCase`
- **DI module** — `FamonCorePackageModule` for `injectable` integration

## Installation

```bash
dart pub add famon_core
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  famon_core: ^1.4.0
```

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

`famon_core` follows a layered domain-driven design:

```
lib/src/
├── core/
│   ├── domain/         # Entities, value objects, repository interfaces
│   ├── application/    # Use cases, application services
│   └── infrastructure/ # Isar implementations
├── services/           # Parsers, formatters, caches
├── models/             # Plain data classes
├── shared/             # Cross-cutting utilities
└── exceptions/         # Domain-specific exceptions
```

The CLI in [`famon`](https://pub.dev/packages/famon) is a thin frontend; all business logic lives here.

## Cross-platform parity

Android and iOS log parsers must produce identical `AnalyticsEvent` output for the same logical event. Bug fixes and feature additions ship across all platforms simultaneously. See `CLAUDE.md` in the repository for details.

## License

MIT — see [LICENSE](LICENSE).
