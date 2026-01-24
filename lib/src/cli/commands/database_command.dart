import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:famon/src/constants.dart';
import 'package:famon/src/core/application/services/event_filter_service.dart';
import 'package:famon/src/core/application/use_cases/export_data_use_case.dart';
import 'package:famon/src/core/application/use_cases/import_data_use_case.dart';
import 'package:famon/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Validates and sanitizes a file path to prevent path traversal attacks.
/// Returns the canonicalized path if valid, or null if the path is invalid.
String? _validateFilePath(String? filePath, {bool mustExist = false}) {
  if (filePath == null || filePath.isEmpty) return null;

  // Canonicalize the path to resolve any . or .. segments
  final canonicalPath = p.canonicalize(filePath);

  // Check for null bytes which could be used to truncate paths
  if (filePath.contains('\x00')) return null;

  // For files that must exist, verify they do
  if (mustExist) {
    final file = File(canonicalPath);
    if (!file.existsSync()) return null;
  }

  return canonicalPath;
}

/// Validates a directory path.
/// Returns the canonicalized path if valid, or null if invalid.
String? _validateDirectoryPath(String? dirPath) {
  if (dirPath == null || dirPath.isEmpty) return null;

  // Canonicalize the path
  final canonicalPath = p.canonicalize(dirPath);

  // Check for null bytes
  if (dirPath.contains('\x00')) return null;

  return canonicalPath;
}

/// Command for database management operations
@injectable
class DatabaseCommand extends Command<int> {
  /// Creates a new DatabaseCommand with injected dependencies
  DatabaseCommand({
    required Logger logger,
    required IsarDatabase database,
    required ExportDataUseCase exportUseCase,
    required ImportDataUseCase importUseCase,
    required EventFilterService filterService,
  }) : _logger = logger {
    addSubcommand(_BackupSubcommand(logger, exportUseCase));
    addSubcommand(_RestoreSubcommand(logger, importUseCase));
    addSubcommand(_ExportSubcommand(logger, exportUseCase));
    addSubcommand(_ImportSubcommand(logger, importUseCase));
    addSubcommand(_ClearSubcommand(logger, database));
    addSubcommand(_InfoSubcommand(logger, filterService));
  }

  @override
  final name = 'database';

  @override
  final description =
      'Database management operations (backup, restore, export, import)';

  final Logger _logger;

  @override
  Future<int> run() async {
    _logger
      ..info(description)
      ..info(usage);
    return 0;
  }
}

class _BackupSubcommand extends Command<int> {
  _BackupSubcommand(this._logger, this._exportUseCase) {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path for the backup',
      )
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'Directory to save the backup file',
      );
  }

  @override
  final name = 'backup';

  @override
  final description = 'Create a backup of the database';

  final Logger _logger;
  final ExportDataUseCase _exportUseCase;

  @override
  Future<int> run() async {
    try {
      final rawFileName = argResults?['output'] as String?;
      final rawDirectory = argResults?['directory'] as String?;

      // Validate directory path if provided
      String? validatedDirectory;
      if (rawDirectory != null) {
        validatedDirectory = _validateDirectoryPath(rawDirectory);
        if (validatedDirectory == null) {
          _logger.err('Invalid directory path: $rawDirectory');
          return 1;
        }
      }

      // Validate file name (just check for path traversal in the name itself)
      String? validatedFileName;
      if (rawFileName != null) {
        // File name should not contain path separators or traversal patterns
        if (rawFileName.contains('..') ||
            rawFileName.contains('/') ||
            rawFileName.contains(r'\') ||
            rawFileName.contains('\x00')) {
          _logger.err('Invalid file name: $rawFileName');
          return 1;
        }
        validatedFileName = rawFileName;
      }

      _logger.info('Creating backup...');
      final filePath = await _exportUseCase.createBackup(
        fileName: validatedFileName,
        directory: validatedDirectory,
      );

      _logger.success('Backup created successfully: $filePath');
      return 0;
    } on Object catch (e) {
      _logger.err('Failed to create backup: $e');
      return 1;
    }
  }
}

class _RestoreSubcommand extends Command<int> {
  _RestoreSubcommand(this._logger, this._importUseCase) {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'Backup file to restore from',
        mandatory: true,
      )
      ..addFlag(
        'overwrite',
        help: 'Overwrite existing data',
        negatable: false,
      );
  }

  @override
  final name = 'restore';

  @override
  final description = 'Restore database from backup';

  final Logger _logger;
  final ImportDataUseCase _importUseCase;

  @override
  Future<int> run() async {
    try {
      final rawFilePath = argResults?['file'] as String;
      final overwrite = argResults?['overwrite'] as bool? ?? false;

      // Validate and canonicalize the file path
      final validatedPath = _validateFilePath(rawFilePath, mustExist: true);
      if (validatedPath == null) {
        _logger.err('Invalid or non-existent file path: $rawFilePath');
        return 1;
      }

      _logger.info('Restoring from backup: $validatedPath');
      await _importUseCase.restoreBackup(validatedPath, overwrite: overwrite);

      _logger.success('Database restored successfully');
      return 0;
    } on Object catch (e) {
      _logger.err('Failed to restore backup: $e');
      return 1;
    }
  }
}

