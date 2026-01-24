import 'package:famon/src/commands/monitor_command.dart';
import 'package:famon/src/services/interfaces/event_cache_interface.dart';
import 'package:famon/src/services/log_parser_factory.dart';
import 'package:famon/src/services/log_source_factory.dart';
import 'package:famon/src/utils/event_filter_utils.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockLogSourceFactory extends Mock implements LogSourceFactory {}

class MockLogParserFactory extends Mock implements LogParserFactory {}

class MockEventCache extends Mock implements EventCacheInterface {}

void main() {
  group('MonitorCommand', () {
    late MockLogger mockLogger;
    late MockLogSourceFactory mockLogSourceFactory;
    late MockLogParserFactory mockLogParserFactory;
    late MockEventCache mockEventCache;
    late MonitorCommand command;

    setUp(() {
      mockLogger = MockLogger();
      mockLogSourceFactory = MockLogSourceFactory();
      mockLogParserFactory = MockLogParserFactory();
      mockEventCache = MockEventCache();

      command = MonitorCommand(
        logger: mockLogger,
        logSourceFactory: mockLogSourceFactory,
        logParserFactory: mockLogParserFactory,
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
