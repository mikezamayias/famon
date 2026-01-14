import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:firebase_analytics_monitor/src/cli/commands/filtered_monitor_command.dart';
import 'package:firebase_analytics_monitor/src/core/application/services/event_filter_service.dart';
import 'package:firebase_analytics_monitor/src/core/domain/entities/analytics_event.dart';
import 'package:firebase_analytics_monitor/src/core/domain/repositories/event_repository.dart';
import 'package:firebase_analytics_monitor/src/core/domain/value_objects/event_statistics.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/utils/event_filter_utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockLogParser extends Mock implements LogParserInterface {}

class MockEventFilterService extends Mock implements EventFilterService {}

class MockEventRepository extends Mock implements EventRepository {}

class MockProcess extends Mock implements Process {}

class FakeAnalyticsEvent extends Fake implements AnalyticsEvent {}

class FakeProcessSignal extends Fake implements ProcessSignal {}

void main() {
  group('FilteredMonitorCommand', () {
    late MockLogger mockLogger;
    late MockProcessManager mockProcessManager;
    late MockLogParser mockLogParser;
    late MockEventFilterService mockFilterService;
    late MockEventRepository mockEventRepository;
    late FilteredMonitorCommand command;
    late CommandRunner<int> runner;

    setUpAll(() {
      registerFallbackValue(FakeAnalyticsEvent());
      registerFallbackValue(FakeProcessSignal());
    });

    setUp(() {
      mockLogger = MockLogger();
      mockProcessManager = MockProcessManager();
      mockLogParser = MockLogParser();
      mockFilterService = MockEventFilterService();
      mockEventRepository = MockEventRepository();

      // Set up default logger behavior
      when(() => mockLogger.info(any())).thenReturn(null);
      when(() => mockLogger.err(any())).thenReturn(null);
      when(() => mockLogger.detail(any())).thenReturn(null);
      when(() => mockLogger.write(any())).thenReturn(null);

      final dependencies = FilteredMonitorDependencies(
        logger: mockLogger,
        processManager: mockProcessManager,
        logParser: mockLogParser,
        filterService: mockFilterService,
        eventRepository: mockEventRepository,
      );
      command = FilteredMonitorCommand(dependencies);

      runner = CommandRunner<int>('famon', 'Firebase Analytics Monitor')
        ..addCommand(command);
    });

    group('command metadata', () {
      test('should have correct name', () {
        expect(command.name, equals('filter'));
      });

      test('should have correct description', () {
        expect(
          command.description,
          contains('advanced filtering'),
        );
      });
    });

    group('argument parsing', () {
      test('should parse hide option', () {
        final argParser = command.argParser;
        final results =
            argParser.parse(['--hide', 'screen_view', '--hide', '_vs']);

        expect(results['hide'], equals(['screen_view', '_vs']));
      });

      test('should parse show-only option with abbreviation', () {
        final argParser = command.argParser;
        final results =
            argParser.parse(['-s', 'purchase', '-s', 'add_to_cart']);

        expect(results['show-only'], equals(['purchase', 'add_to_cart']));
      });

      test('should parse min-frequency option', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--min-frequency', '5']);

        expect(results['min-frequency'], equals('5'));
      });

      test('should parse max-frequency option', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--max-frequency', '100']);

        expect(results['max-frequency'], equals('100'));
      });

      test('should parse limit option with abbreviation', () {
        final argParser = command.argParser;
        final results = argParser.parse(['-l', '50']);

        expect(results['limit'], equals('50'));
      });

      test('should parse from-date option', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--from-date', '2024-01-01']);

        expect(results['from-date'], equals('2024-01-01'));
      });

      test('should parse to-date option', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--to-date', '2024-12-31']);

        expect(results['to-date'], equals('2024-12-31'));
      });

      test('should parse add-param option', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--add-param',
          'purchase:test_mode:true',
          '--add-param',
          'screen_view:debug:enabled',
        ]);

        expect(
          results['add-param'],
          equals(['purchase:test_mode:true', 'screen_view:debug:enabled']),
        );
      });

      test('should parse persist flag', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--persist']);

        expect(results['persist'], isTrue);
      });

      test('should parse stats-only flag', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--stats-only']);

        expect(results['stats-only'], isTrue);
      });

      test('should parse no-color flag', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--no-color']);

        expect(results['no-color'], isTrue);
      });

      test('should parse raw flag with abbreviation', () {
        final argParser = command.argParser;
        final results = argParser.parse(['-r']);

        expect(results['raw'], isTrue);
      });

      test('should handle multiple options together', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--hide',
          'screen_view',
          '-s',
          'purchase',
          '--min-frequency',
          '10',
          '--max-frequency',
          '100',
          '-l',
          '50',
          '--persist',
          '--no-color',
        ]);

        expect(results['hide'], equals(['screen_view']));
        expect(results['show-only'], equals(['purchase']));
        expect(results['min-frequency'], equals('10'));
        expect(results['max-frequency'], equals('100'));
        expect(results['limit'], equals('50'));
        expect(results['persist'], isTrue);
        expect(results['no-color'], isTrue);
      });
    });

    group('stats-only mode', () {
      test('should display statistics and return 0 on success', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 10,
          topEvents: {
            'screen_view': 50,
            'purchase': 30,
            'add_to_cart': 20,
          },
          dateRange: DateTimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 12, 31),
          ),
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => ['screen_view']);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => ['rare_event']);

        final result = await runner.run(['filter', '--stats-only']);

        expect(result, equals(0));
        verify(() => mockLogger.info(any(that: contains('Statistics'))))
            .called(greaterThan(0));
      });

      test('should filter stats by date range', () async {
        final stats = EventStatistics(
          totalEvents: 50,
          uniqueEventTypes: 5,
          topEvents: const {'purchase': 50},
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => []);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => []);

        await runner.run([
          'filter',
          '--stats-only',
          '--from-date',
          '2024-06-01',
          '--to-date',
          '2024-06-30',
        ]);

        verify(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).called(1);
      });

      test('should return 1 on statistics error', () async {
        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenThrow(Exception('Database error'));

        final result = await runner.run(['filter', '--stats-only']);

        expect(result, equals(1));
        verify(() => mockLogger.err(any(that: contains('Failed')))).called(1);
      });

      test('should apply hide filter to top events in stats', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 3,
          topEvents: const {
            'screen_view': 50,
            'purchase': 30,
            '_vs': 20,
          },
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => []);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => []);

        await runner.run(['filter', '--stats-only', '--hide', 'screen_view']);

        // Verify logger was called but screen_view should be hidden
        verify(() => mockLogger.info(any())).called(greaterThan(0));
      });

      test('should apply frequency filters to stats', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 3,
          topEvents: const {
            'high_freq': 200,
            'mid_freq': 50,
            'low_freq': 5,
          },
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        // With frequency filters, suggestions should not be shown
        await runner.run([
          'filter',
          '--stats-only',
          '--min-frequency',
          '10',
          '--max-frequency',
          '100',
        ]);

        // Verify that high frequency and low frequency suggestions
        // are not called when frequency filters are applied
        verifyNever(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        );
        verifyNever(() => mockFilterService.getLowFrequencyEvents());
      });

      test('should show suggestions when no frequency filters', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 3,
          topEvents: const {
            'screen_view': 50,
            'purchase': 30,
          },
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => ['screen_view', 'spam_event']);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => ['rare_event']);

        await runner.run(['filter', '--stats-only']);

        verify(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).called(1);
        verify(() => mockFilterService.getLowFrequencyEvents()).called(1);
      });

      test('should handle empty statistics', () async {
        final stats = EventStatistics(
          totalEvents: 0,
          uniqueEventTypes: 0,
          topEvents: const <String, int>{},
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => <String>[]);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => <String>[]);

        final result = await runner.run(['filter', '--stats-only']);

        expect(result, equals(0));
        verify(
          () => mockLogger.info(any(that: contains('Total Events: 0'))),
        ).called(1);
      });
    });

    group('adb error handling', () {
      test('should display helpful message when adb fails', () async {
        when(
          () => mockProcessManager.start(any()),
        ).thenThrow(const ProcessException('adb', [], 'adb: not found'));

        final result = await runner.run(['filter']);

        expect(result, equals(1));
        verify(
          () => mockLogger.err(any(that: contains('Failed to start adb'))),
        ).called(1);
        verify(() => mockLogger.info(any(that: contains('Android SDK'))))
            .called(greaterThan(0));
      });

      test('should handle unexpected errors gracefully', () async {
        when(
          () => mockProcessManager.start(any()),
        ).thenThrow(Exception('Unexpected error'));

        final result = await runner.run(['filter']);

        expect(result, equals(1));
        verify(() => mockLogger.err(any(that: contains('Unexpected error'))))
            .called(1);
      });
    });

    group('EventFilterUtils integration', () {
      test('should skip events with hide filter', () {
        expect(
          EventFilterUtils.shouldSkipEvent(
            'screen_view',
            <String>['screen_view', '_vs'],
            <String>[],
          ),
          isTrue,
        );

        expect(
          EventFilterUtils.shouldSkipEvent(
            'purchase',
            <String>['screen_view', '_vs'],
            <String>[],
          ),
          isFalse,
        );
      });

      test('should only show events with show-only filter', () {
        expect(
          EventFilterUtils.shouldSkipEvent(
            'purchase',
            <String>[],
            <String>['purchase', 'add_to_cart'],
          ),
          isFalse,
        );

        expect(
          EventFilterUtils.shouldSkipEvent(
            'screen_view',
            <String>[],
            <String>['purchase', 'add_to_cart'],
          ),
          isTrue,
        );
      });

      test('should prioritize show-only over hide option', () {
        expect(
          EventFilterUtils.shouldSkipEvent(
            'purchase',
            <String>['purchase'],
            <String>['purchase'],
          ),
          isFalse,
        );
      });

      test('should not skip events when no filters are applied', () {
        expect(
          EventFilterUtils.shouldSkipEvent(
            'any_event',
            <String>[],
            <String>[],
          ),
          isFalse,
        );
      });
    });

    group('custom parameter parsing', () {
      test('should parse valid custom parameter format', () {
        // Test that custom parameters with correct format are accepted
        final argParser = command.argParser;
        final results = argParser.parse([
          '--add-param',
          'purchase:test_mode:true',
        ]);

        expect(results['add-param'], equals(['purchase:test_mode:true']));
      });

      test('should accept multiple custom parameters for same event', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--add-param',
          'purchase:test_mode:true',
          '--add-param',
          'purchase:debug:enabled',
        ]);

        expect(
          results['add-param'],
          equals(['purchase:test_mode:true', 'purchase:debug:enabled']),
        );
      });

      test('should accept custom parameters for different events', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--add-param',
          'purchase:test_mode:true',
          '--add-param',
          'screen_view:debug:enabled',
        ]);

        expect(
          results['add-param'],
          equals(['purchase:test_mode:true', 'screen_view:debug:enabled']),
        );
      });

      test('should handle empty custom parameters list', () {
        final argParser = command.argParser;
        final results = argParser.parse(<String>[]);

        expect(results['add-param'], isEmpty);
      });
    });

    group('date filtering', () {
      test('should parse valid ISO 8601 dates', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--from-date',
          '2024-01-01T00:00:00',
          '--to-date',
          '2024-12-31T23:59:59',
        ]);

        expect(results['from-date'], equals('2024-01-01T00:00:00'));
        expect(results['to-date'], equals('2024-12-31T23:59:59'));
      });

      test('should handle date-only format', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--from-date',
          '2024-01-01',
          '--to-date',
          '2024-12-31',
        ]);

        expect(results['from-date'], equals('2024-01-01'));
        expect(results['to-date'], equals('2024-12-31'));
      });

      test('should work with only from-date', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--from-date',
          '2024-06-01',
        ]);

        expect(results['from-date'], equals('2024-06-01'));
        expect(results['to-date'], isNull);
      });

      test('should work with only to-date', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--to-date',
          '2024-06-30',
        ]);

        expect(results['from-date'], isNull);
        expect(results['to-date'], equals('2024-06-30'));
      });
    });

    group('frequency filtering arguments', () {
      test('should accept only min-frequency', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--min-frequency', '5']);

        expect(results['min-frequency'], equals('5'));
        expect(results['max-frequency'], isNull);
      });

      test('should accept only max-frequency', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--max-frequency', '100']);

        expect(results['min-frequency'], isNull);
        expect(results['max-frequency'], equals('100'));
      });

      test('should accept both frequency bounds', () {
        final argParser = command.argParser;
        final results = argParser.parse([
          '--min-frequency',
          '10',
          '--max-frequency',
          '100',
        ]);

        expect(results['min-frequency'], equals('10'));
        expect(results['max-frequency'], equals('100'));
      });
    });

    group('flag combinations', () {
      test('should handle persist with stats-only as separate modes', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--persist', '--stats-only']);

        expect(results['persist'], isTrue);
        expect(results['stats-only'], isTrue);
      });

      test('should handle no-color with raw output', () {
        final argParser = command.argParser;
        final results = argParser.parse(['--no-color', '-r']);

        expect(results['no-color'], isTrue);
        expect(results['raw'], isTrue);
      });

      test('should have correct default flag values', () {
        final argParser = command.argParser;
        final results = argParser.parse(<String>[]);

        expect(results['persist'], isFalse);
        expect(results['stats-only'], isFalse);
        expect(results['no-color'], isFalse);
        expect(results['raw'], isFalse);
      });
    });

    group('AnalyticsEvent custom parameters', () {
      test('should merge manual parameters correctly', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 10:30:45.123',
          eventName: 'purchase',
          parameters: const {'original_param': 'original_value'},
        );

        final enhanced = event.copyWith(
          manualParameters: {
            ...event.manualParameters,
            'test_mode': 'true',
            'debug': 'enabled',
          },
        );

        expect(enhanced.manualParameters['test_mode'], equals('true'));
        expect(enhanced.manualParameters['debug'], equals('enabled'));
        expect(enhanced.parameters['original_param'], equals('original_value'));
        expect(enhanced.allParameters['test_mode'], equals('true'));
        expect(
          enhanced.allParameters['original_param'],
          equals('original_value'),
        );
      });

      test('should preserve original event properties when adding params', () {
        final event = AnalyticsEvent.fromParsedLog(
          rawTimestamp: '01-13 10:30:45.123',
          eventName: 'purchase',
          parameters: const {'value': '99.99'},
        );

        final enhanced = event.copyWith(
          manualParameters: const {'test': 'value'},
        );

        expect(enhanced.eventName, equals('purchase'));
        expect(enhanced.rawTimestamp, equals('01-13 10:30:45.123'));
        expect(enhanced.parameters, equals({'value': '99.99'}));
      });
    });

    group('EventStatistics handling', () {
      test('should handle statistics without date range', () async {
        final stats = EventStatistics(
          totalEvents: 50,
          uniqueEventTypes: 5,
          topEvents: const {'event_a': 20, 'event_b': 15, 'event_c': 15},
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => []);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => []);

        final result = await runner.run(['filter', '--stats-only']);

        expect(result, equals(0));
      });

      test('should handle statistics with date range', () async {
        final stats = EventStatistics(
          totalEvents: 100,
          uniqueEventTypes: 10,
          topEvents: const {'screen_view': 50},
          dateRange: DateTimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 12, 31),
          ),
        );

        when(
          () => mockFilterService.getEventStatistics(
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
          ),
        ).thenAnswer((_) async => stats);

        when(
          () => mockFilterService.getHighFrequencyEvents(
            threshold: any(named: 'threshold'),
          ),
        ).thenAnswer((_) async => []);

        when(() => mockFilterService.getLowFrequencyEvents())
            .thenAnswer((_) async => []);

        final result = await runner.run(['filter', '--stats-only']);

        expect(result, equals(0));
        verify(() => mockLogger.info(any(that: contains('Date Range'))))
            .called(1);
      });
    });
  });
}
