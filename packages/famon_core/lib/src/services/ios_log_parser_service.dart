import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/models/platform_type.dart';
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart';
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
///    ```text
///    [FirebaseAnalytics][I-ACS023051] Logging event: origin, name, params:
///    app, screen_view (_vs), {
///        ga_screen (_sn) = Dashboard;
///        ga_screen_class (_sc) = HomeViewController;
///    }
///    ```
///
/// 2. **Event logged confirmation**:
///    ```text
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
    // This captures event name which may have an abbreviation in parentheses.
    // Uses greedy .* to handle nested braces inside items arrays.
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*params:\s*\w+,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 1b: Truncated variant — no closing } (line was cut)
    RegExp(
      r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Logging event:.*params:\s*\w+,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.+)',
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
    RegExp(r'\[FirebaseAnalytics\]\[I-ACS\d+\]\s*Event logged\..*:\s*(\w+)'),

    // Pattern 4: FIRAnalytics format (alternative Firebase Analytics logging)
    // Example: FIRAnalytics: Logging event: purchase
    RegExp(r'FIRAnalytics.*Logging event:\s*(\w+)'),

    // Pattern 5: Debug view format with timestamp
    // Example: 2024-01-15 10:30:45.123+0000 [FirebaseAnalytics] Logging event:
    // origin, name, params: app, purchase
    RegExp(
      r'\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+[+-]\d+.*\[FirebaseAnalytics\].*Logging event:.*,\s*(\w+)(?:\s*\([^)]*\))?,?\s*\{(.*)\}',
      multiLine: true,
      dotAll: true,
    ),

    // Pattern 6: xcrun simctl log stream compact format
    // Compact log output may omit some formatting
    RegExp(r'FirebaseAnalytics.*event[:\s]+(\w+)', caseSensitive: false),
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

  /// Pre-compiled regex pattern for finding the `items` key position.
  static final RegExp _itemsKeyPattern = RegExp(
    r'items\s*=\s*\[',
    caseSensitive: false,
  );

  /// Pattern for cleaning iOS-specific value wrappers
  static final RegExp _iosValueWrapperPattern = RegExp(r'^[A-Za-z]+\((.*)\)$');

  // Pre-compiled patterns for _extractTimestamp (avoids hot path compilation)
  static final RegExp _isoTimestampPattern = RegExp(
    r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+)',
  );
  static final RegExp _timeOnlyPattern = RegExp(r'(\d{2}:\d{2}:\d{2}\.\d+)');

  // Pre-compiled patterns for _cleanValue (avoids hot path compilation)
  static final RegExp _surroundingDoubleQuotesPattern = RegExp(r'^"|"$');
  static final RegExp _surroundingSingleQuotesPattern = RegExp(r"^'|'$");
  static final RegExp _surroundingParenthesesPattern = RegExp(r'^\(|\)$');
  static final RegExp _surroundingBracketsPattern = RegExp(r'^\[|\]$');
  static final RegExp _surroundingBracesPattern = RegExp(r'^{|}$');
  static final RegExp _trailingSemicolonPattern = RegExp(r';$');

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
    // Parse items from the full line to avoid losing data when the regex
    // capture truncates nested braces inside the items array.
    final items = _parseItems(fullLine);

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
  ///
  /// Uses pre-compiled static patterns for performance.
  String _extractTimestamp(String line) {
    // Try to extract ISO-style timestamp using pre-compiled pattern
    final isoMatch = _isoTimestampPattern.firstMatch(line);
    if (isoMatch != null) {
      return isoMatch.group(1) ?? '';
    }

    // Try to extract time-only timestamp using pre-compiled pattern
    final timeMatch = _timeOnlyPattern.firstMatch(line);
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
      // Clean the params string and strip items array to prevent item fields
      // from bleeding into top-level params.
      final cleanParamsString = _stripItemsArray(paramsString.trim());

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

    if (paramsString.isEmpty || !_itemsKeyPattern.hasMatch(paramsString)) {
      return items;
    }

    try {
      final itemsString = _extractItemsSubstring(paramsString);
      if (itemsString == null) return items;

      // Extract individual {...} items using a depth-aware scan so that nested
      // {...} content is handled correctly (a regex using [^}]+ would stop at
      // the first '}' inside a nested object).
      var i = 0;
      while (i < itemsString.length) {
        final braceStart = itemsString.indexOf('{', i);
        if (braceStart == -1) break;

        var depth = 1;
        var endBrace = -1;

        for (var j = braceStart + 1; j < itemsString.length; j++) {
          final ch = itemsString[j];
          if (ch == '{') {
            depth++;
          } else if (ch == '}') {
            depth--;
            if (depth == 0) {
              endBrace = j;
              break;
            }
          }
        }

        if (endBrace == -1) {
          // Truncated item (no matching '}'): stop; don't include partial data.
          break;
        }

        final itemContent = itemsString.substring(braceStart + 1, endBrace);
        i = endBrace + 1;

        if (itemContent.isNotEmpty) {
          final itemParams = _parseParams(itemContent);
          if (itemParams.isNotEmpty) {
            items.add(itemParams);
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

  /// Removes the items array from a params string if present.
  ///
  /// This prevents item-level fields from being parsed as top-level params.
  /// Handles nested brackets inside `[...]` entries by tracking depth.
  /// If the array is truncated (depth never returns to 0), drops everything
  /// from `items` onward.
  String _stripItemsArray(String paramsString) {
    final match = _itemsKeyPattern.firstMatch(paramsString);
    if (match == null) {
      return paramsString;
    }

    final itemsKeyIndex = match.start;
    final bracketIndex = match.end - 1;

    var depth = 0;
    var endBracketIndex = -1;
    for (var i = bracketIndex; i < paramsString.length; i++) {
      final ch = paramsString[i];
      if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) {
          endBracketIndex = i;
          break;
        }
      }
    }

    if (endBracketIndex == -1) {
      // Truncated items array; drop everything from items onward.
      return paramsString.substring(0, itemsKeyIndex).trimRight();
    }

    final before = paramsString.substring(0, itemsKeyIndex).trimRight();
    final after = paramsString.substring(endBracketIndex + 1).trimLeft();

    if (before.isEmpty) {
      return after.startsWith(';') ? after.substring(1).trimLeft() : after;
    }

    if (after.isEmpty) {
      return before.endsWith(';')
          ? before.substring(0, before.length - 1).trimRight()
          : before;
    }

    return '$before $after';
  }

  /// Extracts the items array substring, bounded by the matching `]`.
  ///
  /// Uses `[`/`]` depth tracking to find the closing bracket of the
  /// `items = [...]` array. Falls back to end-of-string when the array is
  /// truncated (no matching `]` exists), so complete items before the cut-off
  /// are still parsed.
  String? _extractItemsSubstring(String paramsString) {
    final match = _itemsKeyPattern.firstMatch(paramsString);
    if (match == null) {
      return null;
    }

    // match.end - 1 is the position of the '[' in 'items = ['
    final startIndex = match.end - 1;

    // Depth-track '['/']' to find the matching close of the items array.
    var depth = 0;
    var endIndex = -1;
    for (var i = startIndex; i < paramsString.length; i++) {
      final ch = paramsString[i];
      if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) {
          endIndex = i;
          break;
        }
      }
    }

    if (endIndex != -1) {
      // Non-truncated: return only the content inside items = [...].
      return paramsString.substring(startIndex + 1, endIndex);
    }

    // Truncated array: return everything after 'items = [' so complete items
    // before the cut-off can still be parsed.
    return paramsString.substring(startIndex + 1);
  }

  /// Clean and normalize parameter values.
  ///
  /// Uses pre-compiled static patterns for performance.
  String _cleanValue(String value) {
    // Unwrap typed wrappers
    final wrapperMatch = _iosValueWrapperPattern.firstMatch(value.trim());
    final v = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    return v
        .replaceAll(_surroundingDoubleQuotesPattern, '') // Remove quotes
        .replaceAll(_surroundingSingleQuotesPattern, '') // Remove single quotes
        .replaceAll(_surroundingParenthesesPattern, '') // Remove parentheses
        .replaceAll(_surroundingBracketsPattern, '') // Remove brackets
        .replaceAll(_surroundingBracesPattern, '') // Remove braces
        .replaceAll(_trailingSemicolonPattern, '') // Remove trailing semicolon
        .trim();
  }
}
