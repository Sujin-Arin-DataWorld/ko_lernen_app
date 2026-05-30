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
/// **v2 타임라인 (2026-05-29 리듬 수정)** — 자연스러운 호흡으로 재설계:
/// - 0.00–0.12  대문이 한지 위로 부드럽게 페이드+살짝 확대 (scale-in)
/// - 0.10–0.55  두 문짝이 경첩으로 천천히 열림 (easeInOutCubic, perspective rotateY)
/// - 0.38–0.85  까치 한 마리가 문을 가로질러 평화롭게 비행
/// - 0.45–0.70  doorway 너머 마당 풍경(gate_final) 페이드인 (안정적인 plateau)
/// - 0.62–0.95  카메라가 부드럽게 마당으로 push-in (easeInOut, 2.4x 한계)
/// - 0.82–1.00  대문 frame이 부드럽게 fade-out
/// - 1.00       홈(또는 온보딩)으로 전환
///
/// 이전 v1의 부자연스러움 원인:
///   ① easeInCubic push (끝에서 가속) → 멀미 유발 → easeInOutCubic으로 변경
///   ② gateScale 4.0배 (과한 줌) → 2.4배로 완화
///   ③ 도어 open(0.50) ↔ 푸시 시작(0.46) 거의 동시 → 사이에 plateau(0.55→0.62) 추가
///   ④ gate_frame이 doorway/외부 모두 불투명 → 도어/배경 다 가려짐 → PNG 알파 knockout으로 해결
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
    // 첫 실행 3.4s — 천천히, 음미하도록. 재실행 1.8s — 적당히 reset.
    _ctrl =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: firstRun ? 3400 : 1800),
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
      duration: const Duration(milliseconds: 520),
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

    // ── 타이밍 함수 ─────────────────────────────────────────────────────────
    // 1) 게이트 등장 — 0.00~0.12 (부드러운 페이드+살짝 확대)
    final appear = Curves.easeOutCubic.transform((t / 0.12).clamp(0.0, 1.0));

    // 2) 문 열림 — 0.10~0.55 (easeInOutCubic = 끝에서 부드럽게 안착)
    final doorOpen = Curves.easeInOutCubic.transform(
      ((t - 0.10) / 0.45).clamp(0.0, 1.0),
    );

    // 3) 마당 풍경 — **v3 (2026-05-29 재수정)**: t=0부터 doorway 뒤에 항상 존재.
    //    이전엔 0.45~0.70 fade-in이라 도어 열렸을 때 cream 배경이 보여
    //    "에러난 듯" 빈 doorway가 노출되는 문제가 있었음. 이제 도어가 열리는
    //    순간부터 마당 풍경이 자연스럽게 드러난다.
    final beyondFade = Curves.easeOut.transform(
      ((t - 0.00) / 0.15).clamp(0.0, 1.0),
    );

    // 4) 카메라 푸시 — 0.62~0.95 (easeInOutCubic, 천천히 가속·천천히 안착)
    final pushIn = Curves.easeInOutCubic.transform(
      ((t - 0.62) / 0.33).clamp(0.0, 1.0),
    );

    // 5) 게이트 페이드아웃 — 0.82~1.00
    final gateFade = 1.0 - Curves.easeIn.transform(
      ((t - 0.82) / 0.18).clamp(0.0, 1.0),
    );

    // 6) 까치 비행 — 0.38~0.85
    final magpieT = ((t - 0.38) / 0.47).clamp(0.0, 1.0);

    // 7) 문틈 빛(닫힌→반쯤 열림 사이 가장 강함, 도어 다 열리면 사라짐)
    final glow = doorOpen * (1.0 - doorOpen) * 4.0; // 0→1→0 종 모양

    // 8) skip 힌트(중반에 잠깐만)
    final skipO = 0.55 * (1.0 - ((t - 0.45) / 0.18).clamp(0.0, 1.0));

    // ── 스케일 / 정렬 ───────────────────────────────────────────────────────
    // 게이트: 0.96에서 등장 → 1.00 안착 → 푸시 시 2.4배까지
    final gateScale = (0.96 + appear * 0.04) + pushIn * 1.4;
    // 마당 풍경: 1.05에서 등장(살짝 크게) → 푸시 시 1.45배 (parallax 차)
    final beyondScale = 1.05 + pushIn * 0.40;
    const gatewayAlign = Alignment(0.0, 0.10);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. 마당 base (한지 cream에 가까운 따뜻한 톤) ─────────────────
        // gate_final 로드 실패 시 안전망. 단색이라 카메라 푸시 영향 안 받음.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HanokColors.madangSkyLight,
                  HanokColors.hanjiCreamDark,
                ],
              ),
            ),
          ),
        ),

        // ── 1b. 문 너머 — 활짝 열린 대문 + 마당 + 하녹 풍경 ─────────
        // doorway가 transparent라서 frame 뒤에서도 잘 보임.
        // **v3**: 도어가 열리는 순간 빈 cream이 아니라 마당 풍경이 보이도록
        // t=0부터 fade-in. 카메라가 들어설수록 함께 커진다(둔하게).
        if (beyondFade > 0.01)
          Opacity(
            opacity: beyondFade,
            child: Transform.scale(
              scale: beyondScale,
              alignment: gatewayAlign,
              child: Image.asset(
                'assets/illustrations/hanok/gate_final.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

        // ── 2. 문틈에서 새어나오는 따뜻한 빛 ────────────────────────
        if (glow > 0.01)
          IgnorePointer(
            child: Align(
              alignment: gatewayAlign,
              child: FractionallySizedBox(
                widthFactor: 0.58,
                heightFactor: 0.52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        HanokColors.hwang.withValues(alpha: 0.42 * glow),
                        HanokColors.hwang.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 3. 대문 (지붕·단청·기둥 + 두 문짝) ─────────────────────
        // **v3**: FittedBox(cover, topCenter)로 화면을 가득 채움.
        //   - AspectRatio+Center 방식은 9:19.5 폰에서 위아래 cream 여백이 생겨
        //     "오류난 듯 빈 공간"을 만들었음.
        //   - 이제 게이트가 화면 가득 — 지붕이 위로, doorway가 화면 중상단에 위치.
        //   - 좌우 살짝 잘려도 단청 detail은 보존되도록 cover 채택.
        Opacity(
          opacity: appear * gateFade.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: gateScale,
            alignment: gatewayAlign,
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 941,
                height: 1672,
                child: _gateLayer(doorOpen),
              ),
            ),
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
// 까치 — 갓 쓴 작은 까치 실루엣 (날갯짓, gate_final 로드 실패 시 fallback)
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
