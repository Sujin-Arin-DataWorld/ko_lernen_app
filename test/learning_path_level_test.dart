import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';

/// [pathVisibleLevel] is the single source of truth for which CEFR level the
/// Lernpfad renders. It must never return an empty/invalid level (the path
/// would be blank) and must map onboarding codes to the upper-case pack code.
void main() {
  test('falls back to A1 before onboarding or on invalid input', () {
    expect(pathVisibleLevel(null), 'A1');
    expect(pathVisibleLevel(''), 'A1');
    expect(pathVisibleLevel('   '), 'A1');
    expect(pathVisibleLevel('nonsense'), 'A1');
    expect(pathVisibleLevel('c1'), 'A1');
  });

  test('returns the chosen level upper-cased', () {
    expect(pathVisibleLevel('a1'), 'A1');
    expect(pathVisibleLevel('a2'), 'A2');
    expect(pathVisibleLevel('b1'), 'B1');
    expect(pathVisibleLevel('b2'), 'B2');
  });

  test('tolerates surrounding whitespace and upper-case input', () {
    expect(pathVisibleLevel(' a2 '), 'A2');
    expect(pathVisibleLevel('B2'), 'B2');
  });
}
