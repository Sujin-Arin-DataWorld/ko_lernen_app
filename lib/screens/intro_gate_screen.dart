import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/hanok/gate_art.dart';
import '../widgets/sori/tokens.dart';
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
    _ctrl =
        AnimationController(
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
    _ctrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Storage.setIntroSeen();
    final next = Storage.userLevelCode == null
        ? const OnboardingLevelScreen()
        : const HomeScreen();
    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.fadeScale((_) => next));
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
    final doorOpen = Curves.easeOutCubic.transform(
      ((t - 0.10) / 0.40).clamp(0.0, 1.0),
    );
    final pushIn = Curves.easeInCubic.transform(
      ((t - 0.46) / 0.46).clamp(0.0, 1.0),
    );
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
        Positioned.fill(
          child: Image.asset(
            'assets/illustrations/hanok/madang(light).png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HanokColors.madangSkyLight,
                    HanokColors.madangGround,
                  ],
                ),
              ),
            ),
          ),
        ),

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
            child: _gateLayer(doorOpen),
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

  Widget _gateLayer(double doorOpen) {
    return HanokGateArt(openAmount: doorOpen);
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
      child: Transform.rotate(
        angle: -0.25 + flap * 0.28,
        child: Image.asset(
          flap > 0.5
              ? 'assets/illustrations/mascot/magpie_wingup.png'
              : 'assets/illustrations/mascot/magpie_wingdown.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              CustomPaint(painter: _MagpiePainter(flap: flap)),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 까치 — 갓 쓴 작은 까치 실루엣 (날갯짓)
// ════════════════════════════════════════════════════════════════════════
class _MagpiePainter extends CustomPainter {
  final double flap;
  _MagpiePainter({required this.flap});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final black = Paint()..color = SoriColors.darkBg;

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
        center: Offset(0, -h * 0.13),
        width: w * 0.28,
        height: h * 0.34,
      ),
      black,
    );
    canvas.restore();

    // 몸통
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.58),
        width: w * 0.42,
        height: h * 0.34,
      ),
      black,
    );
    // 흰 배
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.62),
        width: w * 0.20,
        height: h * 0.17,
      ),
      Paint()..color = SoriColors.lightBg,
    );
    // 머리
    canvas.drawCircle(Offset(w * 0.67, h * 0.44), w * 0.13, black);
    // 갓 — 챙 + 모자
    canvas.drawLine(
      Offset(w * 0.54, h * 0.33),
      Offset(w * 0.82, h * 0.33),
      Paint()
        ..color = SoriColors.darkBg
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
