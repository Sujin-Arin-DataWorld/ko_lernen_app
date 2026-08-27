import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// §15 — `SoriLayout.heroFit` must honor the height budget (`heroMaxShare`/
/// `heroMaxHeight`) *and* an aspect-locked hero's ratio at the same time.
/// When both can't fit as-is, width gives — never height-only clamping
/// (which breaks the ratio) and never a 0dp collapse (controller ruling
/// 2026-08-27, following the scenarios_list_screen regression this fixes;
/// see `visual_layout_regression_test.dart`).
void main() {
  test(
    'narrow phone (360x780) shrinks a 16:9 hero to the height budget, keeping the ratio',
    () {
      // content width ~328dp (360 viewport - 32dp horizontal page padding),
      // matching scenarios_list_screen's real layout.
      const availableWidth = 328.0;
      const viewportHeight = 780.0;
      final budget = viewportHeight * SoriLayout.heroMaxShare; // 171.6, < 200 cap

      final fit = SoriLayout.heroFit(
        availableWidth: availableWidth,
        viewportHeight: viewportHeight,
        aspectRatio: 16 / 9,
      );

      expect(fit.height, closeTo(budget, 0.001));
      expect(fit.width / fit.height, closeTo(16 / 9, 0.0001));
      expect(fit.width, lessThan(availableWidth));
    },
  );

  test(
    'wide viewport where the natural height already fits the budget stays unchanged',
    () {
      const availableWidth = 328.0;
      const viewportHeight = 2000.0; // budget capped at heroMaxHeight (200)
      final naturalHeight = availableWidth / (16 / 9); // ~184.5, under 200

      final fit = SoriLayout.heroFit(
        availableWidth: availableWidth,
        viewportHeight: viewportHeight,
        aspectRatio: 16 / 9,
      );

      expect(fit.width, availableWidth);
      expect(fit.height, closeTo(naturalHeight, 0.001));
    },
  );

  test('a hero with no aspect ratio just clamps height, keeping full width', () {
    const availableWidth = 328.0;
    const viewportHeight = 780.0;
    final budget = viewportHeight * SoriLayout.heroMaxShare;

    final fit = SoriLayout.heroFit(
      availableWidth: availableWidth,
      viewportHeight: viewportHeight,
    );

    expect(fit.width, availableWidth);
    expect(fit.height, closeTo(budget, 0.001));
  });
}
