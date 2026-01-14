import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart';
import 'package:firebase_analytics_monitor/src/services/event_formatter_service.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/utils/event_filter_utils.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

/// Bundles dependencies required by FilteredMonitorCommand.
///
/// This container groups related services to reduce constructor parameter count
/// and improve testability. Create a mock of this class to test the command.
@injectable
class FilteredMonitorDependencies {
  /// Creates a new FilteredMonitorDependencies with all required services.
  const FilteredMonitorDependencies({
    required this.logger,
    required this.processManager,
    required this.logParser,
    required this.filterService,
    required this.eventRepository,
  });

  /// Logger for output and debugging.
  final Logger logger;

  /// Process manager for starting adb commands.
  final ProcessManager processManager;

  /// Parser for converting logcat lines to events.
  final LogParserInterface logParser;

  /// Service for filtering events by frequency and statistics.
  final EventFilterService filterService;

  /// Repository for persisting events.
  final EventRepository eventRepository;
}

/// Command for monitoring Firebase Analytics with advanced database filtering
@injectable
class FilteredMonitorCommand extends Command<int> {
  /// Creates a new FilteredMonitorCommand with injected dependencies.
  ///
  /// Uses [FilteredMonitorDependencies] to bundle related services,
  /// reducing constructor parameters and improving testability.
  FilteredMonitorCommand(FilteredMonitorDependencies dependencies)
      : _logger = dependencies.logger,
        _processManager = dependencies.processManager,
        _logParser = dependencies.logParser,
        _filterService = dependencies.filterService,
        _eventRepository = dependencies.eventRepository {
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
      ..addOption(
        'min-frequency',
        help: 'Minimum frequency threshold for events to display.',
        valueHelp: 'NUMBER',
      )
      ..addOption(
        'max-frequency',
        help: 'Maximum frequency threshold for events to display.',
        valueHelp: 'NUMBER',
      )
      ..addOption(
        'limit',
        abbr: 'l',
        help: 'Limit number of events to display.',
        valueHelp: 'NUMBER',
      )
      ..addOption(
        'from-date',
        help: 'Show events from this date (ISO 8601 format).',
        valueHelp: 'DATE',
      )
      ..addOption(
        'to-date',
        help: 'Show events up to this date (ISO 8601 format).',
        valueHelp: 'DATE',
      )
      ..addMultiOption(
        'add-param',
        help: 'Add custom parameter to events: '
            '"event_name:param_name:param_value".',
        valueHelp: 'EVENT:PARAM:VALUE',
      )
      ..addFlag(
        'persist',
        help: 'Save filtered events to database for future reference.',
        negatable: false,
      )
      ..addFlag(
        'stats-only',
        help: 'Show only statistics, not individual events.',
        negatable: false,
      )
      ..addFlag(
        'no-color',
        negatable: false,
        help: 'Disables colorful output.',
      )
      ..addFlag(
        'raw',
        abbr: 'r',
        negatable: false,
        help: 'Print raw parameter values without formatting or grouping.',
      );
  }

  @override
  final name = 'filter';

  @override
  final description = 'Monitors Firebase Analytics events with advanced '
      'filtering based on database history.';

  final Logger _logger;
  final ProcessManager _processManager;
  final LogParserInterface _logParser;
  final EventFilterService _filterService;
  final EventRepository _eventRepository;
  late final EventFormatterService _formatter;

