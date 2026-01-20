#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Updates the version in both pubspec.yaml and lib/src/version.dart.
///
/// Usage: dart run tool/update_version.dart <version>
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/update_version.dart <version>');
    print('Example: dart run tool/update_version.dart 1.4.0');
    exit(1);
  }

  final version = args[0];

  // Validate version format
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$');
  if (!versionRegex.hasMatch(version)) {
    print('Error: Invalid version format: $version');
    print('Expected format: x.y.z (e.g., 1.4.0 or 1.4.0-beta.1)');
    exit(1);
  }

  // Update pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  var pubspecContent = pubspecFile.readAsStringSync();
  final pubspecVersionRegex = RegExp(r'^version:\s*.+$', multiLine: true);
  if (!pubspecVersionRegex.hasMatch(pubspecContent)) {
    print('Error: Could not find version field in pubspec.yaml');
    exit(1);
  }

  pubspecContent =
      pubspecContent.replaceFirst(pubspecVersionRegex, 'version: $version');
  pubspecFile.writeAsStringSync(pubspecContent);
  print('Updated pubspec.yaml to version $version');

  // Update lib/src/version.dart
  final versionFile = File('lib/src/version.dart');
  if (!versionFile.existsSync()) {
    print('Error: lib/src/version.dart not found');
    exit(1);
  }

  var versionContent = versionFile.readAsStringSync();
  final versionConstRegex =
      RegExp("const packageVersion = '[^']+';", multiLine: true);
  if (!versionConstRegex.hasMatch(versionContent)) {
    print('Error: Could not find packageVersion in lib/src/version.dart');
    exit(1);
  }

  versionContent = versionContent.replaceFirst(
    versionConstRegex,
    "const packageVersion = '$version';",
  );
  versionFile.writeAsStringSync(versionContent);
  print('Updated lib/src/version.dart to version $version');

  print('\nVersion updated to $version');
  print('Remember to update CHANGELOG.md with changes for this version.');
}
