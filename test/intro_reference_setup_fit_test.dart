import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_reference_setup.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });

  for (final language in ['de', 'en']) {
    for (final size in [const Size(320, 402), const Size(402, 500)]) {
      for (final level in ['beginner', 'A2', 'unselected']) {
        testWidgets(
          '$language $size $level fits without scrolling or selection reflow',
          (tester) async {
            tester.view.physicalSize = const Size(420, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final copy = onboardingV2Copy(lookupAppL10n(Locale(language)));
            var selected = copy.setup.purposes.first.id;
            var levelRequests = 0;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                theme: AppTheme.light,
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      key: const ValueKey('finite-setup-body'),
                      width: size.width,
                      height: size.height,
                      child: StatefulBuilder(
                        builder: (context, update) => IntroReferenceSetup(
                          copy: copy,
                          selectedPurposeId: selected,
                          selectedLevelCode: level == 'A2' ? 'A2' : null,
                          beginnerSelected: level == 'beginner',
                          onPurposeChanged: (value) =>
                              update(() => selected = value),
                          onChooseLevel: () => levelRequests++,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(Scrollable), findsNothing);
            final body = tester.getRect(
              find.byKey(const ValueKey('finite-setup-body')),
            );
            final cards = [
              for (final purpose in copy.setup.purposes)
                find.byKey(ValueKey('onboarding-purpose-${purpose.id}')),
            ];
            final cardRects = [for (final card in cards) tester.getRect(card)];
            final arts = [
              for (final name in [
                'interest-travel',
                'interest-culture',
                'interest-study',
                'interest-kcontent',
              ])
                find.byWidgetPredicate(
                  (widget) => widget is CIntroArt && widget.name == name,
                ),
            ];
            final artRects = [for (final art in arts) tester.getRect(art)];
            for (final rect in artRects) {
              expect(rect.height, greaterThanOrEqualTo(52));
            }
            for (final rect in cardRects) {
              expect(rect.height, greaterThanOrEqualTo(48));
              expect(rect.width, greaterThanOrEqualTo(48));
              expect(body.contains(rect.topLeft), isTrue);
              expect(
                body.contains(rect.bottomRight - const Offset(.01, .01)),
                isTrue,
              );
            }
            final levelField = find.byKey(
              const ValueKey('c-onboarding-change-level'),
            );
            expect(tester.getSize(levelField).height, greaterThanOrEqualTo(48));
            for (final paragraph in tester.renderObjectList<RenderParagraph>(
              find.byType(RichText),
            )) {
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: paragraph.text.toPlainText(),
              );
            }
            for (final index in [0, 1, 0]) {
              await tester.tap(cards[index]);
              await tester.pumpAndSettle();
              expect(selected, copy.setup.purposes[index].id);
              expect([
                for (final card in cards) tester.getRect(card),
              ], cardRects);
              expect([for (final art in arts) tester.getRect(art)], artRects);
              expect(tester.takeException(), isNull);
            }
            await tester.tap(levelField);
            await tester.pumpAndSettle();
            expect(levelRequests, 1);
          },
        );
      }
    }
  }
}
