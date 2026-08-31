import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;

import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../features/onboarding_v2/onboarding_story_catalog_projector.dart';
import '../../models/curriculum_alignment_contract.dart';
import '../../models/heritage_journey_contract.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/chip.dart';
import '../../widgets/sori/external_link.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';
import 'onboarding_v2_stage.dart';

/// Mandatory five-page product story.
///
/// [pageIndex] is coordinator-driven rather than owned by this widget. This
/// makes a restored persisted page render directly without replaying earlier
/// pages or mutating service data during a preview.
class OnboardingStoryScreen extends StatefulWidget {
  const OnboardingStoryScreen({
    super.key,
    required this.copy,
    required this.pageIndex,
    required this.onContinue,
    required this.onPrevious,
    this.curriculumEvidenceProjector,
    this.rewardCatalogProjector,
    this.heritageCatalogProjector,
  }) : assert(pageIndex >= 0);

  final OnboardingV2Copy copy;
  final int pageIndex;
  final ValueChanged<String> onContinue;
  final ValueChanged<String> onPrevious;
  final OnboardingCurriculumEvidenceProjection? Function()?
  curriculumEvidenceProjector;
  final OnboardingCatalogProjectionResult<OnboardingRewardCatalogProjection>
  Function()?
  rewardCatalogProjector;
  final OnboardingCatalogProjectionResult<OnboardingHeritageCatalogProjection>
  Function()?
  heritageCatalogProjector;

  @override
  State<OnboardingStoryScreen> createState() => _OnboardingStoryScreenState();
}

class _OnboardingStoryScreenState extends State<OnboardingStoryScreen> {
  int _jamoStage = 0;
  bool _cardFlipped = false;
  bool _questComplete = false;

  @override
  void didUpdateWidget(covariant OnboardingStoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      _jamoStage = 0;
      _cardFlipped = false;
      _questComplete = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final pageIndex = widget.pageIndex;
    assert(copy.storyPages.length == 5);
    assert(pageIndex < copy.storyPages.length);
    final page = copy.storyPages[pageIndex];
    final isLast = pageIndex == copy.storyPages.length - 1;
    final curriculumEvidence = page.curriculumEvidenceCopy == null
        ? null
        : (widget.curriculumEvidenceProjector ??
              () => OnboardingCurriculumEvidenceProjector.project())();
    final rewardProjection = page.rewardCatalogCopy == null
        ? null
        : (widget.rewardCatalogProjector ??
                  () => OnboardingStoryCatalogProjector.projectRewards())()
              .projection;
    final heritageProjection = page.heritageCatalogCopy == null
        ? null
        : (widget.heritageCatalogProjector ??
                  () => OnboardingStoryCatalogProjector.projectIlduGotaek())()
              .projection;
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 220),
    );
    final progress = copy.navigation.progress(pageIndex + 1, 7);

    return OnboardingV2PageShell(
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: pageIndex + 1,
      totalSteps: 7,
      progressLabel: progress,
      stageKey: ValueKey('onboarding-v2-stage-${page.id}-$_questComplete'),
      stage: OnboardingStoryStage(page: page, questComplete: _questComplete),
      // A different scroll identity per mandatory page prevents a long page
      // from handing its old offset to the next explanation.
      bodyKey: ValueKey('onboarding-v2-story-scroll-${page.id}'),
      body: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Column(
          key: ValueKey(page.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingV2Heading(
              key: ValueKey('onboarding-v2-heading-${page.id}'),
              titleKey: const ValueKey('onboarding-v2-story-title'),
              eyebrow: page.eyebrow,
              title: page.title,
              body: page.body,
              announcementLabel: '$progress. ${page.title}',
            ),
            const SizedBox(height: Spacing.xl),
            _StoryInteraction(
              page: page,
              setup: copy.setup,
              syllableGa: copy.syllableGa,
              jamoStage: _jamoStage,
              onAdvanceJamo: () {
                if (_jamoStage < 2) {
                  setState(() => _jamoStage += 1);
                }
              },
              cardFlipped: _cardFlipped,
              onToggleCard: () {
                setState(() => _cardFlipped = !_cardFlipped);
              },
              questComplete: _questComplete,
              onCompleteQuest: () {
                if (!_questComplete) {
                  setState(() => _questComplete = true);
                }
              },
              curriculumEvidence: curriculumEvidence,
              rewardProjection: rewardProjection,
              heritageProjection: heritageProjection,
            ),
          ],
        ),
      ),
      footer: _StoryFooter(
        backLabel: copy.navigation.back,
        nextLabel: isLast ? copy.navigation.finishStory : copy.navigation.next,
        onBack: pageIndex == 0 ? null : () => widget.onPrevious(page.id),
        onNext: () => widget.onContinue(page.id),
      ),
    );
  }
}

