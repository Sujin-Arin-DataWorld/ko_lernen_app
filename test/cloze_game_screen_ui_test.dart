import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _item = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ＿＿＿ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich aufmerksam in der Bibliothek.',
  en: 'Today I study carefully in the library.',
  distractors: ['운동을', '요리를', '독서를'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
    await ClozeLoader.load();
    await DataLoader.loadVocab();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('cloze prompt keeps shared hierarchy and complete actions in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        _configureView(tester, viewport.size);

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: const ClozeGameScreen(items: [_item]),
          ),
        );
        await _pumpUntilVisible(tester, find.byType(ClozePromptCard));

        final koreanFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan?.toPlainText() == _item.sentenceKo,
        );
        final translation = _item.meaning(locale.languageCode);
        final translationFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.textSpan?.toPlainText() == translation,
        );
        final korean = tester.widget<Text>(koreanFinder);
        final koreanSpan = korean.textSpan! as TextSpan;
        final koreanStyle = (koreanSpan.children!.first as TextSpan).style!;
        final translationText = tester.widget<Text>(translationFinder);
        final translationSpan = translationText.textSpan! as TextSpan;
        final translationStyle =
            (translationSpan.children!.first as TextSpan).style!;
        final type = SoriTextTheme.of(tester.element(koreanFinder));

        expect(korean.maxLines, isNull);
        expect(korean.overflow, isNull);
        expect(koreanStyle.fontSize, type.koDisplay.fontSize);
        expect(koreanStyle.fontWeight, type.koDisplay.fontWeight);
        expect(translationText.maxLines, isNull);
        expect(translationText.overflow, isNull);
        expect(translationStyle.fontSize, type.gloss.fontSize);
        expect(translationStyle.fontWeight, type.gloss.fontWeight);

        final t = AppL10n.of(tester.element(find.byType(ClozeGameScreen)));
        expect(find.byType(SoriHomeAction), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        final pronunciation = t.ttsListen;
        final speakAction = find.byKey(const Key('cloze-prompt-speak'));
        expect(speakAction, findsOneWidget);
        expect(tester.widget<IconButton>(speakAction).tooltip, pronunciation);
        final speakSize = tester.getSize(speakAction);
        expect(speakSize.width, greaterThanOrEqualTo(48));
        expect(speakSize.height, greaterThanOrEqualTo(48));

        for (final option in [_item.answer, ..._item.distractors]) {
          final choice = find.widgetWithText(QuizChoice, option);
          expect(choice, findsOneWidget);
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('cloze level filter has a visible name and 48dp controls in '
        '${locale.languageCode} at 200% text', (tester) async {
      final semantics = tester.ensureSemantics();
      _configureView(tester, const Size(320, 640));

      await tester.pumpWidget(
        _host(locale: locale, textScale: 2, child: const ClozeGameScreen()),
      );

      final t = AppL10n.of(tester.element(find.byType(ClozeGameScreen)));
      final levelName = t.clozeLevelLabel;
      await _pumpUntilVisible(tester, find.byIcon(Icons.tune_rounded));
      expect(find.bySemanticsLabel(levelName), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      for (final entry in [
        ('', t.clozeLevelAll),
        ('a1', 'A1'),
        ('a2', 'A2'),
        ('b1', 'B1'),
        ('b2', 'B2'),
        ('c1', 'C1'),
        ('c2', 'C2'),
      ]) {
        final chip = find.byKey(ValueKey('sori-level-sheet-${entry.$1}'));
        final label = tester.widget<SoriChip>(chip).label;
        final text = find.descendant(of: chip, matching: find.text(label));
        expect(chip, findsOneWidget);
        expect(label, startsWith('${entry.$2} · '));
        expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
        expect(tester.widget<Text>(text).maxLines, isNull);
        expect(tester.widget<Text>(text).overflow, isNull);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('a retry keeps first-attempt scoring and still reaches result', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        textScale: 1,
        child: const ClozeGameScreen(items: [_item]),
      ),
    );
    await _pumpUntilVisible(tester, find.byType(ClozePromptCard));
    final t = AppL10n.of(tester.element(find.byType(ClozeGameScreen)));

    final wrongSentence = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.textSpan?.toPlainText() == '오늘은 운동을 합니다.',
    );
    final blankSentence = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.textSpan?.toPlainText() == _item.sentenceKo,
    );
    final correctSentence = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.textSpan?.toPlainText() == _item.fullKo,
    );

    await tester.tap(find.text(_item.distractors.first));
    await tester.pump();
    expect(wrongSentence, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(blankSentence, findsOneWidget);

    await tester.tap(find.text(_item.answer));
    await tester.pump();
    expect(correctSentence, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await _pumpUntilVisible(tester, find.text(t.quizResultTitle));

    expect(find.text(t.quizScore(0, 1)), findsOneWidget);
    expect(find.text(t.quizAgain), findsOneWidget);
    expect(find.text(t.btnClose), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}
