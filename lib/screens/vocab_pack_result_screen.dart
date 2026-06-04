import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/pack_progress_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/mascot.dart';
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

  bool get _cleared =>
      bossAccuracy >= PackProgressService.bossClearThreshold;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = VocabPackService.displayLabel(packId);
    final motif = motifForPackId(packId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.vocabPackResultTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
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
              // Hero: 도장 (cleared) 또는 마스코트 (else) — P0: 3단 시퀀스 진입
              _cleared
                  ? _CelebrationSequence(
                      motif: motif,
                      justCleared: justCleared,
                    )
                  : SizedBox(
                      height: 160,
                      child: Center(
                        child: const Mascot(
                          kind: MascotKind.tiger,
                          emotion: MascotEmotion.worry,
                          size: 130,
                        ),
                      ),
                    ),
              const SizedBox(height: Spacing.lg),
              // Stats card
              SoriCard(
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
                      value: '$bossCorrect / $bossTotal '
                          '(${(bossAccuracy * 100).round()}%)',
                    ),
                    if (quizTotal > 0)
                      _StatLine(
                        icon: Icons.quiz_outlined,
                        label: t.vocabPackResultQuizLabel,
                        value: '$quizCorrect / $quizTotal',
                      ),
                    _StatLine(
                      icon: Icons.workspace_premium_outlined,
                      label: t.vocabPackResultXpLabel,
                      value: '+${_xpAwarded()} XP',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_cleared && nextUnlockedPackId != null)
                _CtaButton(
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
              if (!_cleared)
                _CtaButton(
                  label: t.vocabPackResultRetryCta,
                  icon: Icons.refresh_rounded,
                  variant: SoriButtonVariant.filled,
                  accent: SoriColors.warning,
                  onTap: () => Navigator.of(context).pushReplacementNamed(
                    '/vocab/pack',
                    arguments: packId,
                  ),
                ),
              const SizedBox(height: Spacing.sm),
              _CtaButton(
                label: t.vocabPackResultBackToGrid,
                icon: Icons.grid_view_rounded,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.info,
                onTap: () => Navigator.of(context).popUntil(
                  (r) => r.settings.name == '/vocab' || r.isFirst,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// P0: G3 3단 시퀀스 (호랑이+까치 박수 → XP bar fill 애니메이션)
class _CelebrationSequence extends StatefulWidget {
  final DancheongMotif motif;
  final bool justCleared;
  const _CelebrationSequence({
    required this.motif,
    required this.justCleared,
  });

  @override
  State<_CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<_CelebrationSequence>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _phase = 0; // 0=마스코트, 1=도장

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _playSequence();
  }

  Future<void> _playSequence() async {
    if (!mounted) return;
    // Phase 1: 호랑이+까치 박수 (1.5s)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phase = 0);
    await Future.delayed(const Duration(seconds: 1500));
    // Phase 2: 도장 전환 + 스탬프 애니메이션
    if (!mounted) return;
    setState(() => _phase = 1);
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _phase == 0
              ? _MascotsApplaud(key: const ValueKey(0))
              : DancheongStamp(
                  key: const ValueKey(1),
                  motif: widget.motif,
                  size: 140,
                  animate: widget.justCleared,
                  stamped: true,
                ),
        ),
      ),
    );
  }
}

// 호랑이+까치 박수 포즈
class _MascotsApplaud extends StatelessWidget {
  const _MascotsApplaud({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          child: Mascot(
            kind: MascotKind.tiger,
            emotion: MascotEmotion.celebrate,
            size: 100,
            animate: true,
          ),
        ),
        Positioned(
          right: 0,
          child: Mascot(
            kind: MascotKind.magpie,
            emotion: MascotEmotion.celebrate,
            size: 90,
            animate: true,
          ),
        ),
      ],
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
