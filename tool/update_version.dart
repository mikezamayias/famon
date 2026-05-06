#!/usr/bin/env dart
// This is a development tool that uses print for CLI output.
// ignore_for_file: avoid_print

import 'dart:io';

const _pubspecVersionPattern = r'^version:\s*.+$';
const _dartVersionPattern = "const packageVersion = '[^']+';";
// Matches the hosted-dependency declaration (with caret constraint) only —
// the path-based `dependency_overrides` entry does not start with `^` and is
// safely ignored.
const _famonCoreDepPattern = r'famon_core:\s*\^[^\s]+';

/// Updates the version across all monorepo sources of truth:
///   - pubspec.yaml                          (root famon CLI)
///       * `version:` field
///       * `famon_core: ^X.Y.Z` constraint, kept in lockstep so major bumps
///         (e.g. 2.0.0) do not leave the CLI resolving an old core version.
///   - packages/famon_core/pubspec.yaml      (famon_core library `version:`)
///   - lib/src/version.dart                  (runtime `packageVersion`)
///
/// All updates are validated up front and applied atomically: if any source
/// cannot be located or rewritten, no file is mutated. This avoids the
/// half-bumped state that previously caused git/pub.dev version drift.
///
/// Usage: `dart run tool/update_version.dart <version>`
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/update_version.dart <version>');
    print('Example: dart run tool/update_version.dart 1.4.0');
    exit(1);
  }

  final version = args[0];

  final versionRegex = RegExp(r'^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$');
  if (!versionRegex.hasMatch(version)) {
    print('Error: Invalid version format: $version');
    print('Expected format: x.y.z (e.g., 1.4.0 or 1.4.0-beta.1)');
    exit(1);
  }

  final updates = <_FileUpdate>[
    _FileUpdate('pubspec.yaml', [
      (
        pattern: RegExp(_pubspecVersionPattern, multiLine: true),
        replacement: 'version: $version',
        description: 'version: field',
      ),
      (
        pattern: RegExp(_famonCoreDepPattern),
        replacement: 'famon_core: ^$version',
        description: 'famon_core dependency constraint',
      ),
    ]),
    _FileUpdate('packages/famon_core/pubspec.yaml', [
      (
        pattern: RegExp(_pubspecVersionPattern, multiLine: true),
        replacement: 'version: $version',
        description: 'version: field',
      ),
    ]),
    _FileUpdate('lib/src/version.dart', [
      (
        pattern: RegExp(_dartVersionPattern),
        replacement: "const packageVersion = '$version';",
        description: 'packageVersion constant',
      ),
    ]),
  ];

  // Phase 1 — preflight every update. Any failure aborts before any write.
  for (final update in updates) {
    final error = update.preflight();
    if (error != null) {
      print('Error: $error');
      exit(1);
    }
  }

  // Phase 2 — apply writes. If write N throws after writes 1..N-1 succeeded,
  // restore those files from the snapshot captured during preflight.
  final completed = <_FileUpdate>[];
  try {
    for (final update in updates) {
      update.apply();
      completed.add(update);
      print('Updated ${update.path} → version $version');
    }
  } on FileSystemException catch (e) {
    stderr.writeln(
      'Error: write failed for ${e.path ?? '<unknown>'}: ${e.message}',
    );
    for (final done in completed) {
      done.restore();
      stderr.writeln('Reverted ${done.path}');
    }
    exit(1);
  }

  print('\nVersion updated to $version across all sources.');
  print('Remember to update both CHANGELOG.md files with changes.');
}

typedef _Rewrite = ({
  RegExp pattern,
  String replacement,
  String description,
});

class _FileUpdate {
  _FileUpdate(this.path, this.rewrites);

  final String path;
  final List<_Rewrite> rewrites;

  String? _originalContent;
  String? _newContent;

  /// Returns null on success, or an error message describing why the update
  /// cannot be applied. Captures the file's current contents so [restore]
  /// can revert if a later update in the batch fails.
  String? preflight() {
    final file = File(path);
    if (!file.existsSync()) {
      return '$path not found';
    }

    final original = file.readAsStringSync();
    var next = original;
    for (final rewrite in rewrites) {
      if (!rewrite.pattern.hasMatch(next)) {
        return 'Could not locate ${rewrite.description} in $path';
      }
      next = next.replaceFirst(rewrite.pattern, rewrite.replacement);
    }

    _originalContent = original;
    _newContent = next;
    return null;
  }

  void apply() {
    final newContent = _newContent;
    if (newContent == null) {
      throw StateError('apply() called before preflight() for $path');
    }
    File(path).writeAsStringSync(newContent);
  }

  void restore() {
    final original = _originalContent;
    if (original == null) return;
    try {
      File(path).writeAsStringSync(original);
    } on FileSystemException catch (e) {
      stderr.writeln(
        'WARNING: failed to restore $path: ${e.message}. '
        'Inspect manually with `git diff $path`.',
      );
    }
  }
}
