import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in <double>[1.0, 1.3]) {
    testWidgets(
      'German story 1 keeps the Hanok preview intact and details reachable '
      'at 360dp (×$scale)',
      (tester) async {
        await _pump(tester, textScale: scale);

        final hero = find.byKey(const ValueKey('onboarding-v2-story-hero'));
        final preview = find.descendant(
          of: hero,
          matching: find.byKey(
            const ValueKey('onboarding-v2-hanok-growth-preview'),
          ),
        );
        expect(preview, findsOneWidget);
        final previewSize = tester.getSize(preview);
        expect(previewSize.width / previewSize.height, closeTo(4 / 3, .01));
        final image = tester.widget<Image>(
          find.descendant(of: preview, matching: find.byType(Image)),
        );
        expect(image.fit, BoxFit.contain);
        expect((image.image as AssetImage).assetName, kIlDuV3PreviewAsset);

        final details = find.text('Lehrplan und Quellen');
        expect(details, findsOneWidget);
        await tester.tap(details);
        await tester.pumpAndSettle();
        for (final level in ['A1', 'A2', 'C2']) {
          expect(find.textContaining('$level ·'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pump(WidgetTester tester, {required double textScale}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) => OnboardingStoryScreen(
          copy: onboardingV2Copy(AppL10n.of(context)),
          pageIndex: 0,
          onContinue: (_) {},
          onPrevious: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
