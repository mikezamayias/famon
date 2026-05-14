#!/usr/bin/env dart
// This is a development tool that uses print for CLI output.
// ignore_for_file: avoid_print

import 'dart:io';

const _repoUrl = 'https://github.com/mikezamayias/famon';
const _corePath = 'packages/famon_core/';
const _marker = '---FAMON_CORE---';
const _promptDirectory = '.local/changelog';
const _llmTimeout = Duration(minutes: 2);

final _releaseHeadingPattern = RegExp(r'^## \[[^\]]+\].*$', multiLine: true);

String insertReleaseSection(
  String changelogContent, {
  required String version,
  required String section,
}) {
  final normalizedSection = section.trimRight();
  final existing = _findReleaseSection(changelogContent, version);
  if (existing != null) {
    return changelogContent.replaceRange(
      existing.start,
      existing.end,
      '$normalizedSection\n\n',
    );
  }

  final firstRelease = _releaseHeadingPattern.firstMatch(changelogContent);
  if (firstRelease == null) {
    return '${changelogContent.trimRight()}\n\n$normalizedSection\n';
  }

  return changelogContent.replaceRange(
    firstRelease.start,
    firstRelease.start,
    '$normalizedSection\n\n',
  );
}

List<String> validateChangelogSection(
  String section, {
  required String version,
  required String previousTag,
  required String currentTag,
  required bool coreChanged,
  required bool isCoreChangelog,
}) {
  final errors = <String>[];
  final expectedCompare = '$_repoUrl/compare/$previousTag...$currentTag';
  final lower = section.toLowerCase();
  final headingLine = RegExp(
    r'^## \[' + RegExp.escape(version) + r'\].*$',
    multiLine: true,
  ).firstMatch(section)?.group(0);

  if (headingLine == null) {
    errors.add('Missing heading for $version.');
  }
  if (headingLine == null || !headingLine.contains(expectedCompare)) {
    errors.add('Missing heading compare link $expectedCompare.');
  }
  if (headingLine == null ||
      !RegExp(r'\(\d{4}-\d{2}-\d{2}\)').hasMatch(headingLine)) {
    errors.add('Missing heading date in YYYY-MM-DD format.');
  }
  if (!RegExp(
    r'^### (Added|Changed|Deprecated|Removed|Fixed|Security|Notes)\s+-\s+\S',
    multiLine: true,
  ).hasMatch(section)) {
    errors.add('Section must contain a recognized subsection with a bullet.');
  }

  for (final placeholder in const ['tbd', 'todo', 'lorem']) {
    if (lower.contains(placeholder)) {
      errors.add('Section contains placeholder text: $placeholder.');
    }
  }

  for (final term in const [
    'coderabbit',
    'codacy',
    'release-please',
    'private plan',
  ]) {
    if (lower.contains(term)) {
      errors.add('Section contains internal-noise term: $term.');
    }
  }

  if (isCoreChangelog &&
      coreChanged &&
      lower.contains('no functional changes')) {
    errors.add(
      'Core changed, so the core changelog cannot claim no functional changes.',
    );
  }

  return errors;
}

String buildPrompt({
  required String version,
  required String previousTag,
  required String currentTag,
  required List<String> commits,
  required List<String> pullRequests,
  required bool coreChanged,
}) {
  final today = DateTime.now().toIso8601String().split('T').first;
  final buffer = StringBuffer()
    ..writeln('Draft public changelog sections for famon release $version.')
    ..writeln()
    ..writeln('Return exactly two markdown sections separated by this marker:')
    ..writeln(_marker)
    ..writeln()
    ..writeln('Root changelog target: CHANGELOG.md')
    ..writeln('Core changelog target: packages/famon_core/CHANGELOG.md')
    ..writeln('Previous tag: $previousTag')
    ..writeln('Current tag: $currentTag')
    ..writeln('Release date: $today')
    ..writeln('Compare link: $_repoUrl/compare/$previousTag...$currentTag')
    ..writeln()
    ..writeln('Rules:')
    ..writeln('- Keep entries short and user-facing.')
    ..writeln(
      '- Use Keep a Changelog headings: Added, Changed, Fixed, Security, '
      'Notes.',
    )
    ..writeln(
      '- Do not mention Codacy, CodeRabbit, branch names, private plans, '
      'release-please cleanup, or generic CI plumbing.',
    )
    ..writeln('- Do not invent changes.')
    ..writeln(
      '- Include a ## [$version]($_repoUrl/compare/$previousTag...$currentTag) '
      '($today) heading for each section.',
    )
    ..writeln(
      '- If famon_core has no functional changes, write: No functional '
      'changes. Version bumped to track the CLI release.',
    )
    ..writeln()
    ..writeln('Core package changed: $coreChanged')
    ..writeln()
    ..writeln('Commits:');

  for (final commit in commits) {
    buffer.writeln('- $commit');
  }
  if (pullRequests.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Merged pull requests:');
    for (final pr in pullRequests) {
      buffer.writeln('- $pr');
    }
  }

  return buffer.toString();
}

