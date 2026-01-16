import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/shortcut_action.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';

/// Callback type for toggling pause state.
typedef PauseToggleCallback = void Function({required bool isPaused});

/// Action to toggle pause/resume of event display.
///
/// When paused, events are still captured but not displayed. This allows
/// the user to pause the output to read events without losing new data.
class TogglePauseAction implements ShortcutAction {
  /// Creates a new toggle pause action.
  ///
  /// [onToggle] - Callback invoked with the new pause state.
  TogglePauseAction({required PauseToggleCallback onToggle})
      : _onToggle = onToggle;

  final PauseToggleCallback _onToggle;

  @override
  String get id => 'toggle_pause';

  @override
  String get displayName => 'Toggle Pause';

  @override
  String get description => 'Pause/resume event display';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'p');

  @override
  Future<bool> execute(ActionContext context) async {
    final newPausedState = !context.isPaused;
    _onToggle(isPaused: newPausedState);

    if (newPausedState) {
      context.logger.info('Event display paused (events still captured)');
    } else {
      context.logger.info('Event display resumed');
    }

    return true;
  }
}
