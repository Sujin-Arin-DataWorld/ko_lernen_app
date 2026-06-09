import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/hanok/gate_art.dart';
import '../widgets/sori/tokens.dart';
import '../motion/transitions.dart';
import 'home_screen.dart';
import 'onboarding_level_screen.dart';
import 'consent_screen.dart';
import '../l10n/generated/app_localizations.dart';

const _courtyardAsset = 'assets/illustrations/hanok/gate_final.png';
const _gateFrameCanvas = Size(941, 1672);
const _gatewayAlign = Alignment(0.0, 0.10);

/// **솟을대문 인트로** — 앱의 시그니처 입장 장면.
///
/// 닫힌 종가 대문이 열리고, 카메라가 열린 문 사이로 안마당으로 빨려 들어간다.
/// "상자 더미"가 아니라 "들어서는 살아있는 한옥"의 첫인상.
///
/// **v6 (2026-06-02) — 3겹 단순화**: 사진풍 `gate_entrance` + 미니멀 `madang`
/// 혼용을 제거하고, 서로 어울리는 종가 세트(`gate_frame`+문짝2 + `gate_final`)
/// 한 톤으로 통일. 게이트 PNG는 바깥/문구멍 투명 knockout 완료.
/// - 0.00–0.12  닫힌 대문 establishing (안마당은 dim)
/// - 0.18–0.52  문짝이 경첩 기준 바깥으로 회전해 열림 + 문틈 황금빛
/// - 0.22–0.62  안마당(`gate_final`)이 점점 선명해짐
/// - 0.30–0.80  까치가 대문 위를 가로지름
/// - 0.50–0.92  카메라 push-in: 대문이 커지며 통과, 마당이 확대
/// - 0.80–1.00  대문 페이드아웃 → 마당만 → 홈으로 handoff
class IntroGateScreen extends StatefulWidget {
  const IntroGateScreen({super.key});

  @override
  State<IntroGateScreen> createState() => _IntroGateScreenState();
}

class _IntroGateScreenState extends State<IntroGateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _navigated = false;
  bool _reduceMotion = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // reduce-motion: 화려한 시네마틱 생략, 곧장 마당으로.
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce && !_reduceMotion) {
      _reduceMotion = true;
      _ctrl.duration = const Duration(milliseconds: 900);
    }
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
    final Widget next;
    if (!Storage.consentAccepted) {
      next = const ConsentScreen();
    } else if (Storage.userLevelCode == null) {
      next = const OnboardingLevelScreen();
    } else {
      next = const HomeScreen();
    }
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
    final appear = Curves.easeOutCubic.transform((t / 0.12).clamp(0.0, 1.0));

    // 문 열림 — 0.18~0.52
    final doorOpen = Curves.easeInOutCubic.transform(
      ((t - 0.18) / 0.34).clamp(0.0, 1.0),
    );

    // 안마당 선명도 — 0.22~0.62
    final courtyardReveal = Curves.easeOutCubic.transform(
      ((t - 0.22) / 0.40).clamp(0.0, 1.0),
    );

    // 카메라 푸시 — 0.50~0.92
    final pushIn = Curves.easeInOutCubic.transform(
      ((t - 0.50) / 0.42).clamp(0.0, 1.0),
    );

    // 대문 페이드아웃 — 0.80~1.00 (문지방을 통과하는 느낌)
    final gateFade =
        1.0 - Curves.easeInCubic.transform(((t - 0.80) / 0.20).clamp(0.0, 1.0));

    // 까치 비행 — 0.30~0.80
    final magpieT = ((t - 0.30) / 0.50).clamp(0.0, 1.0);

    // 문틈 빛(반쯤 열림에서 가장 강함, 다 열리면 사라짐) — 종 모양 0→1→0
    final glow = doorOpen * (1.0 - doorOpen) * 4.0;

    // skip 힌트(초반에 잠깐만)
    final skipO = 0.55 * (1.0 - ((t - 0.45) / 0.18).clamp(0.0, 1.0));

    // ── 스케일 ──────────────────────────────────────────────────────────────
    // 마당은 천천히, 대문은 빠르게 커지며 통과 → 전진 parallax.
    final courtyardScale = 1.06 + pushIn * 0.32;
    final gateScale = 1.0 + pushIn * 1.55;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. 안마당(도착점) — push-in의 목적지. 처음엔 dim. ──────────────
        _coverImage(
          asset: _courtyardAsset,
          scale: courtyardScale,
          opacity: 0.40 + courtyardReveal * 0.60,
          alignment: Alignment.center,
        ),

        // ── 2. 대문(프레임 + 문짝) — 바깥/문구멍 투명. 문이 열린다. ─────────
        _coverGateFrame(
          scale: gateScale,
          opacity: appear * gateFade,
          child: HanokGateArt(openAmount: doorOpen),
        ),

        // ── 3. 문틈에서 새어나오는 따뜻한 빛 ────────────────────────────────
        if (glow > 0.01)
          IgnorePointer(
            child: Align(
              alignment: _gatewayAlign,
              child: FractionallySizedBox(
                widthFactor: 0.50,
                heightFactor: 0.46,
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

        // ── 4. 가장자리 vignette — 문 안으로 들어갈 때 중심으로 시선 유도. ──
        IgnorePointer(child: _Vignette(strength: 0.20 + pushIn * 0.18)),

        // ── 5. 까치 ────────────────────────────────────────────────────────
        if (magpieT > 0.0 && magpieT < 1.0) _magpie(size, magpieT),

        // ── 6. 건너뛰기 힌트 ───────────────────────────────────────────────
        if (skipO > 0.01)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: skipO,
              child: Text(
                AppL10n.of(context).introSkipHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
// 까치 — 갓 쓴 작은 까치 실루엣 (날갯짓, PNG 로드 실패 시 fallback)
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
