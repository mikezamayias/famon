import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:famon/src/config/shortcuts_config_loader.dart';
import 'package:famon/src/constants.dart';
import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/action_registry.dart';
import 'package:famon/src/keyboard/actions/clear_screen_action.dart';
import 'package:famon/src/keyboard/actions/copy_to_clipboard_action.dart';
import 'package:famon/src/keyboard/actions/quit_action.dart';
import 'package:famon/src/keyboard/actions/save_to_file_action.dart';
import 'package:famon/src/keyboard/actions/show_help_action.dart';
import 'package:famon/src/keyboard/actions/show_stats_action.dart';
import 'package:famon/src/keyboard/actions/toggle_event_params_action.dart';
import 'package:famon/src/keyboard/actions/toggle_global_params_action.dart';
import 'package:famon/src/keyboard/actions/toggle_pause_action.dart';
import 'package:famon/src/keyboard/keyboard_input_interface.dart';
import 'package:famon/src/keyboard/keyboard_input_service.dart';
import 'package:famon/src/keyboard/shortcut_manager.dart';
import 'package:famon/src/models/platform_type.dart';
import 'package:famon/src/platform/clipboard_service.dart';
import 'package:famon/src/platform/file_dialog_service.dart';
import 'package:famon/src/services/event_formatter_service.dart';
import 'package:famon/src/services/interfaces/event_cache_interface.dart';
import 'package:famon/src/services/interfaces/log_parser_interface.dart';
import 'package:famon/src/services/interfaces/log_source_interface.dart';
import 'package:famon/src/services/log_parser_factory.dart';
import 'package:famon/src/services/log_source_factory.dart';
import 'package:famon/src/utils/event_filter_utils.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';

/// Command for monitoring Firebase Analytics events in real-time
@injectable
class MonitorCommand extends Command<int> {
  /// Creates a new MonitorCommand with injected dependencies
  MonitorCommand({
    required Logger logger,
    required LogSourceFactory logSourceFactory,
    required LogParserFactory logParserFactory,
    required EventCacheInterface eventCache,
  })  : _logger = logger,
        _logSourceFactory = logSourceFactory,
        _logParserFactory = logParserFactory,
        _eventCache = eventCache {
    argParser
      ..addOption(
        'platform',
        abbr: 'p',
        allowed: ['android', 'ios-simulator', 'ios-device', 'auto'],
        defaultsTo: 'auto',
        help: 'Target platform for monitoring.',
      )
      ..addMultiOption(
        'hide',
        help: 'Event names to hide from output. Can be used multiple times.',
        valueHelp: 'EVENT_NAME',
      )
      ..addMultiOption(
        'show-only',
        abbr: 's',
        help: 'Only show these event names. Can be used multiple times.',
        valueHelp: 'EVENT_NAME',
      )
      ..addFlag('no-color', negatable: false, help: 'Disables colorful output.')
      ..addFlag(
        'suggestions',
        help: 'Show smart suggestions based on session history.',
      )
      ..addFlag('stats', help: 'Show session statistics periodically.')
      ..addFlag(
        'raw',
        abbr: 'r',
        negatable: false,
        help: 'Print raw parameter values without formatting or grouping.',
      )
      ..addFlag(
        'verbose',
        abbr: 'V',
        negatable: false,
        help:
            'Verbose mode: stream and print all Firebase Analytics/Crashlytics '
            'log lines.',
      )
      ..addOption(
        'enable-debug',
        abbr: 'D',
        valueHelp: 'PACKAGE',
        help: 'Enable Analytics debug for PACKAGE and raise log levels '
            'before monitoring.',
      )
      ..addFlag(
        'raise-log-levels',
        negatable: false,
        help: 'Raise log levels to VERBOSE before monitoring.',
      )
      ..addFlag(
        'no-shortcuts',
        negatable: false,
        help: 'Disable keyboard shortcuts (for non-interactive environments).',
      )
      ..addMultiOption(
        'global-params',
        abbr: 'g',
        help: 'Parameter names to classify as global/default. '
            'These are separated from event-specific parameters in the '
            'output and can be toggled with the G key at runtime.',
        valueHelp: 'PARAM_NAME',
      )
      ..addFlag(
        'hide-global-params',
        negatable: false,
        help: 'Start with global parameters hidden from output. '
            'Toggle at runtime with G.',
      )
      ..addFlag(
        'hide-event-params',
        negatable: false,
        help: 'Start with event-specific parameters hidden from output. '
            'Toggle at runtime with E.',
      );
  }

  @override
  final name = 'monitor';

  @override
  final description =
      'Monitors Firebase Analytics events from logcat in real-time.';

