import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';

/// Module for registering external dependencies that cannot be annotated
/// directly with @injectable.
///
/// Ordered before core module to ensure Logger and ProcessManager are
/// available when core services are resolved.
@module
@Order(-1)
abstract class RegisterModule {
  /// Provides a singleton Logger instance
  @singleton
  Logger get logger => Logger();

  /// Provides a singleton ProcessManager instance
  @singleton
  ProcessManager get processManager => const LocalProcessManager();

  /// Provides a singleton PubUpdater instance
  @singleton
  PubUpdater get pubUpdater => PubUpdater();
}
