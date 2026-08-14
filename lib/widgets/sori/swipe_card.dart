import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// 스와이프 판정 스탬프 (틴더식 코너 배지) 정의.
class SoriSwipeBadge {
  final String label;
  final IconData icon;
  final Color color;
  final ImageProvider? image;

  const SoriSwipeBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.image,
  });
}

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 판정·저장·스킵 래퍼 (2026-08-14 v2.0).
///
/// 4방향 의미 고정:
/// - **오른쪽(→)**: 앎 (Got it / Gewusst) — enabled 게이트 대상
/// - **왼쪽(←)**: 모름 (Don't know / Nicht gewusst) — enabled 게이트 대상
/// - **위(↑)**: 단어장에 저장 (Super like) — 게이트 무관, 커밋 후 제자리 스프링백
/// - **아래(↓)**: 스킵 / 다음으로 — 게이트 무관, 하단 퇴장
///
/// reduce-motion 에서는 퇴장/복귀 애니메이션 없이 즉시 판정·복귀한다.
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
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final SoriSwipeBadge? leftBadge;
  final SoriSwipeBadge? rightBadge;
  final SoriSwipeBadge? upBadge;
  final SoriSwipeBadge? downBadge;
  final bool enabled;
  final VoidCallback? onBlockedHorizontalDrag;
  final Widget? underlay;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

