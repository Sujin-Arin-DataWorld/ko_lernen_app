// ChosungHint 자모 칸 — W10 T-V5(2026-09-05, Jin 신고).
//
// 30×40 상자 + 24px 텍스트가 큰 글자 배율에서 글자 하단을 잘랐다. 이 테스트는
// 배율 1.0/1.3/2.0 에서 초성 글자가 항상 칸 안에 완전히 들어오는지 고정한다
// (배율은 1.3으로 클램프되므로 2.0에서도 잘리지 않아야 한다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/chosung_hint.dart';

void main() {
  Future<void> pump(WidgetTester tester, double textScale) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChosungHint(
                word: '마',
                mode: HintMode.chosung,
                accent: Colors.teal,
                vowelLabel: 'Vowel',
                jongsungLabel: 'Batchim',
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('배율 ${scale}x — 초성 글자가 칸 안에 완전히 들어온다', (tester) async {
      await pump(tester, scale);

      final glyph = find.text('ㅁ');
      expect(glyph, findsOneWidget);

      final slot = find
          .ancestor(of: glyph, matching: find.byType(Container))
          .first;
      final slotRect = tester.getRect(slot);
      final glyphRect = tester.getRect(glyph);

      expect(
        slotRect.contains(glyphRect.topLeft) &&
            slotRect.contains(glyphRect.bottomRight),
        isTrue,
        reason:
            '배율 ${scale}x — glyph rect $glyphRect must be fully inside '
            'slot rect $slotRect',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
