import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'swipe_rails.dart';
import 'tokens.dart';

/// 스와이프 판정 스탬프 (틴더식 코너 배지) 정의.
class SoriSwipeBadge {
  final String label;
  final IconData icon;
  final Color color;
  final String? asset;
  const SoriSwipeBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.asset,
  });
}

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 덱 래퍼 (Sori Deck 2.0,
/// 2026-08-14 §P2 · **물리 재작성 3.0, 2026-08-18**).
///
/// 방향 의미는 Jin 확정(§1) — 좌=모름 · 우=앎 · **위=저장(super like)** ·
/// **아래=스킵(다음으로)**. 학습 카드에 겹쳐 **탭과 공존**한다: 자식
/// (SoriPressable/FlipCard)의 탭/플립은 그대로 두고 팬 드래그만 가로챈다.
///
/// 판정 무결성 계약:
/// - [enabled] 의 의미는 불변 = **"좌/우 판정 허용"** (flipgate 센서들이 이
///   의미를 물고 있다). `enabled:false` 에서 좌/우 콜백은 **0회** — 단
///   핸들러를 죽이는 대신 **저항 드래그**(표시 오프셋 ×0.15)로 카드가 살아
///   있음을 보여 주고, 원시 손가락 이동량 24px 초과 최초 1회
///   [onBlockedHorizontalDrag] 로 힌트를 쏜다 (발견성).
/// - ↑/↓ 는 판정이 아니므로 게이트 무관 — [onSwipeUp] 은 커밋 후 카드가
///   **제자리 스프링백**(저장은 전진이 아니다), [onSwipeDown] 은 하단 퇴장.
///   null 이면 그 방향은 꺼진다.
///
/// ## 3.0 물리 (2026-08-18) — "붕붕대는" 손맛 제거
///
/// 원인은 셋이고 **체감 기여도 순서**는 다음과 같다 (전부
/// `test/deck_swipe_physics_test.dart` 에서 파괴-복원으로 증명했다):
///
/// 1. **[주범] elasticOut → 스프링 시뮬레이션.** 복귀 커브가
///    `SoriMotion.release`(= `Curves.elasticOut`) 라 임계 미달 드래그를 놓으면
///    카드가 원점을 한참 지나쳐 좌우로 여러 번 흔들렸다 — 그게 말 그대로
///    "붕붕"이다. 이제 [SoriMotion.deckSpring](damping ratio ≈ 0.82) 으로
///    간다: 오버슛 1.1% 미만, 왕복 1회 이하. 저댐핑(damping 8)으로 되돌리면
///    70px 복귀에서 원점을 38px 지나쳐 센서가 빨개진다.
/// 2. **데드존 제거 + 속도 승계.** 축 잠금 임계는 12px → **4px**
///    ([SoriMotion.deckAxisLock]) 이고 **잠금 전에도 카드가 양축으로 손가락을
///    따라간다**. 예전엔 첫 12px 의 표시 오프셋을 버려서 "안 따라오다 갑자기
///    붙는" 느낌이 났다. 잠금 순간 진 축은 버리지 않고 스프링으로 0 까지
///    되돌린다(점프 없음). 퇴장도 고정 150ms 가 아니라 **손을 뗀 속도를
///    승계**해 120~220ms 로 clamp — 세게 던지면 빨리 나간다.
///    ⚠️ 정확히는 **0px 부터 따라오는 게 아니다**: 실제 덱은 카드 안에 탭(플립)
///    recognizer 가 있어 팬이 제스처 아레나에서 `kTouchSlop` 까지 못 이긴다 —
///    실측 ~21px 이 아레나 몫이고 `deckAxisLock` 으로는 못 줄인다. 다만
///    `DragStartBehavior.start` 기본값이라 그 구간이 **점프로 재생되지 않아**
///    "갑자기 붙는" 증상 자체는 사라진다.
/// 3. **프레임당 setState 제거.** 위치는 `ValueNotifier<Offset>` 하나로 들고
///    [ValueListenableBuilder] 의 `child:` 슬롯에 카드 본문을 넣는다.
///    ⚠️ 정직하게: 2.0 의 setState 도 **자식 서브트리까지 재빌드하지는
///    않았다** — `Element.updateChild` 가 위젯 인스턴스 동일 시 서브트리를
///    건너뛴다. 실제로 없앤 비용은 프레임마다 `build()` + LayoutBuilder 빌더
///    재실행 + Transform/Stack/스탬프 재할당 + 엘리먼트 더티 표시이고,
///    이건 손맛보다 배터리/저사양 기기 쪽 이득이다. `child:` 슬롯 계약은
///    **불변 가드**로 센서를 걸어 뒀다(§1).
///
/// 제스처: 팬 + **지배축 잠금**(누적 4px 시점의 큰 축으로 확정, 이후 반대축
/// delta 무시) — 대각 드래그의 이중 트리거를 구조적으로 차단.
/// 카드 면의 세로 스크롤 폴백(오버플로 시)은 축 전용 recognizer 라 팬보다
/// 우선한다 — 넘치는 카드에서는 스크롤이, 정상 카드에서는 ↓/↑ 가 이긴다.
///
/// [underlay] = 덱 스택 미리보기(다음 카드 **앞면만** — 뒷면은 정답 유출,
/// flip_card.dart re-key 계약과 같은 원칙). 진행도는 커밋 거리로 정규화하고
/// **위(-dy) 드래그는 제외**(저장은 전진이 아니므로 다음 카드가 올라오면
/// 거짓 어포던스).
///
/// reduce-motion 에서는 퇴장/복귀 애니메이션 없이 즉시 판정·복귀한다
/// (드래그 추적 자체는 직접 조작이라 유지). 햅틱은 모션이 아니라 정보이므로
/// reduce-motion 에서도 유지한다.
class SoriSwipeCard extends StatefulWidget {
  const SoriSwipeCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.leftBadge,
    this.rightBadge,
    this.upBadge,
    this.downBadge,
    this.enabled = true,
    this.onBlockedHorizontalDrag,
    this.underlay,
    this.nudge = false,
    this.onNudgePlayed,
  });

  final Widget child;

  /// 판정: 모름 — [enabled] 게이트 대상.
  final VoidCallback? onSwipeLeft;

  /// 판정: 앎 — [enabled] 게이트 대상.
  final VoidCallback? onSwipeRight;

  /// 저장 — 게이트 무관. 커밋 후 카드 복귀(퇴장 없음). null 이면 위 방향 꺼짐.
  final VoidCallback? onSwipeUp;

  /// 스킵 — 게이트 무관, 하단 퇴장. null 이면 아래 방향 꺼짐.
  final VoidCallback? onSwipeDown;

  final SoriSwipeBadge? leftBadge;
  final SoriSwipeBadge? rightBadge;
  final SoriSwipeBadge? upBadge;
  final SoriSwipeBadge? downBadge;

  /// ⚠️ 의미 유지 = "좌/우 판정 허용" (flipgate 계약).
  final bool enabled;

  /// 플립 전 수평 시도 → 힌트 훅 (드래그당 1회, 원시 이동량 24px 기준).
  final VoidCallback? onBlockedHorizontalDrag;

  /// 덱 스택 미리보기 (다음 카드 앞면). null 이면 스택 없음.
  final Widget? underlay;

  /// 첫 진입 1회, 카드를 살짝 밀었다 놓아 "끌 수 있는 물건"임을 시연한다.
  ///
  /// 예전 `grammar_screen` 의 `_SwipeNudge` 는 카드를 **밖에서** 흔들어서
  /// 레일·스탬프가 반응하지 않았다 — 움직임만 보이고 결과는 안 보였다.
  /// 이제 내부 오프셋을 직접 몰기 때문에 넛지 도중 **우측 레일이 실제로
  /// 차오르고 같은 스프링으로 돌아온다** — 사용자가 곧 느낄 물리를 미리 본다.
  ///
  /// 게이트는 호출부 책임 — `soriDeckNudgeDue()`(deck_coach.dart) 를 쓴다.
  /// reduce-motion 에서는 재생하지 않는다(전정기관 자극 회피).
  final bool nudge;

  /// 넛지가 **실제로 재생될 때** 1회. 세션 게이트 소비는 여기서 한다 —
  /// 질의 시점에 소비하면 카드가 안 뜨는 빌드에서 플래그만 타 버린다.
  /// 관례상 `markSoriDeckNudgeShown`(deck_coach.dart) 를 넘긴다.
  final VoidCallback? onNudgePlayed;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

