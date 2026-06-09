import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/pack_progress_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **Vocab Pack Result Screen** — Phase 2 의 클리어 결과 화면.
///
/// 보스 정확도 ≥ 70% → 단청 도장 시네마틱 + "다음 팩" CTA.
/// 미달 → 격려 메시지 + "다시 도전" CTA.
///
/// **Args (routes)** via `Navigator.pushReplacementNamed('/vocab/result',
/// arguments: { ... })`:
///   - `packId`: String
///   - `bossAccuracy`: double (0..1)
///   - `bossCorrect`: int
///   - `bossTotal`: int
///   - `quizCorrect`: int
///   - `quizTotal`: int
///   - `justCleared`: bool
///   - `nextUnlockedPackId`: String?
class VocabPackResultScreen extends StatelessWidget {
  final String packId;
  final double bossAccuracy;
  final int bossCorrect;
  final int bossTotal;
  final int quizCorrect;
  final int quizTotal;
  final bool justCleared;
  final String? nextUnlockedPackId;

  const VocabPackResultScreen({
    super.key,
    required this.packId,
    required this.bossAccuracy,
    required this.bossCorrect,
    required this.bossTotal,
    required this.quizCorrect,
    required this.quizTotal,
    required this.justCleared,
    required this.nextUnlockedPackId,
  });

  /// Factory aus Navigator-args. Falls Map fehlt → defaults.
  factory VocabPackResultScreen.fromArgs(Object? args) {
    final m = (args is Map) ? args : const <String, dynamic>{};
    return VocabPackResultScreen(
      packId: m['packId'] as String? ?? '',
      bossAccuracy: (m['bossAccuracy'] as num?)?.toDouble() ?? 0.0,
      bossCorrect: (m['bossCorrect'] as num?)?.toInt() ?? 0,
      bossTotal: (m['bossTotal'] as num?)?.toInt() ?? 0,
      quizCorrect: (m['quizCorrect'] as num?)?.toInt() ?? 0,
      quizTotal: (m['quizTotal'] as num?)?.toInt() ?? 0,
      justCleared: m['justCleared'] as bool? ?? false,
      nextUnlockedPackId: m['nextUnlockedPackId'] as String?,
    );
  }

