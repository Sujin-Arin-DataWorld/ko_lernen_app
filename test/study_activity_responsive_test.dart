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
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
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
    });
    await Storage.init();
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
