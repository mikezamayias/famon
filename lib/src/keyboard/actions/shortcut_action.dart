import 'package:firebase_analytics_monitor/src/keyboard/action_context.dart';
import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';

/// Base interface for all keyboard shortcut actions.
///
/// Each action represents a command that can be triggered by a keyboard
/// shortcut. Actions have a unique identifier, display information, and
/// an execute method that performs the action.
abstract class ShortcutAction {
  /// Unique identifier for this action.
  ///
  /// Used for configuration and registry lookup. Should be snake_case.
  /// Example: 'copy_to_clipboard', 'toggle_pause'
  String get id;

  /// Human-readable name for display in help and menus.
  ///
  /// Example: 'Copy to Clipboard', 'Toggle Pause'
  String get displayName;

  /// Brief description of what this action does.
  ///
  /// Shown in help overlay and configuration documentation.
  String get description;

  /// Default key binding for this action.
  ///
  /// Can be overridden by user configuration.
  KeyBinding get defaultBinding;

  /// Execute the action.
  ///
  /// [context] - Current application state and services.
  ///
  /// Returns true if the action was handled successfully, false if it failed
  /// or was not applicable in the current state.
  Future<bool> execute(ActionContext context);
}

/// Result of executing a shortcut action.
///
/// Provides detailed information about the action outcome for logging
/// and user feedback.
class ActionResult {
  /// Creates a successful result.
  const ActionResult.success({this.message})
      : success = true,
        error = null;

  /// Creates a failed result.
  const ActionResult.failure({this.error, this.message}) : success = false;

  /// Whether the action completed successfully.
  final bool success;

  /// Optional message to display to the user.
  final String? message;

  /// Error message if the action failed.
  final String? error;
}
