import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/hanok/madang_painter.dart';
import '../motion/transitions.dart';
import 'home_screen.dart';
import 'onboarding_level_screen.dart';

/// **솟을대문 인트로** — 앱의 시그니처 입장 장면.
///
/// 정적 splash 대신, 닫힌 한옥 대문이 열리고 카메라가 마당으로 들어선다.
/// "상자 더미"가 아니라 "들어서는 살아있는 한옥"의 첫인상.
///
/// 타임라인 (t = 0..1):
/// - 0.00–0.10  대문이 한지 위로 나타남 (scale-in)
/// - 0.10–0.50  두 문짝이 경첩으로 열림 (perspective rotateY)
/// - 0.42–0.82  까치 한 마리가 문을 가로질러 날아감
/// - 0.46–0.92  카메라가 문을 통과해 마당으로 push-in
/// - 1.00       홈(또는 온보딩)으로 전환
class IntroGateScreen extends StatefulWidget {
  const IntroGateScreen({super.key});

  @override
  State<IntroGateScreen> createState() => _IntroGateScreenState();
}

class _IntroGateScreenState extends State<IntroGateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final firstRun = !Storage.introSeen;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: firstRun ? 2750 : 1600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _skip() {
    if (_navigated || !_ctrl.isAnimating) return;
    _ctrl.animateTo(1.0,
        duration: const Duration(milliseconds: 440), curve: Curves.easeOut);
  }

  void _finish() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Storage.setIntroSeen();
    final next = Storage.userLevelCode == null
        ? const OnboardingLevelScreen()
        : const HomeScreen();
    Navigator.of(context).pushReplacement(SoriTransitions.fadeScale(next));
  }

  @override
  Widget build(BuildContext context) {
    // 인트로는 항상 따뜻한 낮 — "환영"의 톤.
    return Theme(
      data: ThemeData(brightness: Brightness.light),
      child: Scaffold(
        backgroundColor: HanokColors.hanjiCream,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: LayoutBuilder(
            builder: (context, c) => AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => _scene(Size(c.maxWidth, c.maxHeight)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(Size size) {
    final t = _ctrl.value;

    final appear = Curves.easeOut.transform((t / 0.10).clamp(0.0, 1.0));
    final doorOpen =
        Curves.easeOutCubic.transform(((t - 0.10) / 0.40).clamp(0.0, 1.0));
    final pushIn =
        Curves.easeInCubic.transform(((t - 0.46) / 0.46).clamp(0.0, 1.0));
    final gateFade = 1.0 - ((t - 0.78) / 0.20).clamp(0.0, 1.0);
    final magpieT = ((t - 0.42) / 0.40).clamp(0.0, 1.0);
    final glow = doorOpen * (1.0 - pushIn);
    final skipO = 0.5 * (1.0 - ((t - 0.5) / 0.15).clamp(0.0, 1.0));

    final gateScale = (0.96 + appear * 0.04) + pushIn * 3.0;
    const gatewayAlign = Alignment(0.0, 0.18);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. 마당 (문 너머 — 항상 뒤에) ──────────────────────────
        const MadangBackground(),

        // ── 2. 문틈에서 새어나오는 따뜻한 빛 ────────────────────────
        if (glow > 0.01)
          Align(
            alignment: gatewayAlign,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 0.66,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      HanokColors.hwang.withValues(alpha: 0.5 * glow),
                      HanokColors.hwang.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── 3. 대문 (지붕·단청·기둥 + 두 문짝) ─────────────────────
        Opacity(
          opacity: gateFade.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: gateScale,
            alignment: gatewayAlign,
            child: _gateLayer(size, doorOpen),
          ),
        ),

        // ── 4. 까치 ────────────────────────────────────────────────
        if (magpieT > 0.0 && magpieT < 1.0) _magpie(size, magpieT),

        // ── 5. 건너뛰기 힌트 ───────────────────────────────────────
        if (skipO > 0.01)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: skipO,
              child: const Text(
                'Tippen zum Überspringen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: HanokColors.hwangtoDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gateLayer(Size size, double doorOpen) {
    final w = size.width;
    final h = size.height;
    const openL = 0.175, openR = 0.825, openT = 0.33, openB = 0.86;
    final doorW = (openR - openL) / 2 * w;
    final doorH = (openB - openT) * h;
    final doorAngle = doorOpen * 1.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CustomPaint(painter: _GatePainter())),

        // 왼쪽 문짝 — 왼쪽 모서리 경첩
        Positioned(
          left: openL * w,
          top: openT * h,
          width: doorW,
          height: doorH,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(-doorAngle),
            child: CustomPaint(painter: _DoorPainter(isLeft: true)),
          ),
        ),

        // 오른쪽 문짝 — 오른쪽 모서리 경첩
        Positioned(
          left: (openL + (openR - openL) / 2) * w,
          top: openT * h,
          width: doorW,
          height: doorH,
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(doorAngle),
            child: CustomPaint(painter: _DoorPainter(isLeft: false)),
          ),
        ),
      ],
    );
  }

  Widget _magpie(Size size, double mt) {
    final w = size.width;
    final h = size.height;
    final p0 = Offset(-0.12 * w, 0.74 * h);
    final p1 = Offset(0.46 * w, 0.04 * h);
    final p2 = Offset(1.14 * w, 0.30 * h);
    final u = 1 - mt;
    final pos = p0 * (u * u) + p1 * (2 * u * mt) + p2 * (mt * mt);
    final flap = (math.sin(mt * math.pi * 13) + 1) / 2;
    const s = 48.0;
    return Positioned(
      left: pos.dx - s / 2,
      top: pos.dy - s / 2,
      width: s,
      height: s,
      child: CustomPaint(painter: _MagpiePainter(flap: flap)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 대문 구조 — 한지 배경 + 지붕·단청·기둥, opening은 투명하게 뚫음
// ════════════════════════════════════════════════════════════════════════
class _GatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;
    final opening = Rect.fromLTRB(w * 0.175, h * 0.33, w * 0.825, h * 0.86);

    canvas.saveLayer(full, Paint());

    // 1. 한지 크림 배경
    canvas.drawRect(full, Paint()..color = HanokColors.hanjiCream);

    // 2. 기단 (stone base)
    final baseRect = Rect.fromLTRB(w * 0.05, h * 0.86, w * 0.95, h * 0.925);
    canvas.drawRRect(
      RRect.fromRectAndCorners(baseRect,
          topLeft: const Radius.circular(5), topRight: const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HanokColors.giwaHi, HanokColors.giwaShadow],
        ).createShader(baseRect),
    );

    // 3. 기둥 (두 개)
    _pillar(canvas, Rect.fromLTRB(w * 0.085, h * 0.30, w * 0.175, h * 0.875));
    _pillar(canvas, Rect.fromLTRB(w * 0.825, h * 0.30, w * 0.915, h * 0.875));

    // 4. 보 (lintel beam)
    canvas.drawRect(
      Rect.fromLTRB(w * 0.07, h * 0.295, w * 0.93, h * 0.345),
      Paint()..color = HanokColors.hwangtoDark,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.07, h * 0.295, w * 0.93, h * 0.307),
      Paint()..color = HanokColors.hwangtoLight,
    );

    // 5. 단청 띠
    _dancheong(canvas, Rect.fromLTRB(w * 0.07, h * 0.247, w * 0.93, h * 0.295));

    // 6. 지붕
    _roof(canvas, w, h);

    // 7. opening 구멍 뚫기 → 뒤의 마당이 비침
    canvas.drawRect(opening, Paint()..blendMode = BlendMode.clear);

    canvas.restore();

    // 8. opening 안쪽 테두리 (구멍 뚫은 후 위에 그림)
    canvas.drawRect(
      opening,
      Paint()
        ..color = HanokColors.heuk.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _pillar(Canvas canvas, Rect r) {
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            HanokColors.hwangtoDark,
            HanokColors.hwangtoLight,
            HanokColors.hwangto,
            HanokColors.hwangtoDark,
          ],
          stops: const [0.0, 0.32, 0.62, 1.0],
        ).createShader(r),
    );
  }

  void _dancheong(Canvas canvas, Rect band) {
    canvas.drawRect(band, Paint()..color = HanokColors.cheong);
    final line = Paint()
      ..color = HanokColors.heuk
      ..strokeWidth = 2;
    canvas.drawLine(band.topLeft, band.topRight, line);
    canvas.drawLine(band.bottomLeft, band.bottomRight, line);

    const unit = 34.0;
    final n = (band.width / unit).floor();
    final pad = (band.width - n * unit) / 2;
    final cy = band.center.dy;
    final r = band.height * 0.34;
    final stroke = Paint()
      ..color = HanokColors.baek
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < n; i++) {
      final cx = band.left + pad + unit * (i + 0.5);
      final diamond = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r, cy)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r, cy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = i.isEven ? HanokColors.jeok : HanokColors.hwang,
      );
      canvas.drawPath(diamond, stroke);
    }
  }

  void _roof(Canvas canvas, double w, double h) {
    final roof = Path()
      ..moveTo(w * 0.05, h * 0.215)
      ..quadraticBezierTo(w * 0.20, h * 0.265, w * 0.5, h * 0.265)
      ..quadraticBezierTo(w * 0.80, h * 0.265, w * 0.95, h * 0.215)
      ..lineTo(w * 0.79, h * 0.055)
      ..lineTo(w * 0.21, h * 0.055)
      ..close();

    // 그림자
    canvas.drawPath(
      roof.shift(const Offset(0, 7)),
      Paint()
        ..color = HanokColors.heuk.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    // 본체
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            HanokColors.giwaHi,
            HanokColors.giwaGray,
            HanokColors.giwaShadow,
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.05, w, h * 0.22)),
    );
    // 용마루
    canvas.drawLine(
      Offset(w * 0.21, h * 0.057),
      Offset(w * 0.79, h * 0.057),
      Paint()
        ..color = HanokColors.heuk
        ..strokeWidth = h * 0.013
        ..strokeCap = StrokeCap.round,
    );
    // 기와 결 (처마선 따라 3줄)
    final tilePaint = Paint()
      ..color = HanokColors.giwaShadow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var k = 1; k <= 3; k++) {
      final dy = h * 0.017 * k;
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.075, h * 0.205 + dy)
          ..quadraticBezierTo(
              w * 0.20, h * 0.255 + dy, w * 0.5, h * 0.255 + dy)
          ..quadraticBezierTo(
              w * 0.80, h * 0.255 + dy, w * 0.925, h * 0.205 + dy),
        tilePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GatePainter old) => false;
}

