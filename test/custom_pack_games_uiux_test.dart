import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
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
          final lastChoice = choices.last;
          final lastChoiceFinder = find.bySemanticsLabel(lastChoice.text);
          _expectBoundaryContrast(tester, lastChoiceFinder);
          _expectLocaleMeanings(
            tester,
            locale,
            choices.map((item) => item.text),
          );
          await _tapFatal(tester, lastChoiceFinder);
          _expectLiveRegion(
            tester,
            lastChoice.isCorrect ? t.statsCorrect : t.statsWrong,
          );
          final revealedChoice = tester
              .getSemantics(lastChoiceFinder)
              .getSemanticsData();
          expect(revealedChoice.flagsCollection.isSelected, ui.Tristate.isTrue);
          expect(revealedChoice.hasAction(ui.SemanticsAction.tap), isFalse);
          _expectExecutableButton(tester, _soriButton(t.btnNext));
          await _tapFatal(tester, _soriButton(t.btnNext));
          _expectNoException(tester);

          await _pumpGame(
            tester,
            const CustomPackMatchingScreen(packId: _packId, words: _words),
            locale: locale,
            viewport: viewport,
          );
          await _pumpUntil(tester, _firstVisibleKoreanFinder());
          _expectTooltipButton(tester, t.btnClose, minHeight: 48);
          final visibleMatchingWords = _words
              .where(
                (word) =>
                    find.bySemanticsLabel(word.korean).evaluate().isNotEmpty,
              )
              .toList();
          final matchingKorean = visibleMatchingWords.last.korean;
          final left = find.bySemanticsLabel(matchingKorean);
          _expectExecutableButton(tester, left, minHeight: 48);
          _expectBoundaryContrast(tester, left);
          final meaning = _word(
            matchingKorean,
          ).translationFor(locale.languageCode);
          final rightData = tester
              .getSemantics(find.bySemanticsLabel(meaning))
              .getSemanticsData();
          expect(rightData.flagsCollection.isButton, isTrue);
          expect(rightData.hasAction(ui.SemanticsAction.tap), isFalse);
          _expectLocaleMeanings(tester, locale, [meaning]);
          await _tapFatal(tester, left);
          final selectedLeft = tester.getSemantics(left).getSemanticsData();
          expect(selectedLeft.flagsCollection.isSelected, ui.Tristate.isTrue);
          _expectBoundaryContrast(tester, find.bySemanticsLabel(meaning));
          await _tapFatal(tester, find.bySemanticsLabel(meaning));
          _expectLiveRegion(tester, t.statsCorrect);
          final matchedLeft = tester.getSemantics(left).getSemanticsData();
          expect(matchedLeft.hasAction(ui.SemanticsAction.tap), isFalse);
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
          await tester.enterText(find.byType(TextField), 'not-an-answer');
          await _tapFatal(tester, _soriButton(_submitLabel(locale)));
          final feedbackData = tester
              .getSemantics(
                find.byKey(const ValueKey('custom-typing-feedback')),
              )
              .getSemanticsData();
          expect(feedbackData.label, contains(t.statsWrong));
          expect(feedbackData.flagsCollection.isLiveRegion, isTrue);
          final fieldData = tester
              .getSemantics(
                find.byKey(const ValueKey('custom-typing-field-state')),
              )
              .getSemanticsData();
          expect(fieldData.flagsCollection.isEnabled, ui.Tristate.isFalse);
          _expectExecutableButton(tester, _soriButton(t.btnNext));
          await _tapFatal(tester, _soriButton(t.btnNext));
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

  testWidgets('quiz keeps automatic advance when motion is enabled', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    await _pumpGame(
      tester,
      const CustomPackQuizScreen(packId: _packId, words: _words),
      locale: const Locale('en'),
      viewport: _viewports[2],
      disableAnimations: false,
    );
    await _pumpUntil(tester, find.byType(QuizChoice));
    final correct = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .singleWhere((choice) => choice.isCorrect);

    await _tapFatal(tester, find.bySemanticsLabel(correct.text));

    expect(_soriButton(t.btnNext), findsNothing);
    expect(find.text('1 / 8'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 899));
    expect(find.text('1 / 8'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('2 / 8'), findsOneWidget);
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
        await _tapFatal(tester, _soriButton(t.btnNext));
        answered++;
        expect(answered, lessThanOrEqualTo(_words.length));
      }

      expect(answered, _words.length);
      expect(Storage.xp, (_words.length - 1) * 4);
      expect(Storage.wrongCountOf(missedKorean!), 1);
      final missedCard = Storage.srsCard(missedKorean);
      expect(missedCard!.ease, 2.3);
      expect(missedCard.reviewCount, 1);
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
      await _completeMatchingRound(tester, languageCode: 'en');
      await tester.pump();
      expect(Storage.xp, 18);
      expect(find.text('+18 XP'), findsOneWidget);
      _expectLiveRegion(tester, '${t.wbMatchingDone}. ${t.wbMatchingDoneBody}');
      _expectExecutableButton(tester, _soriButton(t.quizAgain));
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

  testWidgets('typing wrong answer preserves negative SRS and exact TTS', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    final spoken = <String>[];
    final semantics = tester.ensureSemantics();
    await _pumpGame(
      tester,
      CustomPackTypingScreen(
        packId: _packId,
        words: [_words.first],
        speaker: spoken.add,
      ),
      locale: const Locale('en'),
      viewport: _viewports[2],
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    await tester.enterText(find.byType(TextField), '학생');
    await _tapFatal(tester, _soriButton(t.btnSubmit));

    _expectLiveRegion(
      tester,
      '${t.statsWrong}. ${t.wbTypingAnswer(_words.first.korean)}',
    );
    expect(spoken, [_words.first.korean]);
    expect(Storage.wrongCountOf(_words.first.korean), 1);
    final card = Storage.srsCard(_words.first.korean);
    expect(card!.ease, 2.3);
    expect(card.intervalDays, 1);
    expect(card.reviewCount, 1);
    await _tapFatal(tester, _soriButton(t.btnNext));
    await tester.pump();
    expect(Storage.xp, 0);
    _expectLiveRegion(tester, '${t.quizResultTitle}. ${t.quizScore(0, 1)}');
    semantics.dispose();
  });

  testWidgets('all custom games render the reviewed fallback meaning', (
    tester,
  ) async {
    final fallbackWords = _words.take(4).map(_withoutEnglish).toList();

    await _pumpGame(
      tester,
      CustomPackQuizScreen(packId: _packId, words: fallbackWords),
      locale: const Locale('en'),
      viewport: _viewports[2],
    );
    await _pumpUntil(tester, find.byType(QuizChoice));
    final quizMeanings = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .map((choice) => choice.text)
        .toSet();
    expect(
      quizMeanings,
      fallbackWords.map((word) => word.translationDe).toSet(),
    );

    await _pumpGame(
      tester,
      CustomPackMatchingScreen(packId: _packId, words: fallbackWords),
      locale: const Locale('en'),
      viewport: _viewports[2],
    );
    await _pumpUntil(tester, _firstVisibleKoreanFinder());
    expect(
      fallbackWords.any(
        (word) =>
            find.bySemanticsLabel(word.translationDe).evaluate().isNotEmpty,
      ),
      isTrue,
    );

    await _pumpGame(
      tester,
      CustomPackTypingScreen(packId: _packId, words: [fallbackWords.first]),
      locale: const Locale('en'),
      viewport: _viewports[2],
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    expect(find.text(fallbackWords.first.translationDe), findsOneWidget);
    _expectNoException(tester);
  });

  testWidgets('mid-round locale switches preserve progress and evidence', (
    tester,
  ) async {
    final de = await AppL10n.delegate.load(const Locale('de'));
    final en = await AppL10n.delegate.load(const Locale('en'));

    final quizLocale = ValueNotifier(const Locale('de'));
    addTearDown(quizLocale.dispose);
    await _pumpSwitchableGame(
      tester,
      const CustomPackQuizScreen(packId: _packId, words: _words),
      locale: quizLocale,
    );
    await _pumpUntil(tester, find.byType(QuizChoice));
    final quizWord = _visibleKorean();
    final correctQuizChoice = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .singleWhere((choice) => choice.isCorrect);
    await _tapFatal(tester, find.bySemanticsLabel(correctQuizChoice.text));
    _expectLiveRegion(tester, de.statsCorrect);
    final quizReviews = Storage.srsCard(quizWord)!.reviewCount;
    quizLocale.value = const Locale('en');
    await tester.pump();
    _expectLiveRegion(tester, en.statsCorrect);
    expect(find.text(correctQuizChoice.text), findsOneWidget);
    expect(Storage.srsCard(quizWord)!.reviewCount, quizReviews);
    await _tapFatal(tester, _soriButton(en.btnNext));

    final matchingLocale = ValueNotifier(const Locale('de'));
    addTearDown(matchingLocale.dispose);
    await _pumpSwitchableGame(
      tester,
      const CustomPackMatchingScreen(packId: _packId, words: _words),
      locale: matchingLocale,
    );
    await _pumpUntil(tester, _firstVisibleKoreanFinder());
    final matchingWord = _visibleKorean();
    final matchingLeft = find.bySemanticsLabel(matchingWord);
    await _tapFatal(tester, matchingLeft);
    await _tapFatal(
      tester,
      find.bySemanticsLabel(_word(matchingWord).translationDe),
    );
    final matchingReviews = Storage.srsCard(matchingWord)!.reviewCount;
    matchingLocale.value = const Locale('en');
    await tester.pump();
    final preservedMatch = tester.getSemantics(matchingLeft).getSemanticsData();
    expect(preservedMatch.hasAction(ui.SemanticsAction.tap), isFalse);
    expect(Storage.srsCard(matchingWord)!.reviewCount, matchingReviews);

    final typingLocale = ValueNotifier(const Locale('de'));
    addTearDown(typingLocale.dispose);
    await _pumpSwitchableGame(
      tester,
      CustomPackTypingScreen(packId: _packId, words: [_words.first]),
      locale: typingLocale,
    );
    await _pumpUntil(tester, find.byType(SoriTextField));
    await tester.enterText(find.byType(TextField), _words.first.korean);
    await _tapFatal(tester, _soriButton(de.btnSubmit));
    final typingReviews = Storage.srsCard(_words.first.korean)!.reviewCount;
    typingLocale.value = const Locale('en');
    await tester.pump();
    _expectLiveRegion(tester, en.statsCorrect);
    expect(find.text(_words.first.translationDe), findsOneWidget);
    expect(find.text(_words.first.translationEn), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      _words.first.korean,
    );
    expect(Storage.srsCard(_words.first.korean)!.reviewCount, typingReviews);
    _expectExecutableButton(tester, _soriButton(en.btnNext));
    _expectNoException(tester);
  });

  for (final target in [
    (locale: const Locale('de'), viewport: _viewports.first),
    (locale: const Locale('en'), viewport: _viewports[1]),
  ]) {
    testWidgets(
      'result and replay stay reachable in ${target.locale.languageCode} '
      '@ ${target.viewport.size.width.toInt()}x'
      '${target.viewport.size.height.toInt()}',
      (tester) async {
        final t = await AppL10n.delegate.load(target.locale);
        final semantics = tester.ensureSemantics();

        await _pumpGame(
          tester,
          CustomPackQuizScreen(packId: _packId, words: _words.take(4).toList()),
          locale: target.locale,
          viewport: target.viewport,
        );
        await _pumpUntil(tester, find.byType(QuizChoice));
        await _completeQuizRound(tester, t);
        _expectLiveRegion(tester, '${t.quizResultTitle}. ${t.quizScore(4, 4)}');
        await _tapFatal(tester, _soriButton(t.quizAgain));
        expect(find.byType(QuizChoice), findsWidgets);

        await _pumpGame(
          tester,
          CustomPackMatchingScreen(
            packId: _packId,
            words: _words.take(2).toList(),
          ),
          locale: target.locale,
          viewport: target.viewport,
        );
        await _pumpUntil(tester, _firstVisibleKoreanFinder());
        await _completeMatchingRound(
          tester,
          languageCode: target.locale.languageCode,
        );
        _expectLiveRegion(
          tester,
          '${t.wbMatchingDone}. ${t.wbMatchingDoneBody}',
        );
        await _tapFatal(tester, _soriButton(t.quizAgain));
        expect(_firstVisibleKoreanFinder(), findsWidgets);

        await _pumpGame(
          tester,
          CustomPackTypingScreen(packId: _packId, words: [_words.first]),
          locale: target.locale,
          viewport: target.viewport,
        );
        await _pumpUntil(tester, find.byType(SoriTextField));
        await tester.enterText(find.byType(TextField), _words.first.korean);
        await _tapFatal(tester, _soriButton(t.btnSubmit));
        await _tapFatal(tester, _soriButton(t.btnNext));
        await tester.pump();
        _expectLiveRegion(tester, '${t.quizResultTitle}. ${t.quizScore(1, 1)}');
        await _tapFatal(tester, _soriButton(t.quizAgain));
        expect(find.byType(SoriTextField), findsOneWidget);
        _expectNoException(tester);
        semantics.dispose();
      },
    );
  }
}

ExtractedWord _withoutEnglish(ExtractedWord word) => ExtractedWord(
  korean: word.korean,
  romanization: word.romanization,
  posDe: word.posDe,
  translationDe: word.translationDe,
  translationEn: '',
  exampleKorean: word.exampleKorean,
  exampleDe: word.exampleDe,
  savedToPackId: word.savedToPackId,
);

Future<void> _completeQuizRound(WidgetTester tester, AppL10n t) async {
  var answered = 0;
  while (find.byType(QuizChoice).evaluate().isNotEmpty) {
    final choice = tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .singleWhere((candidate) => candidate.isCorrect);
    await _tapFatal(tester, find.bySemanticsLabel(choice.text));
    _expectLiveRegion(tester, t.statsCorrect);
    await _tapFatal(tester, _soriButton(t.btnNext));
    answered++;
    expect(answered, lessThanOrEqualTo(8));
  }
  expect(answered, greaterThan(0));
}

Future<void> _completeMatchingRound(
  WidgetTester tester, {
  required String languageCode,
}) async {
  var matched = 0;
  while (true) {
    ExtractedWord? next;
    for (final word in _words) {
      final finder = find.bySemanticsLabel(word.korean);
      if (finder.evaluate().length != 1) {
        continue;
      }
      final data = tester.getSemantics(finder).getSemanticsData();
      if (data.hasAction(ui.SemanticsAction.tap)) {
        next = word;
        break;
      }
    }
    if (next == null) {
      break;
    }
    await _tapFatal(tester, find.bySemanticsLabel(next.korean));
    await _tapFatal(
      tester,
      find.bySemanticsLabel(next.translationFor(languageCode)),
    );
    matched++;
    expect(matched, lessThanOrEqualTo(6));
  }
  expect(matched, greaterThan(0));
  await tester.pump();
}

Future<void> _pumpGame(
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

Future<void> _pumpSwitchableGame(
  WidgetTester tester,
  Widget screen, {
  required ValueNotifier<Locale> locale,
}) async {
  tester.view.physicalSize = _viewports[2].size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (context, activeLocale, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: activeLocale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              padding: _safeInsets,
              viewPadding: _safeInsets,
              textScaler: const TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: SoriTypeScale(child: child!),
          );
        },
        home: screen,
      ),
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

void _expectBoundaryContrast(WidgetTester tester, Finder control) {
  final decorated = find.descendant(
    of: control,
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
  expect(finder, findsOneWidget);
  final pressable = find.descendant(
    of: finder,
    matching: find.byType(GestureDetector),
  );
  final tapTarget = pressable.evaluate().length == 1 ? pressable : finder;
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tapTarget.evaluate().single,
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  final targetBox = tester.renderObject<RenderBox>(tapTarget);
  final candidates = <Offset>[
    const Offset(0.5, 0.5),
    const Offset(0.25, 0.5),
    const Offset(0.75, 0.5),
    const Offset(0.5, 0.25),
    const Offset(0.5, 0.75),
  ];
  Offset? hitPoint;
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
      hitPoint = point;
      break;
    }
  }
  expect(
    hitPoint,
    isNotNull,
    reason: 'The requested control has no pointer-owned point after scrolling.',
  );
  await tester.tapAt(hitPoint!);
  await tester.pump();
}

void _expectNoException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
