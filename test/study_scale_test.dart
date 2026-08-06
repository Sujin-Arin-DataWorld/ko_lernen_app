import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/responsive.dart';

/// 몰입 학습 카드의 태블릿 확대(카드 폭 + 히어로 글씨) 순수 함수·위젯 계약.
/// 폰(≤600dp)에선 시각 변화 0, 태블릿에서만 카드가 커지고 글씨가 화면비율에
/// 따라 자동 확대된다. OS 접근성 글자 배율과는 **곱셈으로** 합성된다.
void main() {
  group('soriStudyScale', () {
    test('폰 폭 → 1.0 (변화 0)', () {
      expect(soriStudyScale(360), 1.0);
      expect(soriStudyScale(430), 1.0);
      expect(soriStudyScale(600), 1.0);
    });

    test('태블릿에서 증가, 1.35 상한', () {
      expect(soriStudyScale(900), closeTo(1.35, 1e-9));
      expect(soriStudyScale(1280), 1.35);
      final mid = soriStudyScale(750);
      expect(mid, greaterThan(1.0));
      expect(mid, lessThan(1.35));
    });

    test('폭이 커질수록 단조 비감소', () {
      var prev = 0.0;
      for (var w = 300.0; w <= 1400; w += 50) {
        final s = soriStudyScale(w);
        expect(s, greaterThanOrEqualTo(prev));
        prev = s;
      }
    });
  });

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

  group('SoriStudyScale (글씨 확대)', () {
    testWidgets('폰(360) → no-op, 스케일러 그대로', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late double scaled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriStudyScale(
              child: Builder(
                builder: (ctx) {
                  scaled = MediaQuery.textScalerOf(ctx).scale(20);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(scaled, 20);
    });

    testWidgets('태블릿(1280) → 히어로 글씨 1.35배 + OS 배율과 곱셈 합성', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late double scaled;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 900),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SoriStudyScale(
                child: Builder(
                  builder: (ctx) {
                    scaled = MediaQuery.textScalerOf(ctx).scale(20);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      // 20 * 1.3(OS 접근성) * 1.35(태블릿 학습 확대) = 35.1
      expect(scaled, closeTo(20 * 1.3 * 1.35, 1e-6));
    });
  });
}
