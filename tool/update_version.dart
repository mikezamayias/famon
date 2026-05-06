#!/usr/bin/env dart
// This is a development tool that uses print for CLI output.
// ignore_for_file: avoid_print

import 'dart:io';

/// Updates the version across all monorepo sources of truth:
///   - pubspec.yaml                          (root famon CLI)
///   - packages/famon_core/pubspec.yaml      (famon_core library)
///   - lib/src/version.dart                  (runtime version constant)
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

  _updatePubspecVersion('pubspec.yaml', version);
  _updatePubspecVersion('packages/famon_core/pubspec.yaml', version);
  _updateDartVersionConst('lib/src/version.dart', version);

  print('\nVersion updated to $version across all sources.');
  print('Remember to update both CHANGELOG.md files with changes.');
}

void _updatePubspecVersion(String path, String version) {
  final file = File(path);
  if (!file.existsSync()) {
    print('Error: $path not found');
    exit(1);
  }

  var content = file.readAsStringSync();
  final regex = RegExp(r'^version:\s*.+$', multiLine: true);
  if (!regex.hasMatch(content)) {
    print('Error: Could not find version field in $path');
    exit(1);
  }

  content = content.replaceFirst(regex, 'version: $version');
  file.writeAsStringSync(content);
  print('Updated $path to version $version');
}

void _updateDartVersionConst(String path, String version) {
  final file = File(path);
  if (!file.existsSync()) {
    print('Error: $path not found');
    exit(1);
  }

  var content = file.readAsStringSync();
  final regex = RegExp(
    "const packageVersion = '[^']+';",
    multiLine: true,
  );
  if (!regex.hasMatch(content)) {
    print('Error: Could not find packageVersion in $path');
    exit(1);
  }

  content = content.replaceFirst(
    regex,
    "const packageVersion = '$version';",
  );
  file.writeAsStringSync(content);
  print('Updated $path to version $version');
}
