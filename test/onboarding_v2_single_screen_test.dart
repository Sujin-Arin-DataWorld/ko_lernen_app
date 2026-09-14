import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'support/real_fonts.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() {
    stubSoriSpeech();
    TigerStageVideo.videoReady = false;
  });
  for (final size in const [
    Size(320, 640),
    Size(360, 640),
    Size(390, 844),
    Size(720, 1152),
    Size(1152, 720),
  ]) {
    for (final language in ['de', 'en']) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          '$language $size text $scale keeps every main step on one screen',
          (tester) async {
            tester.view.devicePixelRatio = 2.5;
            tester.view.physicalSize = Size(
              size.width * 2.5,
              size.height * 2.5,
            );
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final copy = onboardingV2Copy(lookupAppL10n(Locale(language)));
            final screens = <Widget>[
              for (var index = 0; index < 5; index++)
                OnboardingStoryScreen(
                  key: ValueKey(index),
                  copy: copy,
                  pageIndex: index,
                  onContinue: (_) {},
                  onPrevious: (_) {},
                ),
              OnboardingSetupScreen(
                key: const ValueKey('purpose'),
                copy: copy,
                selectedPurposeId: null,
                selectedLevelCode: null,
                onPurposeChanged: (_) {},
                onLevelChanged: (_) {},
                onContinue: (_) {},
              ),
              OnboardingSetupScreen(
                key: const ValueKey('level'),
                copy: copy,
                selectedPurposeId: OnboardingV2Ids.purposeLifeTravel,
                selectedLevelCode: 'C2',
                onPurposeChanged: (_) {},
                onLevelChanged: (_) {},
                onContinue: (_) {},
              ),
              OnboardingCompanionScreen(
                copy: copy,
                selectedCompanionId: 'joy',
                onCompanionChanged: (_) {},
                onContinue: (_) {},
              ),
              OnboardingCompanionConfirmationScreen(
                copy: copy,
                companionId: 'joy',
                onStart: () {},
                onChange: () {},
                previewBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ];
            for (var index = 0; index < screens.length; index++) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: AppTheme.light,
                  locale: Locale(language),
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
                  home: screens[index],
                ),
              );
              await tester.pumpAndSettle();
              final evidence = '$language $size scale=$scale screen=$index';
              _expectScreenFits(tester, size, evidence);
              if (screens[index] is OnboardingCompanionScreen) {
                for (final name in ['Taego', 'Joy']) {
                  final paragraph = tester.renderObject<RenderParagraph>(
                    find.descendant(
                      of: find.text(name),
                      matching: find.byType(RichText),
                    ),
                  );
                  expect(
                    paragraph.getBoxesForSelection(
                      TextSelection(baseOffset: 0, extentOffset: name.length),
                    ),
                    hasLength(1),
                    reason: '$evidence: keep $name on one line',
                  );
                }
              }
            }
          },
        );
      }
    }
  }
}

void _expectScreenFits(WidgetTester tester, Size size, String evidence) {
  expect(tester.takeException(), isNull, reason: evidence);
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    expect(s.position.maxScrollExtent, 0, reason: evidence);
  }
  for (final button in find.byType(SoriButton).evaluate()) {
    final rect = tester.getRect(find.byWidget(button.widget));
    expect(rect.width, greaterThanOrEqualTo(48), reason: evidence);
    expect(rect.height, greaterThanOrEqualTo(48), reason: evidence);
    _expectInside(rect, size, evidence);
  }
  for (final button
      in find
          .byWidgetPredicate(
            (widget) => widget is IconButton || widget is TextButton,
          )
          .evaluate()) {
    final rect = tester.getRect(find.byWidget(button.widget));
    expect(rect.width, greaterThanOrEqualTo(48), reason: evidence);
    expect(rect.height, greaterThanOrEqualTo(48), reason: evidence);
    _expectInside(rect, size, evidence);
  }
  for (final paragraph in find.byType(RichText).evaluate()) {
    _expectInside(
      tester.getRect(find.byWidget(paragraph.widget)),
      size,
      evidence,
    );
  }
}

void _expectInside(Rect rect, Size size, String evidence) {
  expect(rect.left, greaterThanOrEqualTo(-.1), reason: evidence);
  expect(rect.right, lessThanOrEqualTo(size.width + .1), reason: evidence);
  expect(rect.top, greaterThanOrEqualTo(44 - .1), reason: evidence);
  expect(
    rect.bottom,
    lessThanOrEqualTo(size.height - 34 + .1),
    reason: evidence,
  );
}
