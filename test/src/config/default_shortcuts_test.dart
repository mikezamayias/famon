import 'package:famon/src/config/default_shortcuts.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultShortcuts', () {
    test('provides bindings for all action IDs', () {
      for (final actionId in DefaultShortcuts.actionIds) {
        final binding = DefaultShortcuts.bindings[actionId];
        expect(binding, isNotNull, reason: 'Missing binding for $actionId');
      }
    });

    test('getDefault returns binding for known action', () {
      final binding = DefaultShortcuts.getDefault('show_help');
      expect(binding, isNotNull);
      expect(binding!.key, equals('?'));
    });

    test('getDefault returns null for unknown action', () {
      final binding = DefaultShortcuts.getDefault('nonexistent_action');
      expect(binding, isNull);
    });

    test('has expected shortcuts', () {
      // Verify some expected default shortcuts
      expect(DefaultShortcuts.bindings['copy_to_clipboard']?.ctrl, isTrue);
      expect(DefaultShortcuts.bindings['copy_to_clipboard']?.key, equals('s'));

      expect(DefaultShortcuts.bindings['quit']?.key, equals('q'));

      expect(DefaultShortcuts.bindings['toggle_pause']?.key, equals('p'));

      expect(DefaultShortcuts.bindings['clear_screen']?.key, equals('l'));
      expect(DefaultShortcuts.bindings['clear_screen']?.ctrl, isTrue);
    });

    test('actionIds list is not empty', () {
      expect(DefaultShortcuts.actionIds, isNotEmpty);
    });

    test('all shortcuts have non-empty keys', () {
      for (final entry in DefaultShortcuts.bindings.entries) {
        expect(
          entry.value.key,
          isNotEmpty,
          reason: 'Empty key for action ${entry.key}',
        );
      }
    });
  });
}
