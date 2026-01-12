import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/services/event_formatter_service.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/utils/event_filter_utils.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

/// Command for monitoring Firebase Analytics events in real-time
@injectable
class MonitorCommand extends Command<int> {
  /// Creates a new MonitorCommand with injected dependencies
  MonitorCommand({
    required Logger logger,
    required ProcessManager processManager,
    required LogParserInterface logParser,
    required EventCacheInterface eventCache,
  })  : _logger = logger,
        _processManager = processManager,
        _logParser = logParser,
        _eventCache = eventCache {
    argParser
      ..addMultiOption(
        'hide',
        help: 'Event names to hide from output. Can be used multiple times.',
        valueHelp: 'EVENT_NAME',
      )
      ..addMultiOption(
        'show-only',
        abbr: 's',
        help: 'Only show these event names. Can be used multiple times.',
        valueHelp: 'EVENT_NAME',
      )
      ..addFlag(
        'no-color',
        negatable: false,
        help: 'Disables colorful output.',
      )
      ..addFlag(
        'suggestions',
        help: 'Show smart suggestions based on session history.',
      )
      ..addFlag(
        'stats',
        help: 'Show session statistics periodically.',
      )
      ..addFlag(
        'raw',
        abbr: 'r',
        negatable: false,
        help: 'Print raw parameter values without formatting or grouping.',
      )
      ..addFlag(
        'verbose',
        abbr: 'V',
        negatable: false,
        help:
            'Verbose mode: stream and print all Firebase Analytics/Crashlytics '
            'logcat lines.',
      )
      ..addOption(
        'enable-debug',
        abbr: 'D',
        valueHelp: 'PACKAGE',
        help: 'Enable Analytics debug for PACKAGE and raise FA log levels '
            'before monitoring.',
      )
      ..addFlag(
        'raise-log-levels',
        negatable: false,
        help:
            'Raise FA/FA-SVC/FirebaseCrashlytics log levels to VERBOSE before '
            'monitoring.',
      );
  }

  @override
  final name = 'monitor';

  @override
  final description =
      'Monitors Firebase Analytics events from logcat in real-time.';

  final Logger _logger;
  final ProcessManager _processManager;
  final LogParserInterface _logParser;
  final EventCacheInterface _eventCache;
  late final EventFormatterService _formatter;

  // Regex for detecting Firebase-related log lines in verbose mode
  static final RegExp _firebaseLogPattern = RegExp(
    r'\bFA-SVC\b|\bFA\b|I/FA|D/FA|V/FA|W/FA|E/FA|FirebaseCrashlytics|Crashlytics',
  );

  @override
  Future<int> run() async {
    final config = _parseArguments();

    _initializeSession(config);
    await _setupDebugMode(config);
    _logFilterConfiguration(config);

    _logger.info('Press Ctrl+C to stop monitoring\n');

    try {
      final process = await _startLogcatProcess(config.verbose);
      final timers = _setupTimers(config);

      await _processLogStream(process, config);

      _cleanupTimers(timers);
    } on Object catch (e) {
      return _handleError(e);
    }

    return 0;
  }

  /// Parses command line arguments into a configuration record.
  ({
    List<String> hideEvents,
    List<String> showOnlyEvents,
    bool showSuggestions,
    bool showStats,
    bool rawOutput,
    bool noColor,
    bool verbose,
    String? enableDebugFor,
    bool raiseLogLevels,
  }) _parseArguments() {
    return (
      hideEvents: (argResults?['hide'] as List<String>?) ?? <String>[],
      showOnlyEvents: (argResults?['show-only'] as List<String>?) ?? <String>[],
      showSuggestions: argResults?['suggestions'] as bool? ?? false,
      showStats: argResults?['stats'] as bool? ?? false,
      rawOutput: argResults?['raw'] as bool? ?? false,
      noColor: argResults?['no-color'] as bool? ?? false,
      verbose: argResults?['verbose'] as bool? ?? false,
      enableDebugFor: argResults?['enable-debug'] as String?,
      raiseLogLevels: argResults?['raise-log-levels'] as bool? ?? false,
    );
  }

  /// Initializes the session: formatter, cache, and startup messages.
  void _initializeSession(
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) {
    if (config.verbose) {
      _logger.level = Level.verbose;
    }

    _formatter = EventFormatterService(
      _logger,
      rawOutput: config.rawOutput,
      colorEnabled: !config.noColor,
    );
    _formatter.resetTracking();
    _eventCache.clear();

    _logger
      ..info('🔥 ${lightCyan.wrap('Firebase Analytics Monitor Started')}')
      ..info('📱 Connecting to adb logcat...')
      ..detail('Verbose mode: ${config.verbose ? 'ON' : 'OFF'}');
  }

  /// Sets up debug mode and log levels if requested.
  Future<void> _setupDebugMode(
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) async {
    if (config.enableDebugFor != null && config.enableDebugFor!.isNotEmpty) {
      await _enableAnalyticsDebug(config.enableDebugFor!);
    }
    if (config.raiseLogLevels || config.enableDebugFor != null) {
      await _raiseFaLogLevels();
    }
  }

  /// Logs the current filter configuration to the user.
  void _logFilterConfiguration(
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) {
    if (config.hideEvents.isNotEmpty) {
      _logger.info('🙈 Hiding events: ${config.hideEvents.join(', ')}');
    }
    if (config.showOnlyEvents.isNotEmpty) {
      _logger.info('👀 Showing only: ${config.showOnlyEvents.join(', ')}');
    }
  }

