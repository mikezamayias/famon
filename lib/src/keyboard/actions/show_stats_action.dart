import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';

/// Action to display session statistics inline.
///
/// Shows a summary of the current monitoring session including unique events,
/// total events, and most frequent events.
class ShowStatsAction implements ShortcutAction {
  /// Creates a new show stats action.
  ShowStatsAction();

  @override
  String get id => 'show_stats';

  @override
  String get displayName => 'Show Statistics';

  @override
  String get description => 'Display session statistics';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 'i', ctrl: true);

  @override
  Future<bool> execute(ActionContext context) async {
    final stats = context.eventCache.getSessionStats();
    final topEvents = context.eventCache.getTopEvents(5);
    final eventCache = context.eventCache;

    final logger = context.logger;

    final separator = darkGray.wrap('─' * 40);

    logger
      ..status('')
      ..status(lightCyan.wrap('Session Statistics'))
      ..status(separator)
      ..status('Unique Events: ${stats.totalUniqueEvents}')
      ..status('Total Events:  ${stats.totalEventOccurrences}')
      ..status('');

    if (topEvents.isNotEmpty) {
      logger.status('Most Frequent Events:');
      for (final eventName in topEvents) {
        final count = eventCache.getEventCount(eventName);
        logger.status(
          '  ${eventName.padRight(25)} ${count.toString().padLeft(5)}',
        );
      }
    }

    logger
      ..status(separator)
      ..status('');

    return true;
  }
}