class _StoryFooter extends StatelessWidget {
  const _StoryFooter({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final back = SoriButton.outlined(
          key: const ValueKey('onboarding-v2-story-back'),
          label: backLabel,
          fullWidth: true,
          maxLines: 1,
          onTap: onBack,
        );
        final next = SoriButton.filled(
          key: const ValueKey('onboarding-v2-story-next'),
          label: nextLabel,
          trailingIcon: Icons.arrow_forward_rounded,
          fullWidth: true,
          maxLines: 1,
          onTap: onNext,
        );
        if (constraints.maxWidth < SoriBreakpoints.contentActionStack) {
          return Column(
            children: [
              next,
              const SizedBox(height: Spacing.sm),
              back,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: back),
            const SizedBox(width: Spacing.md),
            Expanded(flex: 6, child: next),
          ],
        );
      },
    );
  }
}

class _StoryInteraction extends StatelessWidget {
  const _StoryInteraction({
    required this.page,
    required this.setup,
    required this.syllableGa,
    required this.jamoStage,
    required this.onAdvanceJamo,
    required this.cardFlipped,
    required this.onToggleCard,
    required this.questComplete,
    required this.onCompleteQuest,
    required this.curriculumEvidence,
    required this.rewardProjection,
    required this.heritageProjection,
  });

  final OnboardingStoryPageSpec page;
  final OnboardingSetupCopy setup;
  final String syllableGa;
  final int jamoStage;
  final VoidCallback onAdvanceJamo;
  final bool cardFlipped;
  final VoidCallback onToggleCard;
  final bool questComplete;
  final VoidCallback onCompleteQuest;
  final OnboardingCurriculumEvidenceProjection? curriculumEvidence;
  final OnboardingRewardCatalogProjection? rewardProjection;
  final OnboardingHeritageCatalogProjection? heritageProjection;

  @override
  Widget build(BuildContext context) {
    return switch (page.visualKind) {
      OnboardingStoryVisualKind.personalCurriculum => _LearningPathPreview(
        page: page,
        setup: setup,
        curriculumEvidence: curriculumEvidence,
      ),
      OnboardingStoryVisualKind.learn => _JamoComposer(
        page: page,
        syllableGa: syllableGa,
        stage: jamoStage,
        onTap: onAdvanceJamo,
      ),
      OnboardingStoryVisualKind.saveAndReview => _FlipReviewPreview(
        page: page,
        flipped: cardFlipped,
        onTap: onToggleCard,
        korean: setup.levels.first.exampleKorean,
        translation: setup.levels.first.exampleTranslation,
      ),
      OnboardingStoryVisualKind.gamesAndRewards => _QuestPreview(
        page: page,
        complete: questComplete,
        onTap: onCompleteQuest,
        projection: rewardProjection,
      ),
      OnboardingStoryVisualKind.heritageJourney => _HeritageJourneyPreview(
        page: page,
        projection: heritageProjection,
      ),
    };
  }
}

class _LearningPathPreview extends StatelessWidget {
  const _LearningPathPreview({
    required this.page,
    required this.setup,
    required this.curriculumEvidence,
  });

  final OnboardingStoryPageSpec page;
  final OnboardingSetupCopy setup;
  final OnboardingCurriculumEvidenceProjection? curriculumEvidence;

