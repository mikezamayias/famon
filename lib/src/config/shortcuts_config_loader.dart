import 'dart:io';

import 'package:famon/src/config/default_shortcuts.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Loader for user-configured keyboard shortcuts.
///
/// Loads shortcut configuration from YAML files in platform-specific
/// locations:
/// - macOS/Linux: `~/.config/famon/shortcuts.yaml`
/// - Windows: `%APPDATA%\famon\shortcuts.yaml`
@injectable
class ShortcutsConfigLoader {
  /// Creates a new shortcuts config loader.
  ShortcutsConfigLoader();

  /// Load custom shortcut bindings from the config file.
  ///
  /// Returns a map of action IDs to custom bindings. Actions not specified
  /// in the config will not be in the returned map (use defaults).
  Future<Map<String, KeyBinding>> loadCustomBindings() async {
    final configPath = _getConfigPath();
    final configFile = File(configPath);

    if (!configFile.existsSync()) {
      return {};
    }

    try {
      final content = await configFile.readAsString();
      return _parseConfig(content);
    } on Exception catch (_) {
      // Return empty map on parse errors (fall back to defaults)
      return {};
    }
  }

  /// Get the platform-specific config file path.
  String _getConfigPath() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      return path.join(appData, 'famon', 'shortcuts.yaml');
    } else {
      // macOS and Linux use XDG config directory
      final home = Platform.environment['HOME'] ?? '';
      final xdgConfig =
          Platform.environment['XDG_CONFIG_HOME'] ?? path.join(home, '.config');
      return path.join(xdgConfig, 'famon', 'shortcuts.yaml');
    }
  }

  /// Parse the YAML configuration content.
  Map<String, KeyBinding> _parseConfig(String content) {
    final yaml = loadYaml(content);
    if (yaml is! YamlMap) {
      return {};
    }

    final shortcuts = yaml['shortcuts'];
    if (shortcuts is! YamlMap) {
      return {};
    }

    final bindings = <String, KeyBinding>{};

    for (final entry in shortcuts.entries) {
      final actionId = entry.key as String;
      final config = entry.value;

      if (config is YamlMap && config.containsKey('binding')) {
        final bindingStr = config['binding'] as String;
        bindings[actionId] = KeyBinding.fromString(bindingStr);
      } else if (config is String) {
        // Simple format: action_id: "ctrl+s"
        bindings[actionId] = KeyBinding.fromString(config);
      }
    }

    return bindings;
  }

  /// Check if a config file exists.
  bool hasConfigFile() {
    return File(_getConfigPath()).existsSync();
  }

  /// Create a default config file with all default bindings documented.
  Future<void> createDefaultConfig() async {
    final configPath = _getConfigPath();
    final configFile = File(configPath);

    // Create parent directory if needed
    final configDir = configFile.parent;
    if (!configDir.existsSync()) {
      await configDir.create(recursive: true);
    }

    final content = StringBuffer()
      ..writeln('# Firebase Analytics Monitor - Keyboard Shortcuts')
      ..writeln('# Customize your keyboard shortcuts below.')
      ..writeln('# Format: action_id: "key_binding"')
      ..writeln('# Modifiers: ctrl, shift, alt, cmd (meta)')
      ..writeln('#')
      ..writeln('# Example: copy_to_clipboard: "ctrl+c"')
      ..writeln()
      ..writeln('version: 1')
      ..writeln()
      ..writeln('shortcuts:');

    for (final actionId in DefaultShortcuts.actionIds) {
      final binding = DefaultShortcuts.bindings[actionId]!;
      final bindingStr = binding.toDisplayString().toLowerCase();
      content.writeln('  $actionId: "$bindingStr"');
    }

    await configFile.writeAsString(content.toString());
  }
}
