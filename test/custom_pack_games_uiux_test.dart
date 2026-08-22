import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _packId = 'phase-5b-custom-games';
const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

const _viewports = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

const _words = <ExtractedWord>[
  ExtractedWord(
    korean: '학교',
    romanization: 'hakgyo',
    posDe: 'Nomen',
    translationDe: 'Schule',
    translationEn: 'school',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '학생',
    romanization: 'haksaeng',
    posDe: 'Nomen',
    translationDe: 'Schüler',
    translationEn: 'student',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '친구',
    romanization: 'chingu',
    posDe: 'Nomen',
    translationDe: 'Freund',
    translationEn: 'friend',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '선생님',
    romanization: 'seonsaengnim',
    posDe: 'Nomen',
    translationDe: 'Lehrkraft',
    translationEn: 'teacher',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '책',
    romanization: 'chaek',
    posDe: 'Nomen',
    translationDe: 'Buch',
    translationEn: 'book',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '연필',
    romanization: 'yeonpil',
    posDe: 'Nomen',
    translationDe: 'Bleistift',
    translationEn: 'pencil',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '교실',
    romanization: 'gyosil',
    posDe: 'Nomen',
    translationDe: 'Klassenraum',
    translationEn: 'classroom',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
  ExtractedWord(
    korean: '학급',
    romanization: 'hakgeup',
    posDe: 'Nomen',
    translationDe: 'Klasse',
    translationEn: 'classroom',
    exampleKorean: '',
    exampleDe: '',
    savedToPackId: null,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpQuiz': true,
      'kl_tut_cpMatching': true,
      'kl_tut_cpTyping': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: _packId,
        name: 'Stored pack',
        words: const [
          ExtractedWord(
            korean: '저장',
            romanization: 'jeojang',
            posDe: 'Nomen',
            translationDe: 'Speicher',
            translationEn: 'storage',
            exampleKorean: '',
            exampleDe: '',
            savedToPackId: null,
          ),
        ],
      ),
    );
  });

  test('ExtractedWord selects the active meaning with a safe fallback', () {
    expect(_words.first.translationFor('de'), 'Schule');
    expect(_words.first.translationFor('en'), 'school');
    const legacy = ExtractedWord(
      korean: '옛말',
      romanization: '',
      posDe: '',
      translationDe: 'legacy meaning',
      translationEn: '',
      exampleKorean: '',
      exampleDe: '',
      savedToPackId: null,
    );
    expect(legacy.translationFor('en'), 'legacy meaning');
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in _viewports) {
      testWidgets(
        'custom games use the locked matrix in ${locale.languageCode} '
        '@ ${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
        'x${viewport.textScale}',
        (tester) async {
          final t = await AppL10n.delegate.load(locale);
          final semantics = tester.ensureSemantics();

          await _pumpGame(
            tester,
            const CustomPackQuizScreen(packId: _packId, words: _words),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, find.byType(QuizChoice));
          expect(find.byType(SoriStudyFrame), findsOneWidget);
          _expectTooltipButton(tester, t.btnClose, minHeight: 48);
          final quizKorean = _visibleKorean();
          _expectTooltipButton(
            tester,
            t.ttsListenTarget(quizKorean),
            minHeight: 48,
          );
          final choices = tester
              .widgetList<QuizChoice>(find.byType(QuizChoice))
              .toList();
          expect(choices, hasLength(4));
          for (final choice in choices) {
            _expectExecutableButton(
              tester,
              find.bySemanticsLabel(choice.text),
              minHeight: 48,
            );
          }
          _expectLocaleMeanings(
            tester,
            locale,
            choices.map((item) => item.text),
          );
          _expectNoException(tester);

          await _pumpGame(
            tester,
            const CustomPackMatchingScreen(packId: _packId, words: _words),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, _firstVisibleKoreanFinder());
          _expectTooltipButton(tester, t.btnClose, minHeight: 48);
          final matchingKorean = _visibleKorean();
          final left = find.bySemanticsLabel(matchingKorean);
          _expectExecutableButton(tester, left, minHeight: 48);
          final meaning = _word(
            matchingKorean,
          ).translationFor(locale.languageCode);
          final rightData = tester
              .getSemantics(find.bySemanticsLabel(meaning))
              .getSemanticsData();
          expect(rightData.flagsCollection.isButton, isTrue);
          expect(rightData.hasAction(ui.SemanticsAction.tap), isFalse);
          _expectLocaleMeanings(tester, locale, [meaning]);
          _expectNoException(tester);

          await _pumpGame(
            tester,
            const CustomPackTypingScreen(packId: _packId, words: _words),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, find.byType(SoriTextField));
          expect(find.byType(SoriTextField), findsOneWidget);
          _expectTooltipButton(tester, t.btnClose, minHeight: 48);
          expect(
            _words.any(
              (word) => find
                  .text(word.translationFor(locale.languageCode))
                  .evaluate()
                  .isNotEmpty,
            ),
            isTrue,
          );
          _expectExecutableButton(tester, _soriButton(_submitLabel(locale)));
          _expectNoException(tester);
          semantics.dispose();
        },
      );
    }

    testWidgets('missing and insufficient custom packs stay true-empty in '
        '${locale.languageCode}', (tester) async {
      await _pumpGame(
        tester,
        const CustomPackQuizScreen(packId: 'missing'),
        locale: locale,
        viewport: _viewports.first,
      );
      expect(find.byType(SoriEmptyState), findsOneWidget);

      await _pumpGame(
        tester,
        const CustomPackMatchingScreen(packId: _packId),
        locale: locale,
        viewport: _viewports.first,
      );
      expect(find.byType(SoriEmptyState), findsOneWidget);

      await _pumpGame(
        tester,
        const CustomPackTypingScreen(packId: 'missing'),
        locale: locale,
        viewport: _viewports.first,
      );
      expect(find.byType(SoriEmptyState), findsOneWidget);
      _expectNoException(tester);
    });
  }

  testWidgets('matching rejects an active-locale duplicate-only round', (
    tester,
  ) async {
    await _pumpGame(
      tester,
      CustomPackMatchingScreen(packId: _packId, words: [_words[6], _words[7]]),
      locale: const Locale('en'),
      viewport: _viewports.first,
    );
    expect(find.byType(SoriEmptyState), findsOneWidget);
    expect(find.text('classroom'), findsNothing);
    _expectNoException(tester);
  });

  testWidgets(
    'quiz keeps override, SRS, score, XP, and live result contracts',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('en'));
      final semantics = tester.ensureSemantics();
      await _pumpGame(
        tester,
        const CustomPackQuizScreen(packId: _packId, words: _words),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      await _pumpUntil(tester, find.byType(QuizChoice));
      expect(find.text('storage'), findsNothing);

      String? missedKorean;
      var answered = 0;
      while (find.byType(QuizChoice).evaluate().isNotEmpty) {
        final current = _visibleKorean();
        final choices = tester
            .widgetList<QuizChoice>(find.byType(QuizChoice))
            .toList();
        final choice = answered == 0
            ? choices.firstWhere((item) => !item.isCorrect)
            : choices.singleWhere((item) => item.isCorrect);
        if (answered == 0) {
          missedKorean = current;
        }
        await _tapFatal(tester, find.bySemanticsLabel(choice.text));
        _expectLiveRegion(
          tester,
          choice.isCorrect ? t.statsCorrect : t.statsWrong,
        );
        await tester.pump(const Duration(milliseconds: 901));
        answered++;
        expect(answered, lessThanOrEqualTo(_words.length));
      }

      expect(answered, _words.length);
      expect(Storage.xp, (_words.length - 1) * 4);
      expect(Storage.wrongCountOf(missedKorean!), 1);
      for (final word in _words) {
        expect(Storage.srsCard(word.korean), isNotNull);
      }
      _expectLiveRegion(tester, '${t.quizResultTitle}. ${t.quizScore(7, 8)}');
      _expectExecutableButton(tester, _soriButton(t.quizAgain));
      await _tapFatal(tester, _soriButton(t.quizAgain));
      expect(find.byType(QuizChoice), findsWidgets);
      semantics.dispose();
    },
  );

  testWidgets(
    'matching keeps six unique pairs, first-miss evidence, and state semantics',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('en'));
      final semantics = tester.ensureSemantics();
      await _pumpGame(
        tester,
        const CustomPackMatchingScreen(packId: _packId, words: _words),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      await _pumpUntil(tester, _firstVisibleKoreanFinder());

      final visibleKorean = _words
          .where(
            (word) => find.bySemanticsLabel(word.korean).evaluate().isNotEmpty,
          )
          .toList();
      expect(visibleKorean, hasLength(6));
      expect(
        _words
            .map((word) => word.translationFor('en'))
            .toSet()
            .where(
              (meaning) => find.bySemanticsLabel(meaning).evaluate().isNotEmpty,
            ),
        hasLength(6),
      );

      final chosen = visibleKorean.first;
      final left = find.bySemanticsLabel(chosen.korean);
      await _tapFatal(tester, left);
      final selected = tester.getSemantics(left).getSemanticsData();
      expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);

      final correctMeaning = chosen.translationFor('en');
      final wrongMeaning = _words
          .map((word) => word.translationFor('en'))
          .firstWhere(
            (meaning) =>
                meaning != correctMeaning &&
                find.bySemanticsLabel(meaning).evaluate().isNotEmpty,
          );
      _expectExecutableButton(
        tester,
        find.bySemanticsLabel(wrongMeaning),
        minHeight: 48,
      );
      await _tapFatal(tester, find.bySemanticsLabel(wrongMeaning));
      _expectLiveRegion(tester, t.statsWrong);
      expect(Storage.wrongCountOf(chosen.korean), 1);
      await tester.pump(const Duration(milliseconds: 500));

      await _tapFatal(tester, find.bySemanticsLabel(correctMeaning));
      _expectLiveRegion(tester, t.statsCorrect);
      final matched = tester.getSemantics(left).getSemanticsData();
      expect(matched.value, contains(t.statsCorrect));
      expect(matched.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(Storage.wrongCountOf(chosen.korean), 1);
      expect(Storage.srsCard(chosen.korean)!.intervalDays, 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'typing normalizes spaces and preserves SRS, XP, and live result',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('en'));
      final semantics = tester.ensureSemantics();
      await _pumpGame(
        tester,
        CustomPackTypingScreen(packId: _packId, words: [_words.first]),
        locale: const Locale('en'),
        viewport: _viewports[2],
      );
      await _pumpUntil(tester, find.byType(SoriTextField));
      expect(find.text('school'), findsOneWidget);
      expect(find.text('Schule'), findsNothing);
      await tester.enterText(find.byType(TextField), '학 교');
      await _tapFatal(tester, _soriButton(t.btnSubmit));
      _expectLiveRegion(tester, t.statsCorrect);
      await _tapFatal(tester, _soriButton(t.btnNext));
      await tester.pump();

      expect(Storage.xp, 5);
      expect(Storage.srsCard('학교'), isNotNull);
      _expectLiveRegion(tester, '${t.quizResultTitle}. ${t.quizScore(1, 1)}');
      _expectExecutableButton(tester, _soriButton(t.quizAgain));
      semantics.dispose();
    },
  );
}

