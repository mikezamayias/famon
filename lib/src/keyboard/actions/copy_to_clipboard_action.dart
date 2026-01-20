import 'dart:convert';

import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:famon/src/platform/clipboard_interface.dart';

/// Action to copy recent events to the system clipboard.
///
/// Copies the most recent events as formatted JSON to the clipboard.
/// The number of events is configured in [ActionContext.eventCountToExport].
class CopyToClipboardAction implements ShortcutAction {
  /// Creates a new copy to clipboard action.
  CopyToClipboardAction({required ClipboardInterface clipboard})
      : _clipboard = clipboard;

  final ClipboardInterface _clipboard;

  @override
  String get id => 'copy_to_clipboard';

  @override
  String get displayName => 'Copy to Clipboard';

  @override
  String get description => 'Copy recent events to clipboard as JSON';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 's', ctrl: true);

  @override
  Future<bool> execute(ActionContext context) async {
    if (!_clipboard.isSupported) {
      context.logger.warn('Clipboard not supported on this platform');
      return false;
    }

    final events = context.recentEvents;
    if (events.isEmpty) {
      context.logger.info('No events to copy');
      return true;
    }

    // Get the most recent N events
    final count = context.eventCountToExport;
    final eventsToExport = events.length <= count
        ? events
        : events.sublist(events.length - count);

    // Convert to JSON format
    final jsonData = eventsToExport
        .map(
          (event) => {
            'timestamp': event.rawTimestamp,
            'eventName': event.eventName,
            'parameters': event.parameters,
            if (event.items.isNotEmpty) 'items': event.items,
          },
        )
        .toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    final success = await _clipboard.copy(jsonString);
    if (success) {
      context.logger.success(
        'Copied ${eventsToExport.length} events to clipboard',
      );
    } else {
      context.logger.err('Failed to copy to clipboard');
    }

    return success;
  }
}
