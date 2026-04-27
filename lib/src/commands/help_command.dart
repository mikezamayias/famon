import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that displays detailed help and usage examples.
class HelpCommand extends Command<int> {
  /// Creates a new [HelpCommand].
  ///
  /// If [logger] is not provided, a default [Logger] will be used.
  HelpCommand({Logger? logger}) : _logger = logger ?? Logger();

  @override
  final name = 'help';

  @override
  final description = 'Show detailed help and usage examples.';

  final Logger _logger;

  @override
  Future<int> run() async {
    _showDetailedHelp();
    return 0;
  }

  void _showDetailedHelp() {
    _logger
      ..info('🔥 Firebase Analytics Monitor (famon)')
      ..info(
        'Real-time monitoring of Firebase Analytics events from Android logcat',
      )
      ..info('')
      ..info('${lightCyan.wrap('USAGE:')}')
      ..info('  famon monitor [OPTIONS]')
      ..info('')
      ..info('${lightCyan.wrap('OPTIONS:')}')
      ..info(
        '  -h, --hide EVENT_NAME        Hide specific event names from output',
      )
      ..info('  -s, --show-only EVENT_NAME   Only show specified event names')
      ..info('      --no-color               Disable colored output')
      ..info(
        '      --suggestions            '
        'Show smart suggestions based on session history',
      )
      ..info(
        '      --stats                  Show session statistics periodically',
      )
      ..info('  -v, --version               Show version information')
      ..info('      --help                  Show this help message')
      ..info('')
      ..info('${lightCyan.wrap('EXAMPLES:')}')
      ..info('')
      ..info('${lightGreen.wrap('Basic monitoring:')}')
      ..info('  famon monitor')
      ..info('')
      ..info('${lightGreen.wrap('Hide specific events:')}')
      ..info('  famon monitor --hide screen_view --hide app_update')
      ..info('  famon monitor -h screen_view -h _vs')
      ..info('')
      ..info('${lightGreen.wrap('Show only specific events:')}')
      ..info('  famon monitor --show-only my_event --show-only another_event')
      ..info('  famon monitor -s my_event -s custom_action')
      ..info('')
      ..info('${lightGreen.wrap('Disable colors (for CI/logs):')}')
      ..info('  famon monitor --no-color')
      ..info('')
      ..info('${lightGreen.wrap('With smart suggestions and stats:')}')
      ..info('  famon monitor --suggestions --stats')
      ..info('')
      ..info('${lightGreen.wrap('Report an issue:')}')
      ..info('  famon issue')
      ..info('')
      ..info('${lightCyan.wrap('OTHER COMMANDS:')}')
      ..info('  famon database              Manage local event database')
      ..info('  famon update                Check for and install updates')
      ..info('  famon issue                 Report a bug or issue')
      ..info('  famon help                  Show this detailed help')
      ..info('')
      ..info('${lightYellow.wrap('PREREQUISITES:')}')
      ..info('  • Android SDK platform-tools installed')
      ..info('  • adb in PATH')
      ..info('  • Android device/emulator connected')
      ..info('  • USB debugging enabled')
      ..info('  • App with Firebase Analytics running')
      ..info('')
      ..info('${lightYellow.wrap('TROUBLESHOOTING:')}')
      ..info('  • Run "adb devices" to verify device connection')
      ..info('  • Ensure your app has Firebase Analytics events')
      ..info('  • Check logcat permissions with "adb logcat | head"')
      ..info('')
      ..info('${lightCyan.wrap('EVENT FILTERING TIPS:')}')
      ..info('  • Use --hide to remove noisy events like screen_view or _vs')
      ..info('  • Use --show-only to focus on specific e-commerce events')
      ..info('  • Enable --suggestions to get filtering recommendations')
      ..info('')
      ..info(
        'For more information, visit: '
        'https://github.com/mikezamayias/firebase_analytics_monitor',
      );
  }
}
