// Generates a Codacy issues report for the famon repository on a given
// branch and either prints it to stdout or writes it to a snapshot file.
//
// Codacy's v3 API exposes public-repo issues without authentication.
// We POST to the issues-search endpoint, paginate via the `cursor` in
// the response, group findings by category + file, and emit a tight
// Markdown checklist that PLAN.md Phase 1.5 and Phase 5 can drive
// work from.
//
// Usage:
//
//   dart run tool/codacy_report.dart
//   dart run tool/codacy_report.dart --branch dev
//   dart run tool/codacy_report.dart --category Security
//   dart run tool/codacy_report.dart --snapshot doc/CODACY_BASELINE.md
//   dart run tool/codacy_report.dart --diff doc/CODACY_BASELINE.md
//
// Flags:
//   --branch <name>   Target branch (default: dev).
//   --category <name> Filter to a single Codacy category (e.g. Security,
//                     "Error prone", Documentation, "Code style",
//                     "Best practice", Comprehensibility).
//   --snapshot <path> Write output to <path> instead of stdout.
//   --diff <path>     Compare current state against the saved snapshot
//                     at <path> and print a counts-only delta.
//
// The script has zero package dependencies — uses `dart:io`'s
// `HttpClient` directly so it can run from a clean checkout.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _baseUrl = 'https://app.codacy.com/api/v3/analysis/organizations/gh/'
    'mikezamayias/repositories/famon/issues/search';
const _pageSize = 100;
const _maxPages = 100;

Future<int> main(List<String> args) async {
  final flags = _parseFlags(args);
  final branch = flags['branch'] ?? 'dev';
  final categoryFilter = flags['category'];
  final snapshotPath = flags['snapshot'];
  final diffPath = flags['diff'];

  if (snapshotPath != null && diffPath != null) {
    stderr.writeln('Cannot combine --snapshot and --diff.');
    return 2;
  }

  final issues = await _fetchAllIssues(branch: branch);
  if (issues == null) {
    return 1;
  }

  final filtered = categoryFilter == null
      ? issues
      : issues
          .where(
            (i) =>
                (i['category'] as String).toLowerCase() ==
                categoryFilter.toLowerCase(),
          )
          .toList();

  if (diffPath != null) {
    return _emitDiff(filtered, branch, diffPath);
  }

  final markdown = _renderMarkdown(
    filtered,
    branch: branch,
    categoryFilter: categoryFilter,
    totalBeforeFilter: issues.length,
  );

  if (snapshotPath != null) {
    await File(snapshotPath).writeAsString(markdown);
    stderr.writeln(
      'Wrote ${filtered.length} issue(s) for branch "$branch" to '
      '$snapshotPath.',
    );
  } else {
    stdout.write(markdown);
  }

  return 0;
}

Map<String, String> _parseFlags(List<String> args) {
  final flags = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
      stderr.writeln('Flag $arg expects a value.');
      exit(2);
    }
    flags[arg.substring(2)] = args[i + 1];
    i++;
  }
  return flags;
}

Future<List<Map<String, dynamic>>?> _fetchAllIssues({
  required String branch,
}) async {
  final client = HttpClient();
  try {
    final results = <Map<String, dynamic>>[];
    String? cursor;

    for (var page = 0; page < _maxPages; page++) {
      final uri = Uri.parse('$_baseUrl?branch=$branch&limit=$_pageSize'
          '${cursor == null ? '' : '&cursor=$cursor'}');
      final request = await client.postUrl(uri)
        ..headers.contentType = ContentType.json
        ..add(utf8.encode('{}'));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        stderr.writeln(
          'Codacy API responded ${response.statusCode} for branch '
          '"$branch" on page ${page + 1}.',
        );
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = (decoded['data'] as List?) ?? const <dynamic>[];

      for (final entry in data) {
        final issue = entry as Map<String, dynamic>;
        final pattern = (issue['patternInfo'] as Map?) ?? const {};
        final tool = (issue['toolInfo'] as Map?) ?? const {};
        results.add({
          'category': pattern['category'] ?? 'Unknown',
          'level': pattern['level'] ?? 'Unknown',
          'rule': pattern['id'] ?? 'unknown',
          'file': issue['filePath'] ?? 'unknown',
          'line': issue['lineNumber'] ?? 0,
          'message': issue['message'] ?? '',
          'tool': tool['name'] ?? 'unknown',
        });
      }

      final pagination = decoded['pagination'] as Map?;
      cursor = pagination?['cursor'] as String?;
      if (cursor == null || cursor.isEmpty) break;
    }

    return results;
  } on SocketException catch (e) {
    stderr.writeln('Network error contacting Codacy: ${e.message}');
    return null;
  } finally {
    client.close(force: true);
  }
}