  @override
  Widget build(BuildContext context) {
    final levels = [setup.levels.first, setup.levels[1], setup.levels.last];
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      key: const ValueKey('onboarding-v2-story-hero'),
      container: true,
      label: page.heroSemanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (final (index, level) in levels.indexed) ...[
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Text(level.code, style: SoriTextTheme.of(context).h3),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          level.name,
                          textAlign: TextAlign.center,
                          style: SoriTextTheme.of(context).meta,
                        ),
                      ],
                    ),
                  ),
                  if (index < levels.length - 1) ...[
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      flex: 2,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Divider(color: surfaces.border),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: SoriColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: Spacing.sm,
                              height: Spacing.sm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                ],
              ],
            ),
          ),
          if (page.statusLabel != null) ...[
            const SizedBox(height: Spacing.md),
            _StatusNote(label: page.statusLabel!, accent: SoriColors.primary),
          ],
          if (curriculumEvidence != null) ...[
            const SizedBox(height: Spacing.lg),
            _CurriculumEvidencePreview(
              copy: page.curriculumEvidenceCopy!,
              projection: curriculumEvidence!,
              accent: SoriColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _JamoComposer extends StatelessWidget {
  const _JamoComposer({
    required this.page,
    required this.syllableGa,
    required this.stage,
    required this.onTap,
  });

  final OnboardingStoryPageSpec page;
  final String syllableGa;
  final int stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final activeFirst = stage >= 1;
    final complete = stage >= 2;
    return Semantics(
      key: const ValueKey('onboarding-v2-story-hero'),
      button: true,
      label: page.heroSemanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: surfaces.bg,
        shape: RoundedRectangleBorder(
          borderRadius: SoriRadius.brMd,
          side: BorderSide(color: surfaces.border),
        ),
        child: SoriPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _JamoTile(
                        korean: 'ㄱ',
                        romanization: 'g',
                        active: activeFirst,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
                      child: Text('+'),
                    ),
                    Expanded(
                      child: _JamoTile(
                        korean: 'ㅏ',
                        romanization: 'a',
                        active: complete,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
                      child: Text('='),
                    ),
                    Expanded(
                      child: _JamoTile(
                        korean: complete ? syllableGa : '?',
                        romanization: complete ? 'ga' : '',
                        active: complete,
                        result: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Icon(
                      complete
                          ? Icons.volume_up_rounded
                          : Icons.touch_app_outlined,
                      size: 20,
                      color: complete ? SoriColors.primary : surfaces.textMuted,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        complete
                            ? '${page.highlights[2].title} · '
                                  '$syllableGa · ga'
                            : page.highlights[stage].body,
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JamoTile extends StatelessWidget {
  const _JamoTile({
    required this.korean,
    required this.romanization,
    required this.active,
    this.result = false,
  });

  final String korean;
  final String romanization;
  final bool active;
  final bool result;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final fill = result && active
        ? SoriColors.primaryDark
        : active
        ? SoriColors.primarySoft
        : SoriCard.resolvedBackground(context);
    final foreground = result && active
        ? Colors.white
        : active
        ? SoriColors.primaryDark
        : surfaces.textMuted;
    return AnimatedContainer(
      duration: SoriMotion.respect(context, const Duration(milliseconds: 220)),
      constraints: const BoxConstraints(minHeight: 66),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: SoriRadius.brSm,
        border: Border.all(
          color: active ? SoriColors.primary : surfaces.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            korean,
            locale: const Locale('ko'),
            style: SoriTextTheme.of(
              context,
            ).koDisplay.copyWith(color: foreground, fontSize: 27),
          ),
          if (romanization.isNotEmpty)
            Text(
              romanization,
              style: SoriTextTheme.of(context).meta.copyWith(color: foreground),
            ),
        ],
      ),
    );
  }
}

class _FlipReviewPreview extends StatelessWidget {
  const _FlipReviewPreview({
    required this.page,
    required this.flipped,
    required this.onTap,
    required this.korean,
    required this.translation,
  });

  final OnboardingStoryPageSpec page;
  final bool flipped;
  final VoidCallback onTap;
  final String korean;
  final String translation;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          key: const ValueKey('onboarding-v2-story-hero'),
          button: true,
          label: page.heroSemanticLabel,
          onTap: onTap,
          excludeSemantics: true,
          child: Material(
            color: surfaces.bg,
            shape: RoundedRectangleBorder(
              borderRadius: SoriRadius.brMd,
              side: BorderSide(
                color: flipped ? SoriColors.gold : SoriColors.primary,
              ),
            ),
            child: SoriPressable(
              onTap: onTap,
              child: AnimatedSwitcher(
                duration: SoriMotion.respect(
                  context,
                  const Duration(milliseconds: 360),
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: ConstrainedBox(
                  key: ValueKey(flipped),
                  constraints: const BoxConstraints(minHeight: 132),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          flipped ? page.highlights[0].title : page.eyebrow,
                          textAlign: TextAlign.center,
                          style: SoriTextTheme.of(
                            context,
                          ).meta.copyWith(color: SoriColors.accent),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          flipped ? translation : korean,
                          locale: flipped ? null : const Locale('ko'),
                          textAlign: TextAlign.center,
                          style: SoriTextTheme.of(context).koDisplay,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          flipped ? korean : page.highlights[0].body,
                          locale: flipped ? const Locale('ko') : null,
                          textAlign: TextAlign.center,
                          style: SoriTextTheme.of(context).meta,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Row(
          children: [
            for (final (index, days) in const ['1', '3', '7', '30'].indexed)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      color: index == 0 ? SoriColors.primary : surfaces.border,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(days, style: SoriTextTheme.of(context).meta),
                  ],
                ),
              ),
          ],
        ),
        if (page.highlights.length >= 4) ...[
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MemoryMeaning(
                  icon: Icons.favorite_outline_rounded,
                  highlight: page.highlights[2],
                  accent: SoriColors.tigerOnLight,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _MemoryMeaning(
                  icon: Icons.bookmark_outline_rounded,
                  highlight: page.highlights[3],
                  accent: SoriColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
        if (page.statusLabel != null) ...[
          const SizedBox(height: Spacing.lg),
          _StatusNote(label: page.statusLabel!, accent: SoriColors.accent),
        ],
      ],
    );
  }
}

class _MemoryMeaning extends StatelessWidget {
  const _MemoryMeaning({
    required this.icon,
    required this.highlight,
    required this.accent,
  });

  final IconData icon;
  final OnboardingStoryHighlight highlight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.bg,
        borderRadius: SoriRadius.brSm,
        border: Border.all(color: surfaces.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: accent),
            const SizedBox(height: Spacing.xs),
            Text(highlight.title, style: SoriTextTheme.of(context).meta),
            const SizedBox(height: Spacing.xs),
            Text(highlight.body, style: SoriTextTheme.of(context).bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuestPreview extends StatelessWidget {
  const _QuestPreview({
    required this.page,
    required this.complete,
    required this.onTap,
    required this.projection,
  });

  final OnboardingStoryPageSpec page;
  final bool complete;
  final VoidCallback onTap;
  final OnboardingRewardCatalogProjection? projection;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          key: const ValueKey('onboarding-v2-story-hero'),
          button: true,
          label: page.heroSemanticLabel,
          onTap: onTap,
          excludeSemantics: true,
          child: Material(
            color: surfaces.bg,
            shape: RoundedRectangleBorder(
              borderRadius: SoriRadius.brMd,
              side: BorderSide(color: surfaces.border),
            ),
            child: SoriPressable(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: complete
                            ? SoriColors.primary
                            : SoriColors.gold.withValues(alpha: 0.18),
                        borderRadius: SoriRadius.brSm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Icon(
                          complete
                              ? Icons.check_rounded
                              : Icons.emoji_events_rounded,
                          color: complete
                              ? Colors.white
                              : SoriColors.goldOnLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.highlights.first.title,
                            style: SoriTextTheme.of(context).meta,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            page.highlights.first.body,
                            style: SoriTextTheme.of(context).cardTitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      complete ? '+25 XP' : '25 XP',
                      style: SoriTextTheme.of(
                        context,
                      ).label.copyWith(color: SoriColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Semantics(
          key: const ValueKey('onboarding-v2-quest-xp-progress'),
          value: complete ? '100' : '68',
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: SoriRadius.brPill,
              child: LinearProgressIndicator(
                value: complete ? 1 : 0.68,
                minHeight: 7,
                color: SoriColors.primary,
                backgroundColor: surfaces.border,
              ),
            ),
          ),
        ),
        if (page.statusLabel != null) ...[
          const SizedBox(height: Spacing.md),
          _StatusNote(label: page.statusLabel!, accent: SoriColors.goldOnLight),
        ],
        if (projection != null) ...[
          const SizedBox(height: Spacing.lg),
          _RewardCatalogPreview(
            copy: page.rewardCatalogCopy!,
            projection: projection!,
            accent: SoriColors.goldOnLight,
          ),
        ],
      ],
    );
  }
}

class _HeritageJourneyPreview extends StatelessWidget {
  const _HeritageJourneyPreview({required this.page, required this.projection});

  final OnboardingStoryPageSpec page;
  final OnboardingHeritageCatalogProjection? projection;

  static const _chapters = [
    ('솟을대문', 'Sotdaeulmun', 'assets/illustrations/stamps/stamp_taegeuk.png'),
    ('사랑채', 'Sarangchae', 'assets/illustrations/stamps/stamp_plum.png'),
    ('안채', 'Anchae', 'assets/illustrations/stamps/stamp_mountain.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final heritageCopy = page.heritageCatalogCopy;
    final fallbackStatus = page.statusLabel ?? page.title;
    return Semantics(
      key: const ValueKey('onboarding-v2-story-hero'),
      container: true,
      label: projection == null || heritageCopy == null
          ? '${page.title}. $fallbackStatus'
          : page.heroSemanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: surfaces.border)),
              ),
              child: Column(
                children: [
                  for (final (index, chapter) in _chapters.indexed)
                    _ChapterRow(
                      korean: chapter.$1,
                      latin: chapter.$2,
                      status: page.highlights[index].title,
                      stampAsset: chapter.$3,
                      current: index == 0,
                      trailing: index == 0 ? heritageCopy?.previewLabel : null,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          if (projection != null && heritageCopy != null)
            _HeritageCatalogPreview(
              copy: heritageCopy,
              projection: projection!,
              accent: SoriColors.primaryDark,
            )
          else
            _StatusNote(
              label: heritageCopy?.inPreparationLabel ?? fallbackStatus,
              accent: SoriColors.primaryDark,
            ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.korean,
    required this.latin,
    required this.status,
    required this.stampAsset,
    required this.current,
    required this.trailing,
  });

  final String korean;
  final String latin;
  final String status;
  final String stampAsset;
  final bool current;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: surfaces.border)),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: current ? 1 : 0.48,
            child: Image.asset(
              stampAsset,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  korean,
                  locale: const Locale('ko'),
                  style: SoriTextTheme.of(
                    context,
                  ).cultureTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: Spacing.xs),
                Text('$latin · $status', style: SoriTextTheme.of(context).meta),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            Text(
              trailing!,
              style: SoriTextTheme.of(context).meta.copyWith(
                color: SoriColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 19, color: accent),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            label,
            key: const ValueKey('onboarding-v2-story-status'),
            style: SoriTextTheme.of(context).bodySmall.copyWith(color: accent),
          ),
        ),
      ],
    );
  }
}

class _CurriculumEvidencePreview extends StatelessWidget {
  const _CurriculumEvidencePreview({
    required this.copy,
    required this.projection,
    required this.accent,
  });

  final OnboardingCurriculumEvidenceCopy copy;
  final OnboardingCurriculumEvidenceProjection projection;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaces.surface,
          borderRadius: SoriRadius.brMd,
          border: Border.all(
            color: surfaces.brightness == Brightness.light
                ? SoriColors.lightBorderStrong
                : SoriColors.darkBorderStrong,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.claim,
                key: const ValueKey('onboarding-v2-curriculum-claim'),
                style: text.cardSubtitle,
              ),
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                key: const ValueKey('onboarding-v2-curriculum-sources'),
                label: copy.sourcesAction,
                fullWidth: true,
                onTap: () => _showCurriculumSources(
                  context,
                  copy: copy,
                  projection: projection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showCurriculumSources(
  BuildContext context, {
  required OnboardingCurriculumEvidenceCopy copy,
  required OnboardingCurriculumEvidenceProjection projection,
}) {
  return showOnboardingV2ModalWithFocusRestore(
    () => showSoriSheet<void>(
      context: context,
      maxTextScaleFactor: 2.0,
      builder: (sheetContext) {
        final text = SoriTextTheme.of(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              debugLabel: 'onboarding-v2-curriculum-sources-heading',
              autofocus: true,
              child: Semantics(
                header: true,
                focusable: true,
                excludeSemantics: true,
                child: Text(
                  copy.sourcesTitle,
                  key: const ValueKey('onboarding-v2-curriculum-sources-title'),
                  style: text.h2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(copy.sourcesBody, style: text.body),
            const SizedBox(height: Spacing.lg),
            for (final (index, source) in projection.references.indexed) ...[
              _CurriculumSourceCard(index: index, source: source, copy: copy),
              if (index < projection.references.length - 1)
                const SizedBox(height: Spacing.md),
            ],
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              key: const ValueKey('onboarding-v2-curriculum-sources-close'),
              label: copy.closeAction,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    ),
  );
}

class _CurriculumSourceCard extends StatelessWidget {
  const _CurriculumSourceCard({
    required this.index,
    required this.source,
    required this.copy,
  });

  final int index;
  final OfficialCurriculumReference source;
  final OnboardingCurriculumEvidenceCopy copy;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final openLabel = copy.openSourceBuilder(source.documentName);
    final titleLocale = source.authority == CurriculumAuthority.nikl
        ? const Locale('ko')
        : null;
    void openSource() => openExternalUrl(context, source.url.toString());

    return SoriCard(
      key: ValueKey('onboarding-v2-curriculum-source-$index'),
      variant: SoriCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _curriculumAuthorityLabel(source.authority, copy),
            style: text.cardTitle,
          ),
          const SizedBox(height: Spacing.md),
          _SourceField(
            label: copy.documentLabel,
            value: source.documentName,
            valueLocale: titleLocale,
          ),
          _SourceField(label: copy.versionLabel, value: source.documentVersion),
          _SourceField(label: copy.checkedAtLabel, value: source.checkedAtIso),
          Text(copy.urlLabel, style: text.meta),
          const SizedBox(height: Spacing.xs),
          SelectableText(
            source.url.toString(),
            key: ValueKey('onboarding-v2-curriculum-source-url-$index'),
            style: text.cardSubtitle.copyWith(
              color: surfaces.brightness == Brightness.light
                  ? SoriColors.primaryOnLight
                  : SoriColors.primaryOnDark,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            key: ValueKey('onboarding-v2-curriculum-source-open-$index'),
            button: true,
            enabled: true,
            attributedLabel: titleLocale == null
                ? AttributedString(openLabel)
                : _withKoreanLocale(openLabel, source.documentName),
            onTap: openSource,
            excludeSemantics: true,
            child: SoriButton.outlined(
              label: openLabel,
              fullWidth: true,
              onTap: openSource,
            ),
          ),
        ],
      ),
    );
  }
}

String _curriculumAuthorityLabel(
  CurriculumAuthority authority,
  OnboardingCurriculumEvidenceCopy copy,
) => switch (authority) {
  CurriculumAuthority.cefr => copy.cefrAuthorityLabel,
  CurriculumAuthority.nikl => copy.niklAuthorityLabel,
  CurriculumAuthority.topik => throw StateError(
    'TOPIK evidence is not permitted in the basic onboarding claim.',
  ),
};

class _RewardCatalogPreview extends StatelessWidget {
  const _RewardCatalogPreview({
    required this.copy,
    required this.projection,
    required this.accent,
  });

  final OnboardingRewardCatalogCopy copy;
  final OnboardingRewardCatalogProjection projection;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Semantics(
      key: const ValueKey('onboarding-v2-reward-catalog'),
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.title,
            key: const ValueKey('onboarding-v2-reward-catalog-title'),
            style: text.cardTitle,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            copy.bodyBuilder(projection.sourceCatalogEntryCount),
            key: const ValueKey('onboarding-v2-reward-catalog-body'),
            style: text.cardSubtitle,
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final example in projection.examples)
                SoriChip(
                  key: ValueKey('onboarding-v2-reward-${example.kind.name}'),
                  label: example.label.resolve(languageCode),
                  semanticLabel: copy.possibleRewardBuilder(
                    example.label.resolve(languageCode),
                  ),
                  icon: _rewardIcon(example.kind),
                  accent: accent,
                  variant: SoriChipVariant.outlined,
                  maxLines: null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeritageCatalogPreview extends StatelessWidget {
  const _HeritageCatalogPreview({
    required this.copy,
    required this.projection,
    required this.accent,
  });

  final OnboardingHeritageCatalogCopy copy;
  final OnboardingHeritageCatalogProjection projection;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.surface,
        borderRadius: SoriRadius.brMd,
        border: Border.all(
          color: surfaces.brightness == Brightness.light
              ? SoriColors.lightBorderStrong
              : SoriColors.darkBorderStrong,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projection.officialName,
              key: const ValueKey('onboarding-v2-heritage-official-name'),
              locale: const Locale('ko'),
              style: text.cardTitle,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${copy.previewLabel} · ${copy.inPreparationLabel}',
              key: const ValueKey('onboarding-v2-heritage-runtime-status'),
              style: text.label.copyWith(color: accent),
            ),
            const SizedBox(height: Spacing.sm),
            Text(copy.assetReviewNote, style: text.cardSubtitle),
            const SizedBox(height: Spacing.md),
            SoriButton.outlined(
              key: const ValueKey('onboarding-v2-heritage-sources'),
              label: copy.sourcesAction,
              fullWidth: true,
              onTap: () => _showHeritageSources(
                context,
                copy: copy,
                projection: projection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showHeritageSources(
  BuildContext context, {
  required OnboardingHeritageCatalogCopy copy,
  required OnboardingHeritageCatalogProjection projection,
}) {
  return showOnboardingV2ModalWithFocusRestore(
    () => showSoriSheet<void>(
      context: context,
      maxTextScaleFactor: 2.0,
      builder: (sheetContext) {
        final text = SoriTextTheme.of(sheetContext);
        final sourcesTitle = copy.sourcesTitleBuilder(projection.officialName);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              debugLabel: 'onboarding-v2-heritage-sources-heading',
              autofocus: true,
              child: Semantics(
                header: true,
                focusable: true,
                attributedLabel: _withKoreanLocale(
                  sourcesTitle,
                  projection.officialName,
                ),
                excludeSemantics: true,
                child: Text(
                  sourcesTitle,
                  key: const ValueKey('onboarding-v2-heritage-sources-title'),
                  style: text.h2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(copy.sourcesBody, style: text.body),
            const SizedBox(height: Spacing.lg),
            for (final (index, source) in projection.sources.indexed) ...[
              _HeritageSourceCard(index: index, source: source, copy: copy),
              if (index < projection.sources.length - 1)
                const SizedBox(height: Spacing.md),
            ],
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              key: const ValueKey('onboarding-v2-heritage-sources-close'),
              label: copy.closeAction,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    ),
  );
}

class _HeritageSourceCard extends StatelessWidget {
  const _HeritageSourceCard({
    required this.index,
    required this.source,
    required this.copy,
  });

  final int index;
  final HeritageSourceReference source;
  final OnboardingHeritageCatalogCopy copy;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final openLabel = copy.openSourceBuilder(source.title);
    void openSource() => openExternalUrl(context, source.url.toString());
    return SoriCard(
      key: ValueKey('onboarding-v2-heritage-source-$index'),
      variant: SoriCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.title, locale: const Locale('ko'), style: text.cardTitle),
          const SizedBox(height: Spacing.md),
          _SourceField(
            label: copy.institutionLabel,
            value: source.institution,
            valueLocale: const Locale('ko'),
          ),
          _SourceField(
            label: copy.yearLabel,
            value: copy.yearValueBuilder(
              source.sourceYear,
              _yearBasisLabel(source.yearBasis, copy),
            ),
          ),
          _SourceField(
            label: copy.titleLabel,
            value: source.title,
            valueLocale: const Locale('ko'),
          ),
          _SourceField(
            label: copy.authorLabel,
            value: source.author,
            valueLocale: const Locale('ko'),
          ),
          _SourceField(
            label: copy.licenseLabel,
            value: _licenseLabel(source.license, copy),
          ),
          Text(copy.urlLabel, style: text.meta),
          const SizedBox(height: Spacing.xs),
          SelectableText(
            source.url.toString(),
            key: ValueKey('onboarding-v2-heritage-source-url-$index'),
            style: text.cardSubtitle.copyWith(
              color: surfaces.brightness == Brightness.light
                  ? SoriColors.primaryOnLight
                  : SoriColors.primaryOnDark,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            key: ValueKey('onboarding-v2-heritage-source-open-$index'),
            button: true,
            enabled: true,
            attributedLabel: _withKoreanLocale(openLabel, source.title),
            onTap: openSource,
            excludeSemantics: true,
            child: SoriButton.outlined(
              label: openLabel,
              fullWidth: true,
              onTap: openSource,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceField extends StatelessWidget {
  const _SourceField({
    required this.label,
    required this.value,
    this.valueLocale,
  });

  final String label;
  final String value;
  final Locale? valueLocale;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.meta),
          const SizedBox(height: Spacing.xs),
          Text(value, locale: valueLocale, style: text.cardSubtitle),
        ],
      ),
    );
  }
}

AttributedString _withKoreanLocale(String value, String koreanSegment) {
  final start = value.indexOf(koreanSegment);
  if (start < 0 || koreanSegment.isEmpty) {
    return AttributedString(value);
  }
  return AttributedString(
    value,
    attributes: [
      LocaleStringAttribute(
        locale: const Locale('ko'),
        range: TextRange(start: start, end: start + koreanSegment.length),
      ),
    ],
  );
}

IconData _rewardIcon(SoriRewardKind kind) => switch (kind) {
  SoriRewardKind.none => Icons.block_outlined,
  SoriRewardKind.xp => Icons.bolt_rounded,
  SoriRewardKind.stamp => Icons.approval_outlined,
  SoriRewardKind.questProgress => Icons.flag_outlined,
  SoriRewardKind.hanokProgress => Icons.roofing_outlined,
  SoriRewardKind.bojagi => Icons.inventory_2_outlined,
  SoriRewardKind.gyeLantern => Icons.light_outlined,
  SoriRewardKind.personalBest => Icons.emoji_events_outlined,
};

String _yearBasisLabel(
  HeritageSourceYearBasis basis,
  OnboardingHeritageCatalogCopy copy,
) => switch (basis) {
  HeritageSourceYearBasis.published => copy.yearPublished,
  HeritageSourceYearBasis.updated => copy.yearUpdated,
  HeritageSourceYearBasis.accessed => copy.yearAccessed,
};

String _licenseLabel(
  HeritageLicenseReference license,
  OnboardingHeritageCatalogCopy copy,
) => switch (license.authority) {
  HeritageUseAuthority.koglType1 => copy.licenseKoglType1,
  HeritageUseAuthority.citationOnly => copy.licenseCitationOnly,
  HeritageUseAuthority.separatelyApproved => copy.licenseSeparatelyApproved,
  HeritageUseAuthority.unknown => license.displayName,
};
