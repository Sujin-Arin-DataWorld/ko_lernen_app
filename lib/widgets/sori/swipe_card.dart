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

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 래퍼 (UI/UX 개편 2 §P2).
///
/// - ←/→ : 판정(모름/앎). [enabled] 게이트 대상 — 플립 전에는 저항 드래그만.
/// - ↑ : 저장. 게이트 무관, 퇴장 없이 스프링백. [onSwipeUp] null 이면 꺼짐.
/// - ↓ : 스킵. 게이트 무관, 하단 퇴장. [onSwipeDown] null 이면 꺼짐.
///
/// 기존 [onSwipeLeft]/[onSwipeRight]/[enabled] 의미는 불변(호출부 무수정 컴파일).
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

  /// "좌/우 판정 허용" — flipgate 센서가 이 의미를 물고 있다.
  final bool enabled;

  /// 플립 전 수평 시도(원시 24px+) → 힌트 훅. 드래그당 1회.
  final VoidCallback? onBlockedHorizontalDrag;

  /// 덱 스택 미리보기(다음 카드 앞면). null 이면 스택 없음.
  final Widget? underlay;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

enum _SwipeAxis { horizontal, vertical }

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;
  static const double _axisLockPx = 12;
  static const double _blockedHintRawPx = 24;

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

  bool get _hasHorizontal =>
      widget.onSwipeLeft != null || widget.onSwipeRight != null;
  bool get _hasVertical =>
      widget.onSwipeUp != null || widget.onSwipeDown != null;
  bool get _canPan => _hasHorizontal || _hasVertical;

  void _onPanStart(DragStartDetails details) {
    if (_committing) {
      return;
    }
    _axis = null;
    _blockedRawDx = 0;
    _blockedHintFired = false;
  }

  void _onPanUpdate(DragUpdateDetails details, double height) {
    if (!_canPan || _committing) {
      return;
    }
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    if (_axis == null) {
      final tentativeDx = _dx + dx;
      final tentativeDy = _dy + dy;
      if (tentativeDx.abs() >= _axisLockPx ||
          tentativeDy.abs() >= _axisLockPx) {
        _axis = tentativeDx.abs() >= tentativeDy.abs()
            ? _SwipeAxis.horizontal
            : _SwipeAxis.vertical;
      }
    }

    if (_axis == _SwipeAxis.horizontal) {
      if (!widget.enabled) {
        // 저항 드래그 — 표시는 0.15×, 힌트는 원시 손가락 이동량 기준.
        _blockedRawDx += dx;
        setState(() => _dx += dx * 0.15);
        if (!_blockedHintFired &&
            _blockedRawDx.abs() > _blockedHintRawPx &&
            widget.onBlockedHorizontalDrag != null) {
          _blockedHintFired = true;
          widget.onBlockedHorizontalDrag!();
        }
        return;
      }
      if (!_hasHorizontal) {
        return;
      }
      setState(() => _dx += dx);
      return;
    }

    if (_axis == _SwipeAxis.vertical) {
      if (!_hasVertical) {
        return;
      }
      // up = negative dy; down = positive dy
      final nextDy = _dy + dy;
      if (nextDy < 0 && widget.onSwipeUp == null) {
        return;
      }
      if (nextDy > 0 && widget.onSwipeDown == null) {
        return;
      }
      setState(() => _dy = nextDy);
    }
  }

  double _verticalThreshold(double height) =>
      (height * 0.25).clamp(1.0, 120.0);

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (!_canPan || _committing) {
      _resetDrag();
      return;
    }
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    final vThresh = _verticalThreshold(height);

    if (_axis == _SwipeAxis.horizontal && widget.enabled) {
      final right = _dx > width * _commitFraction || vx > _commitVelocity;
      final left = _dx < -width * _commitFraction || vx < -_commitVelocity;
      if (right && widget.onSwipeRight != null) {
        _commitExit(Offset(width * 1.3, 0), widget.onSwipeRight!);
        return;
      }
      if (left && widget.onSwipeLeft != null) {
        _commitExit(Offset(-width * 1.3, 0), widget.onSwipeLeft!);
        return;
      }
    } else if (_axis == _SwipeAxis.vertical) {
      final up = _dy < -vThresh || vy < -_commitVelocity;
      final down = _dy > vThresh || vy > _commitVelocity;
      if (up && widget.onSwipeUp != null) {
        _commitSave(widget.onSwipeUp!);
        return;
      }
      if (down && widget.onSwipeDown != null) {
        _commitExit(Offset(0, height * 1.1), widget.onSwipeDown!);
        return;
      }
    }
    _springBack();
  }

  void _resetDrag() {
    _axis = null;
    _blockedRawDx = 0;
    _blockedHintFired = false;
  }

  void _commitExit(Offset to, VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      _resetDrag();
      callback();
      return;
    }
    _committing = true;
    _animate(
      toDx: to.dx,
      toDy: to.dy,
      duration: SoriMotion.fast,
      curve: SoriMotion.emphasis,
      onDone: () {
        _committing = false;
        setState(() {
          _dx = 0;
          _dy = 0;
        });
        _resetDrag();
        callback();
      },
    );
  }

  /// ↑ 저장 — 퇴장 없음, 콜백 후 스프링백.
  void _commitSave(VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    callback();
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      _resetDrag();
      return;
    }
    _committing = true;
    _animate(
      toDx: 0,
      toDy: 0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
      onDone: () {
        _committing = false;
        _resetDrag();
      },
    );
  }

  void _springBack() {
    if (SoriMotion.reduceMotion(context)) {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
      _resetDrag();
      return;
    }
    _animate(
      toDx: 0,
      toDy: 0,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
      onDone: _resetDrag,
    );
  }

  void _animate({
    required double toDx,
    required double toDy,
    required Duration duration,
    required Curve curve,
    VoidCallback? onDone,
  }) {
    final beginDx = _dx;
    final beginDy = _dy;
    final Animation<double> t = _ctrl.drive(
      CurveTween(curve: curve),
    );
    void tick() {
      if (!mounted) {
        return;
      }
      final p = t.value;
      setState(() {
        _dx = beginDx + (toDx - beginDx) * p;
        _dy = beginDy + (toDy - beginDy) * p;
      });
    }

    t.addListener(tick);
    _ctrl.duration = duration;
    _ctrl.forward(from: 0).whenCompleteOrCancel(() {
      t.removeListener(tick);
      if (mounted) {
        setState(() {
          _dx = toDx;
          _dy = toDy;
        });
        onDone?.call();
      }
    });
  }

  double _underlayProgress(double width, double height) {
    // 위(-dy) 드래그는 p 계산에서 제외 (저장은 전진이 아님).
    final hProg = width > 0 ? _dx.abs() / (0.35 * width) : 0.0;
    final downOnly = _dy > 0 ? _dy : 0.0;
    final vProg = downOnly / _verticalThreshold(height);
    return (hProg > vProg ? hProg : vProg).clamp(0.0, 1.0);
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
        final double hProgress = (_dx / width).clamp(-1.0, 1.0);
        final double angle = (_axis == _SwipeAxis.vertical)
            ? 0.0
            : hProgress * 0.16;
        final double vScale = (_axis == _SwipeAxis.vertical)
            ? (1.0 - (_dy.abs() / (height * 0.5)).clamp(0.0, 1.0) * 0.03)
            : 1.0;

        final underlayP = widget.underlay == null
            ? 0.0
            : (_committing && _dy >= 0
                  ? 1.0
                  : _underlayProgress(width, height));
        final reduce = SoriMotion.reduceMotion(context);

        final Widget card = Transform.translate(
          offset: Offset(_dx, _dy),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: vScale,
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
                      opacity: ((-_dy / 80) - 0.08).clamp(0.0, 1.0),
                      alignment: Alignment.bottomCenter,
                      tilt: 0,
                    ),
                  if (widget.downBadge != null)
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: ((_dy / 80) - 0.08).clamp(0.0, 1.0),
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
          onPanStart: _canPan ? _onPanStart : null,
          onPanUpdate: _canPan
              ? (d) => _onPanUpdate(d, height)
              : null,
          onPanEnd: _canPan
              ? (d) => _onPanEnd(d, width, height)
              : null,
          child: Stack(
            children: [
              if (widget.underlay != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        reduce ? 10 : 10 * (1 - underlayP),
                      ),
                      child: Transform.scale(
                        scale: reduce ? 0.95 : 0.95 + 0.05 * underlayP,
                        child: widget.underlay,
                      ),
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
