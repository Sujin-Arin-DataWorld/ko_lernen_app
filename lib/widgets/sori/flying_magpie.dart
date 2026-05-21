import 'dart:math' as math;
import 'package:flutter/material.dart';

/// **FlyingMagpie** — 갓 쓴 까치가 화면 상단을 주기적으로 가로지르는 비행 위젯.
///
/// 까치(까치호랑이의 그 까치)는 한국 민화에서 *좋은 소식*을 물어오는 새.
/// 한 주기마다 화면 왼쪽에서 날아 들어와 부드러운 아치를 그리며 오른쪽으로
/// 빠져나간다 — 날갯짓 + 비행 각도 뱅킹 포함. Faceted Minhwa 플랫 스타일.
///
/// `IgnorePointer`로 감싸 탭을 막지 않으며 `Stack`의 `Positioned.fill`로 쓴다.
class FlyingMagpie extends StatefulWidget {
  /// 비행 밴드 상단 위치 (0=화면 최상단, 1=최하단).
  final double bandTop;

  /// 아치가 위로 솟는 높이 (화면 높이 비율).
  final double archHeight;

  /// 까치 크기 (px).
  final double size;

  /// 비행+대기 한 주기.
  final Duration cycle;

  const FlyingMagpie({
    super.key,
    this.bandTop = 0.16,
    this.archHeight = 0.07,
    this.size = 56,
    this.cycle = const Duration(seconds: 22),
  });

  @override
  State<FlyingMagpie> createState() => _FlyingMagpieState();
}

