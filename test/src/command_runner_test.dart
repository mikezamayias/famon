import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:firebase_analytics_monitor/src/command_runner.dart';
import 'package:firebase_analytics_monitor/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

class _MockProgress extends Mock implements Progress {}

class _MockProcessManager extends Mock implements ProcessManager {}

const latestVersion = '0.0.0';

final updatePrompt =
    // We need to ignore this lint in order to match the exact message format.
    // ignore: leading_newlines_in_multiline_strings
    '''${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''';

void main() {
  group('FirebaseAnalyticsMonitorCommandRunner', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late FirebaseAnalyticsMonitorCommandRunner commandRunner;

    setUp(() async {
      pubUpdater = MockPubUpdater();
      logger = MockLogger();

      await setUpTestDependencies(logger: logger, pubUpdater: pubUpdater);

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = FirebaseAnalyticsMonitorCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
      );
    });

    tearDown(() async {
      await tearDownTestDependencies();
    });

    test('shows update message when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info(updatePrompt)).called(1);
    });

    test('shows error message when failed to check for updates', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('Failed to check for updates'));

      await commandRunner.run(['--version']);
      verify(() => logger.err('Failed to check for updates.')).called(1);
    });

    test(
        'Does not show update message when the shell calls the '
        'completion command', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      final result = await commandRunner.run(['completion']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(updatePrompt));
    });

    test('does not show update message when using update command', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);
      when(
        () => pubUpdater.update(
          packageName: packageName,
          versionConstraint: any(named: 'versionConstraint'),
        ),
      ).thenAnswer(
        (_) async => ProcessResult(0, ExitCode.success.code, null, null),
      );
      when(
        () => pubUpdater.isUpToDate(
          packageName: any(named: 'packageName'),
          currentVersion: any(named: 'currentVersion'),
        ),
      ).thenAnswer((_) async => true);

      final progress = _MockProgress();
      final progressLogs = <String>[];
      when(() => progress.complete(any())).thenAnswer((answer) {
        final message = answer.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await commandRunner.run(['update']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(updatePrompt));
    });

    test(
      'can be instantiated without an explicit analytics/logger instance',
      () async {
        // For tests without explicit logger, we still need DI set up
        final testCommandRunner = FirebaseAnalyticsMonitorCommandRunner();
        expect(testCommandRunner, isNotNull);
        expect(testCommandRunner, isA<CompletionCommandRunner<int>>());
      },
    );

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info(commandRunner.usage)).called(1);
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    group('--version', () {
      test('outputs current version', () async {
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(packageVersion)).called(1);
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await commandRunner.run(['--verbose']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verifyNever(() => logger.detail('    Command options:'));
      });

      test('enables verbose logging for sub commands', () async {
        // Need to set up mock process manager for commands that use it
        final mockProcessManager = _MockProcessManager();
        when(() => mockProcessManager.start(any())).thenThrow(
          const ProcessException('adb', [], 'adb: not found'),
        );

        await tearDownTestDependencies();
        await setUpTestDependencies(
          logger: logger,
          pubUpdater: pubUpdater,
          processManager: mockProcessManager,
        );

        final verboseCommandRunner = FirebaseAnalyticsMonitorCommandRunner(
          logger: logger,
          pubUpdater: pubUpdater,
        );

        final result = await verboseCommandRunner.run([
          '--verbose',
          'monitor',
          '--no-color',
        ]);
        // Exit code will be 1 because adb "not found"
        expect(result, equals(1));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verify(() => logger.detail('  Command: monitor')).called(1);
        verify(() => logger.detail('    Command options:')).called(1);
        verify(() => logger.detail('    - no-color: true')).called(1);
      });
    });
  });
}
