import 'dart:convert';
import 'dart:io';

import 'package:famon/src/core/domain/repositories/data_export_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for importing analytics data
@injectable
class ImportDataUseCase {
  /// Creates a new ImportDataUseCase with injected repository
  ImportDataUseCase(this._repository);

  final DataExportRepository _repository;

  /// Imports data from a JSON file at [filePath].
  ///
  /// If [overwrite] is true, existing data will be replaced.
  Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('File not found: $filePath');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    await _repository.importAllData(data, overwrite: overwrite);
  }

  /// Restores data from a backup file at [filePath].
  ///
  /// If [overwrite] is true, existing data will be replaced.
  Future<void> restoreBackup(String filePath, {bool overwrite = false}) async {
    await _repository.restoreBackup(filePath, overwrite: overwrite);
  }

  /// Validates the structure of a file at [filePath].
  Future<bool> validateFile(String filePath) async {
    return _repository.validateBackupFile(filePath);
  }

  /// Gets metadata about a file at [filePath].
  Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    return _repository.getBackupInfo(filePath);
  }
}
