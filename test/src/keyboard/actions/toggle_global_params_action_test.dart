import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/toggle_global_params_action.dart';
import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockEventCache extends Mock implements EventCacheInterface {}

void main() {
  group('ToggleGlobalParamsAction', () {
    late MockLogger logger;
    late MockEventCache eventCache;
    late bool capturedHideGlobalParams;
    late ToggleGlobalParamsAction action;

    setUp(() {
      logger = MockLogger();
      eventCache = MockEventCache();
      capturedHideGlobalParams = false;
      action = ToggleGlobalParamsAction(
        onToggle: ({required hideGlobalParams}) {
          capturedHideGlobalParams = hideGlobalParams;
        },
      );
    });

    test('has correct id', () {
      expect(action.id, equals('toggle_global_params'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Toggle Global Params'));
    });

    test('default binding is G key', () {
      expect(action.defaultBinding.key, equals('g'));
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
      expect(capturedHideGlobalParams, isTrue);
      verify(() => logger.info('Global parameters hidden')).called(1);
    });

    test('toggles from hidden to visible', () async {
      final context = ActionContext(
        recentEvents: const [],
        eventCache: eventCache,
        logger: logger,
        hideGlobalParams: true,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      expect(capturedHideGlobalParams, isFalse);
      verify(() => logger.info('Global parameters visible')).called(1);
    });
  });
}
