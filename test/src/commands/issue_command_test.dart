import 'dart:io';

import 'package:famon/src/commands/issue_command.dart';
import 'package:famon/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockProcessManager processManager;
  late MockClipboardService clipboard;
  late IssueCommand command;

  setUp(() {
    logger = MockLogger();
    processManager = MockProcessManager();
    clipboard = MockClipboardService();

    command = IssueCommand(
      logger: logger,
      processManager: processManager,
      clipboard: clipboard,
    );

    // Default stubs for dart --version
    when(() => processManager.run(['dart', '--version'])).thenAnswer(
      (_) async => ProcessResult(0, 0, 'Dart SDK version: 3.11.0', ''),
    );
  });

  group('IssueCommand metadata', () {
    test('has correct name', () {
      expect(command.name, equals('issue'));
    });

    test('has correct description', () {
      expect(command.description, contains('Report an issue'));
    });
  });

  group('_generateIssueBody via clipboard', () {
    setUp(() {
      when(() => clipboard.isSupported).thenReturn(true);
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
        ),
      ).thenReturn('Copy bug report template to clipboard');
    });

    test('includes prompt sections when includePrompts is true', () async {
      String? capturedBody;
      when(() => clipboard.copy(any())).thenAnswer((invocation) async {
        capturedBody = invocation.positionalArguments[0] as String;
        return true;
      });

      await command.run();

      expect(capturedBody, isNotNull);
      expect(capturedBody, contains('## Describe the bug'));
      expect(capturedBody, contains('## Steps to reproduce'));
      expect(capturedBody, contains('## Expected behavior'));
      expect(capturedBody, contains('## Actual behavior'));
      expect(capturedBody, contains('## Additional context'));
    });

    test('includes environment info table', () async {
      String? capturedBody;
      when(() => clipboard.copy(any())).thenAnswer((invocation) async {
        capturedBody = invocation.positionalArguments[0] as String;
        return true;
      });

      await command.run();

      expect(capturedBody, isNotNull);
      expect(capturedBody, contains('## Environment'));
      expect(capturedBody, contains('| Property | Value |'));
      expect(capturedBody, contains('|----------|-------|'));
      expect(capturedBody, contains('| famon version | $packageVersion |'));
      expect(
        capturedBody,
        contains('| OS | ${Platform.operatingSystem} |'),
      );
      expect(capturedBody, contains('| Dart version |'));
      expect(capturedBody, contains('| Timestamp |'));
    });

    test('returns success code on successful copy', () async {
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.success.code));
    });

    test('falls back to printing body when copy fails', () async {
      when(() => clipboard.copy(any())).thenAnswer((_) async => false);

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.software.code));
      verify(() => logger.err('Failed to copy to clipboard.')).called(1);
    });

    test('returns unavailable when clipboard not supported', () async {
      when(() => clipboard.isSupported).thenReturn(false);

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.unavailable.code));
    });
  });

  group('_generateIssueBody via gh CLI', () {
    setUp(() {
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
        ),
      ).thenReturn('Use GitHub CLI (gh) to create issue');
    });

    test('includes userDescription but no prompt sections', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => processManager.run(['gh', 'auth', 'status'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => logger.prompt('Issue title:')).thenReturn('Test bug');
      when(() => logger.prompt('Description (optional):'))
          .thenReturn('Something broke');
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => logger.progress(any())).thenReturn(_FakeProgress());

      String? capturedBody;
      when(
        () => processManager.run(any()),
      ).thenAnswer((invocation) async {
        final args = invocation.positionalArguments[0] as List<dynamic>;
        if (args.length > 1 && args[0] == 'gh' && args[1] == 'issue') {
          capturedBody = args[args.indexOf('--body') + 1] as String;
          return ProcessResult(
            0,
            0,
            'https://github.com/mikezamayias/famon/issues/99',
            '',
          );
        }
        return ProcessResult(0, 0, '', '');
      });

      await command.run();

      expect(capturedBody, isNotNull);
      expect(capturedBody, contains('Something broke'));
      expect(capturedBody, isNot(contains('## Describe the bug')));
      expect(capturedBody, isNot(contains('## Steps to reproduce')));
      expect(capturedBody, contains('## Environment'));
      expect(capturedBody, contains('| famon version |'));
    });

    test('body without userDescription has no description section', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => processManager.run(['gh', 'auth', 'status'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => logger.prompt('Issue title:')).thenReturn('Test bug');
      when(() => logger.prompt('Description (optional):')).thenReturn('');
      when(() => logger.confirm(any())).thenReturn(true);
      when(() => logger.progress(any())).thenReturn(_FakeProgress());

      String? capturedBody;
      when(
        () => processManager.run(any()),
      ).thenAnswer((invocation) async {
        final args = invocation.positionalArguments[0] as List<dynamic>;
        if (args.length > 1 && args[0] == 'gh' && args[1] == 'issue') {
          capturedBody = args[args.indexOf('--body') + 1] as String;
          return ProcessResult(
            0,
            0,
            'https://github.com/mikezamayias/famon/issues/100',
            '',
          );
        }
        return ProcessResult(0, 0, '', '');
      });

      await command.run();

      expect(capturedBody, isNotNull);
      expect(capturedBody!.trimLeft(), startsWith('## Environment'));
    });

    test('fails when gh is not installed', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 1, '', ''),
      );

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.software.code));
      verify(() => logger.err('GitHub CLI (gh) is not installed.')).called(1);
    });

    test('fails when gh is not authenticated', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => processManager.run(['gh', 'auth', 'status'])).thenAnswer(
        (_) async => ProcessResult(0, 1, '', ''),
      );

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.software.code));
      verify(() => logger.err('GitHub CLI is not authenticated.')).called(1);
    });

    test('returns usage code when title is empty', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => processManager.run(['gh', 'auth', 'status'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => logger.prompt('Issue title:')).thenReturn('');

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('cancellation returns success', () async {
      when(() => processManager.run(['gh', '--version'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => processManager.run(['gh', 'auth', 'status'])).thenAnswer(
        (_) async => ProcessResult(0, 0, '', ''),
      );
      when(() => logger.prompt('Issue title:')).thenReturn('A bug');
      when(() => logger.prompt('Description (optional):')).thenReturn('');
      when(() => logger.confirm(any())).thenReturn(false);

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.success.code));
      verify(() => logger.info('Cancelled.')).called(1);
    });
  });

  group('environment info table formatting', () {
    test('table has correct markdown structure', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
        ),
      ).thenReturn('Copy bug report template to clipboard');

      String? capturedBody;
      when(() => clipboard.copy(any())).thenAnswer((invocation) async {
        capturedBody = invocation.positionalArguments[0] as String;
        return true;
      });

      await command.run();

      final lines = capturedBody!.split('\n');
      final tableStart = lines.indexOf('| Property | Value |');
      expect(tableStart, isNot(-1), reason: 'Table header should exist');

      // Verify separator row
      expect(lines[tableStart + 1], equals('|----------|-------|'));

      // Verify all expected rows exist
      final tableLines =
          lines.skip(tableStart + 2).takeWhile((l) => l.startsWith('|'));
      final rowKeys = tableLines.map((l) => l.split('|')[1].trim()).toList();
      expect(rowKeys, contains('famon version'));
      expect(rowKeys, contains('OS'));
      expect(rowKeys, contains('OS Version'));
      expect(rowKeys, contains('Dart version'));
      expect(rowKeys, contains('Timestamp'));
    });

    test('OS version matches current platform', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
        ),
      ).thenReturn('Copy bug report template to clipboard');

      String? capturedBody;
      when(() => clipboard.copy(any())).thenAnswer((invocation) async {
        capturedBody = invocation.positionalArguments[0] as String;
        return true;
      });

      await command.run();

      expect(
        capturedBody,
        contains('| OS Version | ${Platform.operatingSystemVersion} |'),
      );
    });
  });

  group('view system info', () {
    test('displays all collected info and returns success', () async {
      when(
        () => logger.chooseOne<String>(
          any(),
          choices: any(named: 'choices'),
        ),
      ).thenReturn('View system info only');

      final exitCode = await command.run();

      expect(exitCode, equals(ExitCode.success.code));
      verify(() => logger.info(any(that: contains('famon_version')))).called(1);
    });
  });
}

class _FakeProgress implements Progress {
  @override
  void cancel() {}

  @override
  void complete([String? message]) {}

  @override
  void fail([String? message]) {}

  @override
  void update(String message) {}
}
