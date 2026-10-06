import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/c_free_learning_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

void main() {
  testWidgets('C free learning exposes every non-course Learn entry', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: CFreeLearningScreen(
          onOpenEntry: (entry) async => opened.add(entry.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expected = soriActivityCatalog
        .where((entry) => entry.tab.name == 'learn' && entry.id != 'course')
        .map((entry) => entry.id)
        .toSet();
    expect(expected.length, 12);

    for (final id in expected) {
      final finder = find.byKey(ValueKey('c-free-primary-$id'));
      final secondary = find.byKey(ValueKey('c-free-secondary-$id'));
      final target = finder.evaluate().isNotEmpty ? finder : secondary;
      expect(
        target,
        findsOneWidget,
        reason: 'missing C free-learning tile: $id',
      );
      final action = find.descendant(
        of: target,
        matching: find.byType(CImageTap),
      );
      expect(action, findsOneWidget);
      tester.widget<CImageTap>(action).onTap?.call();
      await tester.pump();
    }
    expect(opened.toSet(), expected);
  });

  testWidgets('C free learning keeps the approved DE/EN responsive shell', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const cases = <({Size size, double scale})>[
      (size: Size(320, 640), scale: 2),
      (size: Size(390, 844), scale: 1),
      (size: Size(720, 1024), scale: 1.3),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final testCase in cases) {
        tester.view.physicalSize = testCase.size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(testCase.scale),
              ),
              child: child!,
            ),
            home: CFreeLearningScreen(onOpenEntry: (_) async {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(
            const ValueKey('c-free-learning-scroll'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('c-free-primary-vocab_packs'),
            skipOffstage: false,
          ),
          findsOneWidget,
          reason:
              '${locale.languageCode} ${testCase.size} scale=${testCase.scale}',
        );
        expect(
          find.byKey(
            const ValueKey('c-free-primary-listening'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
