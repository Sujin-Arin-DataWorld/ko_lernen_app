import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/hard_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _savedWord = ExtractedWord(
  korean: '사랑',
  romanization: 'sarang',
  posDe: 'Substantiv',
  translationDe: 'eine beständige tiefe Zuneigung',
  translationEn: 'a lasting and deep affection',
  translationLanguage: 'en',
  exampleKorean: '사랑은 오래 참아요.',
  exampleDe: 'Love is patient.',
  savedToPackId: null,
);
const _secondSavedWord = ExtractedWord(
  korean: '배우다',
  romanization: 'baeuda',
  posDe: 'Verb',
  translationDe: 'lernen',
  translationEn: 'learn',
  translationLanguage: 'en',
  exampleKorean: '한국어를 배워요.',
  exampleDe: 'I learn Korean.',
  savedToPackId: null,
);
const _hardWord = Vocab(
  id: 'local-tools-hard-word',
  korean: '그리움',
  romanization: 'geurium',
  german: 'tiefe Sehnsucht',
  english: 'deep longing',
  level: 'B2',
  posDe: 'Nomen',
  posEn: 'noun',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

CustomPack get _savedPack => CustomPack.manual(
  id: 'local-word-tools-pack',
  name: 'Local word tools',
  words: const <ExtractedWord>[_savedWord, _secondSavedWord],
  createdAt: DateTime.utc(2026, 8, 22),
);

const _localizedFilterPartsOfSpeech = <String>[
  'Adjektiv',
  'Adverb',
  'Ausdruck',
  'Interjektion',
  'Konjunktion',
  'Partikel',
  'Pronomen',
  'Zahlwort',
  'Verbphrase',
];

ExtractedWord _filterWord(int index, {required String language}) =>
    ExtractedWord.manual(
      korean: '필터단어$index',
      romanization: 'filter$index',
      posDe: language == 'de'
          ? 'Ausführliche einzigartige Wortart Nummer $index'
          : _localizedFilterPartsOfSpeech[index],
      translationDe: 'Bedeutung $index',
      translationEn: 'meaning $index',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Complete the real asset read before a widget's fake async zone can cache
  // an unfinished rootBundle future while resolving saved-word translations.
  setUpAll(() async {
    expect(await DataLoader.loadVocab(), isNotEmpty);
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_custom_packs_v1': '{}',
      'kl_tut_hardWords': true,
    });
    await Storage.init();
    await Storage.setTutSeen('hardWords');
    await CustomPackService.save(_savedPack);
    for (var attempt = 0; attempt < 3; attempt += 1) {
      await Storage.incrementWrongCount(_hardWord.korean);
    }
  });

  testWidgets(
    'populated word search and hard words reflow in the locked DE/EN matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const cases = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final expectedSavedMeaning = locale.languageCode == 'en'
            ? _savedWord.translationEn
            : _savedWord.translationDe;
        final expectedHardMeaning = _hardWord.translationFor(
          locale.languageCode,
        );
        for (final testCase in cases) {
          await _pumpScreen(
            tester,
            const WordbookSearchScreen(),
            locale: locale,
            size: testCase.size,
            textScale: testCase.textScale,
          );
          await _scrollTo(tester, find.text(_savedWord.korean));
          expect(find.text(expectedSavedMeaning), findsOneWidget);
          expect(tester.takeException(), isNull);

          await _pumpScreen(
            tester,
            HardWordsScreen(deckLoader: () async => const <Vocab>[_hardWord]),
            locale: locale,
            size: testCase.size,
            textScale: testCase.textScale,
          );
          await _finishAsyncLoad(tester);
          await _scrollTo(tester, find.text(_hardWord.korean));
          expect(find.text(expectedHardMeaning), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'search filters, result status, clear, and TTS expose final semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      const locale = Locale('en');
      final t = lookupAppL10n(locale);
      await _pumpScreen(
        tester,
        const WordbookSearchScreen(),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );

      final allFilter = find.byKey(const ValueKey('wordbook-pos-all'));
      final nounFilter = find.byKey(const ValueKey('wordbook-pos-Substantiv'));
      expect(
        find.descendant(of: nounFilter, matching: find.text('Noun')),
        findsOneWidget,
      );
      expect(find.text('Substantiv'), findsNothing);
      expect(tester.getSize(allFilter).height, greaterThanOrEqualTo(48));
      final allData = tester.getSemantics(allFilter).getSemanticsData();
      expect(allData.flagsCollection.isButton, isTrue);
      expect(allData.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(allData.hasAction(ui.SemanticsAction.tap), isTrue);
      _expectOutlinedChipContrast(tester, nounFilter);

      await tester.tap(nounFilter);
      await tester.pump();
      _expectLiveSemantics(tester, t.wbSearchCount(1));

      await tester.enterText(find.byType(TextField), 'not-a-saved-word');
      await tester.pump();
      _expectLiveSemantics(tester, t.wbSearchCount(0));
      expect(
        find.widgetWithText(SoriEmptyState, t.wbSearchEmpty),
        findsOneWidget,
      );

      final clear = find.byTooltip(t.wbSearchClear);
      expect(clear, findsOneWidget);
      expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
      final clearData = tester
          .getSemantics(find.bySemanticsLabel(t.wbSearchClear))
          .getSemanticsData();
      expect(clearData.label, t.wbSearchClear);
      expect(clearData.flagsCollection.isButton, isTrue);
      expect(clearData.hasAction(ui.SemanticsAction.tap), isTrue);
      await tester.tap(clear);
      await tester.pump();

      await _expectTtsSemantics(tester, '${t.ttsListen}: ${_savedWord.korean}');
      expect(find.text(_savedWord.translationEn), findsOneWidget);
      expect(find.text(_savedWord.translationDe), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'many long filters scroll without consuming the short result surface',
    (tester) async {
      _resetViewAfterTest(tester);
      const cases = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
      ];

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        // Keep authored long-label stress in German. English uses the supported
        // translated POS labels, since unknown German prose is hidden there.
        final words = List<ExtractedWord>.generate(
          9,
          (index) => _filterWord(index, language: locale.languageCode),
        );
        await CustomPackService.save(
          CustomPack.manual(
            id: 'many-filter-pack',
            name: 'Many filters',
            words: words,
            createdAt: DateTime.utc(2026, 8, 22, 1),
          ),
        );
        for (final testCase in cases) {
          await _pumpScreen(
            tester,
            const WordbookSearchScreen(),
            locale: locale,
            size: testCase.size,
            textScale: testCase.textScale,
          );
          final filterScroll = find.descendant(
            of: find.byKey(const ValueKey('wordbook-pos-filter-scroll')),
            matching: find.byType(Scrollable),
          );
          expect(filterScroll, findsOneWidget);
          final sortedPartsOfSpeech = words.map((word) => word.posDe).toList()
            ..sort();
          final lastFilter = find.byKey(
            ValueKey('wordbook-pos-${sortedPartsOfSpeech.last}'),
          );
          for (final word in words) {
            expect(
              find.byKey(ValueKey('wordbook-pos-${word.posDe}')),
              findsOneWidget,
            );
            expect(find.text(word.posFor(locale.languageCode)), findsWidgets);
          }
          await tester.scrollUntilVisible(
            lastFilter,
            80,
            scrollable: filterScroll,
          );
          await tester.pump();
          expect(tester.getSize(lastFilter).height, greaterThanOrEqualTo(48));

          final resultList = find.byType(ListView);
          expect(resultList, findsOneWidget);
          expect(tester.getSize(resultList).height, greaterThan(0));
          await _scrollTo(tester, find.text(words.first.korean));
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  for (final newerLanguage in const ['de', 'en']) {
    testWidgets(
      'search keeps available meanings when $newerLanguage pack is newer',
      (tester) async {
        _resetViewAfterTest(tester);
        for (final language in const ['de', 'en']) {
          await CustomPackService.save(
            CustomPack.manual(
              id: 'duplicate-$language',
              name: 'Duplicate $language',
              createdAt: DateTime.utc(
                2026,
                8,
                language == newerLanguage ? 24 : 23,
              ),
              words: [
                ExtractedWord.manual(
                  korean: '우리말연습단어',
                  translationDe: language == 'de'
                      ? 'mein eigener deutscher Begriff'
                      : '',
                  translationEn: language == 'en'
                      ? 'my own English meaning'
                      : '',
                ),
              ],
            ),
          );
        }
        for (final locale in const [Locale('en'), Locale('de')]) {
          await _pumpScreen(
            tester,
            const WordbookSearchScreen(),
            locale: locale,
            size: const Size(390, 844),
            textScale: 1.3,
          );
          await _scrollTo(tester, find.text('우리말연습단어'));
          expect(find.text('우리말연습단어'), findsOneWidget);
          expect(
            find.text(
              locale.languageCode == 'en'
                  ? 'my own English meaning'
                  : 'mein eigener deutscher Begriff',
            ),
            findsOneWidget,
          );
        }
      },
    );
  }

  testWidgets(
    'locale switch ignores a hidden POS filter without replacing search state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      await CustomPackService.save(
        CustomPack.manual(
          id: 'locale-filter-de',
          name: 'German word',
          createdAt: DateTime.utc(2026, 8, 24),
          words: [
            ExtractedWord.manual(
              korean: '우리말연습단어',
              posDe: 'Nomen',
              translationDe: 'mein eigener deutscher Begriff',
            ),
          ],
        ),
      );
      await CustomPackService.save(
        CustomPack.manual(
          id: 'locale-filter-en',
          name: 'English word',
          createdAt: DateTime.utc(2026, 8, 23),
          words: [
            ExtractedWord.manual(
              korean: '우리말연습단어',
              translationDe: '',
              translationEn: 'my own English meaning',
            ),
          ],
        ),
      );
      await _pumpScreen(
        tester,
        const WordbookSearchScreen(),
        locale: const Locale('de'),
        size: const Size(390, 844),
        textScale: 1.3,
      );
      final searchState = tester.state(find.byType(WordbookSearchBody));
      final nounFilter = find.byKey(const ValueKey('wordbook-pos-Nomen'));
      await tester.tap(nounFilter);
      await tester.pump();
      expect(
        tester
            .getSemantics(nounFilter)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      _expectLiveSemantics(
        tester,
        lookupAppL10n(const Locale('de')).wbSearchCount(1),
      );

      await _pumpScreen(
        tester,
        const WordbookSearchScreen(),
        locale: const Locale('en'),
        size: const Size(390, 844),
        textScale: 1.3,
        preserveState: true,
      );
      expect(tester.state(find.byType(WordbookSearchBody)), same(searchState));
      expect(nounFilter, findsNothing);
      expect(find.text('my own English meaning'), findsOneWidget);
      final allFilter = find.byKey(const ValueKey('wordbook-pos-all'));
      expect(
        tester
            .getSemantics(allFilter)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      _expectLiveSemantics(
        tester,
        lookupAppL10n(const Locale('en')).wbSearchCount(3),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('hard-word load failure is live and retry recovers safely', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('en');
    final t = lookupAppL10n(locale);
    final recovery = Completer<List<Vocab>>();
    var attempts = 0;
    Future<List<Vocab>> loadDeck() {
      attempts += 1;
      if (attempts == 1) {
        return Future<List<Vocab>>.error(StateError('fixture load failure'));
      }
      return recovery.future;
    }

    await _pumpScreen(
      tester,
      HardWordsScreen(deckLoader: loadDeck),
      locale: locale,
      size: const Size(320, 640),
      textScale: 2,
    );
    await _finishAsyncLoad(tester);
    expect(find.byType(AppError), findsOneWidget);
    _expectLiveSemantics(tester, t.loadErrorTryAgain);

    final retry = find.bySemanticsLabel(t.btnRetry);
    expect(retry, findsOneWidget);
    await _scrollTo(tester, retry);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    final retryData = tester.getSemantics(retry).getSemanticsData();
    expect(retryData.flagsCollection.isButton, isTrue);
    expect(retryData.hasAction(ui.SemanticsAction.tap), isTrue);
    await tester.tap(retry);
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);

    recovery.complete(const <Vocab>[_hardWord]);
    await _finishAsyncLoad(tester);
    expect(find.byType(AppError), findsNothing);
    await _scrollTo(tester, find.text(_hardWord.korean));
    expect(find.text(_hardWord.english), findsOneWidget);
    await _expectTtsSemantics(tester, '${t.ttsListen}: ${_hardWord.korean}');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('hard-word actions keep one primary and exact destinations', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    const locale = Locale('de');
    final t = lookupAppL10n(locale);
    await _pumpScreen(
      tester,
      HardWordsScreen(deckLoader: () async => const <Vocab>[_hardWord]),
      locale: locale,
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _finishAsyncLoad(tester);

    final quiz = _soriButton(t.hardWordsHardQuizCta);
    final study = _soriButton(t.hardWordsStudyCta);
    expect(tester.widget<SoriButton>(quiz).variant, SoriButtonVariant.filled);
    expect(
      tester.widget<SoriButton>(study).variant,
      SoriButtonVariant.outlined,
    );
    _expectOutlinedButtonContrast(tester, study);

    await tester.tap(find.bySemanticsLabel(t.hardWordsHardQuizCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HardChoiceQuizScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _finishAsyncLoad(tester);

    await tester.tap(find.bySemanticsLabel(t.hardWordsStudyCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ReviewSessionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('both true-empty states remain reachable at 320dp and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_custom_packs_v1': '{}',
      'kl_tut_hardWords': true,
    });
    await Storage.init();
    await Storage.setTutSeen('hardWords');

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      await _pumpScreen(
        tester,
        const WordbookSearchScreen(),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(find.text(t.wbSearchNoWords), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pumpScreen(
        tester,
        HardWordsScreen(deckLoader: () async => const <Vocab>[]),
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await _finishAsyncLoad(tester);
      expect(
        find.widgetWithText(SoriEmptyState, t.hardWordsEmptyTitle),
        findsOneWidget,
      );
      final close = find.bySemanticsLabel(t.btnClose);
      expect(close, findsOneWidget);
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget home, {
  required Locale locale,
  required Size size,
  required double textScale,
  bool preserveState = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  if (!preserveState) {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: home,
    ),
  );
  await tester.pump();
}

Future<void> _finishAsyncLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _resetViewAfterTest(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets);
    await tester.drag(scrollables.last, const Offset(0, -220));
    await tester.pump();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

Future<void> _expectTtsSemantics(WidgetTester tester, String label) async {
  final action = find.byTooltip(label);
  await _scrollTo(tester, action);
  expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectLiveSemantics(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

Finder _soriButton(String label) => find.byWidgetPredicate(
  (widget) => widget is SoriButton && widget.label == label,
);

void _expectOutlinedChipContrast(WidgetTester tester, Finder chip) {
  final decorated = find.descendant(
    of: chip,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).border is Border,
    ),
  );
  expect(decorated, findsOneWidget);
  final box =
      tester.widget<AnimatedContainer>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  expect(
    SoriColors.contrastRatio(border.top.color, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}

void _expectOutlinedButtonContrast(WidgetTester tester, Finder button) {
  final decorated = find.descendant(
    of: button,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
  expect(decorated, findsOneWidget);
  final box = tester.widget<Container>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final rendered = Color.alphaBlend(border.top.color, SoriColors.lightBg);
  expect(
    SoriColors.contrastRatio(rendered, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}
