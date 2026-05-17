# LLM Changelog Tool Implementation Plan

<!-- markdownlint-disable MD013 -->

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `tool/changelog.dart` as a repo-local maintainer tool with `prompt`, `draft`, and `validate` subcommands for release changelogs.

**Architecture:** Keep the tool self-contained in one Dart script under `tool/`. The script gathers release context from git/gh, builds a strict prompt, optionally calls a local LLM CLI, inserts generated markdown into the two changelogs, and validates the result deterministically. Tests live under `test/tool/` and cover pure parsing/validation behavior through small fixtures.

**Tech Stack:** Dart CLI script, `dart:io` processes/files, existing `test` package, repository `CHANGELOG.md` files, and local `codex`/`claude` CLIs as optional runtime dependencies. Broad-permission providers are intentionally unsupported.

---

## File structure

- Create `tool/changelog.dart`: single maintainer CLI with subcommands and small internal classes/functions.
- Create `test/tool/changelog_tool_test.dart`: unit tests for version parsing, section extraction, insertion, and validation rules.
- Modify `.gitignore`: ignore `.local/` prompt artifacts.
- Modify `doc/RELEASE_FLOW.md`: add a short mention of the changelog helper under the existing changelog step.

## Task 1: Add testable changelog primitives

**Files:**

- Create: `test/tool/changelog_tool_test.dart`
- Create: `tool/changelog.dart`

- [ ] **Step 1: Write failing tests for changelog section handling**

Create `test/tool/changelog_tool_test.dart` with these tests:

```dart
import 'package:test/test.dart';

import '../../tool/changelog.dart' as changelog;

void main() {
  group('insertReleaseSection', () {
    test('inserts a new release below the changelog intro', () {
      const input = '''
# Changelog

All notable changes to this project will be documented in this file.

## [1.4.1](https://github.com/mikezamayias/famon/compare/v1.4.0...v1.4.1) (2026-05-07)

### Fixed
- Existing entry.
''';

      final result = changelog.insertReleaseSection(
        input,
        version: '1.4.2',
        section: '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Fixed
- Improved release safety.
''',
      );

      expect(
        result.indexOf('## [1.4.2]'),
        lessThan(result.indexOf('## [1.4.1]')),
      );
      expect(result, contains('Improved release safety.'));
    });

    test('replaces an existing section for the same version', () {
      const input = '''
# Changelog

All notable changes to this project will be documented in this file.

## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Fixed
- Old draft.

## [1.4.1](https://github.com/mikezamayias/famon/compare/v1.4.0...v1.4.1) (2026-05-07)

### Fixed
- Existing entry.
''';

      final result = changelog.insertReleaseSection(
        input,
        version: '1.4.2',
        section: '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Fixed
- New draft.
''',
      );

      expect(result, contains('- New draft.'));
      expect(result, isNot(contains('- Old draft.')));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: FAIL because `tool/changelog.dart` does not exist.

- [ ] **Step 3: Implement minimal exported primitives**

Create `tool/changelog.dart` with:

```dart
#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

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

_Range? _findReleaseSection(String content, String version) {
  final heading = RegExp(r'^## \[' + RegExp.escape(version) + r'\].*$', multiLine: true);
  final match = heading.firstMatch(content);
  if (match == null) return null;

  final next = _releaseHeadingPattern.allMatches(content).firstWhere(
        (candidate) => candidate.start > match.start,
        orElse: () => RegExpMatchAdapter(content.length),
      );

  return _Range(match.start, next.start);
}

class _Range {
  const _Range(this.start, this.end);

  final int start;
  final int end;
}

class RegExpMatchAdapter implements RegExpMatch {
  RegExpMatchAdapter(this.start);

  @override
  final int start;

  @override
  int get end => start;

  @override
  String? operator [](int group) => throw UnsupportedError('No groups');

  @override
  String? group(int group) => throw UnsupportedError('No groups');

  @override
  int get groupCount => 0;

  @override
  List<String?> groups(List<int> groupIndices) => throw UnsupportedError('No groups');

  @override
  Pattern get pattern => '';

