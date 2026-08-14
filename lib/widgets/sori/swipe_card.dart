import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// 스와이프 판정 스탬프 (틴더식 코너 배지) 정의.
///
/// [asset] 이 주어지면 그 이미지를 쓰고, 없거나 로드 실패면 [icon] 으로
/// 폴백한다 (§R-3 도장 에셋이 드롭되기 전에도 배포 가능).
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

/// 스와이프 방향.
enum SoriSwipeDirection { left, right, up, down }

/// **SoriSwipeCard** — 데이팅앱식 4방향 스와이프 덱 래퍼 (Sori Deck 2.0).
///
/// 학습 카드에 겹쳐 **탭과 공존**한다: 자식(SoriPressable 등)의 탭/플립은
/// 그대로 두고 드래그만 가로챈다.
///
/// 방향의 의미는 4화면 공통으로 고정돼 있다:
/// - **좌 = 모름 · 우 = 앎** — 판정이다. [enabled] 게이트를 받고, 커밋되면
///   카드가 그 방향으로 날아간다.
/// - **위 = 저장** — 판정이 아니라 북마크다. 게이트와 무관하고, 커밋 후
///   카드는 **퇴장하지 않고 제자리로 돌아온다** (저장은 전진이 아니다).
/// - **아래 = 스킵** — 기록 없는 넘김. 게이트와 무관하고 아래로 퇴장한다.
///
/// **지배축 잠금**: 드래그가 12px 을 넘는 순간 큰 쪽 축으로 잠기고 그 뒤로는
/// 반대축 델타를 무시한다 — 대각 드래그가 두 방향을 동시에 커밋할 수 없다.
///
/// [enabled] 가 false 면 **좌/우 콜백은 절대 불리지 않는다**(플립 게이트 계약).
/// 다만 카드가 1px 도 안 움직이면 스와이프의 존재를 발견할 수 없으므로,
/// 손가락을 15% 만 따라가는 **저항 드래그**를 보여주고 원시 이동량 24px 에서
/// [onBlockedHorizontalDrag] 를 드래그당 1회 호출한다 (힌트 훅).
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

  /// 판정: 모름. [enabled] 게이트 대상.
  final VoidCallback? onSwipeLeft;

  /// 판정: 앎. [enabled] 게이트 대상.
  final VoidCallback? onSwipeRight;

  /// 저장. 게이트 무관, 커밋 후 카드는 제자리로 복귀. null 이면 위 방향 꺼짐.
  final VoidCallback? onSwipeUp;

  /// 스킵. 게이트 무관, 하단 퇴장. null 이면 아래 방향 꺼짐.
  final VoidCallback? onSwipeDown;

  final SoriSwipeBadge? leftBadge;
  final SoriSwipeBadge? rightBadge;
  final SoriSwipeBadge? upBadge;
  final SoriSwipeBadge? downBadge;

  /// "좌/우 판정 허용" — 플립 게이트. 의미를 바꾸지 말 것(센서가 물고 있다).
  final bool enabled;

  /// 플립 전 수평 시도 → 힌트 훅. 드래그당 최대 1회.
  final VoidCallback? onBlockedHorizontalDrag;

  /// 덱 스택 미리보기 (다음 카드의 **앞면만**). null 이면 스택 없음.
  final Widget? underlay;

  @override
  State<SoriSwipeCard> createState() => _SoriSwipeCardState();
}

