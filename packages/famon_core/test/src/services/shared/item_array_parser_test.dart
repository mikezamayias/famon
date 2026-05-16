import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  group('ItemArrayParser', () {
    group('stripAndroidItemsArray', () {
      test('removes the items array from a Bundle params string', () {
        const input = 'items=[Bundle[{item_id=a}]], currency=USD';
        expect(
          ItemArrayParser.stripAndroidItemsArray(input),
          'currency=USD',
        );
      });

      test('joins surrounding params, preserving Android `,` delimiter', () {
        const input = 'currency=USD, items=[Bundle[{item_id=a}]], total=10';
        // Android leaves the trailing `,` from the prefix in place because
        // the downstream `_paramPatterns` regex uses `[,\]}]|$` to bound
        // each value, so the duplicated comma is harmless.
        expect(
          ItemArrayParser.stripAndroidItemsArray(input),
          'currency=USD,, total=10',
        );
      });

      test('returns input unchanged when no items key', () {
        const input = 'currency=USD, total=10';
        expect(
          ItemArrayParser.stripAndroidItemsArray(input),
          'currency=USD, total=10',
        );
      });

      test('drops everything from items=[ onward when truncated', () {
        const input = 'currency=USD, items=[Bundle[{item_id=a}]';
        // Trailing `,` is preserved; the truncated array is dropped after
        // `trimRight` and the downstream regex tolerates the dangling comma.
        expect(
          ItemArrayParser.stripAndroidItemsArray(input),
          'currency=USD,',
        );
      });

      test('handles nested brackets via depth tracking', () {
        const input =
            'items=[Bundle[{nested=[1, 2]}], Bundle[{item_id=b}]], extra=v';
        expect(
          ItemArrayParser.stripAndroidItemsArray(input),
          'extra=v',
        );
      });
    });

    group('extractAndroidItemsSubstring', () {
      test('returns the content between matching brackets', () {
        const input = 'items=[Bundle[{item_id=a}], Bundle[{item_id=b}]], x=1';
        expect(
          ItemArrayParser.extractAndroidItemsSubstring(input),
          'Bundle[{item_id=a}], Bundle[{item_id=b}]',
        );
      });

      test('returns remainder when bracket is truncated', () {
        const input = 'items=[Bundle[{item_id=a}]';
        expect(
          ItemArrayParser.extractAndroidItemsSubstring(input),
          'Bundle[{item_id=a}]',
        );
      });

      test('returns null when no items key', () {
        const input = 'currency=USD';
        expect(
          ItemArrayParser.extractAndroidItemsSubstring(input),
          isNull,
        );
      });
    });

    group('stripIosItemsArray', () {
      final pattern = RegExp(r'items\s*=\s*\[');

      test('removes items array from iOS-style params', () {
        const input = 'items = [{item_id (_a) = a}]; currency (_c) = USD';
        expect(
          ItemArrayParser.stripIosItemsArray(input, pattern),
          'currency (_c) = USD',
        );
      });

      test('joins surrounding params, preserving iOS `;` delimiters', () {
        const input = 'currency (_c) = USD; items = [{x = 1}]; total = 10';
        // iOS `_paramPatterns` requires a trailing `;` to bound each value,
        // so the helper preserves both the prefix's trailing `;` and the
        // suffix's leading `;` and joins them with a single space.
        expect(
          ItemArrayParser.stripIosItemsArray(input, pattern),
          'currency (_c) = USD; ; total = 10',
        );
      });

      test('returns input unchanged when no items key', () {
        const input = 'currency (_c) = USD; total = 10';
        expect(
          ItemArrayParser.stripIosItemsArray(input, pattern),
          'currency (_c) = USD; total = 10',
        );
      });

      test('drops everything from items onward when truncated', () {
        const input = 'currency (_c) = USD; items = [{x = 1}';
        // Trailing `;` is preserved; the truncated array is dropped after
        // `trimRight`. iOS param parsing tolerates the dangling delimiter.
        expect(
          ItemArrayParser.stripIosItemsArray(input, pattern),
          'currency (_c) = USD;',
        );
      });
    });

    group('extractIosItemsSubstring', () {
      final pattern = RegExp(r'items\s*=\s*\[');

      test('returns content between matching brackets', () {
        const input = 'items = [{item_id (_a) = a}, {item_id (_b) = b}]; x = 1';
        expect(
          ItemArrayParser.extractIosItemsSubstring(input, pattern),
          '{item_id (_a) = a}, {item_id (_b) = b}',
        );
      });

      test('returns remainder when bracket is truncated', () {
        const input = 'items = [{item_id (_a) = a}';
        expect(
          ItemArrayParser.extractIosItemsSubstring(input, pattern),
          '{item_id (_a) = a}',
        );
      });

      test('returns null when pattern does not match', () {
        const input = 'currency (_c) = USD';
        expect(
          ItemArrayParser.extractIosItemsSubstring(input, pattern),
          isNull,
        );
      });
    });
  });
}
