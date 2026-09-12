import 'package:flutter_test/flutter_test.dart';
import '../integration_test/support/phase_native_configuration.dart';

void main() {
  test('one binary selects every level and a fresh restoration-only run', () {
    for (final level in PhaseNativeConfiguration.levels) {
      final normal = PhaseNativeConfiguration.fromRoute('/phase-qa/$level');
      final restore = PhaseNativeConfiguration.fromRoute(
        '/phase-qa/$level/restore',
      );
      expect(normal.level, level);
      expect(normal.restoreOnly, isFalse);
      expect(restore.level, level);
      expect(restore.restoreOnly, isTrue);
    }
  });
  test('ordinary launch retains compile-time QA defaults', () {
    final config = PhaseNativeConfiguration.fromRoute(
      '/',
      defaultLevel: 'B1',
      defaultRestoreOnly: true,
    );
    expect(config.level, 'B1');
    expect(config.restoreOnly, isTrue);
  });
  test('invalid routes cannot silently test another level or mode', () {
    for (final route in [
      '/phase-qa/ALL',
      '/phase-qa/b1',
      '/phase-qa/B1/restart',
      '/phase-qa/B1/restore/extra',
      '/phase-qa/B1?restore=true',
      'https://example.org/phase-qa/B1',
      '//example.org/phase-qa/B1',
      '/learning-phase/task',
    ]) {
      expect(
        () => PhaseNativeConfiguration.fromRoute(route),
        throwsArgumentError,
      );
    }
    expect(
      () => PhaseNativeConfiguration.fromRoute('/', defaultLevel: 'typo'),
      throwsArgumentError,
    );
  });
}
