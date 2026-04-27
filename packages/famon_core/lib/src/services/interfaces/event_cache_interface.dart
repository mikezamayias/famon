import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/models/session_stats.dart';

/// Interface for event cache service to enable dependency injection and testing
///
/// This interface follows the Dependency Inversion Principle (SOLID)
/// allowing for easy mocking and testing of components that depend on
/// event caching functionality.
abstract class EventCacheInterface {
  /// Add an event name to the cache
  ///
  /// [eventName] - The name of the Firebase Analytics event to cache
  /// Empty or null event names should be handled gracefully
  void addEvent(String eventName);

  /// Add a full analytics event to the cache
  ///
  /// [event] - The full analytics event to cache
  /// This also updates event name tracking
  void addFullEvent(AnalyticsEvent event);

  /// Get recent events with full data
  ///
  /// [count] - Maximum number of events to return
  /// Returns the most recent [count] events in reverse chronological order
  List<AnalyticsEvent> getRecentEvents(int count);

  /// Get all unique event names seen in the current session
  ///
  /// Returns an immutable list of event names sorted alphabetically
  List<String> get allEventNames;

  /// Get event names sorted by frequency (most common first)
  ///
  /// Returns an immutable list of event names ordered by frequency
  List<String> getEventsByFrequency();

  /// Get count for a specific event
  ///
  /// [eventName] - The event name to get the count for
  /// Returns 0 if the event has not been seen
  int getEventCount(String eventName);

  /// Get top N most frequent events
  ///
  /// [count] - Number of top events to return (must be >= 0)
  /// Returns an immutable list containing up to [count] event names
  List<String> getTopEvents(int count);

  /// Search for events matching a pattern (case-insensitive)
  ///
  /// [pattern] - Regular expression pattern to search for
  /// Returns an immutable list of matching event names
  /// Returns empty list for invalid patterns or empty input
  List<String> searchEvents(String pattern);

  /// Get suggested events to hide (e.g., very frequent ones)
  ///
  /// Returns an immutable list of event names that occur frequently
  /// and might be considered "noisy" for debugging purposes
  List<String> getSuggestedToHide();

  /// Clear the cache (useful for testing or session reset)
  ///
  /// Removes all cached event names and their counts
  void clear();

  /// Get session statistics
  ///
  /// Returns a [SessionStats] object containing:
  /// - totalUniqueEvents: Number of unique events seen
  /// - totalEventOccurrences: Total count of all events
  /// - mostFrequentEvent: Name of the most frequent event (or null)
  SessionStats getSessionStats();
}
