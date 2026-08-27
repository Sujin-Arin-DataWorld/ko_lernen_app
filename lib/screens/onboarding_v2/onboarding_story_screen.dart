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
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

/// Mandatory five-page product story.
///
/// [pageIndex] is coordinator-driven rather than owned by this widget. This
/// makes a restored persisted page render directly without replaying earlier
/// pages or mutating service data during a preview.
class OnboardingStoryScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    assert(copy.storyPages.length == 5);
    assert(pageIndex < copy.storyPages.length);
    final page = copy.storyPages[pageIndex];
    final isLast = pageIndex == copy.storyPages.length - 1;
    final curriculumEvidence = page.curriculumEvidenceCopy == null
        ? null
        : (curriculumEvidenceProjector ??
              () => OnboardingCurriculumEvidenceProjector.project())();
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 220),
    );

    return OnboardingV2PageShell(
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
              announcementLabel:
                  '${copy.navigation.progress(pageIndex + 1, copy.storyPages.length)}. ${page.title}',
            ),
            const SizedBox(height: Spacing.xl),
            _StoryHero(
              page: page,
              curriculumEvidence: curriculumEvidence,
              rewardCatalogProjector: rewardCatalogProjector,
              heritageCatalogProjector: heritageCatalogProjector,
            ),
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: copy.navigation.progress(
              pageIndex + 1,
              copy.storyPages.length,
            ),
            child: ExcludeSemantics(
              child: Text(
                copy.navigation.progress(pageIndex + 1, copy.storyPages.length),
                key: const ValueKey('onboarding-v2-story-progress'),
                style: SoriTextTheme.of(context).meta,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final back = SoriButton.outlined(
                key: const ValueKey('onboarding-v2-story-back'),
                label: copy.navigation.back,
                fullWidth: true,
                onTap: pageIndex == 0 ? null : () => onPrevious(page.id),
              );
              final next = SoriButton.filled(
                key: const ValueKey('onboarding-v2-story-next'),
                label: isLast
                    ? copy.navigation.finishStory
                    : copy.navigation.next,
                trailingIcon: Icons.arrow_forward_rounded,
                fullWidth: true,
                onTap: () => onContinue(page.id),
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
                  Expanded(child: back),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: next),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoryHero extends StatelessWidget {
  const _StoryHero({
    required this.page,
    required this.curriculumEvidence,
    required this.rewardCatalogProjector,
    required this.heritageCatalogProjector,
  });

  final OnboardingStoryPageSpec page;
  final OnboardingCurriculumEvidenceProjection? curriculumEvidence;
  final OnboardingCatalogProjectionResult<OnboardingRewardCatalogProjection>
  Function()?
  rewardCatalogProjector;
  final OnboardingCatalogProjectionResult<OnboardingHeritageCatalogProjection>
  Function()?
  heritageCatalogProjector;

  Color get _accent => switch (page.visualKind) {
    OnboardingStoryVisualKind.personalCurriculum => SoriColors.primary,
    OnboardingStoryVisualKind.learn => SoriColors.accent,
    OnboardingStoryVisualKind.saveAndReview => SoriColors.like,
    OnboardingStoryVisualKind.gamesAndRewards => SoriColors.goldOnLight,
    OnboardingStoryVisualKind.heritageJourney => SoriColors.primaryDark,
  };

  IconData get _heroIcon => switch (page.visualKind) {
    OnboardingStoryVisualKind.personalCurriculum => Icons.auto_stories_outlined,
    OnboardingStoryVisualKind.learn => Icons.school_outlined,
    OnboardingStoryVisualKind.saveAndReview => Icons.bookmarks_outlined,
    OnboardingStoryVisualKind.gamesAndRewards =>
      Icons.workspace_premium_outlined,
    OnboardingStoryVisualKind.heritageJourney => Icons.roofing_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final rewardProjectionResult = page.rewardCatalogCopy == null
        ? null
        : (rewardCatalogProjector ??
              () => OnboardingStoryCatalogProjector.projectRewards())();
    final heritageProjectionResult = page.heritageCatalogCopy == null
        ? null
        : (heritageCatalogProjector ??
              () => OnboardingStoryCatalogProjector.projectIlduGotaek())();
    final rewardProjection = rewardProjectionResult?.projection;
    final heritageProjection = heritageProjectionResult?.projection;
    final heritageUnavailable =
        page.heritageCatalogCopy != null && heritageProjection == null;
    final heroSemanticLabel = heritageUnavailable
        ? '${page.title}. ${page.heritageCatalogCopy!.inPreparationLabel}'
        : page.heroSemanticLabel;
    final statusLabel = heritageUnavailable
        ? page.heritageCatalogCopy!.inPreparationLabel
        : page.statusLabel;
    return Semantics(
      container: true,
      child: SoriCard(
        key: const ValueKey('onboarding-v2-story-hero'),
        variant: SoriCardVariant.hero,
        accent: _accent,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Semantics(
                image: true,
                label: heroSemanticLabel,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Icon(_heroIcon, size: 72, color: _accent),
                    ),
                  ),
                ),
              ),
            ),
            if (statusLabel != null) ...[
              const SizedBox(height: Spacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      statusLabel,
                      key: const ValueKey('onboarding-v2-story-status'),
                      style: text.label.copyWith(color: _accent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Spacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - Spacing.md) / 2;
                return Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.md,
                  children: [
                    for (final highlight in page.highlights)
                      SizedBox(
                        width: itemWidth,
                        child: _StoryHighlightTile(
                          highlight: highlight,
                          accent: _accent,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (curriculumEvidence != null) ...[
              const SizedBox(height: Spacing.xl),
              _CurriculumEvidencePreview(
                copy: page.curriculumEvidenceCopy!,
                projection: curriculumEvidence!,
                accent: _accent,
              ),
            ],
            if (rewardProjection != null) ...[
              const SizedBox(height: Spacing.xl),
              _RewardCatalogPreview(
                copy: page.rewardCatalogCopy!,
                projection: rewardProjection,
                accent: _accent,
              ),
            ],
            if (heritageProjection != null) ...[
              const SizedBox(height: Spacing.xl),
              _HeritageCatalogPreview(
                copy: page.heritageCatalogCopy!,
                projection: heritageProjection,
                accent: _accent,
              ),
            ],
          ],
        ),
      ),
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

class _StoryHighlightTile extends StatelessWidget {
  const _StoryHighlightTile({required this.highlight, required this.accent});

  final OnboardingStoryHighlight highlight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(highlight.icon, size: 28, color: accent)),
        const SizedBox(height: Spacing.sm),
        Text(highlight.title, style: text.cardTitle),
        const SizedBox(height: Spacing.xs),
        Text(highlight.body, style: text.cardSubtitle),
      ],
    );
  }
}
