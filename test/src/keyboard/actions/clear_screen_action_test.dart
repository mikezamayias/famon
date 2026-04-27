import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/clear_screen_action.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockEventCache eventCache;
  late ClearScreenAction action;

  setUp(() {
    logger = MockLogger();
    eventCache = MockEventCache();
    action = ClearScreenAction();
  });

  group('ClearScreenAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('clear_screen'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Clear Screen'));
    });

    test('has correct description', () {
      expect(action.description, equals('Clear terminal output'));
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('l'));
      expect(binding.ctrl, isTrue);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });

  group('ClearScreenAction execute', () {
    test('returns true on success', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
    });

    test('logs monitoring message', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      verify(() => logger.info('Monitoring Firebase Analytics events...'))
          .called(1);
    });

    test('logs help message with Q key', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      verify(() => logger.info('Press ? for help, Q to quit')).called(1);
    });

    test('logs empty line after help', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      final infoCalls = verify(() => logger.info(captureAny())).captured;
      // Should have 3 info calls: monitoring message, help text, empty line
      expect(infoCalls.length, equals(3));
    });

    test('executes without errors with events in context', () async {
      final events = [
        createMockAnalyticsEvent(eventName: 'event1'),
        createMockAnalyticsEvent(eventName: 'event2'),
      ];

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: events,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      // Verify the basic messages are logged regardless of events
      verify(() => logger.info('Monitoring Firebase Analytics events...'))
          .called(1);
    });

    // Note: Testing ANSI escape codes (stdout.write) would require
    // capturing stdout which is complex in unit tests. The functionality
    // is covered by integration tests.
  });
}
