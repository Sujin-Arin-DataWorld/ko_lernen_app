import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/grounded_book_study_service.dart';
import 'package:ko_lernen_app/widgets/grounded_book_study_card.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

void main() {
  const word = ExtractedWord(
    korean: '학교',
    romanization: '',
    posDe: 'Noun',
    translationDe: 'school',
    translationEn: 'school',
    translationLanguage: 'en',
    exampleKorean: '오늘은 학교에 가요.',
    exampleDe: 'I go to school today.',
    sourceUnitId: 'unit:0',
    savedToPackId: null,
  );
  const futureGrammar = GrammarHit(
    patternId: 'g_attribute_future',
    nameDe: 'Future modifier',
    matchedText: '먹을',
    level: 'A2',
    explanationDe: '-(으)ㄹ modifies a following noun for a future action.',
    sourceUnitId: 'unit:2',
  );
  const expression = ExtractedExpression(
    korean: '잘됐어요',
    translationDe: 'That is great.',
    translationEn: 'That is great.',
    translationLanguage: 'en',
    sourceUnitId: 'unit:4',
  );
  const result = BookAnalysisResult(
    words: <ExtractedWord>[word],
    expressions: <ExtractedExpression>[expression],
    grammar: <GrammarHit>[
      futureGrammar,
      GrammarHit(
        patternId: 'g_attribute_present',
        nameDe: 'Present modifier',
        matchedText: '먹는',
        level: 'A2',
        explanationDe: '-는 modifies a following noun for a present action.',
        sourceUnitId: 'unit:3',
      ),
    ],
    sentences: <TranslatedSentence>[
      TranslatedSentence(
        korean: '오늘은 학교에 가요.',
        translationDe: 'I go to school today.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:0',
      ),
      TranslatedSentence(
        korean: '저는 학교에서 한국어를 공부해요.',
        translationDe: 'I study Korean at school.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:0',
      ),
      TranslatedSentence(
        korean: '저는 내일 먹을 음식을 준비해요.',
        translationDe: 'I prepare food for tomorrow.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:2',
      ),
      TranslatedSentence(
        korean: '우리는 먹을 음식을 골라요.',
        translationDe: 'We choose food to eat.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:2',
      ),
      TranslatedSentence(
        korean: '지금 먹는 음식은 비빔밥이에요.',
        translationDe: 'The food being eaten now is bibimbap.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:3',
      ),
      TranslatedSentence(
        korean: '정말 잘됐어요.',
        translationDe: 'That is really great.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:4',
      ),
    ],
    warnings: <String>[],
    analysisLanguage: 'en',
  );

  setUp(() {
    MascotPreference.preference.value = CompanionPreference.tiger;
  });

  tearDown(() {
    MascotPreference.preference.value = CompanionPreference.tiger;
  });

  Widget app(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('each card target has an independent compact ask button', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Row(
          children: <Widget>[
            GroundedBookAskButton(
              result: result,
              target: GroundedBookTarget.forWord(word),
            ),
            GroundedBookAskButton(
              result: result,
              target: GroundedBookTarget.forGrammar(futureGrammar),
            ),
            GroundedBookAskButton(
              result: result,
              target: GroundedBookTarget.forSentence(result.sentences.first),
            ),
            GroundedBookAskButton(
              result: result,
              target: GroundedBookTarget.forExpression(expression),
            ),
          ],
        ),
      ),
    );

    expect(find.byTooltip('Ask your companion'), findsNWidgets(4));
    final tapTarget = tester.getSize(find.byType(IconButton).first);
    expect(tapTarget.width, greaterThanOrEqualTo(48));
    expect(tapTarget.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Ask your companion').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Why does this form look like this?'), findsOneWidget);
    expect(find.text('Show an example from this page'), findsOneWidget);
    expect(find.text('Compare it with similar grammar'), findsOneWidget);
    expect(find.text('Give me a quick question'), findsOneWidget);
    expect(find.text('What does this mean?'), findsNothing);
  });

  testWidgets('unsupported intent shows the explicit no-evidence state', (
    tester,
  ) async {
    const sparseGrammar = GrammarHit(
      patternId: 'g_sparse',
      nameDe: '',
      matchedText: '먹을',
      level: 'A2',
      explanationDe: '',
      sourceUnitId: 'unit:8',
    );
    const sparse = BookAnalysisResult(
      words: <ExtractedWord>[],
      grammar: <GrammarHit>[sparseGrammar],
      sentences: <TranslatedSentence>[],
      warnings: <String>[],
    );
    await tester.pumpWidget(
      app(
        GroundedBookStudyCard(
          result: sparse,
          target: GroundedBookTarget.forGrammar(sparseGrammar),
        ),
      ),
    );

    await tester.tap(find.text('Show an example from this page'));
    await tester.pump();

    expect(
      find.text("I couldn't find evidence for that in this page analysis."),
      findsOneWidget,
    );
  });

  testWidgets('legacy card without provenance opens to no-evidence', (
    tester,
  ) async {
    const legacyWord = ExtractedWord(
      korean: '학교',
      romanization: '',
      posDe: 'Noun',
      translationDe: 'school',
      translationEn: 'school',
      translationLanguage: 'en',
      exampleKorean: '',
      exampleDe: '',
      sourceUnitId: '',
      savedToPackId: null,
    );
    const offline = BookAnalysisResult(
      words: <ExtractedWord>[legacyWord],
      grammar: <GrammarHit>[],
      sentences: <TranslatedSentence>[],
      warnings: <String>['offline_stub'],
      analysisLanguage: 'en',
    );
    await tester.pumpWidget(
      app(
        GroundedBookAskButton(
          result: offline,
          target: GroundedBookTarget.forWord(legacyWord),
        ),
      ),
    );

    expect(find.byTooltip('Ask your companion'), findsOneWidget);
    await tester.tap(find.byTooltip('Ask your companion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('What does this mean?'));
    await tester.pump();

    expect(
      find.text("I couldn't find evidence for that in this page analysis."),
      findsOneWidget,
    );
  });

  testWidgets('persona changes presentation while facts stay identical', (
    tester,
  ) async {
    final target = GroundedBookTarget.forSentence(result.sentences.first);
    await tester.pumpWidget(
      app(GroundedBookStudyCard(result: result, target: target)),
    );
    await tester.tap(find.text('What does this mean?'));
    await tester.pump();

    expect(find.text("Let's verify it step by step."), findsOneWidget);
    expect(find.text('오늘은 학교에 가요.'), findsOneWidget);
    expect(find.text('I go to school today.'), findsOneWidget);
    expect(find.text('Another verified example'), findsNothing);

    MascotPreference.preference.value = CompanionPreference.magpie;
    await tester.pump();

    expect(find.text("Here's the short version!"), findsOneWidget);
    expect(find.text('오늘은 학교에 가요.'), findsOneWidget);
    expect(find.text('I go to school today.'), findsOneWidget);
    expect(find.text('Another verified example'), findsOneWidget);
    expect(find.text('저는 학교에서 한국어를 공부해요.'), findsOneWidget);
    expect(find.text('Evidence from this page · unit:0'), findsOneWidget);
  });

  testWidgets('quiz keeps the verified answer hidden until requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        GroundedBookStudyCard(
          result: result,
          target: GroundedBookTarget.forGrammar(futureGrammar),
        ),
      ),
    );
    await tester.tap(find.text('Give me a quick question'));
    await tester.pump();

    expect(find.text('저는 내일 _____ 음식을 준비해요.'), findsOneWidget);
    expect(find.text('먹을'), findsNothing);
    await tester.tap(find.text('Show answer'));
    await tester.pump();

    expect(find.text('먹을'), findsOneWidget);
  });

  testWidgets('meaningful contaminated result renders no ask button', (
    tester,
  ) async {
    final contaminated = BookAnalysisResult(
      words: result.words,
      grammar: result.grammar,
      sentences: result.sentences,
      warnings: const <String>['invalid_response_filtered'],
      analysisLanguage: 'en',
    );
    await tester.pumpWidget(
      app(
        GroundedBookAskButton(
          result: contaminated,
          target: GroundedBookTarget.forWord(word),
        ),
      ),
    );

    expect(find.byTooltip('Ask your companion'), findsNothing);
  });
}
