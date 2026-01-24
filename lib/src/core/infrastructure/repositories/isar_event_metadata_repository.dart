import 'dart:async';

import 'package:famon/src/core/domain/entities/event_metadata.dart';
import 'package:famon/src/core/domain/repositories/event_repository.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_models.dart';
import 'package:isar/isar.dart';

/// Isar implementation of EventMetadataRepository
class IsarEventMetadataRepository implements EventMetadataRepository {
  /// Creates a new [IsarEventMetadataRepository] with the given [database].
  IsarEventMetadataRepository({required this.database});

  /// The Isar database instance for data operations.
  final IsarDatabase database;

  @override
  Future<void> saveEventMetadata(EventMetadata metadata) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final isarMetadata = IsarEventMetadata.fromDomain(metadata);
      await isar.isarEventMetadatas.put(isarMetadata);
    });
  }

  @override
  Future<EventMetadata?> getEventMetadata(String eventName) async {
    final isar = await database.db;
    final isarMetadata = await isar.isarEventMetadatas
        .where()
        .eventNameEqualTo(eventName)
        .findFirst();
    return isarMetadata?.toDomain();
  }

  @override
  Future<List<EventMetadata>> getEventMetadataList({
    List<String>? eventNames,
    bool? isHidden,
    bool? isWatched,
  }) async {
    final isar = await database.db;
    final names = eventNames ?? const <String>[];
    final whereQuery = isar.isarEventMetadatas
        .where()
        .anyOf<String, QAfterWhereClause>(
          names,
          (
            QueryBuilder<IsarEventMetadata, IsarEventMetadata, QWhereClause> q,
            String name,
          ) =>
              q.eventNameEqualTo(name),
        );

    if (isHidden != null || isWatched != null) {
      final filterBase = whereQuery.filter();
      QueryBuilder<IsarEventMetadata, IsarEventMetadata, QAfterFilterCondition>
          filteredQuery;

      if (isHidden != null) {
        filteredQuery = filterBase.isHiddenEqualTo(isHidden);
        if (isWatched != null) {
          filteredQuery = filteredQuery.isWatchedEqualTo(isWatched);
        }
      } else {
        filteredQuery = filterBase.isWatchedEqualTo(isWatched!);
      }

      final filtered = await filteredQuery.findAll();
      return filtered
          .map((IsarEventMetadata metadata) => metadata.toDomain())
          .toList();
    }

    final results = await whereQuery.findAll();
    return results
        .map((IsarEventMetadata metadata) => metadata.toDomain())
        .toList();
  }

  @override
  Future<void> updateEventStatistics(
    String eventName, {
    int? incrementCount,
    DateTime? lastSeen,
    Map<String, int>? parameterFrequencies,
  }) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      var metadata = await isar.isarEventMetadatas
          .where()
          .eventNameEqualTo(eventName)
          .findFirst();

      if (metadata == null) {
        // Create new metadata if it doesn't exist
        metadata = IsarEventMetadata()
          ..eventName = eventName
          ..totalCount = incrementCount ?? 1
          ..firstSeen = lastSeen ?? DateTime.now()
          ..lastSeen = lastSeen ?? DateTime.now()
          ..frequency = 0.0
          ..averageParameterCount = 0
          ..commonParametersJson = '{}'
          ..isHidden = false
          ..isWatched = false
          ..customTags = [];
      } else {
        // Update existing metadata
        if (incrementCount != null) {
          metadata.totalCount += incrementCount;
        }
        if (lastSeen != null) {
          metadata.lastSeen = lastSeen;
        }
        // Update frequency calculation
        final timeDiff = DateTime.now().difference(metadata.firstSeen);
        metadata.frequency =
            timeDiff.inHours > 0 ? metadata.totalCount / timeDiff.inHours : 0.0;
      }

      await isar.isarEventMetadatas.put(metadata);
    });
  }

  @override
  Future<List<EventMetadata>> getEventsByFrequency({
    int? limit,
    bool descending = true,
  }) async {
    final isar = await database.db;
    final baseQuery = isar.isarEventMetadatas.where();
    final sortedQuery = descending
        ? baseQuery.sortByFrequencyDesc()
        : baseQuery.sortByFrequency();
    final limitedQuery = limit != null ? sortedQuery.limit(limit) : sortedQuery;
    final results = await limitedQuery.findAll();
    return results.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<String>> getSuggestedToHide({
    double frequencyThreshold = 10.0,
  }) async {
    final isar = await database.db;
    final metadata = await isar.isarEventMetadatas
        .filter()
        .frequencyGreaterThan(frequencyThreshold)
        .eventNameProperty()
        .findAll();
    return metadata;
  }

  @override
  Future<void> updateEventVisibility(
    String eventName, {
    bool? isHidden,
    bool? isWatched,
  }) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final metadata = await isar.isarEventMetadatas
          .where()
          .eventNameEqualTo(eventName)
          .findFirst();

      if (metadata != null) {
        if (isHidden != null) {
          metadata.isHidden = isHidden;
        }
        if (isWatched != null) {
          metadata.isWatched = isWatched;
        }
        await isar.isarEventMetadatas.put(metadata);
      }
    });
  }

  @override
  Future<void> addEventTags(String eventName, List<String> tags) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final metadata = await isar.isarEventMetadatas
          .where()
          .eventNameEqualTo(eventName)
          .findFirst();

      if (metadata != null) {
        final updatedTags = {...metadata.customTags, ...tags}.toList();
        metadata.customTags = updatedTags;
        await isar.isarEventMetadatas.put(metadata);
      }
    });
  }

  @override
  Future<void> removeEventTags(String eventName, List<String> tags) async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      final metadata = await isar.isarEventMetadatas
          .where()
          .eventNameEqualTo(eventName)
          .findFirst();

      if (metadata != null) {
        final updatedTags =
            metadata.customTags.where((tag) => !tags.contains(tag)).toList();
        metadata.customTags = updatedTags;
        await isar.isarEventMetadatas.put(metadata);
      }
    });
  }

  @override
  Future<int> deleteEventMetadata(List<String> eventNames) async {
    final isar = await database.db;
    if (eventNames.isEmpty) return 0;
    return isar.writeTxn(() async {
      final ids = await isar.isarEventMetadatas
          .filter()
          .anyOf<String, QAfterFilterCondition>(
            eventNames,
            (
              QueryBuilder<IsarEventMetadata, IsarEventMetadata,
                      QFilterCondition>
                  q,
              String name,
            ) =>
                q.eventNameEqualTo(name),
          )
          .idProperty()
          .findAll();
      if (ids.isEmpty) return 0;
      return isar.isarEventMetadatas.deleteAll(ids);
    });
  }

  @override
  Future<void> clearAllMetadata() async {
    final isar = await database.db;
    await isar.writeTxn(() async {
      await isar.isarEventMetadatas.clear();
    });
  }
}
