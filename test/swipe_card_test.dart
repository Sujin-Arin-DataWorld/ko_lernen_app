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
    VoidCallback? onTap,
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
              onSwipeLeft: onLeft,
              onSwipeRight: onRight,
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
  // ── Sori Deck 2.0: 4방향 ──────────────────────────────────────────

  Widget host4({
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onBlocked,
    bool enabled = true,
    Widget? underlay,
  }) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
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
              child: const ColoredBox(
                color: Colors.white,
                child: Center(child: Text('카드')),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('위 스와이프 = onSwipeUp 1회 (다른 방향 0)', (tester) async {
    var up = 0, down = 0, left = 0, right = 0;
    await tester.pumpWidget(
      host4(
        onUp: () => up++,
        onDown: () => down++,
        onLeft: () => left++,
        onRight: () => right++,
      ),
    );

    await tester.drag(find.text('카드'), const Offset(0, -140));
    await tester.pumpAndSettle();

    expect(up, 1);
    expect([down, left, right], [0, 0, 0]);
  });

  testWidgets('아래 스와이프 = onSwipeDown 1회 (다른 방향 0)', (tester) async {
    var up = 0, down = 0, left = 0, right = 0;
    await tester.pumpWidget(
      host4(
        onUp: () => up++,
        onDown: () => down++,
        onLeft: () => left++,
        onRight: () => right++,
      ),
    );

    await tester.drag(find.text('카드'), const Offset(0, 140));
    await tester.pumpAndSettle();

    expect(down, 1);
    expect([up, left, right], [0, 0, 0]);
  });

  testWidgets('수직 임계 미달은 판정 없이 복귀한다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host4(onUp: () => calls++, onDown: () => calls++));

    await tester.drag(find.text('카드'), const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.drag(find.text('카드'), const Offset(0, 40));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('대각 드래그는 지배축 한 방향만 커밋한다', (tester) async {
    var up = 0, down = 0, left = 0, right = 0;
    await tester.pumpWidget(
      host4(
        onUp: () => up++,
        onDown: () => down++,
        onLeft: () => left++,
        onRight: () => right++,
      ),
    );

    // 오른쪽이 더 큰 대각선 → 수평만 커밋되어야 한다.
    await tester.drag(find.text('카드'), const Offset(220, 150));
    await tester.pumpAndSettle();

    expect(right, 1, reason: '지배축(수평)만 커밋');
    expect(down, 0, reason: '반대축 델타는 잠금 후 무시된다');
    expect([up, left], [0, 0]);
  });

  testWidgets('enabled=false: 좌우 0회 + 힌트 1회, 위/아래는 정상 동작', (tester) async {
    var judged = 0, up = 0, down = 0, blocked = 0;
    await tester.pumpWidget(
      host4(
        enabled: false,
        onLeft: () => judged++,
        onRight: () => judged++,
        onUp: () => up++,
        onDown: () => down++,
        onBlocked: () => blocked++,
      ),
    );

    await tester.drag(find.text('카드'), const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(judged, 0, reason: '플립 게이트: 판정 콜백 0');
    expect(blocked, 1, reason: '드래그당 힌트 1회');

    // 위/아래는 판정이 아니므로 게이트와 무관하게 동작한다.
    await tester.drag(find.text('카드'), const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.drag(find.text('카드'), const Offset(0, 140));
    await tester.pumpAndSettle();
    expect(up, 1);
    expect(down, 1);
    expect(judged, 0);
  });

  testWidgets('underlay 는 히트테스트되지 않는다', (tester) async {
    var underlayTaps = 0;
    await tester.pumpWidget(
      host4(
        onRight: () {},
        underlay: GestureDetector(
          onTap: () => underlayTaps++,
          child: const ColoredBox(
            color: Colors.amber,
            child: Center(child: Text('다음카드')),
          ),
        ),
      ),
    );

    expect(find.text('다음카드'), findsOneWidget, reason: '덱 스택은 그려진다');
    await tester.tap(find.text('카드'));
    await tester.pumpAndSettle();
    expect(underlayTaps, 0, reason: 'IgnorePointer — 뒷 카드는 만질 수 없다');
  });

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
}
