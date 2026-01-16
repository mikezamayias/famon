import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/shortcut_action.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';

/// Callback type for quit request handling.
typedef QuitCallback = void Function();

/// Action to gracefully quit the monitoring session.
///
/// Triggers a cleanup and shutdown of the monitoring process.
class QuitAction implements ShortcutAction {
  /// Creates a new quit action.
  ///
  /// [onQuit] - Callback invoked when quit is requested.
  QuitAction({required QuitCallback onQuit}) : _onQuit = onQuit;

  final QuitCallback _onQuit;

  @override
  String get id => 'quit';

  @override
  String get displayName => 'Quit';

  @override
  String get description => 'Quit monitoring';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'q');

  @override
  Future<bool> execute(ActionContext context) async {
    context.logger.info('');
    context.logger.info('Stopping monitoring...');
    _onQuit();
    return true;
  }
}
