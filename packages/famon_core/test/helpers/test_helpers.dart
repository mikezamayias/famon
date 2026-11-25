import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';

/// Mock logger whose calls tests verify.
class MockLogger extends Mock implements Logger {}

/// Mock stdout for use with [IOOverrides].
class MockStdout extends Mock implements Stdout {}

/// Runs [body] with [stdout] as the global stdout, so code that checks
/// `stdout.hasTerminal` sees the mock's answer.
R runWithStdout<R>(Stdout stdout, R Function() body) =>
    IOOverrides.runZoned(body, stdout: () => stdout);
