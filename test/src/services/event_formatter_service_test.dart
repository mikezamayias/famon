import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/services/event_formatter_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

AnalyticsEvent _makeEvent({
  Map<String, String> parameters = const {},
  List<Map<String, String>> items = const [],
}) {
  return AnalyticsEvent(
    id: 'test_id',
    timestamp: DateTime(2026),
    rawTimestamp: '01-01 00:00:00.000',
    eventName: 'test_event',
    parameters: parameters,
    items: items,
  );
}

void main() {
  late Logger logger;

  setUp(() {
    logger = _MockLogger();
    when(() => logger.info(any())).thenReturn(null);
  });

  group('showOnlyParamNames', () {
    test('shows all params when filter is empty', () {
      final formatter = EventFormatterService(logger);
      final event = _makeEvent(
        parameters: {'screen_name': 'home', 'currency': 'USD'},
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info(any(that: contains('screen_name')))).called(1);
      verify(() => logger.info(any(that: contains('currency')))).called(1);
    });

    test('shows only matching param keys', () {
      final formatter = EventFormatterService(
        logger,
        showOnlyParamNames: {'currency'},
      );
      final event = _makeEvent(
        parameters: {'screen_name': 'home', 'currency': 'USD'},
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info(any(that: contains('currency')))).called(1);
      verifyNever(() => logger.info(any(that: contains('screen_name'))));
    });

    test('filters item keys too', () {
      final formatter = EventFormatterService(
        logger,
        showOnlyParamNames: {'item_name'},
      );
      final event = _makeEvent(
        items: [
          {'item_name': 'shirt', 'price': '29.99'},
        ],
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info(any(that: contains('item_name')))).called(1);
      verifyNever(() => logger.info(any(that: contains('price'))));
    });

    test('skips empty items after filtering', () {
      final formatter = EventFormatterService(
        logger,
        showOnlyParamNames: {'currency'},
      );
      final event = _makeEvent(
        parameters: {'currency': 'USD'},
        items: [
          {'item_name': 'shirt', 'price': '29.99'},
        ],
      );

      formatter.formatAndPrint(event);

      // Item has no matching keys, so "Item 1:" should not appear
      verifyNever(() => logger.info(any(that: contains('Item 1'))));
    });

    test('works in raw mode', () {
      final formatter = EventFormatterService(
        logger,
        rawOutput: true,
        showOnlyParamNames: {'currency'},
      );
      final event = _makeEvent(
        parameters: {'screen_name': 'home', 'currency': 'USD'},
      );

      formatter.formatAndPrint(event);

      final captured = verify(() => logger.info(captureAny())).captured;
      final rawLine = captured.last as String;
      expect(rawLine, contains('currency'));
      expect(rawLine, isNot(contains('screen_name')));
    });

    test('composes with global param separation', () {
      final formatter = EventFormatterService(
        logger,
        globalParamNames: {'session_id', 'currency'},
        showOnlyParamNames: {'currency', 'item_name'},
      );
      final event = _makeEvent(
        parameters: {
          'session_id': '123',
          'currency': 'USD',
          'item_name': 'shirt',
          'screen_name': 'home',
        },
      );

      formatter.formatAndPrint(event);

      // currency is global + allowed, item_name is event + allowed
      verify(() => logger.info(any(that: contains('currency')))).called(1);
      verify(() => logger.info(any(that: contains('item_name')))).called(1);
      // session_id is global but not in show-only, screen_name is neither
      verifyNever(() => logger.info(any(that: contains('session_id'))));
      verifyNever(() => logger.info(any(that: contains('screen_name'))));
    });

    test('returns empty params when no keys match', () {
      final formatter = EventFormatterService(
        logger,
        showOnlyParamNames: {'nonexistent'},
      );
      final event = _makeEvent(
        parameters: {'screen_name': 'home'},
      );

      formatter.formatAndPrint(event);

      verifyNever(() => logger.info(any(that: contains('screen_name'))));
      // "Parameters:" header should not appear for empty map
      verifyNever(() => logger.info(any(that: contains('Parameters:'))));
    });
  });
}
