import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:famon/src/commands/monitor_command.dart';
import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockLogSourceFactory extends Mock implements LogSourceFactory {}

class MockLogParserFactory extends Mock implements LogParserFactory {}

class MockEventCache extends Mock implements EventCacheInterface {}

class MockLogSource extends Mock implements LogSourceInterface {}

class MockLogParser extends Mock implements LogParserInterface {}

class FakeProcess implements Process {
  FakeProcess(String stdoutLine)
      : stdout = Stream<List<int>>.value(utf8.encode(stdoutLine)),
        stderr = const Stream<List<int>>.empty();

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;

  @override
  Future<int> get exitCode async => 0;

  @override
  int get pid => 1;

  @override
  IOSink get stdin => IOSink(StreamController<List<int>>().sink);

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

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

    test('verbose mode prints iOS Firebase/Analytics log lines', () async {
      final logSource = MockLogSource();
      final logParser = MockLogParser();
      const logLine =
          '[Firebase/Analytics][I-ACS023073] Debug mode is enabled. '
          'Event name, parameters: screen_view, { screen = Home; }';

      when(() => logSource.platform).thenReturn(PlatformType.iosSimulator);
      when(() => logSource.platformDisplayName).thenReturn('iOS Simulator');
      when(logSource.checkToolsAvailable).thenAnswer((_) async => true);
      when(() => logSource.startLogStream(verbose: true))
          .thenAnswer((_) async => FakeProcess(logLine));
      when(logSource.getTroubleshootingTips).thenReturn(<String>[]);
      when(() => mockLogSourceFactory.create(PlatformType.iosSimulator))
          .thenAnswer((_) async => logSource);
      when(() => mockLogParserFactory.create(PlatformType.iosSimulator))
          .thenReturn(logParser);
      when(() => logParser.parse(any())).thenReturn(null);
      when(mockEventCache.clear).thenReturn(null);
      when(() => mockLogger.level = Level.verbose).thenReturn(Level.verbose);
      when(() => mockLogger.level).thenReturn(Level.verbose);
      when(() => mockLogger.info(any())).thenReturn(null);
      when(() => mockLogger.detail(any())).thenReturn(null);

      final runner = CommandRunner<int>('test', 'test')..addCommand(command);

      final exitCode = await runner.run(<String>[
        'monitor',
        '--platform',
        'ios-simulator',
        '--verbose',
        '--no-shortcuts',
      ]);

      expect(exitCode, equals(0));
      verify(() => mockLogger.detail(logLine)).called(1);
    });
  });
}
