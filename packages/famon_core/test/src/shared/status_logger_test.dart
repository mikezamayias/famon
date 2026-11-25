import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StatusLogger', () {
    late MockLogger logger;
    late MockStdout stdout;

    setUp(() {
      logger = MockLogger();
      stdout = MockStdout();
      when(() => logger.level).thenReturn(Level.info);
    });

    test('writes status to stdout via info when stdout is a terminal', () {
      when(() => stdout.hasTerminal).thenReturn(true);

      runWithStdout(
        stdout,
        () => logger
          ..status('banner')
          ..statusDetail('detail'),
      );

      verify(() => logger.info('banner')).called(1);
      verify(() => logger.detail('detail')).called(1);
      verifyNever(
        () => logger.err(any(), style: any(named: 'style')),
      );
    });

    test('writes status unstyled to stderr when stdout is not a terminal', () {
      when(() => stdout.hasTerminal).thenReturn(false);

      runWithStdout(stdout, () => logger.status('banner'));

      final style = verify(
        () => logger.err('banner', style: captureAny(named: 'style')),
      ).captured.single as LogStyle;
      expect(style('banner'), 'banner');
      verifyNever(() => logger.info(any()));
    });

    test('statusSuccess uses success on a terminal and stderr when piped', () {
      when(() => stdout.hasTerminal).thenReturn(true);
      runWithStdout(stdout, () => logger.statusSuccess('saved'));
      when(() => stdout.hasTerminal).thenReturn(false);
      runWithStdout(stdout, () => logger.statusSuccess('copied'));

      verify(() => logger.success('saved')).called(1);
      verifyNever(() => logger.success('copied'));
      verify(() => logger.err('copied', style: any(named: 'style'))).called(1);
    });

    test('statusDetail on stderr appears only at verbose level', () {
      when(() => stdout.hasTerminal).thenReturn(false);

      runWithStdout(stdout, () => logger.statusDetail('hidden'));
      when(() => logger.level).thenReturn(Level.verbose);
      runWithStdout(stdout, () => logger.statusDetail('shown'));

      verifyNever(() => logger.err('hidden', style: any(named: 'style')));
      verify(() => logger.err('shown', style: any(named: 'style'))).called(1);
      verifyNever(() => logger.detail(any()));
    });
  });
}
