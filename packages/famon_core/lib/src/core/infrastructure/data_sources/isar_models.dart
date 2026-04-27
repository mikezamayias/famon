import 'dart:convert';

import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/core/domain/entities/event_metadata.dart';
import 'package:isar/isar.dart';

part 'isar_models.g.dart';

/// Isar model for AnalyticsEvent
@collection
class IsarAnalyticsEvent {
  /// Creates an empty [IsarAnalyticsEvent].
  IsarAnalyticsEvent();

  /// Convert from domain entity
  IsarAnalyticsEvent.fromDomain(AnalyticsEvent event) {
    domainId = event.id;
    eventName = event.eventName;
    timestamp = event.timestamp;
    parametersJson = jsonEncode(event.parameters);
    itemsJson = jsonEncode(event.items);
    manualParametersJson = jsonEncode(event.manualParameters);
    isFiltered = event.isFiltered;
  }

  /// Isar auto-incrementing primary key.
  Id id = Isar.autoIncrement;

  /// The domain entity ID.
  @Index()
  late String domainId;

  /// The event name.
  @Index()
  late String eventName;

  /// When the event occurred.
  @Index()
  late DateTime timestamp;

  /// JSON-serialized event parameters.
  late String parametersJson;

  /// JSON-serialized item bundles.
  late String itemsJson;

  /// JSON-serialized manual parameters.
  late String manualParametersJson;

  /// Whether this event was filtered.
  late bool isFiltered;

  /// The session ID this event belongs to.
  String? sessionId;

  /// Convert to domain entity
  AnalyticsEvent toDomain() {
    return AnalyticsEvent(
      id: domainId,
      timestamp: timestamp,
      eventName: eventName,
      parameters: Map<String, String>.from(jsonDecode(parametersJson) as Map),
      items: (jsonDecode(itemsJson) as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      manualParameters: Map<String, String>.from(
        jsonDecode(manualParametersJson) as Map,
      ),
      isFiltered: isFiltered,
    );
  }
}

/// Isar model for EventMetadata
@collection
class IsarEventMetadata {
  /// Creates an empty [IsarEventMetadata].
  IsarEventMetadata();

  /// Convert from domain entity
  IsarEventMetadata.fromDomain(EventMetadata metadata) {
    eventName = metadata.eventName;
    totalCount = metadata.totalCount;
    firstSeen = metadata.firstSeen;
    lastSeen = metadata.lastSeen;
    frequency = metadata.frequency;
    averageParameterCount = metadata.averageParameterCount;
    commonParametersJson = jsonEncode(metadata.commonParameters);
    isHidden = metadata.isHidden;
    isWatched = metadata.isWatched;
    customTags = metadata.customTags;
  }

  /// Isar auto-incrementing primary key.
  Id id = Isar.autoIncrement;

  /// The unique event name.
  @Index(unique: true, replace: true)
  late String eventName;

  /// Total count of this event type.
  late int totalCount;

  /// When this event was first seen.
  late DateTime firstSeen;

  /// When this event was last seen.
  late DateTime lastSeen;

  /// Event frequency (events per hour).
  late double frequency;

  /// Average number of parameters per event.
  late int averageParameterCount;

  /// JSON-serialized `Map<String, int>` of parameter frequencies.
  late String commonParametersJson;

  /// Whether this event is hidden from display.
  late bool isHidden;

  /// Whether this event is being watched.
  late bool isWatched;

  /// User-defined tags for categorization.
  late List<String> customTags;

  /// Convert to domain entity
  EventMetadata toDomain() {
    return EventMetadata(
      eventName: eventName,
      totalCount: totalCount,
      firstSeen: firstSeen,
      lastSeen: lastSeen,
      frequency: frequency,
      averageParameterCount: averageParameterCount,
      commonParameters: Map<String, int>.from(
        jsonDecode(commonParametersJson) as Map,
      ),
      isHidden: isHidden,
      isWatched: isWatched,
      customTags: customTags,
    );
  }
}

/// Isar model for session data
@collection
class IsarSessionData {
  /// Creates an empty [IsarSessionData].
  IsarSessionData();

  /// Convert from session data map
  IsarSessionData.fromMap(this.sessionId, Map<String, dynamic> data) {
    sessionDataJson = jsonEncode(data);
  }

  /// Isar auto-incrementing primary key.
  Id id = Isar.autoIncrement;

  /// The unique session ID.
  @Index(unique: true, replace: true)
  late String sessionId;

  /// JSON-serialized session data.
  late String sessionDataJson;

  /// Convert to session data map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      ...Map<String, dynamic>.from(jsonDecode(sessionDataJson) as Map),
    };
  }
}