class _FlyingMagpieState extends State<FlyingMagpie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.cycle)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _MagpiePainter(
            t: _c.value,
            magpieSize: widget.size,
            bandTop: widget.bandTop,
            archHeight: widget.archHeight,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MagpiePainter extends CustomPainter {
  final double t; // 0..1 주기 진행
  final double magpieSize;
  final double bandTop;
  final double archHeight;

  _MagpiePainter({
    required this.t,
    required this.magpieSize,
    required this.bandTop,
    required this.archHeight,
  });

  /// 비행이 차지하는 주기 비율 (나머지는 화면 밖에서 대기).
  static const double _flightFrac = 0.40;

  /// 주기당 날갯짓 횟수 — 정수라 wrap 시 끊김 없음.
  static const int _flapsPerCycle = 64;

  // Faceted Minhwa 까치 팔레트
  static const Color _dark = Color(0xFF20272F); // 까치 흑 (warm slate)
  static const Color _darkFacet = Color(0xFF323E48); // 그림자 면
  static const Color _white = Color(0xFFF4E8D0); // 한지 크림 = 까치 백
  static const Color _beak = Color(0xFFDFA951); // 단청 금 부리
  static const Color _band = Color(0xFFDFA951); // 갓끈 금

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || t > _flightFrac) return; // 대기 구간엔 안 그림

    final ft = t / _flightFrac; // 0..1 비행 진행
    final margin = magpieSize * 1.6;
    final x = -margin + (size.width + margin * 2) * ft;
    final arc = math.sin(ft * math.pi); // 0→1→0
    final y = bandTop * size.height - arc * archHeight * size.height;

    final flap = math.sin(t * _flapsPerCycle * 2 * math.pi); // -1..1
    final bob = flap * magpieSize * 0.035; // 날갯짓에 맞춘 상하 흔들림
    final bank = -math.cos(ft * math.pi) * 0.17; // 상승/하강 시 기울기

    // 화면 진입/퇴장 페이드
    final fade = (ft < 0.10)
        ? ft / 0.10
        : (ft > 0.90 ? (1.0 - ft) / 0.10 : 1.0);

    canvas.save();
    canvas.translate(x, y + bob);
    canvas.rotate(bank);
    _paintMagpie(canvas, magpieSize, flap, fade.clamp(0.0, 1.0));
    canvas.restore();
  }

  /// 까치를 원점 중심, 오른쪽을 향해 그린다. [flap] -1..1 = 날개 위치.
  void _paintMagpie(Canvas canvas, double s, double flap, double op) {
    final p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 좌표 헬퍼 — 정규화 좌표(원점=몸통 중심)를 px로.
    Offset pt(double nx, double ny) => Offset(nx * s, ny * s);
    Path poly(List<List<double>> pts) {
      final path = Path()..moveTo(pts.first[0] * s, pts.first[1] * s);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i][0] * s, pts[i][1] * s);
      }
      return path..close();
    }

    // ── 1. 꼬리 (길게 뒤로 — 까치의 시그니처) ────────────────────
    p.color = _dark.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [-0.14, -0.05],
        [-0.16, 0.09],
        [-0.95, 0.26],
        [-0.88, 0.13],
      ]),
      p,
    );
    // 꼬리 끝 흰 반점
    p.color = _white.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [-0.95, 0.26],
        [-0.88, 0.13],
        [-0.78, 0.155],
        [-0.83, 0.235],
      ]),
      p,
    );

    // ── 2. 몸통 + 머리 (하나의 각진 덩어리) ──────────────────────
    p.color = _dark.withValues(alpha: op);
    final body = poly([
      [-0.18, 0.07], // 꼬리 연결부
      [-0.10, -0.14], // 등
      [0.10, -0.20], // 어깨~목
      [0.27, -0.20], // 머리 위
      [0.36, -0.10], // 머리 앞
      [0.33, 0.01], // 턱
      [0.20, 0.17], // 배 앞
      [-0.04, 0.20], // 배
    ]);
    canvas.drawPath(body, p);

    // ── 3. 배 — 흰 면 (까치 흑백 대비) ───────────────────────────
    p.color = _white.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [0.30, -0.01],
        [0.21, 0.15],
        [0.0, 0.185],
        [0.0, 0.05],
        [0.18, 0.02],
      ]),
      p,
    );

    // ── 4. 부리 (금색 삼각형) ────────────────────────────────────
    p.color = _beak.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [0.35, -0.13],
        [0.50, -0.075],
        [0.35, -0.03],
      ]),
      p,
    );

    // ── 5. 눈 (작은 크림 점) ─────────────────────────────────────
    p.color = _white.withValues(alpha: op);
    canvas.drawCircle(pt(0.27, -0.115), s * 0.026, p);

    // ── 6. 갓 (머리 위 — 작지만 시그니처) ────────────────────────
    // 크라운
    p.color = _dark.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [0.115, -0.30],
        [0.245, -0.30],
        [0.225, -0.40],
        [0.135, -0.40],
      ]),
      p,
    );
    // 챙 (납작한 타원)
    canvas.save();
    canvas.translate(0.18 * s, -0.295 * s);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.40, height: s * 0.085),
      p,
    );
    canvas.restore();
    // 갓끈 — 금색 띠
    p.color = _band.withValues(alpha: op);
    canvas.drawRect(
      Rect.fromLTWH(0.125 * s, -0.315 * s, 0.115 * s, s * 0.022),
      p,
    );

    // ── 7. 날개 (어깨 피벗에서 회전하며 퍼덕임) ──────────────────
    final shoulder = pt(0.02, -0.10);
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(flap * 0.62); // 위/아래로 퍼덕
    // 날개 본체 (어두운 면)
    p.color = _darkFacet.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [0.02, -0.05],
        [-0.06, 0.07],
        [-0.40, 0.20],
        [-0.30, 0.01],
      ]),
      p,
    );
    // 날개 끝 흰 반점 (까치 날개 흰 무늬)
    p.color = _white.withValues(alpha: op);
    canvas.drawPath(
      poly([
        [-0.40, 0.20],
        [-0.30, 0.01],
        [-0.22, 0.05],
        [-0.31, 0.20],
      ]),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MagpiePainter old) =>
      old.t != t ||
      old.magpieSize != magpieSize ||
      old.bandTop != bandTop ||
      old.archHeight != archHeight;
}
