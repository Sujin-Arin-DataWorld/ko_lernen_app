import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

enum _Flow { play, quiz, typing, matching }

const _packId = 'cp_srs_recovery';
final _words = [
  for (final pair in [
    ('학교', 'school'),
    ('학생', 'student'),
    ('친구', 'friend'),
    ('선생님', 'teacher'),
  ])
    ExtractedWord(
      korean: pair.$1,
      romanization: '',
      posDe: 'Nomen',
      translationDe: pair.$2,
      translationEn: pair.$2,
      exampleKorean: '',
      exampleDe: '',
      savedToPackId: null,
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
    for (final coach in [
      'cpPlay',
      'cpQuiz',
      'cpTyping',
      'cpMatching',
      'soriDeck',
      'wordbook',
    ]) {
      platform.values['kl_tut_$coach'] = true;
    }
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(id: _packId, name: 'SRS recovery', words: _words),
    );
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });
  testWidgets(
    'play editing retires old card callbacks and preserves the edited target',
    (tester) async {
      final word = _words.first.copyWithEditable(
        korean: '검증편집어',
        translationDe: '',
        translationEn: '',
      );
      await CustomPackService.save(
        CustomPack.manual(
          id: _packId,
          name: 'Editing',
          words: [word, ..._words.skip(1)],
        ),
      );
      await _pump(tester, _Flow.play);
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await _settle(tester);
      final oldAnswer = tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onNext!;
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      final oldEdit = tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, t.savedAddTranslation),
          )
          .onPressed!;
      oldEdit();
      await _settle(tester);
      expect(find.byKey(const Key('editor')), findsOneWidget);
      oldAnswer();
      oldEdit();
      await _settle(tester);
      expect(Storage.srsTotalReviewed(), 0);
      expect(find.byKey(const Key('editor')), findsOneWidget);
      await CustomPackService.save(
        CustomPack.manual(
          id: _packId,
          name: 'Editing',
          words: [
            word.copyWithEditable(translationEn: 'edited meaning'),
            ..._words.skip(1),
          ],
        ),
      );
      Navigator.of(tester.element(find.byKey(const Key('editor')))).pop();
      await _settle(tester);
      oldAnswer();
      oldEdit();
      await _settle(tester);
      expect(find.byKey(const Key('editor')), findsNothing);
      expect(Storage.srsTotalReviewed(), 0);
      expect(
        CustomPackService.getById(_packId)!.words.first.translationEn,
        'edited meaning',
      );
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await _settle(tester);
      expect(tester.widget<FlipCard>(find.byType(FlipCard)).flipped, isTrue);
      expect(find.text('edited meaning'), findsOneWidget);
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
      await _settle(tester);
      expect(Storage.srsCard(word.korean)?.reviewCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('matching new selection clears the previous wrong highlight', (
    tester,
  ) async {
    await _pump(tester, _Flow.matching);
    final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
    final wrongLabel = _words[1].translationEn;
    String? feedback() => tester
        .widgetList<Semantics>(find.byType(Semantics))
        .singleWhere(
          (widget) =>
              widget.properties.label == wrongLabel &&
              widget.properties.button == true,
        )
        .properties
        .value;
    _tileAction(tester, _words.first.korean)();
    await tester.pump();
    _tileAction(tester, wrongLabel)();
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
    expect(feedback(), t.statsWrong);
    _tileAction(tester, _words[1].korean)();
    await tester.pump(const Duration(milliseconds: 500));
    expect(feedback(), isNot(t.statsWrong));
    expect(Storage.srsCard(_words.first.korean)?.reviewCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final flow in _Flow.values) {
    testWidgets(
      '${flow.name} replay admits fresh evidence and ignores old result navigation',
      (tester) async {
        await _pump(tester, flow, pushed: true);
        await _completeRound(tester, flow);
        final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
        final oldAgain = _button(
          tester,
          flow == _Flow.play ? t.customPackResultAgain : t.quizAgain,
        );
        final oldBack = _button(
          tester,
          flow == _Flow.matching ? t.btnClose : t.customPackResultBack,
        );
        final xp = switch (flow) {
          _Flow.play => 0,
          _Flow.typing => 20,
          _ => 16,
        };
        expect(Storage.xp, xp);
        expect(Storage.srsTotalReviewed(), 4);
        oldAgain();
        await _settle(tester);
        oldAgain();
        oldBack();
        await _settle(tester);
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byKey(const Key('wordbook-destination')), findsNothing);
        await _completeRound(tester, flow);
        expect(Storage.xp, xp * 2);
        expect(Storage.srsTotalReviewed(), 4);
        for (final word in _words) {
          expect(Storage.srsCard(word.korean)?.reviewCount, 2);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
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
            final word = await _answer(tester, flow);
            await _until(tester, find.byType(AppError));
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
            expect(Storage.srsCard(word)?.reviewCount, 1);
            expect(Storage.studyLogIdsFor(Storage.todayIso()), contains(word));
            expect(Storage.wrongCountOf(word), 1);
            await tester.pumpWidget(const SizedBox());
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
    for (final retirement in ['exit', 'unmount', 'reset', 'pop']) {
      testWidgets('${flow.name} $retirement while judgment save is pending', (
        tester,
      ) async {
        await _pump(tester, flow, pushed: retirement == 'pop');
        final release = Completer<void>();
        platform
          ..rejectKey = 'kl_srs_v1'
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        final word = await _answer(tester, flow);
        await _until(tester, find.byType(AppLoading));
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
          expect(Storage.srsCard(word), isNull);
        }
        expect(Storage.wrongCountOf(word), 0);
        expect(Storage.xp, 0);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('${flow.name} popped route rejects retained judgment', (
      tester,
    ) async {
      await _pump(tester, flow, pushed: true);
      final action = await _acceptedAction(tester, flow);
      final context = tester.element(find.byType(SoriStudyFrame));
      Navigator.of(context).pop();
      expect(context.mounted, isTrue);
      action();
      await tester.pump();
      expect(Storage.srsTotalReviewed(), 0);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('${flow.name} stale input cannot judge the next presentation', (
      tester,
    ) async {
      await _pump(tester, flow);
      final oldAction = await _acceptedAction(tester, flow);
      oldAction();
      await _settle(tester);
      VoidCallback? oldNext;
      if (flow == _Flow.quiz || flow == _Flow.typing) {
        final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
        oldNext = tester
            .widgetList<SoriButton>(find.byType(SoriButton))
            .singleWhere((button) => button.label == t.btnNext)
            .onTap!;
        oldNext();
        await tester.pump();
      } else if (flow == _Flow.matching) {
        _tileAction(tester, _words[1].korean)();
        await tester.pump();
      }
      oldAction();
      oldNext?.call();
      await _settle(tester);
      expect(Storage.srsTotalReviewed(), 1);
      expect(Storage.xp, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
    testWidgets('${flow.name} rejected judgment waits for recovery', (
      tester,
    ) async {
      await _pump(tester, flow);
      platform.rejectKey = 'kl_srs_v1';
      final word = await _answer(tester, flow);
      await _until(tester, find.byType(AppError));
      expect(Storage.srsTotalReviewed(), 0);
      expect(Storage.xp, 0);
      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _settle(tester);
      expect(find.byType(AppError), findsNothing);
      expect(find.byType(AppLoading), findsNothing);
      expect(Storage.srsCard(word)?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), contains(word));
      expect(Storage.wrongCountOf(word), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

VoidCallback _tileAction(WidgetTester tester, String label) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .singleWhere(
      (widget) =>
          widget.properties.label == label && widget.properties.button == true,
    )
    .properties
    .onTap!;

Future<VoidCallback> _acceptedAction(WidgetTester tester, _Flow flow) async {
  switch (flow) {
    case _Flow.play:
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      return tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onHard!;
    case _Flow.quiz:
      return tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((choice) => !choice.isCorrect)
          .onSelected!;
    case _Flow.typing:
      await tester.enterText(find.byType(SoriTextField), '틀린답');
      await tester.pump();
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      return tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .singleWhere((button) => button.label == t.btnSubmit)
          .onTap!;
    case _Flow.matching:
      _tileAction(tester, _words.first.korean)();
      await tester.pump();
      return _tileAction(tester, _words[1].translationEn);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Flow flow, {
  bool pushed = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final screen = switch (flow) {
    _Flow.play => const CustomPackPlayScreen(packId: _packId),
    _Flow.quiz => const CustomPackQuizScreen(packId: _packId),
    _Flow.typing => CustomPackTypingScreen(packId: _packId, speaker: (_) {}),
    _Flow.matching => const CustomPackMatchingScreen(packId: _packId),
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
      routes: {
        '/custom_pack/edit': (_) =>
            const Scaffold(body: SizedBox(key: Key('editor'))),
        '/my_words': (_) => const SizedBox(key: Key('wordbook-destination')),
      },
      home: pushed ? const SizedBox() : wrapped,
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

Future<String> _answer(WidgetTester tester, _Flow flow) async {
  late String word;
  switch (flow) {
    case _Flow.play:
      word = _words.first.korean;
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
    case _Flow.quiz:
      word = _words
          .firstWhere((word) => find.text(word.korean).evaluate().isNotEmpty)
          .korean;
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .firstWhere((choice) => !choice.isCorrect)
          .onSelected!();
    case _Flow.typing:
      word = _words
          .firstWhere(
            (word) => find.text(word.translationEn).evaluate().isNotEmpty,
          )
          .korean;
      await tester.enterText(find.byType(SoriTextField), '틀린답');
      await tester.pump();
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .singleWhere((button) => button.label == t.btnSubmit)
          .onTap!();
    case _Flow.matching:
      word = _words.first.korean;
      await tester.tap(find.text(word));
      await tester.pump();
      await tester.tap(find.text(_words[1].translationEn));
  }
  await tester.pump();
  return word;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

VoidCallback _button(WidgetTester tester, String label) => tester
    .widgetList<SoriButton>(find.byType(SoriButton))
    .singleWhere((button) => button.label == label)
    .onTap!;

Future<void> _completeRound(WidgetTester tester, _Flow flow) async {
  for (var i = 0; i < _words.length; i++) {
    switch (flow) {
      case _Flow.play:
        tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
        await tester.pump();
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
      case _Flow.quiz:
        tester
            .widgetList<QuizChoice>(find.byType(QuizChoice))
            .singleWhere((choice) => choice.isCorrect)
            .onSelected!();
      case _Flow.typing:
        final word = _words.firstWhere(
          (word) => find.text(word.translationEn).evaluate().isNotEmpty,
        );
        await tester.enterText(find.byType(SoriTextField), word.korean);
        await tester.pump();
        final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
        _button(tester, t.btnSubmit)();
      case _Flow.matching:
        final word = _words[i];
        _tileAction(tester, word.korean)();
        await tester.pump();
        _tileAction(tester, word.translationEn)();
    }
    await _settle(tester);
    if (flow == _Flow.quiz || flow == _Flow.typing) {
      final t = AppL10n.of(tester.element(find.byType(SoriStudyFrame)));
      _button(tester, t.btnNext)();
      await _settle(tester);
    }
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}
