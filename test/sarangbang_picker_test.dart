import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/room_slot_picker.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

/// 시트를 열고 결과를 받아 두는 최소 하네스.
/// `showSoriSheet` 는 라우트를 쓰므로 Navigator 가 있는 트리에서만 성립한다.
Future<void> _openSheet(
  WidgetTester tester, {
  required List<String> candidates,
  String? current,
  required void Function(String?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              onResult(
                await showSoriSheet<String>(
                  context: ctx,
                  builder: (_) =>
                      SlotPickerSheet(candidates: candidates, current: current),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('SlotPickerSheet', () {
    // 비우기를 null 로 표현하면 시트를 스와이프로 닫을 때마다 슬롯이 비워진다.
    // sentinel 이 실제 슬러그와 겹치면 그 장식을 고를 때 방이 비어버린다.
    test('the clear sentinel can never be mistaken for a decoration', () {
      expect(kAvailableDecorations.contains(kSlotPickClear), isFalse);
      expect(kDecorCategory.containsKey(kSlotPickClear), isFalse);
      expect(kSlotPickClear.startsWith('decoration_'), isFalse);
    });

    testWidgets('tapping a candidate returns that slug', (tester) async {
      String? result = 'untouched';
      await _openSheet(
        tester,
        candidates: const ['decoration_seoan', 'decoration_soban'],
        current: 'decoration_seoan',
        onResult: (v) => result = v,
      );

      expect(find.text('Schreibpult (서안)'), findsOneWidget);
      // 현재 놓여 있는 것에는 체크가 붙는다.
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('Tabletttisch (소반)'));
      await tester.pumpAndSettle();
      expect(result, 'decoration_soban');
    });

    testWidgets('clearing returns the sentinel, not null', (tester) async {
      String? result = 'untouched';
      await _openSheet(
        tester,
        candidates: const ['decoration_seoan'],
        current: 'decoration_seoan',
        onResult: (v) => result = v,
      );

      await tester.tap(find.text('Platz frei lassen'));
      await tester.pumpAndSettle();
      expect(result, kSlotPickClear);
    });

    testWidgets('an empty slot offers nothing to clear', (tester) async {
      await _openSheet(
        tester,
        candidates: const ['decoration_seoan'],
        onResult: (_) {},
      );

      expect(find.text('Platz frei lassen'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });
}
