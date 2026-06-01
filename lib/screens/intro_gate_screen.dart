import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/hanok/gate_art.dart';
import '../widgets/sori/tokens.dart';
import '../motion/transitions.dart';
import 'home_screen.dart';
import 'onboarding_level_screen.dart';

const _gateEntranceAsset = 'assets/illustrations/hanok/gate_entrance.png';
const _courtyardAsset = 'assets/illustrations/hanok/gate_final.png';
const _paperCourtyardAsset = 'assets/illustrations/hanok/madang(light).png';
const _entranceCanvas = Size(1024, 1536);
const _gateFrameCanvas = Size(941, 1672);
const _gatewayAlign = Alignment(0.0, 0.10);

/// **솟을대문 인트로** — 앱의 시그니처 입장 장면.
///
/// 정적 splash 대신, 닫힌 한옥 대문이 열리고 카메라가 마당으로 들어선다.
/// "상자 더미"가 아니라 "들어서는 살아있는 한옥"의 첫인상.
///
/// **v5 타임라인 (2026-06-01 새 gate 자산 반영)** — 넓은 대문 컷에서 마당으로 진입:
/// - 0.00–0.28  `gate_entrance`로 넓은 닫힌 대문 establishing shot
/// - 0.28–0.44  카메라가 대문에 다가가며 transparent `gate_frame` 레이어로 handoff
/// - 0.34–0.68  문짝이 열리며 `gate_final`의 안마당이 선명해짐
/// - 0.30–0.80  까치가 대문 위를 가로지르며 생동감 추가
/// - 0.68–0.96  카메라가 문간 중심으로 push-in
/// - 0.78–1.00  대문 레이어가 사라지고 마당 화면으로 자연스럽게 handoff
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
    // 첫 실행은 인상 깊게, 재실행은 답답하지 않게.
    _ctrl =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: firstRun ? 3900 : 2300),
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
    final appear = Curves.easeOutCubic.transform((t / 0.14).clamp(0.0, 1.0));
    final settle = Curves.easeOutCubic.transform((t / 0.18).clamp(0.0, 1.0));

    // 2) establishing shot → close gate frame handoff.
    final approach = Curves.easeInOutCubic.transform(
      ((t - 0.12) / 0.24).clamp(0.0, 1.0),
    );
    final frameAppear = Curves.easeOutCubic.transform(
      ((t - 0.28) / 0.14).clamp(0.0, 1.0),
    );
    final entranceFade =
        1.0 -
        Curves.easeInOutCubic.transform(((t - 0.30) / 0.16).clamp(0.0, 1.0));

    // 3) 문 열림 — 0.34~0.68 (대문에 다가간 뒤 열린다)
    final doorOpen = Curves.easeInOutCubic.transform(
      ((t - 0.34) / 0.34).clamp(0.0, 1.0),
    );

    // 4) 안마당 선명도 — 문이 열릴 때 `gate_final` 컷으로 handoff.
    final courtyardReveal = Curves.easeOutCubic.transform(
      ((t - 0.36) / 0.32).clamp(0.0, 1.0),
    );

    // 5) 카메라 푸시 — 0.68~0.96 (문이 충분히 열린 뒤 안으로 들어감)
    final pushIn = Curves.easeInOutCubic.transform(
      ((t - 0.68) / 0.28).clamp(0.0, 1.0),
    );

    // 6) 대문 페이드아웃 — 푸시 후반부에 문지방을 통과하는 느낌.
    final gateFade =
        1.0 - Curves.easeInCubic.transform(((t - 0.78) / 0.22).clamp(0.0, 1.0));

    // 7) 까치 비행 — 0.30~0.80
    final magpieT = ((t - 0.30) / 0.50).clamp(0.0, 1.0);

    // 8) 문틈 빛(닫힌→반쯤 열림 사이 가장 강함, 도어 다 열리면 사라짐)
    final glow = doorOpen * (1.0 - doorOpen) * 4.0; // 0→1→0 종 모양

    // 9) skip 힌트(초반에 잠깐만)
    final skipO = 0.55 * (1.0 - ((t - 0.45) / 0.18).clamp(0.0, 1.0));

    // ── 스케일 / 정렬 ───────────────────────────────────────────────────────
    // entrance는 넓은 컷에서 대문 쪽으로 다가가고, frame은 close-up gate 역할.
    final entranceScale = (1.02 - settle * 0.02) + approach * 1.05;
    final frameScale = (0.97 + frameAppear * 0.03) + pushIn * 1.42;
    final courtyardScale = (1.12 - courtyardReveal * 0.04) + pushIn * 0.38;
    final paperScale = 1.02 + pushIn * 0.10;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. 한지/산 base — reference 이미지처럼 넓은 숨을 먼저 만든다. ──
        _coverImage(
          asset: _paperCourtyardAsset,
          scale: paperScale,
          opacity: 1.0,
          alignment: Alignment.center,
        ),

        // ── 2. 문 너머 안마당 — push-in의 도착점. ─────────────────────
        _coverImage(
          asset: _courtyardAsset,
          scale: courtyardScale,
          opacity: 0.34 + courtyardReveal * 0.66,
          alignment: Alignment.center,
        ),

        // ── 3. reference형 대문 컷 — backup의 with_gate 이미지를 정식 레이어로 사용. ──
        _coverCanvas(
          scale: entranceScale,
          opacity: appear * entranceFade,
          child: Image.asset(
            _gateEntranceAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        // ── 4. 투명 프레임 + 문짝 — 실제 문 열림 레이어. ────────────────
        _coverGateFrame(
          scale: frameScale,
          opacity: appear * frameAppear * gateFade,
          child: HanokGateArt(openAmount: doorOpen),
        ),

        // ── 5. 문틈에서 새어나오는 따뜻한 빛 ────────────────────────
        if (glow > 0.01)
          IgnorePointer(
            child: Align(
              alignment: _gatewayAlign,
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

        // ── 6. 가장자리 vignette — 문 안으로 들어갈 때 중심으로 시선 유도. ──
        IgnorePointer(child: _Vignette(strength: 0.22 + pushIn * 0.18)),

        // ── 7. 까치 ────────────────────────────────────────────────
        if (magpieT > 0.0 && magpieT < 1.0) _magpie(size, magpieT),

        // ── 8. 건너뛰기 힌트 ───────────────────────────────────────
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

  Widget _coverImage({
    required String asset,
    required double scale,
    required double opacity,
    required Alignment alignment,
  }) {
    final o = _unit(opacity);
    if (o <= 0.01) return const SizedBox.shrink();
    return Opacity(
      opacity: o,
      child: Transform.scale(
        scale: scale,
        alignment: _gatewayAlign,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => const DecoratedBox(
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
      ),
    );
  }

  Widget _coverCanvas({
    required double scale,
    required double opacity,
    required Widget child,
  }) {
    final o = _unit(opacity);
    if (o <= 0.01) return const SizedBox.shrink();
    return Opacity(
      opacity: o,
      child: Transform.scale(
        scale: scale,
        alignment: _gatewayAlign,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: _entranceCanvas.width,
            height: _entranceCanvas.height,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _coverGateFrame({
    required double scale,
    required double opacity,
    required Widget child,
  }) {
    final o = _unit(opacity);
    if (o <= 0.01) return const SizedBox.shrink();
    return Opacity(
      opacity: o,
      child: Transform.scale(
        scale: scale,
        alignment: _gatewayAlign,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: _gateFrameCanvas.width,
            height: _gateFrameCanvas.height,
            child: child,
          ),
        ),
      ),
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

double _unit(double value) => value.clamp(0.0, 1.0).toDouble();

class _Vignette extends StatelessWidget {
  final double strength;

  const _Vignette({required this.strength});

  @override
  Widget build(BuildContext context) {
    final edge = _unit(strength);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, 0.06),
          radius: 1.02,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: edge),
          ],
          stops: const [0.54, 1.0],
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
