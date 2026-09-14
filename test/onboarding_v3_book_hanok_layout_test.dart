import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'kl_xp': 43, 'kl_level': 'b1'}),
  );

  for (final lang in ['de', 'en']) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        '$lang book and hanok at 320x640 and text $scale preserve artwork and all states',
        (tester) async {
          final speech = stubSoriSpeech();
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final t = lookupAppL10n(Locale(lang));
          final copy = onboardingV2Copy(t);
          final prefs = await SharedPreferences.getInstance();
          final before = {
            for (final key in prefs.getKeys()) key: prefs.get(key),
          };
          void fits(String state) {
            expect(tester.takeException(), isNull, reason: state);
            for (final element in find.byType(Text).evaluate()) {
              final render = element.findRenderObject();
              if (render is RenderBox && render.hasSize) {
                final rect = render.localToGlobal(Offset.zero) & render.size;
                expect(rect.left, greaterThanOrEqualTo(-0.5), reason: state);
                expect(rect.right, lessThanOrEqualTo(320.5), reason: state);
                expect(rect.bottom, lessThanOrEqualTo(640.5), reason: state);
              }
            }
            for (final element in find.byType(Scrollable).evaluate()) {
              expect(
                (element.widget as Scrollable).axisDirection,
                isNot(AxisDirection.down),
                reason: state,
              );
            }
          }

          Future<void> page(int index, LearnerLevel level) async {
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(lang),
                theme: AppTheme.light,
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 44, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: SoriTypeScale(child: child!),
                ),
                home: OnboardingStoryScreen(
                  key: ValueKey('$index-$level'),
                  copy: copy,
                  selectedLevel: level,
                  pageIndex: index,
                  onContinue: (_) {},
                  onPrevious: (_) {},
                ),
              ),
            );
            await tester.pumpAndSettle();
            fits('page $index $level');
          }

          Future<void> tap(String key) async {
            final finder = find.byKey(ValueKey(key));
            expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
            await tester.tap(finder);
            await tester.pumpAndSettle();
            fits(key);
          }

          for (final level in LearnerLevel.values) {
            await page(3, level);
            expect(
              tester
                  .getSize(
                    find.byKey(const ValueKey('onboarding-v3-book-photo')),
                  )
                  .height,
              greaterThan(60),
            );
            await tap('onboarding-v3-book-action');
            await tap('onboarding-v3-book-meaning');
            await tap('onboarding-v3-book-meaning');
            await tap('onboarding-v3-book-audio');
            expect(speech.spoken, isNotEmpty);
            await tap('onboarding-v3-book-action');
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('onboarding-v3-book-action')),
                matching: find.byIcon(Icons.check),
              ),
              findsOneWidget,
            );
            await tap('onboarding-v3-book-action');
            await tap('onboarding-v3-book-replay');
            expect(
              find.byKey(const ValueKey('onboarding-v3-book-photo')),
              findsOneWidget,
            );
          }
          await page(4, LearnerLevel.a1);
          for (var place = 0; place < 3; place++) {
            await tap('onboarding-v3-place-$place');
            if (place == 1) {
              expect(find.text(t.onboardingJourneyVeranda), findsOneWidget);
            }
          }
          await tap('onboarding-v3-hanok-growth');
          for (final building in ['house', 'gate']) {
            await tap('onboarding-v3-hanok-$building');
            for (var stage = 0; stage < 2; stage++) {
              await tap('onboarding-v3-growth-$stage');
              expect(
                tester
                    .getSize(
                      find.byKey(
                        ValueKey(
                          'onboarding-v3-growth-art-${building == 'gate'}-$stage',
                        ),
                      ),
                    )
                    .height,
                greaterThan(60),
              );
            }
          }
          await tap('onboarding-v3-hanok-places');
          expect(find.text(t.onboardingJourneyRoom), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          expect({
            for (final key in prefs.getKeys()) key: prefs.get(key),
          }, before);
        },
      );
    }
  }
}
