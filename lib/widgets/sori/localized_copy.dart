import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';

/// Sori Stage의 ARB 기반 복사본 해석 — widget 층 정본 (§C-3c P0-1).
///
/// [SoriLocalizedCopy]의 `activityId`/`key`를 ARB ICU select 문으로 매핑한다.
/// 1순위: activityId → `soriStageActivityTitle` / `soriStageActivityDescription`
/// 2순위: key → `soriStageCatalogCopy`
/// 최후 fallback: `resolve(lang)` (미래에 제거 대상, non-production 전용).
String localCopy(BuildContext context, SoriLocalizedCopy copy) {
  final t = AppL10n.of(context);
  final activityId = copy.activityId;
  if (activityId != null) {
    return copy.isActivityDescription
        ? t.soriStageActivityDescription(activityId)
        : t.soriStageActivityTitle(activityId);
  }
  final key = copy.key;
  if (key != null) {
    return t.soriStageCatalogCopy(key.name);
  }
  // 폴백은 테스트 픽스처 전용 — 프로덕션 화면은 항상 activityId 또는 key 를
  // 넘긴다. `SoriLocalizedCopy` 에는 이 목적의 별도 resolver 메서드가 더
  // 이상 없다(삭제됨) — 오용할 API 자체가 사라졌다.
  return Localizations.localeOf(context).languageCode == 'de'
      ? copy.de
      : copy.en;
}
