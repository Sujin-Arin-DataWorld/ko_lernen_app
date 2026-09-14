import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _word = Vocab(
  korean: '하다',
  romanization: 'hada',
  german: 'machen',
  english: 'do',
  level: 'A1',
  posDe: 'Verb',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);
const _puzzle = SilbenPuzzle(
  id: 'recovery',
  rows: 1,
  cols: 2,
  words: [
    SilbenWord(
      dir: 'h',
      row: 0,
      col: 0,
      answer: '가나',
      german: 'Ghana',
      exampleKo: '',
      exampleDe: '',
    ),
  ],
  pool: ['가', '나'],
);
const _chain = [
  KkeunmariWord(
    word: '가나',
    first: '가',
    last: '나',
    level: 'A1',
    german: 'Ghana',
    topic: 'test',
    nextCount: 1,
    isDeadEnd: false,
  ),
  KkeunmariWord(
    word: '나다',
    first: '나',
    last: '다',
    level: 'A1',
    german: 'arise',
    topic: 'test',
    nextCount: 0,
    isDeadEnd: true,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  final t = lookupAppL10n(const Locale('en'));
  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    platform.values.addAll({
      'kl_tut_kkeunmari': true,
      'kl_tut_silben_kreuz': true,
    });
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    SoundService.resetForTesting();
    KkeunmariEngine.reset();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final game in ['hard', 'chain', 'silben']) {
    testWidgets('$game holds completion and retries rejected XP once', (
      tester,
    ) async {
      await _open(tester, game);
      platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
      await _finish(tester, game, t);
      await _until(tester, find.byType(AppError));
      expect(Storage.xp, 0);
      expect(Storage.kkeunmariWins, 0);
      expect(_result(game, t), findsNothing);
      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _until(tester, _result(game, t));
      expect(
        Storage.xp,
        game == 'hard'
            ? 2
            : game == 'chain'
            ? 20
            : 30,
      );
      expect(Storage.kkeunmariWins, game == 'chain' ? 1 : 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final committed in [false, true]) {
      testWidgets('$game retries unknown XP committed=$committed', (
        tester,
      ) async {
        await _open(tester, game);
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await _finish(tester, game, t);
        await _until(tester, find.byType(AppError));
        expect(_result(game, t), findsNothing);
        expect(Storage.xp, 0);
        expect(Storage.kkeunmariWins, 0);
        final writes =
            platform.writes[Storage.listeningRewardLedgerPreferenceKey];
        tester.widget<AppError>(find.byType(AppError)).onRetry!();
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          platform.writes[Storage.listeningRewardLedgerPreferenceKey],
          writes,
        );
        platform
          ..unavailable = false
          ..rejectKey = null;
        tester.widget<AppError>(find.byType(AppError)).onRetry!();
        await _until(tester, _result(game, t));
        expect(
          Storage.xp,
          game == 'hard'
              ? 2
              : game == 'chain'
              ? 20
              : 30,
        );
        expect(Storage.kkeunmariWins, game == 'chain' ? 1 : 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final retirement in ['exit', 'reset']) {
      testWidgets('$game rejects retained input after $retirement', (
        tester,
      ) async {
        await _open(tester, game);
        final frame = tester.widget<SoriStudyFrame>(
          find.byType(SoriStudyFrame),
        );
        expect(frame.onLeave, isNotNull);
        if (retirement == 'reset') {
          await Storage.resetAllStrict();
        } else {
          frame.onLeave!();
        }
        if (game == 'hard') {
          tester
              .widgetList<QuizChoice>(find.byType(QuizChoice))
              .firstWhere((w) => w.isCorrect)
              .onSelected!();
        } else if (game == 'chain') {
          await tester.enterText(find.byType(SoriTextField), '나다');
          tester.widget<SoriTextField>(find.byType(SoriTextField)).onSubmitted!(
            '나다',
          );
        } else {
          await tester.tap(find.bySemanticsLabel('가'));
        }
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        expect(Storage.xp, 0);
        expect(Storage.kkeunmariWins, 0);
        expect(platform.writes['kl_game_best'] ?? 0, 0);
        expect(_result(game, t), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final game in ['chain', 'silben']) {
    testWidgets('$game binds load retry to its error presentation', (
      tester,
    ) async {
      var calls = 0;
      final pendingLoad = Completer<void>();
      addTearDown(() {
        if (!pendingLoad.isCompleted) {
          pendingLoad.complete();
        }
      });
      Future<void> load() async {
        calls++;
        if (calls == 1) {
          throw StateError('Initial load unavailable');
        }
        if (calls == 2) {
          await pendingLoad.future;
        }
      }

      final Widget screen = game == 'chain'
          ? KkeunmariScreen(
              poolLoader: () async {
                await load();
                return _chain;
              },
            )
          : SilbenKreuzScreen(
              puzzleLoader: () async {
                await load();
                return {
                  'A1': [_puzzle, _puzzle],
                };
              },
            );
      await _open(tester, game, screen: screen);
      await _until(tester, find.byType(AppError));
      final oldRetry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      oldRetry();
      oldRetry();
      await tester.pump();
      expect(
        calls,
        2,
        reason: 'Only the failed load may be retried once while pending.',
      );
      pendingLoad.complete();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      oldRetry();
      await tester.pump();
      expect(calls, 2, reason: 'Old load retry must not replace a live round.');
      platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
      await _finish(tester, game, t);
      await _until(tester, find.byType(AppError));
      oldRetry();
      await tester.pump();
      expect(
        calls,
        2,
        reason: 'Old load retry must not erase reward recovery.',
      );
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _until(tester, _result(game, t));
      expect(Storage.xp, game == 'chain' ? 20 : 30);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$game retains XP on best failure and admits replay', (
      tester,
    ) async {
      await _open(tester, game);
      platform.rejectKey = 'kl_game_best';
      await _finish(tester, game, t);
      await _until(tester, find.byType(AppError));
      expect(_result(game, t), findsNothing);
      final expectedXp = game == 'chain' ? 20 : 30;
      expect(Storage.xp, expectedXp);
      expect(Storage.gameBest(game == 'chain' ? 'kkeunmari' : 'skz_a1'), 0);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _until(tester, _result(game, t));
      expect(Storage.xp, expectedXp);
      final next = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .firstWhere(
            (b) =>
                b.label == (game == 'chain' ? t.kkeunmariPlayAgain : t.btnNext),
          )
          .onTap!;
      next();
      next();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await _finish(tester, game, t);
      await _until(tester, _result(game, t));
      expect(Storage.xp, 2 * expectedXp);
      expect(Storage.kkeunmariWins, game == 'chain' ? 2 : 0);
      expect(Storage.gameBest(game == 'chain' ? 'kkeunmari' : 'skz_a1'), 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('chain timeout awards XP without a win', (tester) async {
    await _open(tester, 'chain');
    await tester.pump(const Duration(seconds: 31));
    await _until(tester, _result('chain', t));
    expect(Storage.xp, 20);
    expect(Storage.kkeunmariWins, 0);
    expect(find.text(t.kkeunmariTimeUp), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old hard-choice controls cannot judge or finish next question', (
    tester,
  ) async {
    await _open(tester, 'hard', hardDeck: const [_word, _word]);
    final oldChoice = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((w) => w.isCorrect)
        .onSelected!;
    oldChoice();
    await tester.pump();
    final oldNext = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .firstWhere((b) => b.label == t.btnNext)
        .onTap!;
    oldNext();
    await tester.pump();
    oldChoice();
    oldNext();
    await tester.pump();
    expect(
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .every((w) => !w.revealed),
      isTrue,
    );
    expect(Storage.xp, 0);
    await _finish(tester, 'hard', t);
    await _until(tester, _result('hard', t));
    expect(Storage.xp, 4);
    await tester.pumpWidget(const SizedBox());
  });
}

Finder _result(String game, AppL10n t) => find.text(switch (game) {
  'hard' => t.hardQuizDoneTitle,
  'chain' => t.kkeunmariResultTitle,
  _ => '${t.wordleResultWin} +30 XP',
});

Future<void> _open(
  WidgetTester tester,
  String game, {
  List<Vocab> hardDeck = const [_word],
  Widget? screen,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final Widget child = switch (game) {
    'hard' => HardChoiceQuizScreen(
      deck: hardDeck,
      vocabLoader: () async => hardDeck,
    ),
    'chain' => KkeunmariScreen(poolLoader: () async => _chain),
    _ => SilbenKreuzScreen(
      puzzleLoader: () async => {
        'A1': [_puzzle, _puzzle],
      },
    ),
  };
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: screen ?? child,
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _finish(WidgetTester tester, String game, AppL10n t) async {
  if (game == 'hard') {
    tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((w) => w.isCorrect)
        .onSelected!();
    await tester.pump();
    tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .firstWhere((b) => b.label == t.hardQuizFinish)
        .onTap!();
  } else if (game == 'chain') {
    await tester.enterText(find.byType(SoriTextField), '나다');
    tester.widget<SoriTextField>(find.byType(SoriTextField)).onSubmitted!('나다');
    await tester.pump(const Duration(milliseconds: 1200));
  } else {
    await tester.tap(find.bySemanticsLabel('가'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('나'));
  }
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}
