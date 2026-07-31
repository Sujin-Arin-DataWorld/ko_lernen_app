import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/account_nudge.dart';
import '../models/scenario.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/responsive.dart';

/// Erstes-Launch Onboarding — Nutzer wählt CEFR-Level.
///
/// **v3 (2026-05-29) — Option 3 Cinematic 시퀀스**
/// 인트로(솟을대문 시네마틱)의 직접 연속. 사용자는 게이트를 통과해 마당에 도착했고,
/// 호랑이가 마당에서 환영하는 풍경. gate_final 풍경이 full-bleed 배경.
/// 호랑이 + 말풍선이 hero, 4 level은 2×2 grid의 단청 carved sign으로.
class OnboardingLevelScreen extends StatefulWidget {
  const OnboardingLevelScreen({super.key});

  @override
  State<OnboardingLevelScreen> createState() => _OnboardingLevelScreenState();
}

class _OnboardingLevelScreenState extends State<OnboardingLevelScreen> {
  // Lern-Beispiele bleiben hartkodiert (sprach-agnostisch — koreanischer Inhalt).
  static const _exampleKo = {
    LearnerLevel.a1: '안녕하세요',
    LearnerLevel.a2: '아메리카노 톨',
    LearnerLevel.b1: '영화 봤어요',
    LearnerLevel.b2: '회의가 길어서',
  };

