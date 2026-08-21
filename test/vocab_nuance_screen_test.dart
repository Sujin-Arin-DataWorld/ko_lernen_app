import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_nuance_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_nuance_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

const _packId = 'nb-nuance';
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
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('DE and EN question feedback reflows across the locked matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());

    const cases = <({Locale locale, String prompt})>[
      (locale: Locale('de'), prompt: 'Welches Wort ist förmlicher?'),
      (locale: Locale('en'), prompt: 'Which word is more formal?'),
    ];

    for (final testCase in cases) {
      final language = testCase.locale.languageCode;
      final explanation = VocabNuanceService.questionsFor(
        _words,
        language: language,
      ).first.explanationFor(language);
      for (final viewport in _viewports) {
        await _pumpNuance(
          tester,
          key: ValueKey(
            '${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
        );

        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.prompt), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);

        for (final label in const <String>['시작', '개시']) {
          final choice = find.widgetWithText(QuizChoice, label);
          await _makeHitTestable(tester, choice);
          expect(
            tester.getSize(choice).height,
            greaterThanOrEqualTo(kMinInteractiveDimension),
          );
          _expectChoiceSemantics(
            tester,
            choice,
            label: label,
            enabled: Tristate.isTrue,
            selected: Tristate.isFalse,
          );
          _expectIdleChoiceContrast(tester, choice);
        }

        final correct = find.widgetWithText(QuizChoice, '개시');
        await _makeHitTestable(tester, correct);
        final activeNode = tester.getSemantics(correct);
        tester.semantics.tap(
          find.semantics.byPredicate(
            (candidate) => candidate.id == activeNode.id,
          ),
        );
        await tester.pump();

        expect(find.text(explanation), findsOneWidget);
        final feedback = find.bySemanticsLabel(explanation);
        expect(feedback, findsOneWidget);
        expect(
          tester
              .getSemantics(feedback)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        _expectChoiceSemantics(
          tester,
          correct,
          label: '개시',
          enabled: Tristate.isFalse,
          selected: Tristate.isTrue,
          value: testCase.locale.languageCode == 'de' ? 'Richtig' : 'Correct',
        );

        final nextLabel = testCase.locale.languageCode == 'de'
            ? 'Weiter'
            : 'Next';
        final next = find.widgetWithText(SoriButton, nextLabel);
        await _makeHitTestable(tester, next);
        expect(
          tester.getSize(next).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        final nextData = tester.getSemantics(next).getSemanticsData();
        expect(nextData.label, nextLabel);
        expect(nextData.flagsCollection.isButton, isTrue);
        expect(nextData.flagsCollection.isEnabled, Tristate.isTrue);
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets('DE and EN completion stays reachable across the locked matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());

    const cases = <({Locale locale, String done, String score, String again})>[
      (
        locale: Locale('de'),
        done: 'Alle Karten durchgegangen!',
        score: '3 / 3 richtig',
        again: 'Nochmal durchgehen',
      ),
      (
        locale: Locale('en'),
        done: 'All cards done!',
        score: '3 / 3 correct',
        again: 'Go again',
      ),
    ];

    for (final testCase in cases) {
      final language = testCase.locale.languageCode;
      final questions = VocabNuanceService.questionsFor(
        _words,
        language: language,
      );
      for (final viewport in _viewports) {
        await _pumpNuance(
          tester,
          key: ValueKey(
            'completion-$language-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
        );

        for (final question in questions) {
          final option = question.options.firstWhere(
            (item) => item.korean == question.correctKorean,
          );
          final choice = find.widgetWithText(
            QuizChoice,
            _optionLabel(
              question,
              option,
              noHanja: language == 'de' ? 'Kein Hanja' : 'No Hanja',
            ),
          );
          await _makeHitTestable(tester, choice);
          final choiceNode = tester.getSemantics(choice);
          tester.semantics.tap(
            find.semantics.byPredicate(
              (candidate) => candidate.id == choiceNode.id,
            ),
          );
          await tester.pump();

          final next = find.widgetWithText(
            SoriButton,
            language == 'de' ? 'Weiter' : 'Next',
          );
          await _makeHitTestable(tester, next);
          await tester.tap(next);
          await tester.pump();
        }

        expect(find.text(testCase.done), findsOneWidget);
        expect(find.text(testCase.score), findsOneWidget);
        final result = find.bySemanticsLabel(
          '${testCase.done} ${testCase.score}',
        );
        expect(result, findsOneWidget);
        expect(
          tester
              .getSemantics(result)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );

        final again = find.widgetWithText(SoriButton, testCase.again);
        await _makeHitTestable(tester, again);
        expect(
          tester.getSize(again).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        final againNode = tester.getSemantics(again);
        final againData = againNode.getSemanticsData();
        expect(againData.label, testCase.again);
        expect(againData.flagsCollection.isButton, isTrue);
        expect(againData.flagsCollection.isEnabled, Tristate.isTrue);
        expect(againData.hasAction(SemanticsAction.tap), isTrue);
        tester.semantics.tap(
          find.semantics.byPredicate(
            (candidate) => candidate.id == againNode.id,
          ),
        );
        await tester.pump();
        expect(find.text('1 / 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets('semantic answer activation also works with motion enabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());

    await _pumpNuance(
      tester,
      key: const ValueKey('normal-motion-semantics'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      disableAnimations: false,
    );

    final choice = find.widgetWithText(QuizChoice, '개시');
    await _makeHitTestable(tester, choice);
    final activeNode = tester.getSemantics(choice);
    expect(
      activeNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => candidate.id == activeNode.id),
    );
    await tester.pump();

    expect(find.textContaining('is more formal than'), findsOneWidget);
    expect(
      tester
          .getSemantics(choice)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('missing and empty DE and EN states use the study frame matrix', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const cases =
        <
          ({
            Locale locale,
            String missingTitle,
            String missingBody,
            String emptyTitle,
            String emptyBody,
          })
        >[
          (
            locale: Locale('de'),
            missingTitle: 'Paket nicht gefunden',
            missingBody: 'Möglicherweise wurde es gelöscht.',
            emptyTitle: 'Noch kein Vergleich',
            emptyBody:
                'Fotografiere oder importiere Wörter, die nah beieinanderliegen. Hanja zeigt dann die andere Nuance oder die förmlichere Stufe.',
          ),
          (
            locale: Locale('en'),
            missingTitle: 'Pack not found',
            missingBody: 'It may have been deleted.',
            emptyTitle: 'No comparison yet',
            emptyBody:
                'Photograph or import words that sit close together. Hanja then shows the other nuance or the more formal level.',
          ),
        ];

    for (final testCase in cases) {
      for (final viewport in _viewports) {
        await _pumpNuance(
          tester,
          key: ValueKey(
            'missing-${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
          packId: 'missing-pack',
        );
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.missingTitle), findsOneWidget);
        expect(find.text(testCase.missingBody), findsOneWidget);
        expect(tester.takeException(), isNull);

        await CustomPackService.save(_pack(words: _words.take(1).toList()));
        await _pumpNuance(
          tester,
          key: ValueKey(
            'empty-${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
        );
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.emptyTitle), findsOneWidget);
        expect(find.text(testCase.emptyBody), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('question order, scoring, completion, and reset stay exact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack());
    final questions = VocabNuanceService.questionsFor(_words, language: 'en');
    expect(questions, hasLength(3));
    expect(
      questions
          .map(
            (question) => (
              id: question.id,
              kind: question.kind,
              options: question.options
                  .map((option) => option.korean)
                  .join('|'),
              correctKorean: question.correctKorean,
            ),
          )
          .toList(growable: false),
      equals([
        (
          id: 'register:시작:개시',
          kind: VocabNuanceQuestionKind.register,
          options: '시작|개시',
          correctKorean: '개시',
        ),
        (
          id: 'meaning:시작:개시',
          kind: VocabNuanceQuestionKind.sharedMeaning,
          options: '시작|개시',
          correctKorean: '시작',
        ),
        (
          id: 'root:開:개시',
          kind: VocabNuanceQuestionKind.hanjaRoot,
          options: '개시|시작',
          correctKorean: '개시',
        ),
      ]),
    );

    await _pumpNuance(
      tester,
      key: const ValueKey('score-and-reset'),
      locale: const Locale('en'),
      size: const Size(360, 400),
      textScale: 1,
    );

    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      expect(find.text(question.promptEn), findsOneWidget);
      expect(find.text('${index + 1} / ${questions.length}'), findsOneWidget);

      final option = index == 0
          ? question.options.firstWhere(
              (item) => item.korean != question.correctKorean,
            )
          : question.options.firstWhere(
              (item) => item.korean == question.correctKorean,
            );
      final label = _optionLabel(question, option, noHanja: 'No Hanja');
      final choice = find.widgetWithText(QuizChoice, label);
      await _makeHitTestable(tester, choice);
      await tester.tap(choice);
      await tester.pump();

      _expectChoiceSemantics(
        tester,
        choice,
        label: label,
        enabled: Tristate.isFalse,
        selected: Tristate.isTrue,
        value: index == 0 ? 'Wrong' : 'Correct',
      );
      expect(find.text(question.explanationEn), findsOneWidget);

      final otherOption = question.options.firstWhere(
        (item) => item.korean != option.korean,
      );
      final otherLabel = _optionLabel(
        question,
        otherOption,
        noHanja: 'No Hanja',
      );
      final otherChoice = find.widgetWithText(QuizChoice, otherLabel);
      await _makeHitTestable(tester, otherChoice);
      _expectChoiceSemantics(
        tester,
        otherChoice,
        label: otherLabel,
        enabled: Tristate.isFalse,
        selected: Tristate.isFalse,
        value: otherOption.korean == question.correctKorean ? 'Correct' : null,
      );
      await tester.tap(otherChoice);
      await tester.pump();
      expect(
        tester
            .widgetList<QuizChoice>(find.byType(QuizChoice))
            .where((item) => item.isSelected),
        hasLength(1),
      );
      _expectChoiceSemantics(
        tester,
        choice,
        label: label,
        enabled: Tristate.isFalse,
        selected: Tristate.isTrue,
        value: index == 0 ? 'Wrong' : 'Correct',
      );

      final next = find.widgetWithText(SoriButton, 'Next');
      await _makeHitTestable(tester, next);
      await tester.tap(next);
      await tester.pump();
    }

    expect(find.text('All cards done!'), findsOneWidget);
    expect(find.text('2 / 3 correct'), findsOneWidget);
    expect(
      find.bySemanticsLabel('All cards done! 2 / 3 correct'),
      findsOneWidget,
    );
    final again = find.widgetWithText(SoriButton, 'Go again');
    await _makeHitTestable(tester, again);
    expect(
      tester.getSize(again).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    await tester.tap(again);
    await tester.pump();

    expect(find.text(questions.first.promptEn), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('2 / 3 correct'), findsNothing);

    for (final question in questions) {
      final wrong = question.options.firstWhere(
        (item) => item.korean != question.correctKorean,
      );
      final wrongChoice = find.widgetWithText(
        QuizChoice,
        _optionLabel(question, wrong, noHanja: 'No Hanja'),
      );
      await _makeHitTestable(tester, wrongChoice);
      await tester.tap(wrongChoice);
      await tester.pump();

      final next = find.widgetWithText(SoriButton, 'Next');
      await _makeHitTestable(tester, next);
      await tester.tap(next);
      await tester.pump();
    }
    expect(find.text('All cards done!'), findsOneWidget);
    expect(find.text('0 / 3 correct'), findsOneWidget);
    expect(
      find.bySemanticsLabel('All cards done! 0 / 3 correct'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the optional words override remains the question source', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_pack(words: _words.take(1).toList()));

    await _pumpNuance(
      tester,
      key: const ValueKey('words-override'),
      locale: const Locale('de'),
      size: const Size(390, 844),
      textScale: 1.3,
      words: _words,
    );

    expect(find.text('Welches Wort ist förmlicher?'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Noch kein Vergleich'), findsNothing);
  });
}

final _words = <ExtractedWord>[
  ExtractedWord.manual(
    korean: '시작',
    translationDe: 'Anfang',
    translationEn: 'start',
  ),
  ExtractedWord.manual(
    korean: '개시',
    translationDe: 'Beginn',
    translationEn: 'commencement',
  ),
];

CustomPack _pack({List<ExtractedWord>? words}) =>
    CustomPack.manual(id: _packId, name: 'Heft', words: words ?? _words);

String _optionLabel(
  VocabNuanceQuestion question,
  VocabNuanceOption option, {
  required String noHanja,
}) {
  switch (question.kind) {
    case VocabNuanceQuestionKind.sharedMeaning:
      return option.hanja.isEmpty ? noHanja : option.hanja;
    case VocabNuanceQuestionKind.hanjaRoot:
      return option.meaning.isEmpty
          ? option.korean
          : '${option.korean}  ${option.meaning}';
    case VocabNuanceQuestionKind.register:
      return option.korean;
  }
}

Future<void> _pumpNuance(
  WidgetTester tester, {
  required Key key,
  required Locale locale,
  required Size size,
  required double textScale,
  String packId = _packId,
  List<ExtractedWord>? words,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: _safeInsets,
          viewPadding: _safeInsets,
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: VocabNuanceScreen(key: key, packId: packId, words: words),
    ),
  );
  await tester.pump();
}

Future<void> _makeHitTestable(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: find.byType(SoriStudyFrame),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
    await tester.pump();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void _expectChoiceSemantics(
  WidgetTester tester,
  Finder choice, {
  required String label,
  required Tristate enabled,
  required Tristate selected,
  String? value,
}) {
  final data = tester.getSemantics(choice).getSemanticsData();
  expect(data.label, label);
  expect(data.value, value ?? '');
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, enabled);
  expect(data.flagsCollection.isSelected, selected);
  expect(data.hasAction(SemanticsAction.tap), enabled == Tristate.isTrue);
}

void _expectIdleChoiceContrast(WidgetTester tester, Finder choice) {
  final container = find.descendant(
    of: choice,
    matching: find.byType(AnimatedContainer),
  );
  final decoration = tester.widget<AnimatedContainer>(container).decoration;
  expect(decoration, isA<BoxDecoration>());
  final box = decoration! as BoxDecoration;
  final border = box.border! as Border;
  expect(
    SoriColors.contrastRatio(border.top.color, box.color!),
    greaterThanOrEqualTo(3),
  );
}
