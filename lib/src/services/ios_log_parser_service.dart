import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/models/platform_type.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:mason_logger/mason_logger.dart';

/// Service for parsing Firebase Analytics log lines from iOS console output.
///
/// ## iOS Firebase Analytics Log Formats
///
/// This service handles various iOS Firebase Analytics log formats from both
/// iOS Simulator (via xcrun simctl log stream) and physical devices
/// (via idevicesyslog).
///
/// ### Supported Formats
///
/// 1. **Standard iOS Firebase Analytics format**:
///    ```
///    [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params:
///    app, screen_view (_vs), {
///        ga_screen (_sn) = Dashboard;
///        ga_screen_class (_sc) = HomeViewController;
///    }
///    ```
///
/// 2. **Event logged confirmation**:
///    ```
///    [FirebaseAnalytics][I-ACS023072] Event logged. Event name,
///    event params: purchase
///    ```
///
/// ### Key Differences from Android
///
/// - Parameters use `=` separator with `;` terminators (not `,`)
/// - Parameter abbreviations appear in parentheses (e.g., `(_vs)`, `(_sn)`)
/// - Module identifier: `[FirebaseAnalytics]` instead of FA tag
/// - Log codes: `[I-ACS023051]` format
///
/// ## Performance Considerations
///
/// - All patterns are pre-compiled (`static final`) to avoid compilation
///   overhead
/// - Early termination check for `FirebaseAnalytics` or `FIRAnalytics` markers
/// - Pattern order optimization reduces average number of regex evaluations
class IosLogParserService implements LogParserInterface {
  /// Creates a new IosLogParserService
  ///
  /// [logger] - Optional logger for reporting parsing errors
  IosLogParserService({Logger? logger}) : _logger = logger;

  @override
  PlatformType get platform => PlatformType.iosSimulator;

  /// The logger instance used for reporting parsing errors.
  final Logger? _logger;

  /// Set of markers that indicate a line may contain Firebase Analytics data.
  ///
  /// Used for early termination optimization to skip lines that cannot
  /// possibly match any iOS Firebase patterns.
  static const _faMarkers = [
    'FirebaseAnalytics',
    'FIRAnalytics',
    'Logging event',
    'Event logged',
  ];

  /// Regex patterns for different iOS Firebase Analytics log formats.
  ///
  /// Patterns are ordered by expected frequency of occurrence (most common
  /// first) to minimize the average number of regex evaluations per line.
  static final List<RegExp> _logPatterns = [
    // Pattern 1: Standard iOS Firebase Analytics format
    // Example: [FirebaseAnalytics][I-ACS023051] Logging event: origin, name,
    // params: app, screen_view (_vs), { ... }
    // This captures event name which may have an abbreviation in parentheses
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*params:\s*\w+,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{([^}]*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 2: Simpler iOS format without params block
    // Example: [FirebaseAnalytics][I-ACS023051] Logging event: app, purchase
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*,\s*(\w+)(?:\s*\([^)]*\))?(?:,|$)',
    ),

