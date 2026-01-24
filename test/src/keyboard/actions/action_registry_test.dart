import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/action_registry.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:test/test.dart';

class MockAction implements ShortcutAction {
  MockAction(this.id);

  @override
  final String id;

  @override
  String get displayName => 'Mock Action';

  @override
  String get description => 'A mock action for testing';

  @override
  KeyBinding get defaultBinding => const KeyBinding(key: 't');

  @override
  Future<bool> execute(ActionContext context) async => true;
}

void main() {
  group('ActionRegistry', () {
    late ActionRegistry registry;

    setUp(() {
      registry = ActionRegistry();
    });

    test('starts empty', () {
      expect(registry.allActions, isEmpty);
    });

    test('registers a single action', () {
      final action = MockAction('test_action');
      registry.register(action);

      expect(registry.allActions, hasLength(1));
      expect(registry.getAction('test_action'), equals(action));
    });

    test('registers multiple actions', () {
      final action1 = MockAction('action1');
      final action2 = MockAction('action2');
      final action3 = MockAction('action3');

      registry.registerAll([action1, action2, action3]);

      expect(registry.allActions, hasLength(3));
      expect(registry.getAction('action1'), equals(action1));
      expect(registry.getAction('action2'), equals(action2));
      expect(registry.getAction('action3'), equals(action3));
    });

    test('returns null for unregistered action', () {
      expect(registry.getAction('nonexistent'), isNull);
    });

    test('throws when registering action with same id', () {
      final action1 = MockAction('same_id');
      final action2 = MockAction('same_id');

      registry.register(action1);

      // Should throw ArgumentError for duplicate ID
      expect(
        () => registry.register(action2),
        throwsA(isA<ArgumentError>()),
      );

      // Original action should remain
      expect(registry.allActions, hasLength(1));
      expect(registry.getAction('same_id'), equals(action1));
    });

    test('maintains action order', () {
      final action1 = MockAction('first');
      final action2 = MockAction('second');
      final action3 = MockAction('third');

      registry.registerAll([action1, action2, action3]);

      final actions = registry.allActions;
      expect(actions[0].id, equals('first'));
      expect(actions[1].id, equals('second'));
      expect(actions[2].id, equals('third'));
    });
  });
}
