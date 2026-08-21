import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/content_feedback.dart';
import '../models/course_practice_context.dart';
import '../services/pack_progress_service.dart';
import '../services/pack_session_srs_ledger.dart';
import '../services/course_mission_navigation.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

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
///   - `completionId`: String
///   - `packLevel`: String
///   - `feedbackContext`: ContentFeedbackContext
///   - `showHardWordsCta`: bool (this session has a threshold-reaching miss)
///   - `recallSession`: a typed, ephemeral pack-session evidence ledger
class VocabPackResultScreen extends StatelessWidget {
  final String packId;
  final double bossAccuracy;
  final int bossCorrect;
  final int bossTotal;
  final int quizCorrect;
  final int quizTotal;
  final bool justCleared;
  final String? nextUnlockedPackId;
  final String? completionId;
  final String? packLevel;
  final ContentFeedbackContext? feedbackContext;
  final CoursePracticeContext? courseContext;
  final bool showHardWordsCta;
  final PackRecallSession? recallSession;

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
    this.completionId,
    this.packLevel,
    this.feedbackContext,
    this.courseContext,
    this.showHardWordsCta = false,
    this.recallSession,
  });

  /// Factory aus Navigator-args. Falls Map fehlt → defaults.
  factory VocabPackResultScreen.fromArgs(Object? args) {
    final m = (args is Map) ? args : const <String, dynamic>{};
    final rawCourseContext = m['courseContext'];
    final packId = m['packId'] as String? ?? '';
    return VocabPackResultScreen(
      packId: packId,
      bossAccuracy: (m['bossAccuracy'] as num?)?.toDouble() ?? 0.0,
      bossCorrect: (m['bossCorrect'] as num?)?.toInt() ?? 0,
      bossTotal: (m['bossTotal'] as num?)?.toInt() ?? 0,
      quizCorrect: (m['quizCorrect'] as num?)?.toInt() ?? 0,
      quizTotal: (m['quizTotal'] as num?)?.toInt() ?? 0,
      justCleared: m['justCleared'] as bool? ?? false,
      nextUnlockedPackId: m['nextUnlockedPackId'] as String?,
      completionId: m['completionId'] as String?,
      packLevel: m['packLevel'] as String?,
      feedbackContext: m['feedbackContext'] as ContentFeedbackContext?,
      courseContext: rawCourseContext is CoursePracticeContext
          ? rawCourseContext
          : null,
      showHardWordsCta: m['showHardWordsCta'] as bool? ?? false,
      recallSession: PackRecallSession.fromRouteArgument(
        m['recallSession'],
        expectedPackId: packId,
      ),
    );
  }

  bool get _cleared => bossAccuracy >= PackProgressService.bossClearThreshold;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = VocabPackService.displayLabel(packId, lang: lang);
    final motif = motifForPackId(packId);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);

    return SoriStudyFrame(
      title: t.vocabPackResultTitle,
      automaticallyImplyLeading: false,
      // 짧은 결과 콘텐츠가 태블릿 상단에 쏠려 아래가 텅 비지 않도록,
      // 세로 중앙 정렬 + 넘치면 스크롤(작은 폰·큰 글자 안전). 폰 무변화.
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.md),
                Semantics(
                  key: const Key('vocab-result-pack-title'),
                  header: true,
                  child: Text(title, textAlign: TextAlign.center, style: tt.h3),
                ),
                const SizedBox(height: Spacing.lg),
                // Hero: 클리어 시 호랑이+까치가 단청 도장을 함께 둘러싸는 축하,
                //       미클리어 시 격려 마스코트.
                _cleared
                    ? _CelebrationSequence(
                        motif: motif,
                        justCleared: justCleared,
                        mascotKind: MascotPreference.selectedKind,
                      )
                    : SoriEntrance(
                        child: SizedBox(
                          height: 160,
                          child: Center(
                            child: CompanionBuilder(
                              builder: (context, kind) => Mascot(
                                kind: kind,
                                emotion: MascotEmotion.worry,
                                size: 130,
                              ),
                              noneBuilder: (context) => const Icon(
                                Icons.insights_rounded,
                                size: 104,
                                color: SoriColors.warning,
                              ),
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
                      style: tt.h3.copyWith(color: SoriColors.success),
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
                        Semantics(
                          header: true,
                          child: Text(
                            _cleared
                                ? (justCleared
                                      ? t.vocabPackResultCleared
                                      : t.vocabPackResultClearedAgain)
                                : t.vocabPackResultRetry,
                            textAlign: TextAlign.center,
                            style: tt.h2,
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
                if (feedbackContext != null &&
                    feedbackScope != null &&
                    feedbackScope.featureGate.isEnabled) ...[
                  const SizedBox(height: Spacing.xl),
                  ContentFeedbackCard(
                    feedbackContext: feedbackContext!,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                    completedMissionIds: feedbackScope.completedMissionIds,
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                if (_cleared && nextUnlockedPackId != null)
                  SoriEntrance(
                    delay: const Duration(milliseconds: 920),
                    child: _CtaButton(
                      label: t.vocabPackResultNextPack(
                        VocabPackService.displayLabel(
                          nextUnlockedPackId!,
                          lang: lang,
                        ),
                      ),
                      icon: Icons.arrow_forward_rounded,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.success,
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        '/vocab/pack',
                        arguments: vocabPackRouteArguments(
                          packId: nextUnlockedPackId!,
                        ),
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
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        '/vocab/pack',
                        arguments: vocabPackRouteArguments(
                          packId: packId,
                          courseContext: courseContext,
                        ),
                      ),
                    ),
                  ),
                if (bossTotal > 0) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriEntrance(
                    delay: Duration(milliseconds: _cleared ? 960 : 240),
                    child: _CtaButton(
                      label: t.vocabPackResultRecallCta,
                      icon: Icons.keyboard_alt_outlined,
                      variant: SoriButtonVariant.outlined,
                      accent: SoriColors.accent,
                      onTap: () => Navigator.of(context).pushNamed(
                        '/vocab/recall',
                        arguments: <String, dynamic>{
                          'packId': packId,
                          'recallSession': recallSession,
                        },
                      ),
                    ),
                  ),
                ],
                if (showHardWordsCta) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriEntrance(
                    delay: Duration(milliseconds: _cleared ? 980 : 260),
                    child: _CtaButton(
                      label: t.vocabPackResultHardWordsCta,
                      icon: Icons.bolt_rounded,
                      variant: SoriButtonVariant.outlined,
                      accent: SoriColors.danger,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/hard_words'),
                    ),
                  ),
                ],
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
    final tt = SoriTextTheme.of(context);
    return Semantics(
      key: ValueKey<String>('vocab-result-metric-$label'),
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stack =
              textScale >= 1.6 ||
              constraints.maxWidth < SoriAdaptiveWidth.labelValueRow;
          final labelRow = Row(
            children: [
              Icon(icon, size: 18, color: s.textMuted),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(label, style: tt.caption)),
            ],
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      labelRow,
                      const SizedBox(height: Spacing.xs),
                      Text(value, textAlign: TextAlign.end, style: tt.label),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: labelRow),
                      const SizedBox(width: Spacing.md),
                      Text(value, style: tt.label),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// 클리어 축하 hero — **선택된 캐릭터 하나**가 획득한 단청 도장(보상) 옆에서
// 축하한다. (구버전은 호랑이+까치를 둘 다 띄워 "캐릭터가 난립"했다 — Jin
// 실기기 피드백. 이제 MascotPreference 의 선택 캐릭터 + 도장만 보인다.)
// 단일 컨트롤러가 도장→캐릭터를 한 박자로 구동하고, 도장 착지 순간
// confetti 1회. reduce-motion / 재클리어 시 최종 정지 프레임.
class _CelebrationSequence extends StatefulWidget {
  final DancheongMotif motif;
  final bool justCleared;
  final MascotKind? mascotKind;
  const _CelebrationSequence({
    required this.motif,
    required this.justCleared,
    required this.mascotKind,
  });

  @override
  State<_CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<_CelebrationSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _stampIn;
  late final Animation<double> _mascotIn;
  bool _burstFired = false;
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _stampIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.80, curve: Curves.elasticOut),
    );
    _mascotIn = CurvedAnimation(
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
    // 선택된 캐릭터 하나 + 획득한 도장만. 도장이 보상의 주인공이라 크게,
    // 선택 캐릭터가 그 옆에서 축하한다. Row 로 가운데 정렬해 두 요소가
    // 겹치거나 한쪽으로 쏠리지 않게 한다.
    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 선택된 캐릭터 — MascotPreference 기준(호랑이/까치). 하드코딩 금지.
              if (widget.mascotKind case final kind?) ...[
                Opacity(
                  opacity: _mascotIn.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (0.5 + 0.5 * _mascotIn.value).clamp(0.0, 1.2),
                    child: Mascot(
                      kind: kind,
                      emotion: MascotEmotion.celebrate,
                      size: 92,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
              ],
              // 획득한 단청 도장 = 보상의 주인공.
              Opacity(
                opacity: _stampIn.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: (0.6 + 0.4 * _stampIn.value).clamp(0.0, 1.3),
                  child: Semantics(
                    image: true,
                    label: dancheongMotifName(
                      AppL10n.of(context),
                      widget.motif,
                    ),
                    excludeSemantics: true,
                    child: DancheongStamp(
                      motif: widget.motif,
                      size: 120,
                      animate: false,
                      stamped: true,
                    ),
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
    final tt = SoriTextTheme.of(context);
    final reduce = SoriMotion.reduceMotion(context);
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 900);
    return Semantics(
      key: const Key('vocab-result-xp'),
      container: true,
      label: '$label: +$xp XP',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
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
                Expanded(child: Text(label, style: tt.caption)),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: reduce ? 1.0 : 0.0, end: 1.0),
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => Text(
                    '+${(xp * t).round()} XP',
                    style: tt.h3.copyWith(color: SoriColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: reduce ? 1.0 : 0.0, end: 1.0),
              duration: dur,
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => SoriProgressBar(
                value: t,
                thickness: 8,
                color: SoriColors.gold,
              ),
            ),
          ],
        ),
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
