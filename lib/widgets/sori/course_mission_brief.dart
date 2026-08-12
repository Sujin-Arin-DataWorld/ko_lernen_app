import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/course_mission_brief.dart';
import '../../models/curriculum.dart';
import '../../services/scene_asset_resolver.dart';
import 'button.dart';
import 'card.dart';
import 'tokens.dart';

typedef CourseMissionBriefOpener = Future<void> Function(ContentLink link);

/// The storage-free departure surface used by the production mission screen
/// and the UX gallery. Its CTA receives the exact first link shown as step 1.
class CourseMissionBriefView extends StatelessWidget {
  const CourseMissionBriefView({
    super.key,
    required this.brief,
    required this.openLink,
    this.onExplain,
  });

  final CourseMissionBrief brief;
  final CourseMissionBriefOpener openLink;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final text = SoriTextTheme.of(context);
    final scenario = brief.targetScenario;
    final firstLink = brief.firstLink;
    final poster = scenario == null
        ? null
        : SceneAssetResolver.posterAsset(scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${brief.unit.level.toUpperCase()} · ${brief.unit.title.pick(lang)}',
          style: text.label.copyWith(color: SoriColors.primary),
        ),
        const SizedBox(height: Spacing.sm),
        Text(brief.unit.canDo.pick(lang), style: text.h1),
        if (scenario != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseMissionBriefScene(scenario.title.pick(lang)),
            style: text.body,
          ),
        ],
        if (poster != null) ...[
          const SizedBox(height: Spacing.md),
          Semantics(
            image: true,
            label: scenario?.title.pick(lang),
            child: ClipRRect(
              borderRadius: SoriRadius.brLg,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  poster,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: SoriSurfaces.of(context).surfaceAlt,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: Spacing.sm),
        for (final step in brief.visibleSteps)
          _BriefStepRow(
            step: step,
            title: _stepTitle(step.phase, t),
            body: _stepBody(step.phase, t),
          ),
        if (brief.remainingStepCount > 0) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            t.courseMissionBriefRemaining(brief.remainingStepCount),
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: Spacing.lg),
        if (brief.isCurrent && firstLink != null)
          SoriButton.filled(
            key: const ValueKey('course-mission-primary-cta'),
            label: _stepCta(brief.visibleSteps.first.phase, t),
            fullWidth: true,
            onTap: () async => openLink(firstLink),
          )
        else if (!brief.isCurrent)
          Text(t.courseMissionPreviewNotice, style: text.bodySmall),
        if (onExplain != null)
          Center(
            child: TextButton(
              onPressed: onExplain,
              child: Text(t.courseMissionBriefWhy),
            ),
          ),
      ],
    );
  }

  String _stepTitle(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenTitle,
    CourseMissionPhase.build => t.courseMissionBriefBuildTitle,
    CourseMissionPhase.scene => t.courseMissionBriefSceneTitle,
  };

  String _stepBody(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenBody,
    CourseMissionPhase.build => t.courseMissionBriefBuildBody,
    CourseMissionPhase.scene => t.courseMissionBriefSceneBody,
  };

  String _stepCta(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenCta,
    CourseMissionPhase.build => t.courseMissionBriefBuildCta,
    CourseMissionPhase.scene => t.courseMissionBriefSceneCta,
  };
}

class _BriefStepRow extends StatelessWidget {
  const _BriefStepRow({
    required this.step,
    required this.title,
    required this.body,
  });

  final CourseMissionBriefStep step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoriColors.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${step.displayIndex}',
                style: text.label.copyWith(color: SoriColors.primary),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.label),
                  const SizedBox(height: 2),
                  Text(body, style: text.caption),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.courseMissionBriefMinutes(step.estimatedMinutes),
              style: text.caption,
            ),
          ],
        ),
      ),
    );
  }
}
