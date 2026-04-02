import 'package:famon/src/injection.config.dart';
// ignore: implementation_imports, injectable micro-package module must be imported directly
import 'package:famon_core/src/core_injection.module.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Configure dependencies using injectable.
///
/// Registers core services from famon_core, then CLI-specific services.
@InjectableInit(
  externalPackageModulesBefore: [ExternalModule(FamonCorePackageModule)],
)
Future<void> configureDependencies() async => getIt.init();