  @override
  String get input => '';
}

void main(List<String> args) {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    return;
  }

  stderr.writeln('Subcommands are implemented in later tasks.');
  exit(64);
}

void _printUsage() {
  print('Usage: dart run tool/changelog.dart <prompt|draft|validate> <version>');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: PASS.

Note: if the `RegExpMatchAdapter` feels too awkward during implementation, replace it with a simple helper that returns the next heading start as an `int`. Keep the public surface unchanged.

## Task 2: Add validation rules

**Files:**

- Modify: `test/tool/changelog_tool_test.dart`
- Modify: `tool/changelog.dart`

- [ ] **Step 1: Write failing tests for validation**

Append tests:

```dart
  group('validateChangelogSection', () {
    test('accepts a valid section', () {
      final errors = changelog.validateChangelogSection(
        '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Fixed
- Improved release safety.
''',
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        coreChanged: false,
        isCoreChangelog: false,
      );

      expect(errors, isEmpty);
    });

    test('rejects placeholders and internal noise', () {
      final errors = changelog.validateChangelogSection(
        '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Fixed
- TODO: mention Codacy cleanup.
''',
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        coreChanged: false,
        isCoreChangelog: false,
      );

      expect(errors, contains(contains('placeholder')));
      expect(errors, contains(contains('internal-noise')));
    });

    test('rejects no-functional-change core note when core changed', () {
      final errors = changelog.validateChangelogSection(
        '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

### Notes
- No functional changes. Version bumped to track the CLI release.
''',
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        coreChanged: true,
        isCoreChangelog: true,
      );

      expect(errors, contains(contains('core changed')));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: FAIL because `validateChangelogSection` is missing.

- [ ] **Step 3: Implement validation helpers**

Add public helpers in `tool/changelog.dart`:

```dart
List<String> validateChangelogSection(
  String section, {
  required String version,
  required String previousTag,
  required String currentTag,
  required bool coreChanged,
  required bool isCoreChangelog,
}) {
  final errors = <String>[];
  final expectedCompare = 'https://github.com/mikezamayias/famon/compare/$previousTag...$currentTag';

  if (!RegExp(r'^## \[' + RegExp.escape(version) + r'\].*$', multiLine: true).hasMatch(section)) {
    errors.add('Missing heading for $version.');
  }
  if (!section.contains(expectedCompare)) {
    errors.add('Missing compare link $expectedCompare.');
  }
  if (!RegExp(r'\(\d{4}-\d{2}-\d{2}\)').hasMatch(section)) {
    errors.add('Missing release date in YYYY-MM-DD format.');
  }
  if (!RegExp(r'^-\s+\S', multiLine: true).hasMatch(section)) {
    errors.add('Section is empty.');
  }

  final lower = section.toLowerCase();
  const placeholders = ['tbd', 'todo', 'lorem'];
  for (final placeholder in placeholders) {
    if (lower.contains(placeholder)) {
      errors.add('Section contains placeholder text: $placeholder.');
    }
  }

  const internalNoise = ['coderabbit', 'codacy', 'release-please', 'private plan'];
  for (final term in internalNoise) {
    if (lower.contains(term)) {
      errors.add('Section contains internal-noise term: $term.');
    }
  }

  if (isCoreChangelog && coreChanged && lower.contains('no functional changes')) {
    errors.add('Core changed, so the core changelog cannot claim no functional changes.');
  }

  return errors;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: PASS.

## Task 3: Implement context collection and prompt command

**Files:**

- Modify: `test/tool/changelog_tool_test.dart`
- Modify: `tool/changelog.dart`
- Modify: `.gitignore`

- [ ] **Step 1: Add tests for prompt content**

Add a pure prompt-builder test:

```dart
  group('buildPrompt', () {
    test('includes package-specific instructions and commit context', () {
      final prompt = changelog.buildPrompt(
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        commits: ['abc123 fix: improve release safety'],
        pullRequests: ['#93 chore: release governance cleanup'],
        coreChanged: false,
      );

      expect(prompt, contains('CHANGELOG.md'));
      expect(prompt, contains('packages/famon_core/CHANGELOG.md'));
      expect(prompt, contains('abc123 fix: improve release safety'));
      expect(prompt, contains('No functional changes'));
      expect(prompt, contains('Do not mention Codacy'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: FAIL because `buildPrompt` is missing.

- [ ] **Step 3: Implement prompt builder and `prompt` command**

Add helpers:

```dart
String buildPrompt({
  required String version,
  required String previousTag,
  required String currentTag,
  required List<String> commits,
  required List<String> pullRequests,
  required bool coreChanged,
}) {
  final buffer = StringBuffer()
    ..writeln('Draft public changelog sections for famon release $version.')
    ..writeln()
    ..writeln('Return exactly two markdown sections, separated by this marker:')
    ..writeln('---FAMON_CORE---')
    ..writeln()
    ..writeln('Root changelog target: CHANGELOG.md')
    ..writeln('Core changelog target: packages/famon_core/CHANGELOG.md')
    ..writeln('Previous tag: $previousTag')
    ..writeln('Current tag: $currentTag')
    ..writeln('Compare link: https://github.com/mikezamayias/famon/compare/$previousTag...$currentTag')
    ..writeln()
    ..writeln('Rules:')
    ..writeln('- Keep entries short and user-facing.')
    ..writeln('- Use Keep a Changelog headings such as Added, Changed, Fixed, Security, Notes.')
    ..writeln('- Do not mention Codacy, CodeRabbit, branch names, private plans, release-please cleanup, or generic CI plumbing.')
    ..writeln('- Do not invent changes.')
    ..writeln('- Include a ## [$version](...) (YYYY-MM-DD) heading for each section.')
    ..writeln('- If famon_core has no functional changes, use: No functional changes. Version bumped to track the CLI release.')
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
```

Add process helpers:

```dart
Future<String> _runGit(List<String> args) async {
  final result = await Process.run('git', args);
  if (result.exitCode != 0) {
    throw StateError((result.stderr as String).trim());
  }
  return (result.stdout as String).trim();
}

Future<String?> _tryRun(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}
```

Wire `main` so `prompt X.Y.Z` writes `.local/changelog/draft-X.Y.Z-prompt.md`.

- [ ] **Step 4: Ignore `.local/` artifacts**

Add to `.gitignore`:

```gitignore
.local/
```

- [ ] **Step 5: Run test to verify it passes**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: PASS.

## Task 4: Implement draft command

**Files:**

- Modify: `test/tool/changelog_tool_test.dart`
- Modify: `tool/changelog.dart`

- [ ] **Step 1: Add tests for LLM output parsing**

Add tests:

```dart
  group('parseDraftOutput', () {
    test('splits root and core sections', () {
      final draft = changelog.parseDraftOutput('''
## [1.4.2](link) (2026-05-15)

### Fixed
- Root fix.

---FAMON_CORE---

## [1.4.2](link) (2026-05-15)

### Notes
- No functional changes. Version bumped to track the CLI release.
''');

      expect(draft.rootSection, contains('Root fix'));
      expect(draft.coreSection, contains('No functional changes'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: FAIL because `parseDraftOutput` is missing.

- [ ] **Step 3: Implement parsing and local LLM invocation**

Add:

```dart
DraftOutput parseDraftOutput(String output) {
  const marker = '---FAMON_CORE---';
  final parts = output.split(marker);
  if (parts.length != 2) {
    throw FormatException('LLM output must contain exactly one $marker marker.');
  }
  return DraftOutput(parts[0].trim(), parts[1].trim());
}

class DraftOutput {
  const DraftOutput(this.rootSection, this.coreSection);

  final String rootSection;
  final String coreSection;
}
```

Implement `draft X.Y.Z --llm codex|claude --yes`:

- Build the same prompt as `prompt`.
- Call the selected executable only when `--yes` is present.
- Fence commit and pull request text as untrusted data in the prompt.
- Enforce the prompt-size budget before invoking an LLM.
- If the executable is unavailable or returns non-zero, write the prompt file and exit with a clear error.
- Parse the output with `parseDraftOutput`.
- Insert sections into both changelogs with `insertReleaseSection`.
- Run validation and fail if generated content is invalid.

Keep CLI adapters minimal:

```dart
List<String> _llmArgs(String llm, String prompt) {
  switch (llm) {
    case 'codex':
      return [
        'exec',
        '--sandbox',
        'read-only',
        '--ignore-user-config',
        '--ignore-rules',
        '--ephemeral',
        prompt,
      ];
    case 'claude':
      return ['-p', '--allowedTools', '', prompt];
    default:
      throw ChangelogToolException('Unsupported --llm value: $llm');
  }
}
```

If a CLI's real argument shape differs during verification, adjust only that
adapter. Do not add providers that require broad tool permissions for this
prose-only changelog task.

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/tool/changelog_tool_test.dart`

Expected: PASS.

## Task 5: Implement validate command and release docs update

**Files:**

- Modify: `tool/changelog.dart`
- Modify: `doc/RELEASE_FLOW.md`

- [ ] **Step 1: Implement `validate X.Y.Z` command**

Behavior:

- Determine previous tag.
- Determine whether `packages/famon_core/` changed since previous tag.
- Extract the target section from each changelog.
- Run `validateChangelogSection` for each.
- Print all errors and exit non-zero if any exist.
- Print a short success message on success.

- [ ] **Step 2: Update release docs briefly**

Modify `doc/RELEASE_FLOW.md` section `### 2. Update both changelogs` to
include:

```markdown
You can draft and validate both sections with the maintainer-only helper. The
safe default is to write and review the prompt first:

~~~bash
dart run tool/changelog.dart prompt X.Y.Z
~~~

If the prompt looks reasonable, explicitly opt in to the LLM call:

~~~bash
dart run tool/changelog.dart draft X.Y.Z --llm codex --yes
dart run tool/changelog.dart validate X.Y.Z
~~~

The helper only drafts text and validates formatting. Review the generated
entries before committing the release-prep PR. The LLM path is guarded by
`--yes`, a prompt-size budget, a short timeout, and fenced untrusted release
data so commit messages and pull request titles are treated as data rather than
instructions. Codex runs read-only with user config/rules ignored, and Claude
runs with no tools allowed.
```

- [ ] **Step 3: Run command-level smoke checks**

Run:

```bash
dart run tool/changelog.dart --help
dart run tool/changelog.dart prompt 9.9.9
```

Expected:

- Help prints usage.
- Prompt command writes `.local/changelog/draft-9.9.9-prompt.md`.

Remove the generated `.local/` file after confirming `.gitignore` ignores it.

- [ ] **Step 4: Run tests and analyzer**

Run:

```bash
dart format tool/changelog.dart test/tool/changelog_tool_test.dart
dart test test/tool/changelog_tool_test.dart
dart analyze --fatal-infos --fatal-warnings tool test/tool
```

Expected: all pass.

## Task 6: Final verification and commit

**Files:**

- Modify: all files changed in previous tasks

- [ ] **Step 1: Run release-adjacent checks**

Run:

```bash
dart test
dart analyze --fatal-infos --fatal-warnings lib test tool
```

Expected: all pass.

- [ ] **Step 2: Inspect git diff**

Run: `git diff -- tool/changelog.dart test/tool/changelog_tool_test.dart .gitignore doc/RELEASE_FLOW.md docs/superpowers/specs/2026-05-15-llm-changelog-tool-design.md docs/superpowers/plans/2026-05-15-llm-changelog-tool.md`

Expected: changes match this plan and do not modify public `famon` CLI behavior.

- [ ] **Step 3: Commit if requested**

If committing is requested, stage only relevant files:

```bash
git add tool/changelog.dart test/tool/changelog_tool_test.dart .gitignore doc/RELEASE_FLOW.md docs/superpowers/specs/2026-05-15-llm-changelog-tool-design.md docs/superpowers/plans/2026-05-15-llm-changelog-tool.md
git commit -m "chore: add llm changelog helper"
```

Do not stage unrelated untracked files such as `PLAN.md` or `tasks/` unless
explicitly requested.
