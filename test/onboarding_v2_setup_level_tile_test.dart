import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/real_fonts.dart';

const _levelsUnderTest = <(String code, String label)>[
  ('A1', 'Anfänger'),
  ('A2', 'Grundkenntnisse'),
  ('B1', 'Mittelstufe'),
  ('B2', 'Fortgeschritten'),
  ('C1', 'Kompetent'),
  ('C2', 'Expertenniveau'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);

  for (final testCase
      in const <
        ({Size size, double textScale, int columns, bool compactPicker})
      >[
        (size: Size(360, 800), textScale: 1, columns: 2, compactPicker: false),
        (
          size: Size(390, 844),
          textScale: 1.3,
          columns: 2,
          compactPicker: false,
        ),
        (size: Size(720, 1152), textScale: 1, columns: 3, compactPicker: false),
        (size: Size(360, 640), textScale: 2, columns: 1, compactPicker: true),
        (size: Size(320, 640), textScale: 2, columns: 1, compactPicker: true),
      ]) {
    testWidgets('level tiles keep code above a full-scale German label at '
        '${testCase.size.width}x${testCase.size.height} '
        '(${testCase.textScale}x)', (tester) async {
      await _pump(tester, size: testCase.size, textScale: testCase.textScale);

      expect(
        find.byType(SingleChildScrollView),
        findsNothing,
        reason: 'The mandatory level step must fit without page scrolling.',
      );
      final picker = find.byKey(const ValueKey('onboarding-v2-level-picker'));
      if (testCase.compactPicker) {
        expect(picker, findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding-v2-level-A1')),
          findsNothing,
        );
        await tester.tap(picker);
        await _pumpFinite(tester);
      } else {
        expect(picker, findsNothing);
      }

      final tileRects = <Rect>[];
      for (final (code, label) in _levelsUnderTest) {
        final tile = find.byKey(ValueKey('onboarding-v2-level-$code'));
        final codeFinder = find.descendant(of: tile, matching: find.text(code));
        final labelFinder = find.descendant(
          of: tile,
          matching: find.text(label),
        );
        expect(tile, findsOneWidget, reason: code);
        expect(codeFinder, findsOneWidget, reason: code);
        expect(labelFinder, findsOneWidget, reason: label);

        final tileRect = tester.getRect(tile);
        final codeRect = tester.getRect(codeFinder);
        final labelRect = tester.getRect(labelFinder);
        tileRects.add(tileRect);

        expect(
          codeRect.bottom,
          lessThanOrEqualTo(labelRect.top),
          reason: '$code must read before its label',
        );
        expect(
          labelRect.left,
          greaterThanOrEqualTo(tileRect.left - 0.5),
          reason: '$label overflows the tile on the left',
        );
        expect(
          labelRect.right,
          lessThanOrEqualTo(tileRect.right + 0.5),
          reason: '$label overflows the tile on the right',
        );
        expect(
          labelRect.bottom,
          lessThanOrEqualTo(tileRect.bottom + 0.5),
          reason: '$label overflows the tile vertically',
        );
        expect(
          find.ancestor(of: labelFinder, matching: find.byType(FittedBox)),
          findsNothing,
          reason: '$label must not be scaled down to fit',
        );

        final paragraph = tester.renderObject<RenderParagraph>(labelFinder);
        expect(
          paragraph.textScaler.scale(12),
          closeTo(12 * testCase.textScale, 0.01),
          reason: '$label did not retain the requested text scale',
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }

      final firstRowTop = tileRects.first.top;
      final tilesInFirstRow = tileRects
          .where((rect) => (rect.top - firstRowTop).abs() < 1)
          .length;
      expect(tilesInFirstRow, testCase.columns);
      if (testCase.columns == 1) {
        for (var index = 1; index < tileRects.length; index++) {
          expect(
            tileRects[index].top,
            greaterThanOrEqualTo(tileRects[index - 1].bottom),
            reason: 'large text must use one non-overlapping tile per row',
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpFinite(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) => OnboardingSetupScreen(
          copy: onboardingV2Copy(AppL10n.of(context)),
          selectedPurposeId: OnboardingV2Ids.purposeKContent,
          selectedLevelCode: null,
          onPurposeChanged: (_) {},
          onLevelChanged: (_) {},
          onContinue: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
