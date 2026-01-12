import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// Service for parsing Firebase Analytics log lines from adb logcat output.
///
/// ## Regex Pattern Matching Strategy
///
/// This service uses a collection of pre-compiled static regex patterns to
/// parse various Firebase Analytics log formats from Android logcat output.
/// The patterns are stored as `static final` to ensure they are compiled once
/// at class load time, avoiding the overhead of regex compilation on each
/// parse call.
///
/// ### Pattern Evaluation Order
///
/// Patterns are ordered by expected frequency of occurrence to minimize
/// unnecessary regex evaluations:
///
/// 1. **Standard format** (`Logging event: origin=app,name=...`) - Most common
///    format in modern Firebase Analytics implementations.
/// 2. **FA-SVC tagged patterns** - Firebase Analytics Service logs, frequently
///    seen in debug builds.
/// 3. **FA tagged patterns** - General Firebase Analytics logs.
/// 4. **I/FA patterns** - Info-level FA logs, less common but still used.
/// 5. **Basic/legacy formats** - Older or simplified log formats.
///
/// ### Early Termination Optimization
///
/// Before evaluating any regex patterns, the parser performs a quick string
/// containment check for common FA-related markers (`FA`, `Logging event`,
/// `Event`). Lines that do not contain any of these markers are immediately
/// rejected, avoiding unnecessary regex evaluations for the majority of
/// logcat lines that are not Firebase Analytics related.
///
/// ### Performance Considerations
///
/// - All patterns are pre-compiled (`static final`) to avoid compilation
///   overhead
/// - Early termination check uses simple string containment (O(n) but fast)
/// - Pattern order optimization reduces average number of regex evaluations
/// - Failed matches short-circuit to the next pattern immediately
@Injectable(as: LogParserInterface)
class LogParserService implements LogParserInterface {
  /// Creates a new LogParserService
  ///
  /// [logger] - Optional logger for reporting parsing errors
  LogParserService({Logger? logger}) : _logger = logger;

  /// The logger instance used for reporting parsing errors.
  final Logger? _logger;

  /// Set of markers that indicate a line may contain Firebase Analytics data.
  ///
  /// Used for early termination optimization to skip lines that cannot
  /// possibly match any FA patterns.
  static const _faMarkers = ['FA', 'Logging event', 'Event logged'];

  /// Regex patterns for different Firebase Analytics log formats.
  ///
  /// Patterns are ordered by expected frequency of occurrence (most common
  /// first) to minimize the average number of regex evaluations per line.
  /// Each pattern captures:
  /// - Group 1: Timestamp (MM-DD HH:MM:SS.mmm)
  /// - Group 2: Event name
  /// - Group 3: Parameters (Bundle format, optional in some patterns)
  static final List<RegExp> _logPatterns = [
    // Pattern 1: Standard format (most common in modern FA implementations)
    // Example: Logging event: origin=app,name=screen_view,params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Logging event: '
      r'origin=app,name=([^,]+),params=(Bundle\[.*\])',
    ),

    // Pattern 2: FA-SVC with "Logging event" format
    // Example: FA-SVC Logging event (FE): name=purchase, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),

