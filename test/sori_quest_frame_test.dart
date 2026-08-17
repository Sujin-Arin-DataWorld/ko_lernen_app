import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('word tiles expose selected and wrong state in semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            SoriWordTile(
              key: ValueKey('tile-selected'),
              label: '안녕',
              state: SoriWordTileState.selected,
              onTap: _noop,
            ),
            SoriWordTile(
              key: ValueKey('tile-wrong'),
              label: '감사',
              state: SoriWordTileState.wrong,
              onTap: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('안녕, Selected'), findsOneWidget);
    expect(find.bySemanticsLabel('감사, Not quite'), findsOneWidget);

    final selectedMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('tile-selected')),
        matching: find.byType(Material),
      ),
    );
    final selectedText = tester.widget<Text>(find.text('안녕'));
    expect(selectedMaterial.color, SoriColors.primarySoft);
    expect(
      SoriColors.contrastRatio(
        selectedText.style?.color ?? SoriColors.lightText,
        selectedMaterial.color ?? SoriColors.primarySoft,
      ),
      greaterThan(4.5),
    );
  });

  testWidgets('prompt card and dotted slots render the mockup copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            SoriPromptCard(sentence: 'Ja, hier bitte.', onReplay: _noop),
            SoriAnswerTray(slotCount: 3, tiles: []),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ja, hier bitte.'), findsOneWidget);
    expect(find.text('Listen again'), findsOneWidget);
    expect(find.byType(SoriDottedAnswerSlot), findsNWidgets(3));
  });
}

void _noop() {}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: child),
);
