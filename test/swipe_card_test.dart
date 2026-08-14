import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// SoriSwipeCard 판정 계약 (2026-08-14):
/// 임계(폭 35%/700px/s) 초과 우측 드래그 = onSwipeRight 1회, 좌측 = onSwipeLeft
/// 1회, 임계 미달은 콜백 없이 복귀. 자식 탭(플립)은 스와이프와 공존한다.
void main() {
  Widget host({
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onTap,
    VoidCallback? onBlocked,
    bool enabled = true,
    Widget? underlay,
  }) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        disableAnimations: true, // reduce-motion 경로 = 즉시 판정(테스트 결정성)
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: SoriSwipeCard(
              enabled: enabled,
              onSwipeLeft: onLeft,
              onSwipeRight: onRight,
              onSwipeUp: onUp,
              onSwipeDown: onDown,
              onBlockedHorizontalDrag: onBlocked,
              underlay: underlay,
              rightBadge: const SoriSwipeBadge(
                label: 'Gewusst',
                icon: Icons.check_rounded,
                color: SoriColors.success,
              ),
              leftBadge: const SoriSwipeBadge(
                label: 'Nicht gewusst',
                icon: Icons.close_rounded,
                color: SoriColors.danger,
              ),
              child: GestureDetector(
                onTap: onTap,
                child: const ColoredBox(
                  color: Colors.white,
                  child: Center(child: Text('카드')),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('임계 초과 우측 스와이프 = onSwipeRight 1회', (tester) async {
    var rights = 0;
    var lefts = 0;
    await tester.pumpWidget(
      host(onRight: () => rights++, onLeft: () => lefts++),
    );

    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(rights, 1);
    expect(lefts, 0);
  });

  testWidgets('임계 초과 좌측 스와이프 = onSwipeLeft 1회', (tester) async {
    var rights = 0;
    var lefts = 0;
    await tester.pumpWidget(
      host(onRight: () => rights++, onLeft: () => lefts++),
    );

    await tester.drag(find.text('카드'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(lefts, 1);
    expect(rights, 0);
  });

  testWidgets('임계 미달 드래그는 판정 없이 복귀한다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(onRight: () => calls++, onLeft: () => calls++),
    );

    await tester.drag(find.text('카드'), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('자식 탭(플립)은 스와이프 래퍼와 공존한다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(onTap: () => taps++, onRight: () {}));

    await tester.tap(find.text('카드'));
    await tester.pump();

    expect(taps, 1);
  });

  // §C-3b: enabled=false 일 때 스와이프가 판정되지 않는지 검증.
  // legacy_vocab 에서 플립 전(_flipped=false) 스와이프로 SRS 오답이
  // 기록되던 데이터 버그의 회귀 방지.
  testWidgets('enabled=false 스와이프는 판정되지 않는다 (regression §C-1-1)', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(onLeft: () => calls++, onRight: () => calls++, enabled: false),
    );

    // 우측 임계 초과 드래그
    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();
    // 좌측 임계 초과 드래그
    await tester.drag(find.text('카드'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(calls, 0, reason: 'enabled=false 이므로 판정 콜백 호출 0');
  });

  // ── §P2-1: 4방향 덱 ──────────────────────────────────────────────────
  // 카드 높이 300 → 수직 커밋 임계 = min(120, 300×0.25) = 75.

  testWidgets('임계 초과 아래 스와이프 = onSwipeDown 1회 (중복 0)', (tester) async {
    var downs = 0;
    var ups = 0;
    var judgments = 0;
    await tester.pumpWidget(
      host(
        onDown: () => downs++,
        onUp: () => ups++,
        onLeft: () => judgments++,
        onRight: () => judgments++,
      ),
    );

    await tester.drag(find.text('카드'), const Offset(0, 160));
    await tester.pumpAndSettle();

    expect(downs, 1);
    expect(ups, 0);
    expect(judgments, 0);
  });

  testWidgets('임계 초과 위 스와이프 = onSwipeUp 1회 + 카드 복귀 (퇴장 없음)', (tester) async {
    var ups = 0;
    await tester.pumpWidget(host(onUp: () => ups++, onDown: () {}));

    await tester.drag(find.text('카드'), const Offset(0, -160));
    await tester.pumpAndSettle();

    expect(ups, 1);
    // 복귀 후에도 카드가 그대로 (같은 finder 로 재드래그 가능).
    await tester.drag(find.text('카드'), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(ups, 2);
  });

  testWidgets('수직 sub-threshold 드래그는 콜백 없이 복귀', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(onUp: () => calls++, onDown: () => calls++));

    await tester.drag(find.text('카드'), const Offset(0, 40));
    await tester.pumpAndSettle();
    await tester.drag(find.text('카드'), const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('대각 드래그는 지배축만 판정한다', (tester) async {
    var rights = 0;
    var downs = 0;
    await tester.pumpWidget(
      host(onRight: () => rights++, onDown: () => downs++, onLeft: () {}),
    );

    // 수평 지배 대각 — 수직 커밋 거리(75+)를 함께 넘겨도 수평만 발동.
    await tester.drag(find.text('카드'), const Offset(220, 90));
    await tester.pumpAndSettle();
    expect(rights, 1);
    expect(downs, 0);

    // 수직 지배 대각.
    await tester.drag(find.text('카드'), const Offset(60, 200));
    await tester.pumpAndSettle();
    expect(rights, 1);
    expect(downs, 1);
  });

  testWidgets('enabled=false: 좌/우 0회 + onBlockedHorizontalDrag 1회 + ↑/↓ 는 동작', (
    tester,
  ) async {
    var judgments = 0;
    var blocked = 0;
    var ups = 0;
    var downs = 0;
    await tester.pumpWidget(
      host(
        enabled: false,
        onLeft: () => judgments++,
        onRight: () => judgments++,
        onUp: () => ups++,
        onDown: () => downs++,
        onBlocked: () => blocked++,
      ),
    );

    // 수평 임계 초과 — 판정 0, 힌트 훅은 드래그당 1회.
    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(judgments, 0);
    expect(blocked, 1);

    // ↑/↓ 는 게이트 무관.
    await tester.drag(find.text('카드'), const Offset(0, 160));
    await tester.pumpAndSettle();
    await tester.drag(find.text('카드'), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(downs, 1);
    expect(ups, 1);
    expect(judgments, 0);
  });

  testWidgets('underlay 는 히트테스트 불가 (IgnorePointer)', (tester) async {
    var underlayTaps = 0;
    var cardTaps = 0;
    await tester.pumpWidget(
      host(
        onRight: () {},
        onTap: () => cardTaps++,
        underlay: GestureDetector(
          onTap: () => underlayTaps++,
          child: const ColoredBox(
            color: Colors.black12,
            child: Center(child: Text('다음')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('카드'));
    await tester.pump();

    expect(cardTaps, 1);
    expect(underlayTaps, 0, reason: 'underlay 는 IgnorePointer 뒤에 있다');
  });
}
