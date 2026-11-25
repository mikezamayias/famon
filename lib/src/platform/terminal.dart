import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

/// POSIX `EPIPE`, the same value on macOS and Linux.
const _ePipe = 32;

/// Whether stdin is an interactive terminal that supports raw mode.
///
/// `stdin.hasTerminal` alone is not enough: it is true for `/dev/null`,
/// which is a character device, but reading `lineMode` there throws a
/// [StdinException]. This probe is the single answer every keyboard caller
/// uses. It reads the global [stdin], so tests can swap it with
/// [IOOverrides].
bool stdinIsInteractive() {
  if (!stdin.hasTerminal) return false;
  try {
    stdin.lineMode;
    return true;
  } on StdinException {
    return false;
  }
}

/// Whether [error] means the reader of a pipe went away (`EPIPE`).
bool isBrokenPipe(Object error) =>
    error is FileSystemException && error.osError?.errorCode == _ePipe;

/// Completes when the reader of stdout closes its end of the pipe.
///
/// Without a listener, the `EPIPE` that [stdout] reports through
/// [IOSink.done] is an unhandled error that crashes the process. This
/// handles it and lets the caller shut down through its normal cleanup.
/// Any other stdout error is rethrown, so it stays an uncaught error as
/// before. After `EPIPE`, [stdout] drops further writes without raising.
Future<void> stdoutReaderGone() {
  final gone = Completer<void>();
  unawaited(
    stdout.done.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (!isBrokenPipe(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        gone.complete();
      },
    ),
  );
  return gone.future;
}

String? _unstyled(String? message) => message;

/// Status output that keeps stdout free for event lines when piped.
extension StatusLogger on Logger {
  /// Writes a status line: to stdout as [Logger.info] when stdout is a
  /// terminal, and otherwise unstyled to stderr, so that a pipe or file on
  /// stdout receives only event lines.
  void status(String? message) {
    if (stdout.hasTerminal) {
      info(message);
    } else {
      err(message, style: _unstyled);
    }
  }

  /// Like [status], for lines that [Logger.detail] would print, so they
  /// appear only at verbose level.
  void statusDetail(String? message) {
    if (stdout.hasTerminal) {
      detail(message);
    } else if (level.index <= Level.debug.index) {
      err(message, style: _unstyled);
    }
  }
}
