import 'dart:collection';

import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/models/session_stats.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// In-memory cache service for tracking unique event names
/// and providing smart suggestions for filtering.
///
/// This service includes memory bounds to prevent unbounded growth during
/// long-running monitoring sessions. When the cache reaches its maximum size,
/// the least frequently used events are evicted.
@LazySingleton(as: EventCacheInterface)
class EventCacheService implements EventCacheInterface {
  /// Creates a new EventCacheService.
  EventCacheService({
    Logger? logger,
  }) : _logger = logger;

  /// Default maximum cache size for event tracking.
  static const int defaultMaxCacheSize = 10000;

  /// Maximum number of full events to store for export.
  static const int maxRecentEvents = 1000;

  final Logger? _logger;
  final Set<String> _uniqueEventNames = <String>{};
  final Map<String, int> _eventCounts = <String, int>{};

  /// Circular buffer for recent full events.
  final Queue<AnalyticsEvent> _recentEvents = Queue<AnalyticsEvent>();

  @override
  void addEvent(String eventName) {
    if (eventName.isEmpty) return; // Guard against empty event names

    // If the event is already tracked, just update the count
    if (_eventCounts.containsKey(eventName)) {
      _eventCounts[eventName] = _eventCounts[eventName]! + 1;
      return;
    }

    // If we're at capacity, evict the least frequent event
    if (_uniqueEventNames.length >= defaultMaxCacheSize) {
      _evictLeastFrequent();
    }

    _uniqueEventNames.add(eventName);
    _eventCounts[eventName] = 1;
  }

  @override
  void addFullEvent(AnalyticsEvent event) {
    // Also track by event name
    addEvent(event.eventName);

    // Add to recent events buffer
    _recentEvents.add(event);

    // Maintain bounded size
    while (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeFirst();
    }
  }

  @override
  List<AnalyticsEvent> getRecentEvents(int count) {
    if (count <= 0) return [];

    // Return events in reverse order (most recent first)
    final events = _recentEvents.toList().reversed.take(count).toList();
    return List.unmodifiable(events);
  }

  /// Evicts the least frequently used event from the cache.
  ///
  /// This maintains bounded memory usage during long monitoring sessions.
  void _evictLeastFrequent() {
    if (_eventCounts.isEmpty) return;

    // Find the event with the lowest count
    String? leastFrequentEvent;
    var lowestCount = -1;
    for (final entry in _eventCounts.entries) {
      if (lowestCount < 0 || entry.value < lowestCount) {
        lowestCount = entry.value;
        leastFrequentEvent = entry.key;
      }
    }

    if (leastFrequentEvent != null) {
      _uniqueEventNames.remove(leastFrequentEvent);
      _eventCounts.remove(leastFrequentEvent);
      _logger?.detail(
        'Cache full: evicted least frequent event "$leastFrequentEvent" '
        '(count: $lowestCount)',
      );
    }
  }

  @override
  List<String> get allEventNames =>
      List.unmodifiable(_uniqueEventNames.toList()..sort());

  @override
  List<String> getEventsByFrequency() {
    final entries = _eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return List.unmodifiable(entries.map((e) => e.key));
  }

  @override
  int getEventCount(String eventName) => _eventCounts[eventName] ?? 0;

  @override
  List<String> getTopEvents(int count) {
    if (count < 0) return [];
    return List.unmodifiable(getEventsByFrequency().take(count));
  }

  @override
  List<String> searchEvents(String pattern) {
    if (pattern.isEmpty) return [];

    try {
      final regex = RegExp(pattern, caseSensitive: false);
      return List.unmodifiable(
        _uniqueEventNames.where(regex.hasMatch).toList()..sort(),
      );
    } on Object catch (e) {
      _logger?.detail('Invalid regex pattern in searchEvents: $e');
      return [];
    }
  }

  @override
  List<String> getSuggestedToHide() {
    return List.unmodifiable(
      _eventCounts.entries
          .where((entry) => entry.value > defaultHideThreshold)
          .map((entry) => entry.key),
    );
  }

  @override
  void clear() {
    _uniqueEventNames.clear();
    _eventCounts.clear();
    _recentEvents.clear();
  }

  @override
  SessionStats getSessionStats() {
    return SessionStats(
      totalUniqueEvents: _uniqueEventNames.length,
      totalEventOccurrences:
          _eventCounts.values.fold<int>(0, (sum, count) => sum + count),
      mostFrequentEvent: _eventCounts.isNotEmpty
          ? _eventCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    );
  }
}
