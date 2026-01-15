import 'package:firebase_analytics_monitor/src/commands/monitor_command.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/event_cache_interface.dart';
import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/services/log_source_factory.dart';
import 'package:firebase_analytics_monitor/src/utils/event_filter_utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockLogSourceFactory extends Mock implements LogSourceFactory {}

class MockLogParser extends Mock implements LogParserInterface {}

class MockEventCache extends Mock implements EventCacheInterface {}

void main() {
  group('MonitorCommand', () {
    late MockLogger mockLogger;
    late MockLogSourceFactory mockLogSourceFactory;
    late MockLogParser mockLogParser;
    late MockEventCache mockEventCache;
    late MonitorCommand command;

    setUp(() {
      mockLogger = MockLogger();
      mockLogSourceFactory = MockLogSourceFactory();
      mockLogParser = MockLogParser();
      mockEventCache = MockEventCache();

      command = MonitorCommand(
        logger: mockLogger,
        logSourceFactory: mockLogSourceFactory,
        logParser: mockLogParser,
        eventCache: mockEventCache,
      );
    });

    test('should have correct name and description', () {
      expect(command.name, equals('monitor'));
      expect(command.description, contains('Firebase Analytics events'));
    });

    test('should filter events correctly with hide option', () {
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

    test('should filter events correctly with show-only option', () {
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
}
