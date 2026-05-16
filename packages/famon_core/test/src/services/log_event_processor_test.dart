import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('LogEventProcessor', () {
    test('parses and returns an event for an unfiltered log line', () {
      final processor = LogEventProcessor(parser: LogParserService());

      final result = processor.processLine(
        '11-15 10:23:45.123 12345 12345 V FA      : Logging event: '
        'origin=app,name=screen_view,'
        'params=Bundle[{firebase_screen_class=HomeScreen}]',
      );

      expect(result.event?.eventName, 'screen_view');
      expect(result.shouldDisplay, isTrue);
      expect(result.verboseLine, isNull);
    });

    test('suppresses hidden events without terminal dependencies', () {
      final processor = LogEventProcessor(parser: LogParserService());

      final result = processor.processLine(
        '11-15 10:23:45.123 12345 12345 V FA      : Logging event: '
        'origin=app,name=screen_view,'
        'params=Bundle[{firebase_screen_class=HomeScreen}]',
        hideEvents: const ['screen_view'],
      );

      expect(result.event?.eventName, 'screen_view');
      expect(result.shouldDisplay, isFalse);
    });

    test('returns verbose Firebase lines when requested', () {
      final processor = LogEventProcessor(parser: LogParserService());

      final result = processor.processLine(
        '11-15 10:23:45.123 12345 12345 V FA-SVC  : Uploading data',
        verbose: true,
      );

      expect(result.event, isNull);
      expect(result.verboseLine, contains('Uploading data'));
      expect(result.shouldDisplay, isTrue);
    });
  });
}
