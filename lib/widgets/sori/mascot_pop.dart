import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/sound_service.dart';
import 'dancheong_burst.dart';
import 'mascot.dart';
import 'tokens.dart';

/// **MascotPartner** — 퀘스트 옆에 상주하는 마스코트. 정답 순간 "파바박" 터진다.
///
/// 예전 `MascotPop`은 정답마다 나타났다 사라져서, 시나리오 한 판에 4~6번
/// 반복 등장 → "또 나온다"로 체감됐다. 이제는 **사라지지 않고 자세만 바뀐다**:
/// 대기 중엔 조용히 앉아 있고(perched), 정답이면 celebrate + 날갯짓 + 버스트.
///
/// ```dart
/// Stack(children: [
///   /* quest UI */,
///   Positioned(top: -12, right: 12, child: MascotPartner(celebrating: _correct)),
/// ])
/// ```
///
/// 연출은 단일 컨트롤러 위에 스태거로 겹친 스타카토다:
/// - 스쿼시&스트레치 스냅 (0.85→1.28→0.94→1.0)
/// - 링 충격파 3개 (0 / 70 / 140ms)
/// - [DancheongBurst] 1회 — 복주머니·엽전 시트가 시차를 두고 "파-박"
/// - 햅틱 2연타 (0 / 70ms) — 시트 두 장의 타이밍과 맞춘다
///
/// `MediaQuery.disableAnimations`가 켜져 있으면 포즈 전환만 하고
/// 버스트·햅틱 연타·스케일 시퀀스는 생략한다.
class MascotPartner extends StatefulWidget {
  /// 정답 상태. false→true 전환 순간 축하 연출이 발화한다.
  final bool celebrating;
  final MascotKind kind;
  final double size;

  /// 축하 연출과 함께 정답 효과음을 재생할지. 호출부가 이미
  /// `SoundService.correct()`를 부르고 있으면 false로 꺼서 중복을 막는다.
  final bool playSound;

  const MascotPartner({
    super.key,
    required this.celebrating,
    this.kind = MascotKind.magpie,
    this.size = 56,
    this.playSound = true,
  });

  @override
  State<MascotPartner> createState() => _MascotPartnerState();
}

class _MascotPartnerState extends State<MascotPartner>
    with SingleTickerProviderStateMixin {
  /// 링 확산 320ms + 마지막 발사 170ms → 넉넉히 620ms.
  static const _burstDuration = Duration(milliseconds: 620);

  /// celebrate 포즈를 유지하는 시간. 이후 대기 포즈로 되돌아간다.
  static const _poseHold = Duration(milliseconds: 1100);

  /// 스쿼시&스트레치 — elasticOut의 흐물한 진동 대신 딱 끊어지는 스냅.
  /// 260ms 안에 끝나므로 620ms 기준 앞 42%만 쓴다.
  static final TweenSequence<double> _snap = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.28), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.94), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 45),
  ]);
  static const _snapSpan = 0.42;

  late final AnimationController _ctrl;
  final List<Timer> _timers = [];

  /// 포즈: false = 대기, true = celebrate + 날갯짓.
  bool _celebratePose = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _burstDuration);
    if (widget.celebrating) {
      _celebratePose = true;
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant MascotPartner old) {
    super.didUpdateWidget(old);
    if (widget.celebrating && !old.celebrating) {
      _fire();
    } else if (!widget.celebrating && old.celebrating) {
      _cancelTimers();
      _ctrl.value = 0;
      if (_celebratePose) {
        setState(() => _celebratePose = false);
      }
    }
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _schedule(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (mounted) {
          action();
        }
      }),
    );
  }

  /// 화면 좌표계 기준 마스코트 중심. 버스트 원점으로 쓴다.
  Offset? _center() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _fire() {
    _cancelTimers();
    final reduced = SoriMotion.reduceMotion(context);

    if (widget.playSound) {
      SoundService.correct();
    }

    // 포즈 전환은 reduce-motion에서도 유지 — 정답 신호 자체는 남아야 한다.
    _schedule(reduced ? 0 : 90, () => setState(() => _celebratePose = true));
    _schedule(_poseHold.inMilliseconds, () {
      setState(() => _celebratePose = false);
    });

    if (reduced) {
      HapticFeedback.lightImpact();
      return;
    }

    _ctrl.forward(from: 0);

    // 버스트는 한 번만 쏜다. "파-박" 두 박자는 이제 시트 두 장(복주머니 → 엽전)의
    // 발사 시차가 만들므로, 여기서 여러 번 쏘면 통짜 시트가 겹쳐 뭉개진다.
    final origin = _center();
    if (origin != null) {
      DancheongBurst.fire(context, origin: origin);
    }

    // 햅틱은 시트 두 장의 타이밍에 맞춰 두 번 — 파박을 촉각으로 완성한다.
    HapticFeedback.lightImpact();
    _schedule(70, HapticFeedback.lightImpact);
  }

  @override
  void dispose() {
    _cancelTimers();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = SoriMotion.reduceMotion(context);
    if (reduced) {
      return _avatar();
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final scale = t <= 0 || t >= _snapSpan
            ? 1.0
            : _snap.transform((t / _snapSpan).clamp(0.0, 1.0));
        return _BurstFrame(
          t: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _avatar(),
    );
  }

  Widget _avatar() {
    // 대기 중엔 링을 낮춰 조용히, 정답이면 success 풀컬러로 점등.
    final ringAlpha = _celebratePose ? 1.0 : 0.35;
    final fillAlpha = _celebratePose ? 0.15 : 0.06;
    return AnimatedContainer(
      duration: SoriMotion.fast,
      decoration: BoxDecoration(
        color: SoriColors.success.withValues(alpha: fillAlpha),
        shape: BoxShape.circle,
        border: Border.all(
          color: SoriColors.success.withValues(alpha: ringAlpha),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Mascot(
        kind: widget.kind,
        emotion: _celebratePose
            ? MascotEmotion.celebrate
            : MascotEmotion.neutral,
        size: widget.size,
        animate: _celebratePose,
      ),
    );
  }
}

/// 링 충격파 3개를 마스코트 뒤에 깔아 준다.
/// 기존 원형 링 모티프를 바깥으로 확장하는 구조.
class _BurstFrame extends StatelessWidget {
  final double t; // 0..1
  final Widget child;

  const _BurstFrame({required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    if (t == 0) {
      return child;
    }
    return CustomPaint(
      painter: _ShockwavePainter(t: t),
      child: child,
    );
  }
}

class _ShockwavePainter extends CustomPainter {
  final double t;

  _ShockwavePainter({required this.t});

  /// (지연 비율, 색) — 0 / 70 / 140ms를 620ms로 나눈 값.
  static const _rings = <(double, Color)>[
    (0.0, SoriColors.primary),
    (0.113, SoriColors.gold),
    (0.226, SoriColors.tiger),
  ];

  /// 링 하나의 확산 시간 320ms / 620ms.
  static const _span = 0.516;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    for (final (delay, color) in _rings) {
      final lt = ((t - delay) / _span).clamp(0.0, 1.0);
      if (lt <= 0 || lt >= 1) {
        continue;
      }
      final eased = Curves.easeOutCubic.transform(lt);
      canvas.drawCircle(
        center,
        base * (0.5 + eased * 1.1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - eased)
          ..color = color.withValues(alpha: 0.55 * (1 - eased)),
      );
    }
  }

  @override
  bool shouldRepaint(_ShockwavePainter old) => old.t != t;
}
