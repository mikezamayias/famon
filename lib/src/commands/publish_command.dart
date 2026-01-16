import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:injectable/injectable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

/// {@template publish_command}
/// A command which helps publish a new release.
///
/// This command automates the release process by:
/// 1. Verifying the working tree is clean
/// 2. Reading the version from pubspec.yaml
/// 3. Verifying CHANGELOG.md has an entry for the version
/// 4. Creating and pushing a version tag
/// 5. Triggering GitHub Actions to publish to pub.dev
/// {@endtemplate}
@injectable
class PublishCommand extends Command<int> {
  /// {@macro publish_command}
  PublishCommand({
    required Logger logger,
    required ProcessManager processManager,
  })  : _logger = logger,
        _processManager = processManager {
    argParser
      ..addFlag(
        'dry-run',
        abbr: 'n',
        help: 'Show what would be done without making changes.',
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skip confirmation prompts.',
        negatable: false,
      )
      ..addOption(
        'branch',
        abbr: 'b',
        help: 'The branch to tag and push from.',
        defaultsTo: 'development',
      );
  }

  final Logger _logger;
  final ProcessManager _processManager;

  @override
  String get description => 'Publish a new release to pub.dev via GitHub.';

  /// The name of this command as used on the command line.
  static const String commandName = 'publish';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final force = argResults?['force'] as bool? ?? false;
    final branch = argResults?['branch'] as String? ?? 'development';

    // Step 1: Check if working tree is clean
    _logger.info('Checking working tree...');
    final isClean = await _isWorkingTreeClean();
    if (!isClean) {
      _logger.err(
        'Working tree is not clean. Commit or stash changes before publishing.',
      );
      return ExitCode.software.code;
    }
    _logger.success('Working tree is clean');

    // Step 2: Read version from pubspec.yaml
    final version = _readVersionFromPubspec();
    _logger.info('Reading version from pubspec.yaml...');
    if (version == null) {
      _logger.err('Could not read version from pubspec.yaml');
      return ExitCode.software.code;
    }
    _logger.success('Version: $version');

    // Step 3: Verify CHANGELOG entry exists
    _logger
      ..info('Verifying CHANGELOG.md...')
      ..detail('Looking for ## [$version] section');
    final hasChangelog = _hasChangelogEntry(version);
    if (!hasChangelog) {
      _logger
        ..err('CHANGELOG.md does not contain an entry for [$version]')
        ..info('Add a section like: ## [$version] - YYYY-MM-DD');
      return ExitCode.software.code;
    }
    _logger.success('CHANGELOG entry found for $version');

    // Step 4: Check if tag already exists
    final tagName = 'v$version';
    _logger.info('Checking if tag $tagName exists...');
    final tagExists = await _tagExists(tagName);
    if (tagExists) {
      _logger.err('Tag $tagName already exists. Bump the version first.');
      return ExitCode.software.code;
    }
    _logger.success('Tag $tagName is available');

    // Step 5: Confirm with user
    if (!force && !dryRun) {
      _logger
        ..info('')
        ..info('Ready to publish:')
        ..info('  Version: $version')
        ..info('  Tag: $tagName')
        ..info('  Branch: $branch')
        ..info('');
      final confirm = _logger.confirm('Proceed with publishing?');
      if (!confirm) {
        _logger.info('Aborted.');
        return ExitCode.success.code;
      }
    }

    if (dryRun) {
      _logger
        ..info('')
        ..info('${lightYellow.wrap('[DRY RUN]')} Would execute:')
        ..info('  git tag -a $tagName -m "Release $version"')
        ..info('  git push origin $tagName')
        ..info('')
        ..info('This would trigger GitHub Actions to:')
        ..info('  1. Create a GitHub release')
        ..info('  2. Publish to pub.dev');
      return ExitCode.success.code;
    }

    // Step 6: Create the tag
    _logger.info('Creating tag $tagName...');
    final tagResult = await _runGit(
      ['tag', '-a', tagName, '-m', 'Release $version'],
    );
    if (tagResult.exitCode != 0) {
      _logger.err('Failed to create tag: ${tagResult.stderr}');
      return ExitCode.software.code;
    }
    _logger.success('Tag $tagName created');

    // Step 7: Push the tag
    _logger.info('Pushing tag $tagName to origin...');
    final pushResult = await _runGit(['push', 'origin', tagName]);
    if (pushResult.exitCode != 0) {
      _logger.err('Failed to push tag: ${pushResult.stderr}');
      // Try to clean up the local tag
      await _runGit(['tag', '-d', tagName]);
      return ExitCode.software.code;
    }
    _logger.success('Tag $tagName pushed to origin');

    // Success!
    const repoUrl =
        'https://github.com/mikezamayias/firebase_analytics_monitor';
    _logger
      ..info('')
      ..success('Release $version initiated successfully!')
      ..info('')
      ..info('GitHub Actions will now:')
      ..info('  1. Create a GitHub release at:')
      ..info('     $repoUrl/releases')
      ..info('  2. Publish to pub.dev')
      ..info('')
      ..info('Monitor progress at:')
      ..info('  $repoUrl/actions');

    return ExitCode.success.code;
  }

  /// Checks if the git working tree is clean (no uncommitted changes).
  Future<bool> _isWorkingTreeClean() async {
    final diffResult = await _runGit(['diff', '--quiet']);
    final diffCachedResult = await _runGit(['diff', '--cached', '--quiet']);
    return diffResult.exitCode == 0 && diffCachedResult.exitCode == 0;
  }

  /// Reads the version string from pubspec.yaml.
  String? _readVersionFromPubspec() {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        return null;
      }
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap;
      return yaml['version'] as String?;
    } on Exception {
      return null;
    }
  }

  /// Checks if CHANGELOG.md has an entry for the given version.
  bool _hasChangelogEntry(String version) {
    try {
      final changelogFile = File('CHANGELOG.md');
      if (!changelogFile.existsSync()) {
        return false;
      }
      final content = changelogFile.readAsStringSync();
      // Look for ## [version] pattern
      return content.contains('## [$version]');
    } on Exception {
      return false;
    }
  }

  /// Checks if a git tag already exists.
  Future<bool> _tagExists(String tagName) async {
    final result = await _runGit(['tag', '-l', tagName]);
    return result.stdout.toString().trim().isNotEmpty;
  }

  /// Runs a git command and returns the result.
  Future<ProcessResult> _runGit(List<String> args) async {
    return _processManager.run(['git', ...args]);
  }
}
