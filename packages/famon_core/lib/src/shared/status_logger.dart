import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

String? _unstyled(String? message) => message;

/// Status output that keeps stdout free for event lines when piped.
extension StatusLogger on Logger {
  /// Writes a status line: to stdout as [Logger.info] when stdout is a
  /// terminal, and otherwise unstyled to stderr, so that a pipe or file on
  /// stdout receives only event lines.
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

  /// Like [status], for lines that [Logger.success] would print.
  void statusSuccess(String? message) {
    if (stdout.hasTerminal) {
      success(message);
    } else {
      err(message, style: _unstyled);
    }
  }
}
