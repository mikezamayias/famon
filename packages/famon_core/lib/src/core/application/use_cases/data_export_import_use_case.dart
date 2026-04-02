import 'package:famon_core/src/core/domain/repositories/data_export_repository.dart';
import 'package:famon_core/src/core/domain/repositories/event_repository.dart';

/// Use case for exporting and importing data with JSON compatibility
class DataExportImportUseCase {
  /// Creates a new [DataExportImportUseCase].
  const DataExportImportUseCase({
    required this.dataExportRepository,
    required this.eventRepository,
  });

  /// The repository for data export and backup operations.
  final DataExportRepository dataExportRepository;

  /// The repository for accessing analytics events.
  final EventRepository eventRepository;

  /// Export all data to a JSON file
  Future<String> exportAllData({String? fileName, String? directory}) async {
    final filePath = await dataExportRepository.createBackup(
      fileName: fileName,
      directory: directory,
    );
    return filePath;
  }

  /// Export filtered events to JSON
  Future<Map<String, dynamic>> exportFilteredEvents({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? eventNames,
  }) async {
    return dataExportRepository.exportEvents(
      fromDate: fromDate,
      toDate: toDate,
      eventNames: eventNames,
    );
  }

  /// Import data from a JSON file
  Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
    // Validate the file first
    final isValid = await dataExportRepository.validateBackupFile(filePath);
    if (!isValid) {
      throw ArgumentError('Invalid backup file format');
    }

    // Get file info for logging/validation (could be used for user confirmation)
    await dataExportRepository.getBackupInfo(filePath);

    // Restore the backup
    await dataExportRepository.restoreBackup(filePath, overwrite: overwrite);
  }

  /// Import data from JSON map
  Future<void> importFromJson(
    Map<String, dynamic> jsonData, {
    bool overwrite = false,
  }) async {
    await dataExportRepository.importAllData(jsonData, overwrite: overwrite);
  }

  /// Get backup file information
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    return dataExportRepository.getBackupInfo(filePath);
  }

  /// Create a quick backup with current timestamp
  Future<String> createQuickBackup() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return dataExportRepository.createBackup(
      fileName: 'famon_backup_$timestamp.json',
    );
  }

  /// Export event metadata only
  Future<Map<String, dynamic>> exportEventMetadata() async {
    return dataExportRepository.exportEventMetadata();
  }

  /// Export session data only
  Future<Map<String, dynamic>> exportSessions() async {
    return dataExportRepository.exportSessions();
  }

  /// Validate a backup file without importing
  Future<bool> validateBackup(String filePath) async {
    return dataExportRepository.validateBackupFile(filePath);
  }
}
