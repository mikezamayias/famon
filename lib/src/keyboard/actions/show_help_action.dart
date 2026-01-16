import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/action_registry.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/shortcut_action.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';
import 'package:mason_logger/mason_logger.dart';

/// Callback type for getting the current binding for an action.
typedef GetBindingCallback = KeyBinding Function(String actionId);

/// Action to display keyboard shortcuts help.
///
/// Shows a help overlay with all available keyboard shortcuts and their
/// descriptions.
class ShowHelpAction implements ShortcutAction {
  /// Creates a new show help action.
  ///
  /// [registry] - The action registry containing all available actions.
  /// [getBinding] - Callback to get the current binding for each action.
  ShowHelpAction({
    required ActionRegistry registry,
    required GetBindingCallback getBinding,
  })  : _registry = registry,
        _getBinding = getBinding;

  final ActionRegistry _registry;
  final GetBindingCallback _getBinding;

  @override
  String get id => 'show_help';

  @override
  String get displayName => 'Show Help';

  @override
  String get description => 'Display keyboard shortcuts';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: '?');

  @override
  Future<bool> execute(ActionContext context) async {
    final logger = context.logger;

    final separator = darkGray.wrap('═' * 45);

    logger
      ..info('')
      ..info(lightCyan.wrap('Keyboard Shortcuts'))
      ..info(separator)
      ..info('');

    for (final action in _registry.allActions) {
      final binding = _getBinding(action.id);
      final shortcut = binding.toDisplayString().padRight(15);
      logger.info('  $shortcut ${action.description}');
    }

    logger
      ..info('')
      ..info(separator)
      ..info('');

    return true;
  }
}
