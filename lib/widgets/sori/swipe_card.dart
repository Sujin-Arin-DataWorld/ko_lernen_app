import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

enum _SwipeAxis { horizontal, vertical }

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

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 덱 래퍼 (2026-08-14 P2).
///
/// 학습 카드에 겹쳐 **탭과 공존**한다. 좌/우 판정은 [enabled] 게이트를 따른다
/// (`enabled` = "좌/우 판정 허용" — flipgate 센서가 이 의미를 고정한다).
/// 위(저장)·아래(스킵)는 게이트와 무관하다.
///
/// 임계: 수평 = 폭 35% 또는 700px/s. 수직 = min(120, 높이 25%) 또는 700px/s.
/// 위 커밋은 퇴장 없이 스프링백한다. reduce-motion 에서는 즉시 확정.
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

  /// 좌/우 판정 허용. 위/아래는 이 값과 무관하다.
  final bool enabled;
  final VoidCallback? onBlockedHorizontalDrag;
  final Widget? underlay;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;
  static const double _axisLock = 12;
  static const double _blockedHintRaw = 24;
  static const double _resist = 0.15;

  late final AnimationController _ctrl;
  double _dx = 0;
  double _dy = 0;
  double _blockedRawDx = 0;
  bool _blockedHintFired = false;
  bool _committing = false;
  _SwipeAxis? _axis;

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

  bool get _listens =>
      widget.onSwipeLeft != null ||
      widget.onSwipeRight != null ||
      widget.onSwipeUp != null ||
      widget.onSwipeDown != null;

  void _resetDrag() {
    _axis = null;
    _blockedRawDx = 0;
    _blockedHintFired = false;
  }

  void _onPanStart(DragStartDetails details) {
    if (_committing) {
      return;
    }
    _resetDrag();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_committing) {
      return;
    }
    var ddx = details.delta.dx;
    var ddy = details.delta.dy;
    if (_axis == null) {
      final nextDx = _dx + ddx;
      final nextDy = _dy + ddy;
      if (math.max(nextDx.abs(), nextDy.abs()) >= _axisLock) {
        _axis = nextDx.abs() >= nextDy.abs()
            ? _SwipeAxis.horizontal
            : _SwipeAxis.vertical;
      }
    }
    if (_axis == _SwipeAxis.horizontal) {
      ddy = 0;
    } else if (_axis == _SwipeAxis.vertical) {
      ddx = 0;
    }

    if (_axis == _SwipeAxis.horizontal && !widget.enabled) {
      _blockedRawDx += details.delta.dx;
      if (!_blockedHintFired && _blockedRawDx.abs() > _blockedHintRaw) {
        _blockedHintFired = true;
        widget.onBlockedHorizontalDrag?.call();
      }
      setState(() => _dx += details.delta.dx * _resist);
      return;
    }

    if (_axis == _SwipeAxis.horizontal &&
        widget.enabled &&
        widget.onSwipeLeft == null &&
        widget.onSwipeRight == null) {
      return;
    }
    if (_axis == _SwipeAxis.vertical &&
        widget.onSwipeUp == null &&
        widget.onSwipeDown == null) {
      return;
    }

    setState(() {
      _dx += ddx;
      _dy += ddy;
    });
  }

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (_committing) {
      return;
    }
    final v = details.velocity.pixelsPerSecond;
    final vThresh = math.min(120.0, height * 0.25);

    if (_axis == _SwipeAxis.vertical) {
      final up =
          widget.onSwipeUp != null &&
          (_dy < -vThresh || v.dy < -_commitVelocity);
      final down =
          widget.onSwipeDown != null &&
          (_dy > vThresh || v.dy > _commitVelocity);
      if (up) {
        _commitUp();
      } else if (down) {
        _commitExit(0, height * 1.1, widget.onSwipeDown!);
      } else {
        _springBack();
      }
      _resetDrag();
      return;
    }

    if (!widget.enabled) {
      _springBack();
      _resetDrag();
      return;
    }

    final right =
        widget.onSwipeRight != null &&
        (_dx > width * _commitFraction || v.dx > _commitVelocity);
    final left =
        widget.onSwipeLeft != null &&
        (_dx < -width * _commitFraction || v.dx < -_commitVelocity);
    if (right) {
      _commitExit(width * 1.3, 0, widget.onSwipeRight!);
    } else if (left) {
      _commitExit(-width * 1.3, 0, widget.onSwipeLeft!);
    } else {
      _springBack();
    }
    _resetDrag();
  }

  void _commitUp() {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    widget.onSwipeUp?.call();
    _springBack();
  }

  void _commitExit(double toX, double toY, VoidCallback callback) {
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
    _animate(
      toX: toX,
      toY: toY,
      duration: SoriMotion.fast,
      curve: SoriMotion.emphasis,
      onDone: () {
        _committing = false;
        setState(() {
          _dx = 0;
          _dy = 0;
        });
        callback();
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
    _animate(
      toX: 0,
      toY: 0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
    );
  }

  void _animate({
    required double toX,
    required double toY,
    required Duration duration,
    required Curve curve,
    VoidCallback? onDone,
  }) {
    final animX = _ctrl.drive(
      Tween<double>(begin: _dx, end: toX).chain(CurveTween(curve: curve)),
    );
    final animY = _ctrl.drive(
      Tween<double>(begin: _dy, end: toY).chain(CurveTween(curve: curve)),
    );
    void tick() {
      if (mounted) {
        setState(() {
          _dx = animX.value;
          _dy = animY.value;
        });
      }
    }

    animX.addListener(tick);
    _ctrl.duration = duration;
    _ctrl.forward(from: 0).whenCompleteOrCancel(() {
      animX.removeListener(tick);
      if (mounted) {
        setState(() {
          _dx = toX;
          _dy = toY;
        });
        onDone?.call();
      }
    });
  }

  double _underlayP(double width, double height) {
    if (_committing && _dy >= 0) {
      return 1.0;
    }
    if (_axis == _SwipeAxis.vertical && _dy < 0) {
      return 0;
    }
    final hThresh = width * _commitFraction;
    final vThresh = math.min(120.0, height * 0.25);
    final hp = hThresh <= 0 ? 0.0 : _dx.abs() / hThresh;
    final vp = _dy > 0 && vThresh > 0 ? _dy / vThresh : 0.0;
    return math.max(hp, vp).clamp(0.0, 1.0);
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
        final double hProgress = width == 0
            ? 0
            : (_dx / width).clamp(-1.0, 1.0);
        final double angle = _axis == _SwipeAxis.vertical
            ? 0
            : hProgress * 0.16;
        final vThresh = math.min(120.0, height * 0.25);
        final vP = vThresh <= 0 ? 0.0 : (_dy.abs() / vThresh).clamp(0.0, 1.0);
        final scale = _axis == _SwipeAxis.vertical ? (1.0 - 0.03 * vP) : 1.0;
        final p = _underlayP(width, height);
        final reduce = SoriMotion.reduceMotion(context);
        final underlayP = reduce ? 0.0 : p;

        final Widget card = Transform.translate(
          offset: Offset(_dx, _dy),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  widget.child,
                  if (widget.rightBadge != null)
                    _Stamp(
                      badge: widget.rightBadge!,
                      opacity: ((hProgress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topLeft,
                      tilt: -0.15,
                    ),
                  if (widget.leftBadge != null)
                    _Stamp(
                      badge: widget.leftBadge!,
                      opacity: ((-hProgress - 0.08) / 0.25).clamp(0.0, 1.0),
                      alignment: Alignment.topRight,
                      tilt: 0.15,
                    ),
                  if (widget.upBadge != null)
                    _Stamp(
                      badge: widget.upBadge!,
                      opacity: _dy < 0
                          ? ((-_dy / math.max(vThresh, 1)) - 0.08) / 0.25
                          : 0,
                      alignment: Alignment.bottomCenter,
                      tilt: 0,
                    ),
                  if (widget.downBadge != null)
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: _dy > 0
                          ? ((_dy / math.max(vThresh, 1)) - 0.08) / 0.25
                          : 0,
                      alignment: Alignment.topCenter,
                      tilt: 0,
                    ),
                ],
              ),
            ),
          ),
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _listens ? _onPanStart : null,
          onPanUpdate: _listens ? _onPanUpdate : null,
          onPanEnd: _listens
              ? (details) => _onPanEnd(details, width, height)
              : null,
          child: Stack(
            children: [
              if (widget.underlay != null)
                IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - underlayP)),
                    child: Transform.scale(
                      scale: 0.95 + 0.05 * underlayP,
                      child: widget.underlay,
                    ),
                  ),
                ),
              card,
            ],
          ),
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
              opacity: opacity.clamp(0.0, 1.0),
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
                      if (badge.asset != null)
                        Image.asset(
                          badge.asset!,
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) =>
                              Icon(badge.icon, color: badge.color, size: 20),
                        )
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
