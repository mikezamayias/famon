// Relative imports keep this file portable across analyzers that do not
// resolve `package:famon_core/src/...` self-references inside the package.
// ignore_for_file: always_use_package_imports

import '../core/domain/entities/analytics_event.dart';
import '../utils/event_filter_utils.dart';
import 'interfaces/log_parser_interface.dart';

/// Pure log-line processing primitive that turns a raw log line into a
/// structured outcome a host can render or persist however it likes.
///
/// `LogEventProcessor` is intentionally free of terminal, ANSI, clipboard,
/// or process-lifecycle concerns. It pairs a [LogParserInterface] with the
/// shared [EventFilterUtils] filter rules so callers in any host (the
/// `famon` CLI, a future GUI, a CI lint, a server) can share the same
/// parse-and-filter logic.
class LogEventProcessor {
  /// Creates a processor backed by [parser].
  const LogEventProcessor({required this.parser});

  /// The parser used to decode log lines into [AnalyticsEvent]s.
  final LogParserInterface parser;

  /// Process a single raw log [line] and return a [LogEventProcessResult].
  ///
  /// [hideEvents] suppresses matching event names from display.
  /// [showOnlyEvents], when non-empty, restricts display to those names.
  /// When both are set, [showOnlyEvents] takes precedence (see
  /// [EventFilterUtils.shouldSkipEvent]).
  ///
  /// [verbose] surfaces non-event Firebase Analytics lines for callers
  /// that want to show the underlying log stream. The heuristic covers
  /// Android tags (`FA`, `FA-SVC`, `I/FA`, `D/FA`, `V/FA`, `W/FA`,
  /// `E/FA`) and iOS / Crashlytics markers (`FirebaseAnalytics`,
  /// `Firebase/Analytics`, `FIRAnalytics`, `FirebaseCrashlytics`,
  /// `Crashlytics`).
  LogEventProcessResult processLine(
    String line, {
    List<String> hideEvents = const [],
    List<String> showOnlyEvents = const [],
    bool verbose = false,
  }) {
    final event = parser.parse(line);
    if (event != null) {
      final skip = EventFilterUtils.shouldSkipEvent(
        event.eventName,
        hideEvents,
        showOnlyEvents,
      );
      return skip ? const LogDiscardedResult() : LogEventResult(event);
    }

    if (verbose && _verboseFirebasePattern.hasMatch(line)) {
      return LogVerboseResult(line);
    }

    return const LogDiscardedResult();
  }

  /// Matches Firebase Analytics / Crashlytics chatter for both Android
  /// log tags (`FA`, `FA-SVC`, `I/FA`, etc.) and iOS markers
  /// (`FirebaseAnalytics`, `Firebase/Analytics`, `FIRAnalytics`).
  ///
  /// Compiled once because [processLine] is called per log line on a hot
  /// path (CLAUDE.md performance guideline).
  static final RegExp _verboseFirebasePattern = RegExp(
    r'\bFA-SVC\b|\bFA\b|I/FA|D/FA|V/FA|W/FA|E/FA|'
    'FirebaseCrashlytics|Crashlytics|FirebaseAnalytics|'
    'Firebase/Analytics|FIRAnalytics',
  );
}

/// Outcome of processing one log line.
///
/// Sealed sum type. Exhaustively match on a `switch` to handle every
/// possible outcome:
/// - [LogEventResult] — a Firebase Analytics event was parsed and is
///   allowed by the active filters.
/// - [LogVerboseResult] — the line is non-event Firebase Analytics
///   chatter and verbose mode is on.
/// - [LogDiscardedResult] — the line was either unparseable, an event
///   filtered out by the active rules, or non-event chatter in
///   non-verbose mode. Hosts should skip it.
sealed class LogEventProcessResult {
  const LogEventProcessResult();
}

/// A parsed [AnalyticsEvent] that should be displayed by the host.
final class LogEventResult extends LogEventProcessResult {
  /// Creates an event result wrapping [event].
  const LogEventResult(this.event);

  /// The parsed analytics event.
  final AnalyticsEvent event;
}

/// A non-event Firebase Analytics log line surfaced in verbose mode.
final class LogVerboseResult extends LogEventProcessResult {
  /// Creates a verbose result wrapping [line].
  const LogVerboseResult(this.line);

  /// The raw log line.
  final String line;
}

/// A log line the host should skip (unparseable, filtered out, or
/// non-event chatter in non-verbose mode).
final class LogDiscardedResult extends LogEventProcessResult {
  /// Creates a discarded result.
  const LogDiscardedResult();
}
