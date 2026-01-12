import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/models/session_stats.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// In-memory cache service for tracking unique event names
/// and providing smart suggestions for filtering
@LazySingleton(as: EventCacheInterface)
class EventCacheService implements EventCacheInterface {
  /// Creates a new EventCacheService
  EventCacheService({Logger? logger}) : _logger = logger;

  final Logger? _logger;
  final Set<String> _uniqueEventNames = <String>{};
  final Map<String, int> _eventCounts = <String, int>{};

  @override
  void addEvent(String eventName) {
    if (eventName.isEmpty) return; // Guard against empty event names

    _uniqueEventNames.add(eventName);
    _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
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
