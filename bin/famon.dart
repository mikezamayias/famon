import 'dart:async';
import 'dart:io';

import 'package:famon/src/command_runner.dart';
import 'package:famon/src/injection.dart';
import 'package:famon/src/platform/terminal.dart';

Future<void> main(List<String> args) async {
  // Handle a closed pipe on stdout or stderr from the first byte written,
  // before any command starts its own watch.
  unawaited(outputReaderGone());

  // Initialize dependency injection
  await configureDependencies();

  await _flushThenExit(await FamonCommandRunner().run(args));
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from continuing
/// after the program has been killed.
///
/// A closed pipe on either stream (`famon monitor | head`) is not an error
/// here: the reader already has what it wanted.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([
    stdout.close().catchError((_) {}, test: isBrokenPipe),
    stderr.close().catchError((_) {}, test: isBrokenPipe),
  ]).then<void>((_) => exit(status));
}
