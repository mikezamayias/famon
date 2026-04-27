import 'package:famon_core/famon_core.dart';
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

      verify(
        () => logger.info('[12-25 10:30:45.123] add_shipping_info'),
      ).called(1);
      verify(() => logger.info('  Parameters:')).called(1);
      verify(() => logger.info('    currency: EUR')).called(1);
      verify(() => logger.info('    shipping_tier: home_standard')).called(1);
      verify(() => logger.info('    login_status: email_login')).called(1);
    });

    test('includes item details alongside event parameters', () {
      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'add_shipping_info',
        parameters: const {'shipping_tier': 'express', 'value': '82.91'},
        items: const [
          {'item_name': 'product', 'item_price': '82.91'},
        ],
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('    shipping_tier: express')).called(1);
      verify(() => logger.info('  Items:')).called(1);
      verify(() => logger.info('    Item 1:')).called(1);
      verify(() => logger.info('      item_name: product')).called(1);
    });

    test('supports raw output mode without labels', () {
      final rawFormatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
      );
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

    test('includes items in raw output when present', () {
      final rawFormatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
      );
      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'view_item_list',
        parameters: const {'item_list_name': 'home'},
        items: const [
          {'item_id': 'item1', 'item_name': 'ProductA'},
          {'item_id': 'item2', 'item_name': 'ProductB'},
        ],
      );

      rawFormatter.formatAndPrint(event);

      verify(
        () => logger.info(
          '12-25 10:30:45.123 | view_item_list '
          '| {item_list_name: home} '
          '| items=[{item_id: item1, item_name: ProductA}, '
          '{item_id: item2, item_name: ProductB}]',
        ),
      ).called(1);
    });
  });

  group('EventFormatterService – global parameters', () {
    late MockLogger logger;

    setUp(() {
      logger = MockLogger();
    });

    test('separates global and event params in formatted output', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status', 'environment'},
      )..resetTracking();

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'view_item_list',
        parameters: const {
          'login_status': 'logged_in',
          'environment': 'production',
          'item_list_name': 'recommended',
          'item_list_id': 'rec_001',
        },
      );

      formatter.formatAndPrint(event);

      verify(
        () => logger.info('[12-25 10:30:45.123] view_item_list'),
      ).called(1);
      verify(() => logger.info('  Global Parameters:')).called(1);
      verify(() => logger.info('    login_status: logged_in')).called(1);
      verify(() => logger.info('    environment: production')).called(1);
      verify(() => logger.info('  Event Parameters:')).called(1);
      verify(() => logger.info('    item_list_name: recommended')).called(1);
      verify(() => logger.info('    item_list_id: rec_001')).called(1);
    });

    test('hides global params when toggled off in formatted output', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status', 'environment'},
      )
        ..resetTracking()
        ..hideGlobalParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'view_item_list',
        parameters: const {
          'login_status': 'logged_in',
          'environment': 'production',
          'item_list_name': 'recommended',
        },
      );

      formatter.formatAndPrint(event);

      verify(
        () => logger.info('[12-25 10:30:45.123] view_item_list'),
      ).called(1);
      verify(() => logger.info('  Parameters:')).called(1);
      verify(() => logger.info('    item_list_name: recommended')).called(1);
      verifyNever(() => logger.info('  Global Parameters:'));
      verifyNever(() => logger.info('    login_status: logged_in'));
      verifyNever(() => logger.info('    environment: production'));
    });

    test('hides global params in raw output when toggled off', () {
      final formatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
        globalParamNames: {'login_status', 'environment'},
      )
        ..resetTracking()
        ..hideGlobalParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'screen_view',
        parameters: const {
          'login_status': 'logged_in',
          'environment': 'production',
          'screen_name': 'Dashboard',
        },
      );

      formatter.formatAndPrint(event);

      verify(
        () => logger.info(
          '12-25 10:30:45.123 | screen_view | {screen_name: Dashboard}',
        ),
      ).called(1);
    });

    test('shows all params in raw output when globals visible', () {
      final formatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )..resetTracking();

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'screen_view',
        parameters: const {
          'login_status': 'logged_in',
          'screen_name': 'Dashboard',
        },
      );

      formatter.formatAndPrint(event);

      verify(
        () => logger.info(
          '12-25 10:30:45.123 | screen_view | '
          '{login_status: logged_in, screen_name: Dashboard}',
        ),
      ).called(1);
    });

    test('handles all params being global', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status', 'environment'},
      )..resetTracking();

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'session_start',
        parameters: const {
          'login_status': 'logged_in',
          'environment': 'production',
        },
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('  Global Parameters:')).called(1);
      verify(() => logger.info('    login_status: logged_in')).called(1);
      verify(() => logger.info('    environment: production')).called(1);
      verifyNever(() => logger.info('  Event Parameters:'));
    });

    test('handles no params matching global names', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )..resetTracking();

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {'currency': 'EUR', 'value': '99.99'},
      );

      formatter.formatAndPrint(event);

      verifyNever(() => logger.info('  Global Parameters:'));
      verify(() => logger.info('  Event Parameters:')).called(1);
      verify(() => logger.info('    currency: EUR')).called(1);
      verify(() => logger.info('    value: 99.99')).called(1);
    });

    test('no global param names falls back to single Parameters section', () {
      final formatter = EventFormatterService(logger, colorEnabled: false)
        ..resetTracking();

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {'currency': 'EUR'},
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('  Parameters:')).called(1);
      verifyNever(() => logger.info('  Global Parameters:'));
      verifyNever(() => logger.info('  Event Parameters:'));
    });

    test('hideGlobalParams getter reflects setter', () {
      final formatter = EventFormatterService(
        logger,
        globalParamNames: {'test'},
      );

      expect(formatter.hideGlobalParams, isFalse);
      formatter.hideGlobalParams = true;
      expect(formatter.hideGlobalParams, isTrue);
    });

    test('hides event params when hideEventParams is set', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )
        ..resetTracking()
        ..hideEventParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {
          'login_status': 'logged_in',
          'currency': 'EUR',
          'value': '99.99',
        },
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('  Parameters:')).called(1);
      verify(() => logger.info('    login_status: logged_in')).called(1);
      verifyNever(() => logger.info('  Event Parameters:'));
      verifyNever(() => logger.info('    currency: EUR'));
      verifyNever(() => logger.info('    value: 99.99'));
    });

    test('hides event params in raw output when hideEventParams is set', () {
      final formatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )
        ..resetTracking()
        ..hideEventParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {'login_status': 'logged_in', 'currency': 'EUR'},
      );

      formatter.formatAndPrint(event);

      verify(
        () => logger.info(
          '12-25 10:30:45.123 | purchase | {login_status: logged_in}',
        ),
      ).called(1);
    });

    test('hides both sections when both flags are set', () {
      final formatter = EventFormatterService(
        logger,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )
        ..resetTracking()
        ..hideGlobalParams = true
        ..hideEventParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {'login_status': 'logged_in', 'currency': 'EUR'},
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('[12-25 10:30:45.123] purchase')).called(1);
      verifyNever(() => logger.info('  Parameters:'));
      verifyNever(() => logger.info('  Global Parameters:'));
      verifyNever(() => logger.info('  Event Parameters:'));
    });

    test('hides both in raw output produces empty params map', () {
      final formatter = EventFormatterService(
        logger,
        rawOutput: true,
        colorEnabled: false,
        globalParamNames: {'login_status'},
      )
        ..resetTracking()
        ..hideGlobalParams = true
        ..hideEventParams = true;

      final event = AnalyticsEvent.fromParsedLog(
        rawTimestamp: '12-25 10:30:45.123',
        eventName: 'purchase',
        parameters: const {'login_status': 'logged_in', 'currency': 'EUR'},
      );

      formatter.formatAndPrint(event);

      verify(() => logger.info('12-25 10:30:45.123 | purchase | {}')).called(1);
    });
  });
}
