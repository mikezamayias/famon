// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_analytics_monitor/src/cli/commands/database_command.dart'
    as _i31;
import 'package:firebase_analytics_monitor/src/cli/commands/filtered_monitor_command.dart'
    as _i30;
import 'package:firebase_analytics_monitor/src/commands/monitor_command.dart'
    as _i27;
import 'package:firebase_analytics_monitor/src/commands/publish_command.dart'
    as _i16;
import 'package:firebase_analytics_monitor/src/commands/update_command.dart'
    as _i18;
import 'package:firebase_analytics_monitor/src/config/shortcuts_config_loader.dart'
    as _i17;
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart'
    as _i29;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/export_data_use_case.dart'
    as _i23;
import 'package:firebase_analytics_monitor/src/core/application/use_cases/import_data_use_case.dart'
    as _i24;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/data_export_repository.dart'
    as _i19;
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart'
    as _i21;
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/database_directory_resolver.dart'
    as _i6;
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_database.dart'
    as _i11;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_data_export_repository.dart'
    as _i20;
import 'package:firebase_analytics_monitor/src/core/infrastructure/repositories/isar_event_repository.dart'
    as _i22;
import 'package:firebase_analytics_monitor/src/di/register_module.dart' as _i32;
import 'package:firebase_analytics_monitor/src/keyboard/actions/action_registry.dart'
    as _i3;
import 'package:firebase_analytics_monitor/src/keyboard/keyboard_input_service.dart'
    as _i12;
import 'package:firebase_analytics_monitor/src/keyboard/shortcut_manager.dart'
    as _i28;
import 'package:firebase_analytics_monitor/src/platform/clipboard_service.dart'
    as _i4;
import 'package:firebase_analytics_monitor/src/platform/file_dialog_service.dart'
    as _i10;
import 'package:firebase_analytics_monitor/src/services/event_cache_service.dart'
    as _i8;
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart'
    as _i7;
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart'
    as _i13;
import 'package:firebase_analytics_monitor/src/services/log_parser_factory.dart'
    as _i25;
import 'package:firebase_analytics_monitor/src/services/log_parser_service.dart'
    as _i14;
import 'package:firebase_analytics_monitor/src/services/log_source_factory.dart'
    as _i26;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:mason_logger/mason_logger.dart' as _i9;
import 'package:process/process.dart' as _i5;
import 'package:pub_updater/pub_updater.dart' as _i15;

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
    gh.lazySingleton<_i3.ActionRegistry>(() => _i3.ActionRegistry());
    gh.factory<_i4.ClipboardService>(
        () => _i4.ClipboardService(processManager: gh<_i5.ProcessManager>()));
    gh.factory<_i6.DatabaseDirectoryResolver>(
        () => _i6.DatabaseDirectoryResolver());
    gh.lazySingleton<_i7.EventCacheInterface>(
        () => _i8.EventCacheService(logger: gh<_i9.Logger>()));
    gh.factory<_i10.FileDialogService>(() => _i10.FileDialogService(
          processManager: gh<_i5.ProcessManager>(),
          logger: gh<_i9.Logger>(),
        ));
    gh.singleton<_i11.IsarDatabase>(
      () => _i11.IsarDatabase(gh<_i6.DatabaseDirectoryResolver>()),
      dispose: (i) => i.close(),
    );
    gh.factory<_i12.KeyboardInputService>(() => _i12.KeyboardInputService());
    gh.factory<_i13.LogParserInterface>(
        () => _i14.LogParserService(logger: gh<_i9.Logger>()));
    gh.singleton<_i9.Logger>(() => registerModule.logger);
    gh.singleton<_i5.ProcessManager>(() => registerModule.processManager);
    gh.singleton<_i15.PubUpdater>(() => registerModule.pubUpdater);
    gh.factory<_i16.PublishCommand>(() => _i16.PublishCommand(
          logger: gh<_i9.Logger>(),
          processManager: gh<_i5.ProcessManager>(),
        ));
    gh.factory<_i17.ShortcutsConfigLoader>(() => _i17.ShortcutsConfigLoader());
    gh.factory<_i18.UpdateCommand>(() => _i18.UpdateCommand(
          logger: gh<_i9.Logger>(),
          pubUpdater: gh<_i15.PubUpdater>(),
        ));
    gh.factory<_i19.DataExportRepository>(
        () => _i20.IsarDataExportRepository(database: gh<_i11.IsarDatabase>()));
    gh.factory<_i21.EventRepository>(
        () => _i22.IsarEventRepository(database: gh<_i11.IsarDatabase>()));
    gh.factory<_i23.ExportDataUseCase>(
        () => _i23.ExportDataUseCase(gh<_i19.DataExportRepository>()));
    gh.factory<_i24.ImportDataUseCase>(
        () => _i24.ImportDataUseCase(gh<_i19.DataExportRepository>()));
    gh.factory<_i25.LogParserFactory>(
        () => _i25.LogParserFactory(gh<_i9.Logger>()));
    gh.factory<_i26.LogSourceFactory>(() => _i26.LogSourceFactory(
          gh<_i5.ProcessManager>(),
          gh<_i9.Logger>(),
        ));
    gh.factory<_i27.MonitorCommand>(() => _i27.MonitorCommand(
          logger: gh<_i9.Logger>(),
          logSourceFactory: gh<_i26.LogSourceFactory>(),
          logParserFactory: gh<_i25.LogParserFactory>(),
          eventCache: gh<_i7.EventCacheInterface>(),
        ));
    gh.factory<_i28.ShortcutManager>(() => _i28.ShortcutManager(
          actionRegistry: gh<_i3.ActionRegistry>(),
          configLoader: gh<_i17.ShortcutsConfigLoader>(),
          logger: gh<_i9.Logger>(),
        ));
    gh.factory<_i29.EventFilterService>(() =>
        _i29.EventFilterService(eventRepository: gh<_i21.EventRepository>()));
    gh.factory<_i30.FilteredMonitorDependencies>(
        () => _i30.FilteredMonitorDependencies(
              logger: gh<_i9.Logger>(),
              processManager: gh<_i5.ProcessManager>(),
              logParser: gh<_i13.LogParserInterface>(),
              filterService: gh<_i29.EventFilterService>(),
              eventRepository: gh<_i21.EventRepository>(),
            ));
    gh.factory<_i31.DatabaseCommand>(() => _i31.DatabaseCommand(
          logger: gh<_i9.Logger>(),
          database: gh<_i11.IsarDatabase>(),
          exportUseCase: gh<_i23.ExportDataUseCase>(),
          importUseCase: gh<_i24.ImportDataUseCase>(),
          filterService: gh<_i29.EventFilterService>(),
        ));
    gh.factory<_i30.FilteredMonitorCommand>(() =>
        _i30.FilteredMonitorCommand(gh<_i30.FilteredMonitorDependencies>()));
    return this;
  }
}

class _$RegisterModule extends _i32.RegisterModule {}
