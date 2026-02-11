import 'package:famon/src/config/shortcuts_config_loader.dart';
import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/action_registry.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/key_binding.dart';
import 'package:famon/src/keyboard/keyboard_input_interface.dart';
import 'package:famon/src/keyboard/shortcut_manager.dart';
import 'package:famon/src/services/event_cache_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockShortcutsConfigLoader extends Mock implements ShortcutsConfigLoader {}

class MockAction implements ShortcutAction {
  MockAction({
    required this.id,
    this.binding = const KeyBinding(key: 't'),
    this.executeResult = true,
  });

  @override
  final String id;

  final KeyBinding binding;
  final bool executeResult;

  bool wasExecuted = false;

  @override
  String get displayName => 'Mock $id';

  @override
  String get description => 'Mock action: $id';

  @override
  KeyBinding get defaultBinding => binding;

  @override
  Future<bool> execute(ActionContext context) async {
    wasExecuted = true;
    return executeResult;
  }
}

void main() {
  group('ShortcutManager', () {
    late ActionRegistry registry;
    late MockShortcutsConfigLoader configLoader;
    late MockLogger logger;
    late ShortcutManager manager;

    setUp(() {
      registry = ActionRegistry();
      configLoader = MockShortcutsConfigLoader();
      logger = MockLogger();

      when(() => configLoader.loadCustomBindings())
          .thenAnswer((_) async => <String, KeyBinding>{});

      manager = ShortcutManager(
        actionRegistry: registry,
        configLoader: configLoader,
        logger: logger,
      );
    });

    group('getBinding', () {
      test('returns action default binding when no custom binding', () async {
        final action = MockAction(
          id: 'test',
          binding: const KeyBinding(key: 'x'),
        );
        registry.register(action);
        await manager.loadCustomBindings();

        final binding = manager.getBinding('test');
        expect(binding.key, equals('x'));
      });
    });

    group('handleKeyEvent', () {
      test('executes matching action', () async {
        final action = MockAction(
          id: 'test_action',
          binding: const KeyBinding(key: 'q'),
        );
        registry.register(action);
        await manager.loadCustomBindings();

        final context = ActionContext(
          recentEvents: [],
          eventCache: EventCacheService(),
          logger: Logger(),
        );

        const event = KeyInputEvent(key: 'q');
        final result = await manager.handleKeyEvent(event, context);

        expect(result, isTrue);
        expect(action.wasExecuted, isTrue);
      });

      test('returns false when no matching action', () async {
        final action = MockAction(
          id: 'test_action',
          binding: const KeyBinding(key: 'q'),
        );
        registry.register(action);
        await manager.loadCustomBindings();

        final context = ActionContext(
          recentEvents: [],
          eventCache: EventCacheService(),
          logger: Logger(),
        );

        const event = KeyInputEvent(key: 'x');
        final result = await manager.handleKeyEvent(event, context);

        expect(result, isFalse);
        expect(action.wasExecuted, isFalse);
      });

      test('matches key with modifiers', () async {
        final action = MockAction(
          id: 'ctrl_action',
          binding: const KeyBinding(key: 'c', ctrl: true),
        );
        registry.register(action);
        await manager.loadCustomBindings();

        final context = ActionContext(
          recentEvents: [],
          eventCache: EventCacheService(),
          logger: Logger(),
        );

        // Should match with ctrl
        const eventWithCtrl = KeyInputEvent(key: 'c', ctrl: true);
        final result1 = await manager.handleKeyEvent(eventWithCtrl, context);
        expect(result1, isTrue);

        // Reset for next test
        action.wasExecuted = false;

        // Should not match without ctrl
        const eventWithoutCtrl = KeyInputEvent(key: 'c');
        final result2 = await manager.handleKeyEvent(eventWithoutCtrl, context);
        expect(result2, isFalse);
      });
    });

    group('getHelpText', () {
      test('includes all registered actions', () async {
        registry.registerAll([
          MockAction(id: 'action1', binding: const KeyBinding(key: 'a')),
          MockAction(id: 'action2', binding: const KeyBinding(key: 'b')),
        ]);
        await manager.loadCustomBindings();

        final helpText = manager.getHelpText();

        expect(helpText, contains('Keyboard Shortcuts'));
        expect(helpText, contains('Mock action: action1'));
        expect(helpText, contains('Mock action: action2'));
      });
    });

    group('loadCustomBindings', () {
      test('loads bindings from config', () async {
        when(() => configLoader.loadCustomBindings()).thenAnswer(
          (_) async => {
            'test_action': const KeyBinding(key: 'y'),
          },
        );

        final action = MockAction(
          id: 'test_action',
          binding: const KeyBinding(key: 'x'),
        );
        registry.register(action);

        await manager.loadCustomBindings();

        final binding = manager.getBinding('test_action');
        expect(binding.key, equals('y'));
      });

      test('only loads once', () async {
        await manager.loadCustomBindings();
        await manager.loadCustomBindings();
        await manager.loadCustomBindings();

        verify(() => configLoader.loadCustomBindings()).called(1);
      });

      test('handles config loading errors gracefully', () async {
        when(() => configLoader.loadCustomBindings())
            .thenThrow(Exception('Config error'));
        when(() => logger.warn(any())).thenReturn(null);

        await manager.loadCustomBindings();

        verify(() => logger.warn(any())).called(1);
      });
    });
  });
}