DraftOutput parseDraftOutput(String output) {
  final parts = output.split(_marker);
  if (parts.length != 2) {
    throw const FormatException(
      'LLM output must contain exactly one $_marker marker.',
    );
  }
  return DraftOutput(parts[0].trim(), parts[1].trim());
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    return;
  }

  final command = args.first;
  if (args.length < 2) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final version = args[1];
  try {
    switch (command) {
      case 'prompt':
        final context = await _loadContext(version);
        final path = await _writePromptFile(context.prompt, version: version);
        print('Wrote changelog prompt to $path');
      case 'validate':
        await _validateFiles(version);
      case 'draft':
        final llm = _optionValue(args, '--llm') ?? 'codex';
        await _draft(version, llm: llm);
      default:
        _printUsage();
        exitCode = 64;
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  } on ChangelogToolException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  } on FileSystemException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  }
}

class DraftOutput {
  const DraftOutput(this.rootSection, this.coreSection);

  final String rootSection;
  final String coreSection;
}

class ChangelogToolException implements Exception {
  const ChangelogToolException(this.message);

  final String message;
}

class _ReleaseSectionRange {
  const _ReleaseSectionRange(this.start, this.end);

  final int start;
  final int end;
}

class _ChangelogContext {
  const _ChangelogContext({
    required this.previousTag,
    required this.currentTag,
    required this.coreChanged,
    required this.prompt,
  });

  final String previousTag;
  final String currentTag;
  final bool coreChanged;
  final String prompt;
}

_ReleaseSectionRange? _findReleaseSection(String content, String version) {
  final heading = RegExp(
    r'^## \[' + RegExp.escape(version) + r'\].*$',
    multiLine: true,
  );
  final match = heading.firstMatch(content);
  if (match == null) return null;

  final nextStart = _releaseHeadingPattern
      .allMatches(content)
      .where((candidate) => candidate.start > match.start)
      .map((candidate) => candidate.start)
      .cast<int?>()
      .firstWhere((_) => true, orElse: () => null);

  return _ReleaseSectionRange(match.start, nextStart ?? content.length);
}

String? _extractReleaseSection(String content, String version) {
  final range = _findReleaseSection(content, version);
  if (range == null) return null;
  return content.substring(range.start, range.end).trim();
}

Future<_ChangelogContext> _loadContext(String version) async {
  final previousTag = await _previousTag();
  final currentTag = 'v$version';
  final commits = await _commits(previousTag);
  final pullRequests = await _pullRequests(previousTag);
  final coreChanged = await _coreChanged(previousTag);
  final prompt = buildPrompt(
    version: version,
    previousTag: previousTag,
    currentTag: currentTag,
    commits: commits,
    pullRequests: pullRequests,
    coreChanged: coreChanged,
  );
  return _ChangelogContext(
    previousTag: previousTag,
    currentTag: currentTag,
    coreChanged: coreChanged,
    prompt: prompt,
  );
}

Future<void> _draft(String version, {required String llm}) async {
  final context = await _loadContext(version);
  final argv = _llmArgs(llm, context.prompt);
  final result = await Process.run(llm, argv).timeout(
    _llmTimeout,
    onTimeout: () {
      throw const ChangelogToolException(
        'LLM command timed out after 2 minutes.',
      );
    },
  );
  if (result.exitCode != 0) {
    final path = await _writePromptFile(context.prompt, version: version);
    throw ChangelogToolException(
      'LLM command failed: $llm ${argv.take(1).join(' ')}. '
      'Prompt saved to $path. ${result.stderr.toString().trim()}',
    );
  }

  final draft = parseDraftOutput(result.stdout.toString());
  final rootErrors = validateChangelogSection(
    draft.rootSection,
    version: version,
    previousTag: context.previousTag,
    currentTag: context.currentTag,
    coreChanged: context.coreChanged,
    isCoreChangelog: false,
  );
  final coreErrors = validateChangelogSection(
    draft.coreSection,
    version: version,
    previousTag: context.previousTag,
    currentTag: context.currentTag,
    coreChanged: context.coreChanged,
    isCoreChangelog: true,
  );
  if (rootErrors.isNotEmpty || coreErrors.isNotEmpty) {
    throw ChangelogToolException(
      ['Generated changelog failed validation.', ...rootErrors, ...coreErrors]
          .join('\n'),
    );
  }

  _writeSection('CHANGELOG.md', version, draft.rootSection);
  _writeSection('packages/famon_core/CHANGELOG.md', version, draft.coreSection);
  print('Drafted changelog sections for $version. Review before committing.');
}

