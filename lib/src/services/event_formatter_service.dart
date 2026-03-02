import 'package:famon/src/constants.dart';
import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/services/fa_warning_buffer.dart';
import 'package:mason_logger/mason_logger.dart';

/// Service for formatting and printing analytics events to the console.
///
/// Handles event formatting with color support and raw output modes.
/// FA warning buffering is delegated to [FaWarningBuffer].
///
/// Supports separating "global parameters" (set via Firebase's
/// `setDefaultEventParameters`) from event-specific parameters.
/// When global parameter names are provided, parameters whose keys match the
/// set are displayed in a distinct "Global Parameters:" section, making it
/// easy to distinguish per-event data from session-wide defaults.
class EventFormatterService {
  /// Creates a new EventFormatterService.
  ///
  /// The [_logger] is used for output. Options:
  /// - `rawOutput`: If true, print without section labels (default: false)
  /// - `colorEnabled`: If true, use ANSI colors (default: true)
  /// - `globalParamNames`: Parameter names to classify as global/default
  EventFormatterService(
    this._logger, {
    bool rawOutput = false,
    bool colorEnabled = true,
    Set<String> globalParamNames = const {},
  })  : _rawOutput = rawOutput,
        _colorEnabled = colorEnabled,
        _globalParamNames = globalParamNames {
    _faWarningBuffer = FaWarningBuffer(onFlush: _printFaWarnings);
  }

  final Logger _logger;
  final bool _rawOutput;
  final bool _colorEnabled;
  final Set<String> _globalParamNames;

  /// Whether global parameters are currently hidden from output.
  bool hideGlobalParams = false;

  /// Whether event-specific parameters are currently hidden from output.
  bool hideEventParams = false;

  /// Buffer for grouping FA invalid parameter warnings.
  late final FaWarningBuffer _faWarningBuffer;

  /// Formats and prints the given [event] to the console.
  ///
  /// Handles FA warning buffering and respects the `rawOutput` and
  /// `colorEnabled` settings.
  void formatAndPrint(AnalyticsEvent event) {
    // Handle FA invalid param warnings with buffering
    if (event.eventName == 'fa_invalid_default_param') {
      _faWarningBuffer.add(event);
      return;
    }

    // Flush any pending FA warnings before printing normal event
    _faWarningBuffer.flush();

    if (_rawOutput) {
      _printRaw(event);
    } else {
      _printFormatted(event);
    }
  }

  void _printRaw(AnalyticsEvent event) {
    final timestamp = event.displayTimestamp;
    final eventName = event.eventName;
    final params = _filterParamsForRaw(event.parameters);
    if (event.items.isEmpty) {
      _logger.info('$timestamp | $eventName | $params');
      return;
    }

    _logger.info('$timestamp | $eventName | $params | items=${event.items}');
  }

  void _printFormatted(AnalyticsEvent event) {
    final timestamp = event.displayTimestamp;
    final eventName = event.eventName;

    // Print header with optional color
    if (_colorEnabled) {
      _logger.info('[$timestamp] ${lightCyan.wrap(eventName)}');
    } else {
      _logger.info('[$timestamp] $eventName');
    }

    // Split parameters into global vs event-specific when configured
    if (_globalParamNames.isNotEmpty) {
      _printSeparatedParams(event.parameters);
    } else if (!hideEventParams) {
      _printAllParams(event.parameters);
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

  /// Prints all parameters under a single "Parameters:" section.
  void _printAllParams(Map<String, String> params) {
    if (params.isNotEmpty) {
      _logger.info('  Parameters:');
      for (final entry in params.entries) {
        final paramLine = '    ${entry.key}: ${entry.value}';
        _logger.info(
          _colorEnabled ? (darkGray.wrap(paramLine) ?? paramLine) : paramLine,
        );
      }
    }
  }

  /// Filters parameters for raw output based on hide flags.
  Map<String, String> _filterParamsForRaw(Map<String, String> params) {
    if (_globalParamNames.isEmpty) {
      return hideEventParams ? <String, String>{} : params;
    }
    if (!hideGlobalParams && !hideEventParams) return params;

    return Map<String, String>.fromEntries(
      params.entries.where((e) {
        final isGlobal = _globalParamNames.contains(e.key);
        if (isGlobal && hideGlobalParams) return false;
        if (!isGlobal && hideEventParams) return false;
        return true;
      }),
    );
  }

  /// Prints parameters separated into global and event-specific sections.
  ///
  /// Respects [hideGlobalParams] and [hideEventParams] to control which
  /// sections are displayed.
  void _printSeparatedParams(Map<String, String> params) {
    final globalParams = <String, String>{};
    final eventParams = <String, String>{};

    for (final entry in params.entries) {
      if (_globalParamNames.contains(entry.key)) {
        globalParams[entry.key] = entry.value;
      } else {
        eventParams[entry.key] = entry.value;
      }
    }

    // When both sections are hidden, nothing to print
    if (hideGlobalParams && hideEventParams) return;

    // When one section is hidden, use neutral "Parameters:" header
    if (hideGlobalParams) {
      _printAllParams(eventParams);
      return;
    }
    if (hideEventParams) {
      _printAllParams(globalParams);
      return;
    }

    // Show both sections with their headers
    if (globalParams.isNotEmpty) {
      _logger.info('  Global Parameters:');
      for (final entry in globalParams.entries) {
        final paramLine = '    ${entry.key}: ${entry.value}';
        _logger.info(
          _colorEnabled ? (darkGray.wrap(paramLine) ?? paramLine) : paramLine,
        );
      }
    }
    if (eventParams.isNotEmpty) {
      _logger.info('  Event Parameters:');
      for (final entry in eventParams.entries) {
        final paramLine = '    ${entry.key}: ${entry.value}';
        _logger.info(
          _colorEnabled ? (darkGray.wrap(paramLine) ?? paramLine) : paramLine,
        );
      }
    }
  }

  /// Flushes any pending accumulated FA warnings to the output.
  void flushPending() => _faWarningBuffer.flush();

  /// Resets the internal state used for tracking FA warning buffering.
  void resetTracking() => _faWarningBuffer.reset();

  /// Callback for printing buffered FA warnings.
  void _printFaWarnings({
    required String? startTimestamp,
    required String? endTimestamp,
    required Map<String, String> parameters,
  }) {
    final timeLabel = startTimestamp == null
        ? ''
        : endTimestamp != null && endTimestamp != startTimestamp
            ? '[$startTimestamp–$endTimestamp] '
            : '[$startTimestamp] ';
    final header = '${timeLabel}fa_invalid_default_param'.trimLeft();

    _logger
      ..info(header)
      ..info('  Invalid default parameters:');
    for (final entry in parameters.entries) {
      _logger.info('    ${entry.key}: ${entry.value}');
    }
    _logger.info('');
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
