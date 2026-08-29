import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_srs_v1': '{"seed":{"e":2.5,"i":1,"n":"2026-08-15","r":1}}',
      'kl_pack_progress_v1':
          '{"a1_seed":{"level":"A1","status":"cleared","wordsLearned":5,"wordsTotal":5,"bossAccuracy":1.0,"attempts":1,"clearedAt":"2026-08-14T00:00:00.000Z"}}',
      Storage.courseMasterySnapshotPreferenceKey: '{"version":2,"evidence":{}}',
    });
    await Storage.init();
  });

  testWidgets('shows a localized highlighted prompt and four choices', (
    tester,
  ) async {
    await _pumpPractice(tester);

    expect(
      find.text('Which Korean grammar pattern matches the highlighted part?'),
      findsOneWidget,
    );
    final choices = tester.widgetList<QuizChoice>(find.byType(QuizChoice));
    final target = _fixture().singleWhere(
      (grammar) =>
          grammar.pattern ==
          choices.singleWhere((choice) => choice.isCorrect).text,
    );
    expect(choices, hasLength(4));
    expect(choices.where((choice) => choice.isCorrect), hasLength(1));
    expect(choices.map((choice) => choice.text).toSet(), hasLength(4));
    expect(choices.every((choice) => choice.subtitle == null), isTrue);
    final prompt = tester.widget<Text>(
      find.byKey(const Key('grammar-choice-prompt')),
    );
    expect(prompt.textSpan!.toPlainText(), target.exampleEn);
    final spans = (prompt.textSpan! as TextSpan).children!
        .whereType<TextSpan>();
    final highlight = spans.singleWhere(
      (span) => span.text == target.exampleEnFocus,
    );
    expect(highlight.style!.decoration, TextDecoration.underline);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong answer marks grammar hard without awarding XP', (
    tester,
  ) async {
    await _pumpPractice(tester);
    final choices = tester.widgetList<QuizChoice>(find.byType(QuizChoice));
    final correct = choices.singleWhere((choice) => choice.isCorrect);
    final wrong = choices.firstWhere((choice) => !choice.isCorrect);
    final beforeSrs = Storage.srsRawJson;
    final beforePack = Storage.packProgressJsonRaw;
    final beforeCourse = Storage.courseMasterySnapshotRawJson;

    wrong.onSelected!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(Storage.grammarHard, contains(correct.text));
    expect(Storage.xp, 0);
    expect(Storage.srsRawJson, beforeSrs);
    expect(Storage.packProgressJsonRaw, beforePack);
    expect(Storage.courseMasterySnapshotRawJson, beforeCourse);
    expect(
      find.text(
        'The matching pattern is: ${correct.text}',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .every((choice) => choice.subtitle == 'Test type'),
      isTrue,
    );

    await tester.tap(find.text('See result'));
    await tester.pump();
    expect(find.text('Round complete'), findsOneWidget);
    expect(Storage.xp, 0);
    expect(Storage.srsRawJson, beforeSrs);
    expect(Storage.packProgressJsonRaw, beforePack);
    expect(Storage.courseMasterySnapshotRawJson, beforeCourse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('correct answer scores without mutating course or hard state', (
    tester,
  ) async {
    await _pumpPractice(tester);
    final correct = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .singleWhere((choice) => choice.isCorrect);
    final beforeSrs = Storage.srsRawJson;
    final beforePack = Storage.packProgressJsonRaw;
    final beforeCourse = Storage.courseMasterySnapshotRawJson;

    correct.onSelected!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(Storage.grammarHard, isEmpty);
    expect(Storage.xp, 0);
    expect(Storage.srsRawJson, beforeSrs);
    expect(Storage.packProgressJsonRaw, beforePack);
    expect(Storage.courseMasterySnapshotRawJson, beforeCourse);
    expect(find.text('Correct.', skipOffstage: false), findsOneWidget);
    expect(
      tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .every((choice) => choice.subtitle == 'Test type'),
      isTrue,
    );

    await tester.tap(find.text('See result'));
    await tester.pump();
    expect(find.text('1 of 1 correct'), findsOneWidget);
    expect(
      find.text('This practice does not change your course progress.'),
      findsOneWidget,
    );
    expect(Storage.grammarHard, isEmpty);
    expect(Storage.xp, 0);
    expect(Storage.srsRawJson, beforeSrs);
    expect(Storage.packProgressJsonRaw, beforePack);
    expect(Storage.courseMasterySnapshotRawJson, beforeCourse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for a wrong-answer difficulty marker before continuing', (
    tester,
  ) async {
    final pendingSave = Completer<void>();
    await _pumpPractice(tester, markGrammarHard: (_) => pendingSave.future);
    final wrong = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((choice) => !choice.isCorrect);

    wrong.onSelected!();
    await tester.pump();

    expect(_actionButton(tester, 'See result').onTap, isNull);
    expect(find.byKey(const Key('grammar-choice-save-error')), findsNothing);

    pendingSave.complete();
    await tester.pump();
    await tester.pump();

    expect(_actionButton(tester, 'See result').onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a localized save failure and still permits continuing', (
    tester,
  ) async {
    final pendingSave = Completer<void>();
    await _pumpPractice(tester, markGrammarHard: (_) => pendingSave.future);
    final wrong = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((choice) => !choice.isCorrect);

    wrong.onSelected!();
    await tester.pump();
    expect(_actionButton(tester, 'See result').onTap, isNull);

    pendingSave.completeError(StateError('storage unavailable'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('grammar-choice-save-error'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(
        "We couldn't save this difficulty marker. You can still continue.",
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(_actionButton(tester, 'See result').onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a thrown grammar loader renders retryable error UI', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpPractice(
      tester,
      grammarLoader: () async {
        attempts++;
        if (attempts == 1) {
          throw StateError('asset read failed');
        }
        return _fixture();
      },
    );

    expect(find.text('No practice available yet'), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(attempts, 2);
    expect(find.byType(QuizChoice), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recorded empty-loader failure renders retryable error UI', (
    tester,
  ) async {
    await _pumpPractice(
      tester,
      grammarLoader: () async => const <Grammar>[],
      dataLoaderErrorReader: () => 'CSV header malformed',
    );

    expect(find.text('No practice available yet'), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an empty custom loader without an error uses the reviewed unavailable copy',
    (tester) async {
      await _pumpPractice(
        tester,
        locale: const Locale('de'),
        grammarLoader: () async => const <Grammar>[],
        dataLoaderErrorReader: () => null,
      );

      expect(find.text('Noch keine Übung verfügbar'), findsOneWidget);
      expect(
        find.text(
          'Für diese Stufe gibt es noch nicht genügend geprüfte Beispiele.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'announces both the prompt sentence and focus in English and German',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpPractice(tester, locale: const Locale('en'));
        final englishTarget = _targetForCurrentQuestion(tester);
        expect(
          find.bySemanticsLabel(
            RegExp(
              '${RegExp.escape('Sentence: ${englishTarget.exampleEn}.')}'
              r'\s+'
              '${RegExp.escape('Highlighted part: '
              '${englishTarget.exampleEnFocus}.')}',
            ),
          ),
          findsOneWidget,
        );
        await _pumpPractice(tester, locale: const Locale('de'));
        final germanTarget = _targetForCurrentQuestion(tester);
        expect(
          find.bySemanticsLabel(
            RegExp(
              '${RegExp.escape('Satz: ${germanTarget.exampleGerman}.')}'
              r'\s+'
              '${RegExp.escape('Hervorgehobener Teil: '
              '${germanTarget.exampleGermanFocus}.')}',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'keeps options and the feedback action reachable at short height',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpPractice(tester);
      final lastOption = find.byType(QuizChoice).last;
      await tester.scrollUntilVisible(
        lastOption,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.getRect(lastOption).bottom, lessThanOrEqualTo(480));

      tester.widget<QuizChoice>(lastOption).onSelected!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final finish = find.text('See result', skipOffstage: false);
      expect(finish, findsOneWidget);
      expect(tester.getRect(finish).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(finish).bottom, lessThanOrEqualTo(480));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restricts plan-day targets without slicing authored distractors and keeps them after restart',
    (tester) async {
      await _pumpPractice(
        tester,
        allowedTargetIds: const <String>{'grammar_a1_one'},
      );

      expect(find.text('1 / 1 · A1'), findsOneWidget);
      final choices = tester.widgetList<QuizChoice>(find.byType(QuizChoice));
      expect(choices, hasLength(4));
      expect(choices.singleWhere((choice) => choice.isCorrect).text, '-one');
      expect(
        choices
            .where((choice) => !choice.isCorrect)
            .map((choice) => choice.text),
        containsAll(const <String>['-two', '-three', '-four']),
      );

      choices.singleWhere((choice) => choice.isCorrect).onSelected!();
      await tester.pump();
      await tester.tap(find.text('See result'));
      await tester.pump();
      await tester.tap(find.text('New round'));
      await tester.pump();

      final restartedChoices = tester.widgetList<QuizChoice>(
        find.byType(QuizChoice),
      );
      expect(find.text('1 / 1 · A1'), findsOneWidget);
      expect(
        restartedChoices.singleWhere((choice) => choice.isCorrect).text,
        '-one',
      );
      expect(restartedChoices, hasLength(4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('null target IDs preserves the omitted seeded choice signature', (
    tester,
  ) async {
    await _pumpPractice(tester);
    final omitted = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .map((choice) => '${choice.text}:${choice.isCorrect}')
        .toList();

    await _pumpPractice(tester, allowedTargetIds: null);
    final explicitNull = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .map((choice) => '${choice.text}:${choice.isCorrect}')
        .toList();

    expect(explicitNull, omitted);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan-day label only replaces the progress caption', (
    tester,
  ) async {
    await _pumpPractice(tester, planDayLabel: 'Day 4');

    expect(find.text('Day 4 · 1 / 1'), findsOneWidget);
    expect(find.text('1 / 1 · A1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
    testWidgets(
      '${locale.languageCode} feedback shows localized usage once and omits it for an empty note',
      (tester) async {
        final t = await AppL10n.delegate.load(locale);
        final withNoteFixture = List<Grammar>.from(_fixture())
          ..[0] = _grammar(
            'one',
            exampleEn: 'I am ready.',
            focusEn: 'am',
            exampleGerman: 'Ich bin bereit.',
            focusGerman: 'bin',
            note: 'Anwendungsnotiz',
            noteEn: 'Usage note',
            distractorIds: const <String>[
              'grammar_a1_two',
              'grammar_a1_three',
              'grammar_a1_four',
            ],
          );
        await _pumpPractice(
          tester,
          locale: locale,
          grammarLoader: () async => withNoteFixture,
          allowedTargetIds: const <String>{'grammar_a1_one'},
        );
        final correct = tester
            .widgetList<QuizChoice>(find.byType(QuizChoice))
            .singleWhere((choice) => choice.isCorrect);
        correct.onSelected!();
        await tester.pump();

        expect(
          find.text(t.grammarChoiceExplanationLabel, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text(t.grammarChoiceNoteLabel, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text(
            locale.languageCode == 'en' ? 'Usage note' : 'Anwendungsnotiz',
            skipOffstage: false,
          ),
          findsOneWidget,
        );

        final noNoteFixture = List<Grammar>.from(_fixture())
          ..[0] = _grammar(
            'one',
            exampleEn: 'I am ready.',
            focusEn: 'am',
            exampleGerman: 'Ich bin bereit.',
            focusGerman: 'bin',
            note: '',
            noteEn: '',
            distractorIds: const <String>[
              'grammar_a1_two',
              'grammar_a1_three',
              'grammar_a1_four',
            ],
          );
        await _pumpPractice(
          tester,
          locale: locale,
          grammarLoader: () async => noNoteFixture,
          allowedTargetIds: const <String>{'grammar_a1_one'},
        );
        tester
            .widgetList<QuizChoice>(find.byType(QuizChoice))
            .singleWhere(
              (choice) => choice.isCorrect && choice.onSelected != null,
            )
            .onSelected!();
        await tester.pump();

        expect(
          find.text(t.grammarChoiceNoteLabel, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label?.contains(t.grammarChoiceNoteLabel) ??
                    false),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpPractice(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Future<List<Grammar>> Function()? grammarLoader,
  String? Function()? dataLoaderErrorReader,
  Future<void> Function(String pattern)? markGrammarHard,
  Set<String>? allowedTargetIds,
  String? planDayLabel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: GrammarChoiceQuizScreen(
        key: UniqueKey(),
        initialLevel: 'A1',
        randomSeed: 5,
        maxQuestions: 1,
        grammarLoader: grammarLoader ?? () async => _fixture(),
        dataLoaderErrorReader: dataLoaderErrorReader,
        markGrammarHard: markGrammarHard,
        allowedTargetIds: allowedTargetIds,
        planDayLabel: planDayLabel,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

SoriButton _actionButton(WidgetTester tester, String label) => tester
    .widgetList<SoriButton>(find.byType(SoriButton))
    .singleWhere((button) => button.label == label);

Grammar _targetForCurrentQuestion(WidgetTester tester) {
  final targetPattern = tester
      .widgetList<QuizChoice>(find.byType(QuizChoice))
      .singleWhere((choice) => choice.isCorrect)
      .text;
  return _fixture().singleWhere((grammar) => grammar.pattern == targetPattern);
}

List<Grammar> _fixture() => [
  _grammar(
    'one',
    exampleEn: 'I am ready.',
    focusEn: 'am',
    exampleGerman: 'Ich bin bereit.',
    focusGerman: 'bin',
    distractorIds: const <String>[
      'grammar_a1_two',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  _grammar(
    'two',
    exampleEn: 'You are ready.',
    focusEn: 'are',
    exampleGerman: 'Du bist bereit.',
    focusGerman: 'bist',
    distractorIds: const <String>[
      'grammar_a1_one',
      'grammar_a1_three',
      'grammar_a1_four',
    ],
  ),
  _grammar(
    'three',
    exampleEn: 'We study today.',
    focusEn: 'study',
    exampleGerman: 'Wir lernen heute.',
    focusGerman: 'lernen',
    distractorIds: const <String>[
      'grammar_a1_one',
      'grammar_a1_two',
      'grammar_a1_four',
    ],
  ),
  _grammar(
    'four',
    exampleEn: 'They eat rice.',
    focusEn: 'eat',
    exampleGerman: 'Sie essen Reis.',
    focusGerman: 'essen',
    distractorIds: const <String>[
      'grammar_a1_one',
      'grammar_a1_two',
      'grammar_a1_three',
    ],
  ),
];

Grammar _grammar(
  String id, {
  required String exampleEn,
  required String focusEn,
  required String exampleGerman,
  required String focusGerman,
  String note = 'Test',
  String noteEn = 'Test',
  required List<String> distractorIds,
}) => Grammar(
  id: 'grammar_a1_$id',
  pattern: '-$id',
  level: 'A1',
  typeDe: 'Testtyp',
  explanationDe: 'Test',
  exampleKorean: '한국어 예문 $id',
  exampleGerman: exampleGerman,
  note: note,
  typeEn: 'Test type',
  explanationEn: 'Test',
  exampleEn: exampleEn,
  noteEn: noteEn,
  exampleGermanFocus: focusGerman,
  exampleEnFocus: focusEn,
  quizEnabled: true,
  quizDistractorIds: distractorIds,
);
