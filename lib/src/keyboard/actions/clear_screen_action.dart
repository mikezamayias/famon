import 'dart:io';

import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:famon/src/platform/terminal.dart';

/// Action to clear the terminal screen.
///
/// Clears the terminal output while continuing to monitor events.
/// Useful for cleaning up the display without stopping monitoring.
class ClearScreenAction implements ShortcutAction {
  /// Creates a new clear screen action.
  ClearScreenAction();

  static const _clearSequence = '\x1B[2J\x1B[H';

  @override
  String get id => 'clear_screen';

  @override
  String get displayName => 'Clear Screen';

  @override
  String get description => 'Clear terminal output';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'l', ctrl: true);

  @override
  Future<bool> execute(ActionContext context) async {
    // Use ANSI escape codes to clear screen and move cursor to top
    // ESC[2J clears the screen
    // ESC[H moves cursor to home position (top-left)
    // The sequence goes only to a terminal: to stdout when it is one, else
    // to stderr when that is the terminal the user is looking at, so a pipe
    // or file on stdout never receives it.
    if (stdout.hasTerminal) {
      stdout.write(_clearSequence);
    } else if (stderr.hasTerminal) {
      stderr.write(_clearSequence);
    }

    context.logger.status('Monitoring Firebase Analytics events...');
    context.logger.status('Press ? for help, Q to quit');
    context.logger.status('');

    return true;
  }
}
