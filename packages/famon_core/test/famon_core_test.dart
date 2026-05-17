import 'package:famon_core/famon_core.dart';
import 'package:test/test.dart';

void main() {
  test('library exports load without error', () {
    // Touching a real exported type confirms the barrel file resolves
    // and the package can be imported. Real coverage lives in the CLI's
    // top-level `test/` suite, which exercises famon_core through use.
    expect(LogParserService, isNotNull);
  });
}
