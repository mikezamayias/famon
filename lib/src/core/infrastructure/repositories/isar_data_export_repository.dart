import 'dart:convert';
import 'dart:io';

import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/core/domain/entities/event_metadata.dart';
import 'package:famon/src/core/domain/repositories/data_export_repository.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_models.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

/// Isar implementation of DataExportRepository
@Injectable(as: DataExportRepository)
class IsarDataExportRepository implements DataExportRepository {
  /// Creates a new IsarDataExportRepository with injected database
  IsarDataExportRepository({required this.database});

  /// The Isar database instance for data operations.
  final IsarDatabase database;

  /// Number of records to process per transaction during import.
  ///
  /// This bounds memory usage for large imports by processing in chunks
  /// rather than loading all records into a single transaction.
  static const int _importChunkSize = 1000;

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    final events = await exportEvents();
    final metadata = await exportEventMetadata();
    final sessions = await exportSessions();

    return {
      'version': '1.0.0',
      'exportTimestamp': DateTime.now().toIso8601String(),
      'data': {'events': events, 'metadata': metadata, 'sessions': sessions},
    };
  }

  QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent, QAfterSortBy>
      _executeTimedExportQuery({
    required QueryBuilder<IsarAnalyticsEvent, IsarAnalyticsEvent,
            QAfterWhereClause>
        base,
    DateTime? from,
    DateTime? to,
  }) {
    final filter = base.filter();
    final filteredQuery = from != null && to != null
        ? filter.timestampBetween(from, to)
        : from != null
            ? filter.timestampGreaterThan(from, include: true)
            : filter.timestampLessThan(to!, include: true);
    return filteredQuery.sortByTimestampDesc();
  }

  @override
  Future<Map<String, dynamic>> exportEvents({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? eventNames,
  }) async {
    final isar = await database.db;
    final names = eventNames ?? const <String>[];
    final queryAfterNames =
        isar.isarAnalyticsEvents.where().anyOf<String, QAfterWhereClause>(
              names,
              (q, name) => q.eventNameEqualTo(name),
            );

    final sortedQuery = fromDate != null || toDate != null
        ? _executeTimedExportQuery(
            base: queryAfterNames,
            from: fromDate,
            to: toDate,
          )
        : queryAfterNames.sortByTimestampDesc();
    final filteredEvents = await sortedQuery.findAll();

    return {
      'count': filteredEvents.length,
      'events': filteredEvents.map((e) => e.toDomain().toJson()).toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> exportEventMetadata() async {
    final isar = await database.db;
    final allMetadata = await isar.isarEventMetadatas.where().findAll();

    return {
      'count': allMetadata.length,
      'metadata': allMetadata.map((m) => m.toDomain().toJson()).toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> exportSessions() async {
    final isar = await database.db;
    final allSessions = await isar.isarSessionDatas.where().findAll();

    return {
      'count': allSessions.length,
      'sessions': allSessions.map((s) => s.toMap()).toList(),
    };
  }

  @override
  Future<void> importAllData(
    Map<String, dynamic> data, {
    bool overwrite = false,
  }) async {
    if (overwrite) {
      await database.clear();
    }

    final dataSection = data['data'] as Map<String, dynamic>?;
    if (dataSection == null) return;

    if (dataSection['events'] != null) {
      await importEvents(dataSection['events'] as Map<String, dynamic>);
    }

    if (dataSection['metadata'] != null) {
      await importEventMetadata(
        dataSection['metadata'] as Map<String, dynamic>,
      );
    }

    if (dataSection['sessions'] != null) {
      await importSessions(dataSection['sessions'] as Map<String, dynamic>);
    }
  }

  @override
  Future<void> importEvents(
    Map<String, dynamic> data, {
    bool overwrite = false,
  }) async {
    final isar = await database.db;
    final eventsList = data['events'] as List<dynamic>?;

    if (eventsList == null || eventsList.isEmpty) return;

    // Clear existing data if overwriting (separate transaction)
    if (overwrite) {
      await isar.writeTxn(() => isar.isarAnalyticsEvents.clear());
    }

    // Process in chunks to bound memory usage for large imports
    final totalEvents = eventsList.length;
    for (var offset = 0; offset < totalEvents; offset += _importChunkSize) {
      final endIndex = (offset + _importChunkSize < totalEvents)
          ? offset + _importChunkSize
          : totalEvents;
      final chunk = eventsList.sublist(offset, endIndex);

      await isar.writeTxn(() async {
        for (final eventData in chunk) {
          final event = AnalyticsEvent.fromJson(
            eventData as Map<String, dynamic>,
          );
          final isarEvent = IsarAnalyticsEvent.fromDomain(event);
          await isar.isarAnalyticsEvents.put(isarEvent);
        }
      });
    }
  }

  @override
  Future<void> importEventMetadata(
    Map<String, dynamic> data, {
    bool overwrite = false,
  }) async {
    final isar = await database.db;
    final metadataList = data['metadata'] as List<dynamic>?;

    if (metadataList == null || metadataList.isEmpty) return;

    // Clear existing data if overwriting (separate transaction)
    if (overwrite) {
      await isar.writeTxn(() => isar.isarEventMetadatas.clear());
    }

    // Process in chunks to bound memory usage for large imports
    final totalMetadata = metadataList.length;
    for (var offset = 0; offset < totalMetadata; offset += _importChunkSize) {
      final endIndex = (offset + _importChunkSize < totalMetadata)
          ? offset + _importChunkSize
          : totalMetadata;
      final chunk = metadataList.sublist(offset, endIndex);

      await isar.writeTxn(() async {
        for (final metadataData in chunk) {
          final metadata = EventMetadata.fromJson(
            metadataData as Map<String, dynamic>,
          );
          final isarMetadata = IsarEventMetadata.fromDomain(metadata);
          await isar.isarEventMetadatas.put(isarMetadata);
        }
      });
    }
  }

  @override
  Future<void> importSessions(
    Map<String, dynamic> data, {
    bool overwrite = false,
  }) async {
    final isar = await database.db;
    final sessionsList = data['sessions'] as List<dynamic>?;

    if (sessionsList == null || sessionsList.isEmpty) return;

    // Clear existing data if overwriting (separate transaction)
    if (overwrite) {
      await isar.writeTxn(() => isar.isarSessionDatas.clear());
    }

    // Process in chunks to bound memory usage for large imports
    final totalSessions = sessionsList.length;
    for (var offset = 0; offset < totalSessions; offset += _importChunkSize) {
      final endIndex = (offset + _importChunkSize < totalSessions)
          ? offset + _importChunkSize
          : totalSessions;
      final chunk = sessionsList.sublist(offset, endIndex);

      await isar.writeTxn(() async {
        for (final sessionData in chunk) {
          final sessionMap = sessionData as Map<String, dynamic>;
          final sessionId = sessionMap['sessionId'] as String;
          final isarSession = IsarSessionData.fromMap(sessionId, sessionMap);
          await isar.isarSessionDatas.put(isarSession);
        }
      });
    }
  }

  @override
  Future<String> createBackup({String? fileName, String? directory}) async {
    final data = await exportAllData();

    // Determine file path
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final defaultFileName = 'famon_backup_$timestamp.json';
    final file = fileName ?? defaultFileName;

    final backupDir = directory ?? Directory.current.path;
    final filePath = '$backupDir/$file';

    // Write to file
    final backupFile = File(filePath);
    await backupFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );

    return filePath;
  }

  @override
  Future<void> restoreBackup(String filePath, {bool overwrite = false}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('Backup file not found: $filePath');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    await importAllData(data, overwrite: overwrite);
  }

  @override
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('Backup file not found: $filePath');
    }

    final stat = file.statSync();
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    return {
      'filePath': filePath,
      'fileSize': stat.size,
      'created': stat.modified.toIso8601String(),
      'version': data['version'] ?? 'unknown',
      'exportTimestamp': data['exportTimestamp'] ?? 'unknown',
      'eventCount': _getNestedCount(data, ['data', 'events', 'count']),
      'metadataCount': _getNestedCount(data, ['data', 'metadata', 'count']),
      'sessionCount': _getNestedCount(data, ['data', 'sessions', 'count']),
    };
  }

  @override
  Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Check required structure
      return data.containsKey('version') &&
          data.containsKey('exportTimestamp') &&
          data.containsKey('data');
    } on Object catch (_) {
      return false;
    }
  }

  int _getNestedCount(Map<String, dynamic> data, List<String> path) {
    dynamic current = data;
    for (final key in path) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return 0;
      }
    }
    return current is int ? current : 0;
  }
}
