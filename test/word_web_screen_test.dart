import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/screens/word_web_study_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/word_relation_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';

WordRelationCluster _cluster({
  required String id,
  required String source,
  String sourceDe = '',
  String sourceEn = '',
  String level = 'A1',
  List<WordNeighbor> synonyms = const [],
  List<WordNeighbor> antonyms = const [],
  List<WordNeighbor> related = const [],
  List<WordExpression> expressions = const [],
}) {
  return WordRelationCluster(
    id: id,
    sourceKo: source,
    sourceVocabId: 'vocab_$id',
    sourceDe: sourceDe,
    sourceEn: sourceEn,
    level: level,
    synonyms: synonyms,
    antonyms: antonyms,
    related: related,
    expressions: expressions,
  );
}

WordNeighbor _n(String ko) => WordNeighbor(ko: ko, de: 'de-$ko', en: 'en-$ko');

WordExpression _e(String ko) => WordExpression(
  ko: ko,
  de: 'de-$ko',
  en: 'en-$ko',
  exampleKo: '$ko 예문',
  exampleDe: 'Beispiel $ko',
  exampleEn: 'Example $ko',
);

final _deck = [
  _cluster(
    id: 'big',
    source: '크다',
    sourceDe: 'groß',
    sourceEn: 'big',
    synonyms: [_n('커다랗다')],
    antonyms: [_n('작다')],
    related: [_n('사이즈')],
    expressions: [_e('큰일 나다')],
  ),
  _cluster(
    id: 'small',
    source: '작다',
    synonyms: [_n('조그맣다')],
    antonyms: [_n('크다')],
    related: [_n('조금')],
    expressions: [_e('작은 가게')],
  ),
];

