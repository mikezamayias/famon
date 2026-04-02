import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:famon/src/platform/clipboard_service.dart';
import 'package:famon/src/version.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

/// {@template issue_command}
/// A command to help users submit issues/bug reports.
///
/// Supports multiple workflows:
/// - Open browser to GitHub issues page with pre-filled template
/// - Use GitHub CLI (gh) to create issue if authenticated
/// - Generate bug report template with system info to clipboard
/// {@endtemplate}
@injectable
class IssueCommand extends Command<int> {
  /// {@macro issue_command}
  IssueCommand({
    required Logger logger,
    required ProcessManager processManager,
    required ClipboardService clipboard,
  })  : _logger = logger,
        _processManager = processManager,
        _clipboard = clipboard;

  final Logger _logger;
  final ProcessManager _processManager;
  final ClipboardService _clipboard;

  @override
  String get description =>
      'Report an issue or bug. Opens GitHub, creates via gh CLI, '
      'or copies template.';

  /// The name of this command as used on the command line.
  static const String commandName = 'issue';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    _logger
      ..info(lightCyan.wrap('🔥 Famon Issue Reporter'))
      ..info('');

    // Collect system information
    final systemInfo = await _collectSystemInfo();

    // Show options
    final choice = _logger.chooseOne(
      'How would you like to submit your issue?',
      choices: [
        'Open browser to GitHub issues (pre-filled template)',
        'Use GitHub CLI (gh) to create issue',
        'Copy bug report template to clipboard',
        'View system info only',
      ],
    );

