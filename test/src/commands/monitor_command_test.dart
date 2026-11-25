import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:famon/src/commands/monitor_command.dart';
import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';

class MockLogger extends Mock implements Logger {}

class MockLogSourceFactory extends Mock implements LogSourceFactory {}

class MockLogParserFactory extends Mock implements LogParserFactory {}

class MockEventCache extends Mock implements EventCacheInterface {}

class MockLogSource extends Mock implements LogSourceInterface {}

class MockLogParser extends Mock implements LogParserInterface {}

class MockProcess extends Mock implements Process {}

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
          <String>[
            'screen_view',
            '_vs',
          ],
          <String>[],
        ),
        isTrue,
      );

      expect(
        EventFilterUtils.shouldSkipEvent(
          'purchase',
          <String>[
            'screen_view',
            '_vs',
          ],
          <String>[],
        ),
        isFalse,
      );
    });

    test('should filter events correctly with show-only option', () {
      expect(
        EventFilterUtils.shouldSkipEvent('purchase', <String>[], <String>[
          'purchase',
          'add_to_cart',
        ]),
        isFalse,
      );

      expect(
        EventFilterUtils.shouldSkipEvent('screen_view', <String>[], <String>[
          'purchase',
          'add_to_cart',
        ]),
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
        EventFilterUtils.shouldSkipEvent('any_event', <String>[], <String>[]),
        isFalse,
      );
    });

    test('verbose log filter includes iOS Firebase/Analytics lines', () {
      // The verbose-line heuristic moved from `MonitorCommand` into
      // `MonitoringPipeline` as part of the monitor-loop extraction.
      expect(
        MonitoringPipeline.isFirebaseRelatedLogLine(
          '[Firebase/Analytics][I-ACS023073] Debug mode is enabled.',
        ),
        isTrue,
      );
    });
  });

  group('MonitorCommand.run without a terminal', () {
    late MockLogger logger;
    late MockLogSource logSource;
    late MockProcess process;
    late StreamController<List<int>> logcat;
    late MockStdout stdout;
    late Completer<void> stdoutDone;
    late MockEventCache eventCache;
    late Map<Duration, void Function()> periodicTimers;
    late CommandRunner<int> runner;

    const eventLine = 'event-line';

    setUpAll(() => registerFallbackValue(PlatformType.android));

    setUp(() {
      logger = MockLogger();
      when(() => logger.level).thenReturn(Level.info);
      logSource = MockLogSource();
      process = MockProcess();
      logcat = StreamController<List<int>>();
      stdout = MockStdout();
      stdoutDone = Completer<void>();
      eventCache = MockEventCache();
      periodicTimers = {};
      when(() => stdout.hasTerminal).thenReturn(false);
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stdout.done).thenAnswer((_) => stdoutDone.future);

      when(() => process.stdout).thenAnswer((_) => logcat.stream);
      when(() => process.stderr).thenAnswer((_) => const Stream.empty());
      when(process.kill).thenAnswer((_) {
        unawaited(logcat.close());
        return true;
      });

      when(() => logSource.platform).thenReturn(PlatformType.android);
      when(() => logSource.platformDisplayName).thenReturn('Android');
      when(logSource.checkToolsAvailable).thenAnswer((_) async => true);
      when(
        () => logSource.startLogStream(verbose: any(named: 'verbose')),
      ).thenAnswer((_) async => process);

      final logSourceFactory = MockLogSourceFactory();
      when(
        () => logSourceFactory.create(any()),
      ).thenAnswer((_) async => logSource);
      final parser = MockLogParser();
      when(() => parser.parse(any())).thenReturn(
        AnalyticsEvent.fromParsedLog(
          rawTimestamp: '12-25 10:30:45.123',
          eventName: 'add_to_cart',
          parameters: const {'currency': 'USD'},
        ),
      );
      final parserFactory = MockLogParserFactory();
      when(() => parserFactory.create(any())).thenReturn(parser);

      runner = CommandRunner<int>('famon', 'test')
        ..addCommand(
          MonitorCommand(
            logger: logger,
            logSourceFactory: logSourceFactory,
            logParserFactory: parserFactory,
            eventCache: eventCache,
          ),
        );
    });

    /// Runs `famon monitor --raw` plus [extraArgs] with [stdin] and the
    /// mock stdout, feeds one logcat line, then lets [whileRunning] act on
    /// the session. Each periodic timer the command starts is recorded in
    /// [periodicTimers] by its interval, so a test can fire it at once.
    Future<int?> runMonitor(
      Stdin stdin,
      Future<void> Function() whileRunning, {
      List<String> extraArgs = const [],
    }) {
      return IOOverrides.runZoned(
        () => runZoned(
          () async {
            final result = runner.run(['monitor', '--raw', ...extraArgs]);
            await pumpEventQueue();
            logcat.add(utf8.encode('$eventLine\n'));
            await pumpEventQueue();
            await whileRunning();
            return result;
          },
          zoneSpecification: ZoneSpecification(
            createPeriodicTimer: (self, parent, zone, period, onTick) {
              final timer = parent.createPeriodicTimer(zone, period, onTick);
              periodicTimers[period] = () => onTick(timer);
              return timer;
            },
          ),
        ),
        stdin: () => stdin,
        stdout: () => stdout,
      );
    }

    /// Runs `famon monitor --raw --stats --suggestions` and fires one stats
    /// tick and one suggestions tick before the log stream ends.
    Future<void> runWithStatsAndSuggestions() {
      when(() => eventCache.getSessionStats()).thenReturn(
        const SessionStats(
          totalUniqueEvents: 1,
          totalEventOccurrences: 1,
          mostFrequentEvent: 'add_to_cart',
        ),
      );
      when(() => eventCache.getEventCount('add_to_cart')).thenReturn(1);
      when(() => eventCache.getTopEvents(any())).thenReturn(['add_to_cart']);
      when(() => eventCache.getSuggestedToHide()).thenReturn(['add_to_cart']);
      return runMonitor(
        devNullStdin(),
        () async {
          periodicTimers[statsDisplayInterval]!();
          periodicTimers[suggestionsDisplayInterval]!();
          await logcat.close();
        },
        extraArgs: ['--stats', '--suggestions'],
      );
    }

    const statsAndSuggestionLines = [
      '\n📊 Session Stats:',
      '   Unique Events: 1',
      '   Total Events: 1',
      '   Most Frequent: add_to_cart (1)',
      '\n💡 Smart Suggestions:',
      '   Most frequent events: add_to_cart',
      '   Consider hiding: add_to_cart',
      '   Use: famon monitor --hide add_to_cart',
    ];

    test('starts with shortcuts off when stdin is /dev/null (F9)', () async {
      final stdin = devNullStdin();

      final status = await runMonitor(stdin, logcat.close);

      expect(status, 0);
      verifyNever(() => stdin.lineMode = any());
      verify(
        () => logger.err(
          'Press Ctrl+C to stop monitoring',
          style: any(named: 'style'),
        ),
      ).called(1);
      verifyNever(() => logger.err(any(that: contains('I/O error'))));
    });

    test('stops quietly with status 0 when the stdout reader closes (F10)',
        () async {
      final status = await runMonitor(devNullStdin(), () async {
        stdoutDone.completeError(brokenPipe);
      });

      expect(status, 0);
      verify(process.kill).called(greaterThan(0));
      verifyNever(() => logger.err(any(that: startsWith('❌'))));
      verifyNever(() => logger.err(any(that: contains('Error reading'))));
    });

    test('sends the banner to stderr and events to stdout (F11)', () async {
      await runMonitor(devNullStdin(), logcat.close);

      final infoLines = verify(() => logger.info(captureAny())).captured;
      expect(infoLines, hasLength(1));
      expect(infoLines.single, contains(' | add_to_cart | '));
      verify(
        () => logger.err(
          any(that: contains('Firebase Analytics Monitor Started')),
          style: any(named: 'style'),
        ),
      ).called(1);
      verify(
        () => logger.err(
          '📱 Connecting to Android...',
          style: any(named: 'style'),
        ),
      ).called(1);
      verify(() => logger.err('', style: any(named: 'style'))).called(1);
    });

    test('keeps the banner on stdout when stdout is a terminal (F11)',
        () async {
      when(() => stdout.hasTerminal).thenReturn(true);

      await runMonitor(devNullStdin(), logcat.close);

      verify(
        () => logger.info(
          any(that: contains('Firebase Analytics Monitor Started')),
        ),
      ).called(1);
      verify(() => logger.info('Press Ctrl+C to stop monitoring')).called(1);
      verify(() => logger.info('')).called(1);
      verifyNever(() => logger.err(any(), style: any(named: 'style')));
    });

    test('sends --stats and --suggestions output to stderr when piped',
        () async {
      await runWithStatsAndSuggestions();

      final infoLines = verify(() => logger.info(captureAny())).captured;
      expect(infoLines, hasLength(1));
      expect(infoLines.single, contains(' | add_to_cart | '));
      for (final line in statsAndSuggestionLines) {
        verify(() => logger.err(line, style: any(named: 'style'))).called(1);
      }
      // The banner's blank line, then one after stats and one after
      // suggestions.
      verify(() => logger.err('', style: any(named: 'style'))).called(3);
    });

    test('keeps --stats and --suggestions output on stdout in a terminal',
        () async {
      when(() => stdout.hasTerminal).thenReturn(true);

      await runWithStatsAndSuggestions();

      for (final line in statsAndSuggestionLines) {
        verify(() => logger.info(line)).called(1);
      }
      verify(() => logger.info('')).called(3);
      verifyNever(() => logger.err(any(), style: any(named: 'style')));
    });
  });
}
