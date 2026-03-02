import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';

/// Callback type for toggling global parameters visibility.
typedef GlobalParamsToggleCallback =
    void Function({required bool hideGlobalParams});

/// Action to toggle visibility of global/default parameters.
///
/// When global parameters are hidden, only event-specific parameters are
/// displayed.  This reduces noise when the same default parameters
/// (set via Firebase's `setDefaultEventParameters`) appear on every event.
class ToggleGlobalParamsAction implements ShortcutAction {
  /// Creates a new toggle global params action.
  ///
  /// [onToggle] - Callback invoked with the new visibility state.
  ToggleGlobalParamsAction({required GlobalParamsToggleCallback onToggle})
    : _onToggle = onToggle;

  final GlobalParamsToggleCallback _onToggle;

  @override
  String get id => 'toggle_global_params';

  @override
  String get displayName => 'Toggle Global Params';

  @override
  String get description => 'Show/hide global (default) parameters';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'g');

  @override
  Future<bool> execute(ActionContext context) async {
    final newState = !context.hideGlobalParams;
    _onToggle(hideGlobalParams: newState);

    if (newState) {
      context.logger.info('Global parameters hidden');
    } else {
      context.logger.info('Global parameters visible');
    }

    return true;
  }
}
