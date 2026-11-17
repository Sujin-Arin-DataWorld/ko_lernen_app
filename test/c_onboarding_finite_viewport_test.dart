import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_onboarding.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_games_demo.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';
import 'support/sori_stage_pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });
  setUp(stubSoriSpeech);

  for (final configuration in [
    (size: const Size(320, 640), language: 'de'),
    (size: const Size(360, 740), language: 'de'),
    (size: const Size(393, 873), language: 'de'),
    (size: const Size(402, 934), language: 'de'),
    (size: const Size(800, 1180), language: 'de'),
    (size: const Size(320, 640), language: 'en'),
  ]) {
    for (var page = 1; page <= 7; page++) {
      testWidgets(
        '100% page $page ${configuration.language} ${configuration.size} stays inside the safe viewport',
        (tester) async {
          final copy = onboardingV2Copy(
            lookupAppL10n(Locale(configuration.language)),
          );
          final screen = switch (page) {
            1 => OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: OnboardingV2Ids.purposeLifeTravel,
              selectedLevelCode: 'A1',
              beginnerSelected: true,
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
              onBack: () {},
            ),
            7 => OnboardingCompanionScreen(
              copy: copy,
              selectedCompanionId: OnboardingV2Ids.companionTaego,
              onCompanionChanged: (_) {},
              onContinue: (_) {},
              onBack: () {},
            ),
            _ => OnboardingStoryScreen(
              copy: copy,
              pageIndex: page - 2,
              selectedLevel: LearnerLevel.a1,
              beginner: true,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          };
          await _show(
            tester,
            screen,
            size: configuration.size,
            language: configuration.language,
          );
          expect(tester.takeException(), isNull);
          expect(
            find.descendant(
              of: find.byType(COnboardingFrame),
              matching: find.byType(Scrollable),
            ),
            findsNothing,
          );
          final safeViewport = Rect.fromLTWH(
            0,
            24,
            configuration.size.width,
            configuration.size.height - 48,
          );
          final cta = find.byKey(
            ValueKey(switch (page) {
              1 => 'onboarding-v2-setup-continue',
              7 => 'onboarding-v2-companion-continue',
              _ => 'onboarding-v2-story-next',
            }),
          );
          _expectVisibleControl(tester, cta, safeViewport);
          final back = find.byKey(
            ValueKey(switch (page) {
              1 => 'onboarding-v2-setup-back',
              7 => 'onboarding-v2-companion-back',
              _ => 'onboarding-v2-story-back',
            }),
          );
          _expectVisibleControl(tester, back, safeViewport);
          if (page == 1) {
            _expectVisibleControl(
              tester,
              find.byKey(const ValueKey('c-onboarding-change-level')),
              safeViewport,
            );
            for (final purpose in copy.setup.purposes) {
              _expectVisibleControl(
                tester,
                find.byKey(ValueKey('onboarding-purpose-${purpose.id}')),
                safeViewport,
              );
            }
            for (final name in [
              'interest-travel',
              'interest-culture',
              'interest-study',
              'interest-kcontent',
            ]) {
              final art = find.byWidgetPredicate(
                (widget) => widget is CIntroArt && widget.name == name,
              );
              expect(
                tester.getSize(art).height,
                greaterThanOrEqualTo(40),
                reason: '$name needs visible picture space',
              );
              expect(tester.widget<CIntroArt>(art).fit, BoxFit.contain);
            }
            final title = lookupAppL10n(
              Locale(configuration.language),
            ).onboardingJourneyStartTitle;
            final titleFinder = find.descendant(
              of: find.text(title),
              matching: find.byType(RichText),
            );
            final titleParagraph = tester.renderObject<RenderParagraph>(
              titleFinder,
            );
            final paper = tester.getRect(
              find.byKey(const ValueKey('c-onboarding-paper-surface')),
            );
            expect(
              tester.getRect(titleFinder).bottom,
              lessThanOrEqualTo(paper.top),
            );
            if (configuration.size.width == 320 &&
                configuration.size.height == 640) {
              final painter = TextPainter(
                text: titleParagraph.text,
                textDirection: titleParagraph.textDirection,
                textScaler: titleParagraph.textScaler,
              )..layout(maxWidth: titleParagraph.size.width);
              expect(painter.computeLineMetrics().length, 2);
              expect(
                titleParagraph.size.height,
                greaterThanOrEqualTo(painter.height - .01),
              );
              painter.dispose();
            }
          } else if (page == 7) {
            for (final companion in copy.companion.companions) {
              _expectVisibleControl(
                tester,
                find.byKey(ValueKey('onboarding-v2-companion-${companion.id}')),
                safeViewport,
              );
            }
            final t = lookupAppL10n(Locale(configuration.language));
            for (final value in [
              t.onboardingCTaegoRole,
              t.onboardingCJoyRole,
              t.onboardingCGyeBody,
            ]) {
              final paragraphFinder = find.descendant(
                of: find.text(value),
                matching: find.byType(RichText),
              );
              final paragraph = tester.renderObject<RenderParagraph>(
                paragraphFinder,
              );
              final actualSize =
                  paragraph.text.style!.fontSize! *
                  paragraph.getTransformTo(null).getMaxScaleOnAxis();
              expect(actualSize, greaterThanOrEqualTo(16 - .01), reason: value);
              final rect = tester.getRect(paragraphFinder);
              expect(
                safeViewport.contains(rect.topLeft),
                isTrue,
                reason: value,
              );
              expect(
                safeViewport.contains(
                  rect.bottomRight - const Offset(.01, .01),
                ),
                isTrue,
                reason: value,
              );
            }
          } else if (page == 3) {
            _expectVisibleControl(
              tester,
              find.byKey(const ValueKey('c-onboarding-original-listen')),
              safeViewport,
            );
          } else if (page == 4) {
            _expectVisibleControl(
              tester,
              find.byKey(const ValueKey('c-onboarding-games-preview-button')),
              safeViewport,
            );
          }
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
          }
        },
      );
    }
  }

  testWidgets(
    'short viewport companion A/B/A preserves both portrait and CTA bounds',
    (tester) async {
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
      var selected = OnboardingV2Ids.companionTaego;
      await _show(
        tester,
        StatefulBuilder(
          builder: (context, update) => OnboardingCompanionScreen(
            copy: copy,
            selectedCompanionId: selected,
            onCompanionChanged: (value) => update(() => selected = value),
            onContinue: (_) {},
            onBack: () {},
          ),
        ),
      );
      final taego = find.byKey(const ValueKey('onboarding-v2-companion-taego'));
      final joy = find.byKey(const ValueKey('onboarding-v2-companion-joy'));
      final cta = find.byKey(
        const ValueKey('onboarding-v2-companion-continue'),
      );
      final initial = [
        tester.getRect(taego),
        tester.getRect(joy),
        tester.getRect(cta),
      ];
      for (final target in [taego, joy, taego]) {
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect([
          tester.getRect(taego),
          tester.getRect(joy),
          tester.getRect(cta),
        ], initial);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'the games introduction opens its preview as a full screen route',
    (tester) async {
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
      await _show(
        tester,
        OnboardingStoryScreen(
          copy: copy,
          pageIndex: 2,
          selectedLevel: LearnerLevel.a1,
          onContinue: (_) {},
          onPrevious: (_) {},
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('c-onboarding-games-preview-button')),
      );
      await pumpSoriStage(tester);
      expect(
        tester
            .widget<OnboardingGamesDemo>(find.byType(OnboardingGamesDemo))
            .fullScreen,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('c-onboarding-sheet-close')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(320, 640),
  String language = 'de',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.symmetric(vertical: 24),
          viewPadding: const EdgeInsets.symmetric(vertical: 24),
          textScaler: TextScaler.linear(1),
        ),
        child: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectVisibleControl(WidgetTester tester, Finder finder, Rect viewport) {
  expect(finder.hitTestable(), findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThanOrEqualTo(48));
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(
    viewport.contains(rect.topLeft),
    isTrue,
    reason: '$finder starts outside SafeArea: $rect',
  );
  expect(
    viewport.contains(rect.bottomRight - const Offset(.01, .01)),
    isTrue,
    reason: '$finder ends outside SafeArea: $rect',
  );
}
