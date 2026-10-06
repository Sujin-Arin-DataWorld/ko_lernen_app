import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/c_fonts.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadCFonts();
  });

  test('all 46 registered assets keep the approved crop bytes', () {
    final dir = Directory(COnboardingArt.directory);
    final manifest =
        jsonDecode(File('${dir.path}/source-manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final crops = (manifest['records'] as List)
        .cast<Map<String, dynamic>>()
        .where((record) => record['type'] == 'unchanged-source-pixel-crop')
        .toList();
    expect(crops, hasLength(46));
    expect(
      dir.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.png'),
      ),
      hasLength(46),
    );
    for (final record in crops) {
      final name = (record['path'] as String).split('/').last;
      final bytes = File('${dir.path}/$name').readAsBytesSync();
      expect(sha256.convert(bytes).toString(), record['sha256'], reason: name);
      expect(
        (record['pixelVerification'] as Map)['changedPixels'],
        0,
        reason: name,
      );
    }
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- ${COnboardingArt.directory}/'),
    );
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
        await _tap(tester, 'c-onboarding-preview-${index + 2}');
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
          .widget<CImageTap>(
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

CMaterialAction _mainAction(WidgetTester tester, String key) =>
    tester.widget<CMaterialAction>(find.byKey(ValueKey(key)));

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
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