class _ExportSubcommand extends Command<int> {
  _ExportSubcommand(this._logger, this._exportUseCase) {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path',
        mandatory: true,
      )
      ..addOption(
        'from',
        help: 'Export events from date (ISO 8601)',
      )
      ..addOption(
        'to',
        help: 'Export events to date (ISO 8601)',
      )
      ..addMultiOption(
        'events',
        help: 'Specific event names to export',
      );
  }

  @override
  final name = 'export';

  @override
  final description = 'Export data to JSON file';

  final Logger _logger;
  final ExportDataUseCase _exportUseCase;

  @override
  Future<int> run() async {
    try {
      final rawOutputPath = argResults?['output'] as String;
      final fromDateStr = argResults?['from'] as String?;
      final toDateStr = argResults?['to'] as String?;
      final eventNames = argResults?['events'] as List<String>?;

      // Validate and canonicalize the output path
      final validatedPath = _validateFilePath(rawOutputPath);
      if (validatedPath == null) {
        _logger.err('Invalid output path: $rawOutputPath');
        return 1;
      }

      // Verify parent directory exists
      final parentDir = Directory(p.dirname(validatedPath));
      if (!parentDir.existsSync()) {
        _logger.err(
          'Parent directory does not exist: ${p.dirname(validatedPath)}',
        );
        return 1;
      }

      DateTime? fromDate;
      DateTime? toDate;

      if (fromDateStr != null) {
        fromDate = DateTime.tryParse(fromDateStr);
        if (fromDate == null) {
          _logger.err('Invalid from date format. Use ISO 8601 format.');
          return 1;
        }
      }

      if (toDateStr != null) {
        toDate = DateTime.tryParse(toDateStr);
        if (toDate == null) {
          _logger.err('Invalid to date format. Use ISO 8601 format.');
          return 1;
        }
      }

      _logger.info('Exporting data...');
      await _exportUseCase.exportEventsToFile(
        validatedPath,
        fromDate: fromDate,
        toDate: toDate,
        eventNames: eventNames,
      );

      _logger.success('Data exported successfully to: $validatedPath');
      return 0;
    } on Object catch (e) {
      _logger.err('Failed to export data: $e');
      return 1;
    }
  }
}

class _ImportSubcommand extends Command<int> {
  _ImportSubcommand(this._logger, this._importUseCase) {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'JSON file to import',
        mandatory: true,
      )
      ..addFlag(
        'overwrite',
        help: 'Overwrite existing data',
        negatable: false,
      );
  }

  @override
  final name = 'import';

  @override
  final description = 'Import data from JSON file';

  final Logger _logger;
  final ImportDataUseCase _importUseCase;

  @override
  Future<int> run() async {
    try {
      final rawFilePath = argResults?['file'] as String;
      final overwrite = argResults?['overwrite'] as bool? ?? false;

      // Validate and canonicalize the file path
      final validatedPath = _validateFilePath(rawFilePath, mustExist: true);
      if (validatedPath == null) {
        _logger.err('Invalid or non-existent file path: $rawFilePath');
        return 1;
      }

      _logger.info('Importing data from: $validatedPath');
      await _importUseCase.importFromFile(validatedPath, overwrite: overwrite);

      _logger.success('Data imported successfully');
      return 0;
    } on Object catch (e) {
      _logger.err('Failed to import data: $e');
      return 1;
    }
  }
}

class _ClearSubcommand extends Command<int> {
  _ClearSubcommand(this._logger, this._database) {
    argParser.addFlag(
      'confirm',
      help: 'Confirm deletion without prompt',
      negatable: false,
    );
  }

  @override
  final name = 'clear';

  @override
  final description = 'Clear all data from database';

  final Logger _logger;
  final IsarDatabase _database;

  @override
  Future<int> run() async {
    try {
      final confirm = argResults?['confirm'] as bool? ?? false;

      if (!confirm) {
        _logger
            .warn('This will permanently delete all data from the database.');
        stdout.write('Are you sure? (y/N): ');
        final input = stdin.readLineSync();

        // Handle null input (EOF or non-interactive environment)
        if (input == null) {
          _logger.warn(
            'No input received. Use --confirm flag in non-interactive mode.',
          );
          return 1;
        }

        if (input.toLowerCase() != 'y' && input.toLowerCase() != 'yes') {
          _logger.info('Operation cancelled.');
          return 0;
        }
      }

      await _database.clear();

      _logger.success('Database cleared successfully');
      return 0;
    } on Object catch (e) {
      _logger.err('Failed to clear database: $e');
      return 1;
    }
  }
}

class _InfoSubcommand extends Command<int> {
  _InfoSubcommand(this._logger, this._filterService);

  @override
  final name = 'info';

  @override
  final description = 'Show database information and statistics';

  final Logger _logger;
  final EventFilterService _filterService;

  @override
  Future<int> run() async {
    try {
      final stats = await _filterService.getEventStatistics();

      _logger
        ..info('📊 Database Information:')
        ..info('   Total Events: ${stats.totalEvents}')
        ..info('   Unique Event Types: ${stats.uniqueEventTypes}')
        ..info(
          '   Date Range: ${stats.dateRange?.start.toLocal()} - '
          '${stats.dateRange?.end.toLocal()}',
        );

      if (stats.topEvents.isNotEmpty) {
        _logger.info('\n🔥 Top Events:');
        for (final entry in stats.topEvents.entries.take(statsTopEventsLimit)) {
          _logger.info('   ${entry.key}: ${entry.value} occurrences');
        }
      }

      return 0;
    } on Object catch (e) {
      _logger.err('Failed to get database info: $e');
      return 1;
    }
  }
}
