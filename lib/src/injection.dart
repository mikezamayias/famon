import 'package:famon/src/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Configure dependencies using injectable
@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
