import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/flip_card.dart';

/// FlipCard 계약 회귀 테스트 (flip_card.dart doc-comment):
/// 카드 내용이 바뀔 때는 서빙 카운터 기반 새 key를 줘야 한다. 그러면 새 State가
/// 항상 앞면(0)에서 시작해, 전진 직후 다음 카드의 뒷면(뜻)이 애니메이션
/// 중간값으로 노출되는 일이 없다 (테스터 리포트: 전진 시 다음 카드 독일어가
/// ~190ms 먼저 보임).
class _Harness extends StatefulWidget {
  const _Harness();

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int serve = 0;
  int card = 1;
  bool flipped = false;

  void advance() {
    setState(() {
      card++;
      serve++;
      flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: FlipCard(
            key: ValueKey('serve-$serve'),
            flipped: flipped,
            onTap: () => setState(() => flipped = !flipped),
            front: Text('front-$card'),
            back: Text('back-$card'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('advancing to the next card never shows its back side', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness());
    expect(find.text('front-1'), findsOneWidget);

    // 카드 1 뒤집기 (정상 UX). 첫 pump는 애니메이션 시작 프레임.
    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('back-1'), findsOneWidget);

    // 전진: 내용 교체 + flipped=false + 새 key — 한 setState 안에서.
    tester.state<_HarnessState>(find.byType(_Harness)).advance();

    // 플립 애니메이션 길이(380ms) 전 구간을 16ms 단위로 훑으며
    // 카드 2의 뒷면이 단 한 프레임도 노출되지 않아야 한다.
    for (var elapsed = 0; elapsed <= 400; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.text('back-2'),
        findsNothing,
        reason: 'back-2 visible at ~${elapsed}ms after advance',
      );
    }
    expect(find.text('front-2'), findsOneWidget);

    // 이후 탭하면 정상적으로 뒷면이 열린다.
    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('back-2'), findsOneWidget);
  });

  testWidgets('tap-to-flip still animates (front stays before midpoint)', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness());
    await tester.tap(find.byType(FlipCard));
    await tester.pump();

    // easeInOut 곡선상 중간점(≈190ms) 이전에는 앞면 유지.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('front-1'), findsOneWidget);
    expect(find.text('back-1'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('back-1'), findsOneWidget);
  });
}
