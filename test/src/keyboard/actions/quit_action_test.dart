import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/quit_action.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockEventCache eventCache;
  late bool quitCalled;
  late QuitAction action;

  setUp(() {
    logger = MockLogger();
    eventCache = MockEventCache();
    quitCalled = false;
    action = QuitAction(
      onQuit: () {
        quitCalled = true;
      },
    );
  });

  group('QuitAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('quit'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Quit'));
    });

    test('has correct description', () {
      expect(action.description, equals('Quit monitoring'));
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('q'));
      expect(binding.ctrl, isFalse);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });

  group('QuitAction execute', () {
    test('returns true on success', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
    });

    test('calls onQuit callback', () async {
      expect(quitCalled, isFalse);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      expect(quitCalled, isTrue);
    });

    test('logs stopping message', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      verify(() => logger.info('')).called(1);
      verify(() => logger.info('Stopping monitoring...')).called(1);
    });

    test('logs empty line before message', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      final calls = verify(() => logger.info(captureAny())).captured;
      // First should be empty, then 'Stopping monitoring...'
      expect(calls[0], equals(''));
      expect(calls[1], equals('Stopping monitoring...'));
    });

    test('calls quit even with events in context', () async {
      final events = [
        createMockAnalyticsEvent(eventName: 'event1'),
        createMockAnalyticsEvent(eventName: 'event2'),
      ];

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: events,
      );

      expect(quitCalled, isFalse);

      await action.execute(context);

      expect(quitCalled, isTrue);
    });

    test('multiple calls invoke quit multiple times', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      var callCount = 0;
      final countingAction = QuitAction(
        onQuit: () {
          callCount++;
        },
      );

      await countingAction.execute(context);
      expect(callCount, equals(1));

      await countingAction.execute(context);
      expect(callCount, equals(2));
    });
  });
}
