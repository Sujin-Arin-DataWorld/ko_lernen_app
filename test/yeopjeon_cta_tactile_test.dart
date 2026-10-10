import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_material.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_reward_style.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  testWidgets(
    'raised CTA reacts to contact, cancels safely and activates once',
    (tester) async {
      tester.view.physicalSize = const Size(402, 380);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final evidence = GlobalKey();
      var activations = 0;
      Future<void> render(double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: false,
              ),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: YeopjeonRewardStyle.paper,
              body: RepaintBoundary(
                key: evidence,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      YeopjeonAction(
                        label: 'Visit my Ildu house',
                        onTap: () => activations++,
                      ),
                      const SizedBox(height: 8),
                      YeopjeonAction(
                        label: 'Keep learning',
                        primary: false,
                        onTap: () => activations++,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/animations/rewards/cta_atlas.png'),
            evidence.currentContext!,
          );
          await precacheImage(
            const AssetImage('assets/animations/rewards/arrow.png'),
            evidence.currentContext!,
          );
        });
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        if (Platform.environment['CAPTURE_YEOPJEON_CTA'] != '1') return;
        final boundary =
            evidence.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            'tool/yeopjeon_c_mockups/review-proof/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await render(1);
      await capture('proof-final-native-cta-normal');
      final label = find.text('Visit my Ildu house');
      final resting = tester.getCenter(label);
      final gesture = await tester.startGesture(resting);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.getCenter(label).dy, greaterThan(resting.dy));
      expect(activations, 0);
      await capture('proof-final-native-cta-pressed');
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(activations, 0);
      expect(tester.getCenter(label).dy, closeTo(resting.dy, .1));
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(activations, 1);
      await render(2);
      final surface = find.descendant(
        of: find.byType(YeopjeonCtaMaterial).first,
        matching: find.byType(CustomPaint),
      );
      expect(tester.getSize(surface).height, greaterThan(54));
      await capture('proof-final-native-cta-expanded');
      expect(tester.takeException(), isNull);
    },
  );
}
