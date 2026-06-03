import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/tiger_stage.dart';

void main() {
  // 가장 중요한 불변식: reduce-motion이면 정지 프레임 1장 + 컨트롤러/타이머 0.
  // pumpAndSettle이 완료된다는 것 자체가 "무한 타이머 없음"을 증명한다.
  testWidgets('reduce-motion → static band, no pending timers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: TigerStage(height: 160),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TigerStage), findsOneWidget);
  });

  // 라이브 경로: 첫 프레임이 throw 없이 빌드되고, unmount 시 깨끗이 dispose되는지.
  // (frontIdle 루프는 무한이라 pumpAndSettle 금지 — intro 중 unmount 후 보류 타이머 배수.)
  testWidgets('animated path builds + disposes cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TigerStage(height: 160))),
    );
    await tester.pump(); // intro 시작 (첫 dwell 진입)
    expect(find.byType(TigerStage), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // unmount → dispose
    await tester.pump(const Duration(seconds: 3)); // 보류된 시퀀서 타이머 배수
  });
}
