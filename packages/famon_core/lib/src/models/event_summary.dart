import 'package:isar/isar.dart';

part 'event_summary.g.dart';

/// Isar model for storing event summary data.
@collection
class EventSummary {
  /// Auto-incrementing primary key.
  Id id = Isar.autoIncrement;

  /// The unique name of the event.
  @Index(unique: true, replace: true)
  late String eventName;

  /// Total count of this event type.
  late int eventCount;

  /// When this event was last seen.
  late DateTime lastSeen;
}
