import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card_grid.dart';

/// W10 T-H1 — [SoriIllustratedCardGrid] is the sliver extracted from
/// `sori_stage_catalog_screen.dart` so the listening hub grid (T-H2) can
/// reuse the exact same column rule and measured `childAspectRatio`. This
/// locks the column-count contract down independently of any one screen.
void main() {
  Future<int> pumpColumns(
    WidgetTester tester, {
    required double width,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const itemCount = 15;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SoriIllustratedCardGrid(
                itemCount: itemCount,
                titles: List.generate(itemCount, (i) => 'Card $i'),
                subtitles: List.generate(itemCount, (i) => '3 Min'),
                footerLabels: const ['Neu', 'In Bearbeitung', 'Fertig'],
                itemBuilder: (context, index) =>
                    ColoredBox(color: Colors.blue.shade100),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final delegate =
        tester.widget<SliverGrid>(find.byType(SliverGrid)).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    return delegate.crossAxisCount;
  }

  testWidgets('390dp -> 2 columns', (tester) async {
    final columns = await pumpColumns(tester, width: 390);
    expect(columns, 2);
  });

  testWidgets('800dp -> 4 columns', (tester) async {
    final columns = await pumpColumns(tester, width: 800);
    expect(columns, 4);
  });

  testWidgets('1280dp -> at most 6 columns', (tester) async {
    final columns = await pumpColumns(tester, width: 1280);
    expect(columns, lessThanOrEqualTo(6));
  });

  testWidgets('textScale 1.6 at 390dp -> 1 column', (tester) async {
    final columns = await pumpColumns(tester, width: 390, textScale: 1.6);
    expect(columns, 1);
  });
}
