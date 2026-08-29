import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _item = SatzSentence(
  id: 'satz_ui_a1',
  level: 'a1',
  targetKo: '저는 학교에 가요',
  promptDe: 'Ich gehe zur Schule.',
  promptEn: 'I go to school.',
  distractors: ['오늘', '친구'],
  vocabKo: '학교',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('Satz keeps shared game hierarchy and complete controls in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        _configureView(tester, viewport.size);

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: const SatzArcadeScreen(items: [_item]),
          ),
        );
        await _pumpUntilVisible(tester, find.byType(SatzBauenQuest));

        final context = tester.element(find.byType(SatzArcadeScreen));
        final t = AppL10n.of(context);
        final type = SoriTextTheme.of(context);
        final frame = tester.widget<SoriStudyFrame>(
          find.byType(SoriStudyFrame),
        );
        expect(frame.title, t.satzArcadeTitle);
        expect(frame.eyebrow, '1 / 1 · ${t.quizScore(0, 1)}');

        final close = find.byTooltip(t.btnClose);
        expect(close, findsOneWidget);
        final closeSize = tester.getSize(close);
        expect(closeSize.width, greaterThanOrEqualTo(48));
        expect(closeSize.height, greaterThanOrEqualTo(48));

        final answerLabel = tester.widget<Text>(
          find.text(t.questBuildAnswerLabel),
        );
        expect(answerLabel.style?.fontFamily, type.label.fontFamily);
        expect(answerLabel.style?.fontWeight, type.label.fontWeight);

        final instruction = tester.widget<Text>(
          find.text(t.questSatzBauenInstruction),
        );
        expect(instruction.maxLines, isNull);
        expect(instruction.overflow, isNull);
        expect(instruction.style?.fontFamily, type.bodySmall.fontFamily);
        expect(instruction.style?.fontWeight, type.bodySmall.fontWeight);

        for (final label in [
          ...SatzBauenQuest.tokenize(_item.targetKo),
          ..._item.distractors,
        ]) {
          final tile = find.byWidgetPredicate(
            (widget) => widget is SoriWordTile && widget.label == label,
          );
          expect(tile, findsOneWidget);
          final size = tester.getSize(tile);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }

        final submit = find.byKey(const ValueKey('quest-submit'));
        expect(submit, findsOneWidget);
        final submitButton = tester.widget<SoriButton>(submit);
        expect(submitButton.label, t.questCheckAnswer);
        expect(submitButton.maxLines, isNull);
        expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Satz level filter has a visible name and 48dp controls in '
        '${locale.languageCode} at 200% text', (tester) async {
      final semantics = tester.ensureSemantics();
      _configureView(tester, const Size(320, 640));
      await tester.runAsync(SatzLoader.load);

      await tester.pumpWidget(
        _host(locale: locale, textScale: 2, child: const SatzArcadeScreen()),
      );

      final context = tester.element(find.byType(SatzArcadeScreen));
      final t = AppL10n.of(context);
      await _pumpUntilVisible(tester, find.byIcon(Icons.tune_rounded));
      expect(find.bySemanticsLabel(t.clozeLevelLabel), findsOneWidget);
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

  testWidgets(
    'Satz diagnostic keeps a non-color cue and the shared type role',
    (tester) async {
      _configureView(tester, const Size(390, 844));

      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          textScale: 1,
          child: const SatzArcadeScreen(items: [_item]),
        ),
      );
      await _pumpUntilVisible(tester, find.byType(SatzBauenQuest));
      final context = tester.element(find.byType(SatzArcadeScreen));
      final t = AppL10n.of(context);
      final type = SoriTextTheme.of(context);

      final distractor = find.byWidgetPredicate(
        (widget) =>
            widget is SoriWordTile && widget.label == _item.distractors.first,
      );
      await tester.tap(distractor);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quest-submit')));
      await tester.pump();

      final diagnostics = tester
          .widgetList<Text>(find.text(t.questDiagCount))
          .where((text) => text.style?.color == SoriColors.accent)
          .toList();
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.style?.fontFamily, type.label.fontFamily);
      expect(diagnostics.single.style?.fontWeight, type.label.fontWeight);
      expect(
        SoriColors.contrastRatio(
          diagnostics.single.style!.color!,
          SoriColors.lightBg,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
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
  final exception = tester.takeException();
  throw TestFailure(
    'Expected $finder to become visible after ${attempts * 100}ms. '
    'Last framework exception: $exception',
  );
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
