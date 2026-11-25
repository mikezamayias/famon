import 'dart:async';
import 'dart:io';

import 'package:famon/src/platform/terminal.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';

void main() {
  group('stdinIsInteractive', () {
    test('is false when stdin is not a terminal (pipe)', () {
      final stdin = MockStdin();
      when(() => stdin.hasTerminal).thenReturn(false);

      expect(
        IOOverrides.runZoned(stdinIsInteractive, stdin: () => stdin),
        isFalse,
      );
    });

    test('is false for /dev/null, where hasTerminal is true', () {
      expect(
        IOOverrides.runZoned(stdinIsInteractive, stdin: devNullStdin),
        isFalse,
      );
    });

    test('is true for a terminal whose line mode can be read', () {
      final stdin = MockStdin();
      when(() => stdin.hasTerminal).thenReturn(true);
      when(() => stdin.lineMode).thenReturn(true);

      expect(
        IOOverrides.runZoned(stdinIsInteractive, stdin: () => stdin),
        isTrue,
      );
    });
  });

  group('isBrokenPipe', () {
    test('matches EPIPE only', () {
      expect(isBrokenPipe(brokenPipe), isTrue);
      expect(
        isBrokenPipe(
          const FileSystemException('x', '', OSError('No space', 28)),
        ),
        isFalse,
      );
      expect(isBrokenPipe(const FileSystemException('x')), isFalse);
      expect(isBrokenPipe(StateError('x')), isFalse);
    });
  });

  group('outputReaderGone', () {
    late MockStdout stdout;
    late MockStdout stderr;
    late Completer<void> stdoutDone;
    late Completer<void> stderrDone;

    setUp(() {
      stdoutDone = Completer<void>();
      stderrDone = Completer<void>();
      stdout = pipedStdout(() => stdoutDone.future);
      stderr = pipedStdout(() => stderrDone.future);
    });

    Future<void> watch() => IOOverrides.runZoned(
          outputReaderGone,
          stdout: () => stdout,
          stderr: () => stderr,
        );

    test('completes when stdout reports EPIPE', () async {
      final gone = watch();
      stdoutDone.completeError(brokenPipe);

      await expectLater(gone, completes);
    });

    test('completes when stderr reports EPIPE', () async {
      final gone = watch();
      stderrDone.completeError(brokenPipe);

      await expectLater(gone, completes);
    });

    test(
        'handles EPIPE that arrives before a command watches, and a later '
        'watch still completes', () async {
      // `main` arms the watch before anything is written. An unhandled
      // EPIPE here would fail the test as an uncaught error.
      unawaited(watch());
      stderrDone.completeError(brokenPipe);
      await pumpEventQueue();

      // The command watches only once startup is done.
      await expectLater(watch(), completes);
      verify(() => stderr.done).called(1);
    });

    for (final (name, done) in [
      ('stdout', () => stdoutDone),
      ('stderr', () => stderrDone),
    ]) {
      test('leaves any other $name error uncaught', () async {
        final uncaught = Completer<Object>();

        // The stream futures must belong to the guarded zone: errors do not
        // cross error-zone boundaries.
        runZonedGuarded(
          () {
            stdoutDone = Completer<void>();
            stderrDone = Completer<void>();
            unawaited(watch());
            done().completeError(const FileSystemException('disk full'));
          },
          (error, _) => uncaught.complete(error),
        );

        expect(await uncaught.future, isA<FileSystemException>());
      });
    }
  });
}
