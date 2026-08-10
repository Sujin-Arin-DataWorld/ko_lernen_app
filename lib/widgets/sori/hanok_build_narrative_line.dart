import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/curriculum.dart';
import '../../models/hanok_build_narrative.dart';
import '../../models/hanok_stage.dart';
import 'tokens.dart';

/// One text-first line that keeps the legacy construction stage and the
/// evidence-backed course narrative distinct.
class HanokBuildNarrativeLine extends StatelessWidget {
  const HanokBuildNarrativeLine({
    super.key,
    required this.narrative,
    this.style,
  });

  final HanokBuildNarrative narrative;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final stage = _stageLabel(t, narrative.projection.structureStage);
    final verified = narrative.verifiedUnit;
    final next = narrative.nextUnit;
    final value = switch ((verified, next)) {
      (final CourseUnit unit?, _) => t.hanokNarrativeVerified(
        stage,
        unit.canDo.pick(languageCode),
      ),
      (null, final CourseUnit unit?) => t.hanokNarrativeNext(
        stage,
        unit.canDo.pick(languageCode),
      ),
      _ => t.hanokNarrativeStarting(stage),
    };

    final textStyle =
        style ??
        SoriTextTheme.of(context).bodySmall.copyWith(
          color: SoriSurfaces.of(context).textMuted,
          height: 1.45,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          key: const ValueKey('hanok-build-narrative-line'),
          style: textStyle,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          t.hanokNarrativeMaterialSource,
          key: const ValueKey('hanok-build-material-source'),
          style: textStyle.copyWith(fontSize: textStyle.fontSize! * .94),
        ),
      ],
    );
  }

  static String _stageLabel(AppL10n t, HanokStage stage) => switch (stage) {
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
