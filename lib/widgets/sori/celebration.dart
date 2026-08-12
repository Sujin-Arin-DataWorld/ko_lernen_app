import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriCelebration** — 한 순간의 축하 연출. 단청 색 별·다이아·반짝임이 터진다.
///
/// 듀오링고식 "정답!" 보상감 — 정적 화면이 아니라 살아있는 앱의 한 호흡.
/// 에셋 불필요 (CustomPainter 입자). 어디서든 한 줄로 호출:
/// ```dart
/// SoriCelebration.burst(context);                       // 화면 상단 1/3에서
/// SoriCelebration.burst(context, origin: tapPosition);  // 특정 지점에서
/// ```
class SoriCelebration {
  SoriCelebration._();

  /// 일회성 축하 입자 burst를 [Overlay]에 띄운다. 1.5초 후 스스로 사라진다.
  /// `MediaQuery.disableAnimations`(prefers-reduced-motion)가 켜져 있으면 no-op.
  static void burst(
    BuildContext context, {
    Offset? origin,
    int particles = 30,
  }) {
    if (SoriMotion.reduceMotion(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final media = MediaQuery.maybeOf(context);
    final from =
        origin ??
        Offset(
          (media?.size.width ?? 360) / 2,
          (media?.size.height ?? 720) * 0.36,
        );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationLayer(
        origin: from,
        count: particles,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  /// 정답 순간용 — 엽전·복 코인이 팡팡 튀어 나온다. [origin] 미지정 시 화면
  /// 우상단(까치 컴패니언 자리) 근처. reduce-motion 시 no-op.
  static void coins(BuildContext context, {Offset? origin, int count = 20}) {
    if (SoriMotion.reduceMotion(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final media = MediaQuery.maybeOf(context);
    // origin 미지정 시 화면 중앙(살짝 위)에서 크게 터진다 — 정답 페이오프.
    final from =
        origin ??
        Offset(
          (media?.size.width ?? 360) / 2,
          (media?.size.height ?? 720) * 0.42,
        );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoinBurstLayer(
        origin: from,
        count: count,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _CelebrationLayer extends StatefulWidget {
  final Offset origin;
  final int count;
  final VoidCallback onDone;

  const _CelebrationLayer({
    required this.origin,
    required this.count,
    required this.onDone,
  });

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  static const _palette = [
    SoriColors.tiger, // 호랑이 주황
    SoriColors.gold, // 황
    SoriColors.accent, // 석간주 적
    SoriColors.primary, // 녹청
  ];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(widget.count, (_) {
      // 위쪽 반구 위주로 분사 (−170°~−10°).
      final angle = -math.pi + rnd.nextDouble() * math.pi * 0.92 - 0.08;
      return _Particle(
        angle: angle,
        speed: 160 + rnd.nextDouble() * 300,
        color: _palette[rnd.nextInt(_palette.length)],
        shape: rnd.nextInt(3),
        size: 7 + rnd.nextDouble() * 9,
        spin: (rnd.nextDouble() - 0.5) * 14,
        delay: rnd.nextDouble() * 0.12,
      );
    });
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                origin: widget.origin,
                t: _ctrl.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle; // 발사 방향 (rad)
  final double speed; // 초기 속도 (px/s 상당)
  final Color color;
  final int shape; // 0 별 · 1 다이아 · 2 점
  final double size;
  final double spin; // 회전 속도
  final double delay; // 0~0.12 — 약간 어긋나게 터짐

  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.shape,
    required this.size,
    required this.spin,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset origin;
  final double t; // 0..1

  _ConfettiPainter({
    required this.particles,
    required this.origin,
    required this.t,
  });

  static const double _gravity = 720;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final lt = ((t - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;

      // 바깥으로 뻗다 감속 + 중력 낙하.
      final reach = (1 - math.pow(1 - lt, 2).toDouble()); // easeOut
      final dx = math.cos(p.angle) * p.speed * reach;
      final dy = math.sin(p.angle) * p.speed * reach + _gravity * lt * lt * 0.5;
      final pos = origin + Offset(dx, dy);

      // 끝 35%에서 페이드 + 살짝 축소.
      final fade = lt < 0.65 ? 1.0 : (1 - (lt - 0.65) / 0.35);
      final scale = 0.4 + reach * 0.6 - (lt > 0.7 ? (lt - 0.7) * 0.7 : 0);
      if (fade <= 0 || scale <= 0) continue;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * lt);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      final r = p.size * scale;
      switch (p.shape) {
        case 0:
          _star(canvas, r, paint);
        case 1:
          _diamond(canvas, r, paint);
        default:
          canvas.drawCircle(Offset.zero, r * 0.62, paint);
      }
      canvas.restore();
    }
  }

  void _star(Canvas canvas, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _diamond(Canvas canvas, double r, Paint paint) {
    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.72, 0)
      ..lineTo(0, r)
      ..lineTo(-r * 0.72, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────
// 코인 burst — 엽전·복 PNG 입자 (정답 피드백). 별/다이아와 달리 실제 이미지라
// CustomPainter 대신 위젯(Image.asset) 기반 입자로 렌더한다.
// ─────────────────────────────────────────────────────────────────────────

class _CoinBurstLayer extends StatefulWidget {
  final Offset origin;
  final int count;
  final VoidCallback onDone;

  const _CoinBurstLayer({
    required this.origin,
    required this.count,
    required this.onDone,
  });

  @override
  State<_CoinBurstLayer> createState() => _CoinBurstLayerState();
}

class _CoinBurstLayerState extends State<_CoinBurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Coin> _coins;

  static const _assets = [
    'assets/illustrations/mascot/yupjeon.png',
    'assets/illustrations/mascot/bok.png',
  ];

  static const double _gravity = 680;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _coins = List.generate(widget.count, (i) {
      // 위쪽 반구 위주로 분사 (−170°~−10°).
      final angle = -math.pi + rnd.nextDouble() * math.pi * 0.92 - 0.08;
      return _Coin(
        angle: angle,
        speed: 180 + rnd.nextDouble() * 320,
        asset: _assets[i % _assets.length],
        size: 36 + rnd.nextDouble() * 26,
        spin: (rnd.nextDouble() - 0.5) * 10,
        delay: rnd.nextDouble() * 0.14,
      );
    });
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1300),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              clipBehavior: Clip.none,
              children: [for (final c in _coins) _coin(c, _ctrl.value)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coin(_Coin c, double t) {
    final lt = ((t - c.delay) / (1.0 - c.delay)).clamp(0.0, 1.0);
    if (lt <= 0) return const SizedBox.shrink();
    // 바깥으로 뻗다 감속 + 중력 낙하 (별/다이아 입자와 동일 물리).
    final reach = 1 - math.pow(1 - lt, 2).toDouble(); // easeOut
    final dx = math.cos(c.angle) * c.speed * reach;
    final dy = math.sin(c.angle) * c.speed * reach + _gravity * lt * lt * 0.5;
    final fade = lt < 0.6 ? 1.0 : (1 - (lt - 0.6) / 0.4);
    final scale = (0.5 + reach * 0.5 - (lt > 0.7 ? (lt - 0.7) * 0.6 : 0)).clamp(
      0.0,
      1.2,
    );
    if (fade <= 0 || scale <= 0) return const SizedBox.shrink();
    return Positioned(
      left: widget.origin.dx + dx - c.size / 2,
      top: widget.origin.dy + dy - c.size / 2,
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: c.spin * lt,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              c.asset,
              width: c.size,
              height: c.size,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Icon(
                Icons.brightness_1,
                size: c.size,
                color: SoriColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Coin {
  final double angle;
  final double speed;
  final String asset;
  final double size;
  final double spin;
  final double delay;

  const _Coin({
    required this.angle,
    required this.speed,
    required this.asset,
    required this.size,
    required this.spin,
    required this.delay,
  });
}
