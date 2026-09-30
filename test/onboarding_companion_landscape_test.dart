import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  for (final language in ['de', 'en']) {
    for (final height in [360.0, 480.0, 500.0, 520.0, 540.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'both companions and continue are reachable in landscape $language $height $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(760, height);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            final copy = onboardingV2Copy(lookupAppL10n(Locale(language)));
            String? chosen;
            String? continued;
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                locale: Locale(language),
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(
                      left: 44,
                      right: 44,
                      bottom: 21,
                    ),
                    viewPadding: const EdgeInsets.only(
                      left: 44,
                      right: 44,
                      bottom: 21,
                    ),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: SoriTypeScale(child: child!),
                ),
                home: StatefulBuilder(
                  builder: (context, setState) => OnboardingCompanionScreen(
                    copy: copy,
                    selectedCompanionId: chosen,
                    onCompanionChanged: (value) =>
                        setState(() => chosen = value),
                    onContinue: (value) => continued = value,
                    mediaEnabled: false,
                  ),
                ),
              ),
            );
            await tester.pump();
            for (final id in ['taego', 'joy']) {
              final tile = find.byKey(ValueKey('onboarding-v2-companion-$id'));
              await tester.ensureVisible(tile);
              await tester.pumpAndSettle();
              // Short viewports scroll; taller compact layouts fit both choices.
              // In either case, the visible tap target must remain at least 48dp.
              final scrolls = find.ancestor(
                of: tile,
                matching: find.byType(SingleChildScrollView),
              );
              final viewport = scrolls.evaluate().isNotEmpty
                  ? scrolls.first
                  : find.byKey(
                      const ValueKey('onboarding-v2-companion-scroll'),
                    );
              final visible = tester
                  .getRect(tile)
                  .intersect(tester.getRect(viewport));
              expect(visible.height, greaterThanOrEqualTo(48));
              await tester.tapAt(visible.center);
              await tester.pump();
              expect(chosen, id);
              expect(tester.takeException(), isNull);
            }
            final next = find.byKey(
              const ValueKey('onboarding-v2-companion-continue'),
            );
            expect(next.hitTestable(), findsOneWidget);
            await tester.tap(next);
            expect(continued, 'joy');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
