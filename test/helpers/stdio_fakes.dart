import 'dart:io';

import 'package:mocktail/mocktail.dart';

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