Future<void> _pumpGame(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required ({Size size, double textScale}) viewport,
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
            disableAnimations: true,
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

String _submitLabel(Locale locale) =>
    locale.languageCode == 'de' ? 'Prüfen' : 'Check';

Finder _firstVisibleKoreanFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      _words.any((word) => widget.properties.label == word.korean),
);

String _visibleKorean() => _words
    .firstWhere(
      (word) => find.bySemanticsLabel(word.korean).evaluate().isNotEmpty,
    )
    .korean;

ExtractedWord _word(String korean) =>
    _words.singleWhere((word) => word.korean == korean);

void _expectLocaleMeanings(
  WidgetTester tester,
  Locale locale,
  Iterable<String> visible,
) {
  final expected = _words
      .map((word) => word.translationFor(locale.languageCode))
      .toSet();
  final other = _words
      .map(
        (word) =>
            word.translationFor(locale.languageCode == 'en' ? 'de' : 'en'),
      )
      .toSet();
  expect(visible.every(expected.contains), isTrue);
  for (final meaning in other.difference(expected)) {
    expect(find.text(meaning), findsNothing);
  }
}

void _expectExecutableButton(
  WidgetTester tester,
  Finder finder, {
  double? minHeight,
}) {
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  if (minHeight != null) {
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
  }
}

void _expectTooltipButton(
  WidgetTester tester,
  String tooltip, {
  required double minHeight,
}) {
  final finder = find.byTooltip(tooltip);
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(data.tooltip, tooltip);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(minHeight));
}

void _expectLiveRegion(WidgetTester tester, String label) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.liveRegion == true &&
        widget.properties.label == label,
  );
  expect(finder, findsOneWidget);
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, contains(label));
  expect(data.flagsCollection.isLiveRegion, isTrue);
}

Future<void> _tapFatal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    await tester.tap(finder);
    await tester.pump();
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  }
}

void _expectNoException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
