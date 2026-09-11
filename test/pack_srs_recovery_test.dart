import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_recall_screen.dart';
import 'package:ko_lernen_app/services/pack_session_srs_ledger.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _word = Vocab(
  id: 'test-학교',
  korean: '학교',
  romanization: 'hakgyo',
  german: 'Schule',
  english: 'school',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  isReviewBoss: true,
);
const _pack = VocabPack(id: 'a1_srs_1', level: 'A1', words: [_word]);
const _secondWord = Vocab(
  id: 'test-집',
  korean: '집',
  romanization: 'jip',
  german: 'Haus',
  english: 'house',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  isReviewBoss: true,
);
const _twoWords = VocabPack(
  id: 'a1_srs_1',
  level: 'A1',
  words: [_word, _secondWord],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    platform.values.addAll({
      'kl_tut_vocab_pack': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  testWidgets('system pop preserves already accepted partial Learn progress', (
    tester,
  ) async {
    await _pump(
      tester,
      false,
      PackRecallSession.forPack(packId: _pack.id),
      pushedRoute: true,
      pack: _twoWords,
    );
    await _answer(tester, false);
    expect(Storage.srsTotalReviewed(), 1);
    expect(find.byType(FlipCard), findsOneWidget);
    Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final progress = PackProgressService.get(_pack.id);
    expect(progress?.wordsLearned, 1);
    expect(progress?.status, PackStatus.inProgress);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final recall in [false, true]) {
    testWidgets(
      'flow=$recall popped route rejects retained answer before disposal',
      (tester) async {
        await _pump(
          tester,
          recall,
          PackRecallSession.forPack(packId: _pack.id),
          pushedRoute: true,
        );
        late VoidCallback oldAnswer;
        if (recall) {
          oldAnswer = tester
              .widget<SoriButton>(
                find.byKey(const Key('vocab-recall-show-answer')),
              )
              .onTap!;
        } else {
          tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
          await tester.pump();
          oldAnswer = tester
              .widget<SoriContentFeed>(find.byType(SoriContentFeed))
              .onNext!;
        }
        final context = tester.element(find.byType(SoriStudyFrame));
        Navigator.of(context).pop();
        expect(
          context.mounted,
          isTrue,
          reason: 'Popped route is still mounted during reverse animation',
        );
        oldAnswer();
        await tester.pump();
        expect(Storage.srsTotalReviewed(), 0);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'flow=$recall popped route ignores late pack load before disposal',
      (tester) async {
        final load = Completer<VocabPack?>();
        await _pump(
          tester,
          recall,
          PackRecallSession.forPack(packId: _pack.id),
          pushedRoute: true,
          loader: (_) => load.future,
        );
        final context = tester.element(find.byType(SoriStudyFrame));
        Navigator.of(context).pop();
        expect(context.mounted, isTrue);
        load.complete(_pack);
        await tester.pump();
        expect(find.byType(FlipCard, skipOffstage: false), findsNothing);
        expect(find.byType(SoriTextField, skipOffstage: false), findsNothing);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets('flow=$recall old answer controls cannot judge the next card', (
      tester,
    ) async {
      await _pump(
        tester,
        recall,
        PackRecallSession.forPack(packId: _pack.id),
        pack: _twoWords,
      );
      if (recall) {
        final oldShow = tester
            .widget<SoriButton>(
              find.byKey(const Key('vocab-recall-show-answer')),
            )
            .onTap!;
        oldShow();
        await _until(tester, find.byKey(const Key('vocab-recall-next')));
        final oldNext = tester
            .widget<SoriButton>(find.byKey(const Key('vocab-recall-next')))
            .onTap!;
        oldNext();
        await tester.pump();
        oldNext();
        oldShow();
        await tester.pump();
        expect(find.byKey(const Key('vocab-recall-next')), findsNothing);
        expect(find.byType(SoriTextField), findsOneWidget);
      } else {
        final oldFlip = tester.widget<FlipCard>(find.byType(FlipCard)).onTap!;
        oldFlip();
        await tester.pump();
        final oldFeed = tester.widget<SoriContentFeed>(
          find.byType(SoriContentFeed),
        );
        oldFeed.onNext!();
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        oldFlip();
        oldFeed.onNext!();
        oldFeed.onHard!();
        oldFeed.onSkip!();
        await tester.pump();
        expect(find.byType(FlipCard), findsOneWidget);
        expect(find.byType(QuizChoice), findsNothing);
      }
      expect(Storage.srsTotalReviewed(), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets(
      '${recall ? 'typed recall' : 'pack learn'} holds rejected SRS until retry',
      (tester) async {
        final session = PackRecallSession.forPack(packId: _pack.id);
        await _pump(tester, recall, session);
        platform.rejectKey = 'kl_srs_v1';
        await _answer(tester, recall);
        await _until(tester, find.byType(AppError));
        expect(find.byType(QuizChoice), findsNothing);
        expect(find.byKey(const Key('vocab-recall-next')), findsNothing);
        expect(Storage.srsCard(_word.korean)?.reviewCount ?? 0, 0);
        if (recall) {
          expect(
            session.ledger.stateFor(_word.korean),
            PackSessionSrsState.unrated,
          );
        }
        platform.rejectKey = null;
        final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
        retry();
        retry();
        await _until(
          tester,
          recall
              ? find.byKey(const Key('vocab-recall-next'))
              : find.byWidgetPredicate((w) => w is QuizChoice && w.isCorrect),
        );
        expect(Storage.srsCard(_word.korean)?.reviewCount, 1);
        expect(
          Storage.studyLogIdsFor(Storage.todayIso()),
          contains(_word.korean),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    for (final logFailure in [false, true]) {
      for (final committed in [false, true]) {
        testWidgets(
          'flow=$recall unknown evidence log=$logFailure committed=$committed',
          (tester) async {
            final session = PackRecallSession.forPack(packId: _pack.id);
            await _pump(tester, recall, session);
            final key = logFailure
                ? 'kl_study_log_v1_${Storage.todayIso()}'
                : 'kl_srs_v1';
            platform
              ..rejectKey = key
              ..throwReply = true
              ..commitBeforeFailure = committed
              ..failReloadAfterWrite = true;
            await _answer(tester, recall, gotIt: false);
            await _until(tester, find.byType(AppError));
            final retry = tester
                .widget<AppError>(find.byType(AppError))
                .onRetry!;
            final writes = platform.writes[key];
            retry();
            await tester.pump(const Duration(milliseconds: 200));
            expect(platform.writes[key], writes);
            expect(find.byKey(const Key('vocab-recall-next')), findsNothing);
            platform
              ..unavailable = false
              ..rejectKey = null;
            retry();
            retry();
            await _until(tester, _confirmed(recall));
            expect(Storage.srsCard(_word.korean)?.reviewCount, 1);
            expect(Storage.wrongCountOf(_word.korean), 1);
            expect(
              Storage.studyLogIdsFor(Storage.todayIso()),
              contains(_word.korean),
            );
            if (recall) {
              expect(
                session.ledger.stateFor(_word.korean),
                PackSessionSrsState.negative,
              );
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }

    for (final retirement in ['exit', 'unmount', 'reset', 'route_pop']) {
      testWidgets('flow=$recall $retirement while evidence is pending', (
        tester,
      ) async {
        final session = PackRecallSession.forPack(packId: _pack.id);
        await _pump(
          tester,
          recall,
          session,
          pushedRoute: retirement == 'route_pop',
        );
        final release = Completer<void>();
        platform
          ..rejectKey = 'kl_srs_v1'
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        await _answer(tester, recall);
        await _until(tester, find.byType(AppLoading));
        Future<void>? reset;
        if (retirement == 'exit') {
          tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
        } else if (retirement == 'route_pop') {
          Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
        } else if (retirement == 'unmount') {
          await tester.pumpWidget(const SizedBox());
        } else {
          reset = Storage.resetAllStrict();
        }
        release.complete();
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        if (reset != null) {
          await reset;
          expect(Storage.srsCard(_word.korean), isNull);
        }
        expect(find.byType(QuizChoice), findsNothing);
        expect(find.byKey(const Key('vocab-recall-next')), findsNothing);
        expect(Storage.xp, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets(
      'flow=$recall old load retry cannot replace evidence recovery',
      (tester) async {
        var calls = 0;
        final waiting = Completer<void>();
        addTearDown(() {
          if (!waiting.isCompleted) {
            waiting.complete();
          }
        });
        Future<VocabPack?> loader(String _) async {
          calls++;
          if (calls == 1) {
            throw StateError('Load unavailable');
          }
          await waiting.future;
          return _pack;
        }

        await _pump(
          tester,
          recall,
          PackRecallSession.forPack(packId: _pack.id),
          loader: loader,
        );
        await _until(tester, find.byType(AppError));
        final oldRetry = tester
            .widget<AppError>(find.byType(AppError))
            .onRetry!;
        oldRetry();
        oldRetry();
        await tester.pump();
        expect(calls, 2);
        waiting.complete();
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        platform.rejectKey = 'kl_srs_v1';
        await _answer(tester, recall);
        await _until(tester, find.byType(AppError));
        oldRetry();
        await tester.pump();
        expect(calls, 2);
        platform.rejectKey = null;
        tester.widget<AppError>(find.byType(AppError)).onRetry!();
        await _until(tester, _confirmed(recall));
        expect(Storage.srsCard(_word.korean)?.reviewCount, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'recognition waits for rejected negative evidence and schedules once',
    (tester) async {
      final timers = <Timer>[];
      await _pump(
        tester,
        false,
        PackRecallSession.forPack(packId: _pack.id),
        pack: _twoWords,
        timerFactory: (duration, callback) {
          final timer = Timer(duration, callback);
          timers.add(timer);
          return timer;
        },
      );
      await _answer(tester, false);
      await _answer(tester, false);
      await _until(tester, _confirmed(false));
      final correctText = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect)
          .text;
      final current = _twoWords.words
          .singleWhere((word) => word.english == correctText)
          .korean;
      expect(Storage.srsCard(current)?.reviewCount, 1);
      final wrong = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((choice) => !choice.isCorrect)
          .onSelected!;
      platform.rejectKey = 'kl_srs_v1';
      wrong();
      await _until(tester, find.byType(AppError));
      wrong();
      expect(timers, isEmpty);
      expect(Storage.wrongCountOf(current), 0);
      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _until(tester, _confirmed(false));
      expect(timers, hasLength(1));
      expect(Storage.srsCard(current)?.reviewCount, 2);
      expect(Storage.wrongCountOf(current), 1);
      wrong();
      retry();
      await tester.pump();
      expect(timers, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      expect(timers.single.isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _confirmed(bool recall) => recall
    ? find.byKey(const Key('vocab-recall-next'))
    : find.byWidgetPredicate((w) => w is QuizChoice && w.isCorrect);

Future<void> _pump(
  WidgetTester tester,
  bool recall,
  PackRecallSession session, {
  Future<VocabPack?> Function(String)? loader,
  VocabPack pack = _pack,
  Timer Function(Duration, void Function())? timerFactory,
  bool pushedRoute = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final Widget screen = recall
      ? VocabPackRecallScreen(
          packId: _pack.id,
          recallSession: session,
          packLoader: loader ?? (_) async => pack,
        )
      : VocabPackScreen(
          packId: _pack.id,
          packLoader: loader ?? (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
          advanceTimerFactory: timerFactory,
        );
  final navigatorKey = GlobalKey<NavigatorState>();
  final wrapped = MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: screen,
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: pushedRoute ? const SizedBox() : wrapped,
    ),
  );
  if (pushedRoute) {
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => wrapped),
      ),
    );
  }
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _answer(
  WidgetTester tester,
  bool recall, {
  bool gotIt = true,
}) async {
  if (recall) {
    await tester.enterText(
      find.byType(SoriTextField),
      gotIt ? _word.korean : '틀린답',
    );
    await tester.pump();
    tester
        .widget<SoriButton>(find.byKey(const Key('vocab-recall-submit')))
        .onTap!();
  } else {
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
    (gotIt ? feed.onNext : feed.onHard)!();
  }
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}
