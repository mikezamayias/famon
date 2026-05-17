import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

const _eventLine = '11-15 10:23:45.123 12345 12345 V FA      : '
    'Logging event: '
    'origin=app,name=screen_view,'
    'params=Bundle[{firebase_screen_class=HomeScreen}]';

const _verboseChatterLine =
    '11-15 10:23:45.123 12345 12345 V FA-SVC  : Uploading data';

const _crashlyticsChatterLine =
    '11-15 10:23:45.123 12345 12345 V FirebaseCrashlytics: Initialised';

const _unrelatedLine =
    '11-15 10:23:45.123 12345 12345 V ActivityManager: START activity';

void main() {
  group('LogEventProcessor', () {
    final processor = LogEventProcessor(parser: LogParserService());

    test('returns LogEventResult for an unfiltered Firebase event', () {
      final result = processor.processLine(_eventLine);

      expect(result, isA<LogEventResult>());
      expect((result as LogEventResult).event.eventName, 'screen_view');
    });

    test('returns LogDiscardedResult when hideEvents matches', () {
      final result = processor.processLine(
        _eventLine,
        hideEvents: const ['screen_view'],
      );

      expect(result, isA<LogDiscardedResult>());
    });

    test('returns LogEventResult when showOnlyEvents matches', () {
      final result = processor.processLine(
        _eventLine,
        showOnlyEvents: const ['screen_view'],
      );

      expect(result, isA<LogEventResult>());
      expect((result as LogEventResult).event.eventName, 'screen_view');
    });

    test(
      'returns LogDiscardedResult when showOnlyEvents excludes the event',
      () {
        final result = processor.processLine(
          _eventLine,
          showOnlyEvents: const ['other_event'],
        );

        expect(result, isA<LogDiscardedResult>());
      },
    );

    test('showOnlyEvents takes precedence over hideEvents', () {
      final result = processor.processLine(
        _eventLine,
        hideEvents: const ['screen_view'],
        showOnlyEvents: const ['screen_view'],
      );

      expect(result, isA<LogEventResult>());
    });

    test('returns LogVerboseResult for FA-SVC chatter when verbose', () {
      final result = processor.processLine(
        _verboseChatterLine,
        verbose: true,
      );

      expect(result, isA<LogVerboseResult>());
      expect(
        (result as LogVerboseResult).line,
        contains('Uploading data'),
      );
    });

    test('returns LogVerboseResult for FirebaseCrashlytics line when verbose',
        () {
      final result = processor.processLine(
        _crashlyticsChatterLine,
        verbose: true,
      );

      expect(result, isA<LogVerboseResult>());
    });

    test('discards Firebase chatter when verbose is false (default)', () {
      final result = processor.processLine(_verboseChatterLine);

      expect(result, isA<LogDiscardedResult>());
    });

    test('discards unrelated non-Firebase lines even in verbose mode', () {
      final result = processor.processLine(
        _unrelatedLine,
        verbose: true,
      );

      expect(result, isA<LogDiscardedResult>());
    });
  });
}
