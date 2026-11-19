import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';

void main() {
  for (final dpr in [1.0, 2.75]) {
    testWidgets('jade face has no transparent seams at DPR $dpr', (
      tester,
    ) async {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = Size(240 * dpr, 80 * dpr);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const boundaryKey = ValueKey('material-on-transparent-canvas');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 195,
                height: 48,
                child: ApprovedMaterial('jadeControl'),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(
            'assets/illustrations/approved_games/jade_control_approved.png',
          ),
          tester.element(find.byKey(boundaryKey)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: dpr);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          // A broad cross through the opaque face spans both directions of
          // internal joins, without depending on the renderer's slice grid.
          // Rounded outer corners and the original translucent shadow are
          // intentionally outside these regions. A transparent background
          // exposes coverage gaps which an opaque backing could conceal.
          for (final region in const [
            Rect.fromLTRB(12, 20, 183, 30),
            Rect.fromLTRB(50, 8, 145, 46),
          ]) {
            var minimumAlpha = 255;
            for (
              var y = (region.top * dpr).ceil();
              y < (region.bottom * dpr).floor();
              y++
            ) {
              for (
                var x = (region.left * dpr).ceil();
                x < (region.right * dpr).floor();
                x++
              ) {
                final alpha = bytes.getUint8((y * image.width + x) * 4 + 3);
                if (alpha < minimumAlpha) minimumAlpha = alpha;
              }
            }
            expect(
              minimumAlpha,
              // The original face has slight translucency (alpha252). Keep
              // that artwork while rejecting image-edge coverage gaps.
              greaterThanOrEqualTo(250),
              reason:
                  'The jade face must stay opaque across $region at DPR $dpr',
            );
          }
        } finally {
          image.dispose();
        }
      });
    });
  }
}