enum _SwipeAxis { horizontal, vertical }

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;

  late final AnimationController _ctrl;
  double _dx = 0;
  double _dy = 0;
  double _blockedRawDx = 0;
  bool _blockedHintFired = false;
  _SwipeAxis? _axis;
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

  void _onPanStart(DragStartDetails details) {
    if (_committing) return;
    _axis = null;
    _blockedRawDx = 0;
    _blockedHintFired = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_committing) return;

    final rawDx = details.delta.dx;
    final rawDy = details.delta.dy;

    if (_axis == null) {
      final totalDistX = (_dx + rawDx).abs();
      final totalDistY = (_dy + rawDy).abs();
      if (math.max(totalDistX, totalDistY) >= 12) {
        _axis = totalDistX >= totalDistY
            ? _SwipeAxis.horizontal
            : _SwipeAxis.vertical;
      }
    }

    if (_axis == _SwipeAxis.horizontal) {
      if (widget.enabled) {
        setState(() => _dx += rawDx);
      } else {
        // 저항 드래그 (0.15x) + 힌트 트리거 (원시 이동량 24px 이상)
        _blockedRawDx += rawDx;
        if (!_blockedHintFired && _blockedRawDx.abs() > 24) {
          _blockedHintFired = true;
          widget.onBlockedHorizontalDrag?.call();
        }
        setState(() => _dx += rawDx * 0.15);
      }
    } else if (_axis == _SwipeAxis.vertical) {
      setState(() => _dy += rawDy);
    } else {
      // 축 확정 전 누적
      setState(() {
        _dx += rawDx;
        _dy += rawDy;
      });
    }
  }

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (_committing) return;

    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final verticalThreshold = math.min(120.0, height * 0.25);

    if (_axis == _SwipeAxis.horizontal) {
      if (widget.enabled) {
        final bool right = _dx > width * _commitFraction || vx > _commitVelocity;
        final bool left = _dx < -width * _commitFraction || vx < -_commitVelocity;
        if (right && widget.onSwipeRight != null) {
          _commitHorizontal(width, 1, widget.onSwipeRight!);
          return;
        } else if (left && widget.onSwipeLeft != null) {
          _commitHorizontal(width, -1, widget.onSwipeLeft!);
          return;
        }
      }
      _springBack();
    } else if (_axis == _SwipeAxis.vertical) {
      final bool up = _dy < -verticalThreshold || vy < -_commitVelocity;
      final bool down = _dy > verticalThreshold || vy > _commitVelocity;

      if (up && widget.onSwipeUp != null) {
        _commitUp(widget.onSwipeUp!);
        return;
      } else if (down && widget.onSwipeDown != null) {
        _commitDown(height, widget.onSwipeDown!);
        return;
      }
      _springBack();
    } else {
      _springBack();
    }
  }

  void _commitHorizontal(double width, int direction, VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
        _axis = null;
      });
      callback();
      return;
    }
    _committing = true;
    _animate(
      targetDx: direction * width * 1.3,
      targetDy: _dy,
      duration: SoriMotion.fast,
      curve: SoriMotion.emphasis,
      onDone: () {
        _committing = false;
        setState(() {
          _dx = 0;
          _dy = 0;
          _axis = null;
        });
        callback();
      },
    );
  }

  void _commitDown(double height, VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
        _axis = null;
      });
      callback();
      return;
    }
    _committing = true;
    _animate(
      targetDx: _dx,
      targetDy: height * 1.1,
      duration: SoriMotion.fast,
      curve: SoriMotion.emphasis,
      onDone: () {
        _committing = false;
        setState(() {
          _dx = 0;
          _dy = 0;
          _axis = null;
        });
        callback();
      },
    );
  }

  void _commitUp(VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.mediumImpact();
    callback();
    _committing = true;
    _animate(
      targetDx: 0,
      targetDy: 0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
      onDone: () {
        _committing = false;
        setState(() {
          _dx = 0;
          _dy = 0;
          _axis = null;
        });
      },
    );
  }

  void _springBack() {
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
        _axis = null;
      });
      return;
    }
    _animate(
      targetDx: 0,
      targetDy: 0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
      onDone: () {
        setState(() {
          _axis = null;
        });
      },
    );
  }

  void _animate({
    required double targetDx,
    required double targetDy,
    required Duration duration,
    required Curve curve,
    VoidCallback? onDone,
  }) {
    final startDx = _dx;
    final startDy = _dy;
    final Animation<double> anim = _ctrl.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
    );

    void tick() {
      if (mounted) {
        setState(() {
          _dx = startDx + (targetDx - startDx) * anim.value;
          _dy = startDy + (targetDy - startDy) * anim.value;
        });
      }
    }

    anim.addListener(tick);
    _ctrl.duration = duration;
    _ctrl.forward(from: 0).whenCompleteOrCancel(() {
      anim.removeListener(tick);
      if (mounted) {
        setState(() {
          _dx = targetDx;
          _dy = targetDy;
        });
        onDone?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        final double verticalThreshold = math.min(120.0, height * 0.25);
        final double progressX = (_dx / width).clamp(-1.0, 1.0);
        final double progressY = (_dy / height).clamp(-1.0, 1.0);

        // 틸트는 수평축에서만
        final double angle = (_axis == _SwipeAxis.vertical) ? 0.0 : progressX * 0.16;

        // 수직축 미세 스케일 (1.0 -> 0.97)
        final double verticalScale = (_axis == _SwipeAxis.vertical)
            ? (1.0 - progressY.abs() * 0.03).clamp(0.97, 1.0)
            : 1.0;

        // 덱 스택(underlay) 진행도 계산: 위(-dy) 드래그는 제외
        final double commitProgress;
        if (_committing && _dy <= 0 && _dx == 0) {
          commitProgress = 0.0;
        } else if (_committing) {
          commitProgress = 1.0;
        } else {
          final pHoriz = _dx.abs() / (0.35 * width);
          final pDown = (_dy > 0) ? (_dy / verticalThreshold) : 0.0;
          commitProgress = math.max(pHoriz, pDown).clamp(0.0, 1.0);
        }

        final double underlayScale = SoriMotion.reduceMotion(context)
            ? 0.95
            : 0.95 + 0.05 * commitProgress;
        final double underlayTranslateY = SoriMotion.reduceMotion(context)
            ? 10.0
            : 10.0 * (1.0 - commitProgress);

        final Widget card = Transform.translate(
          offset: Offset(_dx, _dy),
          child: Transform.scale(
            scale: verticalScale,
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  widget.child,
                  if (widget.rightBadge != null && (_axis != _SwipeAxis.vertical || _dx.abs() > 5))
                    _Stamp(
                      badge: widget.rightBadge!,
                      opacity: ((progressX - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topLeft,
                      tilt: -0.15,
                    ),
                  if (widget.leftBadge != null && (_axis != _SwipeAxis.vertical || _dx.abs() > 5))
                    _Stamp(
                      badge: widget.leftBadge!,
                      opacity: ((-progressX - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topRight,
                      tilt: 0.15,
                    ),
                  if (widget.upBadge != null && (_axis != _SwipeAxis.horizontal || _dy.abs() > 5))
                    _Stamp(
                      badge: widget.upBadge!,
                      opacity: ((-_dy / verticalThreshold - 0.1) / 0.3).clamp(0.0, 1.0),
                      alignment: Alignment.bottomCenter,
                      tilt: 0.0,
                    ),
                  if (widget.downBadge != null && (_axis != _SwipeAxis.horizontal || _dy.abs() > 5))
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: ((_dy / verticalThreshold - 0.1) / 0.3).clamp(0.0, 1.0),
                      alignment: Alignment.topCenter,
                      tilt: 0.0,
                    ),
                ],
              ),
            ),
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.underlay != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, underlayTranslateY),
                    child: Transform.scale(
                      scale: underlayScale,
                      child: widget.underlay,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => _onPanEnd(details, width, height),
              child: card,
            ),
          ],
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
                      if (badge.image != null)
                        Image(image: badge.image!, width: 22, height: 22, fit: BoxFit.contain)
                      else
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
