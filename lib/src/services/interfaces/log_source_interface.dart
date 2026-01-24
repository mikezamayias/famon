import 'dart:io';

import 'package:famon/src/models/platform_type.dart';

/// Interface for platform-specific log sources.
///
/// Implementations of this interface provide access to Firebase Analytics
/// logs from different platforms (Android, iOS Simulator, iOS Device).
abstract class LogSourceInterface {
  /// The platform type this log source handles.
  PlatformType get platform;

  /// Human-readable platform display name.
  String get platformDisplayName;

  /// Start the log stream process.
  ///
  /// Returns a [Process] that streams log output. The caller is responsible
  /// for consuming stdout/stderr and terminating the process.
  ///
  /// [verbose] enables additional log output beyond Firebase Analytics events.
  Future<Process> startLogStream({bool verbose = false});

  /// Enable debug mode for analytics on the platform.
  ///
  /// [bundleIdOrPackage] is the app identifier (bundle ID for iOS, package
  /// name for Android).
  ///
  /// For iOS, this may only log instructions since debug mode is enabled
  /// via Xcode scheme arguments.
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage);

  /// Raise log levels for Firebase Analytics tags.
  ///
  /// This makes more detailed logs visible in the stream.
  Future<void> raiseLogLevels();

  /// Get troubleshooting tips specific to this platform.
  ///
  /// Returns a list of user-friendly troubleshooting steps.
  List<String> getTroubleshootingTips();

  /// Check if the required platform tools are available.
  ///
  /// Returns `true` if all necessary tools (adb, xcrun, idevicesyslog, etc.)
  /// are installed and accessible.
  Future<bool> checkToolsAvailable();

  /// Get installation instructions for missing tools.
  ///
  /// Returns human-readable instructions for installing required tools.
  String getToolsInstallationInstructions();
}
