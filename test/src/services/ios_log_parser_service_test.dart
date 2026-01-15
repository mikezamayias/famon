import 'package:firebase_analytics_monitor/src/models/platform_type.dart';
import 'package:firebase_analytics_monitor/src/services/ios_log_parser_service.dart';
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
      expect(result?.parameters['ga_screen_class'], equals('HomeViewController'));
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
      expect(
        parser.parse('FIRAnalytics Logging event: test_event'),
        isNotNull,
      );
    });
  });
}
