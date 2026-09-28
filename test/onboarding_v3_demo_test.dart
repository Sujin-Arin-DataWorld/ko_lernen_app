import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_games_demo.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_learning_demo.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v3_demo_support.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'kl_xp': 42, 'kl_level': 'b1'}),
  );

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    String lang = 'de',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 640),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 112),
                  Expanded(child: child),
                  const SizedBox(height: 112),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'new learners trace four letters, replay strokes and hear a word without persistence',
    (tester) async {
      final speech = stubSoriSpeech();
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      await show(
        tester,
        const OnboardingLearningDemo(level: LearnerLevel.a1, beginner: true),
      );
      expect(find.byType(TraceCanvas), findsOneWidget);
      final canvas = tester.widget<TraceCanvas>(find.byType(TraceCanvas));
      await tester.drag(find.byType(TraceCanvas), const Offset(45, 35));
      await tester.pump();
      expect(canvas.controller.snapshot.strokes, isNotEmpty);
      await tester.tap(find.byKey(const ValueKey('demo-stroke-order')));
      await tester.pumpAndSettle();
      expect(canvas.controller.snapshot.strokes, isEmpty);
      await tester.tap(find.byKey(const ValueKey('demo-letter-3')));
      await tester.pump();
      expect(find.text('ㅗ → 오 · 오리'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('demo-word-audio')));
      await tester.pumpAndSettle();
      expect(speech.spoken, contains('오리'));
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(find.byKey(ValueKey('demo-letter-$i'))).height,
          greaterThanOrEqualTo(48),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(speech.stops, greaterThan(0));
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  testWidgets(
    'A1 course speaking hides model on own turn, reading and writing differ',
    (tester) async {
      stubSoriSpeech();
      await show(
        tester,
        const OnboardingLearningDemo(level: LearnerLevel.a1),
        lang: 'en',
      );
      expect(find.byType(TraceCanvas), findsNothing);
      expect(find.text('저는 학생이에요.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('demo-skill-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('demo-own-turn')));
      await tester.pump();
      expect(find.text('저는 학생이에요.'), findsNothing);
      expect(find.byKey(const ValueKey('demo-speaking-model')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('demo-speaking-model')));
      await tester.pump();
      expect(find.text('저는 학생이에요.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('demo-skill-2')));
      await tester.pump();
      expect(find.byKey(const ValueKey('demo-own-turn')), findsNothing);
      expect(find.byKey(const ValueKey('demo-course-audio')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('demo-skill-3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('demo-word-0')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('demo-assembled'))).data,
        '저는',
      );
    },
  );

  testWidgets('conversation preserves separate partner and own reply bubbles', (
    tester,
  ) async {
    stubSoriSpeech();
    await show(tester, const OnboardingLearningDemo(level: LearnerLevel.a1));
    await tester.tap(find.byKey(const ValueKey('demo-area-2')));
    await tester.pump();
    expect(find.byKey(const ValueKey('demo-partner-bubble')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-reply-bubble')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('demo-show-reply')));
    await tester.pump();
    expect(find.text('네, 여기 있어요.'), findsOneWidget);
    expect(find.text('안녕하세요. 여권 주세요.'), findsOneWidget);
  });

  testWidgets('all six boards respond locally and reset when unmounted', (
    tester,
  ) async {
    stubSoriSpeech();
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    await show(tester, const OnboardingGamesDemo(level: LearnerLevel.a1));
    Future<void> selectGame(int game) async {
      final back = find.byKey(const ValueKey('demo-games-back'));
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await tester.pumpAndSettle();
      }
      final choice = find.byKey(ValueKey('demo-game-$game'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
    }

    await selectGame(0);
    expect(find.byKey(const ValueKey('demo-choice-안녕')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-choice-아니요')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-choice-이름')), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-more-choices')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('demo-choice-안녕')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('demo-initial-answer')).evaluate().isNotEmpty ||
          tester
              .widgetList<DemoPagedText>(find.byType(DemoPagedText))
              .any((widget) => widget.text == '안녕'),
      isTrue,
    );
    await selectGame(1);
    await tester.tap(find.byKey(const ValueKey('demo-cross-cell-1')));
    await tester.tap(find.byKey(const ValueKey('demo-choice-제')));
    await tester.pump();
    expect(
      tester
          .widget<DemoChoice>(find.byKey(const ValueKey('demo-cross-cell-1')))
          .label,
      '제',
    );
    await selectGame(2);
    await tester.tap(find.byKey(const ValueKey('demo-choice-이름')));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('demo-cloze-sentence')))
          .data,
      contains('이름'),
    );
    await selectGame(3);
    await tester.tap(find.byKey(const ValueKey('demo-pair-ko-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('demo-pair-meaning-0')));
    await tester.pump();
    expect(
      tester
          .widget<DemoChoice>(find.byKey(const ValueKey('demo-pair-ko-0')))
          .label,
      contains('↔'),
    );
    await selectGame(4);
    await tester.tap(find.byKey(const ValueKey('demo-word-0')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('demo-assembled'))).data,
      '저는',
    );
    await selectGame(5);
    await tester.tap(find.byKey(const ValueKey('demo-chain-next')));
    await tester.pump();
    expect(find.text('과자'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    await show(tester, const OnboardingGamesDemo(level: LearnerLevel.a1));
    expect(find.byKey(const ValueKey('demo-initial-answer')), findsNothing);
  });

  testWidgets(
    'compact sentence toolbar offers working reset without a no-op example',
    (tester) async {
      stubSoriSpeech();
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      for (final lang in ['de', 'en']) {
        await show(
          tester,
          OnboardingGamesDemo(key: ValueKey(lang), level: LearnerLevel.a1),
          lang: lang,
          scale: 2,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('demo-game-4')));
        await tester.tap(find.byKey(const ValueKey('demo-game-4')));
        await tester.pump();
        expect(find.byKey(const ValueKey('demo-game-example')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('demo-word-1')));
        await tester.pump();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('demo-assembled')))
              .data,
          '학생이에요.',
        );
        await tester.tap(find.byKey(const ValueKey('demo-game-reset')));
        await tester.pump();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('demo-assembled')))
              .data,
          '···',
        );
        await tester.tap(find.byKey(const ValueKey('demo-games-back')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('demo-game-0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('demo-game-example')));
        await tester.pump();
        expect(find.text('안녕'), findsWidgets);
        expect(tester.takeException(), isNull);
      }
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  for (final lang in ['de', 'en']) {
    testWidgets('$lang 320dp at 200% keeps game names on whole lines', (
      tester,
    ) async {
      stubSoriSpeech();
      await show(
        tester,
        OnboardingGamesDemo(key: ValueKey(lang), level: LearnerLevel.a1),
        lang: lang,
        scale: 2,
      );
      for (var game = 0; game < 6; game++) {
        final choice = find.byKey(ValueKey('demo-game-$game'));
        await tester.ensureVisible(choice);
        await tester.pump();
        expect(tester.getSize(choice).width, greaterThan(200));
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        final label = find.descendant(of: choice, matching: find.byType(Text));
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final labelText = tester.widget<Text>(label).data!;
        var offset = 0;
        for (final word in labelText.split(RegExp(r'[\s-]+'))) {
          final start = labelText.indexOf(word, offset);
          expect(
            paragraph.getBoxesForSelection(
              TextSelection(
                baseOffset: start,
                extentOffset: start + word.length,
              ),
            ),
            hasLength(1),
            reason: '$lang game $game must not split $word across lines',
          );
          offset = start + word.length;
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['de', 'en']) {
    testWidgets('$lang all levels and boards fit a bounded 320 x 640 page', (
      tester,
    ) async {
      stubSoriSpeech();
      for (final level in LearnerLevel.values) {
        await show(
          tester,
          OnboardingLearningDemo(key: ValueKey('learn-$level'), level: level),
          lang: lang,
          scale: 1.2,
        );
        for (var skill = 0; skill < 4; skill++) {
          await tester.tap(find.byKey(ValueKey('demo-skill-$skill')));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$level skill $skill');
        }
        for (var area = 1; area < 3; area++) {
          await tester.tap(find.byKey(ValueKey('demo-area-$area')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('demo-show-reply')));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$level area $area');
        }
        await show(
          tester,
          OnboardingGamesDemo(key: ValueKey('play-$level'), level: level),
          lang: lang,
          scale: 1.2,
        );
        for (var game = 0; game < 6; game++) {
          final back = find.byKey(const ValueKey('demo-games-back'));
          if (back.evaluate().isNotEmpty) {
            await tester.tap(back);
            await tester.pumpAndSettle();
          }
          final choice = find.byKey(ValueKey('demo-game-$game'));
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$level game $game');
        }
      }
    });
  }

  for (final lang in ['de', 'en']) {
    testWidgets(
      '$lang actual shell supports all demo interactions at 320 x 640 and 200%',
      (tester) async {
        stubSoriSpeech();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final copy = onboardingV2Copy(lookupAppL10n(Locale(lang)));
        Future<void> page(
          int index,
          LearnerLevel level, {
          bool beginner = false,
        }) async {
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
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: SoriTypeScale(child: child!),
              ),
              home: OnboardingStoryScreen(
                key: ValueKey('$index-$level-$beginner'),
                copy: copy,
                pageIndex: index,
                selectedLevel: level,
                beginner: beginner,
                onContinue: (_) {},
                onPrevious: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang page $index $level',
          );
        }

        Future<void> tap(String key) async {
          if (RegExp(r'^demo-game-[0-5]$').hasMatch(key)) {
            await tester.ensureVisible(find.byKey(ValueKey(key)));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$lang after $key');
        }

        await page(1, LearnerLevel.a1, beginner: true);
        expect(
          tester.getSize(find.byType(TraceCanvas)).height,
          greaterThan(60),
        );
        await tap('demo-stroke-order');
        await tap('demo-letter-mode');
        await tap('demo-word-audio');
        for (final level in LearnerLevel.values) {
          await page(1, level);
          await tap('demo-area-0');
          for (var skill = 0; skill < 4; skill++) {
            await tap('demo-skill-$skill');
            if (skill == 1) {
              await tap('demo-own-turn');
              await tap('demo-speaking-model');
            }
            await tap('demo-learning-back');
          }
          await tap('demo-learning-back');
          for (var area = 1; area < 3; area++) {
            await tap('demo-area-$area');
            await tap('demo-show-reply');
            await tap('demo-learning-back');
          }
          await page(2, level);
          for (var game = 0; game < 6; game++) {
            await tap('demo-game-$game');
            if (game == 1) {
              await tap('demo-cross-row');
            }
            await tap('demo-games-back');
          }
        }
      },
    );
  }

  test('copied puzzle solutions and word chains retain source identities', () {
    final data =
        jsonDecode(
              File(
                'assets/data/onboarding_v3_demo_content.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(data['provenance']['source'], 'sites/onboarding-uiux-20260910');
    for (final level in (data['levels'] as Map).values) {
      final cross = level['cross'];
      expect(cross['sourceId'], isNotEmpty);
      expect((cross['solution'] as List).length, cross['rows'] * cross['cols']);
      final chain = level['chain'] as List;
      for (var i = 1; i < chain.length; i++) {
        expect(
          (chain[i - 1]['ko'] as String).characters.last,
          (chain[i]['ko'] as String).characters.first,
        );
      }
    }
  });
}
