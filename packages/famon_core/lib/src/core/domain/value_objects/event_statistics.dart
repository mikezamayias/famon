/// Statistics for analytics events.
class EventStatistics {
  /// Creates a new [EventStatistics].
  EventStatistics({
    required this.totalEvents,
    required this.uniqueEventTypes,
    required this.topEvents,
    this.dateRange,
  });

  /// Creates an [EventStatistics] from a JSON map.
  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    DateTimeRange? dateRange;
    final dateRangeJson = json['dateRange'] as Map<String, dynamic>?;
    if (dateRangeJson != null) {
      dateRange = DateTimeRange(
        start: DateTime.parse(dateRangeJson['start'] as String),
        end: DateTime.parse(dateRangeJson['end'] as String),
      );
    }

    return EventStatistics(
      totalEvents: json['totalEvents'] as int,
      uniqueEventTypes: json['uniqueEventTypes'] as int,
      topEvents: Map<String, int>.from(json['topEvents'] as Map),
      dateRange: dateRange,
    );
  }

  /// The total count of events.
  final int totalEvents;

  /// The number of unique event types.
  final int uniqueEventTypes;

  /// Map of event names to their occurrence counts.
  final Map<String, int> topEvents;

  /// The date range covered by these events.
  final DateTimeRange? dateRange;

  /// Converts this [EventStatistics] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalEvents': totalEvents,
      'uniqueEventTypes': uniqueEventTypes,
      'topEvents': topEvents,
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
    };
  }
}

/// A range between two [DateTime] values.
class DateTimeRange {
  /// Creates a new [DateTimeRange] with the given [start] and [end].
  ///
  /// Throws [ArgumentError] if [start] is after [end].
  DateTimeRange({required this.start, required this.end}) {
    if (start.isAfter(end)) {
      throw ArgumentError('start must be before or equal to end');
    }
  }

  /// The start of the range.
  final DateTime start;

  /// The end of the range.
  final DateTime end;
}
