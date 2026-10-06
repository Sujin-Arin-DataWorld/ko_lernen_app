import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/activity_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadCFonts();
  });

  for (final language in ['de', 'en']) {
    for (final enlarged in [false, true]) {
      testWidgets(
        '$language C details scroll to native start at ${enlarged ? 200 : 100}%',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = enlarged
              ? const Size(320, 568)
              : const Size(390, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          var starts = 0;
          await tester.pumpWidget(
            _host(
              language: language,
              scale: enlarged ? 2 : 1,
              onStart: () => starts++,
            ),
          );
          await tester.tap(find.text('Details'));
          await tester.pumpAndSettle();
          expect(starts, 0);
          expect(
            find.byKey(const ValueKey('c-activity-sheet-sentence_arcade')),
            findsOneWidget,
          );
          final art = tester.widget<CGameReferenceArt>(
            find.byType(CGameReferenceArt),
          );
          expect(art.part, CGameReferencePart.sentence);
          expect(
            find.descendant(
              of: find.byType(SoriSheetShell),
              matching: find.byType(Icon),
            ),
            findsNothing,
          );
          final start = find.byKey(
            const ValueKey('c-activity-start-sentence_arcade'),
          );
          await tester.ensureVisible(start);
          await tester.pumpAndSettle();
          expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
          expect(
            MediaQuery.textScalerOf(tester.element(start)).scale(16),
            enlarged ? 32 : 16,
          );
          await tester.tap(start);
          await tester.pumpAndSettle();
          expect(starts, 1);
          expect(find.byType(SoriSheetShell), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'C details respect a progress lock and dismiss without starting',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var starts = 0;
      await tester.pumpWidget(
        _host(language: 'de', scale: 1, locked: true, onStart: () => starts++),
      );
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      final start = find.byKey(
        const ValueKey('c-activity-start-sentence_arcade'),
      );
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      expect(tester.widget<CMaterialAction>(start).onTap, isNull);
      expect(starts, 0);
      Navigator.of(tester.element(start)).pop();
      await tester.pumpAndSettle();
      expect(starts, 0);
      expect(find.byType(SoriSheetShell), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({
  required String language,
  required double scale,
  required VoidCallback onStart,
  bool locked = false,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(language),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showSoriActivitySheet(
            context,
            entry: soriActivityCatalog.singleWhere(
              (e) => e.id == 'sentence_arcade',
            ),
            progress: locked
                ? const SoriActivityProgress(
                    activityId: 'sentence_arcade',
                    state: SoriActivityState.locked,
                  )
                : null,
            onStart: onStart,
            conceptC: true,
          ),
          child: const Text('Details'),
        ),
      ),
    ),
  ),
);