class _SoriSwipeCardState extends State<SoriSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;

  /// 지배축이 잠기는 이동량.
  static const double _axisLockSlop = 12;

  /// 잠긴 수평 드래그가 손가락을 따라가는 비율 (발견성용 저항).
  static const double _blockedResistance = 0.15;

  /// 힌트 발화 임계 — **원시** 손가락 이동량 기준. 표시 오프셋으로 걸면
  /// 저항(0.15) 탓에 ~160px 을 끌어야 발화해 발견성 목적이 사라진다.
  static const double _blockedHintRawDx = 24;

  /// 수직 커밋 임계의 절대 상한 (카드 높이 25% 와 함께 min).
  static const double _verticalCommitCap = 120;

  // late-lazy 로 두면 컨트롤러를 한 번도 안 쓴 채 dispose 될 때(리듀스 모션
  // 경로) unmount 중 TickerMode 조상 조회로 크래시한다 — initState 에서 생성.
  late final AnimationController _ctrl;
  double _dx = 0;
  double _dy = 0;
  bool _committing = false;

  Axis? _axis;
  double _rawDx = 0;
  double _rawDy = 0;
  bool _blockedHintSent = false;

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

  /// 좌/우 판정이 열려 있는가 (플립 게이트 + 콜백 존재).
  bool get _canJudge =>
      widget.enabled &&
      (widget.onSwipeLeft != null || widget.onSwipeRight != null);

  /// 수평 드래그를 **추적이라도** 하는가 — 게이트가 닫혀 있어도 저항 드래그로
  /// 스와이프의 존재를 알린다.
  bool get _tracksHorizontal =>
      widget.onSwipeLeft != null || widget.onSwipeRight != null;

  bool get _tracksVertical =>
      widget.onSwipeUp != null || widget.onSwipeDown != null;

  bool get _tracksAny => _tracksHorizontal || _tracksVertical;

  void _onPanStart(DragStartDetails details) {
    _axis = null;
    _rawDx = 0;
    _rawDy = 0;
    _blockedHintSent = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_committing || !_tracksAny) {
      return;
    }
    _rawDx += details.delta.dx;
    _rawDy += details.delta.dy;

    // 지배축 잠금 — 확정 후 반대축은 완전히 무시한다.
    if (_axis == null) {
      final double ax = _rawDx.abs();
      final double ay = _rawDy.abs();
      if (math.max(ax, ay) < _axisLockSlop) {
        return;
      }
      _axis = ax >= ay ? Axis.horizontal : Axis.vertical;
    }

    if (_axis == Axis.horizontal) {
      if (!_tracksHorizontal) {
        return;
      }
      if (_canJudge) {
        setState(() => _dx += details.delta.dx);
        return;
      }
      // 게이트가 닫힌 상태: 저항 드래그 + 1회 힌트.
      setState(() => _dx += details.delta.dx * _blockedResistance);
      if (!_blockedHintSent && _rawDx.abs() > _blockedHintRawDx) {
        _blockedHintSent = true;
        widget.onBlockedHorizontalDrag?.call();
      }
      return;
    }

    if (!_tracksVertical) {
      return;
    }
    final bool up = details.delta.dy < 0;
    if (up && widget.onSwipeUp == null) {
      return;
    }
    if (!up && widget.onSwipeDown == null) {
      return;
    }
    setState(() => _dy += details.delta.dy);
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    final Axis? axis = _axis;
    _axis = null;
    if (_committing || axis == null) {
      _springBack();
      return;
    }
    final Offset v = details.velocity.pixelsPerSecond;

    if (axis == Axis.horizontal) {
      if (!_canJudge) {
        _springBack();
        return;
      }
      final bool right =
          _dx > size.width * _commitFraction || v.dx > _commitVelocity;
      final bool left =
          _dx < -size.width * _commitFraction || v.dx < -_commitVelocity;
      if (right && widget.onSwipeRight != null) {
        _commitExit(
          to: Offset(size.width * 1.3, 0),
          callback: widget.onSwipeRight!,
        );
      } else if (left && widget.onSwipeLeft != null) {
        _commitExit(
          to: Offset(-size.width * 1.3, 0),
          callback: widget.onSwipeLeft!,
        );
      } else {
        _springBack();
      }
      return;
    }

    final double threshold = math.min(_verticalCommitCap, size.height * 0.25);
    final bool down = _dy > threshold || v.dy > _commitVelocity;
    final bool up = _dy < -threshold || v.dy < -_commitVelocity;
    if (down && widget.onSwipeDown != null) {
      _commitExit(
        to: Offset(0, size.height * 1.1),
        callback: widget.onSwipeDown!,
      );
    } else if (up && widget.onSwipeUp != null) {
      // 저장은 전진이 아니다 — 콜백 후 제자리 스프링백 (퇴장 없음).
      HapticFeedback.selectionClick();
      widget.onSwipeUp!.call();
      _springBack();
    } else {
      _springBack();
    }
  }

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
    _animate(
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

  void _springBack() {
    if (_dx == 0 && _dy == 0) {
      return;
    }
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

  /// 덱 스택 진행도 — **커밋 거리로 정규화**해서 카드가 퇴장하는 순간 1이
  /// 되게 한다. |dx|/폭 으로 나누면 커밋 시점에 0.35 라 다음 카드가 65%
  /// 덜 올라온 채 점프한다.
  ///
  /// 위(-dy) 드래그는 제외한다 — 저장은 전진이 아니므로 다음 카드가
  /// 올라오면 거짓 어포던스가 된다.
  double _underlayProgress(Size size) {
    if (_committing) {
      return 1;
    }
    final double h = _dx.abs() / math.max(1, size.width * _commitFraction);
    final double vThreshold = math.min(_verticalCommitCap, size.height * 0.25);
    final double v = _dy > 0 ? _dy / math.max(1, vThreshold) : 0;
    return math.max(h, v).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height,
        );
        final double hProgress = (_dx / size.width).clamp(-1.0, 1.0);
        final double vThreshold = math.min(
          _verticalCommitCap,
          size.height * 0.25,
        );
        final double vProgress = (_dy / vThreshold).clamp(-1.0, 1.0);

        // 틴더식 기울임은 수평축에서만 (최대 ~9°). 수직은 틸트 없이 순수
        // 이동 + 미세 축소.
        final double angle = hProgress * 0.16;
        final double scale = 1 - vProgress.abs() * 0.03;

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
                      opacity: _ramp(hProgress),
                      alignment: Alignment.topLeft,
                      tilt: -0.15,
                    ),
                  if (widget.leftBadge != null)
                    _Stamp(
                      badge: widget.leftBadge!,
                      opacity: _ramp(-hProgress),
                      alignment: Alignment.topRight,
                      tilt: 0.15,
                    ),
                  if (widget.upBadge != null)
                    _Stamp(
                      badge: widget.upBadge!,
                      opacity: _ramp(-vProgress),
                      alignment: Alignment.bottomCenter,
                      tilt: 0,
                    ),
                  if (widget.downBadge != null)
                    _Stamp(
                      badge: widget.downBadge!,
                      opacity: _ramp(vProgress),
                      alignment: Alignment.topCenter,
                      tilt: 0,
                    ),
                ],
              ),
            ),
          ),
        );

        final Widget? underlay = widget.underlay;
        final Widget stacked = underlay == null
            ? card
            : Stack(
                children: [
                  _DeckUnderlay(
                    progress: SoriMotion.reduceMotion(context)
                        ? 0
                        : _underlayProgress(size),
                    child: underlay,
                  ),
                  card,
                ],
              );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _tracksAny ? _onPanStart : null,
          onPanUpdate: _tracksAny ? _onPanUpdate : null,
          onPanEnd: _tracksAny ? (d) => _onPanEnd(d, size) : null,
          child: stacked,
        );
      },
    );
  }

  /// 배지 램프 — 진행 8% 에서 뜨기 시작해 33% 에서 완전 불투명.
  static double _ramp(double progress) =>
      ((progress - 0.08) / 0.25).clamp(0.0, 1.0);
}

/// 덱 스택 — 다음 카드가 현재 카드 뒤에서 살짝 작게·아래로 어긋나 있다가
/// 스와이프 진행에 따라 제자리로 올라온다. 절대 히트테스트되지 않는다.
class _DeckUnderlay extends StatelessWidget {
  const _DeckUnderlay({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = progress.clamp(0.0, 1.0);
    return Positioned.fill(
      child: IgnorePointer(
        // 다음 카드는 **장식**이다 — 스크린리더가 현재 카드와 섞어 읽으면
        // 안 되므로 시맨틱스에서 통째로 제외한다.
        child: ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
          ),
        ),
      ),
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
    final String? asset = badge.asset;
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