// ════════════════════════════════════════════════════════════════════════
// 문짝 — 석간주 적 + 황금 못 + 문고리
// ════════════════════════════════════════════════════════════════════════
class _DoorPainter extends CustomPainter {
  final bool isLeft;
  _DoorPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 바탕 — 석간주 적 세로 그라데이션
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(HanokColors.jeok, Colors.white, 0.10)!,
            HanokColors.jeok,
            Color.lerp(HanokColors.jeok, Colors.black, 0.20)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // 테두리
    canvas.drawRect(
      rect,
      Paint()
        ..color = HanokColors.heuk.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 세로 널결 (planks)
    final plank = Paint()
      ..color = HanokColors.heuk.withValues(alpha: 0.16)
      ..strokeWidth = 2;
    for (var i = 1; i <= 2; i++) {
      final x = w * i / 3;
      canvas.drawLine(Offset(x, h * 0.04), Offset(x, h * 0.96), plank);
    }

    // 황금 못 (brass studs) — 4행 × 3열
    final gold = Paint()..color = HanokColors.hwang;
    final hi = Paint()..color = Color.lerp(HanokColors.hwang, Colors.white, 0.5)!;
    final rad = w * 0.042;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 3; c++) {
        final cx = w * (0.5 + c) / 3;
        final cy = h * (0.13 + 0.247 * r);
        canvas.drawCircle(Offset(cx, cy), rad, gold);
        canvas.drawCircle(
            Offset(cx - rad * 0.3, cy - rad * 0.3), rad * 0.34, hi);
      }
    }

    // 문고리 — 안쪽 가장자리
    final hx = isLeft ? w * 0.85 : w * 0.15;
    final hy = h * 0.52;
    canvas.drawCircle(
      Offset(hx, hy),
      w * 0.10,
      Paint()..color = HanokColors.hwang.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      Offset(hx, hy),
      w * 0.10,
      Paint()
        ..color = HanokColors.hwangtoDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(hx, hy + w * 0.105),
      w * 0.082,
      Paint()
        ..color = Color.lerp(HanokColors.hwang, Colors.black, 0.18)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.034,
    );
  }

  @override
  bool shouldRepaint(_DoorPainter old) => old.isLeft != isLeft;
}

