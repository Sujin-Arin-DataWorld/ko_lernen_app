import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/shelf_case.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/tts_speed_control.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/deck_actions.dart';

const _privatePackName =
    'private.name@example.com-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _privateWord = '\uC0AC\uC801 \uB2E8\uC5B4';
const _privateTranslation = 'private translation';

const _word = Vocab(
  korean: '\uB2E8\uC5B4',
  romanization: 'daneo',
  german: 'Wort',
  english: 'word',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

const _scenario = Scenario(
  id: 'terminal-scenario',
  level: LearnerLevel.a1,
  emoji: '\uD638\uB791\uC774',
  register: Register.polite,
  title: LocalizedText(
    ko: '',
    de: 'Terminal scenario',
    en: 'Terminal scenario',
  ),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '\uC548\uB155',
        'correctIndex': 0,
        'options': [
          {'de': 'Correct response', 'en': 'Correct response'},
        ],
      },
    ),
  ],
);

const _listeningScenario = Scenario(
  id: 'listening-terminal',
  level: LearnerLevel.a1,
  emoji: '\uD638\uB791\uC774',
  register: Register.polite,
  title: LocalizedText(
    ko: '',
    de: 'Listening terminal',
    en: 'Listening terminal',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(
      speaker: 'teacher',
      ko: '\uC548\uB155',
      de: 'Hallo',
      en: 'Hello',
    ),
  ],
  quests: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 900);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpPlay': true,
      'kl_tut_vocab_pack': true,
      'kl_tut_pack_quiz': true,
      'kl_tut_pack_boss': true,
      'kl_tut_scenario': true,
      'kl_tut_listening': true,
      'kl_tut_listening_play': true,
      'kl_tut_review': true,
      'kl_tut_legacyVocab': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('scenario feedback appears only on the real final result route', (
    tester,
  ) async {
    // _load()가 이제 항상 activeScenarioCheckpointContext(→
    // CourseProgressService.shared, CurriculumCatalog.load())를 거친다(T8,
    // 지시서 4.15). 그 서비스의 직렬화 큐는 testWidgets 마다 새로 생기는
    // Zone 을 넘나들면 응답하지 않으므로 이 테스트 자신의 Zone 안에서
    // 새로 시작하고, CurriculumCatalog.load()는 ScenarioLoader.load()의
    // compute() 격리를 거치므로 runAsync로 감싸 미리 예열한다
    // (scenario_mission_context_test.dart와 동일 패턴).
    CourseProgressService.shared.resetForTesting();
    await tester.runAsync(() async {
      await CurriculumCatalog.load();
    });
    await tester.pumpWidget(
      _app(
        ScenarioPlayerScreen(
          scenarioId: _scenario.id,
          scenarioLoader: (_) async => _scenario,
          resultPersister: (_, _, _) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentFeedbackCard), findsNothing);
    await _tapText(tester, "Los geht's!");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Wortschatz'), findsOneWidget);
    expect(find.byType(ContentFeedbackCard), findsNothing);
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Dialog'), findsOneWidget);
    expect(find.byType(ContentFeedbackCard), findsNothing);
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(ContentFeedbackCard), findsNothing);
    await _tapText(tester, 'Correct response');
    await tester.pump();
    await _tapText(tester, 'Antwort prüfen');
    await tester.pump();
    await _tapText(tester, 'Ergebnis ansehen');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('DEINE SZENE IST GESPEICHERT'), findsOneWidget);
    expect(find.text('3 von 3 Sternen'), findsNothing);
    _expectFeedback(tester, type: 'scenario');
  });

  testWidgets(
    'vocab pack feedback follows the actual result-route replacement',
    (tester) async {
      const pack = VocabPack(
        id: 'a1_terminal',
        level: 'A1',
        words: [
          Vocab(
            korean: '\uB2E8\uC5B4',
            romanization: 'daneo',
            german: 'Wort',
            english: 'word',
            level: 'A1',
            posDe: 'Nomen',
            exampleKorean: '',
            exampleGerman: '',
            topic: 'test',
            isReviewBoss: true,
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Current-pack Boss words are taught in Learn before their recognition
      // assessment, so reveal the gloss and complete the Learn card first.
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, 'Gewusst');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final correct = find.byWidgetPredicate(
        (widget) => widget is QuizChoice && widget.isCorrect,
      );
      expect(correct, findsOneWidget);
      tester.widget<QuizChoice>(correct).onSelected!();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      _expectFeedback(tester, type: 'vocab_pack');
    },
  );

  testWidgets(
    'listening feedback appears only after completing the selected session',
    (tester) async {
      await tester.pumpWidget(
        _app(
          ListeningPlayScreen(
            scenario: _listeningScenario,
            speechPlayer: (text, {required voice}) async => true,
            stopPlayer: () async {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ContentFeedbackCard), findsNothing);

      await _tapText(tester, 'Dialog anhören');
      await tester.pump();
      await tester.pump();

      _expectFeedback(tester, type: 'listening');
    },
  );

  testWidgets(
    'review session feedback comes from answering the final deck card',
    (tester) async {
      await tester.pumpWidget(_app(const ReviewSessionScreen(deck: [_word])));
      await tester.pump();
      // §P2-3: 판정 버튼도 플립 게이트 — 카드를 뒤집은 뒤에만 판정 가능.
      await tester.tap(find.text(_word.korean), warnIfMissed: false);
      await tester.pump();
      tapDeckAction(tester, 'Gewusst!');
      await tester.pump();

      _expectFeedback(tester, type: 'review');
    },
  );

  testWidgets(
    'custom pack play completion redacts personal pack and word data',
    (tester) async {
      await CustomPackService.save(
        CustomPack.manual(
          id: 'private-pack',
          name: _privatePackName,
          words: const [
            ExtractedWord(
              korean: _privateWord,
              romanization: 'sajeok daneo',
              posDe: 'Nomen',
              translationDe: _privateTranslation,
              translationEn: _privateTranslation,
              exampleKorean: '',
              exampleDe: '',
              savedToPackId: null,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(const CustomPackPlayScreen(packId: 'private-pack')),
      );
      await tester.pump();
      // §P2-3: 판정 버튼도 플립 게이트 — 카드를 뒤집은 뒤에만 판정 가능.
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, 'Gewusst!');
      await tester.pump();

      final card = _expectFeedback(tester, type: 'custom_wordbook');
      final values = card.feedbackContext.toWire().values.whereType<String>();
      for (final secret in [
        _privatePackName,
        _privateWord,
        _privateTranslation,
      ]) {
        expect(values.any((value) => value.contains(secret)), isFalse);
      }
    },
  );

  testWidgets(
    'legacy due review yields feedback only after a due card is processed',
    (tester) async {
      await tester.pumpWidget(
        _app(LegacyVocabScreen(vocabLoader: () async => const [_word])),
      );
      await tester.pump();
      expect(find.byType(ContentFeedbackCard), findsNothing);
      await tester.tap(find.text(_word.korean));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, 'Gewusst!');
      await tester.pump();

      _expectFeedback(tester, type: 'legacy_vocab');
    },
  );

  testWidgets('legacy empty non-due state has no feedback card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(LegacyVocabScreen(vocabLoader: () async => const [])),
    );
    await tester.pump();

    expect(find.byType(ContentFeedbackCard), findsNothing);
  });

  testWidgets('loaded non-due legacy session has no feedback card', (
    tester,
  ) async {
    await Storage.srsReview(_word.korean, gotIt: true);
    await tester.pumpWidget(
      _app(LegacyVocabScreen(vocabLoader: () async => const [_word])),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FlipCard), findsOneWidget);
    expect(find.byType(ContentFeedbackCard), findsNothing);
  });

  testWidgets(
    'listening player fits a 390px portrait viewport without the shelf',
    (tester) async {
      _setViewport(const Size(390, 844));
      await tester.pumpWidget(
        _app(ListeningPlayScreen(scenario: _listeningScenario)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ListeningPlayScreen), findsOneWidget);
      expect(find.byType(ChaekgadoShelfCase), findsNothing);
      expect(find.text('Beides'), findsNothing);
      expect(find.text('Koreanisch'), findsNothing);
      expect(find.byType(TtsSpeedControl), findsOneWidget);
      expect(
        tester.getRect(find.byType(ListeningPlayScreen)),
        const Offset(0, 0) & const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('legacy mode controls fit a 390px portrait viewport', (
    tester,
  ) async {
    _setViewport(const Size(390, 844));
    await Storage.toggleVokFavorite(_word.korean);
    await tester.pumpWidget(
      _app(LegacyVocabScreen(vocabLoader: () async => const [_word])),
    );
    await tester.pump();
    await tester.pump();

    final today = _chipWhere((label) => label.startsWith('Heute ('));
    final favorites = _chip('1');
    final all = _chip('Alle');
    final modes = [today, favorites, all];
    for (final finder in modes) {
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, inInclusiveRange(44, 48));
    }
    _expectInsideViewport(tester, modes, const Size(390, 844));
    expect(tester.takeException(), isNull);
    for (final selectedMode in modes) {
      await tester.tap(selectedMode);
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final mode in modes) {
        expect(tester.widget<SoriChip>(mode).selected, mode == selectedMode);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide listening and legacy controls retain their inline layout', (
    tester,
  ) async {
    _setViewport(const Size(600, 900));
    await tester.pumpWidget(
      _app(ListeningPlayScreen(scenario: _listeningScenario)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(TtsSpeedControl), findsOneWidget);
    expect(find.text('Beides'), findsNothing);
    expect(find.byType(ChaekgadoShelfCase), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      _app(LegacyVocabScreen(vocabLoader: () async => const [_word])),
    );
    await tester.pump();
    await tester.pump();
    _expectSameRow(tester, [
      _chipWhere((label) => label.startsWith('Heute (')),
      _chip('0'),
      _chip('Alle'),
    ]);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
}

ContentFeedbackCard _expectFeedback(
  WidgetTester tester, {
  required String type,
}) {
  final finder = find.byType(ContentFeedbackCard);
  expect(finder, findsOneWidget);
  final card = tester.widget<ContentFeedbackCard>(finder);
  expect(card.feedbackContext.contentType, type);
  expect(card.feedbackContext.completionId, isNotEmpty);
  return card;
}

Finder _chip(String label) => _chipWhere((candidate) => candidate == label);

Finder _chipWhere(bool Function(String label) matches) => find
    .byWidgetPredicate((widget) => widget is SoriChip && matches(widget.label));

void _expectSameRow(WidgetTester tester, List<Object> controls) {
  final finders = controls.map((control) {
    return switch (control) {
      String label => _chip(label),
      Finder finder => finder,
      _ => throw ArgumentError.value(control, 'control'),
    };
  }).toList();
  for (final finder in finders) {
    expect(finder, findsOneWidget);
  }
  final top = tester.getTopLeft(finders.first).dy;
  for (final finder in finders.skip(1)) {
    expect(tester.getTopLeft(finder).dy, closeTo(top, 0.1));
  }
}

void _expectInsideViewport(
  WidgetTester tester,
  Iterable<Finder> controls,
  Size viewport,
) {
  for (final finder in controls) {
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(viewport.width));
    expect(rect.bottom, lessThanOrEqualTo(viewport.height));
  }
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
  builder: (context, child) => ContentFeedbackControllerScope(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    submitFeedback: (_, __) async => throw UnimplementedError(),
    resumePending: () async => throw UnimplementedError(),
    child: child!,
  ),
  onGenerateRoute: (settings) {
    if (settings.name == '/vocab/result') {
      return MaterialPageRoute<void>(
        builder: (_) => VocabPackResultScreen.fromArgs(settings.arguments),
      );
    }
    return null;
  },
);

void _setViewport(Size size) {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
}
