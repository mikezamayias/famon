import 'dart:async';
import 'dart:io';

import 'package:famon/src/platform/terminal.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';

class _MockLogger extends Mock implements Logger {}

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
      stdout = MockStdout();
      stderr = MockStdout();
      stdoutDone = Completer<void>();
      stderrDone = Completer<void>();
      when(() => stdout.done).thenAnswer((_) => stdoutDone.future);
      when(() => stderr.done).thenAnswer((_) => stderrDone.future);
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

  group('StatusLogger', () {
    late _MockLogger logger;
    late MockStdout stdout;

    setUp(() {
      logger = _MockLogger();
      stdout = MockStdout();
      when(() => logger.level).thenReturn(Level.info);
    });

    test('writes status to stdout via info when stdout is a terminal', () {
      when(() => stdout.hasTerminal).thenReturn(true);

      IOOverrides.runZoned(
        () => logger
          ..status('banner')
          ..statusDetail('detail'),
        stdout: () => stdout,
      );

      verify(() => logger.info('banner')).called(1);
      verify(() => logger.detail('detail')).called(1);
      verifyNever(
        () => logger.err(any(), style: any(named: 'style')),
      );
    });

    test('writes status unstyled to stderr when stdout is not a terminal', () {
      when(() => stdout.hasTerminal).thenReturn(false);

      IOOverrides.runZoned(
        () => logger.status('banner'),
        stdout: () => stdout,
      );

      final style = verify(
        () => logger.err('banner', style: captureAny(named: 'style')),
      ).captured.single as LogStyle;
      expect(style('banner'), 'banner');
      verifyNever(() => logger.info(any()));
    });

    test('statusSuccess uses success on a terminal and stderr when piped', () {
      when(() => stdout.hasTerminal).thenReturn(true);
      IOOverrides.runZoned(
        () => logger.statusSuccess('saved'),
        stdout: () => stdout,
      );
      when(() => stdout.hasTerminal).thenReturn(false);
      IOOverrides.runZoned(
        () => logger.statusSuccess('copied'),
        stdout: () => stdout,
      );

      verify(() => logger.success('saved')).called(1);
      verifyNever(() => logger.success('copied'));
      verify(() => logger.err('copied', style: any(named: 'style'))).called(1);
    });

    test('statusDetail on stderr appears only at verbose level', () {
      when(() => stdout.hasTerminal).thenReturn(false);

      IOOverrides.runZoned(
        () => logger.statusDetail('hidden'),
        stdout: () => stdout,
      );
      when(() => logger.level).thenReturn(Level.verbose);
      IOOverrides.runZoned(
        () => logger.statusDetail('shown'),
        stdout: () => stdout,
      );

      verifyNever(() => logger.err('hidden', style: any(named: 'style')));
      verify(() => logger.err('shown', style: any(named: 'style'))).called(1);
      verifyNever(() => logger.detail(any()));
    });
  });
}
