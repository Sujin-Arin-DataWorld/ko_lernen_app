import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';

/// [HanokStage] enum 원문 대신 로컬라이즈드 단계명.
String hanokStageLabel(AppL10n t, HanokStage stage) => switch (stage) {
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
