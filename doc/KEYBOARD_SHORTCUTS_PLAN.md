# Keyboard Shortcuts Feature Implementation Plan

## Executive Summary

This plan details how to implement keyboard shortcuts for the Firebase Analytics Monitor CLI. The implementation leverages the `termio` package for cross-platform keyboard input handling and follows the existing architectural patterns (dependency injection, interfaces, services).

## 1. Technical Research Summary

### Keyboard Input in Dart CLI

Based on research, Dart's standard `dart:io` library has limited support for advanced keyboard input:

- Basic raw mode is available via `stdin.lineMode = false` and `stdin.echoMode = false`
- Standard Dart **cannot detect modifier keys (Ctrl, Shift, Alt) in isolation** - only when combined with other keys
- Control sequences like `Ctrl+C` produce specific byte sequences that can be detected

**Recommended Package**: [termio](https://pub.dev/packages/termio) (v0.5.2+1)
- Pure Dart implementation using VT100 escape codes
- Supports Windows, macOS, Linux, Android, iOS
- Provides `KeyInputEvent` with modifier detection
- Zero dependencies

Alternative: [dart_console](https://pub.dev/packages/dart_console) (v4.1.2)
- More mature but heavier
- Good raw mode support

### Clipboard Operations

No native Dart clipboard support for CLI apps. Solution: **platform-specific process calls**:

| Platform | Copy Command | Paste Command |
|----------|--------------|---------------|
| macOS    | `pbcopy`     | `pbpaste`     |
| Linux    | `xclip -selection clipboard` | `xclip -selection clipboard -o` |
| Windows  | `clip.exe` (via stdin pipe) | PowerShell `Get-Clipboard` |

### File Save Dialogs

For `Ctrl+Shift+S` (save to file with dialog), implement using:

| Platform | Dialog Tool |
|----------|-------------|
| macOS    | `osascript` with AppleScript |
| Linux    | `zenity --file-selection --save` |
| Windows  | PowerShell `System.Windows.Forms.SaveFileDialog` |

**Alternative approach**: Prompt for file path in terminal (simpler, works everywhere)

---

## 2. Architecture Design

### 2.1 Directory Structure

```
lib/src/
├── keyboard/
│   ├── keyboard_input_service.dart       # Raw keyboard input handling
│   ├── keyboard_input_interface.dart     # Interface for DI
│   ├── shortcut_manager.dart             # Manages shortcut bindings
│   ├── shortcut_config.dart              # Configuration model
│   ├── actions/
│   │   ├── shortcut_action.dart          # Base action interface
│   │   ├── action_registry.dart          # Registry of all actions
│   │   ├── copy_to_clipboard_action.dart
│   │   ├── save_to_file_action.dart
│   │   ├── toggle_pause_action.dart
│   │   ├── show_stats_action.dart
│   │   ├── clear_screen_action.dart
│   │   ├── toggle_filter_action.dart
│   │   └── export_session_action.dart
│   └── key_binding.dart                  # Key binding model
├── platform/
│   ├── clipboard_service.dart            # Cross-platform clipboard
│   ├── clipboard_interface.dart
│   ├── file_dialog_service.dart          # Cross-platform file dialogs
│   └── file_dialog_interface.dart
├── config/
│   ├── shortcuts_config_loader.dart      # Loads config from file
│   └── default_shortcuts.dart            # Default shortcut definitions
```

### 2.2 Key Classes

#### KeyBinding Model

```dart
/// Represents a keyboard shortcut binding
class KeyBinding extends Equatable {
  const KeyBinding({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final String key;        // Single character or named key (e.g., 's', 'f1')
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;         // Command key on macOS

  /// Parse from config string like "ctrl+shift+s"
  factory KeyBinding.fromString(String binding);

  /// Convert to display string for help
  String toDisplayString();
}
```

#### ShortcutAction Interface

```dart
/// Base interface for all shortcut actions
abstract class ShortcutAction {
  /// Unique identifier for this action
  String get id;

  /// Human-readable name for display
  String get displayName;

  /// Description of what this action does
  String get description;

  /// Default key binding (can be overridden by config)
  KeyBinding get defaultBinding;

  /// Execute the action
  /// Returns true if action was handled successfully
  Future<bool> execute(ActionContext context);
}

/// Context passed to actions containing current state
class ActionContext {
  final List<AnalyticsEvent> recentEvents;
  final EventCacheInterface eventCache;
  final Logger logger;
  final int eventCountToExport;
  // ... other contextual data
}
```

#### ActionRegistry

```dart
/// Registry for all available shortcut actions
@lazySingleton
class ActionRegistry {
  final Map<String, ShortcutAction> _actions = {};

  void register(ShortcutAction action);
  ShortcutAction? getAction(String id);
  List<ShortcutAction> get allActions;
}
```

#### ShortcutManager

```dart
/// Manages keyboard shortcuts and dispatches to actions
@injectable
class ShortcutManager {
  ShortcutManager({
    required ActionRegistry actionRegistry,
    required ShortcutConfigLoader configLoader,
    required Logger logger,
  });

  /// Current shortcut bindings (action ID -> key binding)
  Map<String, KeyBinding> get bindings;

  /// Load custom bindings from config file
  Future<void> loadCustomBindings();

  /// Handle a key event, dispatch to appropriate action
  Future<bool> handleKeyEvent(KeyInputEvent event, ActionContext context);

  /// Get help text for all shortcuts
  String getHelpText();
}
```

### 2.3 Configuration File Format

**Location**: `~/.config/famon/shortcuts.yaml` (or `%APPDATA%\famon\shortcuts.yaml` on Windows)

```yaml
# Firebase Analytics Monitor - Keyboard Shortcuts Configuration
version: 1

shortcuts:
  # Copy last N events to clipboard
  copy_to_clipboard:
    binding: "ctrl+s"
    event_count: 10  # How many events to copy

  # Save events to file (with dialog)
  save_to_file:
    binding: "ctrl+shift+s"
    default_filename: "famon_export_{timestamp}.json"

  # Pause/resume event streaming
  toggle_pause:
    binding: "p"

  # Show session statistics
  show_stats:
    binding: "ctrl+i"

  # Clear screen
  clear_screen:
    binding: "ctrl+l"

  # Show help overlay
  show_help:
    binding: "?"

  # Quick filter toggle (hide high-frequency events)
  toggle_noise_filter:
    binding: "ctrl+f"

  # Export entire session
  export_session:
    binding: "ctrl+e"
```

---

## 3. Proposed Actions

### 3.1 Required Actions (User Requested)

| Action | Default Shortcut | Description |
|--------|------------------|-------------|
| `copy_to_clipboard` | `Ctrl+S` | Copy last N events as JSON to clipboard |
| `save_to_file` | `Ctrl+Shift+S` | Save events to file with save dialog |

### 3.2 Additional Suggested Actions

| Action | Default Shortcut | Description |
|--------|------------------|-------------|
| `toggle_pause` | `P` | Pause/resume event display (events still captured) |
| `show_stats` | `Ctrl+I` | Show current session statistics inline |
| `clear_screen` | `Ctrl+L` | Clear terminal, continue monitoring |
| `show_help` | `?` or `F1` | Display keyboard shortcuts help overlay |
| `toggle_noise_filter` | `Ctrl+F` | Toggle hiding high-frequency events |
| `export_session` | `Ctrl+E` | Export entire session to file |
| `search_events` | `/` | Enter search mode to filter displayed events |
| `mark_event` | `M` | Mark current event for later reference |
| `show_marked` | `Ctrl+M` | Show only marked events |
| `toggle_verbose` | `V` | Toggle verbose output mode |
| `quit` | `Q` | Gracefully quit monitoring |

---

## 4. Implementation Phases

### Phase 1: Core Infrastructure

**Goal**: Establish keyboard input handling foundation

1. Add `termio` package to `pubspec.yaml`
2. Create `KeyBinding` model class
3. Create `KeyboardInputInterface` and `KeyboardInputService`
4. Create `ShortcutAction` base interface
5. Create `ActionRegistry` class
6. Create `ActionContext` class
7. Update `RegisterModule` with new DI registrations

**Files to Create**:
- `/lib/src/keyboard/key_binding.dart`
- `/lib/src/keyboard/keyboard_input_interface.dart`
- `/lib/src/keyboard/keyboard_input_service.dart`
- `/lib/src/keyboard/actions/shortcut_action.dart`
- `/lib/src/keyboard/actions/action_registry.dart`
- `/lib/src/keyboard/action_context.dart`

### Phase 2: Platform Services

**Goal**: Cross-platform clipboard and file dialog support

1. Create `ClipboardInterface` and `ClipboardService`
2. Implement platform-specific clipboard operations
3. Create `FileDialogInterface` and `FileDialogService`
4. Implement platform-specific file save dialogs
5. Add fallback prompts for unsupported environments

**Files to Create**:
- `/lib/src/platform/clipboard_interface.dart`
- `/lib/src/platform/clipboard_service.dart`
- `/lib/src/platform/file_dialog_interface.dart`
- `/lib/src/platform/file_dialog_service.dart`

### Phase 3: Action Implementations

**Goal**: Implement all shortcut actions

1. Implement `CopyToClipboardAction`
2. Implement `SaveToFileAction`
3. Implement `TogglePauseAction`
4. Implement `ShowStatsAction`
5. Implement `ClearScreenAction`
6. Implement `ShowHelpAction`
7. Implement `ToggleNoiseFilterAction`
8. Implement `ExportSessionAction`
9. Implement `QuitAction`

**Files to Create**:
- `/lib/src/keyboard/actions/copy_to_clipboard_action.dart`
- `/lib/src/keyboard/actions/save_to_file_action.dart`
- `/lib/src/keyboard/actions/toggle_pause_action.dart`
- `/lib/src/keyboard/actions/show_stats_action.dart`
- `/lib/src/keyboard/actions/clear_screen_action.dart`
- `/lib/src/keyboard/actions/show_help_action.dart`
- `/lib/src/keyboard/actions/toggle_noise_filter_action.dart`
- `/lib/src/keyboard/actions/export_session_action.dart`
- `/lib/src/keyboard/actions/quit_action.dart`

### Phase 4: Configuration System

**Goal**: User-customizable shortcuts

1. Create `ShortcutConfig` model
2. Create `DefaultShortcuts` with built-in defaults
3. Create `ShortcutsConfigLoader` for reading YAML config
4. Create `ShortcutManager` to coordinate everything
5. Implement config file discovery (XDG on Linux, AppData on Windows, etc.)

**Files to Create**:
- `/lib/src/keyboard/shortcut_config.dart`
- `/lib/src/config/default_shortcuts.dart`
- `/lib/src/config/shortcuts_config_loader.dart`
- `/lib/src/keyboard/shortcut_manager.dart`

### Phase 5: Integration

**Goal**: Integrate with existing monitoring commands

1. Modify `MonitorCommand` to:
   - Initialize keyboard input listener
   - Maintain event buffer for export
   - Handle pause state
   - Display help on startup

2. Modify `FilteredMonitorCommand` similarly

3. Update `EventCacheService` to support:
   - Retrieving last N events with full data
   - JSON export of cached events

4. Add `--no-shortcuts` flag for non-interactive environments

**Files to Modify**:
- `/lib/src/commands/monitor_command.dart`
- `/lib/src/cli/commands/filtered_monitor_command.dart`
- `/lib/src/services/event_cache_service.dart`
- `/lib/src/services/interfaces/event_cache_interface.dart`

### Phase 6: Help System

**Goal**: User-friendly help display

1. Implement help overlay that shows all shortcuts
2. Add startup message showing key shortcuts
3. Add `shortcuts` subcommand to display/reset shortcuts

**Files to Create**:
- `/lib/src/keyboard/help_overlay.dart`
- `/lib/src/commands/shortcuts_command.dart`

### Phase 7: Testing

**Goal**: Comprehensive test coverage

1. Unit tests for all action classes
2. Unit tests for `ShortcutManager`
3. Unit tests for `ClipboardService` (mocked platform calls)
4. Integration tests for keyboard handling
5. Manual testing on macOS, Linux, Windows

**Files to Create**:
- `/test/src/keyboard/key_binding_test.dart`
- `/test/src/keyboard/shortcut_manager_test.dart`
- `/test/src/keyboard/actions/*_test.dart`
- `/test/src/platform/clipboard_service_test.dart`

---

## 5. Detailed Implementation Notes

### 5.1 Event Buffer for Export

The current `EventCacheService` only stores event names and counts. For clipboard/file export, we need to store full `AnalyticsEvent` objects.

**Solution**: Add a circular buffer to `EventCacheService`:

```dart
class EventCacheService implements EventCacheInterface {
  // Existing...
  final Set<String> _uniqueEventNames = <String>{};
  final Map<String, int> _eventCounts = <String, int>{};

  // NEW: Circular buffer for recent events
  final Queue<AnalyticsEvent> _recentEvents = Queue<AnalyticsEvent>();
  static const int _maxRecentEvents = 1000;

  void addFullEvent(AnalyticsEvent event) {
    addEvent(event.eventName);
    _recentEvents.add(event);
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }
  }

  List<AnalyticsEvent> getRecentEvents(int count) {
    return _recentEvents.toList().reversed.take(count).toList();
  }
}
```

### 5.2 Keyboard Input Integration Pattern

The keyboard listener must run concurrently with the logcat stream:

```dart
Future<int> run() async {
  // ... existing setup ...

  // Start keyboard listener
  final keyboardSub = _keyboardInput.keyEvents.listen((event) async {
    await _shortcutManager.handleKeyEvent(event, _buildContext());
  });

  try {
    await for (final line in process.stdout...) {
      // ... existing event processing ...
    }
  } finally {
    await keyboardSub.cancel();
    _keyboardInput.dispose();
  }
}
```

### 5.3 Clipboard Service Implementation

```dart
class ClipboardService implements ClipboardInterface {
  final ProcessManager _processManager;

  @override
  Future<void> copy(String text) async {
    if (Platform.isMacOS) {
      final process = await _processManager.start(['pbcopy']);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    } else if (Platform.isLinux) {
      final process = await _processManager.start(
        ['xclip', '-selection', 'clipboard'],
      );
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    } else if (Platform.isWindows) {
      final process = await _processManager.start(
        ['clip.exe'],
        runInShell: true,
      );
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    }
  }
}
```

### 5.4 File Dialog Service Implementation

```dart
class FileDialogService implements FileDialogInterface {
  @override
  Future<String?> showSaveDialog({
    String? defaultFileName,
    String? initialDirectory,
  }) async {
    if (Platform.isMacOS) {
      return _showMacOSDialog(defaultFileName, initialDirectory);
    } else if (Platform.isLinux) {
      return _showLinuxDialog(defaultFileName, initialDirectory);
    } else if (Platform.isWindows) {
      return _showWindowsDialog(defaultFileName, initialDirectory);
    }
    // Fallback: prompt in terminal
    return _promptInTerminal(defaultFileName);
  }

  Future<String?> _showMacOSDialog(String? fileName, String? dir) async {
    final script = '''
      tell application "System Events"
        activate
        set filePath to choose file name default name "${fileName ?? 'export.json'}"
        return POSIX path of filePath
      end tell
    ''';
    final result = await Process.run('osascript', ['-e', script]);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return null;
  }

  Future<String?> _showLinuxDialog(String? fileName, String? dir) async {
    final args = [
      '--file-selection',
      '--save',
      '--confirm-overwrite',
      if (fileName != null) '--filename=$fileName',
    ];
    final result = await Process.run('zenity', args);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return null;
  }
}
```

### 5.5 Help Overlay Display

```dart
void showHelpOverlay(Logger logger, ShortcutManager manager) {
  logger
    ..info('')
    ..info(lightCyan.wrap('═══════════════════════════════════════'))
    ..info(lightCyan.wrap('       Keyboard Shortcuts Help         '))
    ..info(lightCyan.wrap('═══════════════════════════════════════'))
    ..info('');

  for (final action in manager.getAllActions()) {
    final binding = manager.getBinding(action.id);
    logger.info(
      '  ${binding.toDisplayString().padRight(15)} ${action.description}',
    );
  }

  logger
    ..info('')
    ..info(darkGray.wrap('Press any key to continue...'))
    ..info('');
}
```

---

## 6. Cross-Platform Considerations

### 6.1 Platform Detection

```dart
import 'dart:io' show Platform;

// Use existing ProcessManager from DI for all process calls
// This allows mocking in tests
```

### 6.2 Terminal Capability Detection

```dart
bool get isInteractiveTerminal {
  return stdin.hasTerminal && stdout.hasTerminal;
}

// Disable shortcuts in non-interactive mode (pipes, CI, etc.)
```

### 6.3 Fallback Behaviors

| Feature | Primary | Fallback |
|---------|---------|----------|
| Clipboard | Platform tool | Log "copied to /tmp/famon_export.json" |
| File Dialog | Native dialog | Terminal prompt for path |
| Keyboard | Raw mode | Disable shortcuts, log warning |

---

## 7. Dependencies to Add

```yaml
dependencies:
  termio: ^0.5.2  # Keyboard input handling
  yaml: ^3.1.2    # Config file parsing (if not using JSON)
```

---

## 8. Summary

This implementation plan provides:

1. **Modular Architecture**: Clean separation between keyboard input, actions, and platform services
2. **Extensibility**: Easy to add new actions via the registry pattern
3. **Configurability**: YAML-based user customization
4. **Cross-Platform**: Works on macOS, Linux, and Windows
5. **Graceful Degradation**: Fallbacks for unsupported environments
6. **Testability**: Interface-based design enables mocking

The implementation follows existing patterns in the codebase (injectable DI, interfaces, services) and integrates seamlessly with the current monitoring commands.

---

## References

- [Command line keyboard events - Dart SDK Issue #37591](https://github.com/dart-lang/sdk/issues/37591)
- [termio package on pub.dev](https://pub.dev/packages/termio)
- [dart_console package on pub.dev](https://pub.dev/packages/dart_console)
- [DCli Cross Platform documentation](https://dcli.onepub.dev/dcli-api/cross-platform)
- [ncruces/zenity - Cross-platform dialogs](https://github.com/ncruces/zenity)
