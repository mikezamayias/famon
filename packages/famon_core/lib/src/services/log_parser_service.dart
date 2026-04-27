import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/models/platform_type.dart';
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart';
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
/// 1. **Standard format** (`Logging event: origin=\w+,name=...`) - Most common
///    format in modern Firebase Analytics implementations. Accepts any origin
///    value (`app`, `auto`, `firebase`).
/// 2. **FA-SVC tagged patterns** - Firebase Analytics Service logs, frequently
///    seen in debug builds.
/// 3. **FA tagged patterns** - General Firebase Analytics logs.
/// 4. **FA `Logging event (FE)` / `Event logged` formats** - Native Firebase
///    SDK auto-events. Matched by `\bFA\b` to cover both brief (`I/FA:`) and
///    `-v time` (`V FA-SVC  :`, `V FA  :`) logcat output formats.
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

  @override
  PlatformType get platform => PlatformType.android;

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
    // Pattern 1: Standard format with explicit origin field
    // Matches both app-logged (origin=app) and auto/native (origin=auto, origin=firebase) events.
    // Example: Logging event: origin=app,name=purchase,params=Bundle[{...}]
    // Example: Logging event: origin=auto,name=screen_view,params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Logging event: '
      r'origin=\w+,name=([^,]+),params=(Bundle\[.*\])',
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

    // Pattern 6: FA "Logging event (FE)" format without name= prefix
    // Matches both brief (I/FA:) and -v time (V FA-SVC  :) logcat formats.
    // Example (brief):    I/FA: Logging event (FE): screen_view, Bundle[...]
    // Example (-v time):  V FA-SVC  : Logging event (FE): screen_view, ...
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Logging event \(FE\): ([^,\s]+),.*(Bundle\[.*\])',
    ),

    // Pattern 7: FA "Event logged" format
    // Matches both brief (I/FA:) and -v time (V FA  :) logcat formats.
    // Example (brief):   I/FA: Event logged: purchase, params=Bundle[{...}]
    // Example (-v time): V FA  : Event logged: purchase, params=Bundle[{...}]
    RegExp(
      r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*\bFA\b.*Event logged: ([^,\s]+).*params[:=](Bundle\[.*\])',
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

  /// Pre-compiled regex patterns for parameter parsing.
  ///
  /// These patterns handle various Firebase Analytics Bundle parameter formats.
  /// Stored as static final to avoid regex compilation overhead on each
  /// `_parseParams()` call.
  static final List<RegExp> _paramPatterns = [
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

  /// Pre-compiled regex pattern for typed value wrappers.
  ///
  /// Matches patterns like String(...), Long(...), Double(...), etc.
  static final RegExp _typedWrapperPattern = RegExp(r'^[A-Za-z]+\((.*)\)$');

  /// Validates Firebase event names: letters/digits/underscores, starts with
  /// a letter, max 40 characters.
  static final RegExp _validFirebaseNamePattern =
      RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

  /// Maximum allowed length for a Firebase event name.
  static const int _maxEventNameLength = 40;

  /// Maximum allowed length for a Firebase parameter value.
  static const int _maxParamValueLength = 100;

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
    // Short-circuits on first successful match with a valid event name.
    for (final regex in _logPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        final event = _createAnalyticsEvent(match);
        if (event != null) return event;
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

  /// Create AnalyticsEvent from regex match.
  ///
  /// Returns `null` if the captured event name does not conform to the
  /// Firebase naming convention (`^[a-zA-Z][a-zA-Z0-9_]*$`, max 40 chars),
  /// dropping malformed or potentially malicious log lines.
  AnalyticsEvent? _createAnalyticsEvent(RegExpMatch match) {
    final timestamp = match.group(1)!;
    final eventName = match.group(2)!;

    if (!_isValidEventName(eventName)) {
      _logger?.warn('Skipping invalid Firebase event name: "$eventName"');
      return null;
    }

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
      // Clean the params string first
      var cleanParamsString = paramsString;
      if (cleanParamsString.startsWith('Bundle[{')) {
        cleanParamsString = cleanParamsString.substring(8);
      }
      if (cleanParamsString.endsWith('}]')) {
        cleanParamsString = cleanParamsString.substring(
          0,
          cleanParamsString.length - 2,
        );
      }

      // Remove items array so item_* fields don't bleed into top-level params.
      cleanParamsString = _stripItemsArray(cleanParamsString);

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

      // If we didn't get many params, try a more aggressive approach
      if (params.length < 3 && cleanParamsString.isNotEmpty) {
        _parseParamsAggressive(cleanParamsString, params);
      }
    } on FormatException catch (e, stackTrace) {
      _logger?.warn(
        'Parameter parsing failed (FormatException): $e. '
        'Some event parameters may be missing.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    } on Exception catch (e, stackTrace) {
      _logger?.warn(
        'Parameter parsing failed: $e. '
        'Some event parameters may be missing.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    }

    return params;
  }

  /// Removes the items array from a Bundle params string if present.
  ///
  /// This prevents item-level fields from being parsed as top-level params.
  /// Handles nested brackets inside Bundle[...] entries by tracking depth.
  String _stripItemsArray(String paramsString) {
    final itemsKeyIndex = paramsString.indexOf('items=[');
    if (itemsKeyIndex == -1) {
      return paramsString;
    }

    final startBracketIndex = paramsString.indexOf('[', itemsKeyIndex);
    if (startBracketIndex == -1) {
      return paramsString;
    }

    var depth = 0;
    var endBracketIndex = -1;
    for (var i = startBracketIndex; i < paramsString.length; i++) {
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
      // Truncated items array; drop everything from items=[ onward.
      return paramsString.substring(0, itemsKeyIndex).trimRight();
    }

    final before = paramsString.substring(0, itemsKeyIndex).trimRight();
    final after = paramsString.substring(endBracketIndex + 1).trimLeft();

    if (before.isEmpty) {
      return after.startsWith(',') ? after.substring(1).trimLeft() : after;
    }

    if (after.isEmpty) {
      return before.endsWith(',')
          ? before.substring(0, before.length - 1)
          : before;
    }

    final cleanedAfter =
        after.startsWith(',') ? after.substring(1).trimLeft() : after;
    return '$before, $cleanedAfter';
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
      final itemsString = _extractItemsSubstring(paramsString);
      if (itemsString == null) return items;

      // Extract individual Bundle[{...}] items using a depth-aware scan so
      // that nested Bundle[{...}] content is handled correctly (a regex using
      // [^}]+ would stop at the first '}' inside a nested bundle).
      var i = 0;
      while (i < itemsString.length) {
        final bundleStart = itemsString.indexOf('Bundle[{', i);
        if (bundleStart == -1) break;

        // Index of the '{' in 'Bundle[{' (+7 to skip past 'Bundle[')
        final braceStart = bundleStart + 7;
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
          final itemParams = _parseParams('Bundle[{$itemContent}]');
          if (itemParams.isNotEmpty) {
            items.add(itemParams);
          }
        }
      }
    } on FormatException catch (e, stackTrace) {
      _logger?.warn(
        'Items array parsing failed (FormatException): $e. '
        'Item data may be incomplete.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    } on Exception catch (e, stackTrace) {
      _logger?.warn(
        'Items array parsing failed: $e. '
        'Item data may be incomplete.',
      );
      _logger?.detail('Stack trace: $stackTrace');
      _logger?.detail('Input: $paramsString');
    }

    return items;
  }

  /// Extracts the items array substring, bounded by the matching `]`.
  ///
  /// Uses `[`/`]` depth tracking to find the closing bracket of the
  /// `items=[...]` array. Falls back to end-of-string when the array is
  /// truncated (no matching `]` exists), so complete items before the cut-off
  /// are still parsed.
  String? _extractItemsSubstring(String paramsString) {
    final itemsKeyIndex = paramsString.indexOf('items=[');
    if (itemsKeyIndex == -1) {
      return null;
    }

    final startIndex = paramsString.indexOf('[', itemsKeyIndex);
    if (startIndex == -1) {
      return null;
    }

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
      // Non-truncated: return only the content inside items=[...].
      return paramsString.substring(startIndex + 1, endIndex);
    }

    // Truncated array: return everything after 'items=[' so complete items
    // before the cut-off can still be parsed.
    return paramsString.substring(startIndex + 1);
  }

  /// Returns true if [name] conforms to Firebase event name conventions.
  bool _isValidEventName(String name) =>
      name.isNotEmpty &&
      name.length <= _maxEventNameLength &&
      _validFirebaseNamePattern.hasMatch(name);

  /// Clean and normalize a parameter value in a single pass.
  ///
  /// Steps (all in one StringBuffer scan to avoid chained replaceAll):
  /// 1. Unwrap typed wrappers e.g. `String(v)`, `Long(v)`.
  /// 2. Strip leading/trailing delimiter characters (`"'()[]{}`) from the raw
  ///    string.
  /// 3. Iterate the remaining characters once: skip ASCII control characters
  ///    and stop after [_maxParamValueLength] characters have been written.
  String _cleanValue(String value) {
    // Unwrap typed wrappers: String(...), Long(...), Double(...), Boolean(...)
    final wrapperMatch = _typedWrapperPattern.firstMatch(value.trim());
    final raw = wrapperMatch != null ? (wrapperMatch.group(1) ?? value) : value;

    // Strip surrounding delimiter characters from both ends.
    var start = 0;
    var end = raw.length;
    while (start < end && _isWrapperDelimiter(raw.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _isWrapperDelimiter(raw.codeUnitAt(end - 1))) {
      end--;
    }

    final candidate = raw.substring(start, end).trim();

    // Single pass: skip control characters, collect up to _maxParamValueLength.
    final out = StringBuffer();
    for (final codeUnit in candidate.codeUnits) {
      final isControl =
          (codeUnit >= 0x00 && codeUnit <= 0x1F) || codeUnit == 0x7F;
      if (!isControl) {
        out.writeCharCode(codeUnit);
        if (out.length >= _maxParamValueLength) break;
      }
    }

    return out.toString();
  }

  /// Returns true if [codeUnit] is a delimiter that should be stripped from
  /// the start or end of a parameter value.
  static bool _isWrapperDelimiter(int codeUnit) =>
      codeUnit == 0x22 || // "
      codeUnit == 0x27 || // '
      codeUnit == 0x28 || // (
      codeUnit == 0x29 || // )
      codeUnit == 0x5B || // [
      codeUnit == 0x5D || // ]
      codeUnit == 0x7B || // {
      codeUnit == 0x7D; // }
}
