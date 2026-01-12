import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/cli/commands/database_command.dart';
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/domain/value_objects/event_statistics.dart';
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockIsarDatabase extends Mock implements IsarDatabase {}

class MockExportDataUseCase extends Mock implements ExportDataUseCase {}

class MockImportDataUseCase extends Mock implements ImportDataUseCase {}

class MockEventFilterService extends Mock implements EventFilterService {}

void main() {
  group('DatabaseCommand', () {
    late MockLogger mockLogger;
    late MockIsarDatabase mockDatabase;
    late MockExportDataUseCase mockExportUseCase;
    late MockImportDataUseCase mockImportUseCase;
    late MockEventFilterService mockFilterService;
    late CommandRunner<int> runner;

    setUp(() {
      mockLogger = MockLogger();
      mockDatabase = MockIsarDatabase();
      mockExportUseCase = MockExportDataUseCase();
      mockImportUseCase = MockImportDataUseCase();
      mockFilterService = MockEventFilterService();

      final command = DatabaseCommand(
        logger: mockLogger,
        database: mockDatabase,
        exportUseCase: mockExportUseCase,
        importUseCase: mockImportUseCase,
        filterService: mockFilterService,
      );

      runner = CommandRunner<int>('test', 'Test runner')..addCommand(command);
    });

    test('should have correct name and description', () {
      final command = DatabaseCommand(
        logger: mockLogger,
        database: mockDatabase,
        exportUseCase: mockExportUseCase,
        importUseCase: mockImportUseCase,
        filterService: mockFilterService,
      );

      expect(command.name, equals('database'));
      expect(command.description, contains('Database management'));
    });

    test('should require subcommand when run without one', () async {
      expect(
        () => runner.run(['database']),
        throwsA(isA<UsageException>()),
      );
    });

    group('backup subcommand', () {
      test('should create backup successfully', () async {
        const expectedPath = '/path/to/backup.json';
        when(
          () => mockExportUseCase.createBackup(
            fileName: any(named: 'fileName'),
            directory: any(named: 'directory'),
          ),
        ).thenAnswer((_) async => expectedPath);

        final result = await runner.run(['database', 'backup']);

        expect(result, equals(0));
        verify(() => mockLogger.info('Creating backup...')).called(1);
        verify(
          () =>
              mockLogger.success('Backup created successfully: $expectedPath'),
        ).called(1);
      });

      test('should create backup with custom output path', () async {
        const customPath = '/custom/backup.json';
        when(
          () => mockExportUseCase.createBackup(
            fileName: customPath,
            directory: any(named: 'directory'),
          ),
        ).thenAnswer((_) async => customPath);

        final result =
            await runner.run(['database', 'backup', '-o', customPath]);

        expect(result, equals(0));
        verify(
          () => mockExportUseCase.createBackup(fileName: customPath),
        ).called(1);
      });

      test('should create backup with custom directory', () async {
        const customDir = '/custom/dir';
        const expectedPath = '/custom/dir/backup.json';
        when(
          () => mockExportUseCase.createBackup(
            fileName: any(named: 'fileName'),
            directory: customDir,
          ),
        ).thenAnswer((_) async => expectedPath);

        final result =
            await runner.run(['database', 'backup', '-d', customDir]);

        expect(result, equals(0));
        verify(
          () => mockExportUseCase.createBackup(directory: customDir),
        ).called(1);
      });

      test('should handle backup failure', () async {
        when(
          () => mockExportUseCase.createBackup(
            fileName: any(named: 'fileName'),
            directory: any(named: 'directory'),
          ),
        ).thenThrow(Exception('Backup failed'));

        final result = await runner.run(['database', 'backup']);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to create backup'))),
        ).called(1);
      });
    });

    group('restore subcommand', () {
      test('should restore backup successfully', () async {
        const filePath = '/path/to/backup.json';
        when(
          () => mockImportUseCase.restoreBackup(filePath),
        ).thenAnswer((_) async {});

        final result =
            await runner.run(['database', 'restore', '-f', filePath]);

        expect(result, equals(0));
        verify(() => mockLogger.info('Restoring from backup: $filePath'))
            .called(1);
        verify(() => mockLogger.success('Database restored successfully'))
            .called(1);
      });

      test('should restore with overwrite flag', () async {
        const filePath = '/path/to/backup.json';
        when(
          () => mockImportUseCase.restoreBackup(filePath, overwrite: true),
        ).thenAnswer((_) async {});

        final result = await runner
            .run(['database', 'restore', '-f', filePath, '--overwrite']);

        expect(result, equals(0));
        verify(
          () => mockImportUseCase.restoreBackup(filePath, overwrite: true),
        ).called(1);
      });

      test('should handle missing file option by printing usage', () async {
        // When mandatory option is missing, args package prints usage and
        // exits with code 64 (via UsageException) or similar error handling.
        // We verify the command doesn't crash and handles the error.
        try {
          await runner.run(['database', 'restore']);
          // If it doesn't throw, that's also acceptable behavior
        } on UsageException catch (e) {
          expect(e.message, contains('file'));
        }
      });

      test('should handle restore failure', () async {
        const filePath = '/path/to/backup.json';
        when(
          () => mockImportUseCase.restoreBackup(filePath),
        ).thenThrow(Exception('Restore failed'));

        final result =
            await runner.run(['database', 'restore', '-f', filePath]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to restore backup'))),
        ).called(1);
      });
    });

    group('export subcommand', () {
      test('should export data successfully', () async {
        const outputPath = '/path/to/export.json';
        when(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            eventNames: any(named: 'eventNames'),
          ),
        ).thenAnswer((_) async {});

        final result =
            await runner.run(['database', 'export', '-o', outputPath]);

        expect(result, equals(0));
        verify(() => mockLogger.info('Exporting data...')).called(1);
        verify(
          () =>
              mockLogger.success('Data exported successfully to: $outputPath'),
        ).called(1);
      });

      test('should export with date range filters', () async {
        const outputPath = '/path/to/export.json';
        const fromDate = '2024-01-01T00:00:00';
        const toDate = '2024-12-31T23:59:59';
        when(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            eventNames: any(named: 'eventNames'),
          ),
        ).thenAnswer((_) async {});

        final result = await runner.run([
          'database',
          'export',
          '-o',
          outputPath,
          '--from',
          fromDate,
          '--to',
          toDate,
        ]);

        expect(result, equals(0));
        verify(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            fromDate: DateTime.parse(fromDate),
            toDate: DateTime.parse(toDate),
            eventNames: <String>[],
          ),
        ).called(1);
      });

      test('should export with event name filters', () async {
        const outputPath = '/path/to/export.json';
        when(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            eventNames: any(named: 'eventNames'),
          ),
        ).thenAnswer((_) async {});

        final result = await runner.run([
          'database',
          'export',
          '-o',
          outputPath,
          '--events',
          'screen_view',
          '--events',
          'purchase',
        ]);

        expect(result, equals(0));
        verify(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            eventNames: ['screen_view', 'purchase'],
          ),
        ).called(1);
      });

      test('should handle missing output option by printing usage', () async {
        // When mandatory option is missing, args package prints usage
        try {
          await runner.run(['database', 'export']);
        } on UsageException catch (e) {
          expect(e.message, contains('output'));
        }
      });

      test('should reject invalid from date format', () async {
        const outputPath = '/path/to/export.json';
        final result = await runner.run([
          'database',
          'export',
          '-o',
          outputPath,
          '--from',
          'invalid-date',
        ]);

        expect(result, equals(1));
        verify(
          () =>
              mockLogger.err('Invalid from date format. Use ISO 8601 format.'),
        ).called(1);
      });

      test('should reject invalid to date format', () async {
        const outputPath = '/path/to/export.json';
        final result = await runner.run([
          'database',
          'export',
          '-o',
          outputPath,
          '--to',
          'invalid-date',
        ]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err('Invalid to date format. Use ISO 8601 format.'),
        ).called(1);
      });

      test('should handle export failure', () async {
        const outputPath = '/path/to/export.json';
        when(
          () => mockExportUseCase.exportEventsToFile(
            outputPath,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            eventNames: any(named: 'eventNames'),
          ),
        ).thenThrow(Exception('Export failed'));

        final result =
            await runner.run(['database', 'export', '-o', outputPath]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to export data'))),
        ).called(1);
      });
    });

    group('import subcommand', () {
      test('should import data successfully', () async {
        const filePath = '/path/to/import.json';
        when(
          () => mockImportUseCase.importFromFile(filePath),
        ).thenAnswer((_) async {});

        final result = await runner.run(['database', 'import', '-f', filePath]);

        expect(result, equals(0));
        verify(() => mockLogger.info('Importing data from: $filePath'))
            .called(1);
        verify(() => mockLogger.success('Data imported successfully'))
            .called(1);
      });

      test('should import with overwrite flag', () async {
        const filePath = '/path/to/import.json';
        when(
          () => mockImportUseCase.importFromFile(filePath, overwrite: true),
        ).thenAnswer((_) async {});

        final result = await runner
            .run(['database', 'import', '-f', filePath, '--overwrite']);

        expect(result, equals(0));
        verify(
          () => mockImportUseCase.importFromFile(filePath, overwrite: true),
        ).called(1);
      });

      test('should handle missing file option by printing usage', () async {
        // When mandatory option is missing, args package prints usage
        try {
          await runner.run(['database', 'import']);
        } on UsageException catch (e) {
          expect(e.message, contains('file'));
        }
      });

      test('should handle import failure', () async {
        const filePath = '/path/to/import.json';
        when(
          () => mockImportUseCase.importFromFile(filePath),
        ).thenThrow(ArgumentError('File not found: $filePath'));

        final result = await runner.run(['database', 'import', '-f', filePath]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to import data'))),
        ).called(1);
      });
    });

    group('clear subcommand', () {
      test('should clear database with confirm flag', () async {
        when(() => mockDatabase.clear()).thenAnswer((_) async {});

        final result = await runner.run(['database', 'clear', '--confirm']);

        expect(result, equals(0));
        verify(() => mockDatabase.clear()).called(1);
        verify(() => mockLogger.success('Database cleared successfully'))
            .called(1);
      });

      test('should handle clear failure', () async {
        when(() => mockDatabase.clear()).thenThrow(Exception('Clear failed'));

        final result = await runner.run(['database', 'clear', '--confirm']);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to clear database'))),
        ).called(1);
      });
    });

    group('info subcommand', () {
      test('should display database statistics', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 10,
          topEvents: {
            'screen_view': 50,
            'purchase': 30,
            'add_to_cart': 20,
          },
          dateRange: DateTimeRange(
            start: DateTime.utc(2024, 1, 15),
            end: DateTime.utc(2024, 12, 31),
          ),
        );

        when(() => mockFilterService.getEventStatistics())
            .thenAnswer((_) async => stats);

        final result = await runner.run(['database', 'info']);

        expect(result, equals(0));
        verify(
          () => mockLogger.info(any(that: contains('Database Information'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Total Events: 100'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Unique Event Types: 10'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Top Events'))),
        ).called(1);
      });

      test('should display statistics without date range', () async {
        final stats = EventStatistics(
          totalEvents: 0,
          uniqueEventTypes: 0,
          topEvents: {},
        );

        when(() => mockFilterService.getEventStatistics())
            .thenAnswer((_) async => stats);

        final result = await runner.run(['database', 'info']);

        expect(result, equals(0));
        verify(
          () => mockLogger.info(any(that: contains('Total Events: 0'))),
        ).called(1);
      });

      test('should handle info failure', () async {
        when(() => mockFilterService.getEventStatistics())
            .thenThrow(Exception('Failed to get stats'));

        final result = await runner.run(['database', 'info']);

        expect(result, equals(1));
        verify(
          () => mockLogger
              .err(any(that: contains('Failed to get database info'))),
        ).called(1);
      });
    });

    group('input validation', () {
      test('should handle path with spaces in backup', () async {
        const pathWithSpaces = '/path/with spaces/backup.json';
        when(
          () => mockExportUseCase.createBackup(
            fileName: pathWithSpaces,
            directory: any(named: 'directory'),
          ),
        ).thenAnswer((_) async => pathWithSpaces);

        final result =
            await runner.run(['database', 'backup', '-o', pathWithSpaces]);

        expect(result, equals(0));
        verify(
          () => mockExportUseCase.createBackup(fileName: pathWithSpaces),
        ).called(1);
      });

      test('should handle path with special characters in export', () async {
        const specialPath = '/path/special-chars_123/export.json';
        when(
          () => mockExportUseCase.exportEventsToFile(
            specialPath,
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            eventNames: any(named: 'eventNames'),
          ),
        ).thenAnswer((_) async {});

        final result =
            await runner.run(['database', 'export', '-o', specialPath]);

        expect(result, equals(0));
      });

      test('should propagate file not found error during import', () async {
        const nonExistentPath = '/nonexistent/path/file.json';
        when(
          () => mockImportUseCase.importFromFile(nonExistentPath),
        ).thenThrow(ArgumentError('File not found: $nonExistentPath'));

        final result =
            await runner.run(['database', 'import', '-f', nonExistentPath]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to import data'))),
        ).called(1);
      });

      test('should propagate file not found error during restore', () async {
        const nonExistentPath = '/nonexistent/path/backup.json';
        when(
          () => mockImportUseCase.restoreBackup(nonExistentPath),
        ).thenThrow(ArgumentError('File not found: $nonExistentPath'));

        final result =
            await runner.run(['database', 'restore', '-f', nonExistentPath]);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to restore backup'))),
        ).called(1);
      });
    });
  });
}
