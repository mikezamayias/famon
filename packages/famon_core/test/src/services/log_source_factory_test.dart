import 'dart:io';

import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockStdout extends Mock implements Stdout {}

class _MockProcess extends Mock implements Process {}

/// Status output from a log source must keep a piped stdout free for event
/// lines (`famon monitor --enable-debug x | ...`).
void main() {
  late _MockLogger logger;
  late _MockStdout stdout;
  late _MockProcessManager processManager;
  late LogSourceFactory factory;

  setUp(() {
    logger = _MockLogger();
    when(() => logger.level).thenReturn(Level.verbose);
    stdout = _MockStdout();
    processManager = _MockProcessManager();
    final process = _MockProcess();
    when(() => process.exitCode).thenAnswer((_) async => 0);
    when(() => processManager.start(any())).thenAnswer((_) async => process);
    factory = LogSourceFactory(processManager, logger);
  });

  Future<void> enableDebugAndRaiseLevels() => IOOverrides.runZoned(
        () async {
          final source = await factory.create(PlatformType.iosSimulator);
          await source.enableAnalyticsDebug('com.example');
          await source.raiseLogLevels();
        },
        stdout: () => stdout,
      );

  test('writes status lines to stderr when stdout is piped', () async {
    when(() => stdout.hasTerminal).thenReturn(false);

    await enableDebugAndRaiseLevels();

    verify(
      () => logger.err(
        'iOS Analytics debug mode must be enabled in Xcode:',
        style: any(named: 'style'),
      ),
    ).called(1);
    verify(
      () => logger.err(
        'iOS log levels are controlled by the log stream predicate.',
        style: any(named: 'style'),
      ),
    ).called(1);
    verifyNever(() => logger.info(any()));
    verifyNever(() => logger.detail(any()));
  });

  for (final platform in [PlatformType.android, PlatformType.iosDevice]) {
    test('writes ${platform.name} detail lines to stderr when stdout is piped',
        () async {
      when(() => stdout.hasTerminal).thenReturn(false);

      await IOOverrides.runZoned(
        () async {
          final source = await factory.create(platform);
          await source.enableAnalyticsDebug('com.example.app');
          await source.raiseLogLevels();
        },
        stdout: () => stdout,
      );

      verify(() => logger.err(any(), style: any(named: 'style')))
          .called(greaterThan(0));
      verifyNever(() => logger.info(any()));
      verifyNever(() => logger.detail(any()));
    });
  }

  test('keeps status lines on stdout when it is a terminal', () async {
    when(() => stdout.hasTerminal).thenReturn(true);

    await enableDebugAndRaiseLevels();

    verify(
      () => logger.info('iOS Analytics debug mode must be enabled in Xcode:'),
    ).called(1);
    verify(
      () => logger.detail(
        'iOS log levels are controlled by the log stream predicate.',
      ),
    ).called(1);
    verifyNever(() => logger.err(any(), style: any(named: 'style')));
  });
}
