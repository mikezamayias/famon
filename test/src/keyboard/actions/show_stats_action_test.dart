import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/show_stats_action.dart';
import 'package:famon_core/famon_core.dart';
import 'package:famon_core/src/models/session_stats.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockEventCache eventCache;
  late ShowStatsAction action;

  setUp(() {
    logger = MockLogger();
    eventCache = MockEventCache();
    action = ShowStatsAction();
  });

  group('ShowStatsAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('show_stats'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Show Statistics'));
    });

    test('has correct description', () {
      expect(action.description, equals('Display session statistics'));
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('i'));
      expect(binding.ctrl, isTrue);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });

  group('ShowStatsAction execute', () {
    test('displays statistics with empty session', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(
          totalUniqueEvents: 0,
          totalEventOccurrences: 0,
        ),
      );
      when(() => eventCache.getTopEvents(any())).thenReturn([]);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info('')).called(greaterThanOrEqualTo(1));
      verify(() => logger.info(any(that: contains('Session Statistics'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Unique Events: 0'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Total Events:  0'))))
          .called(1);
    });

    test('displays statistics with events', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(
          totalUniqueEvents: 5,
          totalEventOccurrences: 100,
          mostFrequentEvent: 'screen_view',
        ),
      );
      when(() => eventCache.getTopEvents(5)).thenReturn([
        'screen_view',
        'user_engagement',
        'app_open',
        'purchase',
        'login',
      ]);
      when(() => eventCache.getEventCount('screen_view')).thenReturn(50);
      when(() => eventCache.getEventCount('user_engagement')).thenReturn(30);
      when(() => eventCache.getEventCount('app_open')).thenReturn(10);
      when(() => eventCache.getEventCount('purchase')).thenReturn(5);
      when(() => eventCache.getEventCount('login')).thenReturn(5);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info(any(that: contains('Session Statistics'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Unique Events: 5'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Total Events:  100'))))
          .called(1);
      verify(() => logger.info(any(that: contains('Most Frequent Events:'))))
          .called(1);
    });

    test('displays top events with counts', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(
          totalUniqueEvents: 3,
          totalEventOccurrences: 25,
        ),
      );
      when(() => eventCache.getTopEvents(5)).thenReturn([
        'event_a',
        'event_b',
        'event_c',
      ]);
      when(() => eventCache.getEventCount('event_a')).thenReturn(15);
      when(() => eventCache.getEventCount('event_b')).thenReturn(7);
      when(() => eventCache.getEventCount('event_c')).thenReturn(3);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info(any(that: contains('event_a')))).called(1);
      verify(() => logger.info(any(that: contains('event_b')))).called(1);
      verify(() => logger.info(any(that: contains('event_c')))).called(1);
    });

    test('uses darkGray separator line', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(totalUniqueEvents: 0, totalEventOccurrences: 0),
      );
      when(() => eventCache.getTopEvents(any())).thenReturn([]);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      // Verify separator lines are logged (darkGray wrapped '─' characters)
      final infoCalls = verify(() => logger.info(captureAny())).captured;
      final hasSeparator = infoCalls.any((call) {
        final str = call.toString();
        return str.contains('─') && str.length > 20;
      });
      expect(hasSeparator, isTrue);
    });

    test('requests correct number of top events', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(totalUniqueEvents: 0, totalEventOccurrences: 0),
      );
      when(() => eventCache.getTopEvents(5)).thenReturn([]);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      await action.execute(context);

      verify(() => eventCache.getTopEvents(5)).called(1);
    });

    test('handles single event type', () async {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(
          totalUniqueEvents: 1,
          totalEventOccurrences: 10,
          mostFrequentEvent: 'only_event',
        ),
      );
      when(() => eventCache.getTopEvents(5)).thenReturn(['only_event']);
      when(() => eventCache.getEventCount('only_event')).thenReturn(10);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info(any(that: contains('only_event')))).called(1);
      verify(() => logger.info(any(that: contains('10')))).called(1);
    });
  });
}
