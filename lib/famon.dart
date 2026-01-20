/// Firebase Analytics Monitor - Real-time monitoring of Firebase Analytics
/// events from Android logcat.
///
/// This library provides tools for parsing and formatting Firebase Analytics
/// events captured from `adb logcat`.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:famon/firebase_analytics_monitor.dart';
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
/// dart pub global activate firebase_analytics_monitor
///
/// # Monitor events
/// famon monitor
///
/// # Filter events
/// famon monitor --hide screen_view --show-only my_event
/// ```
library;

// Core domain entity
export 'src/core/domain/entities/analytics_event.dart';
// Session statistics model
export 'src/models/session_stats.dart';
// Services for parsing and formatting
export 'src/services/event_formatter_service.dart';
export 'src/services/log_parser_service.dart';