  /// Starts the adb logcat process with appropriate arguments.
  Future<Process> _startLogcatProcess(bool verbose) async {
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

  /// Sets up periodic timers for stats and suggestions display.
  ({Timer? stats, Timer? suggestions, Timer troubleshooting})
      _setupTimers(
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) {
    // Troubleshooting timer - shows tips if no logs detected after 12 seconds
    final troubleshootingTimer = Timer(
      const Duration(seconds: 12),
      _showTroubleshootingTips,
    );

    Timer? statsTimer;
    if (config.showStats) {
      statsTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _showSessionStats(),
      );
    }

    Timer? suggestionsTimer;
    if (config.showSuggestions) {
      suggestionsTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _showSmartSuggestions(),
      );
    }

    return (
      stats: statsTimer,
      suggestions: suggestionsTimer,
      troubleshooting: troubleshootingTimer,
    );
  }

  /// Cleans up all active timers.
  void _cleanupTimers(
    ({Timer? stats, Timer? suggestions, Timer troubleshooting}) timers,
  ) {
    timers.stats?.cancel();
    timers.suggestions?.cancel();
    timers.troubleshooting.cancel();
  }

  /// Processes the logcat output stream.
  Future<void> _processLogStream(
    Process process,
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) async {
    await for (final line in process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())) {
      _processLogLine(line, config);
    }
  }

  /// Processes a single log line from logcat.
  void _processLogLine(
    String line,
    ({
      List<String> hideEvents,
      List<String> showOnlyEvents,
      bool showSuggestions,
      bool showStats,
      bool rawOutput,
      bool noColor,
      bool verbose,
      String? enableDebugFor,
      bool raiseLogLevels,
    }) config,
  ) {
    // In verbose mode, print all Firebase-related lines
    if (config.verbose && _firebaseLogPattern.hasMatch(line)) {
      _logger.detail(line);
    }

    final event = _logParser.parse(line);
    if (event == null) return;

    _eventCache.addEvent(event.eventName);

    if (EventFilterUtils.shouldSkipEvent(
      event.eventName,
      config.hideEvents,
      config.showOnlyEvents,
    )) {
      return;
    }

    _formatter
      ..flushPending()
      ..formatAndPrint(event);
  }

  /// Shows troubleshooting tips when no logs are detected.
  void _showTroubleshootingTips() {
    _logger
      ..warn('No Firebase Analytics/Crashlytics logs detected yet...')
      ..info('Troubleshooting steps:')
      ..info('  1) Confirm device is connected: adb devices')
      ..info('  2) Enable Analytics debug for your app:')
      ..info(
        '     adb shell setprop debug.firebase.analytics.app '
        '<your.package>',
      )
      ..info('  3) Optionally raise FA log level:')
      ..info('     adb shell setprop log.tag.FA VERBOSE')
      ..info('     adb shell setprop log.tag.FA-SVC VERBOSE')
      ..info('  4) Open your app and trigger events; then try again.');
  }

  /// Handles errors from the monitoring process.
  int _handleError(Object e) {
    if (e.toString().contains('adb')) {
      _logger
        ..err('❌ Failed to start adb. Make sure:')
        ..info('   1. Android SDK platform-tools are installed')
        ..info('   2. adb is in your PATH')
        ..info('   3. An Android device/emulator is connected')
        ..info('   4. USB debugging is enabled');
      return 1;
    }

    _logger.err('❌ Unexpected error: $e');
    return 1;
  }

  /// Display session statistics
  void _showSessionStats() {
    final stats = _eventCache.getSessionStats();
    _logger
      ..info('\n📊 Session Stats:')
      ..info('   Unique Events: ${stats.totalUniqueEvents}')
      ..info('   Total Events: ${stats.totalEventOccurrences}');
    final mostFrequent = stats.mostFrequentEvent;
    if (mostFrequent != null) {
      _logger.info(
        '   Most Frequent: $mostFrequent '
        '(${_eventCache.getEventCount(mostFrequent)})',
      );
    }
    _logger.info('');
  }

  /// Display smart suggestions based on session data
  void _showSmartSuggestions() {
    final topEvents = _eventCache.getTopEvents(5);
    final suggestedToHide = _eventCache.getSuggestedToHide();

    if (topEvents.isNotEmpty) {
      _logger
        ..info('\n💡 Smart Suggestions:')
        ..info('   Most frequent events: ${topEvents.join(', ')}');

      if (suggestedToHide.isNotEmpty) {
        _logger
          ..info('   Consider hiding: ${suggestedToHide.join(', ')}')
          ..info(
            '   Use: famon monitor --hide ${suggestedToHide.join(' --hide ')}',
          );
      }

      _logger.info('');
    }
  }

  Future<void> _enableAnalyticsDebug(String packageName) async {
    try {
      _logger.detail('Enabling Analytics debug for $packageName...');
      final proc = await _processManager.start([
        'adb',
        'shell',
        'setprop',
        'debug.firebase.analytics.app',
        packageName,
      ]);
      await proc.exitCode;
    } on Object catch (e) {
      _logger.warn('Failed to enable analytics debug: $e');
    }
  }

  Future<void> _raiseFaLogLevels() async {
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
      } on Object catch (e) {
        _logger.warn('Failed to set log level for $tag: $e');
      }
    }

    _logger.detail('Raising FA/Crashlytics log levels to VERBOSE...');
    await setLevel('FA');
    await setLevel('FA-SVC');
    await setLevel('FirebaseCrashlytics');
    await setLevel('Crashlytics');
  }
}
