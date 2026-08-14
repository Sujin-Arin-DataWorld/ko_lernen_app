import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// 스와이프 판정 스탬프 (틴더식 코너 배지) 정의.
class SoriSwipeBadge {
  final String label;
  final IconData icon;
  final Color color;
  const SoriSwipeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 덱 래퍼 (Sori Deck 2.0,
/// 2026-08-14 §P2).
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
/// 제스처: 수평 전용 → 팬 + **지배축 잠금**(누적 12px 시점의 큰 축으로 확정,
/// 이후 반대축 delta 무시) — 대각 드래그의 이중 트리거를 구조적으로 차단.
/// 카드 면의 세로 스크롤 폴백(오버플로 시)은 축 전용 recognizer 라 팬보다
/// 우선한다 — 넘치는 카드에서는 스크롤이, 정상 카드에서는 ↓/↑ 가 이긴다.
///
/// [underlay] = 덱 스택 미리보기(다음 카드 **앞면만** — 뒷면은 정답 유출,
/// flip_card.dart re-key 계약과 같은 원칙). 진행도는 커밋 거리로 정규화하고
/// **위(-dy) 드래그는 제외**(저장은 전진이 아니므로 다음 카드가 올라오면
/// 거짓 어포던스).
///
/// reduce-motion 에서는 퇴장/복귀 애니메이션 없이 즉시 판정·복귀한다
/// (드래그 추적 자체는 직접 조작이라 유지).
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

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

enum _DragAxis { horizontal, vertical }

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;

  /// 지배축 확정 임계 (누적 원시 이동량).
  static const double _axisLockDistance = 12;

  /// !enabled 수평 저항 계수 — 커밋 절대 금지, 표시만.
  static const double _blockedResistance = 0.15;

  /// 힌트 발화 임계 — **원시 손가락 이동량** 기준 (표시 오프셋 기준이면 저항
  /// 0.15 탓에 ~160px 을 끌어야 발화 — 발견성 목적 상실).
  static const double _blockedHintDistance = 24;

  // late-lazy 로 두면 컨트롤러를 한 번도 안 쓴 채 dispose 될 때(리듀스 모션
  // 경로) unmount 중 TickerMode 조상 조회로 크래시한다 — initState 에서 생성.
  late final AnimationController _ctrl;
  double _dx = 0;
  double _dy = 0;
  _DragAxis? _axis;
  double _rawDx = 0;
  double _rawDy = 0;
  double _blockedRawDx = 0;
  bool _blockedHintFired = false;
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _horizontalWired =>
      widget.onSwipeLeft != null || widget.onSwipeRight != null;

  bool get _verticalWired =>
      widget.onSwipeUp != null || widget.onSwipeDown != null;

  bool get _anyWired => _horizontalWired || _verticalWired;

  double _verticalThreshold(double height) => math.min(120.0, height * 0.25);

  void _onPanStart(DragStartDetails details) {
    _axis = null;
    _rawDx = 0;
    _rawDy = 0;
    _blockedRawDx = 0;
    _blockedHintFired = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_anyWired || _committing) {
      return;
    }
    _rawDx += details.delta.dx;
    _rawDy += details.delta.dy;
    if (_axis == null) {
      if (math.max(_rawDx.abs(), _rawDy.abs()) < _axisLockDistance) {
        return;
      }
      // 지배축 확정 — 반대축 표시 오프셋은 0 에서 시작 (대각 이중 트리거 차단).
      _axis = _rawDx.abs() >= _rawDy.abs()
          ? _DragAxis.horizontal
          : _DragAxis.vertical;
      _dx = 0;
      _dy = 0;
    }
    switch (_axis!) {
      case _DragAxis.horizontal:
        if (!_horizontalWired) {
          return;
        }
        if (widget.enabled) {
          setState(() => _dx += details.delta.dx);
        } else {
          // 저항 드래그 — 커밋 절대 금지. 힌트는 원시 이동량 기준 1회.
          _blockedRawDx += details.delta.dx;
          if (!_blockedHintFired &&
              _blockedRawDx.abs() > _blockedHintDistance) {
            _blockedHintFired = true;
            widget.onBlockedHorizontalDrag?.call();
          }
          setState(() => _dx += details.delta.dx * _blockedResistance);
        }
      case _DragAxis.vertical:
        if (!_verticalWired) {
          return;
        }
        setState(() => _dy += details.delta.dy);
    }
  }

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (!_anyWired || _committing) {
      return;
    }
    final axis = _axis;
    _axis = null;
    if (axis == _DragAxis.horizontal) {
      if (!widget.enabled) {
        // 계약: enabled:false 에서 좌/우 콜백 0회 — 저항 표시만 복귀.
        _springBack();
        return;
      }
      final double v = details.velocity.pixelsPerSecond.dx;
      final bool right = _dx > width * _commitFraction || v > _commitVelocity;
      final bool left = _dx < -width * _commitFraction || v < -_commitVelocity;
      if (right && widget.onSwipeRight != null) {
        _commitExit(to: Offset(width * 1.3, 0), callback: widget.onSwipeRight!);
      } else if (left && widget.onSwipeLeft != null) {
        _commitExit(to: Offset(-width * 1.3, 0), callback: widget.onSwipeLeft!);
      } else {
        _springBack();
      }
      return;
    }
    if (axis == _DragAxis.vertical) {
      final double vy = details.velocity.pixelsPerSecond.dy;
      final double threshold = _verticalThreshold(height);
      final bool down = _dy > threshold || vy > _commitVelocity;
      final bool up = _dy < -threshold || vy < -_commitVelocity;
      if (down && widget.onSwipeDown != null) {
        _commitExit(to: Offset(0, height * 1.1), callback: widget.onSwipeDown!);
      } else if (up && widget.onSwipeUp != null) {
        _commitSaveInPlace(widget.onSwipeUp!);
      } else {
        _springBack();
      }
      return;
    }
    _springBack();
  }

  /// 좌/우/아래 — 방향 퇴장 후 콜백. 다음 카드는 중앙에서 등장.
  void _commitExit({required Offset to, required VoidCallback callback}) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      callback();
      return;
    }
    _committing = true;
    _animateOffset(
      to: to,
      duration: SoriMotion.fast,
      curve: SoriMotion.emphasis,
      onDone: () {
        _committing = false;
        // 다음 카드가 중앙에서 등장하도록 위치는 애니메이션 없이 복귀.
        setState(() {
          _dx = 0;
          _dy = 0;
        });
        callback();
      },
    );
  }

  /// 위=저장 — **퇴장 없음**. 커밋 순간 콜백 1회 후 제자리 스프링백
  /// (저장은 전진이 아니다 — 피드백은 호출부의 스낵바/버스트).
  void _commitSaveInPlace(VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    callback();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      return;
    }
    _committing = true;
    _animateOffset(
      to: Offset.zero,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
      onDone: () {
        _committing = false;
      },
    );
  }

  void _springBack() {
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      return;
    }
    _animateOffset(
      to: Offset.zero,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
    );
  }

  void _animateOffset({
    required Offset to,
    required Duration duration,
    required Curve curve,
    VoidCallback? onDone,
  }) {
    final Animation<Offset> anim = _ctrl.drive(
      Tween<Offset>(
        begin: Offset(_dx, _dy),
        end: to,
      ).chain(CurveTween(curve: curve)),
    );
    void tick() {
      if (mounted) {
        setState(() {
          _dx = anim.value.dx;
          _dy = anim.value.dy;
        });
      }
    }

    anim.addListener(tick);
    _ctrl.duration = duration;
    _ctrl.forward(from: 0).whenCompleteOrCancel(() {
      anim.removeListener(tick);
      if (mounted) {
        setState(() {
          _dx = to.dx;
          _dy = to.dy;
        });
        onDone?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = SoriMotion.reduceMotion(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.5;
        final double progress = (_dx / width).clamp(-1.0, 1.0);
        // 틸트는 수평축에서만 — 아래 모서리를 축으로 살짝(최대 ~9°).
        final double angle = progress * 0.16;
        final double vertThreshold = _verticalThreshold(height);
        final double downProgress = (_dy / vertThreshold).clamp(-1.0, 1.0);
        // 수직축은 틸트 없이 순수 이동 + 미세 스케일 (1.0 → 0.97).
        final double verticalScale = 1.0 - 0.03 * downProgress.abs();

        final Widget card = Transform.translate(
          offset: Offset(_dx, _dy),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: verticalScale,
              child: Stack(
                children: [
                  widget.child,
                  if (widget.rightBadge != null)
                    _Stamp(
                      badge: widget.rightBadge!,
                      opacity: ((progress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topLeft,
                      tilt: -0.15,
                    ),
                  if (widget.leftBadge != null)
                    _Stamp(
                      badge: widget.leftBadge!,
                      opacity: ((-progress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topRight,
                      tilt: 0.15,
                    ),
                  // ↑ 저장 배지 = 카드 하단 중앙, ↓ 스킵 배지 = 상단 중앙.
                  if (widget.upBadge != null)
                    _Stamp(
                      badge: widget.upBadge!,
                      opacity: ((-downProgress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.bottomCenter,
                      tilt: 0,
                    ),
                  if (widget.downBadge != null)
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: ((downProgress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topCenter,
                      tilt: 0,
                    ),
                ],
              ),
            ),
          ),
        );

        Widget body = card;
        if (widget.underlay != null) {
          // 진행도는 **커밋 거리**로 정규화 — 카드가 퇴장하는 순간 p=1 이
          // 되도록 (|_dx|/폭 으로 나누면 커밋 시점 p=0.35 에서 underlay 가
          // 65% 덜 올라온 채 점프한다). **위(-dy)는 제외** — 저장은 전진이
          // 아니다. 퇴장 애니메이션 동안 p=1.0 유지.
          double p = math.max(
            _dx.abs() / (width * _commitFraction),
            math.max(_dy, 0.0) / vertThreshold,
          );
          p = p.clamp(0.0, 1.0);
          if (_committing) {
            p = 1.0;
          }
          if (reduce) {
            p = 0.0;
          }
          final double underScale = 0.95 + 0.05 * p;
          final double underDy = 10.0 * (1.0 - p);
          body = Stack(
            fit: StackFit.passthrough,
            children: [
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(0, underDy),
                  child: Transform.scale(
                    scale: underScale,
                    child: widget.underlay!,
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
          onPanUpdate: _anyWired ? _onPanUpdate : null,
          onPanEnd: _anyWired
              ? (details) => _onPanEnd(details, width, height)
              : null,
          child: body,
        );
      },
    );
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
                      Icon(badge.icon, color: badge.color, size: 20),
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
