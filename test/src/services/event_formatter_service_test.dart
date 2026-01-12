import 'package:firebase_analytics_monitor/src/constants.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/services/event_formatter_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('EventFormatterService', () {
    late MockLogger mockLogger;
    late EventFormatterService formatter;

    setUp(() {
      mockLogger = MockLogger();
      formatter = EventFormatterService(mockLogger, colorEnabled: false)
        ..resetTracking();
    });

    group('formatAndPrint', () {
      test('prints formatted event with header and parameters', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'screen_view',
          parameters: const {
            'screen_name': 'HomeScreen',
            'screen_class': 'HomeActivity',
          },
        );

        formatter.formatAndPrint(event);

        verify(() => mockLogger.info('[01-13 14:30:45.123] screen_view'))
            .called(1);
        verify(() => mockLogger.info('  Parameters:')).called(1);
        verify(() => mockLogger.info('    screen_name: HomeScreen')).called(1);
        verify(() => mockLogger.info('    screen_class: HomeActivity'))
            .called(1);
        verify(() => mockLogger.info('')).called(1);
      });

      test('prints event with items correctly', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'view_item_list',
          parameters: const {'item_list_name': 'Products'},
          items: const [
            {'item_id': 'SKU001', 'item_name': 'Product 1'},
            {'item_id': 'SKU002', 'item_name': 'Product 2'},
          ],
        );

        formatter.formatAndPrint(event);

        verify(() => mockLogger.info('[01-13 14:30:45.123] view_item_list'))
            .called(1);
        verify(() => mockLogger.info('  Parameters:')).called(1);
        verify(() => mockLogger.info('    item_list_name: Products')).called(1);
        verify(() => mockLogger.info('  Items:')).called(1);
        verify(() => mockLogger.info('    Item 1:')).called(1);
        verify(() => mockLogger.info('      item_id: SKU001')).called(1);
        verify(() => mockLogger.info('      item_name: Product 1')).called(1);
        verify(() => mockLogger.info('    Item 2:')).called(1);
        verify(() => mockLogger.info('      item_id: SKU002')).called(1);
        verify(() => mockLogger.info('      item_name: Product 2')).called(1);
      });

      test('prints event without parameters section when empty', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'app_open',
        );

        formatter.formatAndPrint(event);

        verify(() => mockLogger.info('[01-13 14:30:45.123] app_open'))
            .called(1);
        verifyNever(() => mockLogger.info('  Parameters:'));
        verify(() => mockLogger.info('')).called(1);
      });

      test('uses displayTimestamp when rawTimestamp is null', () {
        final event = AnalyticsEvent(
          id: 'test_id',
          timestamp: DateTime(2026, 1, 13, 14, 30, 45, 123),
          eventName: 'custom_event',
          parameters: const {},
          items: const [],
        );

        formatter.formatAndPrint(event);

        // displayTimestamp returns substring of timestamp when rawTimestamp
        // is null
        verify(() => mockLogger.info(any(that: contains('custom_event'))))
            .called(1);
      });
    });

    group('FA warning buffering', () {
      test('buffers fa_invalid_default_param events', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'invalid_param': 'value1'},
        );

        formatter.formatAndPrint(event);

        // Should not print immediately - verify no logger calls yet
        verifyNever(
          () => mockLogger.info(any(that: contains('invalid_param'))),
        );
      });

      test('flushes FA warning buffer when normal event arrives', () {
        final faEvent = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'invalid_param': 'bad_value'},
        );

        final normalEvent = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:46.000',
          eventName: 'screen_view',
        );

        formatter
          ..formatAndPrint(faEvent)
          ..formatAndPrint(normalEvent);

        // FA warning should be flushed and printed
        verify(
          () => mockLogger.info('  Invalid default parameters:'),
        ).called(1);
        verify(
          () => mockLogger.info('    invalid_param: bad_value'),
        ).called(1);

        // Then normal event should print
        verify(() => mockLogger.info('[01-13 14:30:46.000] screen_view'))
            .called(1);
      });

      test('groups multiple FA warnings within threshold', () {
        final event1 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param1': 'value1'},
        );

        final event2 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.200',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param2': 'value2'},
        );

        formatter
          ..formatAndPrint(event1)
          ..formatAndPrint(event2)
          ..flushPending();

        // Both params should be in a single grouped output
        verify(() => mockLogger.info('    param1: value1')).called(1);
        verify(() => mockLogger.info('    param2: value2')).called(1);
        // Only one "Invalid default parameters:" header
        verify(
          () => mockLogger.info('  Invalid default parameters:'),
        ).called(1);
      });

      test('creates new group when FA warnings exceed threshold gap', () {
        // Use a gap larger than faWarningGroupingThresholdMs (500ms)
        final event1 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param1': 'value1'},
        );

        final event2 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:46.000', // 900ms later, > 500ms threshold
          eventName: 'fa_invalid_default_param',
          parameters: const {'param2': 'value2'},
        );

        formatter
          ..formatAndPrint(event1)
          ..formatAndPrint(event2)
          ..flushPending();

        // Should have two separate groups (two headers)
        verify(
          () => mockLogger.info('  Invalid default parameters:'),
        ).called(2);
      });

      test('shows time range for grouped FA warnings', () {
        final event1 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param1': 'value1'},
        );

        final event2 = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.200',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param2': 'value2'},
        );

        formatter
          ..formatAndPrint(event1)
          ..formatAndPrint(event2)
          ..flushPending();

        // Header should contain time range
        verify(
          () => mockLogger.info(
            any(
              that: allOf(
                contains('01-13 14:30:45.100'),
                contains('01-13 14:30:45.200'),
              ),
            ),
          ),
        ).called(1);
      });

      test('shows single timestamp for single FA warning', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param1': 'value1'},
        );

        formatter
          ..formatAndPrint(event)
          ..flushPending();

        // Header should contain single timestamp (not a range)
        verify(
          () => mockLogger
              .info('[01-13 14:30:45.100] fa_invalid_default_param'),
        ).called(1);
      });
    });

    group('flushPending', () {
      test('flushes buffered FA warnings', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'test_param': 'test_value'},
        );

        formatter
          ..formatAndPrint(event)
          ..flushPending();

        verify(
          () => mockLogger.info('  Invalid default parameters:'),
        ).called(1);
        verify(() => mockLogger.info('    test_param: test_value')).called(1);
      });

      test('does nothing when buffer is empty', () {
        formatter.flushPending();

        verifyNever(() => mockLogger.info(any()));
      });
    });

    group('resetTracking', () {
      test('clears buffered FA warnings', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.100',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param': 'value'},
        );

        formatter
          ..formatAndPrint(event)
          ..resetTracking()
          ..flushPending();

        // After reset, flush should do nothing
        verifyNever(() => mockLogger.info(any(that: contains('param'))));
      });
    });

    group('raw output mode', () {
      test('prints event in raw format', () {
        final rawFormatter = EventFormatterService(
          mockLogger,
          rawOutput: true,
          colorEnabled: false,
        );

        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'button_click',
          parameters: const {'button_id': 'submit'},
        );

        rawFormatter.formatAndPrint(event);

        verify(
          () => mockLogger.info(
            '01-13 14:30:45.123 | button_click | {button_id: submit}',
          ),
        ).called(1);
      });

      test('prints event with empty parameters in raw format', () {
        final rawFormatter = EventFormatterService(
          mockLogger,
          rawOutput: true,
          colorEnabled: false,
        );

        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'app_open',
        );

        rawFormatter.formatAndPrint(event);

        verify(
          () => mockLogger.info('01-13 14:30:45.123 | app_open | {}'),
        ).called(1);
      });
    });

    group('color enabled mode', () {
      test('applies color to event name when enabled', () {
        final colorFormatter = EventFormatterService(mockLogger);

        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'test_event',
          parameters: const {'key': 'value'},
        );

        colorFormatter.formatAndPrint(event);

        // Verify that colored output contains ANSI escape codes
        verify(
          () => mockLogger.info(
            any(
              that: allOf(
                contains('[01-13 14:30:45.123]'),
                contains('test_event'),
              ),
            ),
          ),
        ).called(1);
      });

      test('applies darkGray color to parameters when enabled', () {
        final colorFormatter = EventFormatterService(mockLogger);

        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'test_event',
          parameters: const {'param_key': 'param_value'},
        );

        colorFormatter.formatAndPrint(event);

        // Verify parameters are printed (with potential ANSI codes)
        verify(
          () => mockLogger.info(
            any(that: contains('param_key: param_value')),
          ),
        ).called(1);
      });
    });

    group('printStats', () {
      test('prints session statistics', () {
        final stats = <String, dynamic>{
          'totalEvents': 100,
          'uniqueEventTypes': 15,
          'topEvents': <String, int>{
            'screen_view': 50,
            'button_click': 30,
            'page_view': 20,
          },
        };

        formatter.printStats(stats);

        verify(
          () => mockLogger.info(any(that: contains('Session Statistics'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Total Events: 100'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Unique Event Types: 15'))),
        ).called(1);
        verify(() => mockLogger.info(any(that: contains('Top Events'))))
            .called(1);
        verify(
          () => mockLogger.info(any(that: contains('screen_view: 50'))),
        ).called(1);
      });

      test('handles missing stats values with defaults', () {
        final stats = <String, dynamic>{};

        formatter.printStats(stats);

        verify(
          () => mockLogger.info(any(that: contains('Total Events: 0'))),
        ).called(1);
        verify(
          () => mockLogger.info(any(that: contains('Unique Event Types: 0'))),
        ).called(1);
      });

      test('limits top events to statsTopEventsLimit', () {
        final topEvents = <String, int>{};
        for (var i = 0; i < 15; i++) {
          topEvents['event_$i'] = 100 - i;
        }

        final stats = <String, dynamic>{
          'totalEvents': 500,
          'uniqueEventTypes': 15,
          'topEvents': topEvents,
        };

        formatter.printStats(stats);

        // Should only print statsTopEventsLimit (10) events
        // Count calls that contain "occurrences"
        verify(
          () => mockLogger.info(any(that: contains('occurrences'))),
        ).called(statsTopEventsLimit);
      });

      test('handles null topEvents', () {
        final stats = <String, dynamic>{
          'totalEvents': 50,
          'uniqueEventTypes': 5,
          'topEvents': null,
        };

        formatter.printStats(stats);

        verify(
          () => mockLogger.info(any(that: contains('Total Events: 50'))),
        ).called(1);
        // Should not print Top Events section
        verifyNever(() => mockLogger.info(any(that: contains('Top Events'))));
      });

      test('handles empty topEvents', () {
        final stats = <String, dynamic>{
          'totalEvents': 50,
          'uniqueEventTypes': 5,
          'topEvents': <String, int>{},
        };

        formatter.printStats(stats);

        verify(
          () => mockLogger.info(any(that: contains('Total Events: 50'))),
        ).called(1);
        // Should not print Top Events section when empty
        verifyNever(() => mockLogger.info(any(that: contains('Top Events'))));
      });
    });

    group('printError', () {
      test('prints error message with icon', () {
        formatter.printError('Something went wrong');

        verify(
          () => mockLogger.err(any(that: contains('Something went wrong'))),
        ).called(1);
      });
    });

    group('printSuccess', () {
      test('prints success message with icon', () {
        formatter.printSuccess('Operation completed');

        verify(
          () => mockLogger.success(any(that: contains('Operation completed'))),
        ).called(1);
      });
    });

    group('printInfo', () {
      test('prints info message with icon', () {
        formatter.printInfo('Information message');

        verify(
          () => mockLogger.info(any(that: contains('Information message'))),
        ).called(1);
      });
    });

    group('printWarning', () {
      test('prints warning message with icon', () {
        formatter.printWarning('Warning message');

        verify(() => mockLogger.warn(any(that: contains('Warning message'))))
            .called(1);
      });
    });

    group('edge cases', () {
      test('handles event with special characters in parameters', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'test_event',
          parameters: const {
            'message': 'Hello "World"',
            'path': '/users/test@example.com',
            'query': 'foo=bar&baz=qux',
          },
        );

        formatter.formatAndPrint(event);

        verify(() => mockLogger.info('    message: Hello "World"')).called(1);
        verify(() => mockLogger.info('    path: /users/test@example.com'))
            .called(1);
        verify(() => mockLogger.info('    query: foo=bar&baz=qux')).called(1);
      });

      test('handles event with very long parameter values', () {
        final longValue = 'a' * 1000;
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'test_event',
          parameters: {'long_param': longValue},
        );

        formatter.formatAndPrint(event);

        verify(
          () => mockLogger.info(any(that: contains(longValue))),
        ).called(1);
      });

      test('handles event with unicode characters', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'test_event',
          parameters: const {
            'emoji': 'Hello! Some string',
            'chinese': 'Chinese characters',
            'arabic': 'Arabic text',
          },
        );

        formatter.formatAndPrint(event);

        verify(
          () => mockLogger.info('    emoji: Hello! Some string'),
        ).called(1);
        verify(() => mockLogger.info('    chinese: Chinese characters'))
            .called(1);
        verify(() => mockLogger.info('    arabic: Arabic text')).called(1);
      });

      test('handles malformed timestamp gracefully', () {
        // Create event with invalid timestamp format that parser cannot parse
        final event = AnalyticsEvent(
          id: 'test_id',
          timestamp: DateTime.now(),
          rawTimestamp: 'invalid-timestamp',
          eventName: 'test_event',
          parameters: const {},
          items: const [],
        );

        // Should not throw
        expect(() => formatter.formatAndPrint(event), returnsNormally);

        // Uses the raw timestamp as-is in display
        verify(() => mockLogger.info('[invalid-timestamp] test_event'))
            .called(1);
      });

      test('handles FA warning with malformed timestamp', () {
        final event = AnalyticsEvent(
          id: 'test_id',
          timestamp: DateTime.now(),
          rawTimestamp: 'bad-timestamp',
          eventName: 'fa_invalid_default_param',
          parameters: const {'param': 'value'},
          items: const [],
        );

        // Should not throw
        expect(() => formatter.formatAndPrint(event), returnsNormally);

        formatter.flushPending();

        // Should still output the warning with the bad timestamp
        verify(() => mockLogger.info(any(that: contains('bad-timestamp'))))
            .called(1);
      });

      test('handles multiple items with varying keys', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 14:30:45.123',
          eventName: 'purchase',
          parameters: const {'transaction_id': 'T123'},
          items: const [
            {'item_id': 'A', 'quantity': '1'},
            {'item_id': 'B', 'price': '10.00', 'currency': 'USD'},
            {'item_id': 'C'},
          ],
        );

        formatter.formatAndPrint(event);

        verify(() => mockLogger.info('    Item 1:')).called(1);
        verify(() => mockLogger.info('      item_id: A')).called(1);
        verify(() => mockLogger.info('      quantity: 1')).called(1);
        verify(() => mockLogger.info('    Item 2:')).called(1);
        verify(() => mockLogger.info('      item_id: B')).called(1);
        verify(() => mockLogger.info('      price: 10.00')).called(1);
        verify(() => mockLogger.info('      currency: USD')).called(1);
        verify(() => mockLogger.info('    Item 3:')).called(1);
        verify(() => mockLogger.info('      item_id: C')).called(1);
      });
    });
  });
}
