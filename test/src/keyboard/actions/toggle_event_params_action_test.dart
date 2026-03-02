import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/toggle_event_params_action.dart';
import 'package:famon/src/services/interfaces/event_cache_interface.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockEventCache extends Mock implements EventCacheInterface {}

void main() {
  group('ToggleEventParamsAction', () {
    late MockLogger logger;
    late MockEventCache eventCache;
    late bool capturedHideEventParams;
    late ToggleEventParamsAction action;

    setUp(() {
      logger = MockLogger();
      eventCache = MockEventCache();
      capturedHideEventParams = false;
      action = ToggleEventParamsAction(
        onToggle: ({required hideEventParams}) {
          capturedHideEventParams = hideEventParams;
        },
      );
    });

    test('has correct id', () {
      expect(action.id, equals('toggle_event_params'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Toggle Event Params'));
    });

    test('default binding is E key', () {
      expect(action.defaultBinding.key, equals('e'));
      expect(action.defaultBinding.ctrl, isFalse);
      expect(action.defaultBinding.shift, isFalse);
    });

    test('toggles from visible to hidden', () async {
      final context = ActionContext(
        recentEvents: const [],
        eventCache: eventCache,
        logger: logger,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      expect(capturedHideEventParams, isTrue);
      verify(() => logger.info('Event parameters hidden')).called(1);
    });

    test('toggles from hidden to visible', () async {
      final context = ActionContext(
        recentEvents: const [],
        eventCache: eventCache,
        logger: logger,
        hideEventParams: true,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      expect(capturedHideEventParams, isFalse);
      verify(() => logger.info('Event parameters visible')).called(1);
    });
  });
}