  final Logger _logger;
  final LogSourceFactory _logSourceFactory;
  final LogParserFactory _logParserFactory;
  final EventCacheInterface _eventCache;
  late final EventFormatterService _formatter;
  late final LogSourceInterface _logSource;
  late final LogParserInterface _logParser;

  // Keyboard shortcuts support
  KeyboardInputInterface? _keyboardInput;
  ShortcutManager? _shortcutManager;
  bool _isPaused = false;
  bool _hideGlobalParams = false;
  bool _hideEventParams = false;
  bool _shouldQuit = false;

  /// Pre-compiled regex pattern for detecting Firebase Analytics related logs.
  ///
  /// Used in verbose mode to filter relevant log lines.
  /// Supports both Android (FA, FA-SVC) and iOS (FirebaseAnalytics,
  /// FIRAnalytics) patterns.
  static final RegExp _firebaseRelatedPattern = RegExp(
    r'\bFA-SVC\b|\bFA\b|I/FA|D/FA|V/FA|W/FA|E/FA|'
    'FirebaseCrashlytics|Crashlytics|FirebaseAnalytics|FIRAnalytics',
  );

  @override
  Future<int> run() async {
    final platformArg = argResults?['platform'] as String? ?? 'auto';
    final hideEvents = (argResults?['hide'] as List<String>?) ?? <String>[];
    final showOnlyEvents =
        (argResults?['show-only'] as List<String>?) ?? <String>[];
    final showSuggestions = argResults?['suggestions'] as bool? ?? false;
    final showStats = argResults?['stats'] as bool? ?? false;
    final rawOutput = argResults?['raw'] as bool? ?? false;
    final noColor = argResults?['no-color'] as bool? ?? false;
    final verbose = argResults?['verbose'] as bool? ?? false;
    final enableDebugFor = argResults?['enable-debug'] as String?;
    final raiseLogLevels = argResults?['raise-log-levels'] as bool? ?? false;
    final noShortcuts = argResults?['no-shortcuts'] as bool? ?? false;
    final globalParamNames =
        ((argResults?['global-params'] as List<String>?) ?? <String>[]).toSet();
    final initialHideGlobal =
        argResults?['hide-global-params'] as bool? ?? false;
    final initialHideEvent = argResults?['hide-event-params'] as bool? ?? false;

    // Parse platform type from argument
    final platformType = PlatformType.fromCliValue(platformArg);

    // Reset state for new session
    _isPaused = false;
    _hideGlobalParams = initialHideGlobal;
    _hideEventParams = initialHideEvent;
    _shouldQuit = false;

    // Ensure verbose logs are visible when monitor --verbose is used
    if (verbose) {
      _logger.level = Level.verbose;
    }

    // Initialize formatter with color, raw, and global params settings
    _formatter = EventFormatterService(
      _logger,
      rawOutput: rawOutput,
      colorEnabled: !noColor,
      globalParamNames: globalParamNames,
    )
      ..hideGlobalParams = initialHideGlobal
      ..hideEventParams = initialHideEvent;

    // Reset tracking for new session
    _formatter.resetTracking();

    // Clear cache for new session
    _eventCache.clear();

    // Create the appropriate log source for the platform
    _logSource = await _logSourceFactory.create(platformType);

    // Create the appropriate log parser for the detected platform
    _logParser = _logParserFactory.create(_logSource.platform);

    // Check if required tools are available
    if (!await _logSource.checkToolsAvailable()) {
      _logger
        ..err(
          '❌ Required tools not available for '
          '${_logSource.platformDisplayName}',
        )
        ..info(_logSource.getToolsInstallationInstructions());
      return 1;
    }

    _logger
      ..info('🔥 ${lightCyan.wrap('Firebase Analytics Monitor Started')}')
      ..info('📱 Connecting to ${_logSource.platformDisplayName}...')
      ..detail('Platform: ${_logSource.platform.displayName}')
      ..detail('Verbose mode: ${verbose ? 'ON' : 'OFF'}');

    // Optionally enable analytics debug and raise log levels
    if (enableDebugFor != null && enableDebugFor.isNotEmpty) {
      await _logSource.enableAnalyticsDebug(enableDebugFor);
    }
    if (raiseLogLevels || enableDebugFor != null) {
      await _logSource.raiseLogLevels();
    }

    if (hideEvents.isNotEmpty) {
      _logger.info('🙈 Hiding events: ${hideEvents.join(', ')}');
    }

    if (showOnlyEvents.isNotEmpty) {
      _logger.info('👀 Showing only: ${showOnlyEvents.join(', ')}');
    }

    if (globalParamNames.isNotEmpty) {
      _logger.info('🌐 Global parameters: ${globalParamNames.join(', ')}');
    }

    // Initialize keyboard shortcuts if enabled
    final shortcutsEnabled = !noShortcuts && stdin.hasTerminal;
    if (shortcutsEnabled) {
      await _initializeKeyboardShortcuts();
      _logger.info('Press ? for help, Q to quit');
    } else {
      _logger.info('Press Ctrl+C to stop monitoring');
    }
    _logger.info('');

    try {
      // Start log stream using platform-specific log source
      final process = await _logSource.startLogStream(verbose: verbose);

      // Drain stderr to prevent buffer overflow
      // adb may produce error output which could block if not consumed
      unawaited(process.stderr.drain<void>());

      // If nothing shows up for a while, guide the user with
      // platform-specific tips
      var sawRelevantLine = false;
      Timer(troubleshootingTimeout, () {
        if (!sawRelevantLine) {
          _logger
            ..warn('No Firebase Analytics logs detected yet...')
            ..info('Troubleshooting steps:');
          for (final tip in _logSource.getTroubleshootingTips()) {
            _logger.info('  $tip');
          }
        }
      });

      // Setup periodic stats display if requested
      Timer? statsTimer;
      if (showStats) {
        statsTimer = Timer.periodic(
          statsDisplayInterval,
          (_) => _showSessionStats(),
        );
      }

      // Setup suggestions display if requested
      Timer? suggestionsTimer;
      if (showSuggestions) {
        suggestionsTimer = Timer.periodic(
          suggestionsDisplayInterval,
          (_) => _showSmartSuggestions(),
        );
      }

      // Setup signal handlers for graceful shutdown
      StreamSubscription<ProcessSignal>? sigintSub;
      StreamSubscription<ProcessSignal>? sigtermSub;
      StreamSubscription<KeyInputEvent>? keyboardSub;

      void cleanup() {
        statsTimer?.cancel();
        suggestionsTimer?.cancel();
        unawaited(keyboardSub?.cancel());
        _keyboardInput?.dispose();
        process.kill();
      }

      sigintSub = ProcessSignal.sigint.watch().listen((_) {
        cleanup();
        unawaited(sigintSub?.cancel());
        unawaited(sigtermSub?.cancel());
      });
      sigtermSub = ProcessSignal.sigterm.watch().listen((_) {
        cleanup();
        unawaited(sigintSub?.cancel());
        unawaited(sigtermSub?.cancel());
      });

      // Setup keyboard shortcuts listener
      if (shortcutsEnabled && _keyboardInput != null) {
        _keyboardInput!.start();
        keyboardSub = _keyboardInput!.keyEvents.listen((event) async {
          await _handleKeyEvent(event);
        });
      }

      var malformedByteCount = 0;
      var lastMalformedWarning = DateTime.now();

      await for (final line in process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        // Check if quit was requested
        if (_shouldQuit) {
          cleanup();
          break;
        }

        // Detect malformed UTF-8 sequences (replacement character U+FFFD)
        final replacementCount = '\uFFFD'.allMatches(line).length;
        if (replacementCount > 0) {
          malformedByteCount += replacementCount;
          // Warn at most once per minute to avoid spam
          final now = DateTime.now();
          if (now.difference(lastMalformedWarning).inSeconds >= 60) {
            _logger.warn(
              'Detected $malformedByteCount malformed UTF-8 byte(s) in logcat '
              'output. Some log data may be corrupted.',
            );
            lastMalformedWarning = now;
          }
        }

        // If verbose, print all Firebase Analytics/Crashlytics related lines
        if (verbose && !_isPaused) {
          // Filter to only FA/Crashlytics noise to keep it relevant
          // Use pre-compiled static pattern for better performance
          if (_firebaseRelatedPattern.hasMatch(line)) {
            sawRelevantLine = true;
            _logger.detail(line);
          }
        }

        final event = _logParser.parse(line);

        if (event != null) {
          // Add full event to cache for export support
          _eventCache.addFullEvent(event);

          // Apply filtering using shared utility
          if (EventFilterUtils.shouldSkipEvent(
            event.eventName,
            hideEvents,
            showOnlyEvents,
          )) {
            continue;
          }

          // Skip display if paused (events still captured)
          if (_isPaused) {
            continue;
          }

          // Format and display the event
          // Ensure any buffered grouped output is flushed at end
          _formatter.flushPending();
          sawRelevantLine = true;
          _formatter.formatAndPrint(event);
        }
      }

      // Cleanup resources
      statsTimer?.cancel();
      suggestionsTimer?.cancel();
      unawaited(keyboardSub?.cancel());
      _keyboardInput?.dispose();
      unawaited(sigintSub.cancel());
      unawaited(sigtermSub.cancel());
    } on ProcessException catch (e, stackTrace) {
      // Handle adb process failures with specific guidance
      _logger
        ..err('❌ Failed to start adb. Make sure:')
        ..info('   1. Android SDK platform-tools are installed')
        ..info('   2. adb is in your PATH')
        ..info('   3. An Android device/emulator is connected')
        ..info('   4. USB debugging is enabled')
        ..detail('Process error: ${e.message}')
        ..detail('Stack trace: $stackTrace');
      return 1;
    } on IOException catch (e, stackTrace) {
      // Handle I/O errors (connection issues, pipe broken, etc.)
      _logger
        ..err('❌ I/O error while communicating with adb: $e')
        ..detail('Stack trace: $stackTrace');
      return 1;
    } on FormatException catch (e, stackTrace) {
      // Handle malformed data from logcat
      _logger
        ..err('❌ Failed to parse logcat output: $e')
        ..detail('Stack trace: $stackTrace');
      return 1;
    } on Exception catch (e, stackTrace) {
      // Handle other known exceptions
      _logger
        ..err('❌ Unexpected error: $e')
        ..detail('Stack trace: $stackTrace');
      return 1;
    }

    return 0;
  }

