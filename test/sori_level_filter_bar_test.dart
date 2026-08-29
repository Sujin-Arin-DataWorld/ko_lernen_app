import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/level_filter_bar.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

void main() {
  testWidgets(
    'level bar exposes All and A1-C2 with counts, selection, and 48dp targets',
    (tester) async {
      String? changed = 'unchanged';
      await tester.pumpWidget(
        _host(
          SoriLevelFilterBar(
            selected: 'c1',
            allLabel: 'Alle',
            countFor: (level) => level == null
                ? 42
                : <String, int>{
                    'a1': 9,
                    'a2': 8,
                    'b1': 7,
                    'b2': 6,
                    'c1': 5,
                    'c2': 0,
                  }[level]!,
            onChanged: (level) => changed = level,
          ),
        ),
      );

      final labels = await _sweepLevelChips(tester);
      expect(labels, {
        'Alle · 42',
        'A1 · 9',
        'A2 · 8',
        'B1 · 7',
        'B2 · 6',
        'C1 · 5',
        'C2 · 0',
      });

      final selected = find.bySemanticsLabel('C1 · 5');
      expect(
        tester
            .getSemantics(selected)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      final chips = find.descendant(
        of: find.byType(SoriLevelFilterBar),
        matching: find.byType(SoriChip),
      );
      for (final element in chips.evaluate()) {
        final target = find.byElementPredicate(
          (candidate) => candidate == element,
        );
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      }

      final scrollable = find.descendant(
        of: find.byType(SoriLevelFilterBar),
        matching: find.byType(Scrollable),
      );
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changed, isNull);
    },
  );

  testWidgets(
    'level sheet returns only a changed selection and disables zero-count rows',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showSoriLevelFilterSheet(
                  context: context,
                  selected: 'A1',
                  levels: const ['Alle', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
                  allLabel: 'Alle',
                  countFor: (level) => level == 'Alle'
                      ? 42
                      : <String, int>{
                          'A1': 9,
                          'A2': 8,
                          'B1': 7,
                          'B2': 6,
                          'C1': 5,
                          'C2': 0,
                        }[level]!,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SoriSheetShell), findsOneWidget);

      final selected = tester.widget<SoriChip>(
        find.widgetWithText(SoriChip, 'A1 · 9'),
      );
      expect(selected.selected, isTrue);
      expect(selected.onTap, isNull);

      final disabled = tester.widget<SoriChip>(
        find.widgetWithText(SoriChip, 'C2 · 0'),
      );
      expect(disabled.onTap, isNull);

      for (final chip in tester.widgetList<SoriChip>(find.byType(SoriChip))) {
        expect(chip.minInteractiveHeight, greaterThanOrEqualTo(48));
        expect(
          tester.getSize(find.byWidget(chip)).height,
          greaterThanOrEqualTo(48),
        );
      }

      await tester.tap(find.widgetWithText(SoriChip, 'C1 · 5'));
      await tester.pumpAndSettle();
      expect(find.byType(SoriSheetShell), findsNothing);
      expect(result, 'C1');
    },
  );
}

Future<Set<String>> _sweepLevelChips(WidgetTester tester) async {
  final bar = find.byType(SoriLevelFilterBar);
  final scrollable = find.descendant(
    of: bar,
    matching: find.byType(Scrollable),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  final seen = <String>{};

  void collect() {
    seen.addAll(
      tester
          .widgetList<SoriChip>(
            find.descendant(of: bar, matching: find.byType(SoriChip)),
          )
          .map((chip) => chip.label),
    );
  }

  position.jumpTo(0);
  await tester.pump();
  collect();
  for (
    var attempt = 0;
    attempt < 30 && position.pixels < position.maxScrollExtent;
    attempt++
  ) {
    position.jumpTo(
      (position.pixels + 80).clamp(0.0, position.maxScrollExtent),
    );
    await tester.pump();
    collect();
  }
  return seen;
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SizedBox(width: 320, child: child)),
);
