import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_onboarding.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/einleitung_capture_assets.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadEinleitungFonts);

  test('native introduction has no mockup crop consumer', () {
    for (final path in [
      'lib/screens/onboarding_v2/c_onboarding.dart',
      'lib/screens/onboarding_v2/c_intro_art.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('assets/illustrations/concept_c/einleitung/')),
      );
    }
  });

  const captureDirectory = String.fromEnvironment('EINLEITUNG_EVIDENCE_DIR');
  for (final configuration in [
    (language: 'de', width: 402.0, height: 934.0, scale: 1.0),
    (language: 'de', width: 402.0, height: 874.0, scale: 1.0),
    (language: 'en', width: 402.0, height: 874.0, scale: 1.0),
    (language: 'de', width: 402.0, height: 934.0, scale: 1.3),
    (language: 'de', width: 320.0, height: 740.0, scale: 2.0),
  ]) {
    for (var page = 1; page <= 7; page++) {
      testWidgets(
        'native C introduction $page ${configuration.language} ${configuration.width} ${configuration.scale}',
        (tester) async {
          stubSoriSpeech();
          final copy = onboardingV2Copy(
            lookupAppL10n(Locale(configuration.language)),
          );
          final Widget screen = switch (page) {
            1 => OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: OnboardingV2Ids.purposeLifeTravel,
              selectedLevelCode: 'A2',
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
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
              selectedLevel: LearnerLevel.a2,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          };
          await _pump(
            tester,
            screen,
            language: configuration.language,
            size: Size(configuration.width, configuration.height),
            textScale: configuration.scale,
          );
          await settleEinleitungCaptureAssets(tester);
          expect(tester.takeException(), isNull);
          final action = find.byKey(
            ValueKey(switch (page) {
              1 => 'onboarding-v2-setup-continue',
              7 => 'onboarding-v2-companion-continue',
              _ => 'onboarding-v2-story-next',
            }),
          );
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          if (captureDirectory.isNotEmpty) {
            await expectLater(
              find.byType(Scaffold),
              matchesGoldenFile(
                Uri.file(
                  '$captureDirectory/intro-${page.toString().padLeft(2, '0')}-${configuration.language}-${configuration.width.toInt()}-${configuration.height.toInt()}-${configuration.scale.toString().replaceFirst(RegExp(r'\.0$'), '')}x.png',
                ),
              ),
            );
            if (page == 1 &&
                configuration.height == 934 &&
                configuration.scale == 1) {
              await tester.tap(
                find.byKey(const ValueKey('c-onboarding-change-level')),
              );
              await tester.pumpAndSettle();
              await settleEinleitungCaptureAssets(tester);
              expect(tester.takeException(), isNull);
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile(
                  Uri.file('$captureDirectory/intro-level-de-402-934-1x.png'),
                ),
              );
            }
          }
        },
      );
    }
  }

  testWidgets('German sound heading retains every line at 130% text size', (
    tester,
  ) async {
    stubSoriSpeech();
    final t = lookupAppL10n(const Locale('de'));
    await _pump(
      tester,
      OnboardingStoryScreen(
        copy: onboardingV2Copy(t),
        pageIndex: 1,
        selectedLevel: LearnerLevel.a2,
        onContinue: (_) {},
        onPrevious: (_) {},
      ),
      size: const Size(402, 934),
      textScale: 1.3,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(t.onboardingCSoundTitle),
    );
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      strutStyle: paragraph.strutStyle,
      textHeightBehavior: paragraph.textHeightBehavior,
      textWidthBasis: paragraph.textWidthBasis,
    )..layout(maxWidth: paragraph.size.width);
    expect(natural.computeLineMetrics().length, greaterThanOrEqualTo(2));
    expect(paragraph.size.height, greaterThanOrEqualTo(natural.height - .01));
    natural.dispose();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['de', 'en']) {
    testWidgets(
      '$language level picker stays compact and returns stable selection',
      (tester) async {
        stubSoriSpeech();
        String? selected;
        String? purpose;
        OnboardingSetupSelection? submitted;
        final copy = onboardingV2Copy(lookupAppL10n(Locale(language)));
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: purpose,
              selectedLevelCode: selected,
              onLevelChanged: (value) => setState(() => selected = value),
              onPurposeChanged: (value) => setState(() => purpose = value),
              onContinue: (value) => submitted = value,
            ),
          ),
          language: language,
        );
        expect(
          _mainAction(tester, 'onboarding-v2-setup-continue').onTap,
          isNull,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-level-C2')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('c-onboarding-change-level')),
        );
        await tester.pumpAndSettle();
        await _tap(tester, 'onboarding-v2-level-C2');
        expect(
          selected,
          isNull,
          reason: 'A draft must not be saved before Apply.',
        );
        await _tap(tester, 'intro-level-apply');
        expect(selected, 'C2');
        expect(
          find.byKey(const ValueKey('onboarding-v2-level-C2')),
          findsNothing,
        );
        await _tap(
          tester,
          'onboarding-purpose-${OnboardingV2Ids.purposeLifeTravel}',
        );
        expect(purpose, OnboardingV2Ids.purposeLifeTravel);
        await _tap(tester, 'onboarding-v2-setup-continue');
        expect(submitted?.levelCode, 'C2');
        expect(submitted?.purposeId, OnboardingV2Ids.purposeLifeTravel);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('closing level picker discards its unsaved draft', (
    tester,
  ) async {
    String selected = 'A2';
    final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
    await _pump(
      tester,
      OnboardingSetupScreen(
        copy: copy,
        selectedPurposeId: null,
        selectedLevelCode: selected,
        onLevelChanged: (value) => selected = value,
        onPurposeChanged: (_) {},
        onContinue: (_) {},
      ),
    );
    await _tap(tester, 'c-onboarding-change-level');
    await _tap(tester, 'onboarding-v2-level-C1');
    await _tap(tester, 'c-onboarding-sheet-close');
    expect(selected, 'A2');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'first-time choice sends A1 through the existing beginner callback',
    (tester) async {
      stubSoriSpeech();
      var beginner = false;
      String? level;
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => OnboardingSetupScreen(
            copy: copy,
            selectedPurposeId: null,
            selectedLevelCode: level,
            beginnerSelected: beginner,
            onBeginnerSelected: () => setState(() {
              beginner = true;
              level = 'A1';
            }),
            onLevelChanged: (_) =>
                fail('Beginner intent must use its own callback.'),
            onPurposeChanged: (_) {},
            onContinue: (_) {},
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('c-onboarding-change-level')));
      await tester.pumpAndSettle();
      await _tap(tester, 'onboarding-v3-new');
      expect(beginner, isFalse);
      await _tap(tester, 'intro-level-apply');
      expect(beginner, isTrue);
      expect(level, 'A1');
      expect(
        _mainAction(tester, 'onboarding-v2-setup-continue').onTap,
        isNotNull,
      );
    },
  );

  testWidgets(
    'five preview sheets keep story IDs and do not write XP or money',
    (tester) async {
      stubSoriSpeech();
      SharedPreferences.setMockInitialValues({'kl_xp': 42, 'kl_level': 'c2'});
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
      for (var index = 0; index < 5; index++) {
        String? next;
        String? previous;
        await _pump(
          tester,
          OnboardingStoryScreen(
            key: ValueKey(index),
            copy: copy,
            pageIndex: index,
            selectedLevel: LearnerLevel.c2,
            onContinue: (id) => next = id,
            onPrevious: (id) => previous = id,
          ),
        );
        await _tap(
          tester,
          index == 2
              ? 'c-onboarding-games-preview-button'
              : 'c-onboarding-preview-${index + 2}',
        );
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'preview ${index + 2}');
        await tester.tap(find.text(lookupAppL10n(const Locale('de')).btnClose));
        await tester.pumpAndSettle();
        await _tap(tester, 'onboarding-v2-story-next');
        await _tap(tester, 'onboarding-v2-story-back');
        expect(next, COnboardingStory.ids[index]);
        expect(previous, COnboardingStory.ids[index]);
        expect(tester.takeException(), isNull);
      }
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  testWidgets('original sound CTA speaks ga and cancels safely on leaving', (
    tester,
  ) async {
    final speech = stubSoriSpeech(completeSpeak: false);
    final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
    await _pump(
      tester,
      OnboardingStoryScreen(
        copy: copy,
        pageIndex: 1,
        onContinue: (_) {},
        onPrevious: (_) {},
      ),
    );
    await _tap(tester, 'c-onboarding-original-listen');
    expect(speech.spoken, ['가']);
    expect(
      tester
          .widget<IntroAction>(
            find.byKey(const ValueKey('c-onboarding-original-listen')),
          )
          .selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(speech.stops, greaterThan(0));
    speech.speakCompleter!.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'companion focus and selection remain visible to assistive technology',
    (tester) async {
      stubSoriSpeech();
      final semantics = tester.ensureSemantics();
      String? selection;
      String? submitted;
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => OnboardingCompanionScreen(
            copy: copy,
            selectedCompanionId: selection,
            onCompanionChanged: (id) => setState(() => selection = id),
            onContinue: (id) => submitted = id,
          ),
        ),
      );
      final joy = find.byKey(const ValueKey('onboarding-v2-companion-joy'));
      await tester.ensureVisible(joy);
      await tester.pumpAndSettle();
      final focusContext = tester.element(
        find.descendant(of: joy, matching: find.byType(MouseRegion)).first,
      );
      Focus.of(focusContext).requestFocus();
      await tester.pumpAndSettle();
      expect(Focus.of(focusContext).hasFocus, isTrue);
      final data = tester
          .getSemantics(
            find.byKey(const ValueKey('onboarding-v2-companion-semantics-joy')),
          )
          .getSemanticsData();
      expect(data.flagsCollection.isFocused, isNot(Tristate.none));
      expect(data.flagsCollection.isFocused, Tristate.isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selection, 'joy');
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey('onboarding-v2-companion-semantics-joy'),
              ),
            )
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await _tap(tester, 'onboarding-v2-companion-continue');
      expect(submitted, 'joy');
      semantics.dispose();
    },
  );
}

IntroAction _mainAction(WidgetTester tester, String key) =>
    tester.widget<IntroAction>(find.byKey(ValueKey(key)));

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  String language = 'de',
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
