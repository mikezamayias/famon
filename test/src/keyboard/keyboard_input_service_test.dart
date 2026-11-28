import 'dart:async';
import 'dart:io';

import 'package:famon/src/keyboard/keyboard_input_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/stdio_fakes.dart';

class MockSubscription extends Mock implements StreamSubscription<List<int>> {}

void main() {
  group('KeyboardInputService with stdin from /dev/null', () {
    test('is not interactive, and start and dispose do not throw', () {
      final stdin = devNullStdin();

      IOOverrides.runZoned(
        () {
          final service = KeyboardInputService();
          expect(service.isInteractive, isFalse);
          expect(service.start, returnsNormally);
          expect(service.dispose, returnsNormally);
        },
        stdin: () => stdin,
      );

      verifyNever(() => stdin.lineMode = any());
      verifyNever(() => stdin.echoMode = any());
      verifyNever(
        () => stdin.listen(
          any(),
          onError: any(named: 'onError'),
          cancelOnError: any(named: 'cancelOnError'),
        ),
      );
    });
  });

  group('KeyboardInputService on a terminal', () {
    test('restores the terminal mode before it closes stdin', () {
      final stdin = MockStdin();
      final subscription = MockSubscription();
      var lineMode = true;
      when(() => stdin.hasTerminal).thenReturn(true);
      when(() => stdin.lineMode).thenAnswer((_) => lineMode);
      when(() => stdin.lineMode = any()).thenAnswer((invocation) {
        return lineMode = invocation.positionalArguments.single as bool;
      });
      when(() => stdin.echoMode).thenReturn(true);
      when(
        () => stdin.listen(
          any(),
          onError: any(named: 'onError'),
          cancelOnError: any(named: 'cancelOnError'),
        ),
      ).thenReturn(subscription);
      when(subscription.cancel).thenAnswer((_) async {});

      IOOverrides.runZoned(
        () => KeyboardInputService()
          ..start()
          ..dispose(),
        stdin: () => stdin,
      );

      // Cancelling the stdin subscription closes stdin, so the mode must be
      // restored first.
      verifyInOrder([
        () => stdin.lineMode = false,
        () => stdin.echoMode = false,
        () => stdin.lineMode = true,
        () => stdin.echoMode = true,
        subscription.cancel,
      ]);
    });
  });
}
