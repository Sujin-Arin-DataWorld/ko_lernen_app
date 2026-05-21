import 'dart:math' as math;
import 'package:flutter/material.dart';

/// **AmbientParticles** — 화면에 은은하게 떠다니는 입자 레이어.
///
/// - 라이트 모드: 매화(梅花) 꽃잎이 천천히 흩날려 내려온다.
/// - 다크 모드: 따뜻한 불씨/별 입자가 밤 마당 위로 천천히 떠오른다.
///
/// Faceted Minhwa 무드의 차분한 생동감. 컨트롤러 1개 + CustomPainter로 60fps.
/// `IgnorePointer`로 감싸 탭을 가로채지 않으며, `Stack`의 `Positioned.fill`로 쓴다.
///
/// ```dart
/// Stack(children: [
///   background,
///   const Positioned.fill(child: IgnorePointer(child: AmbientParticles())),
///   content,
/// ])
/// ```
///
/// 무한 루프는 입자별 사이클 수를 **정수**로 고정해 컨트롤러 wrap 시점에도
/// 위치·회전이 끊기지 않는다.
class AmbientParticles extends StatefulWidget {
  /// 입자 개수. 화면이 크면 살짝 늘려도 좋다 (기본 14, sparse).
  final int count;

  /// null이면 `Theme.of(context).brightness` 자동 감지.
  final Brightness? brightness;

  const AmbientParticles({super.key, this.count = 14, this.brightness});

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _Particle {
  final double offset; // 0..1 시작 위상
  final int cycles; // 컨트롤러 1주기당 정수 낙하 사이클 (seamless)
  final double xBase; // 0..1 가로 기준 위치
  final double swayAmp; // 가로 흔들림 진폭 (width 비율)
  final int swayCycles; // 정수 — seamless
  final double swayPhase; // 0..1
  final int rotCycles; // 정수 회전 사이클 — seamless
  final double rotDir; // +1 / -1
  final double size; // px
  final double opacity; // 기본 불투명도
  final int colorIdx;

  const _Particle({
    required this.offset,
    required this.cycles,
    required this.xBase,
    required this.swayAmp,
    required this.swayCycles,
    required this.swayPhase,
    required this.rotCycles,
    required this.rotDir,
    required this.size,
    required this.opacity,
    required this.colorIdx,
  });
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    final rnd = math.Random();
    _particles = List.generate(widget.count, (_) {
      return _Particle(
        offset: rnd.nextDouble(),
        cycles: 3 + rnd.nextInt(5), // 3..7 — 17~40초에 한 번 통과
        xBase: 0.04 + rnd.nextDouble() * 0.92,
        swayAmp: 0.02 + rnd.nextDouble() * 0.06,
        swayCycles: 2 + rnd.nextInt(5), // 2..6
        swayPhase: rnd.nextDouble(),
        rotCycles: 1 + rnd.nextInt(3), // 1..3
        rotDir: rnd.nextBool() ? 1 : -1,
        size: 6 + rnd.nextDouble() * 9, // 6..15
        opacity: 0.45 + rnd.nextDouble() * 0.4,
        colorIdx: rnd.nextInt(3),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness ?? Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _AmbientPainter(
            particles: _particles,
            t: _c.value,
            isDark: isDark,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1
  final bool isDark;

  _AmbientPainter({
    required this.particles,
    required this.t,
    required this.isDark,
  });

  // 라이트: 매화 꽃잎 톤 / 다크: 따뜻한 불씨·별 톤
  static const _petalColors = [
    Color(0xFFE8B5BC), // plum pink
    Color(0xFFD8B5B5), // dusty pink
    Color(0xFFF0C8CC), // pale blossom
  ];
  static const _moteColors = [
    Color(0xFFDFA951), // dancheong gold
    Color(0xFFF4E8D0), // hanji cream
    Color(0xFFE0C088), // warm sand
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // seamless: cycles 정수 → wrap 시 progress 동일
      final progress = (p.offset + t * p.cycles) % 1.0;
      // 라이트: 위→아래로 낙하 / 다크: 아래→위로 부유
      final yFrac = isDark ? (1.0 - progress) : progress;

      final sway = math.sin((t * p.swayCycles + p.swayPhase) * 2 * math.pi);
      final x = (p.xBase + sway * p.swayAmp) * size.width;
      final y = yFrac * size.height;

      // 등장/퇴장 가장자리 페이드
      final edge = (progress < 0.12)
          ? progress / 0.12
          : (progress > 0.88 ? (1.0 - progress) / 0.12 : 1.0);

      if (isDark) {
        // 불씨 — twinkle(반짝임) 더해 살아있는 밤
        final twinkle =
            0.6 + 0.4 * math.sin((t * 6 + p.swayPhase) * 2 * math.pi);
        final op = (p.opacity * edge * twinkle).clamp(0.0, 1.0);
        final c = _moteColors[p.colorIdx];
        // 부드러운 글로우 + 코어
        paint.color = c.withValues(alpha: op * 0.28);
        canvas.drawCircle(Offset(x, y), p.size * 0.55, paint);
        paint.color = c.withValues(alpha: op);
        canvas.drawCircle(Offset(x, y), p.size * 0.22, paint);
      } else {
        // 매화 꽃잎 — 회전하며 낙하
        final rot =
            p.rotDir * (t * p.rotCycles) * 2 * math.pi + p.swayPhase * 6.28;
        final op = (p.opacity * edge).clamp(0.0, 1.0);
        paint.color = _petalColors[p.colorIdx].withValues(alpha: op);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rot);
        _drawPetal(canvas, paint, p.size);
        canvas.restore();
      }
    }
  }

  /// 작은 매화 꽃잎 — 대칭 렌즈(아몬드) 모양.
  void _drawPetal(Canvas canvas, Paint paint, double s) {
    final h = s;
    final w = s * 0.62;
    final path = Path()
      ..moveTo(0, -h / 2)
      ..quadraticBezierTo(w, 0, 0, h / 2)
      ..quadraticBezierTo(-w, 0, 0, -h / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.t != t || old.isDark != isDark;
}
