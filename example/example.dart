// ignore_for_file: avoid_print

import 'package:firebase_analytics_monitor/firebase_analytics_monitor.dart';

/// Example demonstrating Firebase Analytics Monitor usage.
///
/// This CLI tool monitors Firebase Analytics events from Android logcat
/// in real-time. The example below shows how to use the parsing
/// functionality programmatically.
void main() {
  // Example logcat lines containing Firebase Analytics events
  final logcatLines = <String>[
    'D/FA      ( 1234): Logging event (FE): screen_view(_vs), Bundle[{firebase_screen(_sn)=HomeScreen, firebase_screen_class(_sc)=MainActivity}]',
    'D/FA-SVC  ( 5678): Logging event: origin=app,name=login,params=Bundle[{method=email, success=true}]',
    'I/FA      ( 9999): Not an analytics event line',
  ];

  // Create a parser instance (logger is optional)
  final parser = LogParserService();

  print('Firebase Analytics Monitor - Parsing Example\n');
  print('=' * 50);

  for (final line in logcatLines) {
    print('\nInput: ${line.substring(0, 60)}...');

    // Parse the logcat line
    final event = parser.parse(line);

    if (event != null) {
      print('  Event Name: ${event.eventName}');
      print('  Timestamp: ${event.displayTimestamp}');
      if (event.parameters.isNotEmpty) {
        print('  Parameters:');
        for (final entry in event.parameters.entries) {
          print('    ${entry.key}: ${entry.value}');
        }
      }
    } else {
      print('  (No Firebase Analytics event detected)');
    }
  }

  print('\n${'=' * 50}');

  // Example: Creating an AnalyticsEvent programmatically using factory
  final customEvent = AnalyticsEvent.fromParsedLog(
    rawTimestamp: '12:34:56.789',
    eventName: 'purchase',
    parameters: const {
      'item_id': 'SKU_12345',
      'item_name': 'Premium Subscription',
      'price': '9.99',
      'currency': 'USD',
    },
  );

  print('\nCustom Event Created:');
  print('  Name: ${customEvent.eventName}');
  print('  Display Timestamp: ${customEvent.displayTimestamp}');
  print('  Parameters: ${customEvent.parameters}');

  // Example: SessionStats (immutable data class)
  const stats = SessionStats(
    totalUniqueEvents: 5,
    totalEventOccurrences: 42,
    mostFrequentEvent: 'screen_view',
  );

  print('\nSession Statistics:');
  print('  Unique Events: ${stats.totalUniqueEvents}');
  print('  Total Occurrences: ${stats.totalEventOccurrences}');
  print('  Most Frequent: ${stats.mostFrequentEvent}');
}
