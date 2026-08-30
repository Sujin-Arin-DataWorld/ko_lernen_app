import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('one grammar ID renders one enlarged resolved entry', (
    tester,
  ) async {
    final grammar = _grammar('grammar_one', 'N(이)세요?');
    await _pumpToGrammar(
      tester,
      scenario: _scenario(grammarIds: const ['grammar_one']),
      grammarLoader: () async => [grammar],
    );

    expect(
      find.byKey(
        const ValueKey<String>('scenario-grammar-expanded-grammar_one'),
      ),
      findsOneWidget,
    );
    expect(find.text('N(이)세요?'), findsOneWidget);
    expect(find.text('Explanation for grammar_one'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('scenario-grammar-summary-grammar_one'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'multiple grammar IDs keep declared order and open an accessible detail sheet',
    (tester) async {
      final first = _grammar('first', 'First pattern');
      final second = _grammar('second', 'Second pattern');
      await _pumpToGrammar(
        tester,
        scenario: _scenario(grammarIds: const ['second', 'first']),
        grammarLoader: () async => [first, second],
      );

      final secondCard = find.byKey(
        const ValueKey<String>('scenario-grammar-summary-second'),
      );
      final firstCard = find.byKey(
        const ValueKey<String>('scenario-grammar-summary-first'),
      );
      expect(secondCard, findsOneWidget);
      expect(firstCard, findsOneWidget);
      expect(
        tester.getTopLeft(secondCard).dy,
        lessThan(tester.getTopLeft(firstCard).dy),
      );

      final semantics = tester.ensureSemantics();
      final semanticsData = tester.getSemantics(secondCard).getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isTrue);
      expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(secondCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('scenario-grammar-detail-second')),
        findsOneWidget,
      );
      expect(find.text('Explanation for second'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('a missing grammar ID is skipped between valid ordered IDs', (
    tester,
  ) async {
    final first = _grammar('first', 'First pattern');
    final second = _grammar('second', 'Second pattern');
    await _pumpToGrammar(
      tester,
      scenario: _scenario(grammarIds: const ['first', 'missing', 'second']),
      grammarLoader: () async => [second, first],
    );

    final firstCard = find.byKey(
      const ValueKey<String>('scenario-grammar-summary-first'),
    );
    final secondCard = find.byKey(
      const ValueKey<String>('scenario-grammar-summary-second'),
    );
    expect(firstCard, findsOneWidget);
    expect(secondCard, findsOneWidget);
    expect(find.text('missing'), findsNothing);
    expect(
      tester.getTopLeft(firstCard).dy,
      lessThan(tester.getTopLeft(secondCard).dy),
    );
  });

  testWidgets('all missing grammar IDs retain the inline grammar fallback', (
    tester,
  ) async {
    await _pumpToGrammar(
      tester,
      scenario: _scenario(
        grammarIds: const ['missing'],
        grammarBlock: _inlineGrammar,
      ),
      grammarLoader: () async => [_grammar('other', 'Other pattern')],
    );

    expect(
      find.byKey(const ValueKey<String>('scenario-grammar-inline')),
      findsOneWidget,
    );
    expect(find.text('Inline grammar fallback'), findsOneWidget);
  });

  testWidgets('grammar loader failure is contained and keeps inline fallback', (
    tester,
  ) async {
    var calls = 0;
    await _pumpToGrammar(
      tester,
      scenario: _scenario(
        grammarIds: const ['grammar_one'],
        grammarBlock: _inlineGrammar,
      ),
      grammarLoader: () async {
        calls += 1;
        throw StateError('grammar fixture unavailable');
      },
    );

    expect(calls, 1);
    expect(find.byType(AppError), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('scenario-grammar-inline')),
      findsOneWidget,
    );
    expect(find.text('Inline grammar fallback'), findsOneWidget);
  });

  test('writing prompt uses the last non-empty user line only', () {
    final scenario = _scenario(
      grammarIds: const [],
      dialog: const [
        DialogLine(speaker: 'assistant', ko: '첫 도우미 문장', de: '', en: ''),
        DialogLine(speaker: 'user', ko: '첫 사용자 문장', de: '', en: ''),
        DialogLine(speaker: 'user', ko: '   ', de: '', en: ''),
        DialogLine(speaker: 'assistant', ko: '마지막 도우미 문장', de: '', en: ''),
        DialogLine(speaker: 'user', ko: '  마지막 사용자 문장  ', de: '', en: ''),
        DialogLine(speaker: 'assistant', ko: '절대 프롬프트가 되면 안 됨', de: '', en: ''),
      ],
    );

    expect(scenarioWritingPromptKo(scenario), '마지막 사용자 문장');
    expect(
      scenarioWritingPromptKo(
        _scenario(
          grammarIds: const [],
          dialog: const [
            DialogLine(speaker: 'assistant', ko: '도우미', de: '', en: ''),
            DialogLine(speaker: 'user', ko: ' ', de: '', en: ''),
          ],
        ),
      ),
      isNull,
    );
  });
}

Future<void> _pumpToGrammar(
  WidgetTester tester, {
  required Scenario scenario,
  required ScenarioGrammarLoader grammarLoader,
}) async {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.physicalSize = const Size(390, 844);
  view.devicePixelRatio = 1;

  CourseProgressService.shared.resetForTesting();
  await tester.runAsync(() async {
    await CurriculumCatalog.load();
  });

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: ScenarioPlayerScreen(
        scenarioId: scenario.id,
        scenarioLoader: (_) async => scenario,
        grammarLoader: grammarLoader,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  await _tapText(tester, "Let's go");
  await _tapText(tester, 'Next');
  await _tapText(tester, 'Next');
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.tap(finder.last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Scenario _scenario({
  required List<String> grammarIds,
  GrammarBlock? grammarBlock,
  List<DialogLine> dialog = const [],
}) => Scenario(
  id: 'scenario-grammar-resolution',
  level: LearnerLevel.a1,
  emoji: '📘',
  register: Register.polite,
  title: const LocalizedText(
    ko: '문법 해석',
    de: 'Grammatikauflösung',
    en: 'Grammar resolution',
  ),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: grammarIds,
  grammarBlock: grammarBlock,
  dialog: dialog,
  quests: const [],
);

Grammar _grammar(String id, String pattern) => Grammar(
  id: id,
  pattern: pattern,
  level: 'A1',
  typeDe: 'Typ $id',
  explanationDe: 'Erklärung für $id',
  exampleKorean: '예문 $id',
  exampleGerman: 'Beispiel $id',
  note: '',
  typeEn: 'Type $id',
  explanationEn: 'Explanation for $id',
  exampleEn: 'Example $id',
);

const _inlineGrammar = GrammarBlock(
  title: LocalizedText(
    ko: '인라인 문법',
    de: 'Inline-Grammatik',
    en: 'Inline grammar fallback',
  ),
  explanation: LocalizedText(
    ko: '인라인 설명',
    de: 'Inline-Erklärung',
    en: 'Inline fallback explanation',
  ),
);
