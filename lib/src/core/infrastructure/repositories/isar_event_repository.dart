import 'dart:async';

import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/core/domain/repositories/event_repository.dart';
import 'package:famon/src/core/domain/value_objects/filter_criteria.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_models.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

/// Isar implementation of EventRepository
@Injectable(as: EventRepository)
class IsarEventRepository implements EventRepository {
  /// Creates a new IsarEventRepository with injected database
  IsarEventRepository({required this.database});

  /// The Isar database instance.
  final IsarDatabase database;

  @override
  Future<void> saveEvent(AnalyticsEvent event) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final isarEvent = IsarAnalyticsEvent.fromDomain(event);
      await isar.isarAnalyticsEvents.put(isarEvent);
    });
  }

  @override
  Future<void> saveEvents(List<AnalyticsEvent> events) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final isarEvents = events.map(IsarAnalyticsEvent.fromDomain).toList();
      await isar.isarAnalyticsEvents.putAll(isarEvents);
    });
  }

  @override
  Future<List<AnalyticsEvent>> getEvents({
    FilterCriteria? criteria,
    int? limit,
    int? offset,
  }) async {
    final isar = await database.db;
    final eventNames = criteria?.eventNames ?? const <String>[];
    final queryAfterNames = isar.isarAnalyticsEvents
        .where()
        .anyOf<String, QAfterWhereClause>(
          eventNames,
          (
            QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QWhereClause>
                q,
            String eventName,
          ) =>
              q.eventNameEqualTo(eventName),
        );

    final fetchLimit = limit != null ? ((offset ?? 0) + limit) : limit;
    final queried = criteria?.timeRange != null
        ? await _executeTimeFilteredQuery(
            base: queryAfterNames,
            range: criteria!.timeRange!,
            fetchLimit: fetchLimit,
          )
        : await _executeBasicQuery(
            base: queryAfterNames,
            fetchLimit: fetchLimit,
          );
    var events = queried.map((IsarAnalyticsEvent e) => e.toDomain()).toList();

    if (criteria != null) {
      events = _applyAdditionalFilters(events, criteria);
    }

    if (offset != null && offset > 0) {
      events = events.skip(offset).toList();
    }
    if (limit != null) {
      events = events.take(limit).toList();
    }

    return events;
  }

  Future<List<IsarAnalyticsEvent>> _executeBasicQuery({
    required QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent,
            QAfterWhereClause>
        base,
    int? fetchLimit,
  }) async {
    final sorted = base.sortByTimestampDesc();
    final limited = fetchLimit != null ? sorted.limit(fetchLimit) : sorted;
    return limited.findAll();
  }

  Future<List<IsarAnalyticsEvent>> _executeTimeFilteredQuery({
    required QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent,
            QAfterWhereClause>
        base,
    required TimeRange range,
    int? fetchLimit,
  }) async {
    final filtered = base
        .filter()
        .timestampBetween(
          range.start,
          range.end,
        )
        .sortByTimestampDesc();
    final limited = fetchLimit != null ? filtered.limit(fetchLimit) : filtered;
    return limited.findAll();
  }

  @override
  Future<AnalyticsEvent?> getEventById(String id) async {
    final isar = await database.db;
    // Find by domain ID since we store the original ID as domainId
    final isarEvent =
        await isar.isarAnalyticsEvents.where().domainIdEqualTo(id).findFirst();
    return isarEvent?.toDomain();
  }

  @override
  Future<List<AnalyticsEvent>> getEventsBySession(String sessionId) async {
    final isar = await database.db;
    final results = await isar.isarAnalyticsEvents
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestampDesc()
        .findAll();
    return results.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<AnalyticsEvent>> getAllEvents() async {
    final isar = await database.db;
    final results =
        await isar.isarAnalyticsEvents.where().sortByTimestampDesc().findAll();
    return results.map((e) => e.toDomain()).toList();
  }

  @override
  Future<int> deleteEvents({FilterCriteria? criteria}) async {
    final isar = await database.db;

    if (criteria == null) {
      return isar.writeTxn(() async {
        final count = await isar.isarAnalyticsEvents.count();
        await isar.isarAnalyticsEvents.clear();
        return count;
      });
    }

    // Get events matching criteria first
    final eventsToDelete = await getEvents(criteria: criteria);
    final domainIds = eventsToDelete.map((e) => e.id).toList();

    return isar.writeTxn(() async {
      var count = 0;
      for (final domainId in domainIds) {
        final deletedCount = await isar.isarAnalyticsEvents
            .where()
            .domainIdEqualTo(domainId)
            .deleteAll();
        count += deletedCount;
      }
      return count;
    });
  }

  @override
  Future<int> deleteEventsOlderThan(DateTime date) async {
    final isar = await database.db;
    return isar.writeTxn(() async {
      return isar.isarAnalyticsEvents
          .where()
          .timestampLessThan(date)
          .deleteAll();
    });
  }

  @override
  Future<int> getEventCount({FilterCriteria? criteria}) async {
    final events = await getEvents(criteria: criteria);
    return events.length;
  }

  @override
  Stream<AnalyticsEvent> watchEvents({FilterCriteria? criteria}) async* {
    final isar = await database.db;

    // Set up a stream that watches for new events
    await for (final _ in isar.isarAnalyticsEvents.watchLazy()) {
      // Get latest events when changes occur
      final latestEvents = await getEvents(
        criteria: criteria,
        limit: 100, // Get recent events
      );

      // Emit the most recent event
      if (latestEvents.isNotEmpty) {
        yield latestEvents.first;
      }
    }
  }

  @override
  Future<void> clearAllEvents() async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      await isar.isarAnalyticsEvents.clear();
    });
  }

  /// Apply filters that can't be efficiently done at the database level
  List<AnalyticsEvent> _applyAdditionalFilters(
    List<AnalyticsEvent> events,
    FilterCriteria criteria,
  ) {
    return events.where((event) {
      // Exclude events filter
      if (criteria.excludeEventNames.contains(event.eventName)) {
        return false;
      }

      // Parameter filters
      for (final entry in criteria.parameterFilters.entries) {
        if (!event.allParameters.containsKey(entry.key) ||
            event.allParameters[entry.key] != entry.value) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
