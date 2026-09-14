import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  test(
    'all four construction previews retain their real transparent backgrounds',
    () {
      for (final name in [
        'sarangchae-01-alpha',
        'sarangchae-02-alpha',
        'gate-01-alpha',
        'gate-02-alpha',
      ]) {
        final image = img.decodePng(
          File('assets/illustrations/onboarding/$name.png').readAsBytesSync(),
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
                      'sarangchae-0${i + 1}-alpha.png',
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
