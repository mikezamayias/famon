// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:famon/src/cli/commands/database_command.dart' as _i892;
import 'package:famon/src/cli/commands/filtered_monitor_command.dart' as _i796;
import 'package:famon/src/commands/issue_command.dart' as _i742;
import 'package:famon/src/commands/monitor_command.dart' as _i376;
import 'package:famon/src/commands/update_command.dart' as _i540;
import 'package:famon/src/config/shortcuts_config_loader.dart' as _i172;
import 'package:famon/src/di/register_module.dart' as _i60;
import 'package:famon/src/keyboard/actions/action_registry.dart' as _i758;
import 'package:famon/src/keyboard/keyboard_input_service.dart' as _i903;
import 'package:famon/src/keyboard/shortcut_manager.dart' as _i213;
import 'package:famon/src/platform/clipboard_service.dart' as _i170;
import 'package:famon/src/platform/file_dialog_service.dart' as _i61;
import 'package:famon_core/core_injection_module.dart' as _i800;
import 'package:famon_core/famon_core.dart' as _i985;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mason_logger/mason_logger.dart' as _i92;
import 'package:process/process.dart' as _i1005;
import 'package:pub_updater/pub_updater.dart' as _i806;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    await _i800.FamonCorePackageModule().init(gh);
    final registerModule = _$RegisterModule();
    gh.factory<_i172.ShortcutsConfigLoader>(
        () => _i172.ShortcutsConfigLoader());
    gh.factory<_i903.KeyboardInputService>(() => _i903.KeyboardInputService());
    gh.singleton<_i92.Logger>(() => registerModule.logger);
    gh.singleton<_i1005.ProcessManager>(() => registerModule.processManager);
    gh.singleton<_i806.PubUpdater>(() => registerModule.pubUpdater);
    gh.lazySingleton<_i758.ActionRegistry>(() => _i758.ActionRegistry());
    gh.factory<_i376.MonitorCommand>(() => _i376.MonitorCommand(
          logger: gh<_i92.Logger>(),
          logSourceFactory: gh<_i985.LogSourceFactory>(),
          logParserFactory: gh<_i985.LogParserFactory>(),
          eventCache: gh<_i985.EventCacheInterface>(),
        ));
    gh.factory<_i540.UpdateCommand>(() => _i540.UpdateCommand(
          logger: gh<_i92.Logger>(),
          pubUpdater: gh<_i806.PubUpdater>(),
        ));
    gh.factory<_i892.DatabaseCommand>(() => _i892.DatabaseCommand(
          logger: gh<_i92.Logger>(),
          database: gh<_i985.IsarDatabase>(),
          exportUseCase: gh<_i985.ExportDataUseCase>(),
          importUseCase: gh<_i985.ImportDataUseCase>(),
          filterService: gh<_i985.EventFilterService>(),
        ));
    gh.factory<_i170.ClipboardService>(() =>
        _i170.ClipboardService(processManager: gh<_i1005.ProcessManager>()));
    gh.factory<_i61.FileDialogService>(() => _i61.FileDialogService(
          processManager: gh<_i1005.ProcessManager>(),
          logger: gh<_i92.Logger>(),
        ));
    gh.factory<_i213.ShortcutManager>(() => _i213.ShortcutManager(
          actionRegistry: gh<_i758.ActionRegistry>(),
          configLoader: gh<_i172.ShortcutsConfigLoader>(),
          logger: gh<_i92.Logger>(),
        ));
    gh.factory<_i796.FilteredMonitorDependencies>(
        () => _i796.FilteredMonitorDependencies(
              logger: gh<_i92.Logger>(),
              processManager: gh<_i1005.ProcessManager>(),
              logParser: gh<_i985.LogParserInterface>(),
              filterService: gh<_i985.EventFilterService>(),
              eventRepository: gh<_i985.EventRepository>(),
            ));
    gh.factory<_i742.IssueCommand>(() => _i742.IssueCommand(
          logger: gh<_i92.Logger>(),
          processManager: gh<_i1005.ProcessManager>(),
          clipboard: gh<_i170.ClipboardService>(),
        ));
    gh.factory<_i796.FilteredMonitorCommand>(() =>
        _i796.FilteredMonitorCommand(gh<_i796.FilteredMonitorDependencies>()));
    return this;
  }
}

class _$RegisterModule extends _i60.RegisterModule {}
