import 'package:equatable/equatable.dart';

/// Typed class representing session statistics
class SessionStats extends Equatable {
  /// Creates a new SessionStats instance
  const SessionStats({
    required this.totalUniqueEvents,
    required this.totalEventOccurrences,
    this.mostFrequentEvent,
  });

  /// The number of unique event types seen in the session.
  final int totalUniqueEvents;

  /// The total count of all events observed in the session.
  final int totalEventOccurrences;

  /// The name of the most frequently occurring event, if any.
  final String? mostFrequentEvent;

  @override
  List<Object?> get props => [
        totalUniqueEvents,
        totalEventOccurrences,
        mostFrequentEvent,
      ];

  @override
  String toString() => 'SessionStats('
      'totalUniqueEvents: $totalUniqueEvents, '
      'totalEventOccurrences: $totalEventOccurrences, '
      'mostFrequentEvent: $mostFrequentEvent)';
}
