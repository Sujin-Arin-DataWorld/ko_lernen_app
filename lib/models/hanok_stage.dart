/// Phase 3 (stately-rising-jongga) — 한옥 건축 12단계.
///
/// Plan §5.1 의 cascade 모델: A1 완료 전에는 한옥 골조 (foundation → beams →
/// thatch), A2 완료 전에는 지붕 (tile), B1 완료 전에는 문 (gate / windows),
/// B2 완료 시 종갓집 (jongga). 단청 (dancheong) 은 A2 100% 시점에 진입.
///
/// 진행도 컷오프는 `computeStage()` 의 boundary 테스트에 의해 lock 되어 있음.
enum HanokStage {
  empty,             // A1 < 25% — 빈 터
  foundation,        // A1 25-50% — 주춧돌
  pillars,           // A1 50-75% — 기둥
  beams,             // A1 75-100% — 대들보 + 서까래
  thatchRoof,        // A1 100% / A2 < 25% — 초가지붕 (소박한 첫 집)
  tileRoofPartial,   // A2 25-75% — 기와 부분
  tileRoofComplete,  // A2 75-100% — 기와 완성
  dancheong,         // A2 100% / B1 < 25% — 처마 단청
  gate,              // B1 25-50% — 솟을대문
  windows,           // B1 50-100% — 창호지문
  sideBuilding,      // B2 25-50% — 사랑채
  jongga;            // B2 50-100% — 종갓집 완성

  /// 시각 분류 — Phase 3 PNG 자산 경로 키.
  /// `assets/illustrations/hanok_stages/stage_{slug}_{light|dark}.png`.
  String get assetSlug => switch (this) {
        HanokStage.empty            => 'empty',
        HanokStage.foundation       => 'foundation',
        HanokStage.pillars          => 'pillars',
        HanokStage.beams            => 'beams',
        HanokStage.thatchRoof       => 'thatch',
        HanokStage.tileRoofPartial  => 'tile_partial',
        HanokStage.tileRoofComplete => 'tile_complete',
        HanokStage.dancheong        => 'dancheong',
        HanokStage.gate             => 'gate',
        HanokStage.windows          => 'windows',
        HanokStage.sideBuilding     => 'side_building',
        HanokStage.jongga           => 'jongga',
      };

  /// 단계 순서 0..11 (cinematic transition detection 에 사용).
  int get ordinal => HanokStage.values.indexOf(this);

  /// JSON / SharedPreferences 직렬화 키 (안정적, enum.name 과 동일).
  String toJsonValue() => name;
  static HanokStage fromJsonValue(String? v) {
    if (v == null) return HanokStage.empty;
    return HanokStage.values.firstWhere(
      (s) => s.name == v,
      orElse: () => HanokStage.empty,
    );
  }
}

/// 사용자의 레벨별 완료 비율을 [0..1] 로 받아서 현재 [HanokStage] 를 계산.
///
/// **Cascade 원칙** (Plan §5.1 기반):
///   - A1 미완료 → A1-Phase 단계 (empty/foundation/pillars/beams)
///   - A1 = 1.0 & A2 미완료 → A2-Phase (thatch/tilePartial/tileComplete)
///   - A2 = 1.0 & B1 미완료 → B1-Phase (dancheong/gate/windows)
///   - B1 = 1.0 → B2-Phase (sideBuilding/jongga)
///
/// 입력은 모두 0.0 ~ 1.0 으로 clamp 됨 — 음수/초과 안전.
///
/// 동일 입력 → 동일 출력 (순수 함수, 캐시 안전).
HanokStage computeStage({
  required double a1Ratio,
  required double a2Ratio,
  required double b1Ratio,
  required double b2Ratio,
}) {
  final a1 = a1Ratio.clamp(0.0, 1.0);
  final a2 = a2Ratio.clamp(0.0, 1.0);
  final b1 = b1Ratio.clamp(0.0, 1.0);
  final b2 = b2Ratio.clamp(0.0, 1.0);

  // ── A1-Phase ──────────────────────────────────────────────────
  if (a1 < 0.25) return HanokStage.empty;
  if (a1 < 0.50) return HanokStage.foundation;
  if (a1 < 0.75) return HanokStage.pillars;
  if (a1 < 1.00) return HanokStage.beams;

  // ── A2-Phase (A1 = 100%) ──────────────────────────────────────
  if (a2 < 0.25) return HanokStage.thatchRoof;
  if (a2 < 0.75) return HanokStage.tileRoofPartial;
  if (a2 < 1.00) return HanokStage.tileRoofComplete;

  // ── B1-Phase (A2 = 100%) ──────────────────────────────────────
  if (b1 < 0.25) return HanokStage.dancheong;
  if (b1 < 0.50) return HanokStage.gate;
  if (b1 < 1.00) return HanokStage.windows;

  // ── B2-Phase (B1 = 100%) ──────────────────────────────────────
  if (b2 < 0.50) return HanokStage.sideBuilding;
  return HanokStage.jongga;
}
