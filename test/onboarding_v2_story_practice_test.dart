import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
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
      '$locale recognition retries, requires separate unwrap, awards nothing at 200%',
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
        final unwrap = find.byKey(const ValueKey('onboarding-v2-unwrap-gift'));
        expect(tester.widget<SoriButton>(unwrap).onTap, isNull);
        for (final syllable in ['가', '나', '다']) {
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
        await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-나')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('onboarding-v2-answer-retry')),
          findsOneWidget,
        );
        expect(tester.widget<SoriButton>(unwrap).onTap, isNull);
        await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-가')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('onboarding-v2-answer-correct')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-false')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-true')),
          findsNothing,
        );
        await tester.ensureVisible(unwrap);
        await tester.tap(unwrap);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('onboarding-v2-gift-true')),
          findsOneWidget,
        );
        expect(tester.widget<SoriButton>(unwrap).onTap, isNull);
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('gift unwrap stages anticipation, opening and gift burst once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host('en', const OnboardingRewardPractice(character: SizedBox.shrink())),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-가')));
    await tester.pump();
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
      await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-가')));
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
    'jamo composition plays canonical 가 at the same action and recovers from failure',
    (tester) async {
      final speech = stubSoriSpeech();
      await tester.pumpWidget(_host('en', const OnboardingJamoPractice()));
      final action = find.byKey(const ValueKey('onboarding-v2-jamo-action'));
      final initialRect = tester.getRect(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('ㄱ + ㅏ → 가'), findsOneWidget);
      expect(speech.spoken, isEmpty);
      expect(tester.getRect(action).top, initialRect.top);
      SoriSpeech.speakImpl = (text, voice) async {
        expect(text, '가');
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
      await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-answer-가')));
    await tester.pump();
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
      final answer = find.byKey(const ValueKey('onboarding-v2-answer-가'));
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
        tester
            .widget<SoriButton>(
              find.byKey(const ValueKey('onboarding-v2-unwrap-gift')),
            )
            .onTap,
        isNull,
      );
    },
  );

  for (final locale in ['de', 'en']) {
    testWidgets(
      '$locale gate preview opens real image, closes and preserves page scroll at 200%',
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
        final scrollable = find
            .ancestor(of: preview, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final offset = position.pixels;
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
        expect(position.pixels, offset);
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
