import 'package:famon/src/services/event_cache_service.dart';
import 'package:famon/src/services/interfaces/event_cache_interface.dart';
import 'package:test/test.dart';

void main() {
  group('EventCacheService', () {
    late EventCacheInterface cache;

    setUp(() {
      cache = EventCacheService()..clear(); // Ensure clean state
    });

    test('should track unique event names', () {
      cache
        ..addEvent('purchase')
        ..addEvent('add_to_cart')
        ..addEvent('purchase'); // duplicate

      expect(cache.allEventNames, containsAll(['purchase', 'add_to_cart']));
      expect(cache.allEventNames.length, equals(2));
    });

    test('should handle empty event names gracefully', () {
      cache
        ..addEvent('')
        ..addEvent('valid_event');

      expect(cache.allEventNames, contains('valid_event'));
      expect(cache.allEventNames, isNot(contains('')));
      expect(cache.allEventNames.length, equals(1));
    });

    test('should count event frequencies', () {
      cache
        ..addEvent('purchase')
        ..addEvent('purchase')
        ..addEvent('add_to_cart');

      expect(cache.getEventCount('purchase'), equals(2));
      expect(cache.getEventCount('add_to_cart'), equals(1));
      expect(cache.getEventCount('unknown'), equals(0));
    });

    test('should return events sorted by frequency', () {
      cache
        ..addEvent('screen_view') // 3 times
        ..addEvent('screen_view')
        ..addEvent('screen_view')
        ..addEvent('purchase') // 1 time
        ..addEvent('add_to_cart') // 2 times
        ..addEvent('add_to_cart');

      final sortedEvents = cache.getEventsByFrequency();
      expect(sortedEvents, ['screen_view', 'add_to_cart', 'purchase']);
    });

    test('should return top N events with bounds checking', () {
      cache.addEvent('event1'); // 5 times
      for (var i = 0; i < 5; i++) {
        cache.addEvent('event1');
      }

      cache.addEvent('event2'); // 3 times
      for (var i = 0; i < 3; i++) {
        cache.addEvent('event2');
      }

      cache.addEvent('event3'); // 1 time

      final top2 = cache.getTopEvents(2);
      expect(top2, ['event1', 'event2']);
      expect(top2.length, equals(2));

      // Test bounds
      final topNegative = cache.getTopEvents(-1);
      expect(topNegative, isEmpty);

      final topZero = cache.getTopEvents(0);
      expect(topZero, isEmpty);
    });
    test('should search events by pattern with error handling', () {
      cache
        ..addEvent('add_to_cart')
        ..addEvent('add_to_wishlist')
        ..addEvent('purchase')
        ..addEvent('screen_view');

      final searchResults = cache.searchEvents('add_');
      expect(searchResults, containsAll(['add_to_cart', 'add_to_wishlist']));
      expect(searchResults.length, equals(2));

      // Test empty pattern
      final emptyResults = cache.searchEvents('');
      expect(emptyResults, isEmpty);

      // Test invalid regex (should return empty list)
      final invalidResults = cache.searchEvents('[invalid');
      expect(invalidResults, isEmpty);
    });

    test('should suggest events to hide based on frequency', () {
      // Add a very frequent event (more than threshold)
      for (var i = 0; i < 15; i++) {
        cache.addEvent('screen_view');
      }

      cache.addEvent('purchase'); // less frequent

      final suggestions = cache.getSuggestedToHide();
      expect(suggestions, contains('screen_view'));
      expect(suggestions, isNot(contains('purchase')));
    });

    test('should provide session statistics', () {
      cache
        ..addEvent('event1')
        ..addEvent('event1')
        ..addEvent('event2');

      final stats = cache.getSessionStats();
      expect(stats.totalUniqueEvents, equals(2));
      expect(stats.totalEventOccurrences, equals(3));
      expect(stats.mostFrequentEvent, equals('event1'));
    });

    test('should clear cache properly', () {
      cache.addEvent('test');
      expect(cache.allEventNames.isNotEmpty, true);

      cache.clear();
      expect(cache.allEventNames.isEmpty, true);
      expect(cache.getEventCount('test'), equals(0));
    });

    test('should return immutable lists', () {
      cache.addEvent('test_event');

      final allEvents = cache.allEventNames;
      final frequencyEvents = cache.getEventsByFrequency();
      final topEvents = cache.getTopEvents(5);
      final searchResults = cache.searchEvents('test');
      final suggestedToHide = cache.getSuggestedToHide();

      // Verify all returned lists are unmodifiable
      expect(() => allEvents.add('new'), throwsUnsupportedError);
      expect(() => frequencyEvents.add('new'), throwsUnsupportedError);
      expect(() => topEvents.add('new'), throwsUnsupportedError);
      expect(() => searchResults.add('new'), throwsUnsupportedError);
      expect(() => suggestedToHide.add('new'), throwsUnsupportedError);
    });
  });
}
