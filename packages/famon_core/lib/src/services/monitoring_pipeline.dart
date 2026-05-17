// Relative imports keep this file portable across analyzers that do not
// resolve `package:famon_core/src/...` self-references inside the package.
// ignore_for_file: always_use_package_imports

import 'dart:async';
import 'dart:convert';

import 'log_event_processor.dart';

/// Signature for the warning callback the pipeline uses to report
/// recoverable issues (currently: malformed UTF-8 byte counts).
typedef MonitoringPipelineOnWarning = void Function(String message);

/// Result callback signature.
///
/// Return `true` to keep consuming the stream, `false` to stop and
/// exit [MonitoringPipeline.run] early (e.g. when a `--limit` is hit).
typedef MonitoringPipelineCallback = FutureOr<bool> Function(
  LogEventProcessResult result,
);

/// Host-agnostic stream pipeline that consumes a raw log process and
/// emits structured [LogEventProcessResult] values to a host callback.
///
/// The pipeline owns the bits of monitor-loop behavior that were
/// previously duplicated between `MonitorCommand` and
/// `FilteredMonitorCommand` in the `famon` CLI package:
///
/// - stderr draining (prevents the child process from blocking on
///   stderr buffer overflow);
/// - UTF-8 line decoding with malformed byte tracking and
///   rate-limited warning callbacks;
/// - delegation to [LogEventProcessor] for parse decisions;
/// - verbose-mode raw line emission for Firebase Analytics /
///   Crashlytics chatter, matching the historical `MonitorCommand`
///   behavior where verbose surfaces both the parsed event and the
///   raw log line it came from.
///
/// The pipeline intentionally does **not** apply hide / show-only
/// filtering, caching, persistence, or terminal rendering: callers do
/// that themselves so they can decide whether filtered events still
/// update caches and stats. The pipeline is also free of
/// `mason_logger`, terminal, ANSI, clipboard, and process-lifecycle
/// concerns — those remain in the host CLI / GUI / server.
class MonitoringPipeline {
  /// Creates a pipeline backed by [processor]. Provide [onWarning] to
  /// receive a rate-limited message every time the pipeline observes
  /// malformed UTF-8 in the input stream; omit it to silently swallow
  /// those warnings.
  const MonitoringPipeline({
    required this.processor,
    this.onWarning,
  });

  /// Parse primitive used to decode each log line into a
  /// [LogEventProcessResult].
  final LogEventProcessor processor;

  /// Optional callback for malformed-UTF-8 warning messages. Defaults
  /// to `null`, in which case warnings are dropped silently.
  final MonitoringPipelineOnWarning? onWarning;

  /// Pre-compiled regex matching Firebase Analytics + Crashlytics
  /// chatter on both Android (`FA`, `FA-SVC`, level-prefixed tags
  /// `I/FA`, `D/FA`, etc.) and iOS (`FirebaseAnalytics`,
  /// `Firebase/Analytics`, `FIRAnalytics`).
  ///
  /// Lifted to a static field so the per-line cost stays flat (CLAUDE.md
  /// performance guideline).
  static final RegExp _firebaseRelatedPattern = RegExp(
    r'\bFA-SVC\b|\bFA\b|I/FA|D/FA|V/FA|W/FA|E/FA|'
    'FirebaseCrashlytics|Crashlytics|FirebaseAnalytics|'
    'Firebase/Analytics|FIRAnalytics',
  );

  /// Whether [line] is a Firebase Analytics or Crashlytics log line
  /// that should be surfaced in verbose mode.
  static bool isFirebaseRelatedLogLine(String line) =>
      _firebaseRelatedPattern.hasMatch(line);

  /// Consume [stdout] line-by-line and emit a [LogEventProcessResult]
  /// to [onResult] for every parsed event and (when [verbose] is on)
  /// every raw Firebase Analytics / Crashlytics chatter line.
  ///
  /// [stderr] is drained concurrently to prevent the child process
  /// from stalling on its stderr buffer. When [verbose] is true,
  /// lines matching [isFirebaseRelatedLogLine] are emitted as
  /// [LogVerboseResult] **before** the parsed [LogEventResult] for
  /// the same line, so the host can render the raw line alongside
  /// the formatted event.
  ///
  /// Returning `false` from [onResult] breaks the loop and resolves
  /// the returned future. The caller is responsible for killing the
  /// underlying process when it decides the pipeline should stop.
  Future<void> run({
    required Stream<List<int>> stdout,
    required Stream<List<int>> stderr,
    required bool verbose,
    required MonitoringPipelineCallback onResult,
  }) async {
    unawaited(stderr.drain<void>());

    var malformedByteCount = 0;
    var lastMalformedWarning = DateTime.now();

    await for (final line in stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())) {
      final replacementCount = '�'.allMatches(line).length;
      if (replacementCount > 0) {
        malformedByteCount += replacementCount;
        final now = DateTime.now();
        if (now.difference(lastMalformedWarning).inSeconds >= 60) {
          onWarning?.call(
            'Detected $malformedByteCount malformed '
            'UTF-8 byte(s) in log stream. '
            'Some log data may be corrupted.',
          );
          lastMalformedWarning = now;
        }
      }

      // Verbose: surface the raw line for Firebase chatter independent
      // of whether the same line also parses to an event below.
      if (verbose && isFirebaseRelatedLogLine(line)) {
        final keepGoing = await onResult(LogVerboseResult(line));
        if (!keepGoing) return;
      }

      // Parse only; filtering, caching, and display are caller
      // concerns (see class-level dartdoc).
      final eventResult = processor.processLine(line);

      if (eventResult is LogEventResult) {
        final keepGoing = await onResult(eventResult);
        if (!keepGoing) return;
      }
    }
  }
}
