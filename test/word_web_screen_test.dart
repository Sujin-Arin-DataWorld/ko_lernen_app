import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/screens/word_web_study_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

WordRelationCluster _cluster({
  required String id,
  required String source,
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
  LearnerLevel level = LearnerLevel.a1,
  List<WordRelationCluster>? deck,
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
        clusterLoader: () async => deck ?? _deck,
        seenLoader: () => seen,
        levelLoader: () => level,
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
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('wordWeb');
  });

  testWidgets('empty learned state can open level browse', (tester) async {
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
    expect(find.text(t.wordWebExpressionSection), findsOneWidget);
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
    expect(find.text('크다'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('word-web-option-작다')));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text(t.wordWebQuizDoneTitle), findsOneWidget);
    expect(find.text(t.wordWebQuizScore(1, 1)), findsOneWidget);
  });
}