enum _DragAxis { horizontal, vertical }

/// 임계 통과 햅틱을 방향당 1회로 묶는 래치 키.
enum _CommitDir { left, right, up, down }

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with TickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;

  /// !enabled 수평 저항 계수 — 커밋 절대 금지, 표시만.
  static const double _blockedResistance = 0.15;

  /// 힌트 발화 임계 — **원시 손가락 이동량** 기준 (표시 오프셋 기준이면 저항
  /// 0.15 탓에 ~160px 을 끌어야 발화 — 발견성 목적 상실).
  static const double _blockedHintDistance = 24;

  /// 카드 위치의 단일 소스. 자식 서브트리를 재빌드하지 않고 Transform 만
  /// 갱신하기 위해 setState 대신 이 notifier 를 쓴다.
  final ValueNotifier<Offset> _offset = ValueNotifier<Offset>(Offset.zero);

  // 축별 드라이버 — 스프링/퇴장을 축마다 독립으로 돌린다.
  // late-lazy 로 두면 컨트롤러를 한 번도 안 쓴 채 dispose 될 때(리듀스 모션
  // 경로) unmount 중 TickerMode 조상 조회로 크래시한다 — initState 에서 생성.
  late final _AxisDriver _cx;
  late final _AxisDriver _cy;

  _DragAxis? _axis;
  double _rawDx = 0;
  double _rawDy = 0;
  double _blockedRawDx = 0;
  bool _blockedHintFired = false;
  bool _committing = false;

  /// 퇴장 애니메이션 세대 — 재타깃으로 취소된 옛 완료 콜백을 무시한다.
  int _exitToken = 0;

  /// 이번 드래그에서 임계 햅틱을 이미 쏜 방향.
  final Set<_CommitDir> _thresholdFired = <_CommitDir>{};

  /// 퇴장 애니메이션 중에 손가락이 내려온 제스처는 **통째로 무효**다.
  ///
  /// `_committing` 만 보고 매 콜백에서 판단하면, 퇴장이 끝나는 120~220ms 뒤부터
  /// **아직 안 뗀 그 손가락이 다음 카드를 몰기 시작한다** — 이전 카드용으로
  /// 시작된 드래그가 다음 카드에 SRS 판정을 남길 수 있다. 제스처 단위로 래치한다.
  bool _gestureDead = false;

  // ⚠️ `late final _nudgeCtrl = AnimationController(...)` 로 두면 안 된다.
  // 넛지가 꺼진 경우 build 가 컨트롤러를 한 번도 읽지 않아 초기화가 미뤄지고,
  // dispose() 가 그제서야 생성자를 돌려 **이미 비활성화된 element** 에서
  // createTicker → 조상 조회로 터진다 (deck_coach.dart:117 과 같은 교훈).
  late final AnimationController _nudgeCtrl;
  late final Animation<double> _nudgeDx;
  bool _nudgePlayed = false;

  /// 넛지 재생~정착 구간. 이 동안 판정 스탬프를 억제한다 — 넛지는 "밀 수 있다"를
  /// 보여 주는 것이지 판정 예고가 아니다. 첫 드래그에서 해제된다.
  bool _nudging = false;

  @override
  void initState() {
    super.initState();
    _cx = _AxisDriver(this, _sync);
    _cy = _AxisDriver(this, _sync);
    _nudgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    // 진폭 18dp — 커밋 임계(카드 폭의 35%)보다 한참 작아 판정이 실수로
    // 일어나지 않는다. 레일은 임계 대비로 정규화되므로 이 정도에서도 눈에 띄게
    // 차오른다.
    //
    // ⚠️ 초판 주석은 "스탬프 램프(4%) 아래라 가짜 도장은 안 뜬다"고 했는데
    // **틀렸다**: 400dp 카드에서 실측 피크가 18.53px = 4.6%, 320dp 면 5.8% 라
    // 흐릿한 "Gewusst" 도장이 실제로 떴다. 폭에 따라 달라지는 값을 상수로
    // 막을 수는 없으므로 [_nudging] 동안 스탬프를 **아예 끈다**.
    _nudgeDx = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 18), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 18, end: -12), weight: 1.6),
    ]).animate(CurvedAnimation(parent: _nudgeCtrl, curve: Curves.easeInOut));
    _nudgeCtrl.addListener(_onNudgeTick);
    if (widget.nudge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNudge());
    }
  }

  void _onNudgeTick() {
    _cx.jumpTo(_supportedHorizontalOffset(_nudgeDx.value));
  }

  void _maybeNudge() {
    if (!mounted || _nudgePlayed || !widget.nudge) {
      return;
    }
    if (SoriMotion.reduceMotion(context) || !_horizontalWired) {
      return;
    }
    _nudgePlayed = true;
    _nudging = true;
    widget.onNudgePlayed?.call();
    // ⚠️ `whenCompleteOrCancel` 이 아니라 `then` — 취소에도 불리면, 손으로
    // 넛지를 낚아챈 직후(마이크로태스크라 `_cx.hold()` 뒤다) 스프링이 켜져
    // **가만히 있는 손가락 밑에서 카드가 흐른다**(실측 3.8px → 1.9px).
    // TickerFuture 의 기본 future 는 자연 완료에만 완료된다.
    // ignore: discarded_futures
    _nudgeCtrl.forward(from: 0).then((_) {
      if (!mounted) {
        return;
      }
      // 복귀는 실제 스프링 — 사용자가 곧 손으로 느낄 그 물리다.
      _cx.spring(0, 0);
    });
  }

  @override
  void dispose() {
    _nudgeCtrl.removeListener(_onNudgeTick);
    _nudgeCtrl.dispose();
    _cx.dispose();
    _cy.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _sync() {
    _offset.value = Offset(_cx.value, _cy.value);
  }

  double get _dx => _cx.value;
  double get _dy => _cy.value;

  bool get _horizontalWired =>
      widget.onSwipeLeft != null || widget.onSwipeRight != null;

  bool get _verticalWired =>
      widget.onSwipeUp != null || widget.onSwipeDown != null;

  bool get _anyWired => _horizontalWired || _verticalWired;

  double _verticalThreshold(double height) => math.min(120.0, height * 0.25);

  double _supportedHorizontalOffset(double proposed) {
    if (proposed < 0 && widget.onSwipeLeft == null) {
      return 0;
    }
    if (proposed > 0 && widget.onSwipeRight == null) {
      return 0;
    }
    return proposed;
  }

  double _supportedVerticalOffset(double proposed) {
    if (proposed < 0 && widget.onSwipeUp == null) {
      return 0;
    }
    if (proposed > 0 && widget.onSwipeDown == null) {
      return 0;
    }
    return proposed;
  }

  /// 퇴장 duration — 플링이 셀수록 짧다 (퇴장은 진입의 ~75%).
  Duration _exitDuration(double distance, double speed) {
    if (speed.abs() < 1) {
      return SoriMotion.deckExitMax;
    }
    final int ms = (distance.abs() / speed.abs() * 1000).round();
    return Duration(
      milliseconds: ms.clamp(
        SoriMotion.deckExitMin.inMilliseconds,
        SoriMotion.deckExitMax.inMilliseconds,
      ),
    );
  }

  // ── 제스처 ───────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    _gestureDead = _committing;
    _nudging = false;
    if (!_gestureDead) {
      // 정착 중인 스프링/넛지를 손으로 낚아채는 경로 — 스냅 콜백까지 무효화.
      _nudgeCtrl.stop();
      _cx.hold();
      _cy.hold();
    }
    // ⚠️ 상태 리셋은 **조기 반환 뒤로 숨기면 안 된다**. 숨기면 이전 드래그의
    // `_axis`/`_rawD*`/힌트·햅틱 래치가 남아 다음 제스처를 오염시킨다.
    _axis = null;
    _rawDx = 0;
    _rawDy = 0;
    _blockedRawDx = 0;
    _blockedHintFired = false;
    _thresholdFired.clear();
  }

  void _onPanUpdate(DragUpdateDetails details, double width, double height) {
    if (!_anyWired || _committing || _gestureDead) {
      return;
    }
    _rawDx += details.delta.dx;
    _rawDy += details.delta.dy;

    if (_axis == null &&
        math.max(_rawDx.abs(), _rawDy.abs()) >= SoriMotion.deckAxisLock) {
      // 지배축 확정. 진 축은 **버리지 않고** 스프링으로 0 까지 되돌린다 —
      // 예전처럼 0 을 대입하면 그 프레임에 점프가 보인다.
      _axis = _rawDx.abs() >= _rawDy.abs()
          ? _DragAxis.horizontal
          : _DragAxis.vertical;
      if (_axis == _DragAxis.horizontal) {
        _cy.spring(0, 0);
      } else {
        _cx.spring(0, 0);
      }
    }

    // 잠금 전에는 양축 모두 손가락을 따라간다 (데드존 제거).
    final bool trackH = _axis == null || _axis == _DragAxis.horizontal;
    final bool trackV = _axis == null || _axis == _DragAxis.vertical;

    if (trackH && _horizontalWired) {
      if (widget.enabled) {
        _cx.jumpTo(_supportedHorizontalOffset(_dx + details.delta.dx));
      } else {
        // 저항 드래그 — 커밋 절대 금지. 힌트는 원시 이동량 기준 1회.
        _blockedRawDx += details.delta.dx;
        final supportedDirection =
            (_blockedRawDx < 0 && widget.onSwipeLeft != null) ||
            (_blockedRawDx > 0 && widget.onSwipeRight != null);
        if (supportedDirection &&
            !_blockedHintFired &&
            _blockedRawDx.abs() > _blockedHintDistance) {
          _blockedHintFired = true;
          widget.onBlockedHorizontalDrag?.call();
        }
        _cx.jumpTo(
          _supportedHorizontalOffset(
            _dx + details.delta.dx * _blockedResistance,
          ),
        );
      }
    }
    if (trackV && _verticalWired) {
      _cy.jumpTo(_supportedVerticalOffset(_dy + details.delta.dy));
    }

    _maybeThresholdHaptic(width, height);
  }

  /// "여기서 놓으면 확정된다"를 손끝으로 알린다 — 드래그당 방향별 1회.
  void _maybeThresholdHaptic(double width, double height) {
    _CommitDir? dir;
    if (_axis == _DragAxis.horizontal && widget.enabled) {
      final double t = width * _commitFraction;
      if (_dx >= t && widget.onSwipeRight != null) {
        dir = _CommitDir.right;
      } else if (_dx <= -t && widget.onSwipeLeft != null) {
        dir = _CommitDir.left;
      }
    } else if (_axis == _DragAxis.vertical) {
      final double t = _verticalThreshold(height);
      if (_dy >= t && widget.onSwipeDown != null) {
        dir = _CommitDir.down;
      } else if (_dy <= -t && widget.onSwipeUp != null) {
        dir = _CommitDir.up;
      }
    }
    if (dir != null && _thresholdFired.add(dir)) {
      // ignore: discarded_futures
      HapticFeedback.selectionClick();
    }
  }

  void _onPanCancel() {
    if (_committing || _gestureDead) {
      return;
    }
    _axis = null;
    _springBack();
  }

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (!_anyWired || _committing || _gestureDead) {
      return;
    }
    final axis = _axis;
    _axis = null;
    if (axis == _DragAxis.horizontal) {
      if (!widget.enabled) {
        // 계약: enabled:false 에서 좌/우 콜백 0회 — 저항 표시만 복귀.
        _springBack(vx: details.velocity.pixelsPerSecond.dx);
        return;
      }
      final double v = details.velocity.pixelsPerSecond.dx;
      final bool right = _dx > width * _commitFraction || v > _commitVelocity;
      final bool left = _dx < -width * _commitFraction || v < -_commitVelocity;
      if (right && widget.onSwipeRight != null) {
        _commitExit(
          to: Offset(width * 1.3, 0),
          speed: v,
          haptic: HapticFeedback.mediumImpact,
          callback: widget.onSwipeRight!,
        );
      } else if (left && widget.onSwipeLeft != null) {
        _commitExit(
          to: Offset(-width * 1.3, 0),
          speed: v,
          haptic: HapticFeedback.lightImpact,
          callback: widget.onSwipeLeft!,
        );
      } else {
        _springBack(vx: v);
      }
      return;
    }
    if (axis == _DragAxis.vertical) {
      final double vy = details.velocity.pixelsPerSecond.dy;
      final double threshold = _verticalThreshold(height);
      final bool down = _dy > threshold || vy > _commitVelocity;
      final bool up = _dy < -threshold || vy < -_commitVelocity;
      if (down && widget.onSwipeDown != null) {
        _commitExit(
          to: Offset(0, height * 1.1),
          speed: vy,
          haptic: HapticFeedback.selectionClick,
          callback: widget.onSwipeDown!,
        );
      } else if (up && widget.onSwipeUp != null) {
        _commitSaveInPlace(widget.onSwipeUp!);
      } else {
        _springBack(vy: vy);
      }
      return;
    }
    _springBack(
      vx: details.velocity.pixelsPerSecond.dx,
      vy: details.velocity.pixelsPerSecond.dy,
    );
  }

  /// 좌/우/아래 — 방향 퇴장 후 콜백. 다음 카드는 중앙에서 등장.
  void _commitExit({
    required Offset to,
    required double speed,
    required VoidCallback haptic,
    required VoidCallback callback,
  }) {
    // ignore: discarded_futures
    haptic();
    if (SoriMotion.reduceMotion(context)) {
      _resetOffset();
      callback();
      return;
    }
    _committing = true;
    final int token = ++_exitToken;
    final double travelX = (to.dx - _dx).abs();
    final double travelY = (to.dy - _dy).abs();
    final Duration d = _exitDuration(math.max(travelX, travelY), speed);
    final TickerFuture fx = _cx.glideTo(to.dx, d);
    final TickerFuture fy = _cy.glideTo(to.dy, d);
    // ⚠️ `AnimationController.animateTo` 는 target == value 일 때 duration 을
    // Duration.zero 로 접는다 — 수평 퇴장에서 y 축 future 를 물면 완료 콜백이
    // **즉시** 터져 카드가 날아가기도 전에 다음 카드가 서빙된다. 실제로
    // 이동하는 축을 드라이버로 삼는다.
    final TickerFuture driver = travelX >= travelY ? fx : fy;
    driver.whenCompleteOrCancel(() {
      if (!mounted || token != _exitToken) {
        return;
      }
      _committing = false;
      // 다음 카드가 중앙에서 등장하도록 위치는 애니메이션 없이 복귀.
      _resetOffset();
      callback();
    });
  }

  /// 위=저장 — **퇴장 없음**. 커밋 순간 콜백 1회 후 제자리 스프링백
  /// (저장은 전진이 아니다 — 피드백은 호출부의 스낵바/버스트).
  ///
  /// 좌/우/아래와 달리 `_committing` 래치를 걸지 **않는다**: 카드는 그 자리에
  /// 남으므로 정착 도중 다시 잡아도 안전하고, 오히려 그게 스프링을 쓰는
  /// 이유다(중단 가능한 애니메이션). `_onPanStart` 가 드라이버를 멈춘다.
  void _commitSaveInPlace(VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.mediumImpact();
    callback();
    if (SoriMotion.reduceMotion(context)) {
      _resetOffset();
      return;
    }
    _cx.spring(0, 0);
    _cy.spring(0, 0);
  }

  void _springBack({double vx = 0, double vy = 0}) {
    if (SoriMotion.reduceMotion(context)) {
      _resetOffset();
      return;
    }
    _cx.spring(0, vx);
    _cy.spring(0, vy);
  }

  void _resetOffset() {
    _cx.jumpTo(0);
    _cy.jumpTo(0);
  }

  // ── 빌드 ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = SoriMotion.reduceMotion(context);
    // 배지를 안 준 방향은 **판정이 아니다** — 한글 카드처럼 좌/우가 그냥
    // 다음/이전인 네비게이션 덱이 그렇다. 거기에 danger/primary 를 깔면
    // "다음"이 빨강, "이전"이 초록으로 읽혀 정확히 반대 신호가 된다.
    // 의미를 선언하지 않은 방향은 중립색으로 둔다.
    final Color neutralRail = SoriSurfaces.of(context).textMuted;
    // ⚠️ widget.child 는 아래 ValueListenableBuilder 의 `child:` 슬롯으로
    // 들어간다 — 드래그·퇴장 중 재빌드되지 않는다 (3.0 §1).
    final Widget cardContent = widget.child;
    final Widget? underlayContent = widget.underlay;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.5;
        final double vertThreshold = _verticalThreshold(height);

        final Widget card = ValueListenableBuilder<Offset>(
          valueListenable: _offset,
          child: cardContent,
          builder: (context, o, child) {
            final double progress = (o.dx / width).clamp(-1.0, 1.0);
            // 틸트는 수평축에서만 — 아래 모서리를 축으로 살짝(최대 ~9°).
            final double angle = progress * 0.16;
            final double downProgress = (o.dy / vertThreshold).clamp(-1.0, 1.0);
            // 수직축은 틸트 없이 순수 이동 + 미세 스케일 (1.0 → 0.97).
            final double verticalScale = 1.0 - 0.03 * downProgress.abs();
            return Transform.translate(
              offset: o,
              child: Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: verticalScale,
                  child: Stack(
                    children: [
                      child!,
                      // 어포던스 레일 — 정지 상태에서도 "어느 방향이 살아
                      // 있고 무슨 뜻인지"를 보여 준다 (3.0 §2).
                      SoriSwipeRails(
                        left: _rail(
                          widget.onSwipeLeft,
                          -progress / _commitFraction,
                          widget.leftBadge?.color ?? neutralRail,
                          gated: true,
                        ),
                        right: _rail(
                          widget.onSwipeRight,
                          progress / _commitFraction,
                          widget.rightBadge?.color ?? neutralRail,
                          gated: true,
                        ),
                        up: _rail(
                          widget.onSwipeUp,
                          -downProgress,
                          widget.upBadge?.color ?? neutralRail,
                        ),
                        down: _rail(
                          widget.onSwipeDown,
                          downProgress,
                          widget.downBadge?.color ?? neutralRail,
                        ),
                      ),
                      if (widget.onSwipeRight != null &&
                          widget.rightBadge != null)
                        _Stamp(
                          badge: widget.rightBadge!,
                          opacity: _ramp(progress),
                          alignment: Alignment.topLeft,
                          tilt: -0.15,
                        ),
                      if (widget.onSwipeLeft != null &&
                          widget.leftBadge != null)
                        _Stamp(
                          badge: widget.leftBadge!,
                          opacity: _ramp(-progress),
                          alignment: Alignment.topRight,
                          tilt: 0.15,
                        ),
                      // ↑ 저장 배지 = 카드 하단 중앙, ↓ 스킵 배지 = 상단 중앙.
                      if (widget.onSwipeUp != null && widget.upBadge != null)
                        _Stamp(
                          badge: widget.upBadge!,
                          opacity: _ramp(-downProgress),
                          alignment: Alignment.bottomCenter,
                          tilt: 0,
                        ),
                      if (widget.onSwipeDown != null &&
                          widget.downBadge != null)
                        _Stamp(
                          badge: widget.downBadge!,
                          opacity: _ramp(downProgress),
                          alignment: Alignment.topCenter,
                          tilt: 0,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        Widget body = card;
        if (underlayContent != null) {
          body = Stack(
            fit: StackFit.passthrough,
            children: [
              IgnorePointer(
                // The next card is decoration, not another readable card.
                // Excluding it prevents screen readers from announcing two
                // words and two action sets at the same time.
                child: ExcludeSemantics(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _offset,
                    child: underlayContent,
                    builder: (context, o, child) {
                      // 진행도는 **커밋 거리**로 정규화 — 카드가 퇴장하는 순간
                      // p=1 이 되도록 (|dx|/폭 으로 나누면 커밋 시점 p=0.35 에서
                      // underlay 가 65% 덜 올라온 채 점프한다). **위(-dy)는
                      // 제외** — 저장은 전진이 아니다. 퇴장 중에는 p=1.0 유지.
                      double p = math.max(
                        o.dx.abs() / (width * _commitFraction),
                        math.max(o.dy, 0.0) / vertThreshold,
                      );
                      p = p.clamp(0.0, 1.0);
                      if (_committing) {
                        p = 1.0;
                      }
                      if (reduce) {
                        p = 0.0;
                      }
                      return Transform.translate(
                        offset: Offset(0, 10.0 * (1.0 - p)),
                        child: Transform.scale(
                          scale: 0.95 + 0.05 * p,
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
              card,
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _anyWired ? _onPanStart : null,
          onPanUpdate: _anyWired
              ? (details) => _onPanUpdate(details, width, height)
              : null,
          onPanEnd: _anyWired
              ? (details) => _onPanEnd(details, width, height)
              : null,
          onPanCancel: _anyWired ? _onPanCancel : null,
          child: body,
        );
      },
    );
  }

  /// 스탬프 램프 — 3.0 에서 시작점을 8% → **4%** 로 당겨 더 일찍 읽히게 했다.
  /// 넛지 중에는 0 — 시연용 움직임이 판정 예고로 보이면 안 된다.
  double _ramp(double p) =>
      _nudging ? 0.0 : ((p - 0.04) / 0.25).clamp(0.0, 1.0);

  /// 방향 레일 상태. [handler] 가 null 이면 그 방향은 레일 자체가 없다.
  ///
  /// [gated] 는 좌/우 판정 방향 — `enabled:false`(플립 전)에서는 아무리 끌어도
  /// 확정되지 않으므로 레일도 **0.35 를 넘지 못하게** 막는다. 꽉 차는데 확정이
  /// 안 되면 거짓 어포던스가 된다.
  SoriRailState? _rail(
    VoidCallback? handler,
    double raw,
    Color color, {
    bool gated = false,
  }) {
    if (handler == null) {
      return null;
    }
    double p = raw.clamp(0.0, 1.0);
    if (gated && !widget.enabled) {
      p = math.min(p, 0.35);
    }
    return SoriRailState(progress: p, color: color);
  }
}

/// 한 축(가로 또는 세로)의 위치를 모는 unbounded 컨트롤러 래퍼.
///
/// 스프링은 tolerance 안에서 멈추므로 **완료 시 목표값으로 정확히 스냅**해야
/// 한다 (안 하면 카드가 0.3px 어긋난 채 남아 "정확히 원점 복귀" 계약이 깨진다).
/// 다만 사용자가 정착 도중 카드를 다시 잡으면 그 스냅이 점프가 되므로,
/// 세대 토큰으로 "내가 시작한 애니메이션이 끝났을 때만" 스냅한다.
class _AxisDriver {
  _AxisDriver(TickerProvider vsync, VoidCallback onTick)
    : ctrl = AnimationController.unbounded(vsync: vsync) {
    ctrl.addListener(onTick);
  }

  final AnimationController ctrl;
  int _token = 0;

  double get value => ctrl.value;

  /// 진행 중인 애니메이션을 무효화하고 멈춘다 (스냅 콜백도 함께 무효화).
  void hold() {
    _token++;
    ctrl.stop();
  }

  /// 애니메이션 없이 즉시 [v] 로.
  void jumpTo(double v) {
    hold();
    ctrl.value = v;
  }

  /// 물리 스프링 복귀. [velocity] 는 손을 뗀 순간의 px/s — 이 승계가
  /// "손가락에서 이어진다"는 감각의 핵심이다.
  void spring(double target, double velocity) {
    if ((ctrl.value - target).abs() < 0.5 && velocity.abs() < 1) {
      jumpTo(target);
      return;
    }
    hold();
    final int token = _token;
    ctrl
        .animateWith(
          SpringSimulation(
            SoriMotion.deckSpring,
            ctrl.value,
            target,
            velocity,
            // 기본 tolerance(1e-3 px)면 눈에 안 보이는 잔여 진폭을 쫓느라
            // ~700ms 동안 ticker 를 물고 있다. 서브픽셀에서 끊는다.
            tolerance: const Tolerance(distance: 0.5, velocity: 1),
          ),
        )
        .whenCompleteOrCancel(() {
          if (_token != token) {
            return;
          }
          // tolerance 잔여 서브픽셀 흡수 — "정확히 원점" 계약.
          ctrl.value = target;
        });
  }

  /// 방향 퇴장 — 스프링이 아니라 직선 활강(오버슛 금지).
  TickerFuture glideTo(double target, Duration duration) {
    hold();
    return ctrl.animateTo(
      target,
      duration: duration,
      curve: SoriMotion.emphasis,
    );
  }

  /// ⚠️ dispose 도 **재타깃과 같다** — 진행 중인 스프링의 스냅 콜백을 무효화한다.
  /// `AnimationController.dispose()` → `Ticker.dispose()` → `TickerFuture._cancel()`
  /// 는 `whenCompleteOrCancel` 을 **`_ticker` 를 null 로 만든 뒤 마이크로태스크로**
  /// 부른다. 토큰을 안 올리면 그 콜백이 죽은 컨트롤러에 `value =` 를 써서 터진다.
  /// 실제 경로: ↑ 저장 → `_commitSaveInPlace` 가 `_cy` 를 스프링 복귀시키는 동안
  /// 저장 콜백이 화면을 닫는다 (`grammar_screen` 의 `onSwipeUp: _saveCurrent`).
  void dispose() {
    _token++;
    ctrl.dispose();
  }
}

/// 드래그 진행에 비례해 떠오르는 판정 스탬프.
class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.badge,
    required this.opacity,
    required this.alignment,
    required this.tilt,
  });

  final SoriSwipeBadge badge;
  final double opacity;
  final Alignment alignment;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) {
      return const SizedBox.shrink();
    }
    final asset = badge.asset;
    final Widget mark = asset == null
        ? Icon(badge.icon, color: badge.color, size: 20)
        : Image.asset(
            asset,
            width: 22,
            height: 22,
            errorBuilder: (_, _, _) =>
                Icon(badge.icon, color: badge.color, size: 20),
          );
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: tilt,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: 0.12),
                    border: Border.all(color: badge.color, width: 2.5),
                    borderRadius: SoriRadius.brMd,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      mark,
                      const SizedBox(width: Spacing.xs),
                      Text(
                        badge.label,
                        style: SoriTextTheme.of(
                          context,
                        ).h3.copyWith(color: badge.color, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
