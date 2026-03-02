import 'package:famon/src/services/interfaces/log_parser_interface.dart';
import 'package:famon/src/services/log_parser_service.dart';
import 'package:test/test.dart';

void main() {
  group('LogParserService', () {
    late LogParserInterface parser;

    setUp(() {
      parser = LogParserService();
    });

    test('should parse standard Firebase Analytics log format', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=purchase,params=Bundle[{currency=USD, value=Double(29.99), transaction_id=txn_123}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('purchase'));
      expect(result.rawTimestamp, equals('12-25 10:30:45.123'));
      expect(result.parameters['currency'], equals('USD'));
      expect(result.parameters['value'], equals('29.99'));
      expect(result.parameters['transaction_id'], equals('txn_123'));
    });

    test('should handle empty log lines', () {
      final result = parser.parse('');
      expect(result, isNull);
    });

    test('should parse log with items array', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=purchase,params=Bundle[{items=[Bundle[{item_id=item1, item_name=String(ProductA), price=Double(19.99)}], Bundle[{item_id=item2, item_name=String(ProductB), price=Double(49.99)}]], currency=USD}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('purchase'));
      expect(result.items.length, equals(2));
      expect(result.items[0]['item_id'], equals('item1'));
      expect(result.items[0]['item_name'], equals('ProductA'));
      expect(result.items[1]['item_id'], equals('item2'));
      expect(result.parameters.containsKey('item_id'), isFalse);
      expect(result.parameters.containsKey('item_name'), isFalse);
      expect(result.parameters['currency'], equals('USD'));
    });

    test('parses items when items array is truncated (no partial item)', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=view_item_list,params=Bundle[{item_list_name=list_a, items=[Bundle[{item_id=item1, item_name=String(ProductA)}], Bundle[{item_id=item2, item_name=String(ProductB)}], Bundle[{item_id=item3, item_name=String(ProductC)}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('view_item_list'));
      expect(result.items.length, equals(3));
      expect(result.items[0]['item_id'], equals('item1'));
      expect(result.items[1]['item_id'], equals('item2'));
      expect(result.items[2]['item_id'], equals('item3'));
      expect(result.parameters.containsKey('item_id'), isFalse);
      expect(result.parameters['item_list_name'], equals('list_a'));
    });

    test('parses complete items when logcat truncates mid-item', () {
      // Simulates logcat truncating the line in the middle of a 4th item,
      // after 3 complete items. The 4th item has no closing }].
      const logLine =
          '02-11 10:30:45.123  3815 28115 V FA-SVC  : Logging event: '
          'origin=app,name=view_item_list,params=Bundle[{'
          'list_name=my_list, environment=staging, '
          'items=['
          'Bundle[{item_id=p1, item_name=ProductA, index=1, price=10.0}], '
          'Bundle[{item_id=p2, item_name=ProductB, index=2, price=20.0}], '
          'Bundle[{item_id=p3, item_name=ProductC, index=3, price=30.0}], '
          'Bundle[{item_id=p4, item_name=ProductD, index=4, pr';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('view_item_list'));
      // Should find the 3 complete items, not the truncated 4th
      expect(result.items.length, equals(3));
      expect(result.items[0]['item_id'], equals('p1'));
      expect(result.items[1]['item_id'], equals('p2'));
      expect(result.items[2]['item_id'], equals('p3'));
      // Item fields must NOT appear as top-level params
      expect(result.parameters.containsKey('item_id'), isFalse);
      expect(result.parameters.containsKey('item_name'), isFalse);
      expect(result.parameters['list_name'], equals('my_list'));
      expect(result.parameters['environment'], equals('staging'));
    });

    test('should handle log without parameters', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : FA-SVC event_name:app_open';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('app_open'));
      expect(result.parameters.isEmpty, true);
      expect(result.items.isEmpty, true);
    });

    test('should return null for non-matching log lines', () {
      const logLine = '12-25 10:30:45.123 I/SomeOtherTag: Random log message';

      final result = parser.parse(logLine);

      expect(result, isNull);
    });

    test('should clean parameter values properly', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=test_event,params=Bundle[{string_param=String("quoted_value"), bool_param=Boolean(true)}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.parameters['string_param'], equals('quoted_value'));
      expect(result.parameters['bool_param'], equals('true'));
    });

    test('should handle various parameter types', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=complex_event,params=Bundle[{str_val=String(test), long_val=Long(12345), double_val=Double(99.99), bool_val=Boolean(false)}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.parameters['str_val'], equals('test'));
      expect(result.parameters['long_val'], equals('12345'));
      expect(result.parameters['double_val'], equals('99.99'));
      expect(result.parameters['bool_val'], equals('false'));
    });

    test('should handle malformed parameter gracefully', () {
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=test_event,params=Bundle[{valid_param=value, malformed_param=, another_valid=test}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('test_event'));
      expect(result.parameters.containsKey('another_valid'), true);
      expect(result.parameters['another_valid'], equals('test'));
    });

    test('should handle malformed or empty Bundle strings', () {
      const logLine1 =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=empty_event,params=Bundle[]';
      const logLine2 =
          '12-25 10:30:45.123 I/FA-SVC  : FA-SVC event_name:malformed_event';

      final result1 = parser.parse(logLine1);
      final result2 = parser.parse(logLine2);

      expect(result1, isNotNull);
      expect(result1!.parameters.isEmpty, true);

      expect(result2, isNotNull);
      expect(result2!.parameters.isEmpty, true);
    });

    test('should parse real-world Firebase Analytics format', () {
      const logLine =
          '09-10 15:41:30.450 I/FA-SVC: Logging event: origin=app,name=view_cart,params=Bundle[{value=0, currency=GBP, login_mode=email_login, language=en, country_app=GB, environment=test, message=no_message}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('view_cart'));
      expect(result.rawTimestamp, equals('09-10 15:41:30.450'));
      expect(result.parameters['currency'], equals('GBP'));
      expect(result.parameters['value'], equals('0'));
      expect(result.parameters['login_mode'], equals('email_login'));
      expect(result.parameters['language'], equals('en'));
      expect(result.parameters['country_app'], equals('GB'));
      expect(result.parameters['environment'], equals('test'));
      expect(result.parameters['message'], equals('no_message'));
    });

    test('should parse screen_view event format', () {
      const logLine =
          '09-10 15:41:35.626 I/FA-SVC: Logging event: origin=app,name=screen_view,params=Bundle[{login_mode=email_login, language=en, country_app=GB, environment=test}]';

      final result = parser.parse(logLine);

      expect(result, isNotNull);
      expect(result!.eventName, equals('screen_view'));
      expect(result.parameters['login_mode'], equals('email_login'));
      expect(result.parameters['language'], equals('en'));
      expect(result.parameters['country_app'], equals('GB'));
      expect(result.parameters['environment'], equals('test'));
    });

    test('parses items with nested Bundle content', () {
      // Each item contains a nested Bundle[{...}] value. The old regex
      // (Bundle\[\{([^}]+)\}\]) would stop at the first '}' inside the
      // nested bundle and mis-parse or drop the item.
      const logLine =
          '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=purchase,'
          'params=Bundle[{'
          'items=['
          'Bundle[{item_id=item1, item_extra=Bundle[{color=red, size=M}], price=Double(9.99)}], '
          'Bundle[{item_id=item2, item_extra=Bundle[{color=blue, size=L}], price=Double(19.99)}]'
          '], currency=USD}]';

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
}