    return switch (choice) {
      'Open browser to GitHub issues (pre-filled template)' =>
        await _openBrowserWithTemplate(systemInfo),
      'Use GitHub CLI (gh) to create issue' =>
        await _createIssueWithGh(systemInfo),
      'Copy bug report template to clipboard' =>
        await _copyTemplateToClipboard(systemInfo),
      'View system info only' => _showSystemInfo(systemInfo),
      _ => ExitCode.success.code,
    };
  }

  /// Collects system information for the bug report.
  Future<Map<String, String>> _collectSystemInfo() async {
    final info = <String, String>{
      'famon_version': packageVersion,
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'dart_version': await _getDartVersion(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Try to get additional info
    try {
      info['path'] = Platform.environment['PATH'] ?? 'N/A';
      info['shell'] = Platform.environment['SHELL'] ?? 'N/A';
    } on Exception catch (_) {
      // Ignore if we can't get environment info
    }

    return info;
  }

  /// Gets the Dart version string.
  Future<String> _getDartVersion() async {
    try {
      final result = await _processManager.run(['dart', '--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } on Exception catch (_) {
      // Ignore errors
    }
    return 'Unknown';
  }

  /// Opens the browser to the GitHub issues page with pre-filled template.
  Future<int> _openBrowserWithTemplate(Map<String, String> info) async {
    final body = _generateIssueBody(info, includePrompts: true);
    const title = '[Bug] ';

    // URL-encode the parameters
    final encodedBody = Uri.encodeComponent(body);
    final encodedTitle = Uri.encodeComponent(title);

    final url = 'https://github.com/mikezamayias/famon/issues/new?title='
        '$encodedTitle&body=$encodedBody';

    final opened = await _openUrl(url);

    if (opened) {
      _logger
        ..success('Opened browser to GitHub issues page.')
        ..info('')
        ..info(lightYellow.wrap('Next steps:'))
        ..info('1. Complete the title and description')
        ..info('2. Add steps to reproduce the issue')
        ..info('3. Submit the issue');
    } else {
      _logger
        ..err('Failed to open browser. Please visit:')
        ..info(url);
    }

    return opened ? ExitCode.success.code : ExitCode.software.code;
  }

  /// Creates an issue using the GitHub CLI if available.
  Future<int> _createIssueWithGh(Map<String, String> info) async {
    // First check if gh is installed and authenticated
    final ghCheck = await _processManager.run(['gh', '--version']);
    if (ghCheck.exitCode != 0) {
      _logger
        ..err('GitHub CLI (gh) is not installed.')
        ..info('')
        ..info('Install it from: https://cli.github.com/')
        ..info('Or use one of the other options.');
      return ExitCode.software.code;
    }

    // Check authentication
    final authCheck = await _processManager.run(['gh', 'auth', 'status']);
    if (authCheck.exitCode != 0) {
      _logger
        ..err('GitHub CLI is not authenticated.')
        ..info('')
        ..info('Run: gh auth login');
      return ExitCode.software.code;
    }

    _logger
      ..info('${lightGreen.wrap('✓')} GitHub CLI is ready')
      ..info('');

    // Prompt for issue details
    final title = _logger.prompt('Issue title:');
    if (title.isEmpty) {
      _logger.err('Issue title is required.');
      return ExitCode.usage.code;
    }

    final description = _logger.prompt('Description (optional):');

    // Build the body
    final body = _generateIssueBody(info, userDescription: description);

    _logger.info('');
    final confirm = _logger.confirm('Create issue with this title: "$title"?');

    if (!confirm) {
      _logger.info('Cancelled.');
      return ExitCode.success.code;
    }

    // Create the issue
    final progress = _logger.progress('Creating issue');

    try {
      final result = await _processManager.run([
        'gh',
        'issue',
        'create',
        '--repo',
        'mikezamayias/famon',
        '--title',
        title,
        '--body',
        body,
      ]);

      if (result.exitCode == 0) {
        progress.complete('Issue created successfully!');
        _logger
          ..info('')
          ..info(result.stdout.toString());
      } else {
        progress.fail('Failed to create issue');
        _logger.err(result.stderr.toString());
        return ExitCode.software.code;
      }
    } on Exception catch (e) {
      progress.fail('Error: $e');
      return ExitCode.software.code;
    }

    return ExitCode.success.code;
  }

  /// Copies the bug report template to clipboard.
  Future<int> _copyTemplateToClipboard(Map<String, String> info) async {
    if (!_clipboard.isSupported) {
      _logger.err('Clipboard operations are not supported on this platform.');
      return ExitCode.unavailable.code;
    }

    final body = _generateIssueBody(info, includePrompts: true);

    final success = await _clipboard.copy(body);

    if (success) {
      _logger
        ..success('Bug report template copied to clipboard!')
        ..info('')
        ..info(lightYellow.wrap('Next steps:'))
        ..info('1. Go to: https://github.com/mikezamayias/famon/issues/new')
        ..info('2. Paste the template into the description')
        ..info('3. Fill in the details and submit');
    } else {
      _logger
        ..err('Failed to copy to clipboard.')
        ..info('')
        ..info('Here is the template:')
        ..info('')
        ..info(body);
    }

    return success ? ExitCode.success.code : ExitCode.software.code;
  }

  /// Displays system information.
  int _showSystemInfo(Map<String, String> info) {
    _logger
      ..info(lightCyan.wrap('System Information:'))
      ..info('');
    for (final entry in info.entries) {
      final value = lightYellow.wrap(entry.value) ?? entry.value;
      _logger.info('  ${entry.key}: $value');
    }
    return ExitCode.success.code;
  }

  /// Generates the issue body text.
  String _generateIssueBody(
    Map<String, String> info, {
    String? userDescription,
    bool includePrompts = false,
  }) {
    final buffer = StringBuffer();

    if (userDescription != null && userDescription.isNotEmpty) {
      buffer
        ..writeln(userDescription)
        ..writeln();
    }

    if (includePrompts) {
      buffer
        ..writeln('## Describe the bug')
        ..writeln(
          '<!-- A clear and concise description of what the bug is -->',
        )
        ..writeln()
        ..writeln('## Steps to reproduce')
        ..writeln('1. ')
        ..writeln('2. ')
        ..writeln('3. ')
        ..writeln()
        ..writeln('## Expected behavior')
        ..writeln('<!-- What you expected to happen -->')
        ..writeln()
        ..writeln('## Actual behavior')
        ..writeln('<!-- What actually happened -->')
        ..writeln();
    }

    buffer
      ..writeln('## Environment')
      ..writeln()
      ..writeln('| Property | Value |')
      ..writeln('|----------|-------|')
      ..writeln('| famon version | ${info['famon_version']} |')
      ..writeln('| OS | ${info['os']} |')
      ..writeln('| OS Version | ${info['os_version']} |')
      ..writeln('| Dart version | ${info['dart_version']} |')
      ..writeln('| Timestamp | ${info['timestamp']} |')
      ..writeln();

    if (includePrompts) {
      buffer
        ..writeln('## Additional context')
        ..writeln('<!-- Add any other context about the problem here -->')
        ..writeln();
    }

    return buffer.toString();
  }

  /// Opens a URL in the default browser.
  Future<bool> _openUrl(String url) async {
    try {
      late final String command;
      late final List<String> args;

      if (Platform.isMacOS) {
        command = 'open';
        args = [url];
      } else if (Platform.isLinux) {
        command = 'xdg-open';
        args = [url];
      } else if (Platform.isWindows) {
        command = 'start';
        args = ['', url];
      } else {
        return false;
      }

      final result = await _processManager.run([command, ...args]);
      return result.exitCode == 0;
    } on Exception catch (_) {
      return false;
    }
  }
}
