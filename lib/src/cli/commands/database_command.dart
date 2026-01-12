import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

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
      final fileName = argResults?['output'] as String?;
      final directory = argResults?['directory'] as String?;

      _logger.info('Creating backup...');
      final filePath = await _exportUseCase.createBackup(
        fileName: fileName,
        directory: directory,
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
      final filePath = argResults?['file'] as String;
      final overwrite = argResults?['overwrite'] as bool? ?? false;

      _logger.info('Restoring from backup: $filePath');
      await _importUseCase.restoreBackup(filePath, overwrite: overwrite);

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
      final outputPath = argResults?['output'] as String;
      final fromDateStr = argResults?['from'] as String?;
      final toDateStr = argResults?['to'] as String?;
      final eventNames = argResults?['events'] as List<String>?;

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
        outputPath,
        fromDate: fromDate,
        toDate: toDate,
        eventNames: eventNames,
      );

      _logger.success('Data exported successfully to: $outputPath');
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
      final filePath = argResults?['file'] as String;
      final overwrite = argResults?['overwrite'] as bool? ?? false;

      _logger.info('Importing data from: $filePath');
      await _importUseCase.importFromFile(filePath, overwrite: overwrite);

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
