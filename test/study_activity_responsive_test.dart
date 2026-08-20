import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_header.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _packId = 'responsive-study-pack';

const _packWords = <ExtractedWord>[
  ExtractedWord(
    korean: '도서관',
    romanization: 'doseogwan',
    posDe: 'N.',
    translationDe: 'Bibliothek',
    translationEn: 'library',
    exampleKorean: '도서관에서 공부해요.',
    exampleDe: 'Ich lerne in der Bibliothek.',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '공부하다',
    romanization: 'gongbuhada',
    posDe: 'V.',
    translationDe: 'lernen',
    translationEn: 'to study',
    exampleKorean: '매일 공부해요.',
    exampleDe: 'Ich lerne jeden Tag.',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '친구',
    romanization: 'chingu',
    posDe: 'N.',
    translationDe: 'Freundschaftsperson',
    translationEn: 'friend',
    exampleKorean: '친구를 만나요.',
    exampleDe: 'Ich treffe einen Freund.',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '천천히',
    romanization: 'cheoncheonhi',
    posDe: 'Adv.',
    translationDe: 'langsam und aufmerksam',
    translationEn: 'slowly and carefully',
    exampleKorean: '천천히 말해 주세요.',
    exampleDe: 'Bitte sprechen Sie langsam.',
    savedToPackId: null,
  ),
];

const _cloze = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ___ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich aufmerksam in der Bibliothek.',
  en: 'Today I study carefully in the library.',
  distractors: ['운동을', '요리를', '독서를'],
);

const _wordWebItem = WordRelationQuizItem(
  kind: WordRelationKind.antonym,
  clusterId: 'big',
  sourceKo: '크다',
  promptDe: 'Welches Wort bedeutet das genaue Gegenteil?',
  promptEn: 'Which word has the exact opposite meaning?',
  answerKo: '작다',
  options: ['작다', '사이즈', '조금', '커다랗다'],
);

const _satz = SatzSentence(
  level: 'a1',
  targetKo: '오늘은 도서관에서 천천히 공부해요.',
  promptDe: 'Heute lerne ich langsam und aufmerksam in der Bibliothek.',
  promptEn: 'Today I study slowly and carefully in the library.',
  distractors: ['친구와'],
  vocabKo: '공부하다',
);

