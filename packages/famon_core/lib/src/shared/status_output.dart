import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

String? _unstyled(String? message) => message;

/// Status output that keeps stdout free for event lines when piped.
///
/// Internal to famon_core and not exported. It mirrors `StatusLogger` in the
/// famon CLI's `lib/src/platform/terminal.dart`, which cannot depend on a
/// famon_core API newer than the version its pubspec allows. Change both
/// together.
extension CoreStatusLogger on Logger {
  /// Writes a status line: to stdout as [Logger.info] when stdout is a
  /// terminal, and otherwise unstyled to stderr.
  void status(String? message) {
    if (stdout.hasTerminal) {
      info(message);
    } else {
      err(message, style: _unstyled);
    }
  }

  /// Like [status], for lines that [Logger.detail] would print, so they
  /// appear only at verbose level.
  void statusDetail(String? message) {
    if (stdout.hasTerminal) {
      detail(message);
    } else if (level.index <= Level.debug.index) {
      err(message, style: _unstyled);
    }
  }
}
