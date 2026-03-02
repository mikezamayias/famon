import 'package:equatable/equatable.dart';

/// Value object representing filtering criteria for events.
class FilterCriteria extends Equatable {
  /// Creates a new [FilterCriteria].
  const FilterCriteria({
    this.eventNames = const [],
    this.excludeEventNames = const [],
    this.minFrequency,
    this.maxFrequency,
    this.parameterFilters = const {},
    this.timeRange,
    this.customTags = const [],
  });

  /// Create from JSON for export/import
  factory FilterCriteria.fromJson(Map<String, dynamic> json) {
    return FilterCriteria(
      eventNames: List<String>.from(json['eventNames'] as List? ?? []),
      excludeEventNames: List<String>.from(
        json['excludeEventNames'] as List? ?? [],
      ),
      minFrequency: json['minFrequency'] as double?,
      maxFrequency: json['maxFrequency'] as double?,
      parameterFilters: Map<String, String>.from(
        json['parameterFilters'] as Map? ?? {},
      ),
      timeRange: json['timeRange'] != null
          ? TimeRange.fromJson(json['timeRange'] as Map<String, dynamic>)
          : null,
      customTags: List<String>.from(json['customTags'] as List? ?? []),
    );
  }

  /// Event names to include (whitelist).
  final List<String> eventNames;

  /// Event names to exclude (blacklist).
  final List<String> excludeEventNames;

  /// Minimum frequency threshold.
  final double? minFrequency;

  /// Maximum frequency threshold.
  final double? maxFrequency;

  /// Parameter name-value filters.
  final Map<String, String> parameterFilters;

  /// Time range filter.
  final TimeRange? timeRange;

  /// Custom tags to filter by.
  final List<String> customTags;

  /// Whether any filters are applied.
  bool get hasFilters =>
      eventNames.isNotEmpty ||
      excludeEventNames.isNotEmpty ||
      minFrequency != null ||
      maxFrequency != null ||
      parameterFilters.isNotEmpty ||
      timeRange != null ||
      customTags.isNotEmpty;

  /// Creates a copy of this [FilterCriteria] with the given fields replaced.
  FilterCriteria copyWith({
    List<String>? eventNames,
    List<String>? excludeEventNames,
    double? minFrequency,
    double? maxFrequency,
    Map<String, String>? parameterFilters,
    TimeRange? timeRange,
    List<String>? customTags,
  }) {
    return FilterCriteria(
      eventNames: eventNames ?? this.eventNames,
      excludeEventNames: excludeEventNames ?? this.excludeEventNames,
      minFrequency: minFrequency ?? this.minFrequency,
      maxFrequency: maxFrequency ?? this.maxFrequency,
      parameterFilters: parameterFilters ?? this.parameterFilters,
      timeRange: timeRange ?? this.timeRange,
      customTags: customTags ?? this.customTags,
    );
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {
      'eventNames': eventNames,
      'excludeEventNames': excludeEventNames,
      'minFrequency': minFrequency,
      'maxFrequency': maxFrequency,
      'parameterFilters': parameterFilters,
      'timeRange': timeRange?.toJson(),
      'customTags': customTags,
    };
  }

  @override
  List<Object?> get props => [
    eventNames,
    excludeEventNames,
    minFrequency,
    maxFrequency,
    parameterFilters,
    timeRange,
    customTags,
  ];
}

/// Value object representing a time range for filtering.
class TimeRange extends Equatable {
  /// Creates a new [TimeRange].
  const TimeRange({required this.start, required this.end});

  /// Create from JSON for export/import
  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  /// The start of the time range.
  final DateTime start;

  /// The end of the time range.
  final DateTime end;

  /// The duration of this time range.
  Duration get duration => end.difference(start);

  /// Checks if [dateTime] is within this range.
  bool contains(DateTime dateTime) {
    return dateTime.isAfter(start) && dateTime.isBefore(end);
  }

  /// Creates a copy of this [TimeRange] with the given fields replaced.
  TimeRange copyWith({DateTime? start, DateTime? end}) {
    return TimeRange(start: start ?? this.start, end: end ?? this.end);
  }

  /// Convert to JSON for export/import
  Map<String, dynamic> toJson() {
    return {'start': start.toIso8601String(), 'end': end.toIso8601String()};
  }

  @override
  List<Object?> get props => [start, end];
}
