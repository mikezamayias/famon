import 'package:equatable/equatable.dart';

/// Represents a keyboard shortcut binding.
///
/// A key binding consists of a key character and optional modifier keys
/// (Ctrl, Shift, Alt, Meta). Key bindings can be parsed from configuration
/// strings like "ctrl+s" or "ctrl+shift+s".
class KeyBinding extends Equatable {
  /// Creates a new key binding.
  const KeyBinding({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  /// Creates a key binding from a configuration string.
  ///
  /// Supported formats:
  /// - "s" - single key
  /// - "ctrl+s" - with Ctrl modifier
  /// - "ctrl+shift+s" - with multiple modifiers
  ///
  /// Modifier keywords (case-insensitive): ctrl, shift, alt, meta, cmd
  factory KeyBinding.fromString(String binding) {
    final parts = binding.toLowerCase().split('+');
    var ctrl = false;
    var shift = false;
    var alt = false;
    var meta = false;
    var key = '';

    for (final part in parts) {
      switch (part.trim()) {
        case 'ctrl':
        case 'control':
          ctrl = true;
        case 'shift':
          shift = true;
        case 'alt':
        case 'option':
          alt = true;
        case 'meta':
        case 'cmd':
        case 'command':
        case 'win':
        case 'windows':
          meta = true;
        default:
          key = part.trim();
      }
    }

    return KeyBinding(
      key: key,
      ctrl: ctrl,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  /// The key character (single character or named key like 'f1', 'space').
  final String key;

  /// Whether the Ctrl key must be held.
  final bool ctrl;

  /// Whether the Shift key must be held.
  final bool shift;

  /// Whether the Alt key must be held.
  final bool alt;

  /// Whether the Meta key (Command on macOS, Windows key on Windows) must
  /// be held.
  final bool meta;

  /// Converts the binding to a human-readable display string.
  ///
  /// Returns strings like "Ctrl+S" or "Ctrl+Shift+S".
  String toDisplayString() {
    final parts = <String>[];

    if (ctrl) parts.add('Ctrl');
    if (shift) parts.add('Shift');
    if (alt) parts.add('Alt');
    if (meta) parts.add('Cmd');

    // Capitalize the key for display
    final displayKey = key.length == 1 ? key.toUpperCase() : key;
    parts.add(displayKey);

    return parts.join('+');
  }

  /// Checks if this binding matches a key event.
  ///
  /// [eventKey] - The key character from the input event.
  /// [eventCtrl] - Whether Ctrl was held during the event.
  /// [eventShift] - Whether Shift was held during the event.
  /// [eventAlt] - Whether Alt was held during the event.
  bool matches({
    required String eventKey,
    bool eventCtrl = false,
    bool eventShift = false,
    bool eventAlt = false,
  }) {
    return eventKey.toLowerCase() == key.toLowerCase() &&
        eventCtrl == ctrl &&
        eventShift == shift &&
        eventAlt == alt;
  }

  @override
  List<Object?> get props => [key, ctrl, shift, alt, meta];
}
