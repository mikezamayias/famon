/// Firebase Analytics Monitor - Real-time monitoring of Firebase Analytics
/// events from Android logcat.
///
/// This library re-exports core types from `famon_core` for backward
/// compatibility. The business logic lives in the `famon_core` package;
/// this package provides the CLI frontend.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:famon/famon.dart';
///
/// // Parse a logcat line
/// final parser = LogParserService();
/// final event = parser.parse(logcatLine);
///
/// if (event != null) {
///   print('Event: ${event.eventName}');
///   print('Parameters: ${event.parameters}');
/// }
/// ```
///
/// ## CLI Usage
///
/// ```bash
/// # Install globally
/// dart pub global activate famon
///
/// # Monitor events
/// famon monitor
///
/// # Filter events
/// famon monitor --hide screen_view --show-only my_event
/// ```
library;

// Re-export core types for backward compatibility
export 'package:famon_core/famon_core.dart';
