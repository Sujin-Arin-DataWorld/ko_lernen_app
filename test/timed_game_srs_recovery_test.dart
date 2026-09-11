import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/kkeunmari_dictionary_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _words = [
  Vocab(
    korean: '사과',
    romanization: 'sagwa',
    german: 'Apfel',
    english: 'apple',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '과일',
    romanization: 'gwail',
    german: 'Obst',
    english: 'fruit',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '가방',
    romanization: 'gabang',
    german: 'Tasche',
    english: 'bag',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
];
const _chain = [
  KkeunmariWord(
    word: '사과',
    first: '사',
    last: '과',
    level: 'A1',
    german: 'Apfel',
    topic: 'test',
    nextCount: 1,
    isDeadEnd: false,
  ),
  KkeunmariWord(
    word: '과일',
    first: '과',
    last: '일',
    level: 'A1',
    german: 'Obst',
    topic: 'test',
    nextCount: 0,
    isDeadEnd: true,
  ),
];

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
    for (final coach in Storage.kScreenCoachIds) {
      platform.values['kl_tut_$coach'] = true;
    }
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    KkeunmariEngine.setPoolForTesting(_chain);
    // Production vocabulary lookup: proves the chain answer is an actual SRS word.
    expect((await DataLoader.loadVocab()).any((v) => v.korean == '과일'), isTrue);
  });
  tearDown(() {
    KkeunmariEngine.reset();
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final kind in ['speed-correct', 'speed-wrong', 'chain']) {
    for (final log in [false, true]) {
      for (final committed in [false, true]) {
        testWidgets(
          '$kind unknown card/log=$log committed=$committed retries once',
          (tester) async {
            await _pump(tester, kind);
            final key = log
                ? 'kl_study_log_v1_${Storage.todayIso()}'
                : 'kl_srs_v1';
            platform
              ..rejectKey = key
              ..throwReply = true
              ..commitBeforeFailure = committed
              ..failReloadAfterWrite = true;
            final answer = await _answerAction(tester, kind);
            answer();
            answer();
            await _flush(tester);
            expect(find.byType(AppError), findsOneWidget);
            expect(platform.writes[key], 1);
            expect(Storage.xp, 0);
            expect(Storage.wrongCountOf('사과'), 0);
            final retry = tester
                .widget<AppError>(find.byType(AppError))
                .onRetry!;
            retry();
            await _flush(tester);
            expect(
              platform.writes[key],
              1,
              reason:
                  'unknown native state must be reconciled before another write',
            );
            platform
              ..rejectKey = null
              ..unavailable = false;
            retry();
            retry();
            await _flush(tester);
            expect(find.byType(AppError), findsNothing);
            expect(Storage.srsCard(_id(kind))?.reviewCount, 1);
            expect(
              Storage.studyLogIdsFor(Storage.todayIso()),
              contains(_id(kind)),
            );
            expect(Storage.wrongCountOf('사과'), kind == 'speed-wrong' ? 1 : 0);
            await _dispose(tester);
          },
        );
      }
    }
    for (final retirement in ['exit', 'unmount', 'reset', 'pop']) {
      testWidgets('$kind $retirement retires pending judgment and timers', (
        tester,
      ) async {
        await _pump(tester, kind, pushed: retirement == 'pop');
        final release = Completer<void>();
        platform
          ..rejectKey = 'kl_srs_v1'
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        final answer = await _answerAction(tester, kind);
        answer();
        answer();
        await _flush(tester);
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
        await _flush(tester);
        if (reset != null) {
          await reset;
          expect(Storage.srsCard(_id(kind)), isNull);
        }
        answer();
        await tester.pump(const Duration(seconds: 65));
        await _flush(tester);
        expect(Storage.xp, 0);
        expect(Storage.wrongCountOf('사과'), 0);
        expect(Storage.kkeunmariWins, 0);
        await _dispose(tester);
      });
    }
    testWidgets('$kind popped route blocks retained answer before disposal', (
      tester,
    ) async {
      await _pump(tester, kind, pushed: true);
      final answer = await _answerAction(tester, kind);
      final context = tester.element(find.byType(SoriStudyFrame));
      Navigator.of(context).pop();
      expect(context.mounted, isTrue);
      answer();
      await _flush(tester);
      expect(platform.writes['kl_srs_v1'], isNull);
      await _dispose(tester);
    });
    for (final success in [false, true]) {
      testWidgets(
        '$kind last-second write success=$success holds expiry until confirmed',
        (tester) async {
          await _pump(tester, kind);
          await tester.pump(Duration(seconds: kind == 'chain' ? 29 : 59));
          await _flush(tester);
          final release = Completer<void>();
          platform
            ..rejectKey = 'kl_srs_v1'
            ..releaseWrite = release
            ..successfulReply = success
            ..commitBeforeFailure = success;
          (await _answerAction(tester, kind))();
          await _flush(tester);
          await tester.pump(const Duration(seconds: 65));
          expect(Storage.xp, 0);
          expect(find.byType(AppLoading), findsOneWidget);
          release.complete();
          await _flush(tester);
          if (!success) {
            expect(find.byType(AppError), findsOneWidget);
            await tester.pump(const Duration(seconds: 65));
            expect(Storage.xp, 0);
            final retry = tester
                .widget<AppError>(find.byType(AppError))
                .onRetry!;
            platform.rejectKey = null;
            retry();
            await _flush(tester);
          }
          expect(Storage.srsCard(_id(kind))?.reviewCount, 1);
          expect(Storage.xp, 0);
          await tester.pump(const Duration(milliseconds: 1100));
          await _flush(tester);
          expect(
            Storage.xp,
            kind == 'chain'
                ? 20
                : kind == 'speed-correct'
                ? 3
                : 0,
          );
          expect(
            Storage.gameBest(kind == 'chain' ? 'kkeunmari' : 'speed_match'),
            kind == 'chain'
                ? 2
                : kind == 'speed-correct'
                ? 1
                : 0,
          );
          await _dispose(tester);
        },
      );
    }
    testWidgets('$kind retries native SRS rejection before progress', (
      tester,
    ) async {
      await _pump(tester, kind);
      platform.rejectKey = 'kl_srs_v1';
      await _answer(tester, kind);
      await _flush(tester);
      expect(platform.writes['kl_srs_v1'], 1);
      expect(find.byType(AppError), findsOneWidget);
      expect(Storage.xp, 0);
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      platform.rejectKey = null;
      retry();
      await _flush(tester);
      expect(Storage.srsCard(kind == 'chain' ? '과일' : '사과')?.reviewCount, 1);
      await _dispose(tester);
    });
  }

  testWidgets(
    'speed correction preserves first negative evidence and one wrong diagnostic',
    (tester) async {
      await _pump(tester, 'speed-wrong');
      await _answer(tester, 'speed-wrong');
      await _flush(tester);
      final negative = Storage.srsCard('사과')!.toJson();
      await _answer(tester, 'speed-wrong');
      await _flush(tester);
      await _answer(tester, 'speed-correct');
      await _flush(tester);
      expect(Storage.srsCard('사과')!.toJson(), negative);
      expect(Storage.wrongCountOf('사과'), 1);
      expect(platform.writes['kl_srs_v1'], 1);
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      expect(find.text(t.speedMatchScore(1)), findsOneWidget);
      await _dispose(tester);
    },
  );

  for (final kind in ['speed-correct', 'chain']) {
    testWidgets('$kind lifecycle resume cannot restart clock during recovery', (
      tester,
    ) async {
      await _pump(tester, kind);
      platform.rejectKey = 'kl_srs_v1';
      await _answer(tester, kind);
      await _flush(tester);
      _pause(tester);
      _resume(tester);
      await tester.pump(const Duration(seconds: 65));
      expect(find.byType(AppError), findsOneWidget);
      expect(Storage.xp, 0);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _flush(tester);
      _pause(tester);
      await tester.pump(const Duration(seconds: 65));
      expect(Storage.xp, 0);
      _resume(tester);
      await tester.pump(const Duration(seconds: 61));
      await _flush(tester);
      expect(Storage.xp, kind == 'chain' ? 20 : 3);
      await _dispose(tester);
    });
  }

  for (final status in KkeunmariDictionaryStatus.values) {
    testWidgets(
      'dictionary $status holds remaining time without creating a ghost card',
      (tester) async {
        final reply = Completer<KkeunmariDictionaryResult>();
        var calls = 0;
        await _pump(
          tester,
          'chain',
          screen: KkeunmariScreen(
            dictionaryValidator: (word) {
              expect(word, '과자');
              calls++;
              return reply.future;
            },
          ),
        );
        await tester.pump(const Duration(seconds: 29));
        final answer = await _answerAction(tester, 'chain', chainWord: '과자');
        answer();
        answer();
        await _flush(tester);
        expect(calls, 1);
        await tester.pump(const Duration(seconds: 65));
        expect(Storage.xp, 0);
        reply.complete(KkeunmariDictionaryResult(status));
        await _flush(tester);
        expect(platform.writes['kl_srs_v1'], isNull);
        await tester.pump(const Duration(milliseconds: 1100));
        await _flush(tester);
        expect(
          Storage.gameBest('kkeunmari'),
          status == KkeunmariDictionaryStatus.valid ? 2 : 1,
        );
        expect(
          Storage.kkeunmariWins,
          status == KkeunmariDictionaryStatus.valid ? 1 : 0,
        );
        await _dispose(tester);
      },
    );
  }

  for (final retirement in ['pop', 'reset']) {
    testWidgets(
      'dictionary late valid reply after $retirement cannot accept a word',
      (tester) async {
        final reply = Completer<KkeunmariDictionaryResult>();
        await _pump(
          tester,
          'chain',
          pushed: retirement == 'pop',
          screen: KkeunmariScreen(dictionaryValidator: (_) => reply.future),
        );
        final answer = await _answerAction(tester, 'chain', chainWord: '과자');
        answer();
        await _flush(tester);
        if (retirement == 'pop') {
          Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
        } else {
          final reset = Storage.resetAllStrict();
          await _flush(tester);
          await reset;
        }
        reply.complete(
          const KkeunmariDictionaryResult(KkeunmariDictionaryStatus.valid),
        );
        await _flush(tester);
        answer();
        await tester.pump(const Duration(seconds: 65));
        await _flush(tester);
        expect(Storage.xp, 0);
        expect(Storage.kkeunmariWins, 0);
        expect(Storage.srsTotalReviewed(), 0);
        await _dispose(tester);
      },
    );
  }

  testWidgets(
    'speed resize during pending evidence preserves the admitted pair',
    (tester) async {
      await _pump(tester, 'speed-correct');
      final oldLeft = _tile(tester, 'left', '과일');
      final oldRight = _tile(tester, 'right', '과일');
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      await _answer(tester, 'speed-correct');
      await _flush(tester);
      tester.view.physicalSize = const Size(800, 1280);
      await tester.pump();
      oldLeft();
      oldRight();
      release.complete();
      await _flush(tester);
      expect(Storage.srsCard('사과')?.reviewCount, 1);
      expect(Storage.srsCard('과일'), isNull);
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      expect(find.text(t.speedMatchScore(1)), findsOneWidget);
      expect(find.byKey(const ValueKey('speed-match-left-사과')), findsNothing);
      oldLeft();
      oldRight();
      await _flush(tester);
      expect(Storage.srsCard('과일'), isNull);
      await _dispose(tester);
    },
  );

  testWidgets('speed retired result actions cannot restart or close a replay', (
    tester,
  ) async {
    await _pump(tester, 'speed-correct', pushed: true);
    await _answer(tester, 'speed-correct');
    await _flush(tester);
    _tile(tester, 'left', '과일')();
    await tester.pump();
    _tile(tester, 'right', '과일')();
    await _flush(tester);
    expect(Storage.xp, 6);
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    final again = _button(tester, t.quizAgain);
    final close = _button(tester, t.btnClose);
    again();
    await _flush(tester);
    await _answer(tester, 'speed-correct');
    await _flush(tester);
    again();
    close();
    await _flush(tester);
    expect(find.byKey(const Key('root-destination')), findsNothing);
    expect(find.byKey(const ValueKey('speed-match-left-사과')), findsNothing);
    expect(Storage.srsCard('사과')?.reviewCount, 2);
    await _dispose(tester);
  });

  for (final kind in ['speed-correct', 'chain']) {
    testWidgets(
      '$kind late loader after pop cannot revive screen or replace chain pool',
      (tester) async {
        final speed = Completer<List<Vocab>>();
        final chain = Completer<List<KkeunmariWord>>();
        await _pump(
          tester,
          kind,
          pushed: true,
          screen: kind == 'chain'
              ? KkeunmariScreen(poolLoader: () => chain.future)
              : SpeedMatchScreen(vocabLoader: () => speed.future),
        );
        final context = tester.element(find.byType(SoriStudyFrame));
        Navigator.of(context).pop();
        if (kind == 'chain') {
          KkeunmariEngine.setPoolForTesting([_chain.first]);
          chain.complete(_chain);
        } else {
          speed.complete(_words);
        }
        await _flush(tester);
        await tester.pump(const Duration(seconds: 2));
        await _flush(tester);
        if (kind == 'chain') {
          expect(KkeunmariEngine.pool.length, 1);
        }
        expect(find.byKey(const Key('root-destination')), findsOneWidget);
        expect(Storage.xp, 0);
        await _dispose(tester);
      },
    );
  }

  testWidgets(
    'dictionary exception is recoverable and resumes the existing countdown',
    (tester) async {
      await _pump(
        tester,
        'chain',
        screen: KkeunmariScreen(
          dictionaryValidator: (_) async => throw StateError('offline'),
        ),
      );
      await tester.pump(const Duration(seconds: 29));
      (await _answerAction(tester, 'chain', chainWord: '과자'))();
      await _flush(tester);
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      expect(find.text(t.kkeunmariDictionaryUnavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 1100));
      await _flush(tester);
      expect(Storage.gameBest('kkeunmari'), 1);
      expect(Storage.kkeunmariWins, 0);
      await _dispose(tester);
    },
  );

  testWidgets(
    'speed resumes after retry when lifecycle returned while evidence was blocked',
    (tester) async {
      await _pump(tester, 'speed-correct');
      await tester.pump(const Duration(seconds: 59));
      platform.rejectKey = 'kl_srs_v1';
      await _answer(tester, 'speed-correct');
      await _flush(tester);
      _pause(tester);
      _resume(tester);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 1100));
      await _flush(tester);
      expect(Storage.xp, 3);
      expect(Storage.gameBest('speed_match'), 1);
      await _dispose(tester);
    },
  );

  testWidgets('chain prior-turn submit cannot consume a new turn input', (
    tester,
  ) async {
    const continued = [
      KkeunmariWord(
        word: '사과',
        first: '사',
        last: '과',
        level: 'A1',
        german: 'Apfel',
        topic: 'test',
        nextCount: 2,
        isDeadEnd: false,
      ),
      KkeunmariWord(
        word: '과일',
        first: '과',
        last: '일',
        level: 'A1',
        german: 'Obst',
        topic: 'test',
        nextCount: 1,
        isDeadEnd: false,
      ),
      KkeunmariWord(
        word: '과정',
        first: '과',
        last: '정',
        level: 'A1',
        german: 'Prozess',
        topic: 'test',
        nextCount: 0,
        isDeadEnd: true,
      ),
      KkeunmariWord(
        word: '일기',
        first: '일',
        last: '기',
        level: 'A1',
        german: 'Tagebuch',
        topic: 'test',
        nextCount: 1,
        isDeadEnd: false,
      ),
      KkeunmariWord(
        word: '기차',
        first: '기',
        last: '차',
        level: 'A1',
        german: 'Zug',
        topic: 'test',
        nextCount: 0,
        isDeadEnd: true,
      ),
    ];
    await _pump(
      tester,
      'chain',
      screen: KkeunmariScreen(poolLoader: () async => continued),
    );
    final oldSubmit = await _answerAction(tester, 'chain');
    oldSubmit();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 1900));
    await _flush(tester);
    final freshSubmit = await _answerAction(tester, 'chain', chainWord: '기차');
    oldSubmit();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await _flush(tester);
    expect(Storage.xp, 0);
    freshSubmit();
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await _flush(tester);
    expect(Storage.gameBest('kkeunmari'), 4);
    expect(Storage.xp, 40);
    await _dispose(tester);
  });

  testWidgets('chain retired result Home cannot pop a replay', (tester) async {
    await _pump(tester, 'chain', pushed: true);
    await _answer(tester, 'chain');
    await _flush(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await _flush(tester);
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    final again = _button(tester, t.kkeunmariPlayAgain);
    final home = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((b) => b.label != t.kkeunmariPlayAgain)
        .onTap!;
    again();
    await _flush(tester);
    home();
    again();
    await _flush(tester);
    expect(
      ModalRoute.of(tester.element(find.byType(KkeunmariScreen)))!.isCurrent,
      isTrue,
    );
    expect(find.byType(TextField), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets(
    'speed old filter callback cannot open a sheet for the next presentation',
    (tester) async {
      await _pump(
        tester,
        'speed-correct',
        screen: SpeedMatchScreen(vocabLoader: () async => _words),
      );
      final oldFilter = tester
          .widget<SoriChromeRow>(find.byType(SoriChromeRow))
          .onFilterTap!;
      await _answer(tester, 'speed-correct');
      await _flush(tester);
      oldFilter();
      await _flush(tester);
      expect(find.byType(BottomSheet), findsNothing);
      tester.widget<SoriChromeRow>(find.byType(SoriChromeRow)).onFilterTap!();
      await _flush(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      await _dispose(tester);
    },
  );

  testWidgets('speed old empty-state CTA cannot restart an active round', (
    tester,
  ) async {
    await _pump(
      tester,
      'speed-correct',
      screen: SpeedMatchScreen(
        vocabLoader: () async => [
          _words.first,
          _atLevel(_words[1], 'B1'),
          _atLevel(_words[2], 'B1'),
        ],
      ),
    );
    final oldCta = tester
        .widget<SoriEmptyState>(find.byType(SoriEmptyState))
        .onCta!;
    oldCta();
    await _flush(tester);
    await _answer(tester, 'speed-correct');
    await _flush(tester);
    oldCta();
    await _flush(tester);
    expect(find.byKey(const ValueKey('speed-match-left-사과')), findsNothing);
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    expect(find.text(t.speedMatchScore(1)), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('speed old retry cannot target a subsequent failed load', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      'speed-correct',
      screen: SpeedMatchScreen(
        vocabLoader: () async {
          calls++;
          if (calls <= 2) {
            throw StateError('temporarily unavailable');
          }
          return _words;
        },
      ),
    );
    final oldRetry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    oldRetry();
    await _flush(tester);
    expect(calls, 2);
    oldRetry();
    await _flush(tester);
    expect(calls, 2);
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await _flush(tester);
    expect(calls, 3);
    expect(find.byKey(const ValueKey('speed-match-left-사과')), findsOneWidget);
    await _dispose(tester);
  });
}

Vocab _atLevel(Vocab word, String level) => Vocab(
  korean: word.korean,
  romanization: word.romanization,
  german: word.german,
  english: word.english,
  level: level,
  posDe: word.posDe,
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

void _pause(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

String _id(String kind) => kind == 'chain' ? '과일' : '사과';

VoidCallback _tile(WidgetTester tester, String side, String word) => tester
    .widget<InkWell>(
      find.descendant(
        of: find.byKey(ValueKey('speed-match-$side-$word')),
        matching: find.byType(InkWell),
      ),
    )
    .onTap!;
VoidCallback _button(WidgetTester tester, String label) => tester
    .widgetList<SoriButton>(find.byType(SoriButton))
    .singleWhere((b) => b.label == label)
    .onTap!;

Future<void> _pump(
  WidgetTester tester,
  String kind, {
  bool pushed = false,
  Widget? screen,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  final game =
      screen ??
      (kind == 'chain'
          ? const KkeunmariScreen()
          : const SpeedMatchScreen(items: _words));
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: pushed ? const SizedBox(key: Key('root-destination')) : game,
    ),
  );
  if (pushed) {
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => game),
      ),
    );
  }
  await _flush(tester);
  if (pushed) {
    await tester.pump(const Duration(milliseconds: 500));
    await _flush(tester);
  }
}

Future<void> _answer(WidgetTester tester, String kind) async {
  (await _answerAction(tester, kind))();
}

Future<VoidCallback> _answerAction(
  WidgetTester tester,
  String kind, {
  String chainWord = '과일',
}) async {
  if (kind == 'chain') {
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    await tester.enterText(find.byType(TextField), chainWord);
    return tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((b) => b.label == t.kkeunmariSubmit)
        .onTap!;
  } else {
    await tester.tap(find.byKey(const ValueKey('speed-match-left-사과')));
    await tester.pump();
    return tester
        .widget<InkWell>(
          find.descendant(
            of: find.byKey(
              ValueKey(
                'speed-match-right-${kind == 'speed-wrong' ? '과일' : '사과'}',
              ),
            ),
            matching: find.byType(InkWell),
          ),
        )
        .onTap!;
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump();
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}
