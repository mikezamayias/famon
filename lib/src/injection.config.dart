// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:famon/src/cli/commands/database_command.dart' as _i15;
import 'package:famon/src/cli/commands/filtered_monitor_command.dart' as _i16;
import 'package:famon/src/commands/issue_command.dart' as _i17;
import 'package:famon/src/commands/monitor_command.dart' as _i10;
import 'package:famon/src/commands/update_command.dart' as _i14;
import 'package:famon/src/config/shortcuts_config_loader.dart' as _i13;
import 'package:famon/src/di/register_module.dart' as _i19;
import 'package:famon/src/keyboard/actions/action_registry.dart' as _i4;
import 'package:famon/src/keyboard/keyboard_input_service.dart' as _i9;
import 'package:famon/src/keyboard/shortcut_manager.dart' as _i18;
import 'package:famon/src/platform/clipboard_service.dart' as _i5;
import 'package:famon/src/platform/file_dialog_service.dart' as _i7;
import 'package:famon_core/famon_core.dart' as _i11;
import 'package:famon_core/src/core_injection.module.dart' as _i3;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:mason_logger/mason_logger.dart' as _i8;
import 'package:process/process.dart' as _i6;
import 'package:pub_updater/pub_updater.dart' as _i12;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    await _i3.FamonCorePackageModule().init(gh);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i4.ActionRegistry>(() => _i4.ActionRegistry());
    gh.factory<_i5.ClipboardService>(
        () => _i5.ClipboardService(processManager: gh<_i6.ProcessManager>()));
    gh.factory<_i7.FileDialogService>(() => _i7.FileDialogService(
          processManager: gh<_i6.ProcessManager>(),
          logger: gh<_i8.Logger>(),
        ));
    gh.factory<_i9.KeyboardInputService>(() => _i9.KeyboardInputService());
    gh.singleton<_i8.Logger>(() => registerModule.logger);
    gh.factory<_i10.MonitorCommand>(() => _i10.MonitorCommand(
          logger: gh<_i8.Logger>(),
          logSourceFactory: gh<_i11.LogSourceFactory>(),
          logParserFactory: gh<_i11.LogParserFactory>(),
          eventCache: gh<_i11.EventCacheInterface>(),
        ));
    gh.singleton<_i6.ProcessManager>(() => registerModule.processManager);
    gh.singleton<_i12.PubUpdater>(() => registerModule.pubUpdater);
    gh.factory<_i13.ShortcutsConfigLoader>(() => _i13.ShortcutsConfigLoader());
    gh.factory<_i14.UpdateCommand>(() => _i14.UpdateCommand(
          logger: gh<_i8.Logger>(),
          pubUpdater: gh<_i12.PubUpdater>(),
        ));
    gh.factory<_i15.DatabaseCommand>(() => _i15.DatabaseCommand(
          logger: gh<_i8.Logger>(),
          database: gh<_i11.IsarDatabase>(),
          exportUseCase: gh<_i11.ExportDataUseCase>(),
          importUseCase: gh<_i11.ImportDataUseCase>(),
          filterService: gh<_i11.EventFilterService>(),
        ));
    gh.factory<_i16.FilteredMonitorDependencies>(
        () => _i16.FilteredMonitorDependencies(
              logger: gh<_i8.Logger>(),
              processManager: gh<_i6.ProcessManager>(),
              logParser: gh<_i11.LogParserInterface>(),
              filterService: gh<_i11.EventFilterService>(),
              eventRepository: gh<_i11.EventRepository>(),
            ));
    gh.factory<_i17.IssueCommand>(() => _i17.IssueCommand(
          logger: gh<_i8.Logger>(),
          processManager: gh<_i6.ProcessManager>(),
          clipboard: gh<_i5.ClipboardService>(),
        ));
    gh.factory<_i18.ShortcutManager>(() => _i18.ShortcutManager(
          actionRegistry: gh<_i4.ActionRegistry>(),
          configLoader: gh<_i13.ShortcutsConfigLoader>(),
          logger: gh<_i8.Logger>(),
        ));
    gh.factory<_i16.FilteredMonitorCommand>(() =>
        _i16.FilteredMonitorCommand(gh<_i16.FilteredMonitorDependencies>()));
    return this;
  }
}

class _$RegisterModule extends _i19.RegisterModule {}
