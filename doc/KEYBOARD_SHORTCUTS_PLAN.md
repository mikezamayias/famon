# Keyboard Shortcuts Implementation Plan

## Technical Background

### Keyboard Input in Dart CLI

`dart:io` has limited support for advanced keyboard input:

- Raw mode: `stdin.lineMode = false`, `stdin.echoMode = false`
- Modifier keys (Ctrl, Shift, Alt) are only detectable in combination with other keys
- Control sequences like `Ctrl+C` produce specific byte sequences

**Package:** [termio](https://pub.dev/packages/termio) (v0.5.2+1)
- Pure Dart, VT100 escape codes
- macOS, Linux, Windows, Android, iOS
- `KeyInputEvent` with modifier detection
- Zero dependencies

Alternative: [dart_console](https://pub.dev/packages/dart_console) (v4.1.2) — more mature, heavier.

### Clipboard

No native Dart clipboard for CLI. Use platform process calls:

| Platform | Copy | Paste |
|----------|------|-------|
| macOS | `pbcopy` | `pbpaste` |
| Linux | `xclip -selection clipboard` | `xclip -selection clipboard -o` |
| Windows | `clip.exe` (stdin pipe) | PowerShell `Get-Clipboard` |

### File Save Dialogs

| Platform | Tool |
|----------|------|
| macOS | `osascript` with AppleScript |
| Linux | `zenity --file-selection --save` |
| Windows | PowerShell `System.Windows.Forms.SaveFileDialog` |

Simpler fallback: prompt for file path in terminal (works everywhere).

---

## Architecture

### Directory Structure

```
lib/src/
├── keyboard/
│   ├── keyboard_input_service.dart
│   ├── keyboard_input_interface.dart
│   ├── shortcut_manager.dart
│   ├── shortcut_config.dart
│   ├── actions/
│   │   ├── shortcut_action.dart
│   │   ├── action_registry.dart
│   │   ├── copy_to_clipboard_action.dart
│   │   ├── save_to_file_action.dart
│   │   ├── toggle_pause_action.dart
│   │   ├── show_stats_action.dart
│   │   ├── clear_screen_action.dart
│   │   ├── toggle_filter_action.dart
│   │   └── export_session_action.dart
│   └── key_binding.dart
├── platform/
│   ├── clipboard_service.dart
│   ├── clipboard_interface.dart
│   ├── file_dialog_service.dart
│   └── file_dialog_interface.dart
├── config/
│   ├── shortcuts_config_loader.dart
│   └── default_shortcuts.dart
```

### Key Classes

```dart
class KeyBinding extends Equatable {
  const KeyBinding({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final String key;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta; // Command key on macOS

  factory KeyBinding.fromString(String binding);
  String toDisplayString();
}
```

```dart
abstract class ShortcutAction {
  String get id;
  String get displayName;
  String get description;
  KeyBinding get defaultBinding;

  /// Returns true if handled successfully.
  Future<bool> execute(ActionContext context);
}

class ActionContext {
  final List<AnalyticsEvent> recentEvents;
  final EventCacheInterface eventCache;
  final Logger logger;
  final int eventCountToExport;
}
```

```dart
@lazySingleton
class ActionRegistry {
  final Map<String, ShortcutAction> _actions = {};

  void register(ShortcutAction action);
  ShortcutAction? getAction(String id);
  List<ShortcutAction> get allActions;
}
```

```dart
@injectable
class ShortcutManager {
  Map<String, KeyBinding> get bindings;
  Future<void> loadCustomBindings();
  Future<bool> handleKeyEvent(KeyInputEvent event, ActionContext context);
  String getHelpText();
}
```

### Config File

**Location:** `~/.config/famon/shortcuts.yaml` (or `%APPDATA%\famon\shortcuts.yaml` on Windows)

```yaml
version: 1

shortcuts:
  copy_to_clipboard:
    binding: "ctrl+s"
    event_count: 10

  save_to_file:
    binding: "ctrl+shift+s"
    default_filename: "famon_export_{timestamp}.json"

  toggle_pause:
    binding: "p"

  show_stats:
    binding: "ctrl+i"

  clear_screen:
    binding: "ctrl+l"

  show_help:
    binding: "?"

  toggle_noise_filter:
    binding: "ctrl+f"

  export_session:
    binding: "ctrl+e"
```

---

## Actions

### Required

| Action | Default Shortcut | Description |
|--------|------------------|-------------|
| `copy_to_clipboard` | `Ctrl+S` | Copy last N events as JSON to clipboard |
| `save_to_file` | `Ctrl+Shift+S` | Save events to file with save dialog |

### Additional

| Action | Default Shortcut | Description |
|--------|------------------|-------------|
| `toggle_pause` | `P` | Pause/resume event display (events still captured) |
| `show_stats` | `Ctrl+I` | Show current session statistics |
| `clear_screen` | `Ctrl+L` | Clear terminal, continue monitoring |
| `show_help` | `?` or `F1` | Display keyboard shortcuts help |
| `toggle_noise_filter` | `Ctrl+F` | Toggle hiding high-frequency events |
| `export_session` | `Ctrl+E` | Export entire session to file |
| `search_events` | `/` | Enter search mode |
| `mark_event` | `M` | Mark current event for later reference |
| `show_marked` | `Ctrl+M` | Show only marked events |
| `toggle_verbose` | `V` | Toggle verbose output |
| `quit` | `Q` | Graceful quit |

---

## Implementation Phases

### Phase 1: Core Infrastructure

1. Add `termio` to `pubspec.yaml`
2. Create `KeyBinding` model
3. Create `KeyboardInputInterface` and `KeyboardInputService`
4. Create `ShortcutAction` interface
5. Create `ActionRegistry`
6. Create `ActionContext`
7. Update `RegisterModule`

**New files:**
- `lib/src/keyboard/key_binding.dart`
- `lib/src/keyboard/keyboard_input_interface.dart`
- `lib/src/keyboard/keyboard_input_service.dart`
- `lib/src/keyboard/actions/shortcut_action.dart`
- `lib/src/keyboard/actions/action_registry.dart`
- `lib/src/keyboard/action_context.dart`

### Phase 2: Platform Services

1. Create `ClipboardInterface` and `ClipboardService`
2. Create `FileDialogInterface` and `FileDialogService`
3. Add terminal-prompt fallbacks

**New files:**
- `lib/src/platform/clipboard_interface.dart`
- `lib/src/platform/clipboard_service.dart`
- `lib/src/platform/file_dialog_interface.dart`
- `lib/src/platform/file_dialog_service.dart`

### Phase 3: Action Implementations

1. `CopyToClipboardAction`
2. `SaveToFileAction`
3. `TogglePauseAction`
4. `ShowStatsAction`
5. `ClearScreenAction`
6. `ShowHelpAction`
7. `ToggleNoiseFilterAction`
8. `ExportSessionAction`
9. `QuitAction`

### Phase 4: Configuration System

1. Create `ShortcutConfig` model
2. Create `DefaultShortcuts`
3. Create `ShortcutsConfigLoader`
4. Create `ShortcutManager`
5. Config file discovery (XDG on Linux, AppData on Windows)

### Phase 5: Integration

1. Update `MonitorCommand`: keyboard listener, event buffer, pause state, help on startup
2. Update `FilteredMonitorCommand` similarly
3. Update `EventCacheService`: retrieve last N full events, JSON export
4. Add `--no-shortcuts` flag for non-interactive environments

**Modified files:**
- `lib/src/commands/monitor_command.dart`
- `lib/src/cli/commands/filtered_monitor_command.dart`
- `lib/src/services/event_cache_service.dart`
- `lib/src/services/interfaces/event_cache_interface.dart`

### Phase 6: Help System

1. Help overlay showing all shortcuts
2. Startup message with key shortcuts
3. `shortcuts` subcommand to display/reset

### Phase 7: Testing

1. Unit tests for all action classes
2. Unit tests for `ShortcutManager`
3. Unit tests for `ClipboardService` (mocked platform calls)
4. Integration tests for keyboard handling
5. Manual testing on macOS, Linux, Windows

---

## Implementation Notes

### Event Buffer

`EventCacheService` currently stores only event names and counts. Clipboard/file export needs full `AnalyticsEvent` objects. Add a circular buffer:

```dart
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
```

### Keyboard Listener Integration

The keyboard listener runs concurrently with the logcat stream:

```dart
Future<int> run() async {
  final keyboardSub = _keyboardInput.keyEvents.listen((event) async {
    await _shortcutManager.handleKeyEvent(event, _buildContext());
  });

  try {
    await for (final line in process.stdout...) {
      // existing event processing
    }
  } finally {
    await keyboardSub.cancel();
    _keyboardInput.dispose();
  }
}
```

### Clipboard Service

```dart
class ClipboardService implements ClipboardInterface {
  @override
  Future<void> copy(String text) async {
    if (Platform.isMacOS) {
      final process = await _processManager.start(['pbcopy']);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    } else if (Platform.isLinux) {
      final process = await _processManager.start(['xclip', '-selection', 'clipboard']);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    } else if (Platform.isWindows) {
      final process = await _processManager.start(['clip.exe'], runInShell: true);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
    }
  }
}
```

### File Dialog Service

```dart
class FileDialogService implements FileDialogInterface {
  @override
  Future<String?> showSaveDialog({String? defaultFileName, String? initialDirectory}) async {
    if (Platform.isMacOS) return _showMacOSDialog(defaultFileName, initialDirectory);
    if (Platform.isLinux) return _showLinuxDialog(defaultFileName, initialDirectory);
    if (Platform.isWindows) return _showWindowsDialog(defaultFileName, initialDirectory);
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
    return result.exitCode == 0 ? result.stdout.toString().trim() : null;
  }

  Future<String?> _showLinuxDialog(String? fileName, String? dir) async {
    final args = [
      '--file-selection', '--save', '--confirm-overwrite',
      if (fileName != null) '--filename=$fileName',
    ];
    final result = await Process.run('zenity', args);
    return result.exitCode == 0 ? result.stdout.toString().trim() : null;
  }
}
```

### Terminal Capability Detection

```dart
bool get isInteractiveTerminal => stdin.hasTerminal && stdout.hasTerminal;
// Shortcuts disabled in non-interactive mode (pipes, CI, etc.)
```

### Fallback Behaviors

| Feature | Primary | Fallback |
|---------|---------|----------|
| Clipboard | Platform tool | Write to `/tmp/famon_export.json` |
| File dialog | Native dialog | Terminal prompt for path |
| Keyboard | Raw mode | Disable shortcuts, log warning |

---

## Dependencies

```yaml
dependencies:
  termio: ^0.5.2
  yaml: ^3.1.2
```

---

## References

- [Dart SDK Issue #37591 - keyboard events](https://github.com/dart-lang/sdk/issues/37591)
- [termio on pub.dev](https://pub.dev/packages/termio)
- [dart_console on pub.dev](https://pub.dev/packages/dart_console)
- [DCli Cross Platform](https://dcli.onepub.dev/dcli-api/cross-platform)
- [ncruces/zenity](https://github.com/ncruces/zenity)
