import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  test('lossless onboarding WebP keeps the approved RGBA pixels', () {
    // Digests were taken from the approved PNGs before their lossless conversion.
    // They include transparent pixels, not just the visible non-alpha area.
    const originals = {
      'book_extract': (
        1448,
        1086,
        '62435a619d16b813e797fc7316b3b51caf5fbf24c6578a21c2d6e3a7f936ccac',
      ),
      'gate-01-alpha': (
        1446,
        1087,
        '5ff68cbecb57b1b90efa5f996e747121c1e1a8e1405416cfe9095e8605c8e2cc',
      ),
      'gate-02-alpha': (
        1446,
        1087,
        '751168d3ff35d49d12fb7c4c0fa4764e6717d7627dc2f3da2164b7b3a0ce1e1c',
      ),
      'sarangchae-01-alpha': (
        1536,
        1024,
        '49300054991df8242417ab5f6d389cb4b7969be75d513c8f7f0d933254c446fb',
      ),
      'sarangchae-02-alpha': (
        1536,
        1024,
        '608972ed55aa8965296bc75d9d617d20e73d93bd386ff97a2359e4340860d391',
      ),
      'sarangchae_canonical': (
        1536,
        1024,
        '9ad674aa7ce47ec1ebfd50b483c3c5c1a56be4dbeb294271ab58be891f182d7d',
      ),
    };
    for (final entry in originals.entries) {
      final base = 'assets/illustrations/onboarding/${entry.key}';
      expect(File('$base.png').existsSync(), isFalse, reason: entry.key);
      final image = img.decodeWebP(File('$base.webp').readAsBytesSync())!;
      expect((image.width, image.height), (entry.value.$1, entry.value.$2));
      expect(
        sha256.convert(image.getBytes(order: img.ChannelOrder.rgba)).toString(),
        entry.value.$3,
        reason: entry.key,
      );
    }
  });

  test(
    'all four construction previews retain their real transparent backgrounds',
    () {
      for (final name in [
        'sarangchae-01-alpha',
        'sarangchae-02-alpha',
        'gate-01-alpha',
        'gate-02-alpha',
      ]) {
        final image = img.decodeWebP(
          File('assets/illustrations/onboarding/$name.webp').readAsBytesSync(),
        )!;
        var clear = 0;
        for (var y = 0; y < image.height; y += 12) {
          for (var x = 0; x < image.width; x += 12) {
            if (image.getPixel(x, y).a == 0) {
              clear++;
            }
          }
        }
        expect(clear, greaterThan(100), reason: name);
      }
    },
  );
  testWidgets(
    'Hanok reveals only first two stages and a rounded rectangular place',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1152);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: OnboardingStoryScreen(
            copy: onboardingV2Copy(lookupAppL10n(const Locale('de'))),
            pageIndex: 4,
            onContinue: (_) {},
            onPrevious: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-place-1')));
      await tester.pumpAndSettle();
      expect(find.text('누마루'), findsOneWidget);
      final window = tester
          .widgetList<ClipPath>(find.byType(ClipPath))
          .where((c) => c.clipper != null)
          .last;
      final path = window.clipper!.getClip(const Size(600, 400));
      final bounds = path.getBounds();
      expect(bounds.center.dx, greaterThan(450));
      expect(
        path.contains(Offset(bounds.left + 10, bounds.top + 3)),
        isTrue,
        reason: 'The view uses a rounded rectangle, not an ellipse.',
      );
      await tester.tap(find.text('So wächst er'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(ValueKey('onboarding-v3-growth-$i')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .any(
                (w) =>
                    w.image is AssetImage &&
                    (w.image as AssetImage).assetName.endsWith(
                      'sarangchae-0${i + 1}-alpha.webp',
                    ),
              ),
          isTrue,
        );
      }
      expect(
        find.byKey(const ValueKey('onboarding-v3-growth-2')),
        findsNothing,
      );
      expect(find.textContaining('16'), findsWidgets);
      expect(find.textContaining('12'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