Future<void> _validateFiles(String version) async {
  final previousTag = await _previousTag();
  final currentTag = 'v$version';
  final coreChanged = await _coreChanged(previousTag);
  final root =
      _extractReleaseSection(File('CHANGELOG.md').readAsStringSync(), version);
  final core = _extractReleaseSection(
    File('packages/famon_core/CHANGELOG.md').readAsStringSync(),
    version,
  );

  final errors = <String>[];
  if (root == null) {
    errors.add('CHANGELOG.md is missing section $version.');
  } else {
    errors.addAll(
      validateChangelogSection(
        root,
        version: version,
        previousTag: previousTag,
        currentTag: currentTag,
        coreChanged: coreChanged,
        isCoreChangelog: false,
      ),
    );
  }
  if (core == null) {
    errors.add('packages/famon_core/CHANGELOG.md is missing section $version.');
  } else {
    errors.addAll(
      validateChangelogSection(
        core,
        version: version,
        previousTag: previousTag,
        currentTag: currentTag,
        coreChanged: coreChanged,
        isCoreChangelog: true,
      ),
    );
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  print('Changelog sections for $version are valid.');
}

void _writeSection(String path, String version, String section) {
  final file = File(path);
  final next = insertReleaseSection(
    file.readAsStringSync(),
    version: version,
    section: section,
  );
  file.writeAsStringSync(next);
}

Future<String> _writePromptFile(
  String prompt, {
  required String version,
}) async {
  final directory = Directory(_promptDirectory)..createSync(recursive: true);
  final path = '${directory.path}/draft-$version-prompt.md';
  await File(path).writeAsString(prompt);
  return path;
}

Future<String> _previousTag() async {
  final tag = await _runGit(['describe', '--tags', '--abbrev=0']);
  if (tag.isEmpty) {
    throw const ChangelogToolException('No previous release tag found.');
  }
  return tag;
}

Future<List<String>> _commits(String previousTag) async {
  final output = await _runGit(['log', '$previousTag..HEAD', '--oneline']);
  if (output.isEmpty) return const [];
  return output.split('\n');
}

Future<List<String>> _pullRequests(String previousTag) async {
  final tagDate = (await _runGit([
    'log',
    '-1',
    '--format=%cI',
    previousTag,
  ]))
      .split('T')
      .first;
  final output = await _tryRun('gh', [
    'pr',
    'list',
    '--state',
    'merged',
    '--base',
    'dev',
    '--search',
    'merged:>=$tagDate',
    '--json',
    'number,title',
    '--jq',
    r'.[] | "#\(.number) \(.title)"',
  ]);
  if (output == null || output.isEmpty) return const [];
  return output.split('\n');
}

Future<bool> _coreChanged(String previousTag) async {
  final output = await _runGit(['diff', '--name-only', '$previousTag..HEAD']);
  return output.split('\n').any((path) => path.startsWith(_corePath));
}

Future<String> _runGit(List<String> args) async {
  final result = await Process.run('git', args);
  if (result.exitCode != 0) {
    throw ChangelogToolException((result.stderr as String).trim());
  }
  return (result.stdout as String).trim();
}

Future<String?> _tryRun(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}

List<String> _llmArgs(String llm, String prompt) {
  switch (llm) {
    case 'codex':
      return ['exec', prompt];
    case 'claude':
      return ['-p', prompt];
    case 'gemini':
      return ['--yolo', prompt];
    default:
      throw ArgumentError('Unsupported --llm value: $llm');
  }
}

String? _optionValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

void _printUsage() {
  print(
    'Usage: dart run tool/changelog.dart <prompt|draft|validate> <version>',
  );
  print('Examples:');
  print('  dart run tool/changelog.dart prompt 1.4.2');
  print('  dart run tool/changelog.dart draft 1.4.2 --llm codex');
  print('  dart run tool/changelog.dart validate 1.4.2');
}