  /// Display session statistics
  void _showSessionStats() {
    final stats = _eventCache.getSessionStats();
    _logger
      ..info('\n📊 Session Stats:')
      ..info('   Unique Events: ${stats.totalUniqueEvents}')
      ..info('   Total Events: ${stats.totalEventOccurrences}');
    final mostFrequent = stats.mostFrequentEvent;
    if (mostFrequent != null) {
      _logger.info(
        '   Most Frequent: $mostFrequent '
        '(${_eventCache.getEventCount(mostFrequent)})',
      );
    }
    _logger.info('');
  }

  /// Display smart suggestions based on session data
  void _showSmartSuggestions() {
    final topEvents = _eventCache.getTopEvents(topEventsForSuggestions);
    final suggestedToHide = _eventCache.getSuggestedToHide();

    if (topEvents.isNotEmpty) {
      _logger
        ..info('\n💡 Smart Suggestions:')
        ..info('   Most frequent events: ${topEvents.join(', ')}');

      if (suggestedToHide.isNotEmpty) {
        _logger
          ..info('   Consider hiding: ${suggestedToHide.join(', ')}')
          ..info(
            '   Use: famon monitor --hide ${suggestedToHide.join(' --hide ')}',
          );
      }

      _logger.info('');
    }
  }

  /// Initialize keyboard shortcuts system.
  Future<void> _initializeKeyboardShortcuts() async {
    // Create keyboard input service
    _keyboardInput = KeyboardInputService();

    // Create action registry and register all actions
    final registry = ActionRegistry();
    final clipboard = ClipboardService();
    final fileDialog = FileDialogService(logger: _logger);

    registry.registerAll([
      CopyToClipboardAction(clipboard: clipboard),
      SaveToFileAction(fileDialog: fileDialog),
      TogglePauseAction(
        onToggle: ({required isPaused}) => _isPaused = isPaused,
      ),
      ToggleGlobalParamsAction(
        onToggle: ({required hideGlobalParams}) {
          _hideGlobalParams = hideGlobalParams;
          _formatter.hideGlobalParams = hideGlobalParams;
        },
      ),
      ToggleEventParamsAction(
        onToggle: ({required hideEventParams}) {
          _hideEventParams = hideEventParams;
          _formatter.hideEventParams = hideEventParams;
        },
      ),
      ShowStatsAction(),
      ClearScreenAction(),
      QuitAction(onQuit: () => _shouldQuit = true),
    ]);

    // Create shortcut manager
    final configLoader = ShortcutsConfigLoader();
    _shortcutManager = ShortcutManager(
      actionRegistry: registry,
      configLoader: configLoader,
      logger: _logger,
    );

    // Add show help action (needs access to manager)
    registry.register(
      ShowHelpAction(
        registry: registry,
        getBinding: _shortcutManager!.getBinding,
      ),
    );

    // Load custom bindings from config file
    await _shortcutManager!.loadCustomBindings();
  }

  /// Handle a keyboard input event.
  Future<void> _handleKeyEvent(KeyInputEvent event) async {
    if (_shortcutManager == null) return;

    // Build action context with current state
    final context = ActionContext(
      recentEvents: _eventCache.getRecentEvents(1000),
      eventCache: _eventCache,
      logger: _logger,
      isPaused: _isPaused,
      hideGlobalParams: _hideGlobalParams,
      hideEventParams: _hideEventParams,
    );

    await _shortcutManager!.handleKeyEvent(event, context);
  }
}
