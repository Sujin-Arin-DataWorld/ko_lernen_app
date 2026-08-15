import '../../l10n/generated/app_localizations.dart';
import '../../models/hanok_stage.dart';

/// [HanokStage] → 사용자 노출 이름 (§P3-3a, 2026-08-14).
///
/// Today 의 `_HanokProgress` 가 `structureStage.name`(enum 원문 — "empty")을
/// 그대로 노출하던 결함의 수리. **전 값 exhaustive switch** — 새 단계가 생기면
/// 컴파일러가 여기서 잡는다. 다른 표면도 이 헬퍼를 재사용할 것 (ARB 매핑
/// switch 를 화면마다 복제하지 말 것).
String hanokStageDisplayName(AppL10n t, HanokStage stage) => switch (stage) {
  HanokStage.empty => t.hanokStageNameEmpty,
  HanokStage.foundation => t.hanokStageNameFoundation,
  HanokStage.pillars => t.hanokStageNamePillars,
  HanokStage.beams => t.hanokStageNameBeams,
  HanokStage.thatchRoof => t.hanokStageNameThatchRoof,
  HanokStage.tileRoofPartial => t.hanokStageNameTileRoofPartial,
  HanokStage.tileRoofComplete => t.hanokStageNameTileRoofComplete,
  HanokStage.dancheong => t.hanokStageNameDancheong,
  HanokStage.gate => t.hanokStageNameGate,
  HanokStage.windows => t.hanokStageNameWindows,
  HanokStage.sideBuilding => t.hanokStageNameSideBuilding,
  HanokStage.jongga => t.hanokStageNameJongga,
};
