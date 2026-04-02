//@GeneratedMicroModule;FamonCorePackageModule;package:famon_core/src/core_injection.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i2;

import 'package:famon_core/src/core/application/services/event_filter_service.dart'
    as _i20;
import 'package:famon_core/src/core/application/use_cases/export_data_use_case.dart'
    as _i18;
import 'package:famon_core/src/core/application/use_cases/import_data_use_case.dart'
    as _i19;
import 'package:famon_core/src/core/domain/repositories/data_export_repository.dart'
    as _i13;
import 'package:famon_core/src/core/domain/repositories/event_repository.dart'
    as _i15;
import 'package:famon_core/src/core/infrastructure/data_sources/database_directory_resolver.dart'
    as _i3;
import 'package:famon_core/src/core/infrastructure/data_sources/isar_database.dart'
    as _i7;
import 'package:famon_core/src/core/infrastructure/repositories/isar_data_export_repository.dart'
    as _i14;
import 'package:famon_core/src/core/infrastructure/repositories/isar_event_metadata_repository.dart'
    as _i16;
import 'package:famon_core/src/core/infrastructure/repositories/isar_event_repository.dart'
    as _i17;
import 'package:famon_core/src/services/event_cache_service.dart' as _i5;
import 'package:famon_core/src/services/interfaces/event_cache_interface.dart'
    as _i4;
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart'
    as _i9;
import 'package:famon_core/src/services/log_parser_factory.dart' as _i8;
import 'package:famon_core/src/services/log_parser_service.dart' as _i10;
import 'package:famon_core/src/services/log_source_factory.dart' as _i11;
import 'package:injectable/injectable.dart' as _i1;
import 'package:mason_logger/mason_logger.dart' as _i6;
import 'package:process/process.dart' as _i12;

class FamonCorePackageModule extends _i1.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i2.FutureOr<void> init(_i1.GetItHelper gh) {
    gh.factory<_i3.DatabaseDirectoryResolver>(
        () => _i3.DatabaseDirectoryResolver());
    gh.lazySingleton<_i4.EventCacheInterface>(
        () => _i5.EventCacheService(logger: gh<_i6.Logger>()));
    gh.singleton<_i7.IsarDatabase>(
      () => _i7.IsarDatabase(gh<_i3.DatabaseDirectoryResolver>()),
      dispose: (i) => i.close(),
    );
    gh.factory<_i8.LogParserFactory>(
        () => _i8.LogParserFactory(gh<_i6.Logger>()));
    gh.factory<_i9.LogParserInterface>(
        () => _i10.LogParserService(logger: gh<_i6.Logger>()));
    gh.factory<_i11.LogSourceFactory>(() => _i11.LogSourceFactory(
          gh<_i12.ProcessManager>(),
          gh<_i6.Logger>(),
        ));
    gh.factory<_i13.DataExportRepository>(
        () => _i14.IsarDataExportRepository(database: gh<_i7.IsarDatabase>()));
    gh.factory<_i15.EventMetadataRepository>(() =>
        _i16.IsarEventMetadataRepository(database: gh<_i7.IsarDatabase>()));
    gh.factory<_i15.EventRepository>(
        () => _i17.IsarEventRepository(database: gh<_i7.IsarDatabase>()));
    gh.factory<_i18.ExportDataUseCase>(
        () => _i18.ExportDataUseCase(gh<_i13.DataExportRepository>()));
    gh.factory<_i19.ImportDataUseCase>(
        () => _i19.ImportDataUseCase(gh<_i13.DataExportRepository>()));
    gh.factory<_i20.EventFilterService>(() =>
        _i20.EventFilterService(eventRepository: gh<_i15.EventRepository>()));
  }
}