// ════════════════════════════════════════════════════════════════════════
// 까치 — 갓 쓴 작은 까치 실루엣 (날갯짓)
// ════════════════════════════════════════════════════════════════════════
class _MagpiePainter extends CustomPainter {
  final double flap;
  _MagpiePainter({required this.flap});

  static const _black = Color(0xFF15151A);
  static const _white = Color(0xFFF4F4F4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final black = Paint()..color = _black;

    // 꼬리
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.32, h * 0.54)
        ..lineTo(w * 0.04, h * 0.44)
        ..lineTo(w * 0.10, h * 0.68)
        ..close(),
      black,
    );

    // 날개 (flap)
    canvas.save();
    canvas.translate(w * 0.46, h * 0.50);
    canvas.rotate(-0.4 - flap * 1.0);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, -h * 0.13), width: w * 0.28, height: h * 0.34),
      black,
    );
    canvas.restore();

    // 몸통
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.52, h * 0.58),
          width: w * 0.42,
          height: h * 0.34),
      black,
    );
    // 흰 배
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.54, h * 0.62),
          width: w * 0.20,
          height: h * 0.17),
      Paint()..color = _white,
    );
    // 머리
    canvas.drawCircle(Offset(w * 0.67, h * 0.44), w * 0.13, black);
    // 갓 — 챙 + 모자
    canvas.drawLine(
      Offset(w * 0.54, h * 0.33),
      Offset(w * 0.82, h * 0.33),
      Paint()
        ..color = _black
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.61, h * 0.20, w * 0.74, h * 0.33),
      black,
    );
    // 부리
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.79, h * 0.43)
        ..lineTo(w * 0.93, h * 0.46)
        ..lineTo(w * 0.79, h * 0.49)
        ..close(),
      Paint()..color = HanokColors.hwang,
    );
  }

  @override
  bool shouldRepaint(_MagpiePainter old) => old.flap != flap;
}
