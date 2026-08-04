import 'package:flutter/widgets.dart';

import 'premium_service.dart';

/// 팩 접근 게이트 단일화 (2026-08-04 감사 #7).
///
/// 규칙: A1 무료 · A2/B1/B2 는 프리미엄 (vocab_packs_screen 과 동일).
/// 홈 히어로·홈 미리보기·`/path` 노드의 중복 인라인 게이트를 이걸로 수렴 —
/// 정책이 바뀌면 이 한 곳만 고친다.
Future<bool> ensurePackAccess(BuildContext context, {required String level}) {
  if (level.toUpperCase() == 'A1' || PremiumService.isPremium) {
    return Future.value(true);
  }
  return PremiumService.gate(context);
}
