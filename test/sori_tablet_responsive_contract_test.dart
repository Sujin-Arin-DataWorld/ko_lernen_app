import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/responsive.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  group('tablet responsive contracts', () {
    test('content column grows smoothly through the tablet breakpoint', () {
      expect(soriAdaptiveContentMaxWidth(360), SoriBreakpoints.content);
      expect(soriAdaptiveContentMaxWidth(SoriBreakpoints.grid), 480);
      expect(soriAdaptiveContentMaxWidth(660), 560);
      expect(soriAdaptiveContentMaxWidth(SoriBreakpoints.tablet), 640);
      expect(soriAdaptiveContentMaxWidth(1280), 640);
    });

    test('comfort scale grows only for wide device layouts', () {
      expect(soriComfortScale(360), 1);
      expect(soriComfortScale(SoriBreakpoints.grid), 1);
      expect(soriComfortScale(660), 1.05);
      expect(soriComfortScale(SoriBreakpoints.tablet), 1.1);
      expect(soriComfortScale(1280), 1.1);
    });

    test('default clamp uses the tablet content column', () {
      final padding = soriClampPadding(
        1000,
        base: const EdgeInsets.symmetric(horizontal: 16),
      );

      expect(padding.left, 16 + 180); // (1000 - 640) / 2 = 180
      expect(padding.right, 16 + 180);
    });

    testWidgets('content clamp uses the tablet column by default', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late EdgeInsets captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriContentClamp(
              base: const EdgeInsets.symmetric(horizontal: 16),
              builder: (_, padding) {
                captured = padding;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(captured.left, 16 + 180); // (1000 - 640) / 2 = 180
      expect(captured.right, 16 + 180);
    });
  });
}