Future<void> _pumpHub(
  WidgetTester tester, {
  required Set<String> seen,
  List<WordRelationCluster>? deck,
  Future<List<WordRelationCluster>> Function()? clusterLoader,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: {'/vocab': (_) => const Scaffold(body: Text('vocab-route'))},
      home: WordWebScreen(
        clusterLoader: clusterLoader ?? () async => deck ?? _deck,
        seenLoader: () => seen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    WordRelationService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('wordWeb');
  });

  tearDown(WordRelationService.resetForTesting);

  testWidgets('default load unions course-only vocab without seenLoader', (
    tester,
  ) async {
    const vocabId = 'vocab_course_web';
    WordRelationService.catalogLoaderForTesting = () async =>
        throw StateError('skip catalog');
    WordRelationService.vocabLoaderForTesting = () async => [
      const Vocab(
        id: vocabId,
        korean: '크다',
        romanization: 'keuda',
        german: 'groß',
        level: 'A1',
        posDe: 'Adj',
        exampleKorean: '크다',
        exampleGerman: 'groß',
        topic: 'test',
      ),
    ];
    await Storage.setCourseMasterySnapshotRawJson(
      jsonEncode(
        CourseMasterySnapshot(
          evidence: [
            MasteryEvidence(
              conceptId: 'concept-a',
              contentKind: CurriculumContentKind.vocab,
              contentId: vocabId,
              isCorrect: true,
              occurredAt: DateTime.utc(2026, 8, 1),
              score: 1,
            ),
          ],
        ).toJson(),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: WordWebScreen(clusterLoader: () async => _deck),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('big')), findsOneWidget);
    expect(find.text('크다'), findsOneWidget);
    expect(find.text('작다'), findsNothing);
  });

  testWidgets('empty learned state can open the all-level catalog', (
    tester,
  ) async {
    await _pumpHub(tester, seen: {});
    final t = await AppL10n.delegate.load(const Locale('de'));

    expect(find.text(t.wordWebEmptyTitle), findsOneWidget);
    expect(find.text('크다'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('word-web-filter-level')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('크다'), findsOneWidget);
    expect(find.text('작다'), findsOneWidget);
    expect(find.text(t.wordWebQuizCta), findsOneWidget);
  });

  testWidgets('learned filter lists only seen words and opens study', (
    tester,
  ) async {
    await _pumpHub(tester, seen: {'크다'});
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.byKey(const ValueKey('big')), findsOneWidget);
    expect(find.text('크다'), findsOneWidget);
    expect(find.text('작다'), findsNothing);
    expect(find.text(t.wordWebSynonymSection), findsNothing);

    await tester.tap(find.byKey(const ValueKey('big')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WordWebStudyScreen), findsOneWidget);
    expect(find.text(t.wordWebSynonymSection), findsOneWidget);
    expect(find.text(t.wordWebAntonymSection), findsOneWidget);
    expect(find.text(t.wordWebRelatedSection), findsOneWidget);
    // §W-A2 재조사(실측): 요약 줄("1 ähnlich · 1 Gegenteil · 1 verwandt ·
    // 1 Wendung")은 데이터에 표현이 있다고 말하는데 "Wendungen" 섹션은
    // 화면 텍스트 목록에 없었다 — 삭제된 게 아니라 4번째(마지막) 섹션이라
    // 목록이 lazy build 범위 밖에 있었다(단어·토큰 확대로 앞 3개 섹션이
    // 커져 스크롤 없이 안 닿게 됨). 뒤쪽 '큰일 나다' 검사처럼 스크롤로
    // 명시적으로 닿게 한다.
    await tester.scrollUntilVisible(
      find.text(t.wordWebExpressionSection),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(t.wordWebExpressionSection), findsOneWidget);
    expect(find.text('groß'), findsWidgets);
    expect(find.text('커다랗다'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('큰일 나다'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('큰일 나다'), findsOneWidget);
  });

  testWidgets('quiz cta opens a local practice round', (tester) async {
    await _pumpHub(tester, seen: {'크다'});

    await tester.tap(find.byKey(const ValueKey('word-web-quiz')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WordWebQuizScreen), findsOneWidget);
  });

  testWidgets('returning from vocab refreshes the learned list', (
    tester,
  ) async {
    final seen = <String>{};
    await _pumpHub(tester, seen: seen);
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.wordWebEmptyTitle), findsOneWidget);

    await tester.tap(find.text(t.wordWebOpenVocabCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('vocab-route'), findsOneWidget);

    seen.add('크다');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('크다'), findsOneWidget);
    expect(find.text(t.wordWebEmptyTitle), findsNothing);
  });

  testWidgets('empty quiz builder shows a fail-closed empty state', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('de'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: WordWebQuizScreen(clusters: _deck, quizBuilder: (_) => const []),
      ),
    );
    await tester.pump();

    expect(find.text(t.wordWebQuizEmptyTitle), findsOneWidget);
    expect(find.text(t.wordWebQuizDoneTitle), findsNothing);
    expect(find.text(t.wordWebQuizScore(0, 0)), findsNothing);
  });

  testWidgets('quiz reveals the correct neighbor after a tap', (tester) async {
    final t = await AppL10n.delegate.load(const Locale('de'));
    final item = WordRelationQuizItem(
      kind: WordRelationKind.antonym,
      clusterId: 'big',
      sourceKo: '크다',
      promptDe: '크다',
      promptEn: '크다',
      answerKo: '작다',
      options: const ['작다', '사이즈', '조금', '커다랗다'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: WordWebQuizScreen(clusters: _deck, quizBuilder: (_) => [item]),
      ),
    );
    await tester.pump();

    expect(find.text(t.wordWebQuizHintAntonym), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.byType(SoriChip), findsNothing);
    expect(find.text('크다'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text(t.wordWebQuizDoneTitle), findsOneWidget);
    expect(find.text(t.wordWebQuizScore(1, 1)), findsOneWidget);
  });

  testWidgets('broken cluster loader shows a distinct retry state', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpHub(
      tester,
      seen: {'크다'},
      clusterLoader: () async {
        attempts++;
        if (attempts == 1) {
          throw StateError('broken word-web asset');
        }
        return _deck;
      },
    );
    final t = await AppL10n.delegate.load(const Locale('de'));

    expect(find.text(t.wordWebLoadErrorTitle), findsOneWidget);
    expect(find.text(t.wordWebEmptyTitle), findsNothing);
    expect(find.text('크다'), findsNothing);

    await tester.tap(find.text(t.btnRetry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(t.wordWebLoadErrorTitle), findsNothing);
    expect(find.text('크다'), findsOneWidget);
    expect(find.text('groß'), findsOneWidget);
  });
}
