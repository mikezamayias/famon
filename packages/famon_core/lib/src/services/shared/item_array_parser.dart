/// Shared `items=[...]` array parsing primitives used by both the
/// Android (`LogParserService`) and iOS (`IosLogParserService`) Firebase
/// Analytics log parsers.
///
/// The two platforms emit different separator characters (`,` on
/// Android, `;` on iOS) and different field syntaxes (`key=value` vs
/// `key (_abbrev) = value`), but the `items=[...]` array uses the same
/// depth-tracked `[`/`]` structure on both. This class centralises the
/// depth-tracking and the cut-off handling so platform-specific parsers
/// only carry their separator/regex differences, not the bracket math.
///
/// **Truncation behaviour** is identical to the historical per-platform
/// implementations:
/// - **Strip**: when the array has no closing `]` in the log line
///   (logcat / oslog truncated the line), the helper drops everything
///   from the `items` key onward. Top-level params before `items` survive.
/// - **Extract**: when the array is truncated, the helper returns the
///   remainder of the line after the opening `[` so complete items in
///   front of the cut-off can still be parsed.
class ItemArrayParser {
  const ItemArrayParser._();

  /// Removes the `items=[...]` Bundle from an Android params string.
  ///
  /// Android top-level parameter pairs are separated by `, ` and the
  /// downstream parser's regex uses `[,\]}]|$` to bound each value, so
  /// the helper only strips a leading `,` from the suffix and joins
  /// with `, `. The prefix's trailing `,` is preserved — the duplicate
  /// is harmless because the bounding regex tolerates it, and stripping
  /// it would require an extra pass.
  static String stripAndroidItemsArray(String paramsString) {
    final itemsKeyIndex = paramsString.indexOf('items=[');
    if (itemsKeyIndex == -1) {
      return paramsString;
    }

    final startBracketIndex = paramsString.indexOf('[', itemsKeyIndex);
    if (startBracketIndex == -1) {
      return paramsString;
    }

    return _stripBracketedArray(
      paramsString: paramsString,
      itemsKeyIndex: itemsKeyIndex,
      startBracketIndex: startBracketIndex,
      separator: ',',
      joiner: ', ',
      stripLeadingSeparatorWhenBothPresent: true,
    );
  }

  /// Removes the iOS `items = [...]` block from a params string.
  ///
  /// [itemsKeyPattern] must be a `RegExp` matching the `items` key plus
  /// the opening `[` (e.g. `RegExp(r'items\s*=\s*\[')`). The pattern's
  /// match end is treated as one past the opening `[`. iOS field pairs
  /// are `;`-terminated, so when both prefix and suffix survive the
  /// stripped array, the helper preserves both delimiters and joins
  /// them with a single space — the iOS `_paramPatterns` regex relies
  /// on the trailing `;` to bound each value.
  static String stripIosItemsArray(
    String paramsString,
    RegExp itemsKeyPattern,
  ) {
    final match = itemsKeyPattern.firstMatch(paramsString);
    if (match == null) {
      return paramsString;
    }

    return _stripBracketedArray(
      paramsString: paramsString,
      itemsKeyIndex: match.start,
      startBracketIndex: match.end - 1,
      separator: ';',
      joiner: ' ',
      stripLeadingSeparatorWhenBothPresent: false,
    );
  }

  /// Extracts the content of the Android `items=[...]` array.
  ///
  /// Returns the substring between the outer `[` and matching `]`. When
  /// the array is truncated, returns the remainder of the string after
  /// the opening `[`. Returns `null` when the params string does not
  /// contain an `items=[` key.
  static String? extractAndroidItemsSubstring(String paramsString) {
    final itemsKeyIndex = paramsString.indexOf('items=[');
    if (itemsKeyIndex == -1) {
      return null;
    }

    final startBracketIndex = paramsString.indexOf('[', itemsKeyIndex);
    if (startBracketIndex == -1) {
      return null;
    }

    return _extractBracketedContent(paramsString, startBracketIndex);
  }

  /// Extracts the content of an iOS `items = [...]` array.
  ///
  /// [itemsKeyPattern] must match the `items` key plus its opening `[`
  /// so that `match.end - 1` is the position of the `[`. Returns `null`
  /// when the pattern does not match.
  static String? extractIosItemsSubstring(
    String paramsString,
    RegExp itemsKeyPattern,
  ) {
    final match = itemsKeyPattern.firstMatch(paramsString);
    if (match == null) {
      return null;
    }

    return _extractBracketedContent(paramsString, match.end - 1);
  }

  /// Returns the index of the `]` that closes the `[` at
  /// [openBracketIndex], or `-1` if the bracket is never closed
  /// (truncated array).
  static int _findMatchingCloseBracket(String text, int openBracketIndex) {
    var depth = 0;
    for (var i = openBracketIndex; i < text.length; i++) {
      final ch = text[i];
      if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Returns the content between the opening `[` at [openBracketIndex]
  /// and its matching `]`. When the bracket is never closed, returns
  /// the remainder of [text] after the opening `[`.
  static String _extractBracketedContent(String text, int openBracketIndex) {
    final close = _findMatchingCloseBracket(text, openBracketIndex);
    if (close == -1) {
      return text.substring(openBracketIndex + 1);
    }
    return text.substring(openBracketIndex + 1, close);
  }

  /// Removes the bracketed array beginning at [startBracketIndex] from
  /// [paramsString]; the surviving prefix and suffix are joined with
  /// [joiner].
  ///
  /// When the array is truncated (no matching `]`), drops everything
  /// from [itemsKeyIndex] onward and returns the prefix trimmed of
  /// trailing whitespace only.
  ///
  /// When prefix or suffix is empty, the helper drops a stray
  /// [separator] character that would otherwise be left dangling. When
  /// both survive, [stripLeadingSeparatorWhenBothPresent] controls
  /// whether the suffix's leading separator is removed before the
  /// join — Android sets this true (the `,` delimiter is recreated by
  /// [joiner]), iOS sets this false because its top-level parameter
  /// regex in `IosLogParserService` requires the trailing `;` to bound
  /// each value.
  static String _stripBracketedArray({
    required String paramsString,
    required int itemsKeyIndex,
    required int startBracketIndex,
    required String separator,
    required String joiner,
    required bool stripLeadingSeparatorWhenBothPresent,
  }) {
    final endBracketIndex = _findMatchingCloseBracket(
      paramsString,
      startBracketIndex,
    );
    if (endBracketIndex == -1) {
      return paramsString.substring(0, itemsKeyIndex).trimRight();
    }

    final before = paramsString.substring(0, itemsKeyIndex).trimRight();
    final after = paramsString.substring(endBracketIndex + 1).trimLeft();

    if (before.isEmpty) {
      return after.startsWith(separator)
          ? after.substring(1).trimLeft()
          : after;
    }
    if (after.isEmpty) {
      return before.endsWith(separator)
          ? before.substring(0, before.length - 1).trimRight()
          : before;
    }

    final cleanedAfter =
        stripLeadingSeparatorWhenBothPresent && after.startsWith(separator)
            ? after.substring(1).trimLeft()
            : after;
    return '$before$joiner$cleanedAfter';
  }
}
