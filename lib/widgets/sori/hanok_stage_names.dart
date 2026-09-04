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

/// Bilingual-neutral "Romanization · Hangul" companion to
/// [hanokStageDisplayName] (H6, §W-C). Only `dancheong`/`sideBuilding`/
/// `jongga` currently ship as bare romanizations with a real Korean-origin
/// identity behind them (단청/사랑채/종가); the other stages are plain
/// German/English construction-progress words with no established loanword
/// in the shipped copy, so their term mirrors the display name on purpose —
/// callers should skip the secondary line when the two are equal.
String hanokStageTerm(AppL10n t, HanokStage stage) => switch (stage) {
  HanokStage.empty => t.hanokStageTermEmpty,
  HanokStage.foundation => t.hanokStageTermFoundation,
  HanokStage.pillars => t.hanokStageTermPillars,
  HanokStage.beams => t.hanokStageTermBeams,
  HanokStage.thatchRoof => t.hanokStageTermThatchRoof,
  HanokStage.tileRoofPartial => t.hanokStageTermTileRoofPartial,
  HanokStage.tileRoofComplete => t.hanokStageTermTileRoofComplete,
  HanokStage.dancheong => t.hanokStageTermDancheong,
  HanokStage.gate => t.hanokStageTermGate,
  HanokStage.windows => t.hanokStageTermWindows,
  HanokStage.sideBuilding => t.hanokStageTermSideBuilding,
  HanokStage.jongga => t.hanokStageTermJongga,
};

/// [HanokStage] → [CulturalGlossary] termId (§W-D D8, §COPY-2/J8). Only the
/// three stages whose [hanokStageTerm] actually differs from
/// [hanokStageDisplayName] have a matching glossary entry today. The rest
/// return null and their caller falls back to plain text (no door — §COPY-3
/// Option A). term 값을 채우려면 같은 PR 에서 글로서리 항목과 termId
/// 매핑을 함께 추가한다(문 없는 용어 금지).
String? hanokStageGlossaryTermId(HanokStage stage) => switch (stage) {
  HanokStage.dancheong => 'dancheong',
  HanokStage.sideBuilding => 'sarangchae',
  HanokStage.jongga => 'jongga',
  _ => null,
};
