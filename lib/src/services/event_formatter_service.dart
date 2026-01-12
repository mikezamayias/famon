import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/shared/log_timestamp_parser.dart';
import 'package:mason_logger/mason_logger.dart';

/// Unified service for formatting and printing analytics events to the console.
///
/// Combines the functionality of LogFormatterService (FA warning buffering)
/// and CliFormatter (color support, raw output) into a single service.
class EventFormatterService {
  /// Creates a new EventFormatterService.
  ///
  /// The [_logger] is used for output. Options:
  /// - `rawOutput`: If true, print without section labels (default: false)
  /// - `colorEnabled`: If true, use ANSI colors (default: true)
  EventFormatterService(
    this._logger, {
    bool rawOutput = false,
    bool colorEnabled = true,
  })  : _rawOutput = rawOutput,
        _colorEnabled = colorEnabled;

  final Logger _logger;
  final bool _rawOutput;
  final bool _colorEnabled;

  // Instance variables for FA warning buffering
  DateTime? _faBufStartTime;
  DateTime? _faBufLastTime;
  String? _faBufStartTsStr;
  String? _faBufLastTsStr;
  final Map<String, String> _faBufParams = {};

  /// Formats and prints the given [event] to the console.
  ///
  /// Handles FA warning buffering and respects the `rawOutput` and
  /// `colorEnabled` settings.
  void formatAndPrint(AnalyticsEvent event) {
    // Handle FA invalid param warnings with buffering
    if (event.eventName == 'fa_invalid_default_param') {
      _bufferFaWarning(event);
      return;
    }

    // Flush any pending FA warnings before printing normal event
    _flushFaWarningBuffer();

    if (_rawOutput) {
      _printRaw(event);
    } else {
      _printFormatted(event);
    }
  }

  /// Prints the event in a simple pipe-delimited format.
  ///
  /// Output format: "timestamp | eventName | {parameters}"
  void _printRaw(AnalyticsEvent event) {
    final timestamp = event.displayTimestamp;
    final eventName = event.eventName;
    final params = event.parameters;
    _logger.info('$timestamp | $eventName | $params');
  }

  /// Prints the event with structured formatting and optional colors.
  ///
  /// Displays timestamp, event name, parameters, and items in a
  /// hierarchical, human-readable format.
  void _printFormatted(AnalyticsEvent event) {
    final timestamp = event.displayTimestamp;
    final eventName = event.eventName;

    // Print header with optional color
    if (_colorEnabled) {
      _logger.info('[$timestamp] ${lightCyan.wrap(eventName)}');
    } else {
      _logger.info('[$timestamp] $eventName');
    }

    // Print parameters
    if (event.parameters.isNotEmpty) {
      _logger.info('  Parameters:');
      for (final entry in event.parameters.entries) {
        final paramLine = '    ${entry.key}: ${entry.value}';
        _logger.info(
          _colorEnabled ? (darkGray.wrap(paramLine) ?? paramLine) : paramLine,
        );
      }
    }

    // Print items
    if (event.items.isNotEmpty) {
      _logger.info('  Items:');
      for (var i = 0; i < event.items.length; i++) {
        final item = event.items[i];
        _logger.info('    Item ${i + 1}:');
        for (final entry in item.entries) {
          _logger.info('      ${entry.key}: ${entry.value}');
        }
      }
    }

    _logger.info('');
  }

  /// Flushes any pending accumulated FA warnings to the output.
  void flushPending() => _flushFaWarningBuffer();

  /// Resets the internal state used for tracking FA warning buffering.
  void resetTracking() {
    _faBufStartTime = null;
    _faBufLastTime = null;
    _faBufStartTsStr = null;
    _faBufLastTsStr = null;
    _faBufParams.clear();
  }

  /// Buffers FA invalid parameter warnings for grouped output.
  ///
  /// Warnings occurring within a short time window are accumulated and
  /// printed together rather than individually, reducing output noise.
  void _bufferFaWarning(AnalyticsEvent event) {
    final tsStr = event.rawTimestamp ?? event.displayTimestamp;
    final ts = parseLogcatTimestamp(tsStr);

    if (_faBufLastTime != null && ts != null) {
      final gap = ts.difference(_faBufLastTime!).inMilliseconds;
      if (gap > faWarningGroupingThresholdMs) {
        _flushFaWarningBuffer();
      }
    }

    _faBufStartTime ??= ts;
    _faBufLastTime = ts ?? _faBufLastTime;
    _faBufStartTsStr ??= tsStr;
    _faBufLastTsStr = tsStr;

    for (final entry in event.parameters.entries) {
      _faBufParams[entry.key] = entry.value;
    }
  }

  /// Outputs all buffered FA warnings and clears the buffer.
  ///
  /// Prints a grouped summary of invalid parameters with the time range
  /// they were recorded, then resets the internal tracking state.
  void _flushFaWarningBuffer() {
    if (_faBufParams.isEmpty) return;

    final timeLabel = _faBufStartTsStr == null
        ? ''
        : _faBufLastTsStr != null && _faBufLastTsStr != _faBufStartTsStr
            ? '[$_faBufStartTsStr–$_faBufLastTsStr] '
            : '[$_faBufStartTsStr] ';
    final header = '${timeLabel}fa_invalid_default_param'.trimLeft();

    _logger
      ..info(header)
      ..info('  Invalid default parameters:');
    for (final entry in _faBufParams.entries) {
      _logger.info('    ${entry.key}: ${entry.value}');
    }
    _logger.info('');

    resetTracking();
  }

  /// Prints the provided [stats] to the console.
  void printStats(Map<String, dynamic> stats) {
    _logger
      ..info('📊 Session Statistics:')
      ..info('   Total Events: ${stats['totalEvents'] ?? 0}')
      ..info('   Unique Event Types: ${stats['uniqueEventTypes'] ?? 0}');

    final topEvents = stats['topEvents'] as Map<String, int>?;
    if (topEvents != null && topEvents.isNotEmpty) {
      _logger.info('\n🔥 Top Events:');
      var count = 0;
      for (final entry in topEvents.entries) {
        if (count >= statsTopEventsLimit) break;
        _logger.info('   ${entry.key}: ${entry.value} occurrences');
        count++;
      }
    }
  }

  /// Prints an error [message] with a red cross icon.
  void printError(String message) {
    _logger.err('❌ $message');
  }

  /// Prints a success [message] with a green checkmark icon.
  void printSuccess(String message) {
    _logger.success('✅ $message');
  }

  /// Prints an informational [message] with an info icon.
  void printInfo(String message) {
    _logger.info('ℹ️  $message');
  }

  /// Prints a warning [message] with a warning icon.
  void printWarning(String message) {
    _logger.warn('⚠️  $message');
  }
}
