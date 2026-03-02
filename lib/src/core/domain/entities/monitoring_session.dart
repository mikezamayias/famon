import 'package:equatable/equatable.dart';

/// Domain entity representing a monitoring session configuration
class MonitoringSession extends Equatable {
  /// Creates a new [MonitoringSession].
  const MonitoringSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.deviceId,
    this.filters = const [],
    this.manualEventParameters = const {},
    this.configuration = const {},
  });

  /// Create from JSON for export/import
  factory MonitoringSession.fromJson(Map<String, dynamic> json) {
    return MonitoringSession(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      deviceId: json['deviceId'] as String?,
      filters: (json['filters'] as List?)
              ?.map((f) => EventFilter.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      manualEventParameters: json['manualEventParameters'] != null
          ? Map<String, Map<String, String>>.from(
              (json['manualEventParameters'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  Map<String, String>.from(value as Map),
                ),
              ),
            )
          : {},
      configuration: json['configuration'] as Map<String, dynamic>? ?? {},
    );
  }

  /// The unique identifier for this session.
  final String id;

  /// A human-readable name for the session.
  final String name;

  /// When the monitoring session began.
  final DateTime startTime;

  /// When the monitoring session ended, or null if still active.
  final DateTime? endTime;

  /// The ID of the connected device, if known.
  final String? deviceId;

  /// List of event filters applied to this session.
  final List<EventFilter> filters;

  /// Manual event parameters keyed by event name.
  final Map<String, Map<String, String>> manualEventParameters;

  /// Session configuration options.
  final Map<String, dynamic> configuration;

  /// Whether this session is still in progress.
  bool get isActive => endTime == null;

  /// The duration of the session.
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Creates a copy of this [MonitoringSession] with the given fields replaced.
  MonitoringSession copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? deviceId,
    List<EventFilter>? filters,
    Map<String, Map<String, String>>? manualEventParameters,
    Map<String, dynamic>? configuration,
  }) {
    return MonitoringSession(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deviceId: deviceId ?? this.deviceId,
      filters: filters ?? this.filters,
      manualEventParameters:
          manualEventParameters ?? this.manualEventParameters,
      configuration: configuration ?? this.configuration,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'deviceId': deviceId,
      'filters': filters.map((f) => f.toJson()).toList(),
      'manualEventParameters': manualEventParameters,
      'configuration': configuration,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        deviceId,
        filters,
        manualEventParameters,
        configuration,
      ];
}

/// Domain entity representing event filtering criteria
class EventFilter extends Equatable {
  /// Creates a new [EventFilter].
  const EventFilter({
    required this.id,
    required this.name,
    required this.type,
    required this.criteria,
    this.isEnabled = true,
  });

  /// Create from JSON for export/import
  factory EventFilter.fromJson(Map<String, dynamic> json) {
    return EventFilter(
      id: json['id'] as String,
      name: json['name'] as String,
      type: EventFilterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventFilterType.include,
      ),
      criteria: json['criteria'] as Map<String, dynamic>,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// The unique identifier for this filter.
  final String id;

  /// A human-readable name for the filter.
  final String name;

  /// The type of filter (include, exclude, etc.).
  final EventFilterType type;

  /// The filter criteria as a flexible map.
  final Map<String, dynamic> criteria;

  /// Whether this filter is enabled.
  final bool isEnabled;

  /// Creates a copy of this [EventFilter] with the given fields replaced.
  EventFilter copyWith({
    String? id,
    String? name,
    EventFilterType? type,
    Map<String, dynamic>? criteria,
    bool? isEnabled,
  }) {
    return EventFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      criteria: criteria ?? this.criteria,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'criteria': criteria,
      'isEnabled': isEnabled,
    };
  }

  @override
  List<Object?> get props => [id, name, type, criteria, isEnabled];
}

/// Types of event filters for monitoring sessions.
enum EventFilterType {
  /// Only show events matching the criteria.
  include,

  /// Hide events matching the criteria.
  exclude,

  /// Filter based on frequency thresholds.
  frequency,

  /// Filter based on parameter values.
  parameter,

  /// Filter based on time ranges.
  time,
}
