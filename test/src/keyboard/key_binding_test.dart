import 'package:firebase_analytics_monitor/src/keyboard/key_binding.dart';
import 'package:test/test.dart';

void main() {
  group('KeyBinding', () {
    group('fromString', () {
      test('parses simple key', () {
        final binding = KeyBinding.fromString('q');
        expect(binding.key, equals('q'));
        expect(binding.ctrl, isFalse);
        expect(binding.shift, isFalse);
        expect(binding.alt, isFalse);
        expect(binding.meta, isFalse);
      });

      test('parses ctrl modifier', () {
        final binding = KeyBinding.fromString('ctrl+c');
        expect(binding.key, equals('c'));
        expect(binding.ctrl, isTrue);
        expect(binding.shift, isFalse);
      });

      test('parses shift modifier', () {
        final binding = KeyBinding.fromString('shift+s');
        expect(binding.key, equals('s'));
        expect(binding.shift, isTrue);
        expect(binding.ctrl, isFalse);
      });

      test('parses alt modifier', () {
        final binding = KeyBinding.fromString('alt+a');
        expect(binding.key, equals('a'));
        expect(binding.alt, isTrue);
      });

      test('parses meta/cmd modifier', () {
        final binding = KeyBinding.fromString('cmd+m');
        expect(binding.key, equals('m'));
        expect(binding.meta, isTrue);
      });

      test('parses multiple modifiers', () {
        final binding = KeyBinding.fromString('ctrl+shift+s');
        expect(binding.key, equals('s'));
        expect(binding.ctrl, isTrue);
        expect(binding.shift, isTrue);
        expect(binding.alt, isFalse);
      });

      test('handles case insensitivity', () {
        final binding = KeyBinding.fromString('CTRL+SHIFT+S');
        expect(binding.key, equals('s'));
        expect(binding.ctrl, isTrue);
        expect(binding.shift, isTrue);
      });

      test('handles empty string', () {
        final binding = KeyBinding.fromString('');
        expect(binding.key, equals(''));
      });
    });

    group('toDisplayString', () {
      test('displays simple key', () {
        const binding = KeyBinding(key: 'q');
        expect(binding.toDisplayString(), equals('Q'));
      });

      test('displays ctrl modifier', () {
        const binding = KeyBinding(key: 'c', ctrl: true);
        expect(binding.toDisplayString(), equals('Ctrl+C'));
      });

      test('displays multiple modifiers in order', () {
        const binding = KeyBinding(key: 's', ctrl: true, shift: true);
        expect(binding.toDisplayString(), equals('Ctrl+Shift+S'));
      });

      test('displays all modifiers', () {
        const binding = KeyBinding(
          key: 'x',
          ctrl: true,
          shift: true,
          alt: true,
          meta: true,
        );
        expect(binding.toDisplayString(), equals('Ctrl+Shift+Alt+Cmd+X'));
      });
    });

    group('matches', () {
      test('matches simple key', () {
        const binding = KeyBinding(key: 'q');
        expect(binding.matches(eventKey: 'q'), isTrue);
        expect(binding.matches(eventKey: 'Q'), isTrue);
        expect(binding.matches(eventKey: 'x'), isFalse);
      });

      test('matches with ctrl modifier', () {
        const binding = KeyBinding(key: 'c', ctrl: true);
        expect(
          binding.matches(eventKey: 'c', eventCtrl: true),
          isTrue,
        );
        expect(
          binding.matches(eventKey: 'c', eventCtrl: false),
          isFalse,
        );
      });

      test('matches with shift modifier', () {
        const binding = KeyBinding(key: 's', shift: true);
        expect(
          binding.matches(eventKey: 's', eventShift: true),
          isTrue,
        );
        expect(
          binding.matches(eventKey: 's', eventShift: false),
          isFalse,
        );
      });

      test('requires all modifiers to match', () {
        const binding = KeyBinding(key: 's', ctrl: true, shift: true);
        expect(
          binding.matches(eventKey: 's', eventCtrl: true, eventShift: true),
          isTrue,
        );
        expect(
          binding.matches(eventKey: 's', eventCtrl: true, eventShift: false),
          isFalse,
        );
        expect(
          binding.matches(eventKey: 's', eventCtrl: false, eventShift: true),
          isFalse,
        );
      });
    });

    group('equality', () {
      test('equal bindings are equal', () {
        const binding1 = KeyBinding(key: 'c', ctrl: true);
        const binding2 = KeyBinding(key: 'c', ctrl: true);
        expect(binding1, equals(binding2));
        expect(binding1.hashCode, equals(binding2.hashCode));
      });

      test('different keys are not equal', () {
        const binding1 = KeyBinding(key: 'c', ctrl: true);
        const binding2 = KeyBinding(key: 'd', ctrl: true);
        expect(binding1, isNot(equals(binding2)));
      });

      test('different modifiers are not equal', () {
        const binding1 = KeyBinding(key: 'c', ctrl: true);
        const binding2 = KeyBinding(key: 'c', shift: true);
        expect(binding1, isNot(equals(binding2)));
      });
    });
  });
}
