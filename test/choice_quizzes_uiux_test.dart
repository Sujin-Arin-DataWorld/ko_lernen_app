import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _viewports = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_srs_v1': '{"seed":{"e":2.5,"i":1,"n":"2026-08-15","r":1}}',
      'kl_pack_progress_v1':
          '{"a1_seed":{"level":"A1","status":"cleared",'
          '"wordsLearned":5,"wordsTotal":5,"bossAccuracy":1.0,'
          '"attempts":1,"clearedAt":"2026-08-14T00:00:00.000Z"}}',
      Storage.courseMasterySnapshotPreferenceKey: '{"version":2,"evidence":{}}',
    });
    // Regression: a completed SRS tail from the previous widget fake-async
    // zone must not strand this reset on a cross-zone Future callback.
    await Storage.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError(
        'Storage.init did not consume the completed SRS reset boundary',
      ),
    );
  });

  for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
    for (final viewport in _viewports) {
      testWidgets('${locale.languageCode} ${viewport.size.width.toInt()}x'
          '${viewport.size.height.toInt()} ${viewport.textScale}x keeps both '
          'choice quizzes reachable, executable, and announced', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          final t = await AppL10n.delegate.load(locale);
          await _pumpScreen(
            tester,
            GrammarChoiceQuizScreen(
              initialLevel: 'A1',
              randomSeed: 5,
              maxQuestions: 1,
              grammarLoader: () async => _grammarFixture,
            ),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, _choiceList());

          expect(find.byType(SoriStudyFrame), findsOneWidget);
          final grammarChoices = _choiceWidgets(tester);
          expect(grammarChoices, hasLength(4));
          for (final choice in grammarChoices) {
            final choiceFinder = await _ensureChoiceVisible(
              tester,
              choice.text,
            );
            _expectExecutableChoice(tester, find.bySemanticsLabel(choice.text));
            _expectBoundaryContrast(tester, choiceFinder);
          }
          final lastGrammar = await _ensureChoiceVisible(
            tester,
            grammarChoices.last.text,
          );
          await _expectPointerOwned(tester, lastGrammar);

          final grammarSelection = locale.languageCode == 'en'
              ? grammarChoices.singleWhere((choice) => choice.isCorrect)
              : grammarChoices.firstWhere((choice) => !choice.isCorrect);
          final grammarTarget = _grammarFixture.singleWhere(
            (grammar) =>
                grammar.pattern ==
                grammarChoices.singleWhere((choice) => choice.isCorrect).text,
          );
          final grammarSelectionFinder = await _ensureChoiceVisible(
            tester,
            grammarSelection.text,
          );
          await _tapFatal(tester, grammarSelectionFinder);
          await tester.pump();

          final grammarTitle = grammarSelection.isCorrect
              ? t.grammarChoiceCorrect
              : t.grammarChoiceIncorrect(grammarTarget.pattern);
          final grammarFeedback = <String>[
            grammarTitle,
            '${t.grammarChoiceKoreanExampleLabel}: '
                '${grammarTarget.exampleKorean}',
            '${t.grammarChoiceExplanationLabel}: '
                '${grammarTarget.explanationFor(locale.languageCode)}',
            '${t.grammarChoiceNoteLabel}: '
                '${grammarTarget.noteFor(locale.languageCode)}',
          ].join('. ');
          await _expectLiveRegion(
            tester,
            grammarFeedback,
            expectVisibleInScrollable: true,
          );
          await _ensureChoiceVisible(tester, grammarSelection.text);
          final selectedGrammar = tester
              .getSemantics(find.bySemanticsLabel(grammarSelection.text))
              .getSemanticsData();
          expect(
            selectedGrammar.flagsCollection.isSelected,
            ui.Tristate.isTrue,
          );
          expect(
            selectedGrammar.flagsCollection.isEnabled,
            ui.Tristate.isFalse,
          );
          expect(selectedGrammar.hasAction(ui.SemanticsAction.tap), isFalse);
          final grammarFinish = _soriButton(t.grammarChoiceFinish);
          _expectExecutableButton(tester, grammarFinish, minHeight: 48);
          await _tapFatal(tester, grammarFinish);
          final grammarResult = <String>[
            t.grammarChoiceDoneTitle,
            t.grammarChoiceScore(grammarSelection.isCorrect ? 1 : 0, 1),
            t.grammarChoicePracticeOnly,
          ].join('. ');
          await _expectLiveRegion(tester, grammarResult);
          _expectExecutableButton(
            tester,
            _soriButton(t.grammarChoiceAgain),
            minHeight: 48,
          );
          _expectExecutableButton(
            tester,
            _soriButton(t.grammarChoiceBack),
            minHeight: 48,
          );
          _expectNoException(tester);

          await _pumpScreen(
            tester,
            HardChoiceQuizScreen(
              deck: const <Vocab>[_hardWord],
              vocabLoader: () async => const <Vocab>[_hardWord],
            ),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, _choiceList());

          expect(find.byType(SoriStudyFrame), findsOneWidget);
          expect(
            find.text(_hardWord.translationFor(locale.languageCode)),
            findsOneWidget,
          );
          final hardChoices = _choiceWidgets(tester);
          expect(hardChoices, hasLength(4));
          for (final choice in hardChoices) {
            final choiceFinder = await _ensureChoiceVisible(
              tester,
              choice.text,
            );
            _expectExecutableChoice(tester, find.bySemanticsLabel(choice.text));
            _expectBoundaryContrast(tester, choiceFinder);
          }
          final lastHard = await _ensureChoiceVisible(
            tester,
            hardChoices.last.text,
          );
          await _expectPointerOwned(tester, lastHard);

          final hardSelection = locale.languageCode == 'de'
              ? hardChoices.singleWhere((choice) => choice.isCorrect)
              : hardChoices.firstWhere((choice) => !choice.isCorrect);
          final hardSelectionFinder = await _ensureChoiceVisible(
            tester,
            hardSelection.text,
          );
          await _tapFatal(tester, hardSelectionFinder);

          final hardFeedback = hardSelection.isCorrect
              ? t.hardQuizCorrectFeedback(_hardWord.korean)
              : t.hardQuizWrongFeedback(_hardWord.korean);
          await _expectLiveRegion(
            tester,
            hardFeedback,
            expectVisibleInScrollable: true,
          );
          if (!hardSelection.isCorrect) {
            _expectTextContrastOnCard(tester, hardFeedback);
          }
          await _ensureChoiceVisible(tester, hardSelection.text);
          final selectedHard = tester
              .getSemantics(find.bySemanticsLabel(hardSelection.text))
              .getSemanticsData();
          expect(selectedHard.flagsCollection.isSelected, ui.Tristate.isTrue);
          expect(selectedHard.flagsCollection.isEnabled, ui.Tristate.isFalse);
          expect(selectedHard.hasAction(ui.SemanticsAction.tap), isFalse);
          final hardFinish = _soriButton(t.hardQuizFinish);
          _expectExecutableButton(tester, hardFinish, minHeight: 48);
          await _tapFatal(tester, hardFinish);
          await _expectLiveRegion(
            tester,
            '${t.hardQuizDoneTitle}. '
            '${t.hardQuizScore(hardSelection.isCorrect ? 1 : 0, 1)}',
          );
          _expectExecutableButton(
            tester,
            _soriButton(t.btnClose),
            minHeight: 48,
          );
          _expectNoException(tester);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('normal motion retains the exact 850 ms hard-quiz advance', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    await _pumpScreen(
      tester,
      HardChoiceQuizScreen(
        deck: const <Vocab>[_hardWord],
        vocabLoader: () async => const <Vocab>[_hardWord],
      ),
      locale: const Locale('en'),
      viewport: _viewports[2],
      disableAnimations: false,
    );
    await _pumpUntil(tester, _choiceList());
    final correct = _choiceWidgets(
      tester,
    ).singleWhere((choice) => choice.isCorrect);

    final correctFinder = await _ensureChoiceVisible(tester, correct.text);
    await _tapFatal(tester, correctFinder);
    expect(_soriButton(t.hardQuizFinish), findsNothing);
    await tester.pump(const Duration(milliseconds: 849));
    expect(find.byType(QuizChoice), findsNWidgets(4));
    expect(find.text(t.hardQuizDoneTitle), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text(t.hardQuizDoneTitle), findsOneWidget);
    expect(Storage.xp, 2);
    _expectNoException(tester);
  });

  testWidgets('an empty hard deck uses the true-empty state and close action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final t = await AppL10n.delegate.load(const Locale('de'));
      await _pumpScreen(
        tester,
        HardChoiceQuizScreen(
          deck: const <Vocab>[],
          vocabLoader: () async => const <Vocab>[],
        ),
        locale: const Locale('de'),
        viewport: _viewports.first,
      );
      await _pumpUntil(tester, find.byType(SoriEmptyState));

      expect(find.text(t.hardWordsEmptyTitle), findsOneWidget);
      expect(find.text(t.hardWordsEmptyBody), findsOneWidget);
      _expectExecutableButton(tester, _soriButton(t.btnClose), minHeight: 48);
      _expectNoException(tester);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required ({Size size, double textScale}) viewport,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _safeInsets,
            viewPadding: _safeInsets,
            textScaler: TextScaler.linear(viewport.textScale),
            disableAnimations: disableAnimations,
          ),
          child: SoriTypeScale(child: child!),
        );
      },
      home: screen,
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
}

