import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _item = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ＿＿＿ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich aufmerksam in der Bibliothek.',
  en: 'Today I study carefully in the library.',
  distractors: ['운동을', '요리를', '독서를'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('daily keeps one study hierarchy and complete actions in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        _configureView(tester, viewport.size);

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: const DailyChallengeScreen(items: [_item]),
          ),
        );
        await _pumpUntilVisible(tester, find.byType(ClozePromptCard));

        final screen = find.byType(DailyChallengeScreen);
        final context = tester.element(screen);
        final t = AppL10n.of(context);
        final frame = tester.widget<SoriStudyFrame>(
          find.byType(SoriStudyFrame),
        );
        expect(frame.eyebrow, '1 / 1 · ${t.quizScore(0, 1)}');

        final instructionFinder = find.text(t.clozeInstruction);
        final instruction = tester.widget<Text>(instructionFinder);
        final type = SoriTextTheme.of(tester.element(instructionFinder));
        expect(instruction.maxLines, isNull);
        expect(instruction.overflow, isNull);
        expect(instruction.style?.fontSize, type.meta.fontSize);
        expect(instruction.style?.fontWeight, type.meta.fontWeight);

        final closeAction = find.byTooltip(t.btnClose);
        expect(closeAction, findsOneWidget);
        final closeSize = tester.getSize(closeAction);
        expect(closeSize.width, greaterThanOrEqualTo(48));
        expect(closeSize.height, greaterThanOrEqualTo(48));

        final speakAction = find.byKey(const Key('cloze-prompt-speak'));
        expect(speakAction, findsOneWidget);
        final speakSize = tester.getSize(speakAction);
        expect(speakSize.width, greaterThanOrEqualTo(48));
        expect(speakSize.height, greaterThanOrEqualTo(48));

        for (final option in [_item.answer, ..._item.distractors]) {
          final choice = find.widgetWithText(QuizChoice, option);
          expect(choice, findsOneWidget);
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('daily practice mode is a readable semantic state in '
        '${locale.languageCode} at 200% text', (tester) async {
      _configureView(tester, const Size(320, 640));
      await Storage.markDailyChallengeDone(now: DateTime.now());

      await tester.pumpWidget(
        _host(
          locale: locale,
          textScale: 2,
          child: const DailyChallengeScreen(items: [_item]),
        ),
      );
      await _pumpUntilVisible(tester, find.byType(ClozePromptCard));

      final t = AppL10n.of(tester.element(find.byType(DailyChallengeScreen)));
      final note = find.byKey(const Key('daily-practice-note'));
      expect(note, findsOneWidget);
      expect(find.bySemanticsLabel(t.dailyAlreadyDone), findsOneWidget);
      final copy = tester.widget<Text>(
        find.descendant(of: note, matching: find.text(t.dailyAlreadyDone)),
      );
      expect(copy.maxLines, isNull);
      expect(copy.overflow, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty daily data uses the shared empty state', (tester) async {
    _configureView(tester, const Size(390, 844));

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: const DailyChallengeScreen(items: []),
      ),
    );
    await _pumpUntilVisible(tester, find.byType(SoriEmptyState));

    final t = AppL10n.of(tester.element(find.byType(DailyChallengeScreen)));
    expect(find.byType(SoriEmptyState), findsOneWidget);
    expect(find.text(t.clozeEmptyBody), findsOneWidget);
    expect(find.byType(GameOverCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry keeps first-attempt score and first completion bonus', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: const DailyChallengeScreen(items: [_item]),
      ),
    );
    await _pumpUntilVisible(tester, find.byType(ClozePromptCard));
    final t = AppL10n.of(tester.element(find.byType(DailyChallengeScreen)));

    await tester.tap(find.text(_item.distractors.first));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text(_item.answer));
    await tester.pump(const Duration(milliseconds: 1100));
    await _pumpUntilVisible(tester, find.byType(GameOverCard));

    expect(find.text(t.quizScore(0, 1)), findsOneWidget);
    expect(Storage.xp, 20);
    expect(Storage.dailyChallengeDoneToday(), isTrue);
    expect(Storage.dailyChallengeStreak, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice completion cannot grant the daily bonus twice', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await Storage.markDailyChallengeDone(now: DateTime.now());

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: const DailyChallengeScreen(items: [_item]),
      ),
    );
    await _pumpUntilVisible(tester, find.byType(ClozePromptCard));
    final t = AppL10n.of(tester.element(find.byType(DailyChallengeScreen)));

    await tester.tap(find.text(_item.answer));
    await tester.pump(const Duration(milliseconds: 1100));
    await _pumpUntilVisible(tester, find.byType(GameOverCard));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(t.quizScore(1, 1)), findsOneWidget);
    expect(find.text('+5 XP'), findsOneWidget);
    expect(Storage.xp, 5);
    expect(Storage.dailyChallengeStreak, 1);
    expect(find.text(t.dailyStreak(1)), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}
