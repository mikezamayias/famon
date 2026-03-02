import 'package:equatable/equatable.dart';

/// Value object representing session statistics.
class SessionStatistics extends Equatable {
  /// Creates a new [SessionStatistics].
  const SessionStatistics({
    required this.totalEvents,
    required this.uniqueEvents,
    required this.averageFrequency,
    required this.topEvents,
    required this.sessionDuration,
    required this.eventTypeDistribution,
    this.peakHour,
    this.mostActiveEvents = const [],
  });

  /// Create from JSON for export/import
  factory SessionStatistics.fromJson(Map<String, dynamic> json) {
    return SessionStatistics(
      totalEvents: json['totalEvents'] as int,
      uniqueEvents: json['uniqueEvents'] as int,
      averageFrequency: (json['averageFrequency'] as num).toDouble(),
      topEvents: (json['topEvents'] as List)
          .map((e) => EventFrequency.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionDuration: Duration(milliseconds: json['sessionDurationMs'] as int),
      eventTypeDistribution: Map<String, int>.from(
        json['eventTypeDistribution'] as Map,
      ),
      peakHour: json['peakHour'] as int?,
      mostActiveEvents: List<String>.from(
        json['mostActiveEvents'] as List? ?? [],
      ),
    );
  }

  /// Total number of events in the session.
  final int totalEvents;

  /// Number of unique event types.
  final int uniqueEvents;

  /// Average event frequency (events per hour).
  final double averageFrequency;

  /// List of top events by frequency.
  final List<EventFrequency> topEvents;

  /// Duration of the monitoring session.
  final Duration sessionDuration;

  /// Distribution of event types (event name to count).
  final Map<String, int> eventTypeDistribution;

  /// Hour of day with most events (0-23).
  final int? peakHour;

  /// Event names with highest activity.
  final List<String> mostActiveEvents;

  /// Events per minute during the session.
  double get eventsPerMinute => sessionDuration.inMinutes > 0
      ? totalEvents / sessionDuration.inMinutes
      : 0.0;

  /// Ratio of unique events to total events.
  double get uniqueEventRatio =>
      totalEvents > 0 ? uniqueEvents / totalEvents : 0.0;

  /// Creates a copy of this [SessionStatistics] with the given fields replaced.
  SessionStatistics copyWith({
    int? totalEvents,
    int? uniqueEvents,
    double? averageFrequency,
    List<EventFrequency>? topEvents,
    Duration? sessionDuration,
    Map<String, int>? eventTypeDistribution,
    int? peakHour,
    List<String>? mostActiveEvents,
  }) {
    return SessionStatistics(
      totalEvents: totalEvents ?? this.totalEvents,
      uniqueEvents: uniqueEvents ?? this.uniqueEvents,
      averageFrequency: averageFrequency ?? this.averageFrequency,
      topEvents: topEvents ?? this.topEvents,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      eventTypeDistribution:
          eventTypeDistribution ?? this.eventTypeDistribution,
      peakHour: peakHour ?? this.peakHour,
      mostActiveEvents: mostActiveEvents ?? this.mostActiveEvents,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'totalEvents': totalEvents,
      'uniqueEvents': uniqueEvents,
      'averageFrequency': averageFrequency,
      'topEvents': topEvents.map((e) => e.toJson()).toList(),
      'sessionDurationMs': sessionDuration.inMilliseconds,
      'eventTypeDistribution': eventTypeDistribution,
      'peakHour': peakHour,
      'mostActiveEvents': mostActiveEvents,
    };
  }

  @override
  List<Object?> get props => [
        totalEvents,
        uniqueEvents,
        averageFrequency,
        topEvents,
        sessionDuration,
        eventTypeDistribution,
        peakHour,
        mostActiveEvents,
      ];
}

/// Value object representing event frequency data.
class EventFrequency extends Equatable {
  /// Creates a new [EventFrequency].
  const EventFrequency({
    required this.eventName,
    required this.count,
    required this.frequency,
    required this.percentage,
  });

  /// Create from JSON for export/import
  factory EventFrequency.fromJson(Map<String, dynamic> json) {
    return EventFrequency(
      eventName: json['eventName'] as String,
      count: json['count'] as int,
      frequency: (json['frequency'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  /// The name of the event.
  final String eventName;

  /// Total count of this event.
  final int count;

  /// Frequency rate (events per hour).
  final double frequency;

  /// Percentage of total events.
  final double percentage;

  /// Creates a copy of this [EventFrequency] with the given fields replaced.
  EventFrequency copyWith({
    String? eventName,
    int? count,
    double? frequency,
    double? percentage,
  }) {
    return EventFrequency(
      eventName: eventName ?? this.eventName,
      count: count ?? this.count,
      frequency: frequency ?? this.frequency,
      percentage: percentage ?? this.percentage,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'count': count,
      'frequency': frequency,
      'percentage': percentage,
    };
  }

  @override
  List<Object?> get props => [eventName, count, frequency, percentage];
}
