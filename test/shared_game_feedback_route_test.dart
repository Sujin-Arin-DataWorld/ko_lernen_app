import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _packName =
    'private-name@example.com-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

const _cloze = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ___ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich.',
  en: 'Today I study.',
  distractors: ['운동을', '요리를', '독서를'],
);

const _satz = SatzSentence(
  level: 'a1',
  targetKo: '가요',
  promptDe: 'Ich gehe.',
  promptEn: 'I go.',
  distractors: [],
  vocabKo: '가요',
);

const _speedWords = [
  Vocab(
    korean: '하나',
    romanization: 'hana',
    german: 'eins',
    level: 'a1',
    posDe: 'Zahl',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '둘',
    romanization: 'dul',
    german: 'zwei',
    level: 'a1',
    posDe: 'Zahl',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
];

const _packWords = [
  ExtractedWord(
    korean: '하나',
    romanization: 'hana',
    posDe: 'Zahl',
    translationDe: 'eins',
    translationEn: 'one',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '둘',
    romanization: 'dul',
    posDe: 'Zahl',
    translationDe: 'zwei',
    translationEn: 'two',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '셋',
    romanization: 'set',
    posDe: 'Zahl',
    translationDe: 'drei',
    translationEn: 'three',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '넷',
    romanization: 'net',
    posDe: 'Zahl',
    translationDe: 'vier',
    translationEn: 'four',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpQuiz': true,
      'kl_tut_cpMatching': true,
      'kl_tut_cpTyping': true,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: 'personal-pack',
        name: _packName,
        words: _packWords,
      ),
    );
  });

  testWidgets('Cloze terminal route exposes feedback context', (tester) async {
    await tester.pumpWidget(_wrap(const ClozeGameScreen(items: [_cloze])));
    await tester.pump();

    await _tapCorrectChoice(tester);
    await tester.pump(const Duration(milliseconds: 1101));

    _expectTerminalFeedback(tester);
  });

  testWidgets('Daily Challenge terminal route exposes feedback context', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const DailyChallengeScreen(items: [_cloze])));
    await tester.pump();

    await _tapCorrectChoice(tester);
    await tester.pump(const Duration(milliseconds: 1101));

    _expectTerminalFeedback(tester);
  });

  testWidgets('Satz Arcade terminal route exposes feedback context', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SatzArcadeScreen(items: [_satz])));
    await tester.pump();

    final answerTile = find.text('가요');
    await tester.ensureVisible(answerTile);
    await tester.pump();
    await tester.tap(answerTile);
    await tester.pump();
    await tester.ensureVisible(find.text('Antwort prüfen'));
    await tester.pump();
    await tester.tap(find.text('Antwort prüfen'));
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();

    _expectTerminalFeedback(tester);
  });

  testWidgets('Speed Match terminal route exposes feedback context', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SpeedMatchScreen(items: _speedWords)));
    await tester.pump();

    await tester.tap(find.text('하나'));
    await tester.tap(find.text('eins'));
    await tester.pump();

    _expectTerminalFeedback(tester);
  });

  testWidgets('custom quiz terminal feedback redacts a personal pack name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CustomPackQuizScreen(packId: 'personal-pack')),
    );
    await tester.pump();

    for (var i = 0; i < _packWords.length; i++) {
      await _tapCorrectChoice(tester);
      await tester.pump(const Duration(milliseconds: 901));
    }

    final card = _expectTerminalFeedback(tester);
    final context = card.feedbackContext!;
    expect(context.contentLabel, 'custom_wordbook');
    final serialized = context.toWire().values.whereType<String>();
    for (final personalText in [
      _packName,
      for (final word in _packWords) ...[
        word.korean,
        word.translationDe,
        word.translationEn,
      ],
    ]) {
      expect(
        serialized.every((value) => !value.contains(personalText)),
        isTrue,
      );
    }
    final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
    await _expectMyWordsReturn(tester, t.customPackResultBack);
  });

  testWidgets('custom matching terminal route exposes feedback context', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CustomPackMatchingScreen(packId: 'personal-pack')),
    );
    await tester.pump();

    for (final word in _packWords) {
      await tester.tap(find.text(word.korean));
      await tester.pump();
      await tester.tap(find.text(word.translationDe));
      await tester.pump();
    }

    _expectTerminalFeedback(tester);
    final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
    await _expectMyWordsReturn(tester, t.btnClose);
  });

  for (final failSecond in [false, true]) {
    testWidgets(
      'matching retry clears prior reward while next write is ${failSecond ? 'failed' : 'delayed'}',
      (tester) async {
        final second = Completer<GameOutcome>();
        final awarded = <int>[];
        await tester.pumpWidget(
          _wrap(
            CustomPackMatchingScreen(
              packId: 'personal-pack',
              recordResult: ({required gameId, required xp}) {
                awarded.add(xp);
                return awarded.length == 1
                    ? Future.value(GameOutcome(xpGained: xp))
                    : second.future;
              },
            ),
          ),
        );
        await tester.pump();
        Future<void> finish() async {
          for (final word in _packWords) {
            await tester.tap(find.text(word.korean));
            await tester.pump();
            await tester.tap(find.text(word.translationDe));
            await tester.pump();
          }
        }

        await finish();
        expect(
          tester.widget<GameOverCard>(find.byType(GameOverCard)).xpGained,
          _packWords.length * 4,
        );
        final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
        await tester.tap(find.text(t.quizAgain));
        await tester.pump();
        await tester.tap(find.text(_packWords.first.korean));
        await tester.pump();
        await tester.tap(find.text(_packWords.last.translationDe));
        await tester.pump(const Duration(milliseconds: 451));
        await finish();
        expect(awarded, [_packWords.length * 4, _packWords.length * 3]);
        var card = tester.widget<GameOverCard>(find.byType(GameOverCard));
        expect(card.xpGained, 0);
        expect(card.outcome, isNull);
        expect(card.rewardReady, isFalse);
        expect(find.text('+0 XP'), findsNothing);
        if (failSecond) {
          second.completeError(StateError('persistence failed'));
        } else {
          second.complete(GameOutcome(xpGained: awarded.last));
        }
        await tester.pump();
        card = tester.widget<GameOverCard>(find.byType(GameOverCard));
        expect(card.xpGained, failSecond ? 0 : _packWords.length * 3);
        if (failSecond) {
          expect(card.outcome, isNull);
          expect(card.rewardReady, isFalse);
          expect(find.text('+0 XP'), findsNothing);
        } else {
          expect(card.rewardReady, isTrue);
          await tester.pump(const Duration(milliseconds: 1000));
          expect(find.text('+${_packWords.length * 3} XP'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      },
    );
  }
  testWidgets('custom typing terminal route exposes feedback context', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CustomPackTypingScreen(packId: 'personal-pack')),
    );
    await tester.pump();

    for (var i = 0; i < _packWords.length; i++) {
      final word = _packWords.singleWhere(
        (candidate) => find.text(candidate.translationDe).evaluate().isNotEmpty,
      );
      await tester.enterText(find.byType(TextField), word.korean);
      await tester.tap(find.text('Prüfen'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pump();
    }

    _expectTerminalFeedback(tester);
    final t = AppL10n.of(tester.element(find.byType(GameOverCard)));
    await _expectMyWordsReturn(tester, t.customPackResultBack);
  });
}

Future<void> _tapCorrectChoice(WidgetTester tester) async {
  final choice = find.byWidgetPredicate(
    (widget) => widget is QuizChoice && widget.isCorrect && !widget.revealed,
  );
  // The cloze and daily screens finish their first state update from initState.
  // Wait for the rendered choice rather than assuming one pump is enough.
  for (var attempt = 0; attempt < 20 && choice.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(choice, findsOneWidget);
  await tester.ensureVisible(choice);
  await tester.pump();
  await tester.tap(choice);
  await tester.pump();
}

GameOverCard _expectTerminalFeedback(WidgetTester tester) {
  final cardFinder = find.byType(GameOverCard);
  expect(cardFinder, findsOneWidget);
  final card = tester.widget<GameOverCard>(cardFinder);
  expect(card.feedbackContext, isNotNull);
  expect(find.byType(ContentFeedbackCard), findsOneWidget);
  return card;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        body: Text(
          settings.name ?? '',
          key: ValueKey('generated-route-${settings.name}'),
        ),
      ),
    ),
    home: ContentFeedbackControllerScope(
      featureGate: const TesterFeedbackFeatureGate(enabled: true),
      submitFeedback: _inertFeedbackSubmitter,
      resumePending: () async => const ContentFeedbackResumeResult(),
      child: child,
    ),
  );
}

Future<void> _expectMyWordsReturn(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(
    find.byKey(const ValueKey('generated-route-/my_words')),
    findsOneWidget,
  );
  expect(
    ModalRoute.of(
      tester.element(find.byKey(const ValueKey('generated-route-/my_words'))),
    )?.settings.name,
    '/my_words',
  );
}

Future<ContentFeedbackSubmitResult> _inertFeedbackSubmitter(
  ContentFeedbackContext context,
  ContentFeedbackDraft draft,
) async => const ContentFeedbackSubmitResult(
  status: ContentFeedbackSubmitStatus.disabled,
);