Finder _soriButton(String label) => find.byWidgetPredicate(
  (widget) => widget is SoriButton && widget.label == label,
);

Finder _choiceList() => find.byType(ListView, skipOffstage: false);

List<QuizChoice> _choiceWidgets(WidgetTester tester) {
  final list = tester.widget<ListView>(_choiceList());
  final children = (list.childrenDelegate as SliverChildListDelegate).children;
  return <QuizChoice>[
    for (final child in children)
      if (child is QuizChoice)
        child
      else if (child is Padding && child.child is QuizChoice)
        child.child! as QuizChoice,
  ];
}

Finder _choiceFinder(String label) => find.byWidgetPredicate(
  (widget) => widget is QuizChoice && widget.text == label,
);

Future<Finder> _ensureChoiceVisible(WidgetTester tester, String label) async {
  final list = _choiceList();
  expect(list, findsOneWidget);
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.minScrollExtent);
  await tester.pump();
  final finder = _choiceFinder(label);
  await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
  await tester.pump();
  expect(finder, findsOneWidget);
  return finder;
}

void _expectExecutableChoice(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.flagsCollection.isSelected, ui.Tristate.isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
}

void _expectExecutableButton(
  WidgetTester tester,
  Finder finder, {
  required double minHeight,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
}

void _expectBoundaryContrast(WidgetTester tester, Finder control) {
  final decorated = find.descendant(
    of: control,
    matching: find.byType(AnimatedContainer),
  );
  expect(decorated, findsOneWidget);
  final box =
      tester.widget<AnimatedContainer>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final rendered = Color.alphaBlend(border.top.color, SoriColors.lightBg);
  expect(
    SoriColors.contrastRatio(rendered, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}

void _expectTextContrastOnCard(WidgetTester tester, String text) {
  final textFinder = find.text(text);
  expect(textFinder, findsOneWidget);
  final cardFinder = find.ancestor(
    of: textFinder,
    matching: find.byType(SoriCard),
  );
  expect(cardFinder, findsOneWidget);
  final renderedText = tester.widget<Text>(textFinder);
  final card = tester.widget<SoriCard>(cardFinder);
  final foreground = renderedText.style!.color!;
  final background = SoriCard.resolvedBackground(
    tester.element(cardFinder),
    accent: card.accent,
    tinted: card.tinted,
  );
  expect(
    SoriColors.contrastRatio(foreground, background),
    greaterThanOrEqualTo(4.5),
  );
}

Future<void> _expectLiveRegion(
  WidgetTester tester,
  String label, {
  bool expectVisibleInScrollable = false,
}) async {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.liveRegion == true &&
        widget.properties.label == label,
  );
  for (var attempt = 0; attempt < 8; attempt++) {
    if (finder.evaluate().isNotEmpty &&
        (!expectVisibleInScrollable ||
            _intersectsScrollableViewport(tester, finder))) {
      break;
    }
    await tester.pump();
  }
  final available = tester
      .widgetList<Semantics>(find.byType(Semantics, skipOffstage: false))
      .where((widget) => widget.properties.liveRegion == true)
      .map((widget) => widget.properties.label)
      .toList();
  expect(
    finder,
    findsOneWidget,
    reason: 'Expected live label: $label; available: $available',
  );
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isLiveRegion, isTrue);
  if (expectVisibleInScrollable) {
    expect(
      _intersectsScrollableViewport(tester, finder),
      isTrue,
      reason: 'The announced feedback must intersect its visible viewport.',
    );
  }
}

bool _intersectsScrollableViewport(WidgetTester tester, Finder target) {
  final scrollable = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isEmpty) {
    return false;
  }
  final targetRect = tester.getRect(target);
  final viewportRect = tester.getRect(scrollable.first);
  final intersection = targetRect.intersect(viewportRect);
  return intersection.width > 0 && intersection.height > 0;
}

