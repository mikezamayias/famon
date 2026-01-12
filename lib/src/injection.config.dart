// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_analytics_monitor/src/cli/commands/database_command.dart'
    as _i20;
import 'package:firebase_analytics_monitor/src/cli/commands/filtered_monitor_command.dart'
    as _i19;
import 'package:firebase_analytics_monitor/src/commands/monitor_command.dart'
    as _i17;
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart'
    as _i18;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart'
    as _i15;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart'
    as _i16;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/data_export_repository.dart'
    as _i11;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart'
    as _i13;
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart'
    as _i6;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_data_export_repository.dart'
    as _i12;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_event_repository.dart'
    as _i14;
import 'package:firebase_analytics_monitor/src/di/register_module.dart' as _i21;
import 'package:firebase_analytics_monitor/src/services/event_cache_service.dart'
    as _i4;
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart'
    as _i3;
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart'
    as _i7;
import 'package:firebase_analytics_monitor/src/services/log_parser_service.dart'
    as _i8;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:mason_logger/mason_logger.dart' as _i5;
import 'package:process/process.dart' as _i9;
import 'package:pub_updater/pub_updater.dart' as _i10;

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
    gh.lazySingleton<_i3.EventCacheInterface>(
        () => _i4.EventCacheService(logger: gh<_i5.Logger>()));
    gh.singleton<_i6.IsarDatabase>(() => _i6.IsarDatabase());
    gh.factory<_i7.LogParserInterface>(
        () => _i8.LogParserService(logger: gh<_i5.Logger>()));
    gh.singleton<_i5.Logger>(() => registerModule.logger);
    gh.singleton<_i9.ProcessManager>(() => registerModule.processManager);
    gh.singleton<_i10.PubUpdater>(() => registerModule.pubUpdater);
    gh.factory<_i11.DataExportRepository>(
        () => _i12.IsarDataExportRepository(database: gh<_i6.IsarDatabase>()));
    gh.factory<_i13.EventRepository>(
        () => _i14.IsarEventRepository(database: gh<_i6.IsarDatabase>()));
    gh.factory<_i15.ExportDataUseCase>(
        () => _i15.ExportDataUseCase(gh<_i11.DataExportRepository>()));
    gh.factory<_i16.ImportDataUseCase>(
        () => _i16.ImportDataUseCase(gh<_i11.DataExportRepository>()));
    gh.factory<_i17.MonitorCommand>(() => _i17.MonitorCommand(
          logger: gh<_i5.Logger>(),
          processManager: gh<_i9.ProcessManager>(),
          logParser: gh<_i7.LogParserInterface>(),
          eventCache: gh<_i3.EventCacheInterface>(),
        ));
    gh.factory<_i18.EventFilterService>(() =>
        _i18.EventFilterService(eventRepository: gh<_i13.EventRepository>()));
    gh.factory<_i19.FilteredMonitorCommand>(() => _i19.FilteredMonitorCommand(
          logger: gh<_i5.Logger>(),
          processManager: gh<_i9.ProcessManager>(),
          logParser: gh<_i7.LogParserInterface>(),
          filterService: gh<_i18.EventFilterService>(),
          eventRepository: gh<_i13.EventRepository>(),
        ));
    gh.factory<_i20.DatabaseCommand>(() => _i20.DatabaseCommand(
          logger: gh<_i5.Logger>(),
          database: gh<_i6.IsarDatabase>(),
          exportUseCase: gh<_i15.ExportDataUseCase>(),
          importUseCase: gh<_i16.ImportDataUseCase>(),
          filterService: gh<_i18.EventFilterService>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i21.RegisterModule {}
