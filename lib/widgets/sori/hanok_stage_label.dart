import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';

/// 한옥 건축 단계 → 사용자에게 보이는 이름.
///
/// 이 매핑은 원래 `can_do_result_card` 와 `hanok_build_narrative_line` 에
/// **똑같이 두 번** 들어 있었다. Today 가 세 번째 사본을 만들 뻔해서 여기로
/// 올렸다 — 새 표면은 이 함수를 쓰고, enum 값이 늘면 여기만 고친다
/// (exhaustive switch 라 컴파일러가 누락을 잡는다).
///
/// ⚠️ `HanokStage.name`(enum 원문 "empty")을 화면에 그대로 쓰지 말 것.
String soriHanokStageLabel(AppL10n t, HanokStage stage) => switch (stage) {
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
