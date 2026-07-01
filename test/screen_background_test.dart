import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';

/// D4-0 토대 위젯 회귀 가드.
/// - 콘텐츠가 원래 Scaffold body 제약을 그대로 받는지(Column/Expanded 무회귀).
/// - 4폭 × textScale 1.3 오버플로 0 (레이아웃 개편 방어).
/// - reduce-motion 시 파티클 정적 폴백(예외 0).
void main() {
  Widget harness({
    required double width,
    double textScale = 1.0,
    bool disableAnimations = false,
    bool particles = false,
    required Widget child,
  }) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: SoriScreenBackground(particles: particles, child: child),
        ),
      ),
    );
  }

  // 세로로 꽉 채우는 콘텐츠 — Expanded가 tight 제약을 요구.
  final tallContent = Column(
    children: [
      const Text('상단'),
      Expanded(child: Container(color: const Color(0x11000000))),
      const Text('하단 버튼 영역'),
    ],
  );

  for (final w in [308.0, 360.0, 800.0, 1280.0]) {
    testWidgets('SoriScreenBackground @${w.toInt()}px ×1.3 오버플로 없음', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(width: w, textScale: 1.3, child: tallContent),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 콘텐츠(Expanded 포함)와 배경이 함께 존재.
      expect(find.text('상단'), findsOneWidget);
      expect(find.text('하단 버튼 영역'), findsOneWidget);
    });
  }

  testWidgets('reduce-motion: 파티클 켜도 정적 폴백(예외 0)', (tester) async {
    await tester.pumpWidget(
      harness(
        width: 360,
        disableAnimations: true,
        particles: true,
        child: const Center(child: Text('내용')),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('내용'), findsOneWidget);
  });

  testWidgets('콘텐츠에 tight full-size 제약 전달(Center 채움)', (tester) async {
    await tester.pumpWidget(
      harness(
        width: 360,
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: Text('바닥 정렬'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // bottomCenter 정렬이 동작하려면 child가 full-height여야 함(tight 제약).
    final bgH = tester.getSize(find.byType(SoriScreenBackground)).height;
    final pos = tester.getCenter(find.text('바닥 정렬'));
    expect(pos.dy, greaterThan(bgH * 0.7)); // 렌더 영역 하단부
  });
}
