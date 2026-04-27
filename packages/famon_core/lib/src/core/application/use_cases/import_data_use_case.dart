import 'dart:convert';
import 'dart:io';

import 'package:famon_core/src/core/domain/repositories/data_export_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for importing analytics data
@injectable
class ImportDataUseCase {
  /// Creates a new ImportDataUseCase with injected repository
  ImportDataUseCase(this._repository);

  final DataExportRepository _repository;

  /// Maximum allowed import file size (100 MB).
  ///
  /// This prevents memory exhaustion attacks from maliciously large files.
  static const int maxImportFileSize = 100 * 1024 * 1024;

  /// Imports data from a JSON file at [filePath].
  ///
  /// If [overwrite] is true, existing data will be replaced.
  ///
  /// Throws [ArgumentError] if:
  /// - File does not exist
  /// - File exceeds [maxImportFileSize]
  ///
  /// Throws [FormatException] if:
  /// - JSON is malformed
  /// - File structure is invalid
  Future<void> importFromFile(String filePath, {bool overwrite = false}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('File not found: $filePath');
    }

    // Security: Check file size before reading to prevent memory exhaustion
    final fileSize = await file.length();
    if (fileSize > maxImportFileSize) {
      throw ArgumentError(
        'Import file too large: ${_formatFileSize(fileSize)} '
        '(max: ${_formatFileSize(maxImportFileSize)})',
      );
    }

    final content = await file.readAsString();

    // Parse and validate JSON structure
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON in import file: ${e.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid import file: expected JSON object at root',
      );
    }

    final data = decoded;

    // Validate schema structure
    final validationError = _validateImportSchema(data);
    if (validationError != null) {
      throw FormatException('Invalid import file structure: $validationError');
    }

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

  /// Validates the import data schema.
  ///
  /// Returns null if valid, or an error message describing the issue.
  String? _validateImportSchema(Map<String, dynamic> data) {
    // Check required top-level fields
    if (!data.containsKey('version')) {
      return 'missing required field: version';
    }
    if (!data.containsKey('data')) {
      return 'missing required field: data';
    }

    final dataSection = data['data'];
    if (dataSection is! Map<String, dynamic>) {
      return '"data" field must be an object';
    }

    // Validate events section if present
    if (dataSection.containsKey('events')) {
      final eventsSection = dataSection['events'];
      if (eventsSection is! Map<String, dynamic>) {
        return '"data.events" must be an object';
      }
      if (eventsSection.containsKey('events')) {
        final eventsList = eventsSection['events'];
        if (eventsList is! List) {
          return '"data.events.events" must be an array';
        }
        // Validate a sample of events (first 10) for structure
        final sampleError = _validateEventsSample(eventsList.take(10).toList());
        if (sampleError != null) {
          return sampleError;
        }
      }
    }

    // Validate metadata section if present
    if (dataSection.containsKey('metadata')) {
      final metadataSection = dataSection['metadata'];
      if (metadataSection is! Map<String, dynamic>) {
        return '"data.metadata" must be an object';
      }
      if (metadataSection.containsKey('metadata')) {
        if (metadataSection['metadata'] is! List) {
          return '"data.metadata.metadata" must be an array';
        }
      }
    }

    // Validate sessions section if present
    if (dataSection.containsKey('sessions')) {
      final sessionsSection = dataSection['sessions'];
      if (sessionsSection is! Map<String, dynamic>) {
        return '"data.sessions" must be an object';
      }
      if (sessionsSection.containsKey('sessions')) {
        if (sessionsSection['sessions'] is! List) {
          return '"data.sessions.sessions" must be an array';
        }
      }
    }

    return null; // Valid
  }

  /// Validates a sample of events for required fields.
  String? _validateEventsSample(List<dynamic> events) {
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (event is! Map<String, dynamic>) {
        return 'event at index $i must be an object';
      }
      if (!event.containsKey('eventName')) {
        return 'event at index $i missing required field: eventName';
      }
      if (event['eventName'] is! String) {
        return 'event at index $i: eventName must be a string';
      }
    }
    return null;
  }

  /// Formats file size for human-readable display.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
