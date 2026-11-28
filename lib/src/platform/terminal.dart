import 'dart:async';
import 'dart:io';

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

/// One watch per stream, so the first caller arms it and later callers share
/// it. Keyed by the stream object, so [IOOverrides] fakes get their own.
final _readerGone = Expando<Future<void>>();

/// Completes when the reader of stdout or of stderr closes its end of the
/// pipe.
///
/// Without a listener, the `EPIPE` that a stream reports through
/// [IOSink.done] is an unhandled error that crashes the process, whichever
/// write hit it. `main` calls this before anything is written, so `EPIPE`
/// is handled from the first byte, and a command calls it again to shut
/// down through its normal cleanup. Any other error on either stream is
/// rethrown once, so it stays an uncaught error as before. After `EPIPE`
/// the stream drops further writes without raising, so nothing tries to
/// report the closed pipe by writing to it.
Future<void> outputReaderGone() => Future.any([_watch(stdout), _watch(stderr)]);

Future<void> _watch(Stdout sink) => _readerGone[sink] ??= () {
      final gone = Completer<void>();
      unawaited(
        sink.done.then<void>(
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
    }();
