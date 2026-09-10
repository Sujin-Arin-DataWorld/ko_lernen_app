import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;

import '../../l10n/generated/app_localizations.dart';
import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../features/onboarding_v2/onboarding_story_catalog_projector.dart';
import '../../models/curriculum_alignment_contract.dart';
import '../../models/heritage_journey_contract.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/chip.dart';
import '../../widgets/sori/external_link.dart';
import '../../widgets/sori/localized_copy.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_hanok_growth_preview.dart';
import 'onboarding_story_practice.dart';
import 'onboarding_character_media.dart';
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
  bool _cardFlipped = false;

  @override
  void didUpdateWidget(covariant OnboardingStoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex) {
      _cardFlipped = false;
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
    final compactHeading = MediaQuery.textScalerOf(context).scale(16) > 24;

    return OnboardingV2PageShell(
      maxContentHeight: pageIndex == 1
          ? 620
          : pageIndex == 2
          ? 740
          : 820,
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: pageIndex + 1,
      totalSteps: 7,
      progressLabel: progress,
      stageKey: ValueKey('onboarding-v2-stage-${page.id}'),
      stage: OnboardingStoryStage(page: page, questComplete: false),
      showStage: pageIndex == 4,
      heading: OnboardingV2Heading(
        key: ValueKey('onboarding-v2-heading-${page.id}'),
        titleKey: const ValueKey('onboarding-v2-story-title'),
        eyebrow: page.eyebrow,
        title: compactHeading ? page.eyebrow : page.title,
        body: page.body,
        showBody: false,
        announcementLabel: '$progress. ${page.title}',
      ),
      bodyKey: ValueKey('onboarding-v2-story-scroll-${page.id}'),
      body: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(page.id),
          child: _StoryInteraction(
            page: page,
            setup: copy.setup,
            cardFlipped: _cardFlipped,
            onToggleCard: () => setState(() => _cardFlipped = !_cardFlipped),
            curriculumEvidence: curriculumEvidence,
            rewardProjection: rewardProjection,
            heritageProjection: heritageProjection,
          ),
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
    return OnboardingV2FooterActions(
      backKey: const ValueKey('onboarding-v2-story-back'),
      backLabel: backLabel,
      onBack: onBack,
      primaryAction: SoriButton.filled(
        key: const ValueKey('onboarding-v2-story-next'),
        label: nextLabel,
        trailingIcon: MediaQuery.textScalerOf(context).scale(16) > 24
            ? null
            : Icons.arrow_forward_rounded,
        fullWidth: true,
        size: SoriButtonSize.md,
        onTap: onNext,
      ),
    );
  }
}

class _StoryInteraction extends StatelessWidget {
  const _StoryInteraction({
    required this.page,
    required this.setup,
    required this.cardFlipped,
    required this.onToggleCard,
    required this.curriculumEvidence,
    required this.rewardProjection,
    required this.heritageProjection,
  });

