import 'dart:io';

import 'package:famon/src/models/platform_type.dart';
import 'package:famon/src/services/interfaces/log_source_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

/// Factory for creating platform-specific log sources.
///
/// This factory handles platform detection and creates the appropriate
/// [LogSourceInterface] implementation for the target platform.
@injectable
class LogSourceFactory {
  /// Creates a new LogSourceFactory.
  LogSourceFactory(this._processManager, this._logger);

  final ProcessManager _processManager;
  final Logger _logger;

  /// Create a log source for the specified platform.
  ///
  /// If [platform] is [PlatformType.auto], attempts to detect the appropriate
  /// platform based on connected devices.
  ///
  /// Throws [StateError] if no suitable platform can be detected.
  Future<LogSourceInterface> create(PlatformType platform) async {
    final targetPlatform =
        platform == PlatformType.auto ? await _autoDetect() : platform;

    return _createForPlatform(targetPlatform);
  }

  LogSourceInterface _createForPlatform(PlatformType platform) {
    return switch (platform) {
      PlatformType.android => _AndroidLogSource(_processManager, _logger),
      PlatformType.iosSimulator => _IosSimulatorLogSource(
          _processManager,
          _logger,
        ),
      PlatformType.iosDevice => _IosDeviceLogSource(_processManager, _logger),
      PlatformType.auto => throw StateError(
          'Auto platform should be resolved before creation',
        ),
    };
  }

  /// Auto-detect the appropriate platform based on connected devices.
  ///
  /// Detection priority:
  /// 1. Android devices (via adb)
  /// 2. iOS Simulator (via xcrun simctl)
  /// 3. iOS Device (via idevice_id)
  Future<PlatformType> _autoDetect() async {
    // Check for Android devices
    if (await _hasAndroidDevices()) {
      _logger.detail('Auto-detected: Android device connected');
      return PlatformType.android;
    }

    // Check for booted iOS Simulator
    if (await _hasBootedSimulator()) {
      _logger.detail('Auto-detected: iOS Simulator running');
      return PlatformType.iosSimulator;
    }

    // Check for connected iOS device
    if (await _hasIosDevice()) {
      _logger.detail('Auto-detected: iOS device connected');
      return PlatformType.iosDevice;
    }

    // Default to Android (existing behavior)
    _logger.warn('No devices detected, defaulting to Android');
    return PlatformType.android;
  }

  Future<bool> _hasAndroidDevices() async {
    try {
      final result = await _processManager.run(['adb', 'devices']);
      if (result.exitCode != 0) return false;

      final output = result.stdout as String;
      final lines = output.split('\n');
      // Skip header line and check for actual devices
      return lines.skip(1).any(
            (line) =>
                line.trim().isNotEmpty &&
                (line.contains('device') || line.contains('emulator')),
          );
    } on ProcessException {
      return false;
    }
  }

  Future<bool> _hasBootedSimulator() async {
    try {
      final result = await _processManager.run([
        'xcrun',
        'simctl',
        'list',
        'devices',
      ]);
      if (result.exitCode != 0) return false;

      final output = result.stdout as String;
      return output.contains('(Booted)');
    } on ProcessException {
      return false;
    }
  }

  Future<bool> _hasIosDevice() async {
    try {
      final result = await _processManager.run(['idevice_id', '-l']);
      if (result.exitCode != 0) return false;

      final output = result.stdout as String;
      return output.trim().isNotEmpty;
    } on ProcessException {
      return false;
    }
  }
}

/// Temporary Android log source implementation.
///
/// This will be moved to a separate file in Phase 2 after refactoring.
class _AndroidLogSource implements LogSourceInterface {
  _AndroidLogSource(this._processManager, this._logger);

  final ProcessManager _processManager;
  final Logger _logger;

  /// Valid Android package name pattern.
  ///
  /// Package names must:
  /// - Start with a letter
  /// - Contain only letters, digits, underscores, and dots
  /// - Have at least one dot (e.g., com.example.app)
  ///
  /// See: https://developer.android.com/studio/build/application-id
  static final _validPackageNamePattern = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  /// Maximum allowed package name length (per Android spec).
  static const _maxPackageNameLength = 256;

  @override
  PlatformType get platform => PlatformType.android;

