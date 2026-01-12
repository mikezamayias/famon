import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/constants.dart';
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

  @override
  Future<int> run() async {
    final hideEvents = (argResults?['hide'] as List<String>?) ?? <String>[];
    final showOnlyEvents =
        (argResults?['show-only'] as List<String>?) ?? <String>[];
    final showSuggestions = argResults?['suggestions'] as bool? ?? false;
    final showStats = argResults?['stats'] as bool? ?? false;
    final rawOutput = argResults?['raw'] as bool? ?? false;
    final noColor = argResults?['no-color'] as bool? ?? false;
    final verbose = argResults?['verbose'] as bool? ?? false;
    final enableDebugFor = argResults?['enable-debug'] as String?;
    final raiseLogLevels = argResults?['raise-log-levels'] as bool? ?? false;

    // Ensure verbose logs are visible when monitor --verbose is used
    if (verbose) {
      _logger.level = Level.verbose;
    }

    // Initialize formatter with color and raw settings
    _formatter = EventFormatterService(
      _logger,
      rawOutput: rawOutput,
      colorEnabled: !noColor,
    );

    // Reset tracking for new session
    _formatter.resetTracking();

    // Clear cache for new session
    _eventCache.clear();

    _logger
      ..info('🔥 ${lightCyan.wrap('Firebase Analytics Monitor Started')}')
      ..info('📱 Connecting to adb logcat...')
      ..detail('Verbose mode: ${verbose ? 'ON' : 'OFF'}');
    // Optionally enable analytics debug and raise log levels
    if (enableDebugFor != null && enableDebugFor.isNotEmpty) {
      await _enableAnalyticsDebug(enableDebugFor);
    }
    if (raiseLogLevels || enableDebugFor != null) {
      await _raiseFaLogLevels();
    }

    if (hideEvents.isNotEmpty) {
      _logger.info('🙈 Hiding events: ${hideEvents.join(', ')}');
    }

    if (showOnlyEvents.isNotEmpty) {
      _logger.info('👀 Showing only: ${showOnlyEvents.join(', ')}');
    }

    _logger.info('Press Ctrl+C to stop monitoring\n');

    try {
      // Start adb logcat process
      // In verbose mode, stream all output; otherwise filter to common
      // FA/Crashlytics tags
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
      final process = await _processManager.start(args);

      // If nothing shows up for a while, guide the user
      // Using inline value (12 seconds) to allow const Duration
      var sawRelevantLine = false;
      Timer(const Duration(seconds: 12), () {
        if (!sawRelevantLine) {
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
      });

      // Setup periodic stats display if requested
      // Using inline value (30 seconds) to allow const Duration
      Timer? statsTimer;
      if (showStats) {
        statsTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _showSessionStats(),
        );
      }

      // Setup suggestions display if requested
      // Using inline value (5 minutes) to allow const Duration
      Timer? suggestionsTimer;
      if (showSuggestions) {
        suggestionsTimer = Timer.periodic(
          const Duration(minutes: 5),
          (_) => _showSmartSuggestions(),
        );
      }

      await for (final line in process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        // If verbose, print all Firebase Analytics/Crashlytics related lines
        if (verbose) {
          // Filter to only FA/Crashlytics noise to keep it relevant
          final isFirebaseRelated = RegExp(
            r'\bFA-SVC\b|\bFA\b|I/FA|D/FA|V/FA|W/FA|E/FA|FirebaseCrashlytics|Crashlytics',
          ).hasMatch(line);
          if (isFirebaseRelated) {
            sawRelevantLine = true;
            _logger.detail(line);
          }
        }

        final event = _logParser.parse(line);

        if (event != null) {
          // Add to cache for suggestions
          _eventCache.addEvent(event.eventName);

          // Apply filtering using shared utility
          if (EventFilterUtils.shouldSkipEvent(
            event.eventName,
            hideEvents,
            showOnlyEvents,
          )) {
            continue;
          }

          // Format and display the event
          // Ensure any buffered grouped output is flushed at end
          _formatter.flushPending();
          sawRelevantLine = true;
          _formatter.formatAndPrint(event);
        }
      }

      // Cleanup timers
      statsTimer?.cancel();
      suggestionsTimer?.cancel();
    } on Object catch (e) {
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

    return 0;
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
    await Future<void>.delayed(const Duration(milliseconds: adbCommandDelayMs));
    await setLevel('FA-SVC');
    await Future<void>.delayed(const Duration(milliseconds: adbCommandDelayMs));
    await setLevel('FirebaseCrashlytics');
    await Future<void>.delayed(const Duration(milliseconds: adbCommandDelayMs));
    await setLevel('Crashlytics');
  }
}
