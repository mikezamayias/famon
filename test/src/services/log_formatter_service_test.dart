import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/services/event_formatter_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('EventFormatterService', () {
    late MockLogger logger;
    late EventFormatterService formatter;

    setUp(() {
      logger = MockLogger();
      formatter = EventFormatterService(logger, colorEnabled: false)
        ..resetTracking();
    });

    test('prints header and all parameters without filtering', () {
      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'add_shipping_info',
        parameters: const {
          'currency': 'EUR',
          'shipping_tier': 'home_standard',
          'login_status': 'email_login',
        },
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('[12-25 10:30:45.123] add_shipping_info'))
          .called(1);
      verify(() => logger.info('  Parameters:')).called(1);
      verify(() => logger.info('    currency: EUR')).called(1);
      verify(() => logger.info('    shipping_tier: home_standard')).called(1);
      verify(() => logger.info('    login_status: email_login')).called(1);
    });

    test('includes item details alongside event parameters', () {
      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'add_shipping_info',
        parameters: const {
          'shipping_tier': 'express',
          'value': '82.91',
        },
        items: const [
          {
            'item_name': 'product',
            'item_price': '82.91',
          },
        ],
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('    shipping_tier: express')).called(1);
      verify(() => logger.info('  Items:')).called(1);
      verify(() => logger.info('    Item 1:')).called(1);
      verify(() => logger.info('      item_name: product')).called(1);
    });

    test('supports raw output mode without labels', () {
      final rawFormatter =
          EventFormatterService(logger, rawOutput: true, colorEnabled: false);
      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'screen_view',
        parameters: const {'ga_session_id': '123'},
      );

      rawFormatter.formatAndPrint(event);

      // Raw mode prints: "timestamp | eventName | params"
      verify(
        () => logger.info(
          '12-25 10:30:45.123 | screen_view | {ga_session_id: 123}',
        ),
      ).called(1);
    });
  });
}
