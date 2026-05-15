import 'dart:async';
import 'dart:io';

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

      expect(errors, contains(contains('Core changed')));
    });

    test('requires compare link and date on the heading line', () {
      final errors = changelog.validateChangelogSection(
        '''
## [1.4.2]

### Fixed
- Improved release safety. See https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2 (2026-05-15).
''',
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        coreChanged: false,
        isCoreChangelog: false,
      );

      expect(errors, contains(contains('heading compare link')));
      expect(errors, contains(contains('heading date')));
    });

    test('requires a recognized subsection with a bullet', () {
      final errors = changelog.validateChangelogSection(
        '''
## [1.4.2](https://github.com/mikezamayias/famon/compare/v1.4.1...v1.4.2) (2026-05-15)

- Improved release safety.
''',
        version: '1.4.2',
        previousTag: 'v1.4.1',
        currentTag: 'v1.4.2',
        coreChanged: false,
        isCoreChangelog: false,
      );

      expect(errors, contains(contains('recognized subsection')));
    });
  });

  group('buildPrompt', () {
    test('includes package instructions and release context', () {
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

  group('runLlmCommand', () {
    test('closes stdin after starting the child process', () async {
      late _FakeProcess process;

      await changelog.runLlmCommand(
        'codex',
        ['exec', 'prompt'],
        startProcess: (executable, arguments) async {
          return process = _FakeProcess(exitCode: 0);
        },
      );

      expect(process.stdinClosed, isTrue);
    });

    test('kills the child process when the command times out', () async {
      _FakeProcess? process;

      final command = changelog.runLlmCommand(
        'codex',
        ['exec', 'prompt'],
        timeout: Duration.zero,
        startProcess: (executable, arguments) async {
          final fakeProcess = _FakeProcess();
          process = fakeProcess;
          return fakeProcess;
        },
      );

      await expectLater(
        command,
        throwsA(
          isA<changelog.ChangelogToolException>().having(
            (exception) => exception.message,
            'message',
            contains('0 seconds'),
          ),
        ),
      );
      expect(process?.killed, isTrue);
    });
  });
}

class _FakeProcess implements Process {
  _FakeProcess({int? exitCode}) {
    if (exitCode != null) {
      _exitCode.complete(exitCode);
    }
  }

  final _exitCode = Completer<int>();
  final _stdinConsumer = _CloseTrackingConsumer();

  bool killed = false;
  bool get stdinClosed => _stdinConsumer.closed;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  int get pid => 123;

  @override
  IOSink get stdin => IOSink(_stdinConsumer);

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    _exitCode.complete(-1);
    return true;
  }
}

class _CloseTrackingConsumer implements StreamConsumer<List<int>> {
  bool closed = false;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> close() async {
    closed = true;
  }
}
