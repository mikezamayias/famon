import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';

/// Interface for event formatting service to enable dependency injection
/// and testing.
///
/// This interface follows the Dependency Inversion Principle (SOLID),
/// allowing for easy mocking and testing of components that depend on
/// event formatting functionality.
abstract class EventFormatterInterface {
  /// Formats and prints the given [event] to the console.
  ///
  /// Handles FA warning buffering and respects output format settings.
  void formatAndPrint(AnalyticsEvent event);

  /// Flushes any pending accumulated FA warnings to the output.
  ///
  /// Call this before exiting or when you want to ensure all buffered
  /// warnings are displayed.
  void flushPending();

  /// Resets the internal state used for tracking FA warning buffering.
  ///
  /// Call this when starting a new monitoring session.
  void resetTracking();

  /// Prints the provided [stats] to the console.
  ///
  /// [stats] should contain:
  /// - `totalEvents`: Total number of events
  /// - `uniqueEventTypes`: Number of unique event types
  /// - `topEvents`: Map of event names to occurrence counts (optional)
  void printStats(Map<String, dynamic> stats);

  /// Prints an error [message] with appropriate formatting.
  void printError(String message);

  /// Prints a success [message] with appropriate formatting.
  void printSuccess(String message);

  /// Prints an informational [message] with appropriate formatting.
  void printInfo(String message);

  /// Prints a warning [message] with appropriate formatting.
  void printWarning(String message);
}