  bool get _cleared => bossAccuracy >= PackProgressService.bossClearThreshold;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = VocabPackService.displayLabel(packId);
    final motif = motifForPackId(packId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.vocabPackResultTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                const SizedBox(height: Spacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                // Hero: 클리어 시 호랑이+까치가 단청 도장을 함께 둘러싸는 축하,
                //       미클리어 시 격려 마스코트.
                _cleared
                    ? _CelebrationSequence(
                        motif: motif,
                        justCleared: justCleared,
                      )
                    : const SoriEntrance(
                        child: SizedBox(
                          height: 160,
                          child: Center(
                            child: Mascot(
                              kind: MascotKind.tiger,
                              emotion: MascotEmotion.worry,
                              size: 130,
                            ),
                          ),
                        ),
                      ),
                if (_cleared) ...[
                  const SizedBox(height: Spacing.md),
                  SoriEntrance(
                    delay: const Duration(milliseconds: 700),
                    child: Text(
                      t.vocabPackResultGeschafft,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).h3.copyWith(
                        color: SoriColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                // Stats card
                SoriEntrance(
                  delay: Duration(milliseconds: _cleared ? 780 : 120),
                  child: SoriCard(
                    variant: SoriCardVariant.hero,
                    accent: _cleared ? SoriColors.success : SoriColors.warning,
                    tinted: true,
                    child: Column(
                      children: [
                        Text(
                          _cleared
                              ? (justCleared
                                    ? t.vocabPackResultCleared
                                    : t.vocabPackResultClearedAgain)
                              : t.vocabPackResultRetry,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: s.text,
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        _StatLine(
                          icon: Icons.bolt,
                          label: t.vocabPackResultBossLabel,
                          value:
                              '$bossCorrect / $bossTotal '
                              '(${(bossAccuracy * 100).round()}%)',
                        ),
                        if (quizTotal > 0)
                          _StatLine(
                            icon: Icons.quiz_outlined,
                            label: t.vocabPackResultQuizLabel,
                            value: '$quizCorrect / $quizTotal',
                          ),
                        if (_cleared)
                          _XpPayoffLine(
                            label: t.vocabPackResultXpLabel,
                            xp: _xpAwarded(),
                          )
                        else
                          _StatLine(
                            icon: Icons.workspace_premium_outlined,
                            label: t.vocabPackResultXpLabel,
                            value: '+${_xpAwarded()} XP',
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_cleared && nextUnlockedPackId != null)
                  SoriEntrance(
                    delay: const Duration(milliseconds: 920),
                    child: _CtaButton(
                      label: t.vocabPackResultNextPack(
                        VocabPackService.displayLabel(nextUnlockedPackId!),
                      ),
                      icon: Icons.arrow_forward_rounded,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.success,
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        '/vocab/pack',
                        arguments: nextUnlockedPackId,
                      ),
                    ),
                  ),
                if (!_cleared)
                  SoriEntrance(
                    delay: const Duration(milliseconds: 200),
                    child: _CtaButton(
                      label: t.vocabPackResultRetryCta,
                      icon: Icons.refresh_rounded,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.warning,
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed('/vocab/pack', arguments: packId),
                    ),
                  ),
                const SizedBox(height: Spacing.sm),
                SoriEntrance(
                  delay: Duration(milliseconds: _cleared ? 1000 : 280),
                  child: _CtaButton(
                    label: t.vocabPackResultBackToGrid,
                    icon: Icons.grid_view_rounded,
                    variant: SoriButtonVariant.outlined,
                    accent: SoriColors.info,
                    onTap: () => Navigator.of(
                      context,
                    ).popUntil((r) => r.settings.name == '/vocab' || r.isFirst),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _xpAwarded() {
    // Plan §4.4: wordsTotal*5 + bossCorrect*10. wordsTotal unbekannt im
    // Result-Screen — approx via quizTotal + bossTotal.
    final wordsTotal = quizTotal + bossTotal;
    return wordsTotal * 5 + bossCorrect * 10;
  }
}

class _StatLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: s.textMuted),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: s.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// 클리어 축하 hero — 호랑이·까치가 단청 도장(보상)을 함께 둘러싸며 등장.
// 단일 컨트롤러가 글로우→도장→호랑이→까치를 한 박자로 구동하고,
// 도장 착지 순간 confetti 1회. reduce-motion / 재클리어 시 최종 정지 프레임.
class _CelebrationSequence extends StatefulWidget {
  final DancheongMotif motif;
  final bool justCleared;
  const _CelebrationSequence({required this.motif, required this.justCleared});

  @override
  State<_CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<_CelebrationSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;
  late final Animation<double> _stampIn;
  late final Animation<double> _tigerIn;
  late final Animation<double> _magpieIn;
  bool _burstFired = false;
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _glow = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _stampIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.20, 0.80, curve: Curves.elasticOut),
    );
    _tigerIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.12, 0.85, curve: Curves.elasticOut),
    );
    _magpieIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 1.0, curve: Curves.elasticOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kicked) {
      return;
    }
    _kicked = true;
    // reduce-motion 또는 재클리어(이미 클리어한 팩) → 최종 프레임, confetti 억제.
    if (SoriMotion.reduceMotion(context) || !widget.justCleared) {
      _ctrl.value = 1.0;
      _burstFired = true;
    } else {
      _ctrl.addListener(_maybeBurst);
      _ctrl.forward();
    }
  }

  // 도장 착지(~55%) 순간 단청 confetti 1회 — 도장 중심에서.
  void _maybeBurst() {
    if (_burstFired || _ctrl.value < 0.55) {
      return;
    }
    _burstFired = true;
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    Offset? origin;
    if (box != null && box.hasSize) {
      origin = box.localToGlobal(box.size.center(Offset.zero));
    }
    SoriCelebration.burst(context, origin: origin, particles: 34);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_maybeBurst);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // (1) 바닥 글로우 — 마스코트가 떠 있지 않게 그라운딩.
              Positioned(
                bottom: 14,
                child: Opacity(
                  opacity: (_glow.value * 0.9).clamp(0.0, 1.0),
                  child: Container(
                    width: 190,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          SoriColors.gold.withValues(alpha: 0.32),
                          SoriColors.gold.withValues(alpha: 0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              // (3) 호랑이 — 왼쪽 바깥, 도장을 향해, 바닥에 grounding. (더 옆으로)
              Positioned(
                left: -8,
                bottom: 8,
                child: Opacity(
                  opacity: _tigerIn.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (0.5 + 0.5 * _tigerIn.value).clamp(0.0, 1.2),
                    alignment: Alignment.bottomCenter,
                    child: const Mascot(
                      kind: MascotKind.tiger,
                      emotion: MascotEmotion.celebrate,
                      size: 96,
                      animate: true,
                    ),
                  ),
                ),
              ),
              // (4) 까치 — 오른쪽 바깥, 살짝 띄워서, 약간 늦게. (더 옆으로)
              Positioned(
                right: -8,
                top: 6,
                child: Opacity(
                  opacity: _magpieIn.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (0.5 + 0.5 * _magpieIn.value).clamp(0.0, 1.2),
                    alignment: Alignment.bottomCenter,
                    child: const Mascot(
                      kind: MascotKind.magpie,
                      emotion: MascotEmotion.celebrate,
                      size: 72,
                      animate: true,
                    ),
                  ),
                ),
              ),
              // (2) 단청 도장 = 중앙 주인공(보상), 마스코트 위에 앞에 배치.
              Opacity(
                opacity: _stampIn.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: (0.6 + 0.4 * _stampIn.value).clamp(0.0, 1.3),
                  child: DancheongStamp(
                    motif: widget.motif,
                    size: 118,
                    animate: false,
                    stamped: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 클리어 시 XP payoff — 숫자 카운트업 + gold 채움 바로 보상감 강화.
class _XpPayoffLine extends StatelessWidget {
  final int xp;
  final String label;
  const _XpPayoffLine({required this.label, required this.xp});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final reduce = SoriMotion.reduceMotion(context);
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 900);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 18,
                color: s.textMuted,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: s.textMuted),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduce ? 1.0 : 0.0, end: 1.0),
                duration: dur,
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Text(
                  '+${(xp * t).round()} XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: reduce ? 1.0 : 0.0, end: 1.0),
            duration: dur,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) =>
                SoriProgressBar(value: t, thickness: 8, color: SoriColors.gold),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final SoriButtonVariant variant;
  final Color accent;
  final VoidCallback onTap;
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SoriButton(
        label: label,
        icon: icon,
        variant: variant,
        accent: accent,
        fullWidth: true,
        onTap: onTap,
      ),
    );
  }
}
