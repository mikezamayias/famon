import 'package:equatable/equatable.dart';
import 'package:firebase_analytics_monitor/src/shared/log_timestamp_parser.dart';

/// Core domain entity representing a Firebase Analytics event
///
/// This is the unified model for analytics events, used for both real-time
/// monitoring (parsed from logcat) and persistence to the database.
class AnalyticsEvent extends Equatable {
  /// Creates a new [AnalyticsEvent].
  const AnalyticsEvent({
    required this.id,
    required this.timestamp,
    required this.eventName,
    required this.parameters,
    required this.items,
    this.rawTimestamp,
    this.manualParameters = const {},
    this.isFiltered = false,
  });

  /// Create from parsed logcat output
  ///
  /// Generates a unique ID and parses the timestamp string to DateTime.
  factory AnalyticsEvent.fromParsedLog({
    required String rawTimestamp,
    required String eventName,
    Map<String, String> parameters = const {},
    List<Map<String, String>> items = const [],
  }) {
    final parsedTimestamp =
        parseLogcatTimestamp(rawTimestamp) ?? DateTime.now();
    final uniqueId = '${parsedTimestamp.toIso8601String()}_${eventName}_'
        '${DateTime.now().microsecondsSinceEpoch}';

    return AnalyticsEvent(
      id: uniqueId,
      timestamp: parsedTimestamp,
      rawTimestamp: rawTimestamp,
      eventName: eventName,
      parameters: parameters,
      items: items,
    );
  }

  /// Create from JSON for export/import
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventName: json['eventName'] as String,
      parameters: Map<String, String>.from(json['parameters'] as Map),
      items: (json['items'] as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      rawTimestamp: json['rawTimestamp'] as String?,
      manualParameters: json['manualParameters'] != null
          ? Map<String, String>.from(json['manualParameters'] as Map)
          : {},
      isFiltered: json['isFiltered'] as bool? ?? false,
    );
  }

  /// The unique identifier for this event.
  final String id;

  /// The parsed timestamp as a [DateTime] object.
  final DateTime timestamp;

  /// Original timestamp string from logcat (may be null for imported events)
  final String? rawTimestamp;

  /// Name of the analytics event
  final String eventName;

  /// Event parameters as key-value pairs
  final Map<String, String> parameters;

  /// List of item bundles (for e-commerce events)
  final List<Map<String, String>> items;

  /// User-added manual parameters
  final Map<String, String> manualParameters;

  /// Whether this event was filtered
  final bool isFiltered;

  /// A map containing all parameters, including both parsed and manual ones.
  Map<String, String> get allParameters => {
        ...parameters,
        ...manualParameters,
      };

  /// A string representation of the timestamp for display purposes.
  ///
  /// Prefers the [rawTimestamp] if available; otherwise falls back to a
  /// formatted substring of [timestamp].
  String get displayTimestamp =>
      rawTimestamp ?? timestamp.toString().substring(11, 23);

  /// Creates a copy of this [AnalyticsEvent] with the given fields replaced
  /// with the new values.
  AnalyticsEvent copyWith({
    String? id,
    DateTime? timestamp,
    String? rawTimestamp,
    String? eventName,
    Map<String, String>? parameters,
    List<Map<String, String>>? items,
    Map<String, String>? manualParameters,
    bool? isFiltered,
  }) {
    return AnalyticsEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      rawTimestamp: rawTimestamp ?? this.rawTimestamp,
      eventName: eventName ?? this.eventName,
      parameters: parameters ?? this.parameters,
      items: items ?? this.items,
      manualParameters: manualParameters ?? this.manualParameters,
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }

  /// Converts this event to a JSON map for export.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'rawTimestamp': rawTimestamp,
      'eventName': eventName,
      'parameters': parameters,
      'items': items,
      'manualParameters': manualParameters,
      'isFiltered': isFiltered,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        rawTimestamp,
        eventName,
        parameters,
        items,
        manualParameters,
        isFiltered,
      ];
}