const _speedWords = <Vocab>[
  Vocab(
    korean: '공부하다',
    romanization: 'gongbuhada',
    german: 'langsam und aufmerksam lernen',
    english: 'study slowly and carefully',
    level: 'a1',
    posDe: 'Verb',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '도서관',
    romanization: 'doseogwan',
    german: 'öffentliche Bibliothek',
    english: 'public library',
    level: 'a1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '천천히',
    romanization: 'cheoncheonhi',
    german: 'langsam und sorgfältig',
    english: 'slowly and carefully',
    level: 'a1',
    posDe: 'Adverb',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
  Vocab(
    korean: '친구',
    romanization: 'chingu',
    german: 'befreundete Person',
    english: 'friend and companion',
    level: 'a1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpPlay': true,
      'kl_tut_cpQuiz': true,
      'kl_tut_cpMatching': true,
      'kl_tut_cpTyping': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
      'kl_tut_chosung': true,
      'kl_tut_kkeunmari': true,
      'kl_tut_silben_kreuz': true,
    });
    await Storage.init();
    await DataLoader.loadVocab();
    await KkeunmariEngine.load();
    await SilbenPuzzleLoader.load();
    await CustomPackService.save(
      CustomPack.manual(
        id: _packId,
        name: 'Meine ausführliche persönliche Lernsammlung',
        words: _packWords,
      ),
    );
  });

  final activities = <String, Widget Function()>{
    'grammar choice': () => GrammarChoiceQuizScreen(
      initialLevel: 'A1',
      randomSeed: 5,
      maxQuestions: 1,
      grammarLoader: () async => _grammarDeck(),
    ),
    'hard choice': () => HardChoiceQuizScreen(
      deck: const [
        Vocab(
          korean: '공부하다',
          romanization: 'gongbuhada',
          german: 'aufmerksam lernen',
          level: 'A1',
          posDe: 'Verb',
          exampleKorean: '',
          exampleGerman: '',
          topic: 'test',
        ),
      ],
      vocabLoader: () async => const [],
    ),
    'word web': () => WordWebQuizScreen(
      clusters: const [],
      quizBuilder: (_) => const [_wordWebItem],
    ),
    'custom pack cards': () => const CustomPackPlayScreen(packId: _packId),
    'custom pack quiz': () => const CustomPackQuizScreen(packId: _packId),
    'custom pack matching': () =>
        const CustomPackMatchingScreen(packId: _packId),
    'custom pack typing': () => const CustomPackTypingScreen(packId: _packId),
    'daily challenge': () => const DailyChallengeScreen(items: [_cloze]),
    'cloze game': () => const ClozeGameScreen(items: [_cloze]),
    'sentence arcade': () => const SatzArcadeScreen(items: [_satz]),
    'speed match': () => const SpeedMatchScreen(items: _speedWords),
    'initial consonant quiz': () => const ChosungQuizScreen(),
    'word chain': () => const KkeunmariScreen(),
    'syllable crossword': () => const SilbenKreuzScreen(),
  };

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
    ]) {
      for (final activity in activities.entries) {
        testWidgets('${activity.key} stays usable in ${locale.languageCode} '
            '@ ${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
            '×${viewport.textScale}', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;

          await tester.pumpWidget(
            _host(
              locale: locale,
              textScale: viewport.textScale,
              child: activity.value(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(SoriStudyFrame), findsOneWidget);
          final readyFinder = _readyFinderFor(activity.key);
          if (readyFinder != null) {
            await _pumpUntilVisible(tester, readyFinder);
            expect(readyFinder, findsOneWidget);
          }
          final adaptiveBody = find.byType(SoriAdaptiveStudyBody);
          if (adaptiveBody.evaluate().isNotEmpty) {
            expect(
              find.descendant(
                of: adaptiveBody,
                matching: find.byType(SingleChildScrollView),
              ),
              findsWidgets,
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'speed match exposes complete instructional and vocabulary text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);

      await tester.pumpWidget(
        _host(
          locale: const Locale('de'),
          textScale: 2,
          child: const SpeedMatchScreen(items: _speedWords),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final l10n = AppL10n.of(tester.element(find.byType(SpeedMatchScreen)));
      final instruction = tester.widget<Text>(
        find.text(l10n.speedMatchInstruction),
      );
      final translation = tester.widget<Text>(
        find.text('langsam und aufmerksam lernen'),
      );

      expect(instruction.maxLines, isNull);
      expect(instruction.overflow, isNull);
      expect(translation.maxLines, isNull);
      expect(translation.overflow, isNull);
      expect(find.bySemanticsLabel(l10n.speedMatchInstruction), findsOneWidget);
      expect(
        find.bySemanticsLabel('langsam und aufmerksam lernen'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

Finder? _readyFinderFor(String activity) {
  return switch (activity) {
    'initial consonant quiz' || 'word chain' => find.byType(HanokHeader),
    'syllable crossword' => find.byKey(const ValueKey('silben-level-A1')),
    _ => null,
  };
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
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

List<Grammar> _grammarDeck() => const [
  Grammar(
    id: 'grammar_a1_one',
    pattern: '-아요/어요',
    level: 'A1',
    typeDe: 'Aussageform',
    explanationDe: 'Höfliche Aussage in der Gegenwart.',
    exampleKorean: '매일 공부해요.',
    exampleGerman: 'Ich lerne jeden Tag aufmerksam.',
    note: '',
    typeEn: 'Statement form',
    explanationEn: 'Polite present-tense statement.',
    exampleEn: 'I study carefully every day.',
    exampleGermanFocus: 'lerne',
    exampleEnFocus: 'study',
    quizEnabled: true,
    quizDistractorIds: [
      'grammar_a1_two',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  Grammar(
    id: 'grammar_a1_two',
    pattern: '-고 싶어요',
    level: 'A1',
    typeDe: 'Wunsch',
    explanationDe: 'Drückt einen Wunsch aus.',
    exampleKorean: '한국에 가고 싶어요.',
    exampleGerman: 'Ich möchte nach Korea reisen.',
    note: '',
    typeEn: 'Wish',
    explanationEn: 'Expresses a wish.',
    exampleEn: 'I want to travel to Korea.',
    exampleGermanFocus: 'möchte',
    exampleEnFocus: 'want',
    quizEnabled: true,
    quizDistractorIds: [
      'grammar_a1_one',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  Grammar(
    id: 'grammar_a1_three',
    pattern: '-(으)세요',
    level: 'A1',
    typeDe: 'Bitte',
    explanationDe: 'Formuliert eine höfliche Bitte.',
    exampleKorean: '천천히 말해 주세요.',
    exampleGerman: 'Bitte sprechen Sie langsam.',
    note: '',
    typeEn: 'Request',
    explanationEn: 'Makes a polite request.',
    exampleEn: 'Please speak slowly.',
    exampleGermanFocus: 'Bitte',
    exampleEnFocus: 'Please',
    quizEnabled: true,
    quizDistractorIds: ['grammar_a1_one', 'grammar_a1_two', 'grammar_a1_four'],
  ),
  Grammar(
    id: 'grammar_a1_four',
    pattern: '-지 않아요',
    level: 'A1',
    typeDe: 'Verneinung',
    explanationDe: 'Verneint eine Handlung oder Eigenschaft.',
    exampleKorean: '오늘은 일하지 않아요.',
    exampleGerman: 'Heute arbeite ich nicht.',
    note: '',
    typeEn: 'Negation',
    explanationEn: 'Negates an action or quality.',
    exampleEn: 'I do not work today.',
    exampleGermanFocus: 'nicht',
    exampleEnFocus: 'not',
    quizEnabled: true,
    quizDistractorIds: ['grammar_a1_one', 'grammar_a1_two', 'grammar_a1_three'],
  ),
];
