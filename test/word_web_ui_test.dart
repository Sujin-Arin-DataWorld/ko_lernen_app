import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/screens/word_web_quiz_screen.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/screens/word_web_study_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
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
    SharedPreferences.setMockInitialValues({'kl_tut_wordWeb': true});
    await Storage.init();
    await Storage.setTutSeen('wordWeb');
  });

  testWidgets('filters and pronunciation actions expose the shared contract', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      child: _hub(),
      size: const Size(390, 844),
      textScale: 1.3,
      locale: const Locale('en'),
    );
    await _finishLoad(tester);

    final filters = <Finder>[
      find.byKey(const ValueKey('word-web-filter-learned')),
      find.byKey(const ValueKey('word-web-filter-level')),
    ];
    for (final filter in filters) {
      expect(filter, findsOneWidget);
      final chip = tester.widget<SoriChip>(filter);
      expect(chip.maxLines, isNull);
      expect(chip.minInteractiveHeight, greaterThanOrEqualTo(48));
      expect(tester.getSize(filter).height, greaterThanOrEqualTo(48));
    }
    final selected = tester.widget<SoriChip>(filters.first);
    expect(selected.selected, isTrue);
    expect(selected.icon, Icons.check_rounded);

    final hubAudio = find.byTooltip('Pronunciation: 크다');
    expect(hubAudio, findsOneWidget);
    expect(tester.getSize(hubAudio).shortestSide, greaterThanOrEqualTo(48));
    final audioData = tester.getSemantics(hubAudio).getSemanticsData();
    expect(audioData.flagsCollection.isButton, isTrue);
    expect(audioData.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.byKey(const ValueKey('big')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SoriStudyFrame), findsOneWidget);

    for (final label in const [
      'Pronunciation: 크다',
      'Pronunciation: 커다랗다',
      'Pronunciation: 큰일 나다',
      'Pronunciation: 큰일 나다 예문',
    ]) {
      final action = find.descendant(
        of: find.byType(WordWebStudyScreen),
        matching: find.byTooltip(label),
      );
      if (action.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          action,
          220,
          scrollable: find.byType(Scrollable).last,
        );
      }
      expect(action, findsOneWidget);
      expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
      final actionData = tester.getSemantics(action).getSemanticsData();
      expect(actionData.flagsCollection.isButton, isTrue);
      expect(actionData.hasAction(ui.SemanticsAction.tap), isTrue);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'DE and EN hub and study content reflow across the viewport matrix',
    (tester) async {
      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final testCase in _viewports) {
          await _pump(
            tester,
            child: _hub(
              key: ValueKey(
                'hub-${locale.languageCode}-${testCase.size.width}',
              ),
            ),
            size: testCase.size,
            textScale: testCase.textScale,
            locale: locale,
          );
          await _finishLoad(tester);

          expect(find.text('크다'), findsOneWidget);
          expect(find.byKey(const ValueKey('word-web-quiz')), findsOneWidget);
          expect(tester.takeException(), isNull);

          await _pump(
            tester,
            child: const WordWebStudyScreen(cluster: _cluster),
            size: testCase.size,
            textScale: testCase.textScale,
            locale: locale,
            includeSafeInsets: true,
          );
          final expression = find.text('큰일 나다');
          await tester.scrollUntilVisible(
            expression,
            240,
            scrollable: find.byType(Scrollable).last,
          );
          expect(expression, findsOneWidget);
          expect(find.text('큰일 나다 예문'), findsOneWidget);
          expect(find.byType(SoriStudyFrame), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
    for (final viewport in _viewports) {
      testWidgets('${locale.languageCode} ${viewport.size.width.toInt()}x'
          '${viewport.size.height.toInt()} ${viewport.textScale}x keeps the '
          'word-web quiz reachable, executable, and announced', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final t = await AppL10n.delegate.load(locale);
          await _pump(
            tester,
            child: _quiz(),
            size: viewport.size,
            textScale: viewport.textScale,
            locale: locale,
            includeSafeInsets: true,
          );

          expect(find.byType(SoriStudyFrame), findsOneWidget);
          expect(
            find.text(_quizItem.promptGloss(locale.languageCode)),
            findsOneWidget,
          );
          final choices = _choiceWidgets(tester);
          expect(choices, hasLength(4));
          for (final choice in choices) {
            final choiceFinder = await _ensureChoiceVisible(
              tester,
              choice.text,
            );
            _expectExecutableChoice(tester, find.bySemanticsLabel(choice.text));
            _expectBoundaryContrast(tester, choiceFinder);
          }
          final lastChoice = await _ensureChoiceVisible(
            tester,
            choices.last.text,
          );
          await _expectPointerOwned(tester, lastChoice);

          final selection = locale.languageCode == 'de'
              ? choices.singleWhere((choice) => choice.isCorrect)
              : choices.firstWhere((choice) => !choice.isCorrect);
          final selectionFinder = await _ensureChoiceVisible(
            tester,
            selection.text,
          );
          await _tapFatal(tester, selectionFinder);

          final feedback = selection.isCorrect
              ? t.wordWebQuizCorrectFeedback(_quizItem.answerKo)
              : t.wordWebQuizWrongFeedback(_quizItem.answerKo);
          await _expectLiveRegion(
            tester,
            feedback,
            expectVisibleInScrollable: true,
          );
          if (!selection.isCorrect) {
            _expectTextContrastOnCard(tester, feedback);
          }
          await _ensureChoiceVisible(tester, selection.text);
          final selected = tester
              .getSemantics(find.bySemanticsLabel(selection.text))
              .getSemanticsData();
          expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
          expect(selected.flagsCollection.isEnabled, ui.Tristate.isFalse);
          expect(selected.hasAction(ui.SemanticsAction.tap), isFalse);

          final finish = await _ensureSoriButtonVisibleInChoiceList(
            tester,
            t.wordWebQuizFinish,
          );
          _expectExecutableButton(tester, finish, minHeight: 48);
          await _tapFatal(tester, finish);
          await _expectLiveRegion(
            tester,
            '${t.wordWebQuizDoneTitle}. '
            '${t.wordWebQuizScore(selection.isCorrect ? 1 : 0, 1)}',
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

  testWidgets('normal motion retains the exact 850 ms word-web advance', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    await _pump(
      tester,
      child: _quiz(),
      size: _viewports[2].size,
      textScale: _viewports[2].textScale,
      locale: const Locale('en'),
      disableAnimations: false,
      includeSafeInsets: true,
    );
    final correct = _choiceWidgets(
      tester,
    ).singleWhere((choice) => choice.isCorrect);
    final correctFinder = await _ensureChoiceVisible(tester, correct.text);
    await _tapFatal(tester, correctFinder);

    expect(_soriButton(t.wordWebQuizFinish), findsNothing);
    await tester.pump(const Duration(milliseconds: 849));
    expect(find.byType(QuizChoice), findsNWidgets(4));
    expect(find.text(t.wordWebQuizDoneTitle), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text(t.wordWebQuizDoneTitle), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('an empty word-web quiz exposes the true-empty close action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final t = await AppL10n.delegate.load(const Locale('de'));
      await _pump(
        tester,
        child: WordWebQuizScreen(
          clusters: const [_cluster],
          quizBuilder: (_) => const [],
        ),
        size: _viewports.first.size,
        textScale: _viewports.first.textScale,
        locale: const Locale('de'),
        includeSafeInsets: true,
      );

      expect(find.byType(SoriEmptyState), findsOneWidget);
      expect(find.text(t.wordWebQuizEmptyTitle), findsOneWidget);
      expect(find.text(t.wordWebQuizEmptyBody), findsOneWidget);
      _expectExecutableButton(tester, _soriButton(t.btnClose), minHeight: 48);
      _expectNoException(tester);
    } finally {
      semantics.dispose();
    }
  });
}

WordWebQuizScreen _quiz() => WordWebQuizScreen(
  clusters: const [_cluster],
  quizBuilder: (_) => const [_quizItem],
);

WordWebScreen _hub({Key? key}) => WordWebScreen(
  key: key,
  clusterLoader: () async => const [_cluster],
  seenLoader: () => const {'크다'},
);

const _quizItem = WordRelationQuizItem(
  kind: WordRelationKind.expression,
  clusterId: 'big',
  sourceKo: '크다',
  promptDe: 'in Schwierigkeiten geraten',
  promptEn: 'get into trouble',
  answerKo: '큰일 나다',
  options: ['큰일 나다', '커다랗다', '사이즈', '조금'],
);

const _cluster = WordRelationCluster(
  id: 'big',
  sourceKo: '크다',
  sourceVocabId: 'vocab_big',
  sourceDe: 'groß',
  sourceEn: 'big',
  level: 'A1',
  synonyms: [WordNeighbor(ko: '커다랗다', de: 'sehr groß', en: 'very big')],
  expressions: [
    WordExpression(
      ko: '큰일 나다',
      de: 'in Schwierigkeiten geraten',
      en: 'get into trouble',
      exampleKo: '큰일 나다 예문',
      exampleDe: 'Ein Beispielsatz.',
      exampleEn: 'An example sentence.',
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double textScale,
  required Locale locale,
  bool disableAnimations = true,
  bool includeSafeInsets = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: includeSafeInsets ? _safeInsets : EdgeInsets.zero,
            viewPadding: includeSafeInsets ? _safeInsets : EdgeInsets.zero,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: child,
    ),
  );
  await tester.pump();
}

Future<void> _finishLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
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
  await Scrollable.ensureVisible(
    list.evaluate().single,
    alignment: 0.2,
    duration: Duration.zero,
  );
  await tester.pump();
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

Future<Finder> _ensureSoriButtonVisibleInChoiceList(
  WidgetTester tester,
  String label,
) async {
  final list = _choiceList();
  expect(list, findsOneWidget);
  await Scrollable.ensureVisible(
    list.evaluate().single,
    alignment: 0.2,
    duration: Duration.zero,
  );
  await tester.pump();
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final finder = _soriButton(label);
  for (var attempt = 0; attempt < 8; attempt++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        finder.evaluate().single,
        alignment: 0.8,
        duration: Duration.zero,
      );
      await tester.pump();
      break;
    }
  }
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
  final scrollables = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (scrollables.evaluate().isEmpty) {
    return false;
  }
  final targetRect = tester.getRect(target);
  for (final scrollable in scrollables.evaluate()) {
    final viewportRect = tester.getRect(
      find.byElementPredicate((element) => identical(element, scrollable)),
    );
    final intersection = targetRect.intersect(viewportRect);
    if (intersection.width <= 0 || intersection.height <= 0) {
      return false;
    }
  }
  return true;
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
