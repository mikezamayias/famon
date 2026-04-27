import 'dart:io';

import 'package:famon/src/keyboard/action_context.dart';
import 'package:famon/src/keyboard/actions/save_to_file_action.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockLogger logger;
  late MockFileDialogInterface fileDialog;
  late MockEventCache eventCache;
  late SaveToFileAction action;

  setUp(() {
    logger = MockLogger();
    fileDialog = MockFileDialogInterface();
    eventCache = MockEventCache();
    action = SaveToFileAction(fileDialog: fileDialog);
  });

  group('SaveToFileAction metadata', () {
    test('has correct id', () {
      expect(action.id, equals('save_to_file'));
    });

    test('has correct display name', () {
      expect(action.displayName, equals('Save to File'));
    });

    test('has correct description', () {
      expect(action.description, equals('Save events to a file'));
    });

    test('has correct default binding', () {
      final binding = action.defaultBinding;
      expect(binding.key, equals('s'));
      expect(binding.ctrl, isTrue);
      expect(binding.shift, isTrue);
      expect(binding.alt, isFalse);
    });
  });

  group('SaveToFileAction execute', () {
    test('returns true when no events to save', () async {
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info('No events to save')).called(1);
    });

    test('returns true when save cancelled', () async {
      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: any(named: 'defaultFileName'),
        ),
      ).thenAnswer((_) async => null);

      final event = createMockAnalyticsEvent();
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.info('Save cancelled')).called(1);
    });

    test('saves single event to file', () async {
      final tempDir = Directory.systemTemp.createTempSync('famon_test_');
      final filePath = '${tempDir.path}/test_export.json';
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: any(named: 'defaultFileName'),
        ),
      ).thenAnswer((_) async => filePath);

      final event = createMockAnalyticsEvent(
        parameters: {'param1': 'value1'},
      );

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.success('Saved 1 events to $filePath')).called(1);

      // Verify file content
      final file = File(filePath);
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('test_event'));
      expect(content, contains('param1'));
      expect(content, contains('value1'));
      expect(content, contains('exportedAt'));
      expect(content, contains('eventCount'));
    });

    test('saves multiple events to file', () async {
      final tempDir = Directory.systemTemp.createTempSync('famon_test_');
      final filePath = '${tempDir.path}/multi_export.json';
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: any(named: 'defaultFileName'),
        ),
      ).thenAnswer((_) async => filePath);

      final events = [
        createMockAnalyticsEvent(eventName: 'event1'),
        createMockAnalyticsEvent(eventName: 'event2'),
        createMockAnalyticsEvent(eventName: 'event3'),
      ];

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: events,
      );

      final result = await action.execute(context);

      expect(result, isTrue);
      verify(() => logger.success('Saved 3 events to $filePath')).called(1);

      // Verify file contains all events
      final file = File(filePath);
      final content = file.readAsStringSync();
      expect(content, contains('event1'));
      expect(content, contains('event2'));
      expect(content, contains('event3'));
    });

    test('returns false on file system error', () async {
      // Use an invalid path that will cause a file system error
      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: any(named: 'defaultFileName'),
        ),
      ).thenAnswer((_) async => '/nonexistent/path/file.json');

      final event = createMockAnalyticsEvent();
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isFalse);
      verify(() => logger.err(any(that: contains('Failed to save file'))))
          .called(1);
    });

    test('generates default filename with timestamp', () async {
      String? capturedDefaultName;
      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: captureAny(named: 'defaultFileName'),
        ),
      ).thenAnswer((invocation) async {
        capturedDefaultName = invocation
            .namedArguments[const Symbol('defaultFileName')] as String?;
        return '/tmp/test.json';
      });

      final event = createMockAnalyticsEvent();
      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      await action.execute(context);

      expect(capturedDefaultName, isNotNull);
      expect(capturedDefaultName, startsWith('famon_export_'));
      expect(capturedDefaultName, endsWith('.json'));
      // Should have timestamp format: YYYYMMDD_HHMMSS
      expect(capturedDefaultName!.length, greaterThan(20));
    });

    test('file includes items when present', () async {
      final tempDir = Directory.systemTemp.createTempSync('famon_test_');
      final filePath = '${tempDir.path}/items_export.json';
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      when(
        () => fileDialog.showSaveDialog(
          defaultFileName: any(named: 'defaultFileName'),
        ),
      ).thenAnswer((_) async => filePath);

      final event = createMockAnalyticsEvent(
        eventName: 'purchase',
        items: [
          {'item_name': 'Product A', 'price': '10.00'},
          {'item_name': 'Product B', 'price': '20.00'},
        ],
      );

      final context = ActionContext(
        logger: logger,
        eventCache: eventCache,
        recentEvents: [event],
      );

      final result = await action.execute(context);

      expect(result, isTrue);

      final file = File(filePath);
      final content = file.readAsStringSync();
      expect(content, contains('items'));
      expect(content, contains('Product A'));
      expect(content, contains('Product B'));
    });
  });
}
