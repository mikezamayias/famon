import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/core/domain/entities/event_metadata.dart';
import 'package:famon/src/core/domain/value_objects/filter_criteria.dart';
import 'package:famon/src/core/domain/value_objects/session_statistics.dart';

/// Repository interface for managing analytics events
/// Follows the Repository pattern from Domain-Driven Design
abstract class EventRepository {
  /// Store a new analytics event
  Future<void> saveEvent(AnalyticsEvent event);

  /// Store multiple events efficiently
  Future<void> saveEvents(List<AnalyticsEvent> events);

  /// Retrieve events based on filtering criteria
  Future<List<AnalyticsEvent>> getEvents({
    FilterCriteria? criteria,
    int? limit,
    int? offset,
  });

  /// Get a specific event by ID
  Future<AnalyticsEvent?> getEventById(String id);

  /// Get events for a specific session
  Future<List<AnalyticsEvent>> getEventsBySession(String sessionId);

  /// Get all events (use with caution on large datasets)
  Future<List<AnalyticsEvent>> getAllEvents();

  /// Delete events based on criteria
  Future<int> deleteEvents({FilterCriteria? criteria});

  /// Delete events older than specified date
  Future<int> deleteEventsOlderThan(DateTime date);

  /// Get total count of events
  Future<int> getEventCount({FilterCriteria? criteria});

  /// Stream events in real-time (for monitoring)
  Stream<AnalyticsEvent> watchEvents({FilterCriteria? criteria});

  /// Clear all events
  Future<void> clearAllEvents();
}

/// Repository interface for managing event metadata and statistics
abstract class EventMetadataRepository {
  /// Save or update event metadata
  Future<void> saveEventMetadata(EventMetadata metadata);

  /// Get metadata for a specific event
  Future<EventMetadata?> getEventMetadata(String eventName);

  /// Get metadata for multiple events
  Future<List<EventMetadata>> getEventMetadataList({
    List<String>? eventNames,
    bool? isHidden,
    bool? isWatched,
  });

  /// Update event statistics (count, frequency, etc.)
  Future<void> updateEventStatistics(
    String eventName, {
    int? incrementCount,
    DateTime? lastSeen,
    Map<String, int>? parameterFrequencies,
  });

  /// Get events sorted by frequency
  Future<List<EventMetadata>> getEventsByFrequency({
    int? limit,
    bool descending = true,
  });

  /// Get events that should be suggested for hiding
  Future<List<String>> getSuggestedToHide({double frequencyThreshold = 10.0});

  /// Mark events as hidden or watched
  Future<void> updateEventVisibility(
    String eventName, {
    bool? isHidden,
    bool? isWatched,
  });

  /// Add custom tags to an event
  Future<void> addEventTags(String eventName, List<String> tags);

  /// Remove custom tags from an event
  Future<void> removeEventTags(String eventName, List<String> tags);

  /// Delete metadata for specific events
  Future<int> deleteEventMetadata(List<String> eventNames);

  /// Clear all metadata
  Future<void> clearAllMetadata();
}

/// Repository interface for managing monitoring sessions
abstract class SessionRepository {
  /// Save a new monitoring session
  Future<void> saveSession(String sessionId, Map<String, dynamic> sessionData);

  /// Get session data
  Future<Map<String, dynamic>?> getSession(String sessionId);

  /// Get all sessions
  Future<List<Map<String, dynamic>>> getAllSessions();

  /// Update session data
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates);

  /// Delete a session
  Future<void> deleteSession(String sessionId);

  /// Get session statistics
  Future<SessionStatistics> getSessionStatistics(String sessionId);

  /// Clear all sessions
  Future<void> clearAllSessions();
}
