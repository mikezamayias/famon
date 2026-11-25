import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart';
import 'package:famon_core/src/shared/status_logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Shared parsing skeleton for the Android and iOS log parsers.
///
/// Both platforms follow the same shape: a cheap marker check, an ordered
/// list of line patterns, a key/value scan over the params block, and a
/// depth-aware scan over the items array. Only the patterns, the token that
/// opens an item, and the value cleaning differ, so those are the hooks.
abstract class BaseLogParserService implements LogParserInterface {
  /// Creates the base parser with an optional [logger] for parse failures.
  BaseLogParserService({this.logger});

  /// Logger used for reporting parsing errors.
  final Logger? logger;

  /// Short platform label used in warning messages, e.g. `Android` or `iOS`.
  String get platformLabel;

  /// Substrings that must appear in a line for it to be worth matching.
  List<String> get faMarkers;

  /// Line patterns, ordered by expected frequency.
  List<RegExp> get logPatterns;

  /// Key/value patterns applied to the params block.
  List<RegExp> get paramPatterns;

  /// Token that opens one item inside the items array.
  ///
  /// Android bundles read `Bundle[{...}]`, iOS dictionaries read `{...}`.
  /// The last character of the token must be `{`.
  String get itemOpenToken;

  /// Builds an event from a matched line, or `null` to keep trying patterns.
  AnalyticsEvent? createAnalyticsEvent(RegExpMatch match, String fullLine);

  /// Called when no line pattern matched. Returns `null` by default.
  AnalyticsEvent? parseUnmatched(String logLine) => null;

  /// Prepares the params block before the key/value scan.
  ///
  /// Implementations strip wrappers and the items array here.
  String normalizeParamsString(String paramsString);

  /// Called after the key/value scan with the normalized block.
  ///
  /// Android uses this for a looser second pass when few params matched.
  void afterParamScan(String cleanParamsString, Map<String, String> params) {}

  /// Whether [paramsString] carries an items array worth scanning.
  bool hasItemsArray(String paramsString);

  /// Extracts the items array substring, bounded by the matching `]`.
  String? extractItemsSubstring(String paramsString);

  /// Wraps one item's inner content so [parseParams] can read it.
  String wrapItemContent(String itemContent) => itemContent;

  /// Cleans and normalizes a single parameter value.
  String cleanValue(String value);

  @override
  AnalyticsEvent? parse(String logLine) {
    if (logLine.isEmpty) return null;

    if (!containsFaMarker(logLine)) {
      return null;
    }

    for (final regex in logPatterns) {
      final match = regex.firstMatch(logLine);
      if (match != null) {
        final event = createAnalyticsEvent(match, logLine);
        if (event != null) return event;
      }
    }

    return parseUnmatched(logLine);
  }

  /// Fast check that skips lines which cannot match any pattern.
  bool containsFaMarker(String line) {
    for (final marker in faMarkers) {
      if (line.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  /// Parses a params block into a flat key/value map.
  Map<String, String> parseParams(String paramsString) {
    final params = <String, String>{};

    if (paramsString.isEmpty) {
      return params;
    }

    try {
      final cleanParamsString = normalizeParamsString(paramsString);

      for (final pattern in paramPatterns) {
        for (final match in pattern.allMatches(cleanParamsString)) {
          if (match.groupCount < 2) continue;
          final key = match.group(1)?.trim();
          final value = match.group(2)?.trim();

          if (key == null || value == null) continue;
          if (key.isEmpty || value.isEmpty) continue;
          // Items are parsed separately by [parseItems].
          if (key.toLowerCase() == 'items') continue;

          params[key] = cleanValue(value);
        }
      }

      afterParamScan(cleanParamsString, params);
    } on Exception catch (e, stackTrace) {
      _warn(
        '$platformLabel parameter parsing failed',
        e,
        stackTrace,
        paramsString,
      );
    }

    return params;
  }

  /// Parses the items array into one map per item.
  ///
  /// Items are located with a depth-aware brace scan so nested content
  /// inside an item does not end it early. A truncated item, one with no
  /// closing brace, ends the scan without adding partial data.
  List<Map<String, String>> parseItems(String paramsString) {
    final items = <Map<String, String>>[];

    if (paramsString.isEmpty || !hasItemsArray(paramsString)) {
      return items;
    }

    try {
      final itemsString = extractItemsSubstring(paramsString);
      if (itemsString == null) return items;

      var i = 0;
      while (i < itemsString.length) {
        final tokenStart = itemsString.indexOf(itemOpenToken, i);
        if (tokenStart == -1) break;

        final braceStart = tokenStart + itemOpenToken.length - 1;
        final endBrace = _matchingBrace(itemsString, braceStart);
        if (endBrace == -1) break;

        final itemContent = itemsString.substring(braceStart + 1, endBrace);
        i = endBrace + 1;

        if (itemContent.isNotEmpty) {
          final itemParams = parseParams(wrapItemContent(itemContent));
          if (itemParams.isNotEmpty) {
            items.add(itemParams);
          }
        }
      }
    } on Exception catch (e, stackTrace) {
      _warn(
        '$platformLabel items array parsing failed',
        e,
        stackTrace,
        paramsString,
      );
    }

    return items;
  }

  /// Returns the index of the `}` matching the `{` at [openIndex], or -1.
  static int _matchingBrace(String text, int openIndex) {
    var depth = 1;
    for (var j = openIndex + 1; j < text.length; j++) {
      final ch = text[j];
      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return j;
      }
    }
    return -1;
  }

  void _warn(String what, Object error, StackTrace stackTrace, String input) {
    logger?.warn('$what: $error. Some event data may be missing.');
    logger?.statusDetail('Stack trace: $stackTrace');
    logger?.statusDetail('Input: $input');
  }
}