  Color _colorFor(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1:
        return SoriColors.success;
      case LearnerLevel.a2:
        return SoriColors.primary;
      case LearnerLevel.b1:
        return SoriColors.warning;
      case LearnerLevel.b2:
        return SoriColors.hangul;
    }
  }

  String _titleFor(AppL10n t, LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1:
        return t.onboardingLevelA1;
      case LearnerLevel.a2:
        return t.onboardingLevelA2;
      case LearnerLevel.b1:
        return t.onboardingLevelB1;
      case LearnerLevel.b2:
        return t.onboardingLevelB2;
    }
  }

  String _descFor(AppL10n t, LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1:
        return t.onboardingLevelA1Desc;
      case LearnerLevel.a2:
        return t.onboardingLevelA2Desc;
      case LearnerLevel.b1:
        return t.onboardingLevelB1Desc;
      case LearnerLevel.b2:
        return t.onboardingLevelB2Desc;
    }
  }

  Future<void> _select(BuildContext context, LearnerLevel level) async {
    HapticFeedback.mediumImpact();
    await Storage.setUserLevelCode(level.code);
    if (!context.mounted) return;
    // P1-2: G8 첫날 환영 모달 (이미지 준비 후 활성화)
    // await _showWelcomeModal(context, level);
    await showAccountNudgeSheet(context);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _skip(BuildContext context) async {
    HapticFeedback.selectionClick();
    await Storage.setUserLevelCode(LearnerLevel.a1.code);
    if (!context.mounted) return;
    await showAccountNudgeSheet(context);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. 마당 풍경 fullbleed — 인트로의 직접 연속 ──────────────
          // 사용자가 솟을대문을 통과해 도착한 마당. Ken Burns 미세 줌으로 호흡.
          Positioned.fill(
            child: SoriKenBurns(
              period: const Duration(seconds: 50),
              maxScale: 1.08,
              panAmount: 0.06,
              child: Image.asset(
                'assets/illustrations/hanok/gate_final.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),

          // ── 2. 가독성 gradient overlay (위:어둠 → 아래: 더 어둠) ──────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Ambient 입자 — 따뜻한 불씨 ────────────────────────────
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 14)),
          ),

          // ── 4. Content ───────────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                return SingleChildScrollView(
                  padding: soriClampPadding(
                    c.maxWidth,
                    base: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: c.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),

                        // ── Tiger + 말풍선 hero ──
                        _TigerWelcome(
                          greeting: t.onboardingTigerGreeting,
                        ),

                        const SizedBox(height: 20),

                        // ── Title (smaller, more grounded) ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 380),
                          slideY: 12,
                          child: Text(
                            t.onboardingTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SoriEntrance(
                          delay: const Duration(milliseconds: 440),
                          slideY: 8,
                          child: Text(
                            t.onboardingSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── 4-card 2×2 grid (단청 sign style) ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 540),
                          slideY: 22,
                          child: _LevelGrid(
                            t: t,
                            colorFor: _colorFor,
                            titleFor: _titleFor,
                            descFor: _descFor,
                            exampleKo: _exampleKo,
                            onSelect: (lvl) => _select(context, lvl),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── 작은 안내 + skip ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 720),
                          slideY: 6,
                          child: Text(
                            t.onboardingPrompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => _skip(context),
                            child: Text(
                              t.onboardingSkip,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tiger welcome with speech bubble
// ─────────────────────────────────────────────────────────────────────────

class _TigerWelcome extends StatelessWidget {
  final String greeting;
  const _TigerWelcome({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return SoriEntrance(
      duration: const Duration(milliseconds: 820),
      slideY: 24,
      startScale: 0.92,
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Soft glow halo behind tiger
            Positioned(
              bottom: 6,
              child: Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(
                    colors: [
                      SoriColors.gold.withValues(alpha: 0.42),
                      SoriColors.gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Tiger (animate: breathe + blink)
            const Positioned(
              bottom: 0,
              child: Mascot.tiger(
                size: 170,
                emotion: MascotEmotion.smile,
                animate: false,
              ),
            ),
            // Speech bubble
            Positioned(
              top: 0,
              right: 18,
              child: _SpeechBubble(text: greeting),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(
        bgColor: Colors.white.withValues(alpha: 0.96),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1A14),
            height: 1.35,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color bgColor;
  _BubbleTailPainter({required this.bgColor});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = bgColor;
    // Tail pointing down-left (toward tiger)
    final tail = Path()
      ..moveTo(size.width * 0.15, size.height - 2)
      ..lineTo(size.width * 0.05, size.height + 14)
      ..lineTo(size.width * 0.30, size.height - 2)
      ..close();
    canvas.drawPath(tail, p);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────
// 4-level grid (2×2) — 단청 carved wood sign style
// ─────────────────────────────────────────────────────────────────────────

class _LevelGrid extends StatelessWidget {
  final AppL10n t;
  final Color Function(LearnerLevel) colorFor;
  final String Function(AppL10n, LearnerLevel) titleFor;
  final String Function(AppL10n, LearnerLevel) descFor;
  final Map<LearnerLevel, String> exampleKo;
  final void Function(LearnerLevel) onSelect;

  const _LevelGrid({
    required this.t,
    required this.colorFor,
    required this.titleFor,
    required this.descFor,
    required this.exampleKo,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final levels = LearnerLevel.values;
    return Column(
      children: [
        for (int row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (int col = 0; col < 2; col++) ...[
                Expanded(
                  child: _LevelSign(
                    level: levels[row * 2 + col],
                    color: colorFor(levels[row * 2 + col]),
                    title: titleFor(t, levels[row * 2 + col]),
                    desc: descFor(t, levels[row * 2 + col]),
                    exampleKo: exampleKo[levels[row * 2 + col]]!,
                    onTap: () => onSelect(levels[row * 2 + col]),
                  ),
                ),
                if (col == 0) const SizedBox(width: 12),
              ],
            ],
          ),
          if (row == 0) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LevelSign extends StatelessWidget {
  final LearnerLevel level;
  final Color color;
  final String title;
  final String desc;
  final String exampleKo;
  final VoidCallback onTap;

  const _LevelSign({
    required this.level,
    required this.color,
    required this.title,
    required this.desc,
    required this.exampleKo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.light,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          // Glass-like translucent dancheong wood sign
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(SoriRadius.lg),
          border: Border.all(
            color: color.withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level badge + arrow
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(SoriRadius.sm),
                  ),
                  child: Text(
                    level.display,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Desc (1 line)
            Text(
              desc,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Korean example chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(SoriRadius.sm),
              ),
              child: Text(
                exampleKo,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color.computeLuminance() < 0.5
                      ? Colors.white
                      : Colors.white,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
