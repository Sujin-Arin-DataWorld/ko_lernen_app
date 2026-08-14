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
    VoidCallback? onBlocked,
    VoidCallback? onTap,
    VoidCallback? onUnderlayTap,
    bool enabled = true,
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
              underlay: onUnderlayTap == null
                  ? null
                  : GestureDetector(
                      onTap: onUnderlayTap,
                      child: const ColoredBox(
                        color: Colors.grey,
                        child: Center(child: Text('다음 카드')),
                      ),
                    ),
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
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: SoriSwipeCard(
                  enabled: false,
                  onSwipeLeft: () => calls++,
                  onSwipeRight: () => calls++,
                  rightBadge: const SoriSwipeBadge(
                    label: 'R',
                    icon: Icons.check,
                    color: SoriColors.success,
                  ),
                  leftBadge: const SoriSwipeBadge(
                    label: 'L',
                    icon: Icons.close,
                    color: SoriColors.danger,
                  ),
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

    // 우측 임계 초과 드래그
    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();
    // 좌측 임계 초과 드래그
    await tester.drag(find.text('카드'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(calls, 0, reason: 'enabled=false 이므로 판정 콜백 호출 0');
  });

  testWidgets('위 스와이프는 저장을 1회 호출하고 카드는 복귀한다', (tester) async {
    var saves = 0;
    await tester.pumpWidget(host(onUp: () => saves++));

    await tester.drag(find.text('카드'), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(saves, 1);
    expect(tester.getCenter(find.text('카드')), const Offset(200, 400));
  });

  testWidgets('아래 스와이프는 스킵을 정확히 1회 호출한다', (tester) async {
    var skips = 0;
    await tester.pumpWidget(host(onDown: () => skips++));

    await tester.drag(find.text('카드'), const Offset(0, 180));
    await tester.pumpAndSettle();

    expect(skips, 1);
  });

  testWidgets('수직 임계 미달은 콜백 없이 복귀한다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(onUp: () => calls++, onDown: () => calls++));

    await tester.drag(find.text('카드'), const Offset(0, 40));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('대각선 드래그는 지배축 하나만 커밋한다', (tester) async {
    var rights = 0;
    var downs = 0;
    await tester.pumpWidget(
      host(onRight: () => rights++, onDown: () => downs++),
    );

    await tester.drag(find.text('카드'), const Offset(220, 150));
    await tester.pumpAndSettle();

    expect(rights, 1);
    expect(downs, 0);
  });

  testWidgets('enabled=false 수평은 저항과 힌트만, 수직은 동작한다', (tester) async {
    var judgments = 0;
    var blocked = 0;
    var skips = 0;
    await tester.pumpWidget(
      host(
        enabled: false,
        onLeft: () => judgments++,
        onRight: () => judgments++,
        onDown: () => skips++,
        onBlocked: () => blocked++,
      ),
    );

    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('카드'), const Offset(0, 180));
    await tester.pumpAndSettle();

    expect(judgments, 0);
    expect(blocked, 1);
    expect(skips, 1);
  });

  testWidgets('underlay는 포인터를 받지 않는다', (tester) async {
    var underlayTaps = 0;
    await tester.pumpWidget(
      host(onRight: () {}, onUnderlayTap: () => underlayTaps++),
    );

    await tester.tap(find.text('다음 카드'), warnIfMissed: false);
    await tester.pump();

    expect(underlayTaps, 0);
  });
}
