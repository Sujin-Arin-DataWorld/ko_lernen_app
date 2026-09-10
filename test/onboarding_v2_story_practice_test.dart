import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_hanok_growth_preview.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_practice.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() => SharedPreferences.setMockInitialValues({'existing_xp': 42}));

  for (final locale in ['de', 'en']) {
    testWidgets(
      '$locale keeps 문, Hanok growth, gift discovery, and unwrap in order at 200%',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        await tester.pumpWidget(
          _host(
            locale,
            const OnboardingRewardPractice(character: SizedBox.shrink()),
          ),
        );
        final discover = find.byKey(
          const ValueKey('onboarding-v2-discover-gift'),
        );
        expect(discover, findsNothing);
        expect(
          find.byKey(const ValueKey('onboarding-v2-hanok-growth-before')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-action')),
          findsNothing,
        );
        for (final syllable in ['문', '눈', '물']) {
          final answer = find.byKey(ValueKey('onboarding-v2-answer-$syllable'));
          expect(tester.getSize(answer).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(answer).width, greaterThanOrEqualTo(48));
          expect(
            tester
                .getSemantics(answer)
                .getSemanticsData()
                .flagsCollection
                .isButton,
            isTrue,
          );
        }
        await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-눈')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('onboarding-v2-answer-retry')),
          findsOneWidget,
        );
        expect(discover, findsNothing);
        await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-문')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('onboarding-v2-answer-correct')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-hanok-growth-after')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-action')),
          findsNothing,
        );
        expect(discover, findsOneWidget);
        expect(tester.widget<SoriButton>(discover).onTap, isNull);
        await tester.pump(const Duration(milliseconds: 420));
        expect(tester.widget<SoriButton>(discover).onTap, isNotNull);
        await tester.tap(discover);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('onboarding-v2-hanok-growth-after')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-false')),
          findsOneWidget,
        );
        final unwrap = find.byKey(const ValueKey('onboarding-v2-unwrap-gift'));
        await tester.ensureVisible(unwrap);
        await tester.tap(unwrap);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-true')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-replay-demo')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('onboarding-v2-replay-demo')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('onboarding-v2-hanok-growth-before')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-answer-문')),
          findsOneWidget,
        );
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  for (final (locale, meaning) in const [('de', 'Tür'), ('en', 'door')]) {
    testWidgets('$locale review keeps 문 paired with $meaning', (tester) async {
      final speech = stubSoriSpeech();
      await tester.pumpWidget(
        _host(
          locale,
          Builder(
            builder: (context) => OnboardingStoryScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              pageIndex: 2,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          ),
          scrollable: false,
        ),
      );
      expect(find.text('문'), findsOneWidget);
      expect(find.text(meaning), findsNothing);
      await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-hero')));
      await tester.pumpAndSettle();
      expect(find.text('문 · $meaning'), findsOneWidget);
      expect(find.text(learnedExample), findsOneWidget);
      expect(speech.spoken, ['문']);
      await tester.tap(
        find.byKey(const ValueKey('onboarding-v3-example-audio')),
      );
      await tester.pump();
      expect(speech.spoken.last, learnedExample);
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-card-audio')));
      await tester.pump();
      expect(speech.spokenSlow, [learnedExample]);
    });
  }

  testWidgets(
    'review audio failure permits retry, flip and onward navigation',
    (tester) async {
      stubSoriSpeech();
      SoriSpeech.speakImpl = (_, _) async => throw StateError('offline');
      var continued = false;
      await tester.pumpWidget(
        _host(
          'en',
          Builder(
            builder: (context) => OnboardingStoryScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              pageIndex: 2,
              onContinue: (_) => continued = true,
              onPrevious: (_) {},
            ),
          ),
          scrollable: false,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-card-flip')));
      await tester.pumpAndSettle();
      expect(find.text(learnedExample), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      var played = false;
      SoriSpeech.speakSlowImpl = (text, _) async {
        expect(text, learnedExample);
        return played = true;
      };
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-card-audio')));
      await tester.pumpAndSettle();
      expect(played, isTrue);
      expect(find.text('Try again'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-next')));
      expect(continued, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review pauses on background and ignores audio completion after leaving',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await tester.pumpWidget(
        _host(
          'en',
          Builder(
            builder: (context) => OnboardingStoryScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              pageIndex: 2,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          ),
          scrollable: false,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-card-flip')));
      await tester.pump();
      final audio = find.byKey(const ValueKey('onboarding-v3-card-audio'));
      expect(tester.widget<TextButton>(audio).onPressed, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(speech.stops, 1);
      expect(tester.widget<TextButton>(audio).onPressed, isNotNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(_host('en', const SizedBox.shrink()));
      speech.speakCompleter!.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Hanok preview preserves the courtyard and V3 building ratios', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        'en',
        const SizedBox(
          width: 500,
          height: 500,
          child: OnboardingHanokGrowthPreview(),
        ),
      ),
    );
    final preview = find.byKey(
      const ValueKey('onboarding-v2-hanok-growth-preview'),
    );
    expect(tester.getSize(preview), const Size(500, 250));
    final images = tester.widgetList<Image>(
      find.descendant(of: preview, matching: find.byType(Image)),
    );
    expect(images.every((image) => image.fit == BoxFit.contain), isTrue);
    expect(images.map((image) => (image.image as AssetImage).assetName), [
      'assets/illustrations/onboarding/ildu_v3_courtyard.png',
      'assets/illustrations/onboarding/ildu_v3_sarangchae.png',
    ]);
  });

  testWidgets('gift unwrap stages anticipation, opening and gift burst once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host('en', const OnboardingRewardPractice(character: SizedBox.shrink())),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-문')));
    await tester.pump(const Duration(milliseconds: 420));
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-discover-gift')));
    await tester.pumpAndSettle();
    final parcel = find.byKey(const ValueKey('onboarding-v2-gift-action'));
    await tester.ensureVisible(parcel);
    await tester.tap(parcel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final anticipation = tester.widget<Transform>(
      find.byKey(const ValueKey('onboarding-v2-gift-anticipation')),
    );
    expect(anticipation.transform.entry(1, 1), lessThan(1));
    expect(find.byKey(const ValueKey('onboarding-v2-gift-pop')), findsNothing);
    await tester.pump(const Duration(milliseconds: 180));
    final cloth = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(
      cloth,
      containsAll([
        'assets/illustrations/reward/reward_bojagi_closed.png',
        'assets/illustrations/reward/reward_bojagi_open.png',
      ]),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('onboarding-v2-gift-pop')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-v2-gift-sparks')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SoriButton>(
            find.byKey(const ValueKey('onboarding-v2-unwrap-gift')),
          )
          .onTap,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-v2-gift-anticipation')),
      findsNothing,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'reduced motion shows the final open gift without running animation',
    (tester) async {
      await tester.pumpWidget(
        _host(
          'en',
          const OnboardingRewardPractice(character: SizedBox.shrink()),
          reduceMotion: true,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-문')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('onboarding-v2-discover-gift')),
      );
      await tester.pumpAndSettle();
      final parcel = find.byKey(const ValueKey('onboarding-v2-gift-action'));
      await tester.ensureVisible(parcel);
      await tester.tap(parcel);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-v2-gift-anticipation')),
        findsNothing,
      );
      final pop = tester.widget<Transform>(
        find.byKey(const ValueKey('onboarding-v2-gift-pop')),
      );
      expect(pop.transform.entry(0, 0), 1);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'jamo composition plays canonical 문 at the same action and recovers from failure',
    (tester) async {
      final speech = stubSoriSpeech();
      await tester.pumpWidget(_host('en', const OnboardingJamoPractice()));
      final action = find.byKey(const ValueKey('onboarding-v2-jamo-action'));
      final initialRect = tester.getRect(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('ㅁ + ㅜ + ㄴ → 문'), findsOneWidget);
      expect(speech.spoken, ['문']);
      expect(tester.getRect(action).top, initialRect.top);
      SoriSpeech.speakImpl = (text, voice) async {
        expect(text, '문');
        expect(voice, 'female');
        throw StateError('offline');
      };
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.text('Audio is unavailable. Try again or continue.'),
        findsOneWidget,
      );
      expect(tester.widget<SoriButton>(action).onTap, isNotNull);
      var played = false;
      SoriSpeech.speakImpl = (_, _) async => played = true;
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(played, isTrue);
      expect(
        find.text('Audio is unavailable. Try again or continue.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'leaving pending pronunciation stops audio and ignores late completion',
    (tester) async {
      final speech = stubSoriSpeech(completeSpeak: false);
      await tester.pumpWidget(_host('en', const OnboardingJamoPractice()));
      final action = find.byKey(const ValueKey('onboarding-v2-jamo-action'));
      await tester.tap(action);
      await tester.pump();
      expect(tester.widget<SoriButton>(action).onTap, isNull);
      await tester.pumpWidget(_host('en', const SizedBox.shrink()));
      await tester.pump();
      expect(speech.stops, 1);
      speech.speakCompleter!.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving while the gift opens disposes its animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host('en', const OnboardingRewardPractice(character: SizedBox.shrink())),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-문')));
    await tester.pump(const Duration(milliseconds: 420));
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-discover-gift')));
    await tester.pumpAndSettle();
    final parcel = find.byKey(const ValueKey('onboarding-v2-gift-action'));
    await tester.ensureVisible(parcel);
    await tester.tap(parcel);
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpWidget(_host('en', const SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving the recognition page resets the demonstration and always permits next',
    (tester) async {
      var page = 3;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          'en',
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return OnboardingStoryScreen(
                copy: onboardingV2Copy(AppL10n.of(context)),
                pageIndex: page,
                onContinue: (_) => setState(() => page = 4),
                onPrevious: (_) {},
              );
            },
          ),
          scrollable: false,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-next')));
      await tester.pumpAndSettle();
      expect(page, 4);
      update(() => page = 3);
      await tester.pumpAndSettle();
      final answer = find.byKey(const ValueKey('onboarding-v2-answer-문'));
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-v2-answer-correct')),
        findsOneWidget,
      );
      update(() => page = 4);
      await tester.pumpAndSettle();
      update(() => page = 3);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-v2-answer-correct')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('onboarding-v2-discover-gift')),
        findsNothing,
      );
    },
  );

  for (final locale in ['de', 'en']) {
    testWidgets(
      '$locale gate preview opens and closes without adding primary scroll at 200%',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var continued = false;
        await tester.pumpWidget(
          _host(
            locale,
            Builder(
              builder: (context) => OnboardingStoryScreen(
                copy: onboardingV2Copy(AppL10n.of(context)),
                pageIndex: 4,
                onContinue: (_) => continued = true,
                onPrevious: (_) {},
              ),
            ),
            scrollable: false,
          ),
        );
        final preview = find.byKey(
          const ValueKey('onboarding-v2-gate-preview'),
        );
        await tester.ensureVisible(preview);
        await tester.pumpAndSettle();
        expect(
          find.ancestor(of: preview, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(tester.getSize(preview).height, greaterThanOrEqualTo(48));
        await tester.tap(preview);
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(
          find.byKey(const ValueKey('onboarding-v2-gate-preview-image')),
        );
        expect(
          (image.image as AssetImage).assetName,
          'assets/illustrations/personal_hanok_v3/world/main-gate.png',
        );
        final mapTitle = find.text(
          locale == 'de' ? 'Ildu Gotaek entdecken' : 'Explore Ildu Gotaek',
        );
        await tester.ensureVisible(mapTitle);
        await tester.tap(mapTitle);
        await tester.pumpAndSettle();
        final map = tester.widget<Image>(
          find.byKey(const ValueKey('onboarding-v3-map-preview-image')),
        );
        expect(map.fit, BoxFit.contain);
        expect(
          (map.image as AssetImage).assetName,
          'assets/illustrations/onboarding/ildu_v3_map_preview.png',
        );
        final mapClose = find.text(locale == 'de' ? 'Schließen' : 'Close');
        await tester.ensureVisible(mapClose);
        await tester.tap(mapClose);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('onboarding-v3-map-preview-image')),
          findsNothing,
        );
        final close = find.byKey(
          const ValueKey('onboarding-v2-gate-preview-close'),
        );
        await tester.ensureVisible(close);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('onboarding-v2-gate-preview-image')),
          findsNothing,
        );
        expect(continued, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _host(
  String locale,
  Widget child, {
  bool scrollable = true,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: scrollable
      ? Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        )
      : child,
);
