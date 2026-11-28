import 'dart:io';

import 'package:famon/src/platform/file_dialog_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';
import '../../helpers/test_helpers.dart' show MockLogger;

void main() {
  group('promptForPath', () {
    late MockLogger logger;
    late MockStdout stdout;
    late MockStdout stderr;

    setUp(() {
      logger = MockLogger();
      stdout = MockStdout();
      stderr = MockStdout();
      when(() => logger.prompt(any())).thenReturn('');
    });

    /// Prompts with stdout on a terminal or not, and answers `out.json`.
    Future<String?> prompt({required bool stdoutIsTerminal}) {
      final stdin = MockStdin();
      when(() => stdout.hasTerminal).thenReturn(stdoutIsTerminal);
      when(stdin.readLineSync).thenReturn('out.json');
      return IOOverrides.runZoned(
        () => FileDialogService(logger: logger)
            .promptForPath(defaultFileName: 'events.json'),
        stdin: () => stdin,
        stdout: () => stdout,
        stderr: () => stderr,
      );
    }

    test('asks on stderr when stdout is piped', () async {
      expect(await prompt(stdoutIsTerminal: false), 'out.json');

      verify(() => stderr.write('Enter file path [events.json]: ')).called(1);
      verifyNever(() => logger.prompt(any()));
      verifyNever(() => stdout.write(any()));
    });

    test('asks through the logger when stdout is a terminal', () async {
      expect(await prompt(stdoutIsTerminal: true), 'out.json');

      verify(() => logger.prompt('Enter file path [events.json]: ')).called(1);
      verifyNever(() => stderr.write(any()));
    });
  });
}