  @override
  String get platformDisplayName => 'Android';

  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    final args = <String>['adb', 'logcat', '-v', 'time'];
    if (!verbose) {
      args.addAll([
        '-s',
        'FA',
        'FA-SVC',
        'FA-Ads',
        'FirebaseCrashlytics',
        'Crashlytics',
      ]);
    }
    return _processManager.start(args);
  }

  @override
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
    if (bundleIdOrPackage == null || bundleIdOrPackage.isEmpty) return;

    // Security: Validate package name format to prevent command injection
    if (bundleIdOrPackage.length > _maxPackageNameLength) {
      _logger.warn(
        'Package name too long (max $_maxPackageNameLength chars): '
        '${bundleIdOrPackage.length} chars provided',
      );
      return;
    }

    if (!_validPackageNamePattern.hasMatch(bundleIdOrPackage)) {
      _logger.warn(
        'Invalid package name format: $bundleIdOrPackage\n'
        'Package names must start with a letter, contain only '
        'alphanumeric characters, underscores, and dots.',
      );
      return;
    }

    try {
      _logger.detail('Enabling Analytics debug for $bundleIdOrPackage...');
      final proc = await _processManager.start([
        'adb',
        'shell',
        'setprop',
        'debug.firebase.analytics.app',
        bundleIdOrPackage,
      ]);
      await proc.exitCode;
    } on ProcessException catch (e) {
      _logger.warn('Failed to enable analytics debug: ${e.message}');
    }
  }

  @override
  Future<void> raiseLogLevels() async {
    Future<void> setLevel(String tag) async {
      try {
        final p = await _processManager.start([
          'adb',
          'shell',
          'setprop',
          'log.tag.$tag',
          'VERBOSE',
        ]);
        await p.exitCode;
      } on ProcessException catch (e) {
        _logger.warn('Failed to set log level for $tag: ${e.message}');
      }
    }

    _logger.detail('Raising FA/Crashlytics log levels to VERBOSE...');
    await setLevel('FA');
    await setLevel('FA-SVC');
    await setLevel('FirebaseCrashlytics');
    await setLevel('Crashlytics');
  }

  @override
  List<String> getTroubleshootingTips() => [
        '1. Confirm device is connected: adb devices',
        '2. Enable Analytics debug for your app:',
        '   adb shell setprop debug.firebase.analytics.app <your.package>',
        '3. Optionally raise FA log level:',
        '   adb shell setprop log.tag.FA VERBOSE',
        '   adb shell setprop log.tag.FA-SVC VERBOSE',
        '4. Open your app and trigger events; then try again.',
      ];

  @override
  Future<bool> checkToolsAvailable() async {
    try {
      final result = await _processManager.run(['adb', 'version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  String getToolsInstallationInstructions() =>
      'Android SDK platform-tools are required.\n'
      'Install via Android Studio or: brew install android-platform-tools';
}

/// Placeholder iOS Simulator log source.
///
/// Full implementation will be added in Phase 3.
class _IosSimulatorLogSource implements LogSourceInterface {
  _IosSimulatorLogSource(this._processManager, this._logger);

  final ProcessManager _processManager;
  final Logger _logger;

  @override
  PlatformType get platform => PlatformType.iosSimulator;

  @override
  String get platformDisplayName => 'iOS Simulator';

  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    // xcrun simctl spawn booted log stream
    //   --level debug
    //   --predicate 'subsystem contains "firebase" OR ...'
    final predicate = verbose
        ? 'subsystem CONTAINS "com.google" OR subsystem CONTAINS "firebase"'
        : 'subsystem CONTAINS "firebase" OR eventMessage CONTAINS '
            '"FirebaseAnalytics" OR eventMessage CONTAINS "FIRAnalytics"';

    return _processManager.start([
      'xcrun',
      'simctl',
      'spawn',
      'booted',
      'log',
      'stream',
      '--level',
      'debug',
      '--style',
      'compact',
      '--predicate',
      predicate,
    ]);
  }

  @override
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
    // iOS debug mode is enabled via Xcode scheme arguments
    _logger
      ..info('iOS Analytics debug mode must be enabled in Xcode:')
      ..info('  1. Edit scheme > Run > Arguments')
      ..info('  2. Add: -FIRAnalyticsDebugEnabled')
      ..info('  3. Rebuild and run your app');
  }

  @override
  Future<void> raiseLogLevels() async {
    // iOS doesn't have the same log level mechanism as Android
    _logger.detail(
      'iOS log levels are controlled by the log stream predicate.',
    );
  }

  @override
  List<String> getTroubleshootingTips() => [
        '1. Ensure iOS Simulator is running with Firebase Analytics app',
        '2. Enable debug mode in your Xcode scheme:',
        '   Edit Scheme > Run > Arguments > -FIRAnalyticsDebugEnabled',
        '3. Verify Firebase is properly initialized in your app',
        '4. Check Console.app for FirebaseAnalytics messages',
      ];

  @override
  Future<bool> checkToolsAvailable() async {
    try {
      final result = await _processManager.run(['xcrun', '--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  String getToolsInstallationInstructions() =>
      'Xcode Command Line Tools are required.\n'
      'Install via: xcode-select --install';
}

/// Placeholder iOS Device log source.
///
/// Full implementation will be added in Phase 3.
class _IosDeviceLogSource implements LogSourceInterface {
  _IosDeviceLogSource(this._processManager, this._logger);

  final ProcessManager _processManager;
  final Logger _logger;

  @override
  PlatformType get platform => PlatformType.iosDevice;

  @override
  String get platformDisplayName => 'iOS Device';

  @override
  Future<Process> startLogStream({bool verbose = false}) async {
    // idevicesyslog -m "FirebaseAnalytics"
    final args = <String>['idevicesyslog'];
    if (!verbose) {
      args.addAll(['-m', 'FirebaseAnalytics']);
    }
    return _processManager.start(args);
  }

  @override
  Future<void> enableAnalyticsDebug(String? bundleIdOrPackage) async {
    // Same as simulator - iOS debug mode is enabled via Xcode
    _logger
      ..info('iOS Analytics debug mode must be enabled in Xcode:')
      ..info('  1. Edit scheme > Run > Arguments')
      ..info('  2. Add: -FIRAnalyticsDebugEnabled')
      ..info('  3. Rebuild and install on your device');
  }

  @override
  Future<void> raiseLogLevels() async {
    _logger.detail('iOS Device log levels are controlled by idevicesyslog.');
  }

  @override
  List<String> getTroubleshootingTips() => [
        '1. Ensure iOS device is connected and trusted',
        '2. Install libimobiledevice: brew install libimobiledevice',
        '3. Enable debug mode in your Xcode scheme:',
        '   Edit Scheme > Run > Arguments > -FIRAnalyticsDebugEnabled',
        '4. Deploy your app to the device and trigger events',
      ];

  @override
  Future<bool> checkToolsAvailable() async {
    try {
      final result = await _processManager.run(['which', 'idevicesyslog']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  String getToolsInstallationInstructions() =>
      'libimobiledevice is required for iOS device monitoring.\n'
      'Install via: brew install libimobiledevice';
}
