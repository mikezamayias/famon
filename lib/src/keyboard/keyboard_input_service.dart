import 'dart:async';
import 'dart:io';

import 'package:famon/src/keyboard/keyboard_input_interface.dart';
import 'package:injectable/injectable.dart';

/// Implementation of [KeyboardInputInterface] using dart:io stdin.
///
/// This service puts the terminal into raw mode to receive individual
/// keystrokes without waiting for Enter. It handles control sequences
/// for modifier keys where possible.
///
/// ## Control Sequences
///
/// In raw terminal mode, modifier keys produce specific byte sequences:
/// - Ctrl+A through Ctrl+Z: bytes 1-26 (Ctrl+C = 3, Ctrl+S = 19, etc.)
/// - Plain letters: ASCII codes 65-90 (uppercase) or 97-122 (lowercase)
/// - Special keys: escape sequences starting with ESC (27)
@injectable
class KeyboardInputService implements KeyboardInputInterface {
  /// Creates a new keyboard input service.
  KeyboardInputService();

  StreamController<KeyInputEvent>? _controller;
  StreamSubscription<List<int>>? _subscription;
  bool _originalLineMode = true;
  bool _originalEchoMode = true;
  bool _isStarted = false;

  @override
  Stream<KeyInputEvent> get keyEvents {
    _controller ??= StreamController<KeyInputEvent>.broadcast();
    return _controller!.stream;
  }

  @override
  bool get isInteractive => stdin.hasTerminal;

  @override
  void start() {
    if (_isStarted) return;
    if (!isInteractive) return;

    _controller ??= StreamController<KeyInputEvent>.broadcast();

    // Save original terminal settings
    _originalLineMode = stdin.lineMode;
    _originalEchoMode = stdin.echoMode;

    // Set raw mode
    stdin.lineMode = false;
    stdin.echoMode = false;

    _isStarted = true;

    // Listen for stdin input
    _subscription = stdin.listen(
      _handleInput,
      onError: (Object error) {
        // Ignore errors - terminal might not support raw mode
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    if (!_isStarted) return;

    // Cancel subscription
    unawaited(_subscription?.cancel());
    _subscription = null;

    // Restore terminal settings
    if (isInteractive) {
      try {
        stdin.lineMode = _originalLineMode;
        stdin.echoMode = _originalEchoMode;
      } on StdinException catch (_) {
        // Terminal might be gone, ignore
      }
    }

    // Close controller
    unawaited(_controller?.close());
    _controller = null;
    _isStarted = false;
  }

  /// Handle raw input bytes from stdin.
  void _handleInput(List<int> bytes) {
    if (bytes.isEmpty) return;

    final event = _parseInput(bytes);
    if (event != null) {
      _controller?.add(event);
    }
  }

  /// Parse raw input bytes into a [KeyInputEvent].
  KeyInputEvent? _parseInput(List<int> bytes) {
    if (bytes.isEmpty) return null;

    final firstByte = bytes[0];

    // Check for Ctrl+key combinations (bytes 1-26)
    if (firstByte >= 1 && firstByte <= 26) {
      // Ctrl+A = 1, Ctrl+B = 2, ..., Ctrl+Z = 26
      final keyChar = String.fromCharCode(firstByte + 96); // 'a' = 97
      return KeyInputEvent(key: keyChar, ctrl: true);
    }

    // Check for escape sequences (ESC = 27)
    if (firstByte == 27) {
      return _parseEscapeSequence(bytes);
    }

    // Regular printable character
    if (firstByte >= 32 && firstByte <= 126) {
      return KeyInputEvent(key: String.fromCharCode(firstByte));
    }

    // Enter key
    if (firstByte == 10 || firstByte == 13) {
      return const KeyInputEvent(key: 'enter');
    }

    // Backspace
    if (firstByte == 127 || firstByte == 8) {
      return const KeyInputEvent(key: 'backspace');
    }

    // Tab
    if (firstByte == 9) {
      return const KeyInputEvent(key: 'tab');
    }

    return null;
  }

  /// Parse escape sequences for special keys.
  KeyInputEvent? _parseEscapeSequence(List<int> bytes) {
    if (bytes.length == 1) {
      // Just ESC key
      return const KeyInputEvent(key: 'escape');
    }

    if (bytes.length >= 2) {
      // Alt+key combination: ESC followed by key
      if (bytes[1] >= 32 && bytes[1] <= 126) {
        return KeyInputEvent(key: String.fromCharCode(bytes[1]), alt: true);
      }

      // Arrow keys and function keys
      if (bytes.length >= 3 && bytes[1] == 91) {
        // '[' = 91
        return _parseCSISequence(bytes);
      }
    }

    return const KeyInputEvent(key: 'escape');
  }

  /// Parse CSI (Control Sequence Introducer) sequences.
  ///
  /// CSI sequences start with ESC [ and are used for arrow keys,
  /// function keys, and other special keys.
  KeyInputEvent? _parseCSISequence(List<int> bytes) {
    if (bytes.length < 3) return null;

    final code = bytes[2];

    // Arrow keys
    switch (code) {
      case 65: // Up
        return const KeyInputEvent(key: 'up');
      case 66: // Down
        return const KeyInputEvent(key: 'down');
      case 67: // Right
        return const KeyInputEvent(key: 'right');
      case 68: // Left
        return const KeyInputEvent(key: 'left');
      case 72: // Home
        return const KeyInputEvent(key: 'home');
      case 70: // End
        return const KeyInputEvent(key: 'end');
    }

    // Function keys and other special keys
    if (bytes.length >= 4 && bytes[3] == 126) {
      // '~' = 126
      switch (code) {
        case 49: // F1-F4 have additional bytes
          return const KeyInputEvent(key: 'home');
        case 50:
          return const KeyInputEvent(key: 'insert');
        case 51:
          return const KeyInputEvent(key: 'delete');
        case 52:
          return const KeyInputEvent(key: 'end');
        case 53:
          return const KeyInputEvent(key: 'pageup');
        case 54:
          return const KeyInputEvent(key: 'pagedown');
      }
    }

    return null;
  }
}
