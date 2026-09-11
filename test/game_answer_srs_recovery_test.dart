import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

enum _Flow { chosung, skip, cloze, daily, hard }

final _word = Vocab(
  id: 'answer-evidence-apple',
  korean: '사과',
  romanization: 'sagwa',
  german: 'Apfel',
  english: 'apple',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);
const _item = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ＿＿＿ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich.',
  en: 'Today I study.',
  distractors: ['운동을', '요리를', '독서를'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  late SoriSpeechStub speech;
  var courseCalls = 0;
  setUp(() async {
    speech = stubSoriSpeech();
    courseCalls = 0;
    CourseActivityReporter.recordContentAttemptForTesting =
        (kind, id, correct, context, reason, concept, score) async {
          courseCalls++;
          return CourseUpdate(
            snapshot: CourseMasterySnapshot(),
            currentUnit: null,
          );
        };
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    for (final id in Storage.kScreenCoachIds) {
      platform.values['kl_tut_$id'] = true;
    }
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    CourseActivityReporter.resetOverridesForTesting();
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  testWidgets('chosung disposed mode callback cannot close a new sheet', (
    tester,
  ) async {
    await _pump(tester, _Flow.chosung);
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    void openMode(String tooltip) => tester
        .widgetList<IconButton>(find.byType(IconButton))
        .singleWhere((button) => button.tooltip == tooltip)
        .onPressed!();
    openMode(t.chosungModeWithVowels);
    await _settle(tester);
    final oldMode = tester
        .widget<SoriChip>(find.byKey(const Key('chosung-mode-initials-only')))
        .onTap!;
    oldMode();
    await _settle(tester);
    openMode(t.chosungModeInitialsOnly);
    await _settle(tester);
    oldMode();
    await tester.pump();
    expect(find.byKey(const Key('chosung-mode-with-vowels')), findsOneWidget);
    tester
        .widget<SoriChip>(find.byKey(const Key('chosung-mode-with-vowels')))
        .onTap!();
    await _settle(tester);
    expect(find.byKey(const Key('chosung-mode-with-vowels')), findsNothing);
    expect(Storage.srsTotalReviewed(), 0);
    await _dispose(tester);
  });

  testWidgets('chosung popped route rejects retained load retry', (
    tester,
  ) async {
    var loads = 0;
    await _pump(
      tester,
      _Flow.chosung,
      pushed: true,
      overrideScreen: ChosungQuizScreen(
        vocabLoader: () async {
          loads++;
          throw StateError('fixture loader unavailable');
        },
      ),
    );
    final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    final context = tester.element(find.byType(SoriStudyFrame));
    Navigator.of(context).pop();
    expect(context.mounted, isTrue);
    retry();
    await tester.pump();
    expect(loads, 1);
    await _dispose(tester);
  });

  testWidgets('chosung late initial load cannot revive a popped route', (
    tester,
  ) async {
    final load = Completer<List<Vocab>>();
    await _pump(
      tester,
      _Flow.chosung,
      pushed: true,
      overrideScreen: ChosungQuizScreen(vocabLoader: () => load.future),
    );
    final context = tester.element(find.byType(SoriStudyFrame));
    final route = ModalRoute.of(context)!;
    expect(route.isCurrent, isTrue);
    Navigator.of(context).pop();
    expect(context.mounted, isTrue);
    expect(route.isActive, isFalse);
    load.complete([_word]);
    await _settle(tester);
    expect(find.byType(TextField), findsNothing);
    // Inactive routes can remain mounted while the reverse transition is
    // finalized. The late load must not publish input during that interval.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(ChosungQuizScreen), findsNothing);
    expect(find.byKey(const Key('root-destination')), findsOneWidget);
    expect(Storage.srsTotalReviewed(), 0);
    await _dispose(tester);
  });

  for (final flow in _Flow.values) {
    testWidgets(
      '${flow.name} stale answer cannot judge the next repeated word',
      (tester) async {
        await _pump(tester, flow, repetitions: 2);
        final oldAction = await _answerAction(tester, flow, correct: true);
        final oldSkip = flow == _Flow.chosung
            ? await _answerAction(tester, _Flow.skip)
            : null;
        final oldSubmit = flow == _Flow.chosung
            ? tester.widget<TextField>(find.byType(TextField)).onSubmitted
            : null;
        oldAction();
        await _settle(tester);
        VoidCallback? oldNext;
        if (flow == _Flow.hard) {
          final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
          oldNext = _button(tester, t.btnNext);
          oldNext();
          await tester.pump();
        } else {
          await tester.pump(const Duration(milliseconds: 1200));
        }
        if (flow == _Flow.chosung) {
          await tester.enterText(find.byType(TextField), _word.korean);
          await tester.pump();
        }
        oldAction();
        oldSkip?.call();
        oldSubmit?.call(_word.korean);
        oldNext?.call();
        await _settle(tester);
        expect(Storage.srsCard(_id(flow))?.reviewCount, 1);
        if (flow == _Flow.chosung) {
          expect(Storage.chosungWrong, 0);
        }
        (await _answerAction(tester, flow, correct: true))();
        await _settle(tester);
        expect(Storage.srsCard(_id(flow))?.reviewCount, 2);
        await _dispose(tester);
      },
    );

    for (final log in [false, true]) {
      for (final committed in [false, true]) {
        testWidgets(
          '${flow.name} unknown evidence log=$log committed=$committed',
          (tester) async {
            await _pump(tester, flow);
            final key = log
                ? 'kl_study_log_v1_${Storage.todayIso()}'
                : 'kl_srs_v1';
            platform
              ..rejectKey = key
              ..throwReply = true
              ..commitBeforeFailure = committed
              ..failReloadAfterWrite = true;
            final action = await _answerAction(tester, flow);
            action();
            action();
            await _settle(tester);
            expect(find.byType(AppError), findsOneWidget);
            expect(Storage.xp, 0);
            expect(courseCalls, 0);
            expect(speech.spoken, isEmpty);
            final retry = tester
                .widget<AppError>(find.byType(AppError))
                .onRetry!;
            final writes = platform.writes[key];
            retry();
            await _settle(tester);
            expect(platform.writes[key], writes);
            platform
              ..rejectKey = null
              ..unavailable = false;
            retry();
            retry();
            await _settle(tester);
            expect(find.byType(AppError), findsNothing);
            expect(Storage.srsCard(_id(flow))?.reviewCount, 1);
            expect(
              Storage.studyLogIdsFor(Storage.todayIso()),
              contains(_id(flow)),
            );
            expect(courseCalls, flow == _Flow.cloze ? 1 : 0);
            await _dispose(tester);
          },
        );
      }
    }

    for (final retirement in ['exit', 'unmount', 'reset', 'pop']) {
      testWidgets('${flow.name} $retirement retires a pending judgment', (
        tester,
      ) async {
        await _pump(tester, flow, pushed: retirement == 'pop');
        final release = Completer<void>();
        platform
          ..rejectKey = 'kl_srs_v1'
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        final action = await _answerAction(tester, flow);
        action();
        action();
        await _settle(tester);
        expect(find.byType(AppLoading), findsOneWidget);
        expect(platform.writes['kl_srs_v1'], 1);
        Future<void>? reset;
        if (retirement == 'exit') {
          tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
        } else if (retirement == 'unmount') {
          await tester.pumpWidget(const SizedBox());
        } else if (retirement == 'pop') {
          Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
        } else {
          reset = Storage.resetAllStrict();
        }
        release.complete();
        await _settle(tester);
        if (reset != null) {
          await reset;
          expect(Storage.srsCard(_id(flow)), isNull);
        }
        action();
        await tester.pump();
        expect(Storage.xp, 0);
        expect(Storage.chosungWrong, 0);
        expect(Storage.wrongCountOf(_id(flow)), 0);
        expect(courseCalls, 0);
        expect(speech.spoken, isEmpty);
        await _dispose(tester);
      });
    }

    testWidgets(
      '${flow.name} popped route rejects retained answer before disposal',
      (tester) async {
        await _pump(tester, flow, pushed: true);
        final action = await _answerAction(tester, flow);
        final context = tester.element(find.byType(SoriStudyFrame));
        Navigator.of(context).pop();
        expect(context.mounted, isTrue);
        action();
        await tester.pump();
        expect(Storage.srsTotalReviewed(), 0);
        expect(courseCalls, 0);
        expect(speech.spoken, isEmpty);
        await _dispose(tester);
      },
    );

    testWidgets('${flow.name} retries native SRS rejection before advancing', (
      tester,
    ) async {
      await _pump(tester, flow);
      platform.rejectKey = 'kl_srs_v1';
      final answer = await _answerAction(tester, flow);
      answer();
      await _settle(tester);
      expect(find.byType(AppError), findsOneWidget);
      expect(Storage.xp, 0);
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      platform.rejectKey = null;
      retry();
      retry();
      await _settle(tester);
      expect(find.byType(AppError), findsNothing);
      expect(Storage.srsCard(_id(flow))?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), contains(_id(flow)));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  for (final flow in [_Flow.cloze, _Flow.daily]) {
    testWidgets(
      '${flow.name} correction preserves first negative evidence and score',
      (tester) async {
        await _pump(tester, flow);
        platform.rejectKey = 'kl_srs_v1';
        final oldWrong = await _answerAction(tester, flow);
        oldWrong();
        await _settle(tester);
        final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
        platform.rejectKey = null;
        retry();
        await _settle(tester);
        await tester.pump(const Duration(milliseconds: 800));
        oldWrong();
        await tester.pump();
        expect(Storage.srsCard(_id(flow))?.reviewCount, 1);
        final correct = await _answerAction(tester, flow, correct: true);
        correct();
        await _settle(tester);
        await tester.pump(const Duration(milliseconds: 1200));
        await _settle(tester);
        expect(Storage.srsCard(_id(flow))?.reviewCount, 1);
        expect(courseCalls, flow == _Flow.cloze ? 1 : 0);
        expect(find.byType(GameOverCard), findsOneWidget);
        final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
        expect(
          tester.widget<GameOverCard>(find.byType(GameOverCard)).scoreLabel,
          t.quizScore(0, 1),
        );
        expect(Storage.xp, flow == _Flow.daily ? 20 : 0);
        await _dispose(tester);
      },
    );
  }

  for (final flow in [_Flow.chosung, _Flow.cloze]) {
    testWidgets('${flow.name} replay ignores old result and retry callbacks', (
      tester,
    ) async {
      await _pump(tester, flow, pushed: true);
      platform.rejectKey = 'kl_srs_v1';
      (await _answerAction(tester, flow, correct: true))();
      await _settle(tester);
      final oldRetry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      platform.rejectKey = null;
      oldRetry();
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 1200));
      if (flow == _Flow.chosung) {
        await _finishChosung(tester, remaining: 9);
      } else {
        await _settle(tester);
      }
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      final again = _button(
        tester,
        flow == _Flow.chosung ? t.chosungRoundContinue : t.quizAgain,
      );
      final close = flow == _Flow.cloze ? _button(tester, t.btnClose) : null;
      final count = flow == _Flow.chosung ? 10 : 1;
      expect(Storage.srsCard(_id(flow))?.reviewCount, count);
      expect(Storage.xp, flow == _Flow.chosung ? 40 : 5);
      again();
      await _settle(tester);
      again();
      close?.call();
      oldRetry();
      await _settle(tester);
      expect(find.byKey(const Key('root-destination')), findsNothing);
      expect(Storage.srsCard(_id(flow))?.reviewCount, count);
      (await _answerAction(tester, flow, correct: true))();
      await _settle(tester);
      expect(Storage.srsCard(_id(flow))?.reviewCount, count + 1);
      await _dispose(tester);
    });
  }
}

String _id(_Flow flow) =>
    flow == _Flow.cloze || flow == _Flow.daily ? _item.answer : _word.korean;

Future<void> _pump(
  WidgetTester tester,
  _Flow flow, {
  bool pushed = false,
  int repetitions = 1,
  Widget? overrideScreen,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final screen =
      overrideScreen ??
      switch (flow) {
        _Flow.chosung || _Flow.skip => ChosungQuizScreen(deck: [_word]),
        _Flow.cloze => ClozeGameScreen(items: List.filled(repetitions, _item)),
        _Flow.daily => DailyChallengeScreen(
          items: List.filled(repetitions, _item),
        ),
        _Flow.hard => HardChoiceQuizScreen(
          deck: List.filled(repetitions, _word),
          vocabLoader: () async => [_word],
        ),
      };
  final navigator = GlobalKey<NavigatorState>();
  final wrapped = MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: screen,
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: pushed ? const SizedBox(key: Key('root-destination')) : wrapped,
    ),
  );
  if (pushed) {
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => wrapped),
      ),
    );
  }
  await _settle(tester);
}

Future<VoidCallback> _answerAction(
  WidgetTester tester,
  _Flow flow, {
  bool correct = false,
}) async {
  if (flow == _Flow.chosung || flow == _Flow.skip) {
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    if (flow == _Flow.chosung) {
      await tester.enterText(
        find.byType(TextField),
        correct ? _word.korean : '틀린답',
      );
      await tester.pump();
    }
    return tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere(
          (button) =>
              button.label ==
              (flow == _Flow.skip ? t.btnSkip : t.chosungSubmitBtn),
        )
        .onTap!;
  }
  return tester
      .widgetList<QuizChoice>(find.byType(QuizChoice))
      .firstWhere((choice) => choice.isCorrect == correct)
      .onSelected!;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}

VoidCallback _button(WidgetTester tester, String label) => tester
    .widgetList<SoriButton>(find.byType(SoriButton))
    .singleWhere((button) => button.label == label)
    .onTap!;

Future<void> _finishChosung(
  WidgetTester tester, {
  required int remaining,
}) async {
  for (var i = 0; i < remaining; i++) {
    (await _answerAction(tester, _Flow.chosung, correct: true))();
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 800));
  }
  await _settle(tester);
}
