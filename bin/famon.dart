import 'dart:io';

import 'package:famon/src/command_runner.dart';
import 'package:famon/src/injection.dart';

Future<void> main(List<String> args) async {
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
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
