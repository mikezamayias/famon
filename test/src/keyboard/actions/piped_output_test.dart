import 'dart:io';

import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/action_registry.dart';
import 'package:famon/src/keyboard/actions/clear_screen_action.dart';
import 'package:famon/src/keyboard/actions/copy_to_clipboard_action.dart';
import 'package:famon/src/keyboard/actions/quit_action.dart';
import 'package:famon/src/keyboard/actions/save_to_file_action.dart';
import 'package:famon/src/keyboard/actions/shortcut_action.dart';
import 'package:famon/src/keyboard/actions/show_help_action.dart';
import 'package:famon/src/keyboard/actions/show_stats_action.dart';
import 'package:famon/src/keyboard/actions/toggle_event_params_action.dart';
import 'package:famon/src/keyboard/actions/toggle_global_params_action.dart';
import 'package:famon/src/keyboard/actions/toggle_pause_action.dart';
import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/stdio_fakes.dart';
import '../../../helpers/test_helpers.dart';

/// With stdin on a terminal and stdout piped (`famon monitor | tee log`),
/// shortcut output must reach stderr and never the pipe.
void main() {
  late MockLogger logger;
  late MockEventCache eventCache;
  late MockClipboardInterface clipboard;
  late MockFileDialogInterface fileDialog;
  late MockStdout stdout;
  late MockStdout stderr;
  late Directory tempDir;

  setUp(() {
    (:stdout, :stderr) = fakeStdio(
      stdoutIsTerminal: false,
      stderrIsTerminal: true,
    );
    logger = MockLogger();
    when(() => logger.level).thenReturn(Level.info);
    eventCache = MockEventCache();
    when(() => eventCache.getSessionStats()).thenReturn(
      const SessionStats(
        totalUniqueEvents: 1,
        totalEventOccurrences: 2,
        mostFrequentEvent: 'add_to_cart',
      ),
    );
    when(() => eventCache.getTopEvents(any())).thenReturn(['add_to_cart']);
    when(() => eventCache.getEventCount(any())).thenReturn(2);
    clipboard = MockClipboardInterface();
    when(() => clipboard.isSupported).thenReturn(true);
    when(() => clipboard.copy(any())).thenAnswer((_) async => true);
    tempDir = Directory.systemTemp.createTempSync('famon_piped_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    fileDialog = MockFileDialogInterface();
    when(
      () => fileDialog.showSaveDialog(
        defaultFileName: any(named: 'defaultFileName'),
      ),
    ).thenAnswer((_) async => '${tempDir.path}/events.json');
  });

  List<ShortcutAction> allActions() {
    final registry = ActionRegistry();
    final actions = <ShortcutAction>[
      CopyToClipboardAction(clipboard: clipboard),
      SaveToFileAction(fileDialog: fileDialog),
      TogglePauseAction(onToggle: ({required isPaused}) {}),
      ToggleGlobalParamsAction(onToggle: ({required hideGlobalParams}) {}),
      ToggleEventParamsAction(onToggle: ({required hideEventParams}) {}),
      ShowStatsAction(),
      ClearScreenAction(),
      QuitAction(onQuit: () {}),
    ];
    registry.registerAll(actions);
    final help = ShowHelpAction(
      registry: registry,
      getBinding: (id) => registry.getAction(id)!.defaultBinding,
    );
    registry.register(help);
    return [...actions, help];
  }

  ActionContext context({bool withEvents = true}) => ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: withEvents
            ? [createMockAnalyticsEvent(eventName: 'add_to_cart')]
            : [],
      );

  void expectNothingOnStdout() {
    verifyNever(() => logger.info(any()));
    verifyNever(() => logger.success(any()));
    verifyNever(() => logger.detail(any()));
    verifyNever(() => logger.write(any()));
    verifyNever(() => stdout.write(any()));
    verifyNever(() => stdout.writeln(any()));
  }

  for (final withEvents in [true, false]) {
    test(
        'every action writes its messages to stderr only '
        '(${withEvents ? 'with' : 'without'} events)', () async {
      for (final action in allActions()) {
        await action.execute(context(withEvents: withEvents));
      }

      expectNothingOnStdout();
      verify(() => logger.err(any(), style: any(named: 'style')))
          .called(greaterThan(5));
    });
  }

  test('help and stats reach stderr', () async {
    final actions = allActions();
    await actions.whereType<ShowHelpAction>().single.execute(context());
    await actions.whereType<ShowStatsAction>().single.execute(context());

    verify(
      () => logger.err(
        any(that: contains('Keyboard Shortcuts')),
        style: any(named: 'style'),
      ),
    ).called(1);
    verify(
      () => logger.err(
        any(that: contains('Session Statistics')),
        style: any(named: 'style'),
      ),
    ).called(1);
  });

  test('copy and save still do their work', () async {
    final actions = allActions();
    await actions.whereType<CopyToClipboardAction>().single.execute(context());
    await actions.whereType<SaveToFileAction>().single.execute(context());

    verify(() => clipboard.copy(any(that: contains('add_to_cart')))).called(1);
    expect(
      File('${tempDir.path}/events.json').readAsStringSync(),
      contains('add_to_cart'),
    );
    verify(
      () => logger.err(
        'Copied 1 events to clipboard',
        style: any(named: 'style'),
      ),
    ).called(1);
  });

  group('clear screen', () {
    const clear = '\x1B[2J\x1B[H';

    test('clears the terminal on stderr, never the stdout pipe', () async {
      await ClearScreenAction().execute(context());

      verify(() => stderr.write(clear)).called(1);
      expectNothingOnStdout();
    });

    test('writes no escape sequence when neither stream is a terminal',
        () async {
      final (:stdout, :stderr) = fakeStdio(stdoutIsTerminal: false);

      await ClearScreenAction().execute(context());

      verifyNever(() => stdout.write(any()));
      verifyNever(() => stderr.write(any()));
    });

    test('keeps clearing stdout when it is a terminal', () async {
      final (:stdout, :stderr) = fakeStdio(stdoutIsTerminal: true);

      await ClearScreenAction().execute(context());

      verify(() => stdout.write(clear)).called(1);
      verifyNever(() => stderr.write(any()));
    });
  });
}