String _renderMarkdown(
  List<Map<String, dynamic>> issues, {
  required String branch,
  required int totalBeforeFilter,
  String? categoryFilter,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  final byCategory = <String, List<Map<String, dynamic>>>{};
  for (final issue in issues) {
    byCategory.putIfAbsent(issue['category'] as String, () => []).add(issue);
  }
  final sortedCategories = byCategory.keys.toList()
    ..sort((a, b) => byCategory[b]!.length.compareTo(byCategory[a]!.length));

  final buf = StringBuffer()
    ..writeln('# Codacy report — branch `$branch`')
    ..writeln()
    ..writeln('Generated $now')
    ..writeln();

  if (categoryFilter != null) {
    buf
      ..writeln('Filtered to category **$categoryFilter** '
          '(${issues.length} of $totalBeforeFilter total issues).')
      ..writeln();
  } else {
    buf
      ..writeln('${issues.length} total issues.')
      ..writeln();
  }

  buf
    ..writeln('## Summary by category')
    ..writeln()
    ..writeln('| Category | Count |')
    ..writeln('|---|---:|');
  for (final category in sortedCategories) {
    buf.writeln('| $category | ${byCategory[category]!.length} |');
  }
  buf.writeln();

  for (final category in sortedCategories) {
    buf
      ..writeln('## $category (${byCategory[category]!.length})')
      ..writeln();
    final byFile = <String, List<Map<String, dynamic>>>{};
    for (final issue in byCategory[category]!) {
      byFile.putIfAbsent(issue['file'] as String, () => []).add(issue);
    }
    final sortedFiles = byFile.keys.toList()
      ..sort((a, b) => byFile[b]!.length.compareTo(byFile[a]!.length));
    for (final file in sortedFiles) {
      buf
        ..writeln('### `$file` (${byFile[file]!.length})')
        ..writeln();
      for (final issue in byFile[file]!) {
        final message = (issue['message'] as String).replaceAll('\n', ' ');
        buf.writeln(
          '- [ ] L${issue['line']} `${issue['rule']}` — $message',
        );
      }
      buf.writeln();
    }
  }

  return buf.toString();
}

Future<int> _emitDiff(
  List<Map<String, dynamic>> current,
  String branch,
  String snapshotPath,
) async {
  final file = File(snapshotPath);
  if (!file.existsSync()) {
    stderr.writeln('Snapshot $snapshotPath does not exist. Run with '
        '--snapshot $snapshotPath first to create it.');
    return 1;
  }

  final content = await file.readAsString();
  final snapshotByCategory = <String, int>{};
  final categoryHeader = RegExp(r'^## (.+) \((\d+)\)\s*$', multiLine: true);
  for (final match in categoryHeader.allMatches(content)) {
    final name = match.group(1)!.trim();
    if (name.toLowerCase() == 'summary by category') continue;
    snapshotByCategory[name] = int.parse(match.group(2)!);
  }

  final currentByCategory = <String, int>{};
  for (final issue in current) {
    final category = issue['category'] as String;
    currentByCategory[category] = (currentByCategory[category] ?? 0) + 1;
  }

  final keys = {...snapshotByCategory.keys, ...currentByCategory.keys}.toList()
    ..sort();

  final buf = StringBuffer()
    ..writeln('Codacy diff for `$branch` vs $snapshotPath')
    ..writeln()
    ..writeln('| Category | Snapshot | Current | Delta |')
    ..writeln('|---|---:|---:|---:|');

  for (final category in keys) {
    final before = snapshotByCategory[category] ?? 0;
    final after = currentByCategory[category] ?? 0;
    final delta = after - before;
    final sign = delta > 0
        ? '+$delta'
        : delta == 0
            ? '0'
            : '$delta';
    buf.writeln('| $category | $before | $after | $sign |');
  }

  stdout.write(buf.toString());
  return 0;
}
