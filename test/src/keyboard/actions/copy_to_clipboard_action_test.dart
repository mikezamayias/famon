import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/copy_to_clipboard_action.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockClipboardInterface clipboard;
  late MockEventCache eventCache;
  late CopyToClipboardAction action;

  setUp(() {
    logger = MockLogger();
    clipboard = MockClipboardInterface();
    eventCache = MockEventCache();
    action = CopyToClipboardAction(clipboard: clipboard);
  });

  group('CopyToClipboardAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('copy_to_clipboard'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Copy to Clipboard'));
    });

    test('has correct description', () {
      expect(
        action.description,
        equals('Copy recent events to clipboard as JSON'),
      );
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('s'));
      expect(binding.ctrl, isTrue);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });

  group('CopyToClipboardAction execute', () {
    test('returns false when clipboard not supported', () async {
      when(() => clipboard.isSupported).thenReturn(false);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isFalse);
      verify(() => logger.warn('Clipboard not supported on this platform'))
          .called(1);
    });

    test('returns true when no events to copy', () async {
      when(() => clipboard.isSupported).thenReturn(true);

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info('No events to copy')).called(1);
    });

    test('copies single event to clipboard', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

      final event = createMockAnalyticsEvent(
        parameters: {'param1': 'value1'},
      );

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.success('Copied 1 events to clipboard')).called(1);

      // Verify clipboard was called with JSON
      final captured =
          verify(() => clipboard.copy(captureAny())).captured.single as String;
      expect(captured, contains('test_event'));
      expect(captured, contains('param1'));
      expect(captured, contains('value1'));
    });

    test('copies multiple events to clipboard', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

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
      verify(() => logger.success('Copied 2 events to clipboard')).called(1);
    });

    test('respects eventCountToExport limit', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

      final events = [
        createMockAnalyticsEvent(eventName: 'event1'),
        createMockAnalyticsEvent(eventName: 'event2'),
        createMockAnalyticsEvent(eventName: 'event3'),
        createMockAnalyticsEvent(eventName: 'event4'),
        createMockAnalyticsEvent(eventName: 'event5'),
      ];

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: events,
        eventCountToExport: 3,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      // Should only copy last 3 events (event3, event4, event5)
      verify(() => logger.success('Copied 3 events to clipboard')).called(1);
    });

    test('includes items in JSON output when present', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

      final event = createMockAnalyticsEvent(
        eventName: 'purchase',
        items: [
          {'item_id': '123', 'price': '9.99'},
        ],
      );

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      final captured =
          verify(() => clipboard.copy(captureAny())).captured.single as String;
      expect(captured, contains('items'));
      expect(captured, contains('item_id'));
      expect(captured, contains('9.99'));
    });

    test('returns false when clipboard copy fails', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => false);

      final event = createMockAnalyticsEvent();

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isFalse);
      verify(() => logger.err('Failed to copy to clipboard')).called(1);
    });

    test('uses all events when count exceeds available', () async {
      when(() => clipboard.isSupported).thenReturn(true);
      when(() => clipboard.copy(any())).thenAnswer((_) async => true);

      final events = [
        createMockAnalyticsEvent(eventName: 'event1'),
        createMockAnalyticsEvent(eventName: 'event2'),
      ];

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: events,
        eventCountToExport: 100, // More than available
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      // Should copy both events since only 2 available
      verify(() => logger.success('Copied 2 events to clipboard')).called(1);
    });
  });
}
