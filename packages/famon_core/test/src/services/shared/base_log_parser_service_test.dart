import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

class _FailingAndroidParser extends LogParserService {
  _FailingAndroidParser({super.logger});

  @override
  String normalizeParamsString(String paramsString) =>
      throw const FormatException('broken params');
}

class _FailingIosParser extends IosLogParserService {
  _FailingIosParser({super.logger});

  @override
  String normalizeParamsString(String paramsString) =>
      throw const FormatException('broken params');
}

void main() {
  late MockLogger logger;
  late MockStdout stdout;

  setUp(() {
    logger = MockLogger();
    when(() => logger.level).thenReturn(Level.verbose);
    stdout = MockStdout();
  });

  for (final (platform, create) in [
    ('Android', (Logger l) => _FailingAndroidParser(logger: l)),
    ('iOS', (Logger l) => _FailingIosParser(logger: l)),
  ]) {
    group('$platform parse failure details', () {
      void parseBrokenParams() =>
          runWithStdout(stdout, () => create(logger).parseParams('key=value'));

      test('go to stderr when stdout is piped', () {
        when(() => stdout.hasTerminal).thenReturn(false);

        parseBrokenParams();

        verify(() => logger.warn(any())).called(1);
        verify(
          () => logger.err('Input: key=value', style: any(named: 'style')),
        ).called(1);
        verifyNever(() => logger.detail(any()));
      });

      test('stay verbose detail lines when stdout is a terminal', () {
        when(() => stdout.hasTerminal).thenReturn(true);

        parseBrokenParams();

        verify(() => logger.detail('Input: key=value')).called(1);
        verifyNever(() => logger.err(any(), style: any(named: 'style')));
      });
    });
  }
}
