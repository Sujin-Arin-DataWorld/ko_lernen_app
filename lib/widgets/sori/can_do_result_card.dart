import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';
import '../../models/scenario_can_do_result.dart';
import 'card.dart';
import 'tokens.dart';

/// Shows an outcome derived from a persisted scenario checkpoint. The card has
/// no action and no storage dependency, so it cannot turn a UI visit into
/// mastery or completion evidence.
class CanDoResultCard extends StatelessWidget {
  const CanDoResultCard({super.key, required this.result});

  final ScenarioCanDoResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final (
      IconData icon,
      Color accent,
      String title,
      String body,
    ) = switch (result.status) {
      ScenarioCanDoStatus.verified => (
        Icons.verified_outlined,
        SoriColors.success,
        t.scenarioCanDoVerifiedTitle,
        t.scenarioCanDoVerifiedBody,
      ),
      ScenarioCanDoStatus.reviewNeeded => (
        Icons.replay_outlined,
        SoriColors.warning,
        t.scenarioCanDoReviewTitle,
        t.scenarioCanDoReviewBody,
      ),
      ScenarioCanDoStatus.practiceOnly => (
        Icons.menu_book_outlined,
        SoriColors.primary,
        t.scenarioCanDoPracticeTitle,
        t.scenarioCanDoPracticeBody,
      ),
    };
    final canDo = result.isVerified
        ? result.courseUnit?.canDo.pick(languageCode)
        : null;

    return Semantics(
      container: true,
      label: title,
      child: ExcludeSemantics(
        child: SoriCard(
          variant: SoriCardVariant.base,
          accent: accent,
          tinted: true,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SoriTextTheme.of(
                        context,
                      ).h3.copyWith(color: accent),
                    ),
                    if (canDo != null && canDo.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        canDo,
                        style: SoriTextTheme.of(
                          context,
                        ).body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: Spacing.xs),
                    Text(body, style: SoriTextTheme.of(context).bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Names only a structure transition derived from before/after validated
/// projections. A checkpoint that did not change the visible Hanok says so.
class ScenarioStructureResultCard extends StatelessWidget {
  const ScenarioStructureResultCard({super.key, required this.result});

  final ScenarioCanDoResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final changed = result.hasStructureChange;
    final hasEvidence = result.hasStructureEvidence;
    final title = !hasEvidence
        ? t.scenarioStructureUnavailableTitle
        : changed
        ? t.scenarioStructureChangedTitle
        : t.scenarioStructureUnchangedTitle;
    final body = !hasEvidence
        ? t.scenarioStructureUnavailableBody
        : changed
        ? t.scenarioStructureChangedBody(
            _stageLabel(t, result.structureStageAfter!),
          )
        : t.scenarioStructureUnchangedBody;
    final accent = changed ? SoriColors.success : SoriColors.primary;

    return Semantics(
      container: true,
      label: '$title $body',
      child: ExcludeSemantics(
        child: SoriCard(
          variant: SoriCardVariant.base,
          accent: accent,
          tinted: true,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home_work_outlined, color: accent),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoriTextTheme.of(context).h3),
                    const SizedBox(height: Spacing.xs),
                    Text(body, style: SoriTextTheme.of(context).bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageLabel(AppL10n t, HanokStage stage) => switch (stage) {
    HanokStage.empty => t.hanokStageEmpty,
    HanokStage.foundation => t.hanokStageFoundation,
    HanokStage.pillars => t.hanokStagePillars,
    HanokStage.beams => t.hanokStageBeams,
    HanokStage.thatchRoof => t.hanokStageThatch,
    HanokStage.tileRoofPartial => t.hanokStageTilePartial,
    HanokStage.tileRoofComplete => t.hanokStageTileComplete,
    HanokStage.dancheong => t.hanokStageDancheong,
    HanokStage.gate => t.hanokStageGate,
    HanokStage.windows => t.hanokStageWindows,
    HanokStage.sideBuilding => t.hanokStageSideBuilding,
    HanokStage.jongga => t.hanokStageJongga,
  };
}
