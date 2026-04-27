/// Repository interface for importing and exporting data
/// Supports backup and restore functionality with JSON format
abstract class DataExportRepository {
  /// Export all data to JSON format
  Future<Map<String, dynamic>> exportAllData();

  /// Export specific data types
  Future<Map<String, dynamic>> exportEvents({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? eventNames,
  });

  /// Export event metadata to JSON format.
  Future<Map<String, dynamic>> exportEventMetadata();

  /// Export session data to JSON format.
  Future<Map<String, dynamic>> exportSessions();

  /// Import data from JSON format
  Future<void> importAllData(
    Map<String, dynamic> data, {
    bool overwrite = false,
  });

  /// Import specific data types
  Future<void> importEvents(
    Map<String, dynamic> data, {
    bool overwrite = false,
  });

  /// Import event metadata from JSON data.
  ///
  /// If [overwrite] is true, existing metadata will be replaced.
  Future<void> importEventMetadata(
    Map<String, dynamic> data, {
    bool overwrite = false,
  });

  /// Import session data from JSON data.
  ///
  /// If [overwrite] is true, existing sessions will be replaced.
  Future<void> importSessions(
    Map<String, dynamic> data, {
    bool overwrite = false,
  });

  /// Create a backup file
  Future<String> createBackup({String? fileName, String? directory});

  /// Restore from a backup file
  Future<void> restoreBackup(String filePath, {bool overwrite = false});

  /// Get backup file info
  Future<Map<String, dynamic>> getBackupInfo(String filePath);

  /// Validate backup file format
  Future<bool> validateBackupFile(String filePath);
}
