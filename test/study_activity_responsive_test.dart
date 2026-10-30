import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
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
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/silben_puzzle_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/real_fonts.dart';

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

const _listeningScenario = Scenario(
  id: 'responsive-listening',
  level: LearnerLevel.a1,
  emoji: '🎧',
  register: Register.polite,
  title: LocalizedText(
    ko: '도서관에서 천천히 말하기',
    de: 'Aufmerksam in der Bibliothek zuhören',
    en: 'Listening carefully in the library',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(
      speaker: 'teacher',
      ko: '도서관에서는 천천히 말해 주세요.',
      de: 'Bitte sprechen Sie in der Bibliothek langsam und deutlich.',
      en: 'Please speak slowly and clearly in the library.',
    ),
  ],
  quests: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

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
      'kl_tut_listening_play': true,
      'kl_tut_review': true,
      'kl_tut_smalltalk': true,
      'kl_tut_grammar': true,
      'kl_tut_hangul': true,
      'kl_tut_hangulWriteRules': true,
    });
    await Storage.init();
    await DataLoader.loadVocab();
    await DataLoader.loadGrammar();
    await KkeunmariEngine.load();
    await SilbenPuzzleLoader.load();
    await SmalltalkLoader.load();
    await CustomPackService.save(
      CustomPack.manual(
        id: _packId,
        name: 'Meine ausführliche persönliche Lernsammlung',
        words: _packWords,
      ),
    );
  });

  final activities = <String, Widget Function()>{
    'grammar deck': () => const GrammarScreen(),
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
    'listening player': () =>
        const ListeningPlayScreen(scenario: _listeningScenario),
    'review session': () => const ReviewSessionScreen(deck: _speedWords),
    'small talk': () => const SmalltalkScreen(),
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

  // Representative focus screens at the window sizes used for Pad 6 QA.
  // The full activity inventory above remains the narrow-screen regression.
  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(600, 800), textScale: 1),
      (size: Size(720, 1152), textScale: 1),
      (size: Size(720, 1152), textScale: 2),
      (size: Size(1152, 720), textScale: 1),
      (size: Size(1280, 900), textScale: 1),
    ]) {
      for (final name in const [
        'grammar deck',
        'cloze game',
        'speed match',
        'syllable crossword',
        'listening player',
        'word chain',
      ]) {
        testWidgets('Pad focus $name ${locale.languageCode} '
            '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
            '×${viewport.textScale}', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;
          await tester.pumpWidget(
            _host(
              locale: locale,
              textScale: viewport.textScale,
              child: activities[name]!(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(SoriStudyFrame), findsOneWidget);
          final ready = _readyFinderFor(name);
          if (ready != null) {
            await _pumpUntilVisible(tester, ready);
            expect(ready, findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          if (name == 'cloze game' &&
              viewport.size == const Size(720, 1152) &&
              viewport.textScale == 1) {
            expect(
              find.byKey(const ValueKey('cloze-focus-group')),
              findsOneWidget,
            );
            final promptBottom = tester
                .getRect(find.byType(ClozePromptCard))
                .bottom;
            final optionsTop = tester
                .getRect(find.byType(ClozeOptionsList))
                .top;
            expect(optionsTop - promptBottom, inInclusiveRange(0, 80));
          }
        });
      }
    }
  }

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets('Pad word chain submit stays reachable above keyboard '
        'in ${locale.languageCode}', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(720, 1152);
      await tester.pumpWidget(
        _host(
          locale: locale,
          textScale: 1,
          keyboardInset: 360,
          child: const KkeunmariScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('kkeunmari-gameplay')),
      );
      final t = AppL10n.of(tester.element(find.byType(KkeunmariScreen)));
      final submit = find.text(t.kkeunmariSubmit);
      await tester.ensureVisible(submit);
      await tester.pump();
      expect(submit, findsOneWidget);
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(1152 - 360));
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(1024, 768), textScale: 1),
    ]) {
      testWidgets('Hangul tabs stay usable in ${locale.languageCode} '
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
            child: HangulScreen(textPrefetcher: (_) async {}),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        final semantics = tester.ensureSemantics();
        await tester.pump();
        _expectNativeHangulChrome(tester);
        for (var index = 0; index < 3; index++) {
          final tab = find.byKey(ValueKey('hangul-tab-$index'));
          await tester.ensureVisible(tab);
          await tester.pumpAndSettle();
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(tester.widget<CAtelierButton>(tab).selected, isTrue);
          expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
        }
        final paperOwner = find.ancestor(
          of: find.byType(TabBarView),
          matching: find.byType(CAtelierPaper),
        );
        expect(paperOwner, findsOneWidget);
        final paper = tester.getSize(paperOwner);
        expect(paper.width, lessThanOrEqualTo(viewport.size.width));
        expect(
          paper.width,
          greaterThanOrEqualTo(viewport.size.width.clamp(0, 1100) - 48),
        );
        semantics.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('Hangul overview keeps complete section hierarchy in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        final semantics = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.size;

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: HangulScreen(textPrefetcher: (_) async {}),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        final t = AppL10n.of(tester.element(find.byType(HangulScreen)));
        final discover = find.text(t.atelierDiscover);
        expect(
          tester
              .getSemantics(discover)
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        for (final item in [
          (t.hangulChipConsonants, '${t.hangulChipConsonants} · 19', 19),
          (t.hangulChipVowels, '${t.hangulChipVowels} · 15', 15),
          (t.hangulChipSyllables, '${t.atelierStructure} · 16', 16),
        ]) {
          final action = _nativeHangulButton(item.$2);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.widget<Text>(find.text(item.$2)).maxLines, isNull);
          expect(tester.widget<Text>(find.text(item.$2)).overflow, isNull);
          await tester.tap(action);
          await tester.pumpAndSettle();
          final title = find.text('${item.$1} (${item.$3})');
          expect(title, findsOneWidget);
          expect(tester.widget<Text>(title).maxLines, isNull);
          expect(tester.widget<Text>(title).overflow, isNull);
          expect(
            tester
                .getSemantics(title)
                .getSemanticsData()
                .flagsCollection
                .isHeader,
            isTrue,
          );
          final catalog = find.descendant(
            of: find.byType(Dialog),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CAtelierButton &&
                  (w.key is ValueKey<String>) &&
                  ((w.key! as ValueKey<String>).value.startsWith(
                    'hangul-catalog-',
                  )),
            ),
          );
          expect(catalog, findsNWidgets(item.$3));
          Navigator.of(tester.element(find.byType(Dialog))).pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets('Hangul card modes keep full labels and 48dp controls in '
        '${locale.languageCode} at 200% text', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);

      await tester.pumpWidget(
        _host(
          locale: locale,
          textScale: 2,
          child: HangulScreen(textPrefetcher: (_) async {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final t = AppL10n.of(tester.element(find.byType(HangulScreen)));
      final tab = find.byKey(const ValueKey('hangul-tab-1'));
      await tester.ensureVisible(tab);
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();
      final modeSelector = find.byKey(const Key('hangul-cards-selection'));
      await tester.ensureVisible(modeSelector);
      await tester.pumpAndSettle();
      expect(tester.getSize(modeSelector).height, greaterThanOrEqualTo(48));
      await tester.tap(modeSelector);
      await tester.pumpAndSettle();
      for (final index in [0, 1, 2]) {
        final button = find.byKey(ValueKey('hangul-cards-mode-$index'));
        final widget = tester.widget<CAtelierButton>(button);
        final label = find.descendant(
          of: button,
          matching: find.text(widget.label),
        );
        expect(widget.onTap, isNotNull);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(tester.widget<Text>(label).maxLines, isNull);
        expect(tester.widget<Text>(label).overflow, isNull);
      }
      Navigator.of(tester.element(find.byType(Dialog))).pop();
      await tester.pumpAndSettle();
      for (final control in [
        modeSelector,
        find.byKey(const Key('hangul-cards-filter')),
        find.byKey(const Key('hangul-card-like')),
        _nativeHangulButton(t.cHangulListen),
        find.byKey(const Key('hangul-finish-cards')),
      ]) {
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'listening bubble actions expose button meaning and 48dp hit areas',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);

      await tester.pumpWidget(
        _host(
          locale: const Locale('de'),
          textScale: 1,
          child: ListeningPlayScreen(
            scenario: _listeningScenario,
            speechPlayer: (text, {required voice}) async => false,
            stopPlayer: () async {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final l10n = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
      await tester.ensureVisible(find.text(l10n.listeningDialogueStart));
      await tester.tap(find.text(l10n.listeningDialogueStart));
      await tester.pump();
      // §W-A2 재조사(실측): 첫 대사(교사, TTS 필요)가 재생 실패 카드로
      // 잠깐 보였다가 대화 버블로 바뀌는 데 300ms 로는 부족하고 1.3s 는
      // 충분했다(find.bySemanticsLabel 로 실측: 0 → 0 → 1). 폭/높이
      // 문제가 아니라 정착 시간 문제 — pumpAndSettle 로 완전히 정착시킨다.
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l10n.listeningReplay),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      final replayTarget = find.bySemanticsLabel(l10n.listeningReplay);
      final translationTarget = find.bySemanticsLabel(
        l10n.listeningShowTranslation,
      );

      expect(replayTarget, findsOneWidget);
      expect(translationTarget, findsOneWidget);
      for (final target in [replayTarget, translationTarget]) {
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('listening completion stays usable in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.size;

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: ListeningPlayScreen(
              scenario: _listeningScenario,
              speechPlayer: (text, {required voice}) async => true,
              stopPlayer: () async {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        final l10n = AppL10n.of(
          tester.element(find.byType(ListeningPlayScreen)),
        );
        await tester.ensureVisible(find.text(l10n.listeningDialogueStart));
        await tester.tap(find.text(l10n.listeningDialogueStart));
        await tester.pump();
        await tester.pump();
        await _pumpUntilVisible(tester, find.text(l10n.listeningReviewCta));
        await _pumpUntilCondition(
          tester,
          () => Storage.completedScenarios.contains(_listeningScenario.id),
        );

        expect(find.byType(SoriContentFeed), findsNothing);
        expect(find.text(l10n.listeningCompleteTitle), findsOneWidget);
        expect(Storage.completedScenarios, contains(_listeningScenario.id));
        expect(Storage.xp, 40);
        for (final label in [
          l10n.listeningReviewCta,
          l10n.listeningBackToScroll,
        ]) {
          final action = find.ancestor(
            of: find.text(label),
            matching: find.byType(SoriButton),
          );
          expect(action, findsOneWidget);
          await tester.ensureVisible(action);
          expect(tester.getRect(action).size.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
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
    'initial consonant quiz' => find.byType(SoriChromeRow),
    'word chain' => find.byKey(const ValueKey('kkeunmari-gameplay')),
    'syllable crossword' => find.byType(SoriChromeRow),
    'listening player' => find.byKey(
      const ValueKey('listening-dialogue-start'),
    ),
    'review session' || 'small talk' => find.byType(SoriContentFeed),
    'grammar deck' => find.byKey(const ValueKey('grammar-filter-row')),
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

Future<void> _pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 40,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (condition()) {
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue, reason: 'Expected async state did not settle.');
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
  double keyboardInset = 0,
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
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: SoriTypeScale(
          child: RepaintBoundary(
            key: const ValueKey('pad-study-evidence'),
            child: appChild!,
          ),
        ),
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

Finder _nativeHangulButton(String label) => find.byWidgetPredicate(
  (widget) => widget is CAtelierButton && widget.label == label,
);

void _expectNativeHangulChrome(WidgetTester tester) {
  expect(find.byKey(const ValueKey('hangul-atelier-header')), findsOneWidget);
  expect(find.byType(CAtelierTabs), findsOneWidget);
  expect(find.byType(TabBarView), findsOneWidget);
  expect(find.byType(SoriStudyFrame), findsOneWidget);
  expect(
    tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave,
    isNotNull,
  );
  for (final action in [
    find.byType(SoriCloseAction),
    find.byType(SoriHomeAction),
    find.byKey(const Key('hangul-settings')),
  ]) {
    expect(action, findsOneWidget);
    expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  }
  final t = AppL10n.of(tester.element(find.byType(HangulScreen)));
  for (final label in [
    t.closeActionLabel,
    t.homeActionLabel,
    t.settingsTitle,
  ]) {
    final node = tester.getSemantics(find.bySemanticsLabel(label));
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  }
  final title = find.text(
    AppL10n.of(tester.element(find.byType(HangulScreen))).screenHangulTitle,
  );
  expect(
    tester.getSemantics(title).getSemanticsData().flagsCollection.isHeader,
    isTrue,
  );
}
