/// Pre-compiled regex pattern for Android logcat timestamp parsing.
///
/// Matches format: `MM-DD HH:mm:ss.SSS`
final _logcatTimestampPattern = RegExp(
  r'^(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{3})',
);

/// Parses Android logcat timestamps (`MM-DD HH:mm:ss.SSS`) into a [DateTime].
///
/// The log format does not include a year, so we infer it using [reference].
/// By default we use [DateTime.now]. When the inferred timestamp ends up more
/// than ~30 days in the future we roll it back one year, and when it is more
/// than ~335 days in the past we roll it forward a year. This keeps year
/// boundaries stable when capturing logs near New Year's.
DateTime? parseLogcatTimestamp(String value, {DateTime? reference}) {
  // Use pre-compiled static pattern for better performance
  final match = _logcatTimestampPattern.firstMatch(value);
  if (match == null) {
    return null;
  }

  final ref = reference ?? DateTime.now();
  final month = int.parse(match.group(1)!);
  final day = int.parse(match.group(2)!);
  final hour = int.parse(match.group(3)!);
  final minute = int.parse(match.group(4)!);
  final second = int.parse(match.group(5)!);
  final millisecond = int.parse(match.group(6)!);

  var inferred = DateTime(
    ref.year,
    month,
    day,
    hour,
    minute,
    second,
    millisecond,
  );

  // If the inferred time is too far in the future relative to the reference,
  // we likely crossed a year boundary (e.g., logs from December replayed in
  // January). Roll back one year.
  if (inferred.isAfter(ref.add(const Duration(days: 30)))) {
    inferred = DateTime(
      ref.year - 1,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  // Likewise, if the inferred time is almost a full year behind, bump it
  // forward. This guards replays recorded late in the previous year being read
  // near the next New Year.
  if (inferred.isBefore(ref.subtract(const Duration(days: 335)))) {
    inferred = DateTime(
      ref.year + 1,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  return inferred;
}
