import 'dart:io';

import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/shortcut_action.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';

/// Action to clear the terminal screen.
///
/// Clears the terminal output while continuing to monitor events.
/// Useful for cleaning up the display without stopping monitoring.
class ClearScreenAction implements ShortcutAction {
  /// Creates a new clear screen action.
  ClearScreenAction();

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
    stdout.write('\x1B[2J\x1B[H');

    context.logger.info('Monitoring Firebase Analytics events...');
    context.logger.info('Press ? for help, Q to quit');
    context.logger.info('');

    return true;
  }
}
