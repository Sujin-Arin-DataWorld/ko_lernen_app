import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/responsive.dart';

/// 몰입 학습 카드의 태블릿 확대(카드 폭) 순수 함수·위젯 계약.
/// 폰(≤600dp)에선 시각 변화 0, 태블릿에서만 카드가 커진다. 글씨 배율은
/// SoriTypeScale(type_scale_test.dart) 로 이관됐다(2026-08-19).
void main() {
  group('soriStudyContentMaxWidth', () {
    test('폰 폭 → 480 (회귀 0)', () {
      expect(soriStudyContentMaxWidth(360), 480);
      expect(soriStudyContentMaxWidth(600), 480);
    });

    test('태블릿에서 760까지 확장', () {
      expect(soriStudyContentMaxWidth(900), closeTo(760, 1e-9));
      expect(soriStudyContentMaxWidth(1280), 760);
      expect(soriStudyContentMaxWidth(750), inInclusiveRange(480, 760));
    });
  });

  group('SoriStudyClamp', () {
    testWidgets('폰(360) → 폭 그대로 통과 (회귀 0)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriStudyClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 360);
    });

    testWidgets('태블릿(1280) → 760으로 클램프', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriStudyClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 760);
    });
  });
}