    // Pattern 3: FA with "Logging event" format
    // Example: FA Logging event: name=add_to_cart, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
    ),

    // Pattern 4: FA-SVC with "Event:" format
    // Example: FA-SVC Event: screen_view Bundle[{screen_name=Home}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),

    // Pattern 5: FA with "Event:" format
    // Example: FA Event: login Bundle[{method=google}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Event: ([^,\s]+).*Bundle\[(.*)\]',
    ),

    // Pattern 6: I/FA "Logging event (FE)" format
    // Example: I/FA: Logging event (FE): screen_view, Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*I/FA.*Logging event \(FE\): ([^,\s]+),.*(Bundle\[.*\])',
    ),

    // Pattern 7: I/FA "Event logged" format
    // Example: I/FA: Event logged: purchase, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*I/FA.*Event logged: ([^,\s]+).*params[:=](Bundle\[.*\])',
    ),

    // Pattern 8: Alternative "Event logged" format (less common)
    // Example: Event logged: add_to_cart params:Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Event logged: ([^\s]+).*params:(Bundle\[.*\])?',
    ),

    // Pattern 9: FA-SVC basic format with event_name: prefix
    // Example: FA-SVC event_name:custom_event
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*event_name:([^\s,]+)',
    ),

    // Pattern 10: FA basic format with event_name: prefix
    // Example: FA event_name:custom_event
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*event_name:([^\s,]+)',
    ),
  ];

  /// Pattern for FA warnings about invalid default parameter types.
  ///
  /// Example: W/FA: Invalid default event parameter type. Name, value:
  /// cart_total_items, 1
  static final RegExp _faInvalidDefaultParamPattern = RegExp(
    r'^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\b[VDIWE]/FA\b.*Invalid default event parameter type\.\s*Name, value:\s*([^,]+),\s*(.+)$',
  );

  @override
  AnalyticsEvent? parse(String logLine) {
    if (logLine.isEmpty) return null;

    // Early termination: skip lines that don't contain any FA-related markers.
    // This optimization avoids running expensive regex patterns on the vast
    // majority of logcat lines that are not Firebase Analytics related.
    if (!_containsFaMarker(logLine)) {
      return null;
    }

    // Evaluate patterns in order of expected frequency.
    // Short-circuits on first successful match.
    for (final regex in _logPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        return _createAnalyticsEvent(match);
      }
    }

    // Special handling for FA warnings about invalid default parameter types
    final warn = _faInvalidDefaultParamPattern.firstMatch(logLine);
    if (warn != null) {
      return _createFaInvalidDefaultParamEvent(warn);
    }

    return null;
  }

  /// Check if the log line contains any FA-related markers.
  ///
  /// This is a fast preliminary check to avoid running regex patterns on
  /// lines that cannot possibly match.
  bool _containsFaMarker(String line) {
    for (final marker in _faMarkers) {
      if (line.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  /// Create AnalyticsEvent from regex match
  AnalyticsEvent _createAnalyticsEvent(RegExpMatch match) {
    final timestamp = match.group(1)!;
    final eventName = match.group(2)!;
    final paramsString = match.groupCount >= 3 ? match.group(3) ?? '' : '';

    final params = _parseParams(paramsString);
    final items = _parseItems(paramsString);

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: timestamp,
      eventName: eventName,
      parameters: params,
      items: items,
    );
  }

  /// Create a synthetic AnalyticsEvent for FA invalid default param warnings
  AnalyticsEvent _createFaInvalidDefaultParamEvent(RegExpMatch match) {
    final timestamp = match.group(1)!;
    final paramName = match.group(2)!.trim();
    final paramValue = match.group(3)!.trim();

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: timestamp,
      eventName: 'fa_invalid_default_param',
      parameters: {paramName: _cleanValue(paramValue)},
    );
  }

  /// Parse parameter string from Firebase Analytics Bundle format
  Map<String, String> _parseParams(String paramsString) {
    final params = <String, String>{};

    if (paramsString.isEmpty) {
      return params;
    }

    try {
      // Enhanced regex patterns to handle various parameter formats
      final patterns = [
        // Standard key=value format
        RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),
        // Typed parameters: String(value), Long(value), etc.
        RegExp(r'(\w+)=String\(([^)]*)\)'),
        RegExp(r'(\w+)=Long\(([^)]*)\)'),
        RegExp(r'(\w+)=Double\(([^)]*)\)'),
        RegExp(r'(\w+)=Boolean\(([^)]*)\)'),
        RegExp(r'(\w+)=Integer\(([^)]*)\)'),
        RegExp(r'(\w+)=Float\(([^)]*)\)'),
        // Handle quoted strings
        RegExp(r'(\w+)="([^"]*)"'),
        RegExp(r"(\w+)='([^']*)'"),
        // Handle parameters separated by commas with spaces
        RegExp(r'(\w+):\s*([^,\[\]{}]+)(?=[,\]}]|$)'),
        // Key-value pairs with colon separator
        RegExp(r'(\w+)\s*:\s*([^,\[\]{}]+)(?=[,\]}]|$)'),
        // Parameters without type wrapper but with equals
        RegExp(r'(\w+)\s*=\s*([^,\[\]{}()]+)(?=[,\]}]|$)'),
      ];

      // Clean the params string first
      var cleanParamsString = paramsString;
      if (cleanParamsString.startsWith('Bundle[{')) {
        cleanParamsString = cleanParamsString.substring(8);
      }
      if (cleanParamsString.endsWith('}]')) {
        cleanParamsString =
            cleanParamsString.substring(0, cleanParamsString.length - 2);
      }

      for (final pattern in patterns) {
        final matches = pattern.allMatches(cleanParamsString);
        for (final match in matches) {
          if (match.groupCount >= 2) {
            final key = match.group(1)?.trim();
            final value = match.group(2)?.trim();

            if (key != null &&
                value != null &&
                key.isNotEmpty &&
                value.isNotEmpty) {
              // Skip items parameter as it's handled separately
              if (key.toLowerCase() != 'items') {
                params[key] = _cleanValue(value);
              }
            }
          }
        }
      }

      // If we didn't get many params, try a more aggressive approach
      if (params.length < 3 && cleanParamsString.isNotEmpty) {
        _parseParamsAggressive(cleanParamsString, params);
      }
    } on Object catch (e) {
      _logger?.detail('Parameter parsing error: $e');
    }

    return params;
  }

  /// More aggressive parameter parsing for complex formats
  void _parseParamsAggressive(String paramsString, Map<String, String> params) {
    // Split by comma and try to extract key=value pairs
    final parts = paramsString.split(',');

    for (final part in parts) {
      final trimmedPart = part.trim();

      // Look for key=value or key:value patterns
      final colonIndex = trimmedPart.indexOf(':');
      final equalsIndex = trimmedPart.indexOf('=');

      var separatorIndex = -1;
      if (colonIndex != -1 && (equalsIndex == -1 || colonIndex < equalsIndex)) {
        separatorIndex = colonIndex;
      } else if (equalsIndex != -1) {
        separatorIndex = equalsIndex;
      }

      if (separatorIndex > 0 && separatorIndex < trimmedPart.length - 1) {
        final key = trimmedPart.substring(0, separatorIndex).trim();
        final value = trimmedPart.substring(separatorIndex + 1).trim();

        if (key.isNotEmpty &&
            value.isNotEmpty &&
            !value.startsWith('[') &&
            !value.startsWith('{') &&
            key.toLowerCase() != 'items') {
          params[key] = _cleanValue(value);
        }
      }
    }
  }

  /// Parse items array from Firebase Analytics Bundle format
  List<Map<String, String>> _parseItems(String paramsString) {
    final items = <Map<String, String>>[];

    if (paramsString.isEmpty || !paramsString.contains('items=')) {
      return items;
    }

    try {
      // Look for items array: items=[Bundle[{...}], Bundle[{...}]]
      final itemsRegex = RegExp(
        r'items=\[(Bundle\[\{[^\}]+\}\](?:,\s*Bundle\[\{[^\}]+\}\])*)\]',
      );
      final itemsMatch = itemsRegex.firstMatch(paramsString);

      if (itemsMatch != null) {
        final itemsString = itemsMatch.group(1);
        if (itemsString != null) {
          // Extract individual Bundle[{...}] items
          final itemRegex = RegExp(r'Bundle\[\{([^\}]+)\}\]');
          final itemMatches = itemRegex.allMatches(itemsString);

          for (final itemMatch in itemMatches) {
            final itemParamsString = itemMatch.group(1);
            if (itemParamsString != null) {
              final itemParams = _parseParams('Bundle[{$itemParamsString}]');
              if (itemParams.isNotEmpty) {
                items.add(itemParams);
              }
            }
          }
        }
      }
    } on Object catch (e) {
      _logger?.detail('Items parsing error: $e');
    }

    return items;
  }

  /// Clean and normalize parameter values
  String _cleanValue(String value) {
    // Unwrap typed wrappers like String(...), Long(...), Double(...),
    // Boolean(...)
    final typedWrapper = RegExp(r'^[A-Za-z]+\((.*)\)$');
    final wrapperMatch = typedWrapper.firstMatch(value.trim());
    final v = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    return v
        .replaceAll(RegExp(r'^"|"$'), '') // Remove surrounding quotes
        .replaceAll(RegExp(r"^'|'$"), '') // Remove surrounding single quotes
        .replaceAll(RegExp(r'^\(|\)$'), '') // Remove surrounding parentheses
        .replaceAll(RegExp(r'^\[|\]$'), '') // Remove surrounding brackets
        .replaceAll(RegExp(r'^{|}$'), '') // Remove surrounding braces
        .trim();
  }
}