Future<void> _expectPointerOwned(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  final pressable = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final target = pressable.evaluate().length == 1 ? pressable : finder;
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    target.evaluate().single,
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  final targetBox = tester.renderObject<RenderBox>(target);
  final hitPoint = _ownedHitPoint(tester, targetBox);
  expect(
    hitPoint,
    isNotNull,
    reason: 'The requested control has no pointer-owned point after scrolling.',
  );
}

Future<void> _tapFatal(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  final pressable = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final target = pressable.evaluate().length == 1 ? pressable : finder;
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    target.evaluate().single,
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  final targetBox = tester.renderObject<RenderBox>(target);
  final hitPoint = _ownedHitPoint(tester, targetBox);
  expect(
    hitPoint,
    isNotNull,
    reason: 'The requested control has no pointer-owned point after scrolling.',
  );
  await tester.tapAt(hitPoint!);
  await tester.pump();
}

Offset? _ownedHitPoint(WidgetTester tester, RenderBox targetBox) {
  const candidates = <Offset>[
    Offset(0.5, 0.5),
    Offset(0.25, 0.5),
    Offset(0.75, 0.5),
    Offset(0.5, 0.25),
    Offset(0.5, 0.75),
  ];
  for (final fraction in candidates) {
    final point = targetBox.localToGlobal(
      Offset(
        targetBox.size.width * fraction.dx,
        targetBox.size.height * fraction.dy,
      ),
    );
    final result = HitTestResult();
    tester.binding.hitTestInView(result, point, tester.view.viewId);
    if (result.path.any((entry) => identical(entry.target, targetBox))) {
      return point;
    }
  }
  return null;
}

