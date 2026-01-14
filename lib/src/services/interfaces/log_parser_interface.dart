import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/models/platform_type.dart';

/// Interface for log parser service to enable dependency injection and testing
///
/// This interface follows the Dependency Inversion Principle (SOLID)
/// allowing for easy mocking and testing of components that depend on
/// log parsing functionality.
abstract class LogParserInterface {
  /// The platform this parser handles.
  ///
  /// Used to select the appropriate parser for the current log source.
  PlatformType get platform;

  /// Parse a log line into an AnalyticsEvent if it's a Firebase Analytics log
  ///
  /// [line] - A single line from adb logcat output
  /// Returns an AnalyticsEvent if the line contains Firebase Analytics
  /// data, null otherwise.
  ///
  /// Expected log format examples:
  /// - Event logs: "Logging event: event_name, Bundle[...]"
  /// - Parameter logs: "Logging event parameter: param_name, value"
  ///
  /// The parser should handle:
  /// - Malformed or incomplete log lines gracefully
  /// - Various timestamp and log level formats
  /// - Bundle parameter parsing with nested structures
  /// - Special characters and encoding issues in event names and parameters
  AnalyticsEvent? parse(String line);
}
