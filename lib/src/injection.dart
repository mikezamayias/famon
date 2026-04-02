import 'package:famon/src/injection.config.dart';
import 'package:famon_core/core_injection_module.dart';
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
