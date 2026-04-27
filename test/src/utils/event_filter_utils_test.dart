import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('shouldSkipEvent', () {
    test('returns false when no filters are applied', () {
      expect(
        EventFilterUtils.shouldSkipEvent('screen_view', [], []),
        isFalse,
      );
    });

    test('returns true when event is in hide list', () {
      expect(
        EventFilterUtils.shouldSkipEvent(
          'screen_view',
          ['screen_view'],
          [],
        ),
        isTrue,
      );
    });

    test('returns false when event is not in hide list', () {
      expect(
        EventFilterUtils.shouldSkipEvent(
          'purchase',
          ['screen_view'],
          [],
        ),
        isFalse,
      );
    });

    test('returns false when event is in show-only list', () {
      expect(
        EventFilterUtils.shouldSkipEvent(
          'purchase',
          [],
          ['purchase'],
        ),
        isFalse,
      );
    });

    test('returns true when event is not in show-only list', () {
      expect(
        EventFilterUtils.shouldSkipEvent(
          'screen_view',
          [],
          ['purchase'],
        ),
        isTrue,
      );
    });

    test('show-only takes priority over hide', () {
      expect(
        EventFilterUtils.shouldSkipEvent(
          'purchase',
          ['purchase'],
          ['purchase'],
        ),
        isFalse,
      );
    });
  });

  group('shouldSkipEventWithFrequency', () {
    test('delegates to shouldSkipEvent for basic filters', () {
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'screen_view',
          ['screen_view'],
          [],
        ),
        isTrue,
      );
    });

    test('skips when frequency is below minFrequency', () {
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'purchase',
          [],
          [],
          eventFrequency: 2,
          minFrequency: 5,
        ),
        isTrue,
      );
    });

    test('skips when frequency is above maxFrequency', () {
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'screen_view',
          [],
          [],
          eventFrequency: 10,
          maxFrequency: 5,
        ),
        isTrue,
      );
    });

    test('passes when frequency is within range', () {
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'purchase',
          [],
          [],
          eventFrequency: 5,
          minFrequency: 3,
          maxFrequency: 10,
        ),
        isFalse,
      );
    });

    test('ignores frequency filters when eventFrequency is null', () {
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'purchase',
          [],
          [],
          minFrequency: 5,
          maxFrequency: 10,
        ),
        isFalse,
      );
    });

    test('applies both name and frequency filters', () {
      // Hidden by name — frequency doesn't matter
      expect(
        EventFilterUtils.shouldSkipEventWithFrequency(
          'screen_view',
          ['screen_view'],
          [],
          eventFrequency: 5,
          minFrequency: 1,
        ),
        isTrue,
      );
    });
  });
}
