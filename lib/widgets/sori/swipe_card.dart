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

/// **SoriSwipeCard** — 데이팅앱식 좌/우 스와이프 판정·넘김 래퍼 (2026-08-14).
///
/// 학습 카드에 겹쳐 **탭과 공존**한다: 자식(SoriPressable 등)의 탭/플립은
/// 그대로 두고, 수평 드래그만 가로챈다. 임계(폭 35% 또는 700px/s 플링)를
/// 넘기면 카드가 그 방향으로 날아가며 콜백이 1회 불린다 — 판정 후 부모가
/// 다음 카드를 서빙하면 위치는 소리 없이 중앙으로 복귀한다(카드 내용 교체는
/// 부모의 서빙 키 재생성 계약을 따른다).
///
/// 두 가지 용법:
/// - **판정 덱** (복습 세션): [rightBadge]=Gewusst(성공색)·[leftBadge]=
///   Nicht gewusst(위험색) 스탬프가 드래그 진행에 비례해 떠오른다.
///   버튼 행은 제거하지 않는다 — 스위치 접근·발견가능성의 정본은 버튼이고
///   스와이프는 가속 경로다.
/// - **넘김 덱** (단어장 브라우즈): 배지 없이 왼쪽=다음/오른쪽=이전.
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
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final SoriSwipeBadge? leftBadge;
  final SoriSwipeBadge? rightBadge;
  final SoriSwipeBadge? upBadge;
  final SoriSwipeBadge? downBadge;

  /// 좌/우 판정 허용 여부. 위 저장과 아래 스킵은 판정이 아니므로 영향받지 않는다.
  final bool enabled;
  final VoidCallback? onBlockedHorizontalDrag;

  /// 다음 카드의 앞면 미리보기. 포인터 이벤트를 받지 않는다.
  final Widget? underlay;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

enum _DragAxis { horizontal, vertical }

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;
  static const double _axisLockDistance = 12;
  static const double _blockedHintDistance = 24;

  // late-lazy 로 두면 컨트롤러를 한 번도 안 쓴 채 dispose 될 때(리듀스 모션
  // 경로) unmount 중 TickerMode 조상 조회로 크래시한다 — initState 에서 생성.
  late final AnimationController _ctrl;
  double _dx = 0;
  double _dy = 0;
  double _rawDx = 0;
  double _rawDy = 0;
  _DragAxis? _axis;
  bool _blockedHintSent = false;
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

  bool get _hasHorizontal =>
      widget.onSwipeLeft != null || widget.onSwipeRight != null;
  bool get _hasVertical =>
      widget.onSwipeUp != null || widget.onSwipeDown != null;
  bool get _canPan => _hasHorizontal || _hasVertical;

  void _onPanStart(DragStartDetails details) {
    if (_committing) {
      return;
    }
    _ctrl.stop();
    _rawDx = 0;
    _rawDy = 0;
    _axis = null;
    _blockedHintSent = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_committing) {
      return;
    }
    _rawDx += details.delta.dx;
    _rawDy += details.delta.dy;
    if (_axis == null &&
        math.max(_rawDx.abs(), _rawDy.abs()) >= _axisLockDistance) {
      _axis = _rawDx.abs() >= _rawDy.abs()
          ? _DragAxis.horizontal
          : _DragAxis.vertical;
    }
    switch (_axis) {
      case _DragAxis.horizontal:
        if (!_hasHorizontal) {
          return;
        }
        setState(() {
          _dx += details.delta.dx * (widget.enabled ? 1 : 0.15);
        });
        if (!widget.enabled &&
            !_blockedHintSent &&
            _rawDx.abs() > _blockedHintDistance) {
          _blockedHintSent = true;
          widget.onBlockedHorizontalDrag?.call();
        }
      case _DragAxis.vertical:
        if (!_hasVertical) {
          return;
        }
        setState(() => _dy += details.delta.dy);
      case null:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details, double width, double height) {
    if (_committing) {
      return;
    }
    final velocity = details.velocity.pixelsPerSecond;
    if (_axis == _DragAxis.horizontal && _hasHorizontal) {
      final right =
          widget.enabled &&
          (_dx > width * _commitFraction || velocity.dx > _commitVelocity);
      final left =
          widget.enabled &&
          (_dx < -width * _commitFraction || velocity.dx < -_commitVelocity);
      if (right && widget.onSwipeRight != null) {
        _commitExit(
          offset: Offset(width * 1.3, 0),
          callback: widget.onSwipeRight!,
        );
      } else if (left && widget.onSwipeLeft != null) {
        _commitExit(
          offset: Offset(-width * 1.3, 0),
          callback: widget.onSwipeLeft!,
        );
      } else {
        _springBack();
      }
    } else if (_axis == _DragAxis.vertical && _hasVertical) {
      final threshold = math.min(120.0, height * 0.25);
      final up = _dy < -threshold || velocity.dy < -_commitVelocity;
      final down = _dy > threshold || velocity.dy > _commitVelocity;
      if (up && widget.onSwipeUp != null) {
        _commitUp(widget.onSwipeUp!);
      } else if (down && widget.onSwipeDown != null) {
        _commitExit(
          offset: Offset(0, height * 1.1),
          callback: widget.onSwipeDown!,
        );
      } else {
        _springBack();
      }
    } else {
      _springBack();
    }
    _axis = null;
    _rawDx = 0;
    _rawDy = 0;
  }

  void _commitExit({required Offset offset, required VoidCallback callback}) {
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
      to: offset,
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

  void _commitUp(VoidCallback callback) {
    // ignore: discarded_futures
    HapticFeedback.selectionClick();
    callback();
    _springBack();
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
      to: Offset.zero,
      duration: SoriMotion.medium,
      curve: SoriMotion.release,
    );
  }

  void _animate({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final double progress = (_dx / width).clamp(-1.0, 1.0);
        final double verticalProgress = (_dy / height).clamp(-1.0, 1.0);
        final double verticalThreshold = math.min(120.0, height * 0.25);
        final double underlayProgress = math
            .max(
              _dx.abs() / (width * _commitFraction),
              _dy > 0 ? _dy / verticalThreshold : 0,
            )
            .clamp(0.0, 1.0);
        // 틴더식 기울임 — 아래 모서리를 축으로 살짝(최대 ~9°).
        final double angle = progress * 0.16;

        final Widget card = Transform.translate(
          offset: Offset(_dx, _dy),
          child: Transform.scale(
            scale: 1 - verticalProgress.abs() * 0.03,
            child: Transform.rotate(
              angle: _axis == _DragAxis.vertical ? 0 : angle,
              alignment: Alignment.bottomCenter,
              child: Stack(
                fit: StackFit.passthrough,
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
                  if (widget.upBadge != null)
                    _Stamp(
                      badge: widget.upBadge!,
                      opacity: ((-verticalProgress - 0.08) / 0.25).clamp(
                        0.0,
                        1.0,
                      ),
                      alignment: Alignment.bottomCenter,
                      tilt: 0,
                    ),
                  if (widget.downBadge != null)
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: ((verticalProgress - 0.08) / 0.25).clamp(
                        0.0,
                        1.0,
                      ),
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
          onPanUpdate: _canPan ? _onPanUpdate : null,
          onPanEnd: _canPan
              ? (details) => _onPanEnd(details, width, height)
              : null,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              if (widget.underlay != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - underlayProgress)),
                      child: Transform.scale(
                        scale: 0.95 + 0.05 * underlayProgress,
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
