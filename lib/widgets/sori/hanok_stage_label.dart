import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';

/// Short localized [HanokStage] name for Today / progress surfaces.
///
/// Exhaustive — never expose [HanokStage.name] (enum raw) to users.
String hanokStageLocalizedName(AppL10n t, HanokStage stage) => switch (stage) {
  HanokStage.empty => t.hanokStageName_empty,
  HanokStage.foundation => t.hanokStageName_foundation,
  HanokStage.pillars => t.hanokStageName_pillars,
  HanokStage.beams => t.hanokStageName_beams,
  HanokStage.thatchRoof => t.hanokStageName_thatchRoof,
  HanokStage.tileRoofPartial => t.hanokStageName_tileRoofPartial,
  HanokStage.tileRoofComplete => t.hanokStageName_tileRoofComplete,
  HanokStage.dancheong => t.hanokStageName_dancheong,
  HanokStage.gate => t.hanokStageName_gate,
  HanokStage.windows => t.hanokStageName_windows,
  HanokStage.sideBuilding => t.hanokStageName_sideBuilding,
  HanokStage.jongga => t.hanokStageName_jongga,
};

/// Path for the light-mode stage banner PNG used by Madang / learning-path.
///
/// Same resolver contract as [MadangBackground] / learning_path_screen —
/// do not invent a parallel slug map.
String hanokStageLightAsset(HanokStage stage) =>
    'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_light.png';
