// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_analytics_monitor/src/cli/commands/database_command.dart'
    as _i24;
import 'package:firebase_analytics_monitor/src/cli/commands/filtered_monitor_command.dart'
    as _i23;
import 'package:firebase_analytics_monitor/src/commands/monitor_command.dart'
    as _i21;
import 'package:firebase_analytics_monitor/src/commands/update_command.dart'
    as _i12;
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart'
    as _i22;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart'
    as _i17;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart'
    as _i18;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/data_export_repository.dart'
    as _i13;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart'
    as _i15;
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/database_directory_resolver.dart'
    as _i3;
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart'
    as _i7;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_data_export_repository.dart'
    as _i14;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_event_repository.dart'
    as _i16;
import 'package:firebase_analytics_monitor/src/di/register_module.dart' as _i25;
import 'package:firebase_analytics_monitor/src/services/event_cache_service.dart'
    as _i5;
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart'
    as _i4;
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart'
    as _i8;
import 'package:firebase_analytics_monitor/src/services/log_parser_factory.dart'
    as _i19;
import 'package:firebase_analytics_monitor/src/services/log_parser_service.dart'
    as _i9;
import 'package:firebase_analytics_monitor/src/services/log_source_factory.dart'
    as _i20;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:mason_logger/mason_logger.dart' as _i6;
import 'package:process/process.dart' as _i10;
import 'package:pub_updater/pub_updater.dart' as _i11;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.factory<_i3.DatabaseDirectoryResolver>(
        () => _i3.DatabaseDirectoryResolver());
    gh.lazySingleton<_i4.EventCacheInterface>(
        () => _i5.EventCacheService(logger: gh<_i6.Logger>()));
    gh.singleton<_i7.IsarDatabase>(
      () => _i7.IsarDatabase(gh<_i3.DatabaseDirectoryResolver>()),
      dispose: (i) => i.close(),
    );
    gh.factory<_i8.LogParserInterface>(
        () => _i9.LogParserService(logger: gh<_i6.Logger>()));
    gh.singleton<_i6.Logger>(() => registerModule.logger);
    gh.singleton<_i10.ProcessManager>(() => registerModule.processManager);
    gh.singleton<_i11.PubUpdater>(() => registerModule.pubUpdater);
    gh.factory<_i12.UpdateCommand>(() => _i12.UpdateCommand(
          logger: gh<_i6.Logger>(),
          pubUpdater: gh<_i11.PubUpdater>(),
        ));
    gh.factory<_i13.DataExportRepository>(
        () => _i14.IsarDataExportRepository(database: gh<_i7.IsarDatabase>()));
    gh.factory<_i15.EventRepository>(
        () => _i16.IsarEventRepository(database: gh<_i7.IsarDatabase>()));
    gh.factory<_i17.ExportDataUseCase>(
        () => _i17.ExportDataUseCase(gh<_i13.DataExportRepository>()));
    gh.factory<_i18.ImportDataUseCase>(
        () => _i18.ImportDataUseCase(gh<_i13.DataExportRepository>()));
    gh.factory<_i19.LogParserFactory>(
        () => _i19.LogParserFactory(gh<_i6.Logger>()));
    gh.factory<_i20.LogSourceFactory>(() => _i20.LogSourceFactory(
          gh<_i10.ProcessManager>(),
          gh<_i6.Logger>(),
        ));
    gh.factory<_i21.MonitorCommand>(() => _i21.MonitorCommand(
          logger: gh<_i6.Logger>(),
          logSourceFactory: gh<_i20.LogSourceFactory>(),
          logParserFactory: gh<_i19.LogParserFactory>(),
          eventCache: gh<_i4.EventCacheInterface>(),
        ));
    gh.factory<_i22.EventFilterService>(() =>
        _i22.EventFilterService(eventRepository: gh<_i15.EventRepository>()));
    gh.factory<_i23.FilteredMonitorDependencies>(
        () => _i23.FilteredMonitorDependencies(
              logger: gh<_i6.Logger>(),
              processManager: gh<_i10.ProcessManager>(),
              logParser: gh<_i8.LogParserInterface>(),
              filterService: gh<_i22.EventFilterService>(),
              eventRepository: gh<_i15.EventRepository>(),
            ));
    gh.factory<_i24.DatabaseCommand>(() => _i24.DatabaseCommand(
          logger: gh<_i6.Logger>(),
          database: gh<_i7.IsarDatabase>(),
          exportUseCase: gh<_i17.ExportDataUseCase>(),
          importUseCase: gh<_i18.ImportDataUseCase>(),
          filterService: gh<_i22.EventFilterService>(),
        ));
    gh.factory<_i23.FilteredMonitorCommand>(() =>
        _i23.FilteredMonitorCommand(gh<_i23.FilteredMonitorDependencies>()));
    return this;
  }
}

class _$RegisterModule extends _i25.RegisterModule {}