void _expectNoException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

const _hardWord = Vocab(
  id: 'hard-choice-hada',
  korean: '하다',
  romanization: 'hada',
  german: 'machen',
  english: 'to do',
  level: 'A1',
  posDe: 'Verb',
  posEn: 'verb',
  exampleKorean: '',
  exampleGerman: '',
  exampleEnglish: '',
  topic: 'test',
);

const _grammarFixture = <Grammar>[
  Grammar(
    id: 'grammar_a1_one',
    pattern: '-one',
    level: 'A1',
    typeDe: 'Testtyp eins',
    explanationDe: 'Erklärung eins',
    exampleKorean: '한국어 예문 하나',
    exampleGerman: 'Ich bin bereit.',
    note: 'Test',
    typeEn: 'Test type one',
    explanationEn: 'Explanation one',
    exampleEn: 'I am ready.',
    noteEn: 'Test',
    exampleGermanFocus: 'bin',
    exampleEnFocus: 'am',
    quizEnabled: true,
    quizDistractorIds: <String>[
      'grammar_a1_two',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  Grammar(
    id: 'grammar_a1_two',
    pattern: '-two',
    level: 'A1',
    typeDe: 'Testtyp zwei',
    explanationDe: 'Erklärung zwei',
    exampleKorean: '한국어 예문 둘',
    exampleGerman: 'Du bist bereit.',
    note: 'Test',
    typeEn: 'Test type two',
    explanationEn: 'Explanation two',
    exampleEn: 'You are ready.',
    noteEn: 'Test',
    exampleGermanFocus: 'bist',
    exampleEnFocus: 'are',
    quizEnabled: true,
    quizDistractorIds: <String>[
      'grammar_a1_one',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  Grammar(
    id: 'grammar_a1_three',
    pattern: '-three',
    level: 'A1',
    typeDe: 'Testtyp drei',
    explanationDe: 'Erklärung drei',
    exampleKorean: '한국어 예문 셋',
    exampleGerman: 'Wir lernen heute.',
    note: 'Test',
    typeEn: 'Test type three',
    explanationEn: 'Explanation three',
    exampleEn: 'We study today.',
    noteEn: 'Test',
    exampleGermanFocus: 'lernen',
    exampleEnFocus: 'study',
    quizEnabled: true,
    quizDistractorIds: <String>[
      'grammar_a1_one',
      'grammar_a1_two',
      'grammar_a1_four',
    ],
  ),
  Grammar(
    id: 'grammar_a1_four',
    pattern: '-four',
    level: 'A1',
    typeDe: 'Testtyp vier',
    explanationDe: 'Erklärung vier',
    exampleKorean: '한국어 예문 넷',
    exampleGerman: 'Sie essen Reis.',
    note: 'Test',
    typeEn: 'Test type four',
    explanationEn: 'Explanation four',
    exampleEn: 'They eat rice.',
    noteEn: 'Test',
    exampleGermanFocus: 'essen',
    exampleEnFocus: 'eat',
    quizEnabled: true,
    quizDistractorIds: <String>[
      'grammar_a1_one',
      'grammar_a1_two',
      'grammar_a1_three',
    ],
  ),
];
