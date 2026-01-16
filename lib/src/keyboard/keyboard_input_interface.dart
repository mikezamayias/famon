import 'dart:async';

/// Represents a keyboard input event.
///
/// Contains information about the key pressed and any modifier keys.
class KeyInputEvent {
  /// Creates a new key input event.
  const KeyInputEvent({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
  });

  /// The key character or control code.
  final String key;

  /// Whether the Ctrl key was held.
  final bool ctrl;

  /// Whether the Shift key was held.
  final bool shift;

  /// Whether the Alt key was held.
  final bool alt;

  @override
  String toString() {
    final modifiers = <String>[];
    if (ctrl) modifiers.add('Ctrl');
    if (shift) modifiers.add('Shift');
    if (alt) modifiers.add('Alt');
    if (modifiers.isEmpty) return 'KeyInputEvent($key)';
    return 'KeyInputEvent(${modifiers.join('+')}+$key)';
  }
}

/// Interface for keyboard input handling services.
///
/// Implementations provide raw keyboard input events from the terminal.
/// The service must be started before events are emitted and should be
/// disposed when no longer needed.
abstract class KeyboardInputInterface {
  /// Stream of keyboard input events.
  ///
  /// Events are emitted as keys are pressed. The stream continues until
  /// [dispose] is called.
  Stream<KeyInputEvent> get keyEvents;

  /// Whether the terminal supports interactive keyboard input.
  ///
  /// Returns false if running in a non-interactive environment (e.g., pipes,
  /// CI/CD, or redirected input).
  bool get isInteractive;

  /// Start listening for keyboard input.
  ///
  /// Must be called before events are emitted on [keyEvents].
  /// Sets the terminal to raw mode (no line buffering or echo).
  void start();

  /// Stop listening and restore terminal settings.
  ///
  /// Should be called when keyboard input is no longer needed.
  /// Restores the terminal to its previous mode.
  void dispose();
}
