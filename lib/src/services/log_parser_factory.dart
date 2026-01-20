import 'package:famon/src/models/platform_type.dart';
import 'package:famon/src/services/interfaces/log_parser_interface.dart';
import 'package:famon/src/services/ios_log_parser_service.dart';
import 'package:famon/src/services/log_parser_service.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// Factory for creating platform-specific log parsers.
///
/// This factory creates the appropriate [LogParserInterface] implementation
/// based on the target platform. It ensures that the correct parser is used
/// for parsing log output from different platforms (Android, iOS Simulator,
/// iOS Device).
@injectable
class LogParserFactory {
  /// Creates a new LogParserFactory.
  LogParserFactory(this._logger);

  final Logger _logger;

  /// Create a log parser for the specified platform.
  ///
  /// [platform] - The target platform for parsing logs.
  ///
  /// Returns the appropriate [LogParserInterface] implementation:
  /// - [LogParserService] for Android
  /// - [IosLogParserService] for iOS Simulator and iOS Device
  LogParserInterface create(PlatformType platform) {
    return switch (platform) {
      PlatformType.android => LogParserService(logger: _logger),
      PlatformType.iosSimulator => IosLogParserService(logger: _logger),
      PlatformType.iosDevice => IosLogParserService(logger: _logger),
      PlatformType.auto =>
        // Default to Android parser for auto-detect
        // The actual platform will be determined by LogSourceFactory
        LogParserService(logger: _logger),
    };
  }
}
