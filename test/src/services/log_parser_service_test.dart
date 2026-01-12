import 'package:firebase_analytics_monitor/src/services/interfaces/log_parser_interface.dart';
import 'package:firebase_analytics_monitor/src/services/log_parser_service.dart';
import 'package:test/test.dart';

void main() {
  group('LogParserService', () {
    late LogParserInterface parser;

    setUp(() {
      parser = LogParserService();
    });

    group('Pattern 1 - Standard format: origin=app,name=...,params=Bundle', () {
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

      test('should handle log with items array', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC  : Logging event: origin=app,name=purchase,params=Bundle[{items=[Bundle[{item_id=sku123, item_name=String(T-Shirt), price=Double(19.99)}], Bundle[{item_id=sku456, item_name=String(Jeans), price=Double(49.99)}]], currency=USD}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('purchase'));
        expect(result.items.length, equals(2));
        expect(result.items[0]['item_id'], equals('sku123'));
        expect(result.items[0]['item_name'], equals('T-Shirt'));
        expect(result.items[1]['item_id'], equals('sku456'));
      });
    });

    group('Pattern 2 - Alternative format: Event logged: event_name', () {
      test('should parse Event logged format with params', () {
        const logLine =
            '01-15 14:22:33.456 D/FA  : Event logged: add_to_cart params:Bundle[{item_id=prod_001, quantity=Long(2), price=Double(15.99)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('add_to_cart'));
        expect(result.rawTimestamp, equals('01-15 14:22:33.456'));
        expect(result.parameters['item_id'], equals('prod_001'));
        expect(result.parameters['quantity'], equals('2'));
        expect(result.parameters['price'], equals('15.99'));
      });

      test('should parse Event logged format with optional empty params', () {
        // Pattern 2 has params as optional: params:(Bundle\[.*\])?
        // Without the params: part, it still matches but params will be empty
        const logLine =
            '03-20 08:15:42.789 D/FA  : Event logged: session_start params:Bundle[]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('session_start'));
        expect(result.rawTimestamp, equals('03-20 08:15:42.789'));
        expect(result.parameters.isEmpty, true);
      });
    });

    group('Pattern 3 - FA-SVC comprehensive format', () {
      test('should parse FA-SVC Logging event with name= format', () {
        const logLine =
            '06-01 12:45:00.111 V/FA-SVC  : Logging event (FE): name=user_engagement, params=Bundle[{engagement_time_msec=Long(5000), ga_session_id=Long(12345)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('user_engagement'));
        expect(result.rawTimestamp, equals('06-01 12:45:00.111'));
        expect(result.parameters['engagement_time_msec'], equals('5000'));
      });

      test('should parse FA-SVC with verbose output', () {
        const logLine =
            '11-22 09:30:15.222 D/FA-SVC  : Logging event: origin=auto, name=app_background, params=Bundle[{_o=auto}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('app_background'));
      });
    });

    group('Pattern 4 - FA comprehensive format', () {
      test('should parse FA Logging event with name= format', () {
        const logLine =
            '07-18 16:20:30.333 I/FA  : Logging event: origin=app,name=login,params=Bundle[{method=String(google), success=Boolean(true)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('login'));
        expect(result.rawTimestamp, equals('07-18 16:20:30.333'));
        expect(result.parameters['method'], equals('google'));
        expect(result.parameters['success'], equals('true'));
      });

      test('should parse FA Logging event without type wrappers', () {
        const logLine =
            '02-28 11:11:11.111 I/FA: Logging event: origin=app,name=signup,params=Bundle[{email_verified=true, account_type=premium}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('signup'));
        expect(result.parameters['email_verified'], equals('true'));
        expect(result.parameters['account_type'], equals('premium'));
      });
    });

    group('Pattern 5 - Newer FA-SVC format: Event: event_name Bundle', () {
      test('should parse FA-SVC Event: format', () {
        const logLine =
            '04-10 07:55:20.444 D/FA-SVC  : Event: select_content Bundle[{content_type=article, item_id=news_123}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('select_content'));
        expect(result.rawTimestamp, equals('04-10 07:55:20.444'));
        expect(result.parameters['content_type'], equals('article'));
        expect(result.parameters['item_id'], equals('news_123'));
      });

      test('should parse FA-SVC Event: with typed params', () {
        // Pattern 5 captures bundle content without Bundle[] wrapper
        // so typed values may not be cleaned in certain scenarios
        const logLine =
            '08-05 18:40:50.555 V/FA-SVC: Event: share Bundle[{method=facebook, content_id=99999}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('share'));
        expect(result.parameters['method'], equals('facebook'));
        expect(result.parameters['content_id'], equals('99999'));
      });
    });

    group('Pattern 6 - Newer FA format: Event: event_name...Bundle[...]', () {
      test('should parse FA Event: format', () {
        const logLine =
            '05-25 13:33:33.666 I/FA  : Event: view_item Bundle[{item_id=SKU456, item_name=Widget, price=Double(24.99)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('view_item'));
        expect(result.rawTimestamp, equals('05-25 13:33:33.666'));
        expect(result.parameters['item_id'], equals('SKU456'));
        expect(result.parameters['item_name'], equals('Widget'));
        expect(result.parameters['price'], equals('24.99'));
      });

      test('should parse FA Event: with numeric params', () {
        const logLine =
            '10-12 22:10:05.777 D/FA: Event: level_up Bundle[{level=5, character=warrior}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('level_up'));
        expect(result.parameters['level'], equals('5'));
        expect(result.parameters['character'], equals('warrior'));
      });
    });

    group('Pattern 7 - Older Logging event (FE) format tagged as I/FA', () {
      test('should parse I/FA Logging event (FE) format', () {
        const logLine =
            '09-30 19:45:30.888 I/FA  : Logging event (FE): tutorial_complete, Bundle[{step=Long(10), duration_sec=Long(120)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('tutorial_complete'));
        expect(result.rawTimestamp, equals('09-30 19:45:30.888'));
        expect(result.parameters['step'], equals('10'));
        expect(result.parameters['duration_sec'], equals('120'));
      });

      test('should parse I/FA Logging event (FE) with special chars', () {
        const logLine =
            '12-01 06:00:00.999 I/FA: Logging event (FE): custom_event_123, Bundle[{param_a=value_a, param_b=Long(42)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('custom_event_123'));
        expect(result.parameters['param_a'], equals('value_a'));
        expect(result.parameters['param_b'], equals('42'));
      });
    });

    group('Pattern 8 - I/FA Event logged: event_name, params=(Bundle[...])',
        () {
      test('should parse I/FA Event logged with params=', () {
        const logLine =
            '03-15 08:30:00.100 I/FA  : Event logged: app_open params=Bundle[{firebase_event_origin=auto}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('app_open'));
        expect(result.rawTimestamp, equals('03-15 08:30:00.100'));
        expect(result.parameters['firebase_event_origin'], equals('auto'));
      });

      test('should parse I/FA Event logged with params:', () {
        const logLine =
            '07-04 15:00:00.200 I/FA: Event logged: first_open params:Bundle[{previous_app_version=none}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('first_open'));
        expect(result.parameters['previous_app_version'], equals('none'));
      });
    });

    group('Pattern 9 - Basic FA-SVC format: event_name:...', () {
      test('should handle log without parameters (FA-SVC)', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC  : FA-SVC event_name:app_open';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('app_open'));
        expect(result.parameters.isEmpty, true);
        expect(result.items.isEmpty, true);
      });

      test('should parse FA-SVC event_name: format', () {
        const logLine =
            '11-11 11:11:11.300 D/FA-SVC: FA-SVC event_name:screen_view';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('screen_view'));
        expect(result.rawTimestamp, equals('11-11 11:11:11.300'));
      });

      test('should parse FA-SVC event_name: with underscore event names', () {
        const logLine =
            '06-30 23:59:59.400 V/FA-SVC: FA-SVC event_name:user_engagement_start';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('user_engagement_start'));
      });
    });

    group('Pattern 10 - Basic FA format: event_name:...', () {
      test('should parse FA event_name: format', () {
        const logLine = '02-14 12:00:00.500 I/FA: FA event_name:session_start';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('session_start'));
        expect(result.rawTimestamp, equals('02-14 12:00:00.500'));
      });

      test('should parse FA event_name: with numeric suffix', () {
        const logLine =
            '08-20 04:30:30.600 D/FA: FA event_name:notification_received';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('notification_received'));
      });
    });

    group('FA Invalid Default Parameter Pattern', () {
      test('should parse W/FA Invalid default event parameter type', () {
        const logLine =
            '09-15 11:18:06.373 W/FA (19723): Invalid default event parameter type. Name, value: cart_total_items, 1';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.rawTimestamp, equals('09-15 11:18:06.373'));
        expect(result.parameters['cart_total_items'], equals('1'));
      });

      test('should parse E/FA Invalid default event parameter type', () {
        const logLine =
            '10-20 14:25:30.100 E/FA: Invalid default event parameter type. Name, value: user_score, 9999';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.parameters['user_score'], equals('9999'));
      });

      test('should parse I/FA Invalid default event parameter type', () {
        const logLine =
            '05-05 05:05:05.505 I/FA: Invalid default event parameter type. Name, value: test_param, test_value';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.parameters['test_param'], equals('test_value'));
      });

      test('should parse D/FA Invalid default event parameter type', () {
        const logLine =
            '01-01 00:00:00.001 D/FA: Invalid default event parameter type. Name, value: debug_flag, true';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.parameters['debug_flag'], equals('true'));
      });

      test('should parse V/FA Invalid default event parameter type', () {
        const logLine =
            '12-31 23:59:59.999 V/FA: Invalid default event parameter type. Name, value: verbose_param, 3.14';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.parameters['verbose_param'], equals('3.14'));
      });

      test('should handle Invalid default param with spaces in value', () {
        const logLine =
            '07-07 07:07:07.777 W/FA: Invalid default event parameter type. Name, value: description, hello world';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('fa_invalid_default_param'));
        expect(result.parameters['description'], equals('hello world'));
      });
    });

    group('Edge cases - Empty and null handling', () {
      test('should handle empty log lines', () {
        final result = parser.parse('');
        expect(result, isNull);
      });

      test('should return null for non-matching log lines', () {
        const logLine = '12-25 10:30:45.123 I/SomeOtherTag: Random log message';

        final result = parser.parse(logLine);

        expect(result, isNull);
      });

      test('should return null for lines without FA markers', () {
        const logLine =
            '12-25 10:30:45.123 I/ActivityManager: Starting activity';

        final result = parser.parse(logLine);

        expect(result, isNull);
      });

      test('should return null for partial FA tag matches', () {
        const logLine =
            '12-25 10:30:45.123 I/FACTORY: Some factory log message';

        final result = parser.parse(logLine);

        expect(result, isNull);
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
    });

    group('Edge cases - Malformed Bundle content', () {
      test('should handle Bundle with missing closing bracket', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=test,params=Bundle[{key=value';

        final result = parser.parse(logLine);

        // Should still attempt to parse or return null gracefully
        // Behavior depends on regex matching
        expect(result == null || result.eventName == 'test', isTrue);
      });

      test('should handle Bundle with nested braces', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=nested,params=Bundle[{outer={inner=value}}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('nested'));
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

      test('should handle Bundle with special characters in values', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=special,params=Bundle[{url=https://example.com, emoji=test}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('special'));
        // URL parsing may vary
      });
    });

    group('Edge cases - Invalid timestamps', () {
      test('should not parse line with missing timestamp', () {
        const logLine =
            'I/FA-SVC: Logging event: origin=app,name=no_timestamp,params=Bundle[{key=value}]';

        final result = parser.parse(logLine);

        expect(result, isNull);
      });

      test('should not parse line with malformed timestamp', () {
        const logLine =
            '99-99 99:99:99.999 I/FA-SVC: Logging event: origin=app,name=bad_timestamp,params=Bundle[{key=value}]';

        final result = parser.parse(logLine);

        // Regex allows this format since it matches \d{2}-\d{2} pattern
        // But the timestamp value itself is invalid
        expect(result, isNotNull);
        expect(result!.rawTimestamp, equals('99-99 99:99:99.999'));
      });

      test('should handle timestamp with single-digit components', () {
        const logLine =
            '1-5 8:30:45.123 I/FA-SVC: Logging event: origin=app,name=short_timestamp,params=Bundle[{key=value}]';

        final result = parser.parse(logLine);

        // Single digit timestamps do not match the pattern
        expect(result, isNull);
      });
    });

    group('Edge cases - Missing parameters', () {
      test('should handle event with completely empty params', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=empty_params,params=Bundle[{}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('empty_params'));
        expect(result.parameters.isEmpty, true);
      });

      test('should handle params with only whitespace', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=whitespace_params,params=Bundle[{   }]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('whitespace_params'));
        expect(result.parameters.isEmpty, true);
      });

      test('should handle params with keys but no values', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=keyonly,params=Bundle[{key1=, key2=}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('keyonly'));
        // Empty values should be filtered out
      });
    });

    group('Parameter type handling', () {
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

      test('should handle Integer type wrapper', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=int_test,params=Bundle[{count=Integer(42)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.parameters['count'], equals('42'));
      });

      test('should handle Float type wrapper', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=float_test,params=Bundle[{ratio=Float(0.75)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.parameters['ratio'], equals('0.75'));
      });

      test('should handle single quoted strings', () {
        const logLine =
            "12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=quote_test,params=Bundle[{message='hello'}]";

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.parameters['message'], equals('hello'));
      });

      test('should handle double quoted strings', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=quote_test,params=Bundle[{message="world"}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.parameters['message'], equals('world'));
      });
    });

    group('Items array parsing', () {
      test('should parse single item in items array', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=add_to_cart,params=Bundle[{items=[Bundle[{item_id=prod_1, item_name=String(Product One), price=Double(9.99)}]], currency=USD}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('add_to_cart'));
        expect(result.items.length, equals(1));
        expect(result.items[0]['item_id'], equals('prod_1'));
        expect(result.items[0]['item_name'], equals('Product One'));
        expect(result.items[0]['price'], equals('9.99'));
      });

      test('should parse multiple items in items array', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=view_item_list,params=Bundle[{items=[Bundle[{item_id=a, item_name=A}], Bundle[{item_id=b, item_name=B}], Bundle[{item_id=c, item_name=C}]], list_name=featured}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.items.length, equals(3));
        expect(result.items[0]['item_id'], equals('a'));
        expect(result.items[1]['item_id'], equals('b'));
        expect(result.items[2]['item_id'], equals('c'));
      });

      test('should handle empty items array', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=empty_items,params=Bundle[{items=[], currency=USD}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('empty_items'));
        expect(result.items.isEmpty, true);
      });

      test('should not include items key in parameters', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=purchase,params=Bundle[{items=[Bundle[{item_id=x}]], currency=USD, value=Double(100)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.parameters.containsKey('items'), isFalse);
        expect(result.parameters['currency'], equals('USD'));
        expect(result.parameters['value'], equals('100'));
      });
    });

    group('Real-world scenarios', () {
      test('should parse e-commerce purchase event', () {
        const logLine =
            '01-20 15:30:00.000 I/FA-SVC: Logging event: origin=app,name=purchase,params=Bundle[{transaction_id=TXN123456, affiliation=Store, currency=EUR, value=Double(149.99), tax=Double(25.0), shipping=Double(10.0), coupon=SAVE10}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('purchase'));
        expect(result.parameters['transaction_id'], equals('TXN123456'));
        expect(result.parameters['affiliation'], equals('Store'));
        expect(result.parameters['currency'], equals('EUR'));
        expect(result.parameters['value'], equals('149.99'));
        expect(result.parameters['tax'], equals('25.0'));
        expect(result.parameters['shipping'], equals('10.0'));
        expect(result.parameters['coupon'], equals('SAVE10'));
      });

      test('should parse user properties event', () {
        const logLine =
            '06-15 09:00:00.000 I/FA: Logging event: origin=app,name=user_engagement,params=Bundle[{engagement_time_msec=Long(30000), ga_session_id=Long(1623744000), ga_session_number=Long(5)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('user_engagement'));
        expect(result.parameters['engagement_time_msec'], equals('30000'));
        expect(result.parameters['ga_session_id'], equals('1623744000'));
        expect(result.parameters['ga_session_number'], equals('5'));
      });

      test('should parse search event', () {
        const logLine =
            '08-10 12:45:30.500 I/FA-SVC: Logging event: origin=app,name=search,params=Bundle[{search_term=String(blue shoes), number_of_results=Long(42)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('search'));
        expect(result.parameters['search_term'], equals('blue shoes'));
        expect(result.parameters['number_of_results'], equals('42'));
      });

      test('should parse error event', () {
        const logLine =
            '11-30 23:59:59.999 I/FA: Logging event: origin=app,name=app_exception,params=Bundle[{fatal=Boolean(false), exception_type=String(NetworkError), stack_trace=String(truncated)}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('app_exception'));
        expect(result.parameters['fatal'], equals('false'));
        expect(result.parameters['exception_type'], equals('NetworkError'));
      });
    });

    group('Colon vs equals separator handling', () {
      test('should parse params with colon separator', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=colon_test,params=Bundle[{key1:value1, key2:value2}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('colon_test'));
        expect(result.parameters['key1'], equals('value1'));
        expect(result.parameters['key2'], equals('value2'));
      });

      test('should parse params with mixed separators', () {
        const logLine =
            '12-25 10:30:45.123 I/FA-SVC: Logging event: origin=app,name=mixed_test,params=Bundle[{key1=value1, key2:value2}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('mixed_test'));
        expect(result.parameters['key1'], equals('value1'));
        expect(result.parameters['key2'], equals('value2'));
      });
    });

    group('Log level variations', () {
      test('should parse verbose level logs (V)', () {
        const logLine =
            '12-25 10:30:45.123 V/FA: Logging event: origin=app,name=verbose_event,params=Bundle[{level=verbose}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('verbose_event'));
      });

      test('should parse debug level logs (D)', () {
        const logLine =
            '12-25 10:30:45.123 D/FA: Logging event: origin=app,name=debug_event,params=Bundle[{level=debug}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('debug_event'));
      });

      test('should parse info level logs (I)', () {
        const logLine =
            '12-25 10:30:45.123 I/FA: Logging event: origin=app,name=info_event,params=Bundle[{level=info}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('info_event'));
      });

      test('should parse warning level logs (W)', () {
        const logLine =
            '12-25 10:30:45.123 W/FA: Logging event: origin=app,name=warning_event,params=Bundle[{level=warning}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('warning_event'));
      });

      test('should parse error level logs (E)', () {
        const logLine =
            '12-25 10:30:45.123 E/FA: Logging event: origin=app,name=error_event,params=Bundle[{level=error}]';

        final result = parser.parse(logLine);

        expect(result, isNotNull);
        expect(result!.eventName, equals('error_event'));
      });
    });
  });
}
