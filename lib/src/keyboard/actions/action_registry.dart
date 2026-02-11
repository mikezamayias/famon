import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:injectable/injectable.dart';

/// Registry for all available keyboard shortcut actions.
///
/// The registry maintains a collection of all registered actions and provides
/// lookup capabilities. Actions are registered during application startup
/// and can be retrieved by their unique ID.
@lazySingleton
class ActionRegistry {
  /// Creates a new action registry.
  ActionRegistry();

  final Map<String, ShortcutAction> _actions = {};

  /// Register an action in the registry.
  ///
  /// [action] - The action to register.
  ///
  /// Throws [ArgumentError] if an action with the same ID is already
  /// registered.
  void register(ShortcutAction action) {
    if (_actions.containsKey(action.id)) {
      throw ArgumentError(
        'Action with ID "${action.id}" is already registered',
      );
    }
    _actions[action.id] = action;
  }

  /// Register multiple actions at once.
  ///
  /// [actions] - The actions to register.
  void registerAll(Iterable<ShortcutAction> actions) {
    actions.forEach(register);
  }

  /// Get an action by its ID.
  ///
  /// Returns null if no action with the given ID is registered.
  ShortcutAction? getAction(String id) => _actions[id];

  /// Get all registered actions.
  List<ShortcutAction> get allActions => _actions.values.toList();

  /// Get all action IDs.
  List<String> get actionIds => _actions.keys.toList();

  /// Check if an action is registered.
  bool hasAction(String id) => _actions.containsKey(id);

  /// Clear all registered actions.
  ///
  /// Primarily used for testing.
  void clear() => _actions.clear();
}
