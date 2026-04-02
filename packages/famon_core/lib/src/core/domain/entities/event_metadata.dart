import 'package:equatable/equatable.dart';

/// Domain entity representing event statistics and metadata
class EventMetadata extends Equatable {
  /// Creates a new [EventMetadata].
  const EventMetadata({
    required this.eventName,
    required this.totalCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.frequency,
    this.averageParameterCount = 0,
    this.commonParameters = const {},
    this.isHidden = false,
    this.isWatched = false,
    this.customTags = const [],
  });

  /// Create from JSON for export/import
  factory EventMetadata.fromJson(Map<String, dynamic> json) {
    return EventMetadata(
      eventName: json['eventName'] as String,
      totalCount: json['totalCount'] as int,
      firstSeen: DateTime.parse(json['firstSeen'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      frequency: (json['frequency'] as num).toDouble(),
      averageParameterCount: json['averageParameterCount'] as int? ?? 0,
      commonParameters: json['commonParameters'] != null
          ? Map<String, int>.from(json['commonParameters'] as Map)
          : {},
      isHidden: json['isHidden'] as bool? ?? false,
      isWatched: json['isWatched'] as bool? ?? false,
      customTags: json['customTags'] != null
          ? List<String>.from(json['customTags'] as List)
          : [],
    );
  }

  /// The name of the event.
  final String eventName;

  /// Total number of times this event has occurred.
  final int totalCount;

  /// When this event was first recorded.
  final DateTime firstSeen;

  /// When this event was most recently recorded.
  final DateTime lastSeen;

  /// Rate of event occurrences per hour.
  final double frequency;

  /// Average number of parameters per event occurrence.
  final int averageParameterCount;

  /// Map of parameter names to their occurrence counts.
  final Map<String, int> commonParameters;

  /// Whether this event is hidden from display.
  final bool isHidden;

  /// Whether this event is being actively watched.
  final bool isWatched;

  /// User-defined tags for categorization.
  final List<String> customTags;

  /// Creates a copy of this [EventMetadata] with the given fields replaced.
  EventMetadata copyWith({
    String? eventName,
    int? totalCount,
    DateTime? firstSeen,
    DateTime? lastSeen,
    double? frequency,
    int? averageParameterCount,
    Map<String, int>? commonParameters,
    bool? isHidden,
    bool? isWatched,
    List<String>? customTags,
  }) {
    return EventMetadata(
      eventName: eventName ?? this.eventName,
      totalCount: totalCount ?? this.totalCount,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      frequency: frequency ?? this.frequency,
      averageParameterCount:
          averageParameterCount ?? this.averageParameterCount,
      commonParameters: commonParameters ?? this.commonParameters,
      isHidden: isHidden ?? this.isHidden,
      isWatched: isWatched ?? this.isWatched,
      customTags: customTags ?? this.customTags,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'totalCount': totalCount,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'frequency': frequency,
      'averageParameterCount': averageParameterCount,
      'commonParameters': commonParameters,
      'isHidden': isHidden,
      'isWatched': isWatched,
      'customTags': customTags,
    };
  }

  @override
  List<Object?> get props => [
        eventName,
        totalCount,
        firstSeen,
        lastSeen,
        frequency,
        averageParameterCount,
        commonParameters,
        isHidden,
        isWatched,
        customTags,
      ];
}
