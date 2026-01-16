import 'package:firebase_analytics_monitor/src/config/default_shortcuts.dart';
import 'package:firebase_analytics_monitor/src/config/shortcuts_config_loader.dart';
import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/action_registry.dart';
import 'package:firebase_analytics_monitor/src/keyboard/actions/shortcut_action.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';
import 'package:firebase_analytics_monitor/src/keyboard/keyboard_input_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// Manager for keyboard shortcuts.
///
/// Coordinates shortcut bindings, handles key events, and dispatches to
/// appropriate actions. Supports custom user bindings loaded from config.
@injectable
class ShortcutManager {
  /// Creates a new shortcut manager.
  ShortcutManager({
    required ActionRegistry actionRegistry,
    required ShortcutsConfigLoader configLoader,
    required Logger logger,
  })  : _registry = actionRegistry,
        _configLoader = configLoader,
        _logger = logger;

  final ActionRegistry _registry;
  final ShortcutsConfigLoader _configLoader;
  final Logger _logger;

  /// Custom bindings loaded from config file.
  final Map<String, KeyBinding> _customBindings = {};

  /// Whether custom bindings have been loaded.
  bool _bindingsLoaded = false;

  /// Get the current binding for an action.
  ///
  /// Returns custom binding if set, otherwise the action's default binding.
  KeyBinding getBinding(String actionId) {
    // Check custom bindings first
    if (_customBindings.containsKey(actionId)) {
      return _customBindings[actionId]!;
    }

    // Check default shortcuts
    final defaultBinding = DefaultShortcuts.getDefault(actionId);
    if (defaultBinding != null) {
      return defaultBinding;
    }

    // Fall back to action's own default
    final action = _registry.getAction(actionId);
    return action?.defaultBinding ?? const KeyBinding(key: '');
  }

  /// Get all current bindings.
  Map<String, KeyBinding> get bindings {
    final result = <String, KeyBinding>{};
    for (final action in _registry.allActions) {
      result[action.id] = getBinding(action.id);
    }
    return result;
  }

  /// Load custom bindings from the config file.
  Future<void> loadCustomBindings() async {
    if (_bindingsLoaded) return;

    try {
      final custom = await _configLoader.loadCustomBindings();
      _customBindings.addAll(custom);
      _bindingsLoaded = true;

      if (custom.isNotEmpty) {
        _logger.detail('Loaded ${custom.length} custom shortcut bindings');
      }
    } on Exception catch (e) {
      _logger.warn('Failed to load custom shortcuts: $e');
      _bindingsLoaded = true;
    }
  }

  /// Handle a keyboard input event.
  ///
  /// Finds the action matching the key event and executes it.
  ///
  /// Returns true if an action was found and executed.
  Future<bool> handleKeyEvent(
    KeyInputEvent event,
    ActionContext context,
  ) async {
    // Find action with matching binding
    final action = _findActionForEvent(event);
    if (action == null) {
      return false;
    }

    try {
      return await action.execute(context);
    } on Exception catch (e) {
      _logger.err('Action "${action.id}" failed: $e');
      return false;
    }
  }

  /// Find the action that matches a key event.
  ShortcutAction? _findActionForEvent(KeyInputEvent event) {
    for (final action in _registry.allActions) {
      final binding = getBinding(action.id);
      if (binding.matches(
        eventKey: event.key,
        eventCtrl: event.ctrl,
        eventShift: event.shift,
        eventAlt: event.alt,
      )) {
        return action;
      }
    }
    return null;
  }

  /// Get help text showing all shortcuts.
  String getHelpText() {
    final buffer = StringBuffer()
      ..writeln('Keyboard Shortcuts:')
      ..writeln();

    for (final action in _registry.allActions) {
      final binding = getBinding(action.id);
      final shortcut = binding.toDisplayString().padRight(15);
      buffer.writeln('  $shortcut ${action.description}');
    }

    return buffer.toString();
  }

  /// Get all registered actions.
  List<ShortcutAction> get allActions => _registry.allActions;
}
