import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

/// Mock stdin for use with [IOOverrides].
class MockStdin extends Mock implements Stdin {}

/// Mock stdout or stderr for use with [IOOverrides].
class MockStdout extends Mock implements Stdout {}

/// The error stdout reports when the reader of its pipe has gone away.
const brokenPipe = FileSystemException(
  'writeFrom failed',
  '',
  OSError('Broken pipe', 32),
);

final class _StdioOverrides extends IOOverrides {
  _StdioOverrides(this._stdout, this._stderr);

  final Stdout _stdout;
  final Stdout _stderr;

  @override
  Stdout get stdout => _stdout;

  @override
  Stdout get stderr => _stderr;
}

/// Replaces the global stdout and stderr with mocks until the current test
/// ends, so code that checks `hasTerminal` behaves the same however
/// `dart test` itself is run. Call it from `setUp` or a test body; a later
/// call wins.
({MockStdout stdout, MockStdout stderr}) fakeStdio({
  required bool stdoutIsTerminal,
  bool stderrIsTerminal = false,
}) {
  final stdout = MockStdout();
  final stderr = MockStdout();
  when(() => stdout.hasTerminal).thenReturn(stdoutIsTerminal);
  when(() => stderr.hasTerminal).thenReturn(stderrIsTerminal);
  when(() => stdout.supportsAnsiEscapes).thenReturn(stdoutIsTerminal);
  when(() => stderr.supportsAnsiEscapes).thenReturn(stderrIsTerminal);
  final previous = IOOverrides.current;
  IOOverrides.global = _StdioOverrides(stdout, stderr);
  addTearDown(() => IOOverrides.global = previous);
  return (stdout: stdout, stderr: stderr);
}

/// A stdin like `</dev/null`: `hasTerminal` is true because it is a
/// character device, but reading the terminal mode throws.
MockStdin devNullStdin() {
  final stdin = MockStdin();
  when(() => stdin.hasTerminal).thenReturn(true);
  when(() => stdin.lineMode).thenThrow(
    const StdinException(
      'Error getting terminal line mode',
      OSError('Operation not supported by device', 19),
    ),
  );
  return stdin;
}
