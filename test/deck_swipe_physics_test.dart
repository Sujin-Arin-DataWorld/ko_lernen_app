library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/deck_coach.dart';

import 'package:ko_lernen_app/widgets/sori/swipe_card.dart';
import 'package:ko_lernen_app/widgets/sori/swipe_rails.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// **Sori Deck 3.0 물리·어포던스 센서** (2026-08-18).
///
/// Jin 이 실기기에서 지적한 "붕붕대는" 손맛의 원인 3개와, 그걸 고치며 넣은
/// 어포던스 레일을 계약으로 못박는다. 기존 `swipe_card_test.dart` 의 판정
/// 계약 15건은 그대로 두고(완화 금지) 여기서 **감각과 성능**만 다룬다.
///
/// 파괴-복원:
///  - `SoriMotion.deckAxisLock` 을 12 로 되돌리면 §2 가 빨개진다.
///  - `_exitDuration` 을 상수 `deckExitMax` 로 바꾸면 §3 이 빨개진다.
///  - `_rail()` 의 `gated` 분기를 지우면 §4-4 가 빨개진다.
void _noop() {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onUp,
    VoidCallback? onDown,
    bool enabled = true,
    bool disableAnimations = false,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        disableAnimations: disableAnimations,
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
              rightBadge: const SoriSwipeBadge(
                label: 'R',
                icon: Icons.check_rounded,
                color: SoriColors.success,
              ),
              leftBadge: const SoriSwipeBadge(
                label: 'L',
                icon: Icons.close_rounded,
                color: SoriColors.danger,
              ),
              upBadge: const SoriSwipeBadge(
                label: 'U',
                icon: Icons.redeem_rounded,
                color: SoriColors.gold,
              ),
              downBadge: const SoriSwipeBadge(
                label: 'D',
                icon: Icons.arrow_downward_rounded,
                color: SoriColors.info,
              ),
              child: Container(
                color: SoriColors.lightSurfaceRaised,
                alignment: Alignment.center,
                child: const Text('카드'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// 넛지 전용 하네스 — §5 가 30줄짜리 MaterialApp 을 세 번 인라인하던 걸 대체.
  /// 배지를 주므로 넛지 도중 레일 반응도 검사할 수 있다.
  Widget nudgeHost({
    required bool nudge,
    VoidCallback? onPlayed,
    bool reduce = false,
    bool wired = true,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        disableAnimations: reduce,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: SoriSwipeCard(
              nudge: nudge,
              onNudgePlayed: onPlayed,
              onSwipeLeft: wired ? _noop : null,
              onSwipeRight: wired ? _noop : null,
              rightBadge: const SoriSwipeBadge(
                label: 'R',
                icon: Icons.check_rounded,
                color: SoriColors.success,
              ),
              child: const Text('카드'),
            ),
          ),
        ),
      ),
    ),
  );

  SoriSwipeRails rails(WidgetTester tester) =>
      tester.widget<SoriSwipeRails>(find.byType(SoriSwipeRails));

  // §1 — 위치 갱신이 자식 서브트리를 재빌드하지 않는 **구조**를 소스에서 고정.
  //
  // 초판은 자식 빌드 횟수를 세는 위젯 테스트였는데, 코드리뷰가 40개 변이로
  // 측정한 결과 **어떤 변이로도 빨개지지 않았다** — 프레임당 setState 를 되살린
  // 2.0 회귀조차 green 이었다. 원인은 구조적이다: 카운터가 세는 `Builder` 는
  // 테스트 하네스가 **한 번 만들어 넘긴 인스턴스**라 `SoriSwipeCard` 가 그
  // 엘리먼트를 다시 빌드할 방법이 아예 없다. `expect(1, 1)` 이었던 셈이다.
  //
  // 못 죽는 테스트는 없는 테스트보다 나쁘다(있지도 않은 확신을 CI 시간으로 산다).
  // 저장소 관례(`deck_direction_contract_test`·`typography_guard`)대로 **소스를
  // 스캔하는 래칫**으로 바꾼다. 이건 실제로 죽는다.
  group('§1 위치 갱신 구조 (소스 래칫)', () {
    late String swipeCardSource;

    setUpAll(() {
      swipeCardSource = File(
        'lib/widgets/sori/swipe_card.dart',
      ).readAsStringSync();
    });

    test('카드 본문은 ValueListenableBuilder 의 child 슬롯으로 넘긴다', () {
      expect(
        swipeCardSource.contains('child: cardContent,'),
        isTrue,
        reason: '빌더 안에서 본문을 만들면 프레임마다 서브트리가 새로 생긴다',
      );
    });

    test('드래그 경로에 setState 가 없다', () {
      // _onPanUpdate · _sync · _onNudgeTick 은 프레임당 호출된다.
      for (final fn in const ['_onPanUpdate', '_sync', '_onNudgeTick']) {
        final i = swipeCardSource.indexOf('void $fn(');
        expect(i, greaterThan(0), reason: '$fn 이 사라졌다 — 래칫을 갱신할 것');
        // 함수 본문 대략 60줄 창.
        final window = swipeCardSource.substring(
          i,
          (i + 2600).clamp(0, swipeCardSource.length),
        );
        final body = window.substring(0, window.indexOf('\n  }') + 1);
        expect(
          body.contains('setState('),
          isFalse,
          reason: '$fn 은 프레임당 호출된다 — setState 금지',
        );
      }
    });

    test('nudge 를 쓰는 호출부는 onNudgePlayed 도 함께 넘긴다', () {
      // 빠뜨리면 세션 게이트가 소비되지 않아 **화면에 들어올 때마다** 흔들린다
      // (3.0 이 고친 바로 그 버그의 재발).
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('nudge:') || lines[i].contains('this.nudge')) {
            continue;
          }
          final window = lines
              .sublist(i, (i + 6).clamp(0, lines.length))
              .join('\n');
          if (!window.contains('onNudgePlayed:')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('§2 데드존', () {
    testWidgets('축 잠금 임계(4px) 미만에서도 카드가 손가락을 따라간다', (tester) async {
      await tester.pumpWidget(host(onLeft: () {}, onRight: () {}));
      final card = find.text('카드');
      final origin = tester.getCenter(card);

      final gesture = await tester.startGesture(origin);
      await gesture.moveBy(const Offset(3, 0));
      await tester.pump();

      // 3px 은 잠금 임계(4px) 아래 — 예전 12px 데드존에서는 0 이었다.
      expect(tester.getCenter(card).dx - origin.dx, closeTo(3, 0.6));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getCenter(card), origin);
    });

    testWidgets('4px 만 움직여도 축이 잠긴다 (12px 이면 안 잠긴다)', (tester) async {
      // 초판은 `expect(SoriMotion.deckAxisLock, 4)` 였는데, 코드리뷰 실측 결과
      // 제스처 코드에 12 를 하드코딩해도 green 이었다 — 토큰을 **읽는지** 를
      // 증명하지 못하는 공허한 단언이었다. 행동으로 바꾼다.
      await tester.pumpWidget(
        host(onLeft: _noop, onRight: _noop, onUp: _noop, onDown: _noop),
      );
      final card = find.text('카드');
      final origin = tester.getCenter(card);
      final g = await tester.startGesture(origin);

      await g.moveBy(const Offset(5, 0)); // 4px 초과 → 수평으로 잠김
      await tester.pump();
      await g.moveBy(const Offset(0, 60)); // 12px 였다면 여기서 수직으로 잠겼다
      await tester.pump();

      expect(
        tester.getCenter(card).dy - origin.dy,
        closeTo(0, 1),
        reason: '이미 수평으로 잠겨 세로 delta 는 무시된다',
      );
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('§3 퇴장 속도 승계', () {
    testWidgets('세게 던지면 느리게 민 것보다 먼저 퇴장이 끝난다', (tester) async {
      // ── 느린 커밋: 임계는 넘되 속도는 0 에 가깝다 → deckExitMax(220ms).
      var slowDone = false;
      await tester.pumpWidget(
        host(onLeft: () {}, onRight: () => slowDone = true),
      );
      final slowGesture = await tester.startGesture(
        tester.getCenter(find.text('카드')),
      );
      for (var i = 0; i < 30; i++) {
        await slowGesture.moveBy(const Offset(6, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await slowGesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(slowDone, isFalse, reason: '속도 0 커밋은 220ms 를 다 쓴다');
      await tester.pumpAndSettle();
      expect(slowDone, isTrue);

      // ── 빠른 플링: 같은 150ms 지점에서 이미 끝나 있어야 한다.
      var fastDone = false;
      await tester.pumpWidget(
        host(onLeft: () {}, onRight: () => fastDone = true),
      );
      await tester.fling(find.text('카드'), const Offset(220, 0), 4000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(fastDone, isTrue, reason: '플링 속도를 승계하면 120~150ms 안에 나간다');
      await tester.pumpAndSettle();
    });
  });

  group('§4 어포던스 레일', () {
    testWidgets('배선된 방향만 레일이 있다', (tester) async {
      await tester.pumpWidget(
        host(onLeft: () {}, onRight: () {}, onDown: () {}),
      );
      final r = rails(tester);
      expect(r.left, isNotNull);
      expect(r.right, isNotNull);
      expect(r.down, isNotNull);
      // ↑ 미배선(커스텀 팩·자모 카드) → 레일 자체가 없다. "그 방향이 없다"도
      // 정보다.
      expect(r.up, isNull);
    });

    testWidgets('정지 상태에서도 레일이 존재한다 (0 진행도)', (tester) async {
      await tester.pumpWidget(host(onLeft: () {}, onRight: () {}));
      final r = rails(tester);
      expect(r.right!.progress, 0);
      expect(r.left!.progress, 0);
    });

    testWidgets('드래그하면 그 방향 레일만 차오른다', (tester) async {
      await tester.pumpWidget(host(onLeft: () {}, onRight: () {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('카드')),
      );
      // 커밋 거리의 절반 = 400 × 0.35 ÷ 2 = 70px.
      await gesture.moveBy(const Offset(70, 0));
      await tester.pump();

      final r = rails(tester);
      expect(r.right!.progress, closeTo(0.5, 0.05));
      expect(r.left!.progress, 0, reason: '반대 방향은 0 을 유지한다');

      await gesture.moveBy(const Offset(70, 0));
      await tester.pump();
      expect(rails(tester).right!.progress, closeTo(1.0, 0.05));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('플립 전(enabled:false) 판정 레일은 0.35 를 넘지 못한다', (tester) async {
      await tester.pumpWidget(
        host(onLeft: () {}, onRight: () {}, enabled: false),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('카드')),
      );
      // 저항(×0.15)을 뚫을 만큼 크게 끌어도 꽉 차면 안 된다 — 확정이 안 되는데
      // 레일이 가득 차면 거짓 어포던스다.
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(40, 0));
        await tester.pump();
      }
      expect(rails(tester).right!.progress, lessThanOrEqualTo(0.35));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('배지를 안 준 방향(네비게이션 덱)은 중립색이다', (tester) async {
      // 한글 카드처럼 좌/우가 다음/이전인 화면은 배지를 주지 않는다.
      // 거기에 danger/primary 기본색이 붙으면 "다음"이 빨강, "이전"이 초록으로
      // 읽혀 정확히 반대 신호가 된다 (2026-08-18 발견).
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: const MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: SoriSwipeCard(
                    onSwipeLeft: _noop,
                    onSwipeRight: _noop,
                    child: Text('카드'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final r = rails(tester);
      expect(r.left!.color, isNot(SoriColors.danger));
      expect(r.right!.color, isNot(SoriColors.primary));
      expect(r.left!.color, r.right!.color, reason: '양쪽 다 같은 중립색');
    });

    testWidgets('레일 색은 그 방향 스탬프 색과 같다', (tester) async {
      await tester.pumpWidget(
        host(onLeft: () {}, onRight: () {}, onUp: () {}, onDown: () {}),
      );
      final r = rails(tester);
      expect(r.right!.color, SoriColors.success);
      expect(r.left!.color, SoriColors.danger);
      expect(r.up!.color, SoriColors.gold);
      expect(r.down!.color, SoriColors.info);
    });
  });

  group('§6 스프링백 오버슛', () {
    testWidgets('임계 미달 복귀는 원점을 지나쳐 튕기지 않는다', (tester) async {
      await tester.pumpWidget(host(onLeft: () {}, onRight: () {}));
      final card = find.text('카드');
      final origin = tester.getCenter(card).dx;

      // 커밋 임계(140px) 미달로 오른쪽 70px — 놓으면 원점으로 돌아온다.
      final gesture = await tester.startGesture(tester.getCenter(card));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(7, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();

      // 복귀 궤적을 60프레임 샘플링.
      double worstUndershoot = 0;
      var reversals = 0;
      double prev = tester.getCenter(card).dx;
      var wasFalling = true;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        final double now = tester.getCenter(card).dx;
        worstUndershoot = worstUndershoot > origin - now
            ? worstUndershoot
            : origin - now;
        final bool falling = now <= prev;
        if (falling != wasFalling && (now - prev).abs() > 0.2) {
          reversals++;
          wasFalling = falling;
        }
        prev = now;
      }

      // elasticOut(2.0) 은 원점을 한참 지나쳐 좌우로 여러 번 흔들렸다 —
      // 그게 Jin 이 말한 "붕붕"이다. damping ratio 0.82 스프링은 오버슛이
      // 1.1% 미만이라 70px 기준 1px 을 못 넘는다.
      expect(
        worstUndershoot,
        lessThan(3.0),
        reason: '원점을 3px 넘게 지나치면 튕기는 것으로 보인다',
      );
      expect(reversals, lessThanOrEqualTo(1), reason: '왕복은 1회 이하');

      await tester.pumpAndSettle();
      expect(tester.getCenter(card).dx, origin);
    });
  });

  group('§7 레일 지오메트리', () {
    test('inset 은 SoriCard accent 막대(0~4px)를 피한다', () {
      // SoriCard(accent:) 는 card.dart:196-203 에서 left:0 · width:4 로 전체
      // 높이 세로 막대를 그린다. 레일이 그 옆에 붙으면 왼쪽 변에 막대가 둘
      // 서는 꼴이라 어포던스가 아니라 노이즈가 된다. 최소 8 이상 확보.
      const rails = SoriSwipeRails(
        left: null,
        right: null,
        up: null,
        down: null,
      );
      expect(rails.inset, greaterThanOrEqualTo(8));
    });

    test('넛지 게이트는 순수 질의다 — 재생 전에는 소비되지 않는다', () async {
      // 초판은 soriDeckNudgeDue() 가 호출 즉시 소비해서, 호출부가 전부 build()
      // 안이라 ① 빌드가 부수효과를 갖고 ② 카드가 안 뜨는 빌드에서도 플래그가
      // 타 버려 넛지가 영원히 안 뜰 수 있었다.
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      await Storage.init();
      resetSoriDeckCoachForTesting();

      expect(soriDeckNudgeDue(), isTrue);
      expect(soriDeckNudgeDue(), isTrue, reason: '질의만으로는 안 닳는다');

      markSoriDeckNudgeShown();
      expect(soriDeckNudgeDue(), isFalse, reason: '실제 재생 시점에만 소비');
    });
  });

  group('§8 코드리뷰 회귀 (2026-08-18)', () {
    testWidgets('스프링 정착 도중 unmount 되어도 죽은 컨트롤러를 안 건드린다', (tester) async {
      // AnimationController.dispose() → Ticker.dispose() → TickerFuture._cancel()
      // 은 whenCompleteOrCancel 을 **_ticker 를 null 로 만든 뒤** 마이크로태스크로
      // 부른다. _AxisDriver.dispose() 가 세대 토큰을 안 올리면 그 콜백이 죽은
      // 컨트롤러에 value= 를 써서 터진다.
      // 실제 경로: ↑ 저장 콜백이 화면을 닫는 경우(grammar 의 onSwipeUp).
      var show = true;
      late StateSetter setOuter;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  if (!show) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: SizedBox(
                      width: 400,
                      height: 300,
                      child: SoriSwipeCard(
                        onSwipeUp: () {},
                        onSwipeLeft: _noop,
                        onSwipeRight: _noop,
                        child: const Text('카드'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // ↑ 커밋 → 제자리 스프링백 시작.
      await tester.fling(find.text('카드'), const Offset(0, -200), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // 정착 도중 화면을 닫는다.
      setOuter(() => show = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('퇴장 중 내려온 손가락은 다음 카드를 판정하지 못한다', (tester) async {
      // _onPanStart 가 _committing 일 때 조기 반환하면 이전 드래그의 _axis 가
      // 남아, 퇴장이 끝난 뒤 **아직 안 뗀 그 손가락**이 다음 카드를 몰기
      // 시작한다 — 이전 카드용 제스처가 다음 카드에 판정을 남긴다.
      var rights = 0;
      var downs = 0;
      await tester.pumpWidget(
        host(onLeft: _noop, onRight: () => rights++, onDown: () => downs++),
      );

      // 1) 우측 커밋 → 퇴장 시작. (콜백은 퇴장이 **끝날 때** 불린다.)
      await tester.fling(find.text('카드'), const Offset(220, 0), 2000);
      await tester.pump();

      // 2) 퇴장 40ms 지점(아직 _committing)에 손가락을 내리고, 퇴장이 끝난 뒤
      //    아래로 크게 끈다.
      await tester.pump(const Duration(milliseconds: 40));
      final g = await tester.startGesture(tester.getCenter(find.text('카드')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(rights, 1, reason: '첫 판정은 퇴장 완료 시점에 1회');
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();

      // 죽은 제스처다 — 어떤 방향도 판정하지 않는다.
      expect(rights, 1, reason: '두 번째 판정이 새어 나가면 안 된다');
      expect(downs, 0, reason: '퇴장 중 시작된 제스처는 통째로 무효');

      // 손을 뗀 뒤 새 제스처는 정상 동작해야 한다.
      await tester.fling(find.text('카드'), const Offset(0, 300), 2000);
      await tester.pumpAndSettle();
      expect(downs, 1, reason: '새 제스처는 살아 있다');
    });
  });

  group('§9 넛지 게이트 소비 (코드리뷰 C2)', () {
    testWidgets('onNudgePlayed 는 실제 재생될 때 정확히 1회', (tester) async {
      var played = 0;
      await tester.pumpWidget(nudgeHost(nudge: true, onPlayed: () => played++));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(played, 1);
      await tester.pumpAndSettle();
      expect(played, 1, reason: '정착 후에도 재발화 없음');
    });

    testWidgets('reduce-motion 에서는 게이트를 소비하지 않는다', (tester) async {
      // 재생을 안 했으면 소비도 하면 안 된다 — 소비해 버리면 그 사용자는 넛지를
      // 영영 못 본다(3.0 이 deck_coach 에서 고친 버그를 여기로 옮기는 셈).
      var played = 0;
      await tester.pumpWidget(
        nudgeHost(nudge: true, reduce: true, onPlayed: () => played++),
      );
      await tester.pumpAndSettle();
      expect(played, 0);
    });

    testWidgets('좌/우 미배선 카드는 게이트를 소비하지 않는다', (tester) async {
      var played = 0;
      await tester.pumpWidget(
        nudgeHost(nudge: true, wired: false, onPlayed: () => played++),
      );
      await tester.pumpAndSettle();
      expect(played, 0);
    });

    testWidgets('넛지 진폭은 판정 임계 한참 아래고 가짜 도장을 안 띄운다', (tester) async {
      // 실측 피크 18.53px = 400dp 의 4.6% → 스탬프 램프(4%) **위**였다.
      // 폭 의존이라 상수로 못 막으므로 넛지 중에는 스탬프를 아예 끈다.
      await tester.pumpWidget(nudgeHost(nudge: true));
      final origin = tester.getCenter(find.text('카드')).dx;
      double peak = 0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final d = tester.getCenter(find.text('카드')).dx - origin;
        peak = d > peak ? d : peak;
        expect(
          find.text('R'),
          findsNothing,
          reason: '넛지는 판정 예고가 아니다 — 도장이 뜨면 안 된다',
        );
      }
      expect(peak, inInclusiveRange(10, 26), reason: '커밋 임계 140px 한참 아래');
      expect(
        rails(tester).right!.progress,
        greaterThan(0.05),
        reason: '넛지 도중 레일은 실제로 차오른다',
      );
      await tester.pumpAndSettle();
    });
  });

  group('§10 이관된 계약 (코드리뷰 I1·I2)', () {
    testWidgets('축 잠금 순간 진 축은 점프하지 않고 스프링으로 0 에 간다', (tester) async {
      await tester.pumpWidget(
        host(onLeft: _noop, onRight: _noop, onUp: _noop, onDown: _noop),
      );
      final card = find.text('카드');
      final originY = tester.getCenter(card).dy;
      final g = await tester.startGesture(tester.getCenter(card));

      // ⚠️ 한 번에 크게 끌면 이 경로를 못 탄다: 축은 delta 를 **적용하기 전에**
      // 확정되므로, 진 축이 오프셋을 쥐고 있으려면 잠금(4px) **미만**의 이동이
      // 먼저 쌓여야 한다. 그래서 (3,3) → (4,0) 두 단계다.
      await g.moveBy(const Offset(3, 3));
      await tester.pump();
      expect(tester.getCenter(card).dy - originY, greaterThan(2));

      await g.moveBy(const Offset(4, 0));
      await tester.pump();

      var framesOffAxis = 0;
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        if ((tester.getCenter(card).dy - originY).abs() > 0.5) {
          framesOffAxis++;
        }
      }
      // jumpTo(0) 이면 첫 프레임에 이미 0 — 그게 예전의 "그 프레임에 보이는 점프".
      // 스프링이면 실측 2.65 → 1.62 로 8프레임 내내 살아 있다.
      expect(framesOffAxis, greaterThan(4), reason: '한 프레임 만에 0 이면 점프다');
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('위(-dy) 드래그는 다음 카드를 끌어올리지 않는다', (tester) async {
      // HANDOFF §P2-1: 저장은 전진이 아니므로 underlay 가 올라오면 거짓 어포던스.
      // 3.0 이 이 산술을 다른 ValueListenableBuilder 로 옮겼다 — 부호 뒤집힘 감시.
      await tester.pumpWidget(
        MaterialApp(
          home: const MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: SoriSwipeCard(
                    onSwipeUp: _noop,
                    onSwipeDown: _noop,
                    underlay: Text('다음'),
                    child: Text('카드'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Rect rest = tester.getRect(find.text('다음'));
      final g = await tester.startGesture(tester.getCenter(find.text('카드')));

      await g.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(
        tester.getRect(find.text('다음')),
        rest,
        reason: '↑ 는 전진이 아니다 — 다음 카드가 1px 도 올라오면 거짓 어포던스',
      );

      await g.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(
        tester.getRect(find.text('다음')).width,
        greaterThan(rest.width),
        reason: '↓ 는 전진이다 — 다음 카드가 올라온다',
      );
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('§11 실제로 칠하는가 · 손끝에 오는가 (코드리뷰 I3·I4)', () {
    testWidgets('레일은 정지 상태에서 실제로 칠해지고, 밀면 진해진다', (tester) async {
      // §4 는 전부 위젯 프로퍼티만 읽어서 `_RailsPainter` 가 통째로 무방비였다 —
      // 코드리뷰 실측: rest alpha 를 0 으로 만들어도 16건 전부 green.
      // "정지 상태에서도 옅게 늘 보인다"가 이 위젯의 존재 이유다.
      await tester.pumpWidget(host(onLeft: _noop, onRight: _noop));
      // `paints` 는 RenderObject 를 본다 — 위젯이 아니라 그 안의 CustomPaint.
      final canvas = find.descendant(
        of: find.byType(SoriSwipeRails),
        matching: find.byType(CustomPaint),
      );
      expect(
        canvas,
        paints
          ..rrect(color: SoriColors.danger.withValues(alpha: 0.16))
          ..rrect(color: SoriColors.success.withValues(alpha: 0.16)),
      );

      final g = await tester.startGesture(tester.getCenter(find.text('카드')));
      await g.moveBy(const Offset(140, 0)); // 커밋 임계 = 진행도 1.0
      await tester.pump();
      expect(
        canvas,
        paints
          ..rrect(color: SoriColors.danger.withValues(alpha: 0.16))
          ..rrect(color: SoriColors.success.withValues(alpha: 0.90)),
        reason: '진행도에 비례해 진해져야 "얼마나 더 밀어야 하는지"가 읽힌다',
      );
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('커밋 햅틱은 방향마다 다르고, 임계 통과 때 한 번 더 온다', (tester) async {
      final types = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            types.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(host(onLeft: _noop, onRight: _noop));
      final g = await tester.startGesture(tester.getCenter(find.text('카드')));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(const Offset(6, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // 임계(140px)를 넘는 순간 "여기서 놓으면 확정"을 알리는 selectionClick 1회.
      expect(
        types.where((t) => t.contains('selectionClick')).length,
        1,
        reason: '임계 통과 햅틱은 드래그당 방향별 1회',
      );

      await g.up();
      await tester.pumpAndSettle();
      // 우(앎) 커밋은 mediumImpact — 좌(모름)의 lightImpact 와 구분된다.
      expect(
        types.last,
        contains('mediumImpact'),
        reason: '우=앎 커밋은 mediumImpact',
      );
    });
  });

  group('§5 넛지', () {
    testWidgets('nudge:false 면 카드는 가만히 있는다', (tester) async {
      await tester.pumpWidget(host(onLeft: () {}, onRight: () {}));
      final origin = tester.getCenter(find.text('카드'));
      // 첫 pump 는 ticker 의 elapsed 가 0 이라 값이 안 변한다 — 한 번 더.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getCenter(find.text('카드')), origin);
      await tester.pumpAndSettle();
    });

    testWidgets('nudge:true 는 카드를 밀었다 정확히 원점으로 돌린다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: SoriSwipeCard(
                    nudge: true,
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    child: Container(
                      color: SoriColors.lightSurfaceRaised,
                      alignment: Alignment.center,
                      child: const Text('카드'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final origin = tester.getCenter(find.text('카드'));
      // 첫 pump 는 ticker 의 elapsed 가 0 이라 값이 안 변한다 — 한 번 더.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.getCenter(find.text('카드')).dx,
        greaterThan(origin.dx),
        reason: '넛지는 실제로 카드를 민다 — 그래야 레일이 함께 차오른다',
      );
      await tester.pumpAndSettle();
      // 스프링 tolerance 잔여 서브픽셀까지 흡수해 **정확히** 원점.
      expect(tester.getCenter(find.text('카드')), origin);
    });

    testWidgets('reduce-motion 에서는 넛지가 재생되지 않는다', (tester) async {
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
                    nudge: true,
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    child: Container(
                      color: SoriColors.lightSurfaceRaised,
                      alignment: Alignment.center,
                      child: const Text('카드'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final origin = tester.getCenter(find.text('카드'));
      // 첫 pump 는 ticker 의 elapsed 가 0 이라 값이 안 변한다 — 한 번 더.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getCenter(find.text('카드')), origin);
      await tester.pumpAndSettle();
    });
  });
}