  final OnboardingStoryPageSpec page;
  final OnboardingSetupCopy setup;
  final bool cardFlipped;
  final VoidCallback onToggleCard;
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
      OnboardingStoryVisualKind.learn => LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingJamoPractice(),
            const SizedBox(height: Spacing.sm),
            if (MediaQuery.textScalerOf(context).scale(16) <= 24 &&
                constraints.maxHeight >= 260)
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).body,
              )
            else
              OnboardingV2DetailsButton(
                label: AppL10n.of(context).onboardingV2DetailsAction,
                sheetTitle: page.title,
                child: _StoryFullCopy(page: page),
              ),
          ],
        ),
      ),
      OnboardingStoryVisualKind.saveAndReview => _FlipReviewPreview(
        page: page,
        flipped: cardFlipped,
        onTap: onToggleCard,
        korean: learnedWord,
        translation: AppL10n.of(context).onboardingV2DoorMeaning,
      ),
      OnboardingStoryVisualKind.gamesAndRewards => _QuestPreview(
        page: page,
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
    final text = SoriTextTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showCopy =
            constraints.maxHeight >= 200 &&
            MediaQuery.textScalerOf(context).scale(16) <= 24;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                key: const ValueKey('onboarding-v2-story-hero'),
                container: true,
                label: page.heroSemanticLabel,
                child: const ExcludeSemantics(
                  child: OnboardingHanokGrowthPreview(complete: true),
                ),
              ),
            ),
            if (showCopy) ...[
              const SizedBox(height: Spacing.sm),
              Text(page.body, textAlign: TextAlign.center, style: text.body),
            ],
            OnboardingV2DetailsButton(
              label: MediaQuery.textScalerOf(context).scale(16) > 24
                  ? AppL10n.of(context).onboardingV2DetailsAction
                  : AppL10n.of(context).onboardingV2CurriculumDetails,
              sheetTitle: AppL10n.of(context).onboardingV2CurriculumDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoryFullCopy(page: page),
                  const SizedBox(height: Spacing.md),
                  for (final level in levels)
                    Text(
                      '${level.code} · ${level.name}',
                      textAlign: TextAlign.center,
                      style: text.body,
                    ),
                  if (page.statusLabel != null) ...[
                    const SizedBox(height: Spacing.md),
                    _StatusNote(
                      label: page.statusLabel!,
                      accent: SoriColors.primary,
                    ),
                  ],
                  if (curriculumEvidence != null) ...[
                    const SizedBox(height: Spacing.md),
                    _CurriculumEvidencePreview(
                      copy: page.curriculumEvidenceCopy!,
                      projection: curriculumEvidence!,
                      accent: SoriColors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlipReviewPreview extends StatefulWidget {
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
  State<_FlipReviewPreview> createState() => _FlipReviewPreviewState();
}

class _FlipReviewPreviewState extends State<_FlipReviewPreview>
    with WidgetsBindingObserver {
  bool _playing = false;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _play(String value, {bool slow = false}) async {
    final request = ++_request;
    setState(() {
      _playing = true;
      _failed = false;
    });
    var played = false;
    try {
      played = slow
          ? await SoriSpeech.speakSlow(value)
          : await SoriSpeech.speak(value);
    } catch (_) {
      // The card stays readable and the learner can retry unavailable audio.
    }
    if (mounted && request == _request) {
      setState(() {
        _playing = false;
        _failed = !played;
      });
    }
  }

  void _stop() {
    _request++;
    if (_playing) {
      unawaited(SoriSpeech.stop().catchError((Object _) {}));
    }
    _playing = false;
  }

  void _flip() {
    final revealing = !widget.flipped;
    widget.onTap();
    if (revealing) {
      unawaited(_play(widget.korean));
    } else {
      setState(_stop);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(_stop);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final page = widget.page;
    final flipped = widget.flipped;
    final korean = widget.korean;
    final translation = widget.translation;
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
        final compact = constraints.maxHeight < 420;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                key: const ValueKey('onboarding-v2-story-hero'),
                color: flipped ? surfaces.surfaceAlt : SoriColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: SoriRadius.brMd,
                  side: BorderSide(
                    color: flipped ? SoriColors.gold : SoriColors.primary,
                  ),
                ),
                child: Padding(
                  padding: compact
                      ? const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        )
                      : const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: flipped
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$korean · $translation',
                                    textAlign: TextAlign.center,
                                    style: compact && largeText
                                        ? text.body
                                        : text.h2,
                                  ),
                                  if (!compact && !largeText)
                                    Text('mun', style: text.meta),
                                  if (!compact || !largeText)
                                    const SizedBox(height: Spacing.xs),
                                  TextButton.icon(
                                    key: const ValueKey(
                                      'onboarding-v3-example-audio',
                                    ),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onPressed: _playing
                                        ? null
                                        : () => _play(learnedExample),
                                    icon: const Icon(Icons.volume_up_rounded),
                                    label: Text(
                                      learnedExample,
                                      locale: const Locale('ko'),
                                      textAlign: TextAlign.center,
                                      style: largeText ? text.body : text.h2,
                                    ),
                                  ),
                                  Text(
                                    t.onboardingV3DoorExampleTranslation,
                                    textAlign: TextAlign.center,
                                    style: text.bodySmall,
                                  ),
                                ],
                              )
                            : Semantics(
                                key: const ValueKey('onboarding-v3-card-front'),
                                button: true,
                                label: page.heroSemanticLabel,
                                onTap: _flip,
                                excludeSemantics: true,
                                child: SoriPressable(
                                  onTap: _flip,
                                  child: Center(
                                    child: Text(
                                      korean,
                                      locale: const Locale('ko'),
                                      style: text.koDisplay.copyWith(
                                        color: Colors.white,
                                        fontSize: largeText
                                            ? text.koDisplay.fontSize
                                            : soriFillSize(
                                                constraints.maxHeight,
                                                .22,
                                                64,
                                                104,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              key: const ValueKey('onboarding-v3-card-audio'),
                              style: TextButton.styleFrom(
                                foregroundColor: flipped
                                    ? SoriColors.primaryOnLight
                                    : Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: _playing
                                  ? null
                                  : () => _play(
                                      flipped ? learnedExample : korean,
                                      slow: flipped,
                                    ),
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _failed
                                    ? t.btnRetry
                                    : flipped
                                    ? t.onboardingV3ListenSlow
                                    : t.onboardingV3ListenWord,
                                semanticsLabel: _failed
                                    ? t.onboardingV2AudioUnavailable
                                    : null,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              key: const ValueKey('onboarding-v3-card-flip'),
                              style: TextButton.styleFrom(
                                foregroundColor: flipped
                                    ? SoriColors.primaryOnLight
                                    : Colors.white,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: _flip,
                              icon: const Icon(Icons.flip_rounded, size: 20),
                              label: Text(
                                t.onboardingV3FlipCard,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!flipped || (!largeText && constraints.maxHeight >= 450)) ...[
              SizedBox(height: compact ? Spacing.xs : Spacing.md),
              Row(
                children: [
                  for (final (index, days) in const [
                    '1',
                    '3',
                    '7',
                    '30',
                  ].indexed)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 3,
                            color: index == 0
                                ? SoriColors.primary
                                : surfaces.border,
                          ),
                          SizedBox(height: compact ? Spacing.xs : Spacing.sm),
                          Text(
                            days,
                            textAlign: TextAlign.center,
                            style: text.meta,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (!largeText && constraints.maxHeight >= 450) ...[
              const SizedBox(height: Spacing.md),
              Text(page.body, textAlign: TextAlign.center, style: text.body),
            ],
            _StoryDetails(
              title: AppL10n.of(context).onboardingV2ReviewDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoryFullCopy(page: page),
                  if (page.highlights.length >= 4) ...[
                    const SizedBox(height: Spacing.md),
                    _MemoryMeaning(
                      icon: Icons.favorite_outline_rounded,
                      highlight: page.highlights[2],
                      accent: SoriColors.tigerOnLight,
                    ),
                    const SizedBox(height: Spacing.md),
                    _MemoryMeaning(
                      icon: Icons.bookmark_outline_rounded,
                      highlight: page.highlights[3],
                      accent: SoriColors.primaryDark,
                    ),
                  ],
                  if (page.statusLabel != null) ...[
                    const SizedBox(height: Spacing.md),
                    _StatusNote(
                      label: page.statusLabel!,
                      accent: SoriColors.accent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
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
            Text(
              highlight.title,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).meta,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              highlight.body,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestPreview extends StatelessWidget {
  const _QuestPreview({required this.page, required this.projection});
  final OnboardingStoryPageSpec page;
  final OnboardingRewardCatalogProjection? projection;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Expanded(
        child: OnboardingRewardPractice(
          character: OnboardingCharacterMedia(characterId: 'tiger'),
        ),
      ),
      _StoryDetails(
        title: AppL10n.of(context).onboardingV2RewardDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StoryFullCopy(page: page),
            const SizedBox(height: Spacing.sm),
            Text(
              AppL10n.of(context).onboardingV2RewardDemoNote,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).bodySmall,
            ),
            if (projection != null) ...[
              const SizedBox(height: Spacing.md),
              _RewardCatalogPreview(
                copy: page.rewardCatalogCopy!,
                projection: projection!,
                accent: SoriColors.goldOnLight,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _StoryFullCopy extends StatelessWidget {
  const _StoryFullCopy({required this.page});
  final OnboardingStoryPageSpec page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        page.title,
        textAlign: TextAlign.center,
        style: SoriTextTheme.of(context).h3,
      ),
      const SizedBox(height: Spacing.sm),
      Text(
        page.body,
        textAlign: TextAlign.center,
        style: SoriTextTheme.of(context).body,
      ),
    ],
  );
}

class _StoryDetails extends StatelessWidget {
  const _StoryDetails({
    required this.title,
    required this.child,
    this.sheetTitle,
  });
  final String title;
  final String? sheetTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => OnboardingV2DetailsButton(
    label: MediaQuery.textScalerOf(context).scale(16) > 24
        ? AppL10n.of(context).onboardingV2DetailsAction
        : title,
    sheetTitle: sheetTitle ?? title,
    child: child,
  );
}

class _HeritageJourneyPreview extends StatelessWidget {
  const _HeritageJourneyPreview({required this.page, required this.projection});

  final OnboardingStoryPageSpec page;
  final OnboardingHeritageCatalogProjection? projection;

  static const _chapters = [
    ('솟을대문', 'Soseuldaemun', 'assets/illustrations/stamps/stamp_taegeuk.png'),
    ('사랑채', 'Sarangchae', 'assets/illustrations/stamps/stamp_plum.png'),
    ('안채', 'Anchae', 'assets/illustrations/stamps/stamp_mountain.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final heritageCopy = page.heritageCatalogCopy;
    final text = SoriTextTheme.of(context);
    final fallbackStatus = page.statusLabel ?? page.title;
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        key: const ValueKey('onboarding-v2-story-hero'),
        container: true,
        label: projection == null || heritageCopy == null
            ? '${page.title}. $fallbackStatus'
            : page.heroSemanticLabel,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (projection != null && heritageCopy != null)
              SoriButton.outlined(
                key: const ValueKey('onboarding-v2-gate-preview'),
                label: heritageCopy.previewLabel,
                semanticLabel: 'Soseuldaemun · ${heritageCopy.previewLabel}',
                icon: Icons.visibility_outlined,
                fullWidth: true,
                onTap: () => _showGatePreview(
                  context,
                  copy: heritageCopy,
                  projection: projection!,
                ),
              )
            else
              _StatusNote(
                label: heritageCopy?.inPreparationLabel ?? fallbackStatus,
                accent: SoriColors.primaryDark,
              ),
            if (constraints.maxHeight >= 230 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24) ...[
              const SizedBox(height: Spacing.sm),
              Text(page.body, textAlign: TextAlign.center, style: text.body),
            ],
            _StoryDetails(
              title: AppL10n.of(context).onboardingV2DetailsAction,
              sheetTitle: page.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoryFullCopy(page: page),
                  const SizedBox(height: Spacing.md),
                  for (final (index, chapter) in _chapters.indexed)
                    _ChapterRow(
                      korean: chapter.$1,
                      latin: chapter.$2,
                      status: page.highlights[index].title,
                      stampAsset: chapter.$3,
                      current: index == 0,
                    ),
                  if (projection != null && heritageCopy != null) ...[
                    const SizedBox(height: Spacing.md),
                    _HeritageCatalogPreview(
                      copy: heritageCopy,
                      projection: projection!,
                      accent: SoriColors.primaryDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
  });

  final String korean;
  final String latin;
  final String status;
  final String stampAsset;
  final bool current;

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
    () => showOnboardingV2ReadingModal<void>(
      context: context,
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
                  label: localCopy(context, example.label),
                  semanticLabel: copy.possibleRewardBuilder(
                    localCopy(context, example.label),
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

Future<void> _showGatePreview(
  BuildContext context, {
  required OnboardingHeritageCatalogCopy copy,
  required OnboardingHeritageCatalogProjection projection,
}) {
  return showOnboardingV2ModalWithFocusRestore(
    () => showOnboardingV2ReadingModal<void>(
      context: context,
      builder: (sheetContext) {
        final t = AppL10n.of(sheetContext);
        final text = SoriTextTheme.of(sheetContext);
        final dpr = MediaQuery.devicePixelRatioOf(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              debugLabel: 'onboarding-v2-gate-preview-heading',
              autofocus: true,
              child: Semantics(
                header: true,
                child: Text(
                  t.onboardingV2GatePreviewTitle,
                  key: const ValueKey('onboarding-v2-gate-preview-title'),
                  style: text.h2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(t.onboardingV2GatePreviewBody, style: text.body),
            const SizedBox(height: Spacing.md),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1100 / dpr),
                child: AspectRatio(
                  aspectRatio: 1100 / 733,
                  child: Image.asset(
                    'assets/illustrations/personal_hanok_v3/world/main-gate.png',
                    key: const ValueKey('onboarding-v2-gate-preview-image'),
                    fit: BoxFit.contain,
                    semanticLabel: t.onboardingV2GatePreviewTitle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SoriButton.filled(
              key: const ValueKey('onboarding-v2-gate-preview-close'),
              label: t.onboardingV2GatePreviewClose,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              projection.officialName,
              locale: const Locale('ko'),
              style: text.cardTitle,
            ),
            Text(copy.assetReviewNote, style: text.bodySmall),
            const SizedBox(height: Spacing.md),
            OnboardingV2DetailsButton(
              label: t.onboardingV3MapPreviewTitle,
              child: Column(
                children: [
                  Text(t.onboardingV3MapPreviewBody, style: text.bodySmall),
                  const SizedBox(height: Spacing.sm),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1202 / dpr),
                      child: Image.asset(
                        'assets/illustrations/onboarding/ildu_v3_map_preview.png',
                        key: const ValueKey('onboarding-v3-map-preview-image'),
                        fit: BoxFit.contain,
                        semanticLabel: t.onboardingV3MapPreviewTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            _StoryDetails(
              title: copy.sourcesAction,
              child: Column(
                children: [
                  Text(copy.sourcesBody, style: text.bodySmall),
                  for (final (index, source) in projection.sources.indexed) ...[
                    const SizedBox(height: Spacing.md),
                    _HeritageSourceCard(
                      index: index,
                      source: source,
                      copy: copy,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showHeritageSources(
  BuildContext context, {
  required OnboardingHeritageCatalogCopy copy,
  required OnboardingHeritageCatalogProjection projection,
}) {
  return showOnboardingV2ModalWithFocusRestore(
    () => showOnboardingV2ReadingModal<void>(
      context: context,
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