    // Pattern 3: Event logged confirmation format
    // Example: [FirebaseAnalytics][I-ACS023072] Event logged. Event name,
    // event params: purchase
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Event logged\..*:\s*(\w+)',
    ),

    // Pattern 4: FIRAnalytics format (alternative Firebase Analytics logging)
    // Example: FIRAnalytics: Logging event: purchase
    RegExp(
      r'FIRAnalytics.*Logging event:\s*(\w+)',
    ),

    // Pattern 5: Debug view format with timestamp
    // Example: 2024-01-15 10:30:45.123+0000 [FirebaseAnalytics] Logging event:
    // origin, name, params: app, purchase
    RegExp(
      r'\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+[+-]\d+.*\[FirebaseAnalytics\].*Logging event:.*,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{([^}]*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 6: xcrun simctl log stream compact format
    // Compact log output may omit some formatting
    RegExp(
      r'FirebaseAnalytics.*event[:\s]+(\w+)',
      caseSensitive: false,
    ),
  ];

  /// Pre-compiled regex patterns for iOS parameter parsing.
  ///
  /// iOS Firebase Analytics uses different parameter formats than Android:
  /// - `key = value;` format with semicolon terminator
  /// - Optional abbreviation in parentheses: `ga_screen (_sn) = Dashboard;`
  static final List<RegExp> _paramPatterns = [
    // iOS format: key (_abbrev) = value;
    RegExp(r'(\w+)\s*(?:\([^)]*\))?\s*=\s*([^;]+);'),

    // Simpler key = value format
    RegExp(r'(\w+)\s*=\s*([^;,}]+)'),

    // Key: value format (sometimes used in logs)
    RegExp(r'(\w+)\s*:\s*([^;,}]+)'),
  ];

  /// Pre-compiled regex pattern for iOS items array extraction.
  static final RegExp _itemsArrayPattern = RegExp(
    r'items\s*=\s*\[([^\]]+)\]',
    caseSensitive: false,
  );

  /// Pre-compiled regex pattern for individual iOS item extraction.
  static final RegExp _itemPattern = RegExp(
    r'\{([^}]+)\}',
  );

  /// Pattern for cleaning iOS-specific value wrappers
  static final RegExp _iosValueWrapperPattern = RegExp(
    r'^[A-Za-z]+\((.*)\)$',
  );

  @override
  AnalyticsEvent? parse(String logLine) {
    if (logLine.isEmpty) return null;

    // Early termination: skip lines that don't contain any iOS FA markers.
    if (!_containsFaMarker(logLine)) {
      return null;
    }

    // Evaluate patterns in order of expected frequency.
    for (final regex in _logPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        return _createAnalyticsEvent(match, logLine);
      }
    }

    return null;
  }

  /// Check if the log line contains any iOS FA-related markers.
  bool _containsFaMarker(String line) {
    for (final marker in _faMarkers) {
      if (line.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  /// Create AnalyticsEvent from regex match
  AnalyticsEvent _createAnalyticsEvent(RegExpMatch match, String fullLine) {
    final eventName = match.group(1) ?? 'unknown_event';
    final paramsString = match.groupCount >= 2 ? match.group(2) ?? '' : '';

    // Extract timestamp from line if present
    final timestamp = _extractTimestamp(fullLine);

    final params = _parseParams(paramsString);
    final items = _parseItems(paramsString);

    return AnalyticsEvent.fromParsedLog(
      rawTimestamp: timestamp,
      eventName: eventName,
      parameters: params,
      items: items,
    );
  }

  /// Extract timestamp from iOS log line.
  ///
  /// iOS timestamps can be in various formats:
  /// - `2024-01-15 10:30:45.123+0000`
  /// - `10:30:45.123`
  /// - No timestamp at all
  String _extractTimestamp(String line) {
    // Try to extract ISO-style timestamp
    final isoMatch = RegExp(
      r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+)',
    ).firstMatch(line);
    if (isoMatch != null) {
      return isoMatch.group(1) ?? '';
    }

    // Try to extract time-only timestamp
    final timeMatch = RegExp(
      r'(\d{2}:\d{2}:\d{2}\.\d+)',
    ).firstMatch(line);
    if (timeMatch != null) {
      return timeMatch.group(1) ?? '';
    }

    // Return current time as fallback
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Parse parameter string from iOS Firebase Analytics format
  Map<String, String> _parseParams(String paramsString) {
    final params = <String, String>{};

    if (paramsString.isEmpty) {
      return params;
    }

    try {
      // Clean the params string
      final cleanParamsString = paramsString.trim();

      // Use pre-compiled static patterns for better performance
      for (final pattern in _paramPatterns) {
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
    } on FormatException catch (e, stackTrace) {
      _logger?.warn(
        'iOS parameter parsing failed (FormatException): $e. '
        'Some event parameters may be missing.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    } on Exception catch (e, stackTrace) {
      _logger?.warn(
        'iOS parameter parsing failed: $e. '
        'Some event parameters may be missing.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    }

    return params;
  }

  /// Parse items array from iOS Firebase Analytics format
  List<Map<String, String>> _parseItems(String paramsString) {
    final items = <Map<String, String>>[];

    if (paramsString.isEmpty || !paramsString.toLowerCase().contains('items')) {
      return items;
    }

    try {
      final itemsMatch = _itemsArrayPattern.firstMatch(paramsString);

      if (itemsMatch != null) {
        final itemsString = itemsMatch.group(1);
        if (itemsString != null) {
          final itemMatches = _itemPattern.allMatches(itemsString);

          for (final itemMatch in itemMatches) {
            final itemParamsString = itemMatch.group(1);
            if (itemParamsString != null) {
              final itemParams = _parseParams(itemParamsString);
              if (itemParams.isNotEmpty) {
                items.add(itemParams);
              }
            }
          }
        }
      }
    } on Exception catch (e, stackTrace) {
      _logger?.warn(
        'iOS items array parsing failed: $e. '
        'Item data may be incomplete.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    }

    return items;
  }

  /// Clean and normalize parameter values
  String _cleanValue(String value) {
    // Unwrap typed wrappers
    final wrapperMatch = _iosValueWrapperPattern.firstMatch(value.trim());
    final v = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    return v
        .replaceAll(RegExp(r'^"|"$'), '') // Remove surrounding quotes
        .replaceAll(RegExp(r"^'|'$"), '') // Remove single quotes
        .replaceAll(RegExp(r'^\(|\)$'), '') // Remove parentheses
        .replaceAll(RegExp(r'^\[|\]$'), '') // Remove brackets
        .replaceAll(RegExp(r'^{|}$'), '') // Remove braces
        .replaceAll(RegExp(r';$'), '') // Remove trailing semicolon
        .trim();
  }
}
