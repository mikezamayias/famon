import 'package:firebase_analytics_monitor/src/commands/commands.dart';
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/core/domain/repositories/data_export_repository.dart';
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart';
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart';
import 'package:firebase_analytics_monitor/src/injection.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/services/log_parser_factory.dart';
import 'package:firebase_analytics_monitor/src/services/log_source_factory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';

/// Mock classes for testing
class MockLogParser extends Mock implements LogParserInterface {}

class MockEventCache extends Mock implements EventCacheInterface {}

class MockLogger extends Mock implements Logger {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockIsarDatabase extends Mock implements IsarDatabase {}

class MockEventRepository extends Mock implements EventRepository {}

class MockDataExportRepository extends Mock implements DataExportRepository {}

class MockEventFilterService extends Mock implements EventFilterService {}

class MockExportDataUseCase extends Mock implements ExportDataUseCase {}

class MockImportDataUseCase extends Mock implements ImportDataUseCase {}

class MockLogSourceFactory extends Mock implements LogSourceFactory {}

class MockLogParserFactory extends Mock implements LogParserFactory {}

/// Create a mock analytics event for testing
AnalyticsEvent createMockAnalyticsEvent({
  String eventName = 'test_event',
  String rawTimestamp = '12-25 10:30:45.123',
  Map<String, String>? parameters,
  List<Map<String, String>>? items,
}) {
  return AnalyticsEvent.fromParsedLog(
    eventName: eventName,
    rawTimestamp: rawTimestamp,
    parameters: parameters ?? const {},
    items: items ?? const [],
  );
}

/// Sets up mock dependencies for testing.
///
/// Should be called in setUp() of tests that require DI.
Future<void> setUpTestDependencies({
  Logger? logger,
  ProcessManager? processManager,
  PubUpdater? pubUpdater,
  LogParserInterface? logParser,
  LogParserFactory? logParserFactory,
  EventCacheInterface? eventCache,
  IsarDatabase? database,
  EventRepository? eventRepository,
  DataExportRepository? dataExportRepository,
  EventFilterService? filterService,
  ExportDataUseCase? exportUseCase,
  ImportDataUseCase? importUseCase,
  LogSourceFactory? logSourceFactory,
}) async {
  // Reset GetIt to clean state
  await getIt.reset();

  final resolvedLogger = logger ?? MockLogger();
  final resolvedProcessManager = processManager ?? const LocalProcessManager();
  final resolvedDatabase = database ?? MockIsarDatabase();
  final resolvedLogParser = logParser ?? MockLogParser();
  final resolvedEventCache = eventCache ?? MockEventCache();
  final resolvedEventRepository = eventRepository ?? MockEventRepository();
  final resolvedDataExportRepository =
      dataExportRepository ?? MockDataExportRepository();
  final resolvedFilterService = filterService ?? MockEventFilterService();
  final resolvedExportUseCase = exportUseCase ?? MockExportDataUseCase();
  final resolvedImportUseCase = importUseCase ?? MockImportDataUseCase();
  final resolvedLogSourceFactory = logSourceFactory ?? MockLogSourceFactory();
  final resolvedLogParserFactory = logParserFactory ?? MockLogParserFactory();

  // Register core dependencies
  getIt
    ..registerSingleton<Logger>(resolvedLogger)
    ..registerSingleton<ProcessManager>(resolvedProcessManager)
    ..registerSingleton<PubUpdater>(pubUpdater ?? MockPubUpdater())
    ..registerSingleton<LogParserInterface>(resolvedLogParser)
    ..registerLazySingleton<EventCacheInterface>(() => resolvedEventCache)
    ..registerSingleton<IsarDatabase>(resolvedDatabase)
    ..registerSingleton<EventRepository>(resolvedEventRepository)
    ..registerSingleton<DataExportRepository>(resolvedDataExportRepository)
    ..registerSingleton<EventFilterService>(resolvedFilterService)
    ..registerSingleton<ExportDataUseCase>(resolvedExportUseCase)
    ..registerSingleton<ImportDataUseCase>(resolvedImportUseCase)
    ..registerSingleton<LogSourceFactory>(resolvedLogSourceFactory)
    ..registerSingleton<LogParserFactory>(resolvedLogParserFactory)
    // Register commands that are resolved via DI in the command runner
    ..registerFactory<MonitorCommand>(
      () => MonitorCommand(
        logger: resolvedLogger,
        logSourceFactory: resolvedLogSourceFactory,
        logParserFactory: resolvedLogParserFactory,
        eventCache: resolvedEventCache,
      ),
    )
    ..registerFactory<FilteredMonitorDependencies>(
      () => FilteredMonitorDependencies(
        logger: resolvedLogger,
        processManager: resolvedProcessManager,
        logParser: resolvedLogParser,
        filterService: resolvedFilterService,
        eventRepository: resolvedEventRepository,
      ),
    )
    ..registerFactory<FilteredMonitorCommand>(
      () => FilteredMonitorCommand(getIt<FilteredMonitorDependencies>()),
    )
    ..registerFactory<DatabaseCommand>(
      () => DatabaseCommand(
        logger: resolvedLogger,
        database: resolvedDatabase,
        exportUseCase: resolvedExportUseCase,
        importUseCase: resolvedImportUseCase,
        filterService: resolvedFilterService,
      ),
    )
    ..registerFactory<UpdateCommand>(
      () => UpdateCommand(
        logger: resolvedLogger,
        pubUpdater: getIt<PubUpdater>(),
      ),
    );
}

/// Tears down test dependencies.
///
/// Should be called in tearDown() of tests that require DI.
Future<void> tearDownTestDependencies() async {
  await getIt.reset();
}
