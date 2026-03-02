import 'package:famon/src/models/platform_type.dart';
import 'package:famon/src/services/ios_log_parser_service.dart';
import 'package:test/test.dart';

void main() {
  group('IosLogParserService', () {
    late IosLogParserService parser;

    setUp(() {
      parser = IosLogParserService();
    });

    test('should have correct platform', () {
      expect(parser.platform, equals(PlatformType.iosSimulator));
    });

    test('should parse standard iOS Firebase Analytics log format', () {
      const logLine =
          '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
          'params: app, screen_view (_vs), { ga_screen (_sn) = Dashboard; '
          'ga_screen_class (_sc) = HomeViewController; }';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('screen_view'));
      expect(result?.parameters['ga_screen'], equals('Dashboard'));
      expect(
        result?.parameters['ga_screen_class'],
        equals('HomeViewController'),
      );
    });

    test('should parse iOS event logged confirmation format', () {
      const logLine =
          '[FirebaseAnalytics][I-ACS023072] Event logged. Event name, '
          'event params: purchase';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('purchase'));
    });

    test('should parse simple iOS log format without params block', () {
      const logLine = '[FirebaseAnalytics][I-ACS023051] Logging event: app, '
          'add_to_cart';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('add_to_cart'));
    });

    test('should parse FIRAnalytics format', () {
      const logLine = 'FIRAnalytics Logging event: custom_event';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('custom_event'));
    });

    test('should return null for empty log lines', () {
      expect(parser.parse(''), isNull);
    });

    test('should return null for non-matching log lines', () {
      expect(parser.parse('Some random log line'), isNull);
      expect(parser.parse('I/FA: Some Android log'), isNull);
    });

    test('should handle iOS parameters with abbreviations', () {
      const logLine =
          '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
          'params: app, purchase, { '
          'currency (_c) = USD; '
          'value (_v) = 29.99; '
          'transaction_id (_ti) = txn_123; '
          '}';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('purchase'));
      expect(result?.parameters['currency'], equals('USD'));
      expect(result?.parameters['value'], equals('29.99'));
      expect(result?.parameters['transaction_id'], equals('txn_123'));
    });

    test('should handle iOS log with timestamp', () {
      const logLine =
          '2024-01-15 10:30:45.123+0000 [FirebaseAnalytics][I-ACS023051] '
          'Logging event: origin, name, params: app, login, { '
          'method = google; '
          '}';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.eventName, equals('login'));
      expect(result?.parameters['method'], equals('google'));
      expect(result?.rawTimestamp, contains('2024-01-15'));
    });

    test('should clean parameter values properly', () {
      const logLine =
          '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
          'params: app, test_event, { '
          'quoted_value = "test string"; '
          'trailing_semi = value; '
          '}';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result?.parameters['quoted_value'], equals('test string'));
      expect(result?.parameters['trailing_semi'], equals('value'));
    });

    test('should only match lines containing FA markers', () {
      // Should not parse lines without Firebase markers
      expect(parser.parse('Regular log line'), isNull);
      expect(parser.parse('[SomeOther] Logging event: test'), isNull);

      // Should parse lines with Firebase markers
      expect(
        parser.parse(
          '[FirebaseAnalytics][I-ACS023051] Logging event: app, test_event',
        ),
        isNotNull,
      );
      expect(parser.parse('FIRAnalytics Logging event: test_event'), isNotNull);
    });

    group('items array parsing', () {
      test('should parse items and not bleed item fields into params', () {
        const logLine =
            '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
            'params: app, view_item_list, { '
            'item_list_name (_iln) = category_results; '
            'items = [{item_id = item1; item_name = ProductA;}, '
            '{item_id = item2; item_name = ProductB;}]; '
            '}';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result?.eventName, equals('view_item_list'));
        expect(
          result?.parameters['item_list_name'],
          equals('category_results'),
        );
        // item fields must NOT bleed into top-level params
        expect(result?.parameters.containsKey('item_id'), isFalse);
        expect(result?.parameters.containsKey('item_name'), isFalse);
        // items must be parsed separately
        expect(result?.items, hasLength(2));
        expect(result?.items[0]['item_id'], equals('item1'));
        expect(result?.items[0]['item_name'], equals('ProductA'));
        expect(result?.items[1]['item_id'], equals('item2'));
        expect(result?.items[1]['item_name'], equals('ProductB'));
      });

      test('should parse complete items from truncated items array', () {
        // Simulate a truncated log line where the items array is cut mid-item
        const logLine =
            '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
            'params: app, view_item_list, { '
            'item_list_name (_iln) = results; '
            'items = [{item_id = item1; item_name = ProductA;}, '
            '{item_id = item2; item_name = ProductB;}, '
            '{item_id = ite';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result?.eventName, equals('view_item_list'));
        expect(result?.parameters['item_list_name'], equals('results'));
        // item fields must NOT bleed into top-level params
        expect(result?.parameters.containsKey('item_id'), isFalse);
        expect(result?.parameters.containsKey('item_name'), isFalse);
        // Only the 2 complete items should be parsed
        expect(result?.items, hasLength(2));
        expect(result?.items[0]['item_id'], equals('item1'));
        expect(result?.items[1]['item_id'], equals('item2'));
      });

      test(
        'should handle items array with no complete items on truncation',
        () {
          const logLine =
              '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
              'params: app, view_item_list, { '
              'item_list_name (_iln) = results; '
              'items = [{item_id = ite';

          final result = parser.parse(logLine);

          expect(result, isNotNull);
          expect(result?.parameters['item_list_name'], equals('results'));
          expect(result?.parameters.containsKey('item_id'), isFalse);
          expect(result?.items, isEmpty);
        },
      );

      test('parses iOS items with nested object content', () {
        // Each item contains a nested {...} value. The old regex
        // (\{([^}]+)\}) would stop at the first '}' inside the nested object
        // and mis-parse or drop the item.
        const logLine =
            '[FirebaseAnalytics][I-ACS023051] Logging event: origin, name, '
            'params: app, purchase, { '
            'items = [{item_id = item1; item_extra = {color = red; size = M;}; '
            'price = 9.99;}, '
            '{item_id = item2; item_extra = {color = blue; size = L;}; '
            'price = 19.99;}]; '
            'currency = USD; '
            '}';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('purchase'));
        expect(result.items.length, equals(2));
        expect(result.items[0]['item_id'], equals('item1'));
        expect(result.items[0]['price'], equals('9.99'));
        expect(result.items[1]['item_id'], equals('item2'));
        expect(result.items[1]['price'], equals('19.99'));
        expect(result.parameters['currency'], equals('USD'));
        expect(result.parameters.containsKey('item_id'), isFalse);
      });
    });
  });
}
