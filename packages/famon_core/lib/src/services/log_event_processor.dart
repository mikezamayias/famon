import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/services/interfaces/log_parser_interface.dart';
import 'package:famon_core/src/utils/event_filter_utils.dart';

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
  /// [verbose] surfaces non-event Firebase Analytics lines (`FA`/`FA-SVC`
  /// chatter, `FirebaseCrashlytics` lines) for callers that want to show
  /// the underlying log stream.
  LogEventProcessResult processLine(
    String line, {
    List<String> hideEvents = const [],
    List<String> showOnlyEvents = const [],
    bool verbose = false,
  }) {
    final event = parser.parse(line);
    if (event != null) {
      final shouldSkip = EventFilterUtils.shouldSkipEvent(
        event.eventName,
        hideEvents,
        showOnlyEvents,
      );

      return LogEventProcessResult(
        event: event,
        shouldDisplay: !shouldSkip,
      );
    }

    if (verbose && _isVerboseFirebaseLine(line)) {
      return LogEventProcessResult(verboseLine: line, shouldDisplay: true);
    }

    return const LogEventProcessResult(shouldDisplay: false);
  }

  bool _isVerboseFirebaseLine(String line) {
    return line.contains(' FA ') ||
        line.contains(' FA-SVC ') ||
        line.contains(' FA-') ||
        line.contains('FirebaseCrashlytics');
  }
}

/// Outcome of processing one log line.
///
/// Exactly one of [event] or [verboseLine] is populated when
/// [shouldDisplay] is `true`; both are `null` when the line was discarded.
class LogEventProcessResult {
  /// Creates a process result.
  const LogEventProcessResult({
    required this.shouldDisplay,
    this.event,
    this.verboseLine,
  });

  /// Whether the host should render this result to the user.
  final bool shouldDisplay;

  /// The parsed analytics event, if the line was an event log.
  final AnalyticsEvent? event;

  /// The raw verbose Firebase log line, when [event] is null but the line
  /// is still useful to surface in verbose mode.
  final String? verboseLine;
}
