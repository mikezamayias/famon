import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';

/// Callback type for toggling event parameters visibility.
typedef EventParamsToggleCallback = void Function({
  required bool hideEventParams,
});

/// Action to toggle visibility of event-specific parameters.
///
/// When event parameters are hidden, only global/default parameters are
/// displayed.  This is useful when debugging default parameter propagation
/// without the noise of event-specific data.
class ToggleEventParamsAction implements ShortcutAction {
  /// Creates a new toggle event params action.
  ///
  /// [onToggle] - Callback invoked with the new visibility state.
  ToggleEventParamsAction({required EventParamsToggleCallback onToggle})
      : _onToggle = onToggle;

  final EventParamsToggleCallback _onToggle;

  @override
  String get id => 'toggle_event_params';

  @override
  String get displayName => 'Toggle Event Params';

  @override
  String get description => 'Show/hide event-specific parameters';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'e');

  @override
  Future<bool> execute(ActionContext context) async {
    final newState = !context.hideEventParams;
    _onToggle(hideEventParams: newState);

    if (newState) {
      context.logger.info('Event parameters hidden');
    } else {
      context.logger.info('Event parameters visible');
    }

    return true;
  }
}
