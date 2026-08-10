import 'package:flutter/material.dart';

import 'tokens.dart';

/// **Sori Motion** — 정적인 화면에 생동감을 부여하는 재사용 애니메이션 래퍼.
///
/// - [SoriEntrance] — 화면 진입 시 child가 fade + slide-up + 살짝 scale로 등장.
///   카드·일러스트 배너에 감싸고 `delay`로 stagger.
///
/// 모두 컨트롤러 1개 + 가벼운 Transform — 60fps 부담 없음.

/// 화면 진입 등장 애니메이션. 처음 빌드 시 1회 재생, 이후 정지.
class SoriEntrance extends StatefulWidget {
  final Widget child;

  /// 등장 시작 전 대기 — 여러 [SoriEntrance]에 다른 값을 주면 stagger.
  final Duration delay;
  final Duration duration;

  /// 시작 시 아래로 얼마나 내려가 있다가 올라올지 (logical px).
  final double slideY;

  /// 시작 scale (1.0 미만이면 살짝 커지며 등장).
  final double startScale;

  const SoriEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 540),
    this.slideY = 18,
    this.startScale = 0.97,
  });

  @override
  State<SoriEntrance> createState() => _SoriEntranceState();
}

class _SoriEntranceState extends State<SoriEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SoriMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.slideY),
            child: Transform.scale(
              scale: widget.startScale + (1 - widget.startScale) * t,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// **Sori 모션 상수** — 일관된 애니메이션 타이밍 & 곡선.
///
/// 모든 위젯이 같은 Duration/Curve를 사용하면 일관된 느낌의 인터페이스.
/// 예: `ScaleTransition(scale: anim, ...)` 대신
///     `ScaleTransition(scale: Tween(...).animate(CurvedAnimation(parent: ctrl, curve: SoriAnimation.tapOut)))`
abstract final class SoriAnimation {
  // ─── Durations ───
  static const Duration tap = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration verySlow = Duration(milliseconds: 1200);

  // ─── Curves ───
  static const Curve tapOut = Curves.easeOut;
  static const Curve release = Curves.elasticOut;
  static const Curve gentle = Curves.easeOutCubic;

  // ─── Entrance (화면 진입) ───
  static const Duration entranceDuration = Duration(milliseconds: 540);
  static const Curve entranceCurve = gentle;

  // ─── Preset combos ───
  /// press feedback: 즉시 반응, 탄력적 복귀
  static const Duration pressDuration = quick;
  static const Curve pressCurve = release;

  /// list/card 진입: 부드러운 fade + slide
  static const Duration cardDuration = normal;
  static const Curve cardCurve = gentle;

  /// idle 호흡: 느슨하고 자연스러운 반복
  static const Duration idleDuration = verySlow;
  static const Curve idleCurve = Curves.easeInOut;
}
