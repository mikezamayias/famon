import 'dart:convert';
import 'dart:io';

import 'package:famon/src/core/domain/repositories/data_export_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for exporting analytics data
@injectable
class ExportDataUseCase {
  /// Creates a new ExportDataUseCase with injected repository
  ExportDataUseCase(this._repository);

  final DataExportRepository _repository;

  /// Creates a backup file with all data.
  ///
  /// Uses optional [fileName] and [directory] for the backup location.
  Future<String> createBackup({String? fileName, String? directory}) async {
    return _repository.createBackup(fileName: fileName, directory: directory);
  }

  /// Exports all data to the specified [filePath] in JSON format.
  Future<void> exportAllDataToFile(String filePath) async {
    final data = await _repository.exportAllData();

    // Write to file
    final file = File(filePath);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Exports filtered events to the specified [filePath].
  ///
  /// Optionally filters by date range and event names.
  Future<void> exportEventsToFile(
    String filePath, {
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? eventNames,
  }) async {
    final data = await _repository.exportEvents(
      fromDate: fromDate,
      toDate: toDate,
      eventNames: eventNames,
    );

    // Write to file
    final file = File(filePath);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Gets metadata about a backup file at [filePath].
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    return _repository.getBackupInfo(filePath);
  }

  /// Validates the structure of a backup file at [filePath].
  Future<bool> validateBackupFile(String filePath) async {
    return _repository.validateBackupFile(filePath);
  }
}
