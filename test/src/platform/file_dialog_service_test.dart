import 'dart:io';

import 'package:famon/src/platform/file_dialog_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('promptForPath asks on stderr when stdout is piped', () async {
    final logger = _MockLogger();
    final stdin = MockStdin();
    final stdout = MockStdout();
    final stderr = MockStdout();
    when(() => stdout.hasTerminal).thenReturn(false);
    when(stdin.readLineSync).thenReturn('out.json');

    final path = await IOOverrides.runZoned(
      () => FileDialogService(logger: logger)
          .promptForPath(defaultFileName: 'events.json'),
      stdin: () => stdin,
      stdout: () => stdout,
      stderr: () => stderr,
    );

    expect(path, 'out.json');
    verify(() => stderr.write('Enter file path [events.json]: ')).called(1);
    verifyNever(() => logger.prompt(any()));
    verifyNever(() => stdout.write(any()));
  });

  test('promptForPath asks through the logger when stdout is a terminal',
      () async {
    final logger = _MockLogger();
    final stdin = MockStdin();
    final stdout = MockStdout();
    final stderr = MockStdout();
    when(() => stdout.hasTerminal).thenReturn(true);
    when(() => logger.prompt(any())).thenReturn('');
    when(stdin.readLineSync).thenReturn('out.json');

    final path = await IOOverrides.runZoned(
      () => FileDialogService(logger: logger)
          .promptForPath(defaultFileName: 'events.json'),
      stdin: () => stdin,
      stdout: () => stdout,
      stderr: () => stderr,
    );

    expect(path, 'out.json');
    verify(() => logger.prompt('Enter file path [events.json]: ')).called(1);
    verifyNever(() => stderr.write(any()));
  });
}
