import 'package:famon/src/keyboard/key_binding.dart';

/// Default keyboard shortcut bindings.
///
/// These defaults are used when no custom configuration is provided
/// or when specific bindings are not overridden in the config file.
class DefaultShortcuts {
  DefaultShortcuts._();

  /// Default bindings map from action ID to key binding.
  static final Map<String, KeyBinding> bindings = {
    'copy_to_clipboard': const KeyBinding(key: 's', ctrl: true),
    'save_to_file': const KeyBinding(key: 's', ctrl: true, shift: true),
    'toggle_pause': const KeyBinding(key: 'p'),
    'show_stats': const KeyBinding(key: 'i', ctrl: true),
    'clear_screen': const KeyBinding(key: 'l', ctrl: true),
    'show_help': const KeyBinding(key: '?'),
    'quit': const KeyBinding(key: 'q'),
  };

  /// Get the default binding for an action.
  ///
  /// Returns the default binding if defined, otherwise null.
  static KeyBinding? getDefault(String actionId) => bindings[actionId];

  /// Get all default action IDs.
  static List<String> get actionIds => bindings.keys.toList();
}
