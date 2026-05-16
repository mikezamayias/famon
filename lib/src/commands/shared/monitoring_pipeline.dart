import 'dart:async';
import 'dart:convert';

import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';

/// Result callback signature.
///
/// Return `true` to keep consuming the stream, `false` to stop and exit
/// [MonitoringPipeline.run] early (e.g. when an `--limit` is hit).
typedef MonitoringPipelineCallback = FutureOr<bool> Function(
  LogEventProcessResult result,
);

/// CLI-side stream pipeline that consumes a raw log process and emits
/// structured [LogEventProcessResult] values to a host callback.
///
/// The pipeline owns the bits of monitor-loop behavior that were
/// previously duplicated between `MonitorCommand` and
/// `FilteredMonitorCommand`:
///
/// - stderr draining (prevents the child process from blocking on
///   stderr buffer overflow);
/// - UTF-8 line decoding with malformed byte tracking and rate-limited
///   warnings;
/// - delegation to [LogEventProcessor] for parse + filter decisions;
/// - verbose-mode raw line emission for Firebase Analytics /
///   Crashlytics chatter, matching the historical `MonitorCommand`
///   behavior where verbose surfaces both parsed events and the raw
///   log line they came from.
///
/// CLI-only concerns — process startup, signal handlers, option
/// parsing, keyboard shortcuts, clipboard/file dialogs, terminal
/// rendering, and cache updates — stay in the calling command.
class MonitoringPipeline {
  /// Creates a pipeline backed by [processor] for parse + filter and
  /// [logger] for malformed-byte warnings.
  const MonitoringPipeline({
    required this.processor,
    required this.logger,
  });

  /// Parse + filter primitive supplied by `famon_core`.
  final LogEventProcessor processor;

  /// Logger used for malformed-UTF-8 warnings; **not** used for event
  /// or verbose-line output — those go through the `onResult` callback
  /// passed to [run].
  final Logger logger;

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
  /// The pipeline intentionally does **not** apply hide / show-only
  /// filtering: callers do that themselves so they can decide whether
  /// filtered events still update caches, stats, or persistence
  /// (`MonitorCommand` caches filtered events for export; the
  /// frequency-aware `FilteredMonitorCommand` runs its DB query before
  /// the basic filter).
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
          logger.warn(
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
