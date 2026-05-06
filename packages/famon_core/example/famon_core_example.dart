// Demonstrates parsing a single Android logcat line with famon_core.
// Run with: `dart run example/famon_core_example.dart`
// ignore_for_file: avoid_print

import 'package:famon_core/famon_core.dart';

void main() {
  final parser = LogParserService();

  const logLine = '11-15 10:23:45.123 12345 12345 V FA      : Logging event: '
      'origin=app,name=screen_view,'
      'params=Bundle[{firebase_screen_class=HomeScreen, firebase_screen=Home}]';

  final event = parser.parse(logLine);
  if (event == null) {
    print('Line did not contain a Firebase Analytics event.');
    return;
  }

  print('Event:      ${event.eventName}');
  print('Timestamp:  ${event.rawTimestamp}');
  print('Parameters: ${event.parameters}');
  if (event.items.isNotEmpty) {
    print('Items:      ${event.items}');
  }
}
