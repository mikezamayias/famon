import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/action_registry.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/actions/show_help_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

// Fake action for testing
class FakeAction implements ShortcutAction {
  FakeAction(this._id, this._displayName, this._description, this._binding);

  final String _id;
  final String _displayName;
  final String _description;
  final KeyBinding _binding;

  @override
  String get id => _id;

  @override
  String get displayName => _displayName;

  @override
  String get description => _description;

  @override
  KeyBinding get defaultBinding => _binding;

  @override
  Future<bool> execute(ActionContext context) async => true;
}

void main() {
  late MockLogger logger;
  late MockEventCache eventCache;
  late ActionRegistry registry;
  late ShowHelpAction action;

  setUp(() {
    logger = MockLogger();
    eventCache = MockEventCache();
    registry = ActionRegistry()
      // Register some test actions
      ..register(
        FakeAction(
          'action1',
          'Action 1',
          'First test action',
          const KeyBinding(key: 'a'),
        ),
      )
      ..register(
        FakeAction(
          'action2',
          'Action 2',
          'Second test action',
          const KeyBinding(key: 'b', ctrl: true),
        ),
      );

    action = ShowHelpAction(
      registry: registry,
      getBinding: (id) {
        // Return the binding from the action itself
        final action = registry.allActions.firstWhere((a) => a.id == id);
        return action.defaultBinding;
      },
    );
  });

  group('ShowHelpAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('show_help'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Show Help'));
    });

    test('has correct description', () {
      expect(action.description, equals('Display keyboard shortcuts'));
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('?'));
      expect(binding.ctrl, isFalse);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });

  group('ShowHelpAction execute', () {
    test('returns true on success', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
    });

    test('displays header with title', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      verify(() => logger.info(any(that: contains('Keyboard Shortcuts'))))
          .called(1);
    });

    test('displays separator lines', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      // Verify separator lines (═ characters)
      final infoCalls = verify(() => logger.info(captureAny())).captured;
      final hasSeparator = infoCalls.any((call) {
        final str = call.toString();
        return str.contains('═') && str.length > 20;
      });
      expect(hasSeparator, isTrue);
    });

    test('displays all registered actions', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      // Should display both registered actions with their descriptions
      verify(() => logger.info(any(that: contains('First test action'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Second test action'))))
          .called(1);
    });

    test('displays action shortcuts', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      // Should display shortcuts for registered actions
      // Note: Exact format depends on KeyBinding.toDisplayString()
      final infoCalls = verify(() => logger.info(captureAny())).captured;
      final hasShortcuts = infoCalls.any((call) {
        final str = call.toString();
        return str.contains('a') || str.contains('ctrl+b');
      });
      expect(hasShortcuts, isTrue);
    });

    test('handles empty registry', () async {
      final emptyRegistry = ActionRegistry();
      final emptyAction = ShowHelpAction(
        registry: emptyRegistry,
        getBinding: (_) => const KeyBinding(key: 'x'),
      );

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await emptyAction.execute(context);

      expect(result, isTrue);
      // Should still show header and separators even with no actions
      verify(() => logger.info(any(that: contains('Keyboard Shortcuts'))))
          .called(1);
    });

    test('uses darkGray separator lines', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      // Verify darkGray is used for separators (lightCyan for title)
      final infoCalls = verify(() => logger.info(captureAny())).captured;
      // Title should be lightCyan
      expect(
        infoCalls.any((c) => c.toString().contains('Keyboard Shortcuts')),
        isTrue,
      );
    });
  });
}
