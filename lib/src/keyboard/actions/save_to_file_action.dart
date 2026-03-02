import 'dart:convert';
import 'dart:io';

import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:famon/src/platform/file_dialog_interface.dart';

/// Action to save events to a file with a save dialog.
///
/// Opens a file save dialog (or terminal prompt as fallback) and saves
/// all recent events as formatted JSON to the selected file.
class SaveToFileAction implements ShortcutAction {
  /// Creates a new save to file action.
  SaveToFileAction({required FileDialogInterface fileDialog})
      : _fileDialog = fileDialog;

  final FileDialogInterface _fileDialog;

  @override
  String get id => 'save_to_file';

  @override
  String get displayName => 'Save to File';

  @override
  String get description => 'Save events to a file';

  @override
  KeyBinding get defaultBinding =>
      const KeyBinding(key: 's', ctrl: true, shift: true);

  @override
  Future<bool> execute(ActionContext context) async {
    final events = context.recentEvents;
    if (events.isEmpty) {
      context.logger.info('No events to save');
      return true;
    }

    // Show save dialog or prompt
    final filePath = await _fileDialog.showSaveDialog(
      defaultFileName: _generateDefaultFileName(),
    );

    if (filePath == null || filePath.isEmpty) {
      context.logger.info('Save cancelled');
      return true;
    }

    // Convert events to JSON
    final jsonData = events
        .map(
          (event) => {
            'timestamp': event.rawTimestamp,
            'eventName': event.eventName,
            'parameters': event.parameters,
            if (event.items.isNotEmpty) 'items': event.items,
          },
        )
        .toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'eventCount': events.length,
      'events': jsonData,
    });

    try {
      final file = File(filePath);
      await file.writeAsString(jsonString);
      context.logger.success('Saved ${events.length} events to $filePath');
      return true;
    } on FileSystemException catch (e) {
      context.logger.err('Failed to save file: ${e.message}');
      return false;
    }
  }

  /// Generate a default file name with timestamp.
  String _generateDefaultFileName() {
    final now = DateTime.now();
    final date = '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final time = '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'famon_export_${date}_$time.json';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
