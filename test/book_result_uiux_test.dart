import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _completeResult = BookAnalysisResult(
  words: <ExtractedWord>[
    ExtractedWord(
      korean: '안녕하세요',
      romanization: 'annyeonghaseyo',
      posDe: 'Grußformel',
      translationDe: 'Guten Tag',
      translationEn: 'Hello',
      translationLanguage: 'de',
      exampleKorean: '안녕하세요, 반갑습니다.',
      exampleDe: 'Guten Tag, schön dich kennenzulernen.',
      savedToPackId: null,
      definitionKo: '만났을 때 하는 인사말',
      sourceUnitId: 'unit-word',
    ),
  ],
  expressions: <ExtractedExpression>[
    ExtractedExpression(
      korean: '반갑습니다',
      translationDe: 'Freut mich',
      translationEn: 'Nice to meet you',
      translationLanguage: 'de',
      sourceUnitId: 'unit-expression',
    ),
  ],
  grammar: <GrammarHit>[
    GrammarHit(
      patternId: 'g_polite',
      nameDe: 'Höfliche Endung',
      matchedText: '습니다',
      level: 'A1',
      explanationDe: 'Formelle höfliche Aussage.',
      sourceUnitId: 'unit-grammar',
    ),
  ],
  sentences: <TranslatedSentence>[
    TranslatedSentence(
      korean: '안녕하세요, 반갑습니다.',
      translationDe: 'Guten Tag, freut mich.',
      sourceUnitId: 'unit-sentence',
    ),
  ],
  warnings: <String>[],
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_book': true,
      'kl_tut_wordbook': true,
      'kl_bookshelf_v1': '{}',
    });
    await Storage.init();
  });

  testWidgets(
    'complete result stays reachable across the DE/EN viewport matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        final result = _localizedCompleteResult(locale.languageCode);
        for (final viewport in viewports) {
          await _pumpResult(
            tester,
            locale: locale,
            size: viewport.size,
            textScale: viewport.textScale,
            result: result,
          );

          expect(find.text(t.bookResultTitle), findsOneWidget);
          expect(find.text(t.bookResultFoundN(1)), findsOneWidget);
          _expectLiveHeader(tester, t.bookResultFoundN(1));
          expect(find.text(t.bookResultSectionWords), findsOneWidget);
          expect(find.text(t.bookResultSectionExpressions), findsOneWidget);
          expect(find.text(t.bookResultSectionGrammar), findsOneWidget);
          expect(find.text(t.bookResultSectionSentences), findsOneWidget);
          expect(
            find.text(locale.languageCode == 'en' ? 'Hello' : 'Guten Tag'),
            findsOneWidget,
          );

          for (final spokenText in const <String>[
            '안녕하세요',
            '반갑습니다',
            '안녕하세요, 반갑습니다.',
          ]) {
            await _expectEnabledIconSemantics(
              tester,
              '${t.ttsListen}: $spokenText',
            );
          }

          final save = find.widgetWithText(SoriButton, t.bookResultSave);
          await tester.scrollUntilVisible(
            save,
            280,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump();
          _expectEnabledButtonSemantics(tester, save, t.bookResultSave);
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'blocked warning is live and actions remain safe at 320dp and 200%',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const blocked = BookAnalysisResult(
        words: <ExtractedWord>[],
        grammar: <GrammarHit>[],
        sentences: <TranslatedSentence>[],
        warnings: <String>['no_korean_text'],
      );

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        await _pumpResult(tester, locale: locale, result: blocked);

        final warning = find.bySemanticsLabel(t.bookResultNoKoreanNotice);
        expect(warning, findsOneWidget);
        final warningData = tester.getSemantics(warning).getSemanticsData();
        expect(warningData.flagsCollection.isLiveRegion, isTrue);

        final retake = find.widgetWithText(SoriButton, t.bookPreviewRetake);
        await tester.scrollUntilVisible(
          retake,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        _expectEnabledButtonSemantics(tester, retake, t.bookPreviewRetake);
        _expectOutlinedBoundaryContrast(tester, retake);
        expect(find.widgetWithText(SoriButton, t.bookResultSave), findsNothing);
        expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets('save becomes an announced disabled action while it is pending', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final saveGate = Completer<void>();
    final t = lookupAppL10n(const Locale('en'));
    await _pumpResult(
      tester,
      locale: const Locale('en'),
      result: _localizedCompleteResult('en'),
      pageSaver: (_, __) => saveGate.future,
      size: const Size(390, 844),
      textScale: 1.3,
    );

    final save = find.widgetWithText(SoriButton, t.bookResultSave);
    await tester.scrollUntilVisible(
      save,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(save);
    await tester.pump();

    final saving = find.widgetWithText(SoriButton, t.bookResultSaving);
    _expectDisabledButtonSemantics(tester, saving, t.bookResultSaving);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(t.bookResultSaving))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );

    saveGate.complete();
    await tester.pumpAndSettle();
    final createPack = find.widgetWithText(
      SoriButton,
      t.bookshelfCreatePackCta,
    );
    expect(createPack, findsOneWidget);
    await tester.scrollUntilVisible(
      createPack,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(seconds: 3));
    final back = find.widgetWithText(SoriButton, t.bookResultBackToCapture);
    _expectEnabledButtonSemantics(tester, back, t.bookResultBackToCapture);
    _expectOutlinedBoundaryContrast(tester, back);

    await tester.tap(createPack);
    await tester.pumpAndSettle();
    final nameField = find.byType(SoriTextField);
    expect(nameField, findsOneWidget);
    expect(
      tester.widget<SoriTextField>(nameField).labelText,
      t.bookshelfCreatePackName,
    );
    expect(
      tester.widget<SoriTextField>(nameField).hintText,
      t.bookshelfCreatePackNameHint,
    );
    await tester.tap(find.text(t.btnCancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'unknown save outcome stays fail-closed and persistently visible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = lookupAppL10n(const Locale('de'));
      var writes = 0;
      await _pumpResult(
        tester,
        result: _completeResult,
        pageSaver: (_, __) async {
          writes++;
          throw const PreferenceOutcomeUnknownException('kl_bookshelf_v1');
        },
        size: const Size(390, 844),
        textScale: 1.3,
      );

      final save = find.widgetWithText(SoriButton, t.bookResultSave);
      await tester.scrollUntilVisible(
        save,
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();

      final warning = find.bySemanticsLabel(t.bookResultSaveUnresolvedBody);
      expect(warning, findsOneWidget);
      expect(
        tester
            .getSemantics(warning)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      final unresolved = find.widgetWithText(
        SoriButton,
        t.bookResultSaveUnresolved,
      );
      _expectDisabledButtonSemantics(
        tester,
        unresolved,
        t.bookResultSaveUnresolved,
      );
      expect(writes, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('loading and error states stay localized and retryable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      final analysis = Completer<BookAnalysisResult>();
      await _pumpResultWithAnalyzer(
        tester,
        locale: locale,
        analyzer: ({required text, required targetLang}) => analysis.future,
      );
      expect(find.text(t.bookResultAnalyzing), findsOneWidget);
      expect(tester.takeException(), isNull);

      analysis.completeError(StateError('private backend detail'));
      await tester.pumpAndSettle();
      expect(find.text(t.loadErrorTryAgain), findsOneWidget);
      expect(find.textContaining('private backend detail'), findsNothing);
      final errorStatus = find.bySemanticsLabel(t.loadErrorTryAgain);
      expect(errorStatus, findsOneWidget);
      expect(
        tester
            .getSemantics(errorStatus)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      final retry = find.widgetWithText(SoriButton, t.btnRetry);
      _expectEnabledButtonSemantics(tester, retry, t.btnRetry);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });
}

BookAnalysisResult _localizedCompleteResult(String language) {
  if (language != 'en') return _completeResult;
  return const BookAnalysisResult(
    words: <ExtractedWord>[
      ExtractedWord(
        korean: '안녕하세요',
        romanization: 'annyeonghaseyo',
        posDe: 'Greeting',
        translationDe: '',
        translationEn: 'Hello',
        translationLanguage: 'en',
        exampleKorean: '안녕하세요, 반갑습니다.',
        exampleDe: 'Hello, nice to meet you.',
        savedToPackId: null,
        definitionKo: '만났을 때 하는 인사말',
        sourceUnitId: 'unit-word',
      ),
    ],
    expressions: <ExtractedExpression>[
      ExtractedExpression(
        korean: '반갑습니다',
        translationDe: '',
        translationEn: 'Nice to meet you',
        translationLanguage: 'en',
        sourceUnitId: 'unit-expression',
      ),
    ],
    grammar: <GrammarHit>[
      GrammarHit(
        patternId: 'g_polite',
        nameDe: 'Polite ending',
        matchedText: '습니다',
        level: 'A1',
        explanationDe: 'Formal polite statement.',
        sourceUnitId: 'unit-grammar',
      ),
    ],
    sentences: <TranslatedSentence>[
      TranslatedSentence(
        korean: '안녕하세요, 반갑습니다.',
        translationDe: 'Hello, nice to meet you.',
        translationLanguage: 'en',
        sourceUnitId: 'unit-sentence',
      ),
    ],
    warnings: <String>[],
    analysisLanguage: 'en',
  );
}

Future<void> _pumpResult(
  WidgetTester tester, {
  Locale locale = const Locale('de'),
  Size size = const Size(320, 640),
  double textScale = 2,
  required BookAnalysisResult result,
  BookPageSaver? pageSaver,
}) => _pumpResultWithAnalyzer(
  tester,
  locale: locale,
  size: size,
  textScale: textScale,
  analyzer: ({required text, required targetLang}) async => result,
  pageSaver: pageSaver,
);

Future<void> _pumpResultWithAnalyzer(
  WidgetTester tester, {
  Locale locale = const Locale('de'),
  Size size = const Size(320, 640),
  double textScale = 2,
  required BookAnalyzer analyzer,
  BookPageSaver? pageSaver,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SoriTypeScale(child: child!),
      ),
      home: BookResultScreen(
        args: const <String, dynamic>{'text': '안녕하세요, 반갑습니다.'},
        analyzer: analyzer,
        pageSaver: pageSaver,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _expectLiveHeader(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isHeader, isTrue);
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

Future<void> _expectEnabledIconSemantics(
  WidgetTester tester,
  String label,
) async {
  final icon = find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == label,
  );
  expect(icon, findsOneWidget);
  await tester.scrollUntilVisible(
    icon,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectEnabledButtonSemantics(
  WidgetTester tester,
  Finder finder,
  String label,
) {
  expect(finder, findsOneWidget);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  expect(tester.widget<SoriButton>(finder).onTap, isNotNull);
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectDisabledButtonSemantics(
  WidgetTester tester,
  Finder finder,
  String label,
) {
  expect(finder, findsOneWidget);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  expect(tester.widget<SoriButton>(finder).onTap, isNull);
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
}

void _expectOutlinedBoundaryContrast(WidgetTester tester, Finder action) {
  final decorated = find.descendant(
    of: action,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
  expect(decorated, findsOneWidget);
  final box = tester.widget<Container>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final renderedBorder = Color.alphaBlend(border.top.color, SoriColors.lightBg);
  expect(
    SoriColors.contrastRatio(renderedBorder, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}