  /// Pre-compiled regex pattern for validating Firebase event/parameter names.
  ///
  /// Must start with a letter and contain only alphanumeric characters and
  /// underscores.
  static final RegExp _validFirebaseNamePattern = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*$',
  );

  @override
  Future<int> run() async {
    // Parse arguments
    final hideEvents = (argResults?['hide'] as List<String>?) ?? <String>[];
    final showOnlyEvents =
        (argResults?['show-only'] as List<String>?) ?? <String>[];
    final minFrequency = _parseIntOption('min-frequency');
    final maxFrequency = _parseIntOption('max-frequency');
    final limit = _parseIntOption('limit');
    final fromDate = _parseDateOption('from-date');
    final toDate = _parseDateOption('to-date');
    final customParams =
        (argResults?['add-param'] as List<String>?) ?? <String>[];
    final persist = argResults?['persist'] as bool? ?? false;
    final statsOnly = argResults?['stats-only'] as bool? ?? false;
    final noColor = argResults?['no-color'] as bool? ?? false;
    final rawOutput = argResults?['raw'] as bool? ?? false;

    // Initialize formatter with runtime settings
    _formatter = EventFormatterService(
      _logger,
      colorEnabled: !noColor,
      rawOutput: rawOutput,
    );

    // Parse custom parameters
    final customParamMap = _parseCustomParameters(customParams);

    _logger
      ..info('🔍 ${lightCyan.wrap('Advanced Firebase Analytics Monitor')}')
      ..info('📊 Using database-based filtering...');

    if (statsOnly) {
      return _showStatsOnly(
        hideEvents: hideEvents,
        showOnlyEvents: showOnlyEvents,
        minFrequency: minFrequency,
        maxFrequency: maxFrequency,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    _logger.info('📱 Connecting to adb logcat...');

    try {
      // Start adb logcat process
      final process = await _processManager.start([
        'adb',
        'logcat',
        '-v',
        'time',
        '-s',
        'FA-SVC',
      ]);

      // Drain stderr to prevent buffer overflow
      // adb may produce error output which could block if not consumed
      unawaited(process.stderr.drain<void>());

      // Setup signal handlers for graceful shutdown
      StreamSubscription<ProcessSignal>? sigintSub;
      StreamSubscription<ProcessSignal>? sigtermSub;
      void cleanup() {
        process.kill();
      }

      sigintSub = ProcessSignal.sigint.watch().listen((_) {
        cleanup();
        unawaited(sigintSub?.cancel());
        unawaited(sigtermSub?.cancel());
      });
      sigtermSub = ProcessSignal.sigterm.watch().listen((_) {
        cleanup();
        unawaited(sigintSub?.cancel());
        unawaited(sigtermSub?.cancel());
      });

      var eventCount = 0;
      var malformedByteCount = 0;
      var lastMalformedWarning = DateTime.now();

      await for (final line in process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        // Detect malformed UTF-8 sequences (replacement character U+FFFD)
        final replacementCount = '\uFFFD'.allMatches(line).length;
        if (replacementCount > 0) {
          malformedByteCount += replacementCount;
          // Warn at most once per minute to avoid spam
          final now = DateTime.now();
          if (now.difference(lastMalformedWarning).inSeconds >= 60) {
            _logger.warn(
              'Detected $malformedByteCount malformed UTF-8 byte(s) in logcat '
              'output. Some log data may be corrupted.',
            );
            lastMalformedWarning = now;
          }
        }

        final event = _logParser.parse(line);

        if (event != null) {
          // Add custom parameters if specified
          final enhancedEvent = _addCustomParameters(event, customParamMap);

          // Apply frequency-based filtering using database
          if (await _shouldSkipByFrequency(
            enhancedEvent.eventName,
            minFrequency,
            maxFrequency,
          )) {
            continue;
          }

          // Apply basic filtering using shared utility
          if (EventFilterUtils.shouldSkipEvent(
            enhancedEvent.eventName,
            hideEvents,
            showOnlyEvents,
          )) {
            continue;
          }

          // Save to database if persist is enabled
          if (persist) {
            await _eventRepository.saveEvent(enhancedEvent);
          }

          // Format and display the event
          _formatter.formatAndPrint(enhancedEvent);
          eventCount++;

          // Apply limit
          if (limit != null && eventCount >= limit) {
            _logger.info('\n📊 Reached limit of $limit events');
            break;
          }
        }
      }

      // Cleanup signal subscriptions
      unawaited(sigintSub.cancel());
      unawaited(sigtermSub.cancel());
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

  Future<int> _showStatsOnly({
    required List<String> hideEvents,
    required List<String> showOnlyEvents,
    int? minFrequency,
    int? maxFrequency,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final stats = await _filterService.getEventStatistics(
        fromDate: fromDate,
        toDate: toDate,
      );

      _logger
        ..info('📊 Database Statistics:')
        ..info('   Total Events: ${stats.totalEvents}')
        ..info('   Unique Event Types: ${stats.uniqueEventTypes}');

      if (stats.dateRange != null) {
        _logger.info(
          '   Date Range: ${stats.dateRange!.start.toLocal()} - '
          '${stats.dateRange!.end.toLocal()}',
        );
      }

      if (stats.topEvents.isNotEmpty) {
        _logger.info('\n🔥 Top Events:');
        var count = 0;
        for (final entry in stats.topEvents.entries) {
          if (count >= maxTopEventsToDisplay) break;

          final shouldSkip = EventFilterUtils.shouldSkipEventWithFrequency(
            entry.key,
            hideEvents,
            showOnlyEvents,
            eventFrequency: entry.value,
            minFrequency: minFrequency,
            maxFrequency: maxFrequency,
          );

          if (!shouldSkip) {
            _logger.info('   ${entry.key}: ${entry.value} occurrences');
            count++;
          }
        }
      }

      // Show frequency-based suggestions
      if (minFrequency == null && maxFrequency == null) {
        final highFrequency = await _filterService.getHighFrequencyEvents(
          threshold: highFrequencyThreshold,
        );
        final lowFrequency = await _filterService.getLowFrequencyEvents();

        if (highFrequency.isNotEmpty) {
          _logger
            ..info('\n💡 High Frequency Events (consider hiding):')
            ..info('   ${highFrequency.take(5).join(', ')}');
        }

        if (lowFrequency.isNotEmpty) {
          _logger
            ..info('\n🔍 Low Frequency Events (might be interesting):')
            ..info('   ${lowFrequency.take(5).join(', ')}');
        }
      }

      return 0;
    } on Object catch (e) {
      _logger.err('❌ Failed to get statistics: $e');
      return 1;
    }
  }

  Future<bool> _shouldSkipByFrequency(
    String eventName,
    int? minFrequency,
    int? maxFrequency,
  ) async {
    if (minFrequency == null && maxFrequency == null) return false;

    try {
      final frequencies = await _filterService.getEventFrequencies();
      final eventFrequency = frequencies[eventName] ?? 0;

      if (minFrequency != null && eventFrequency < minFrequency) return true;
      if (maxFrequency != null && eventFrequency > maxFrequency) return true;

      return false;
    } on Object catch (e) {
      _logger.detail('Failed to get frequency data: $e');
      return false;
    }
  }

  /// Validates that a name follows Firebase Analytics naming conventions.
  /// Names must be alphanumeric with underscores, start with a letter,
  /// and be 1-40 characters long.
  bool _isValidFirebaseName(String name) {
    if (name.isEmpty || name.length > 40) return false;
    // Use pre-compiled static pattern for better performance
    return _validFirebaseNamePattern.hasMatch(name);
  }

  Map<String, Map<String, String>> _parseCustomParameters(
    List<String> customParams,
  ) {
    final result = <String, Map<String, String>>{};

    for (final param in customParams) {
      final parts = param.split(':');
      if (parts.length != 3) {
        _logger.warn(
          'Invalid parameter format: "$param". '
          'Expected format: "event_name:param_name:param_value"',
        );
        continue;
      }

      final eventName = parts[0].trim();
      final paramName = parts[1].trim();
      final paramValue = parts[2].trim();

      // Validate event name
      if (!_isValidFirebaseName(eventName)) {
        _logger.warn(
          'Invalid event name: "$eventName". '
          'Must be 1-40 alphanumeric characters starting with a letter.',
        );
        continue;
      }

      // Validate parameter name
      if (!_isValidFirebaseName(paramName)) {
        _logger.warn(
          'Invalid parameter name: "$paramName". '
          'Must be 1-40 alphanumeric characters starting with a letter.',
        );
        continue;
      }

      // Validate parameter value is not empty
      if (paramValue.isEmpty) {
        _logger.warn(
          'Empty parameter value for "$eventName:$paramName". Skipping.',
        );
        continue;
      }

      // Validate parameter value length (Firebase limit is 100 chars)
      if (paramValue.length > 100) {
        _logger.warn(
          'Parameter value too long for "$eventName:$paramName" '
          '(max 100 characters). Truncating.',
        );
        result.putIfAbsent(eventName, () => <String, String>{});
        result[eventName]![paramName] = paramValue.substring(0, 100);
        continue;
      }

      result.putIfAbsent(eventName, () => <String, String>{});
      result[eventName]![paramName] = paramValue;
    }

    return result;
  }

  AnalyticsEvent _addCustomParameters(
    AnalyticsEvent event,
    Map<String, Map<String, String>> customParamMap,
  ) {
    final customParams = customParamMap[event.eventName];
    if (customParams == null || customParams.isEmpty) {
      return event;
    }

    // Merge custom params using manualParameters
    return event.copyWith(
      manualParameters: {
        ...event.manualParameters,
        ...customParams,
      },
    );
  }

  int? _parseIntOption(String optionName) {
    final value = argResults?[optionName] as String?;
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) {
      _logger.warn('Invalid integer value for --$optionName: "$value"');
      return null;
    }
    if (parsed < 0) {
      _logger.warn(
        'Negative value for --$optionName: $parsed. Using 0 instead.',
      );
      return 0;
    }
    return parsed;
  }

  DateTime? _parseDateOption(String optionName) {
    final value = argResults?[optionName] as String?;
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
