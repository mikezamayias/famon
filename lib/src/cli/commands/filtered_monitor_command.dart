import 'dart:async';
import 'dart:convert';

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

/// Command for monitoring Firebase Analytics with advanced database filtering
@injectable
class FilteredMonitorCommand extends Command<int> {
  /// Creates a new FilteredMonitorCommand with injected dependencies
  FilteredMonitorCommand({
    required Logger logger,
    required ProcessManager processManager,
    required LogParserInterface logParser,
    required EventFilterService filterService,
    required EventRepository eventRepository,
  })  : _logger = logger,
        _processManager = processManager,
        _logParser = logParser,
        _filterService = filterService,
        _eventRepository = eventRepository {
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

      var eventCount = 0;
      await for (final line in process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
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
    } catch (e) {
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

          final shouldSkip = EventFilterUtils.shouldSkipEvent(
                entry.key,
                hideEvents,
                showOnlyEvents,
              ) ||
              (minFrequency != null && entry.value < minFrequency) ||
              (maxFrequency != null && entry.value > maxFrequency);

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
    } catch (e) {
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
    } catch (e) {
      _logger.detail('Failed to get frequency data: $e');
      return false;
    }
  }

  Map<String, Map<String, String>> _parseCustomParameters(
    List<String> customParams,
  ) {
    final result = <String, Map<String, String>>{};

    for (final param in customParams) {
      final parts = param.split(':');
      if (parts.length == 3) {
        final eventName = parts[0];
        final paramName = parts[1];
        final paramValue = parts[2];

        result.putIfAbsent(eventName, () => <String, String>{});
        result[eventName]![paramName] = paramValue;
      }
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
    return int.tryParse(value);
  }

  DateTime? _parseDateOption(String optionName) {
    final value = argResults?[optionName] as String?;
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
