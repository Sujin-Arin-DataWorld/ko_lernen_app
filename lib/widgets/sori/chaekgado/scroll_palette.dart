import 'package:flutter/material.dart';

/// 두루마리(족자) 한 벌의 색 — 앱 안에서 펼쳐지는 [ChaekgadoScroll] 과 밖으로
/// 나가는 공유 이미지([ShareSlipRenderer]) 가 **같은 물건**으로 보이게 하는
/// 단일 소스.
///
/// 값의 출처는 두 곳뿐이다.
/// - 축·마구리·한지: `assets/illustrations/chaekgado/chaekgado_rod.png` 실측
///   (짙은 옻칠 몸통 + 금 마구리) 과 그 폴백으로 쓰이던 기존 팔레트.
/// - 단청 3색: `docs/assets/STYLE_LOCK.json` F-A 실측 팔레트
///   (`deepMutedTeal` · `dancheongGold` · `darkBrickRed`). 여기 값을 고칠 땐
///   STYLE_LOCK 이 먼저다 — BIBLE §1.3 명목값은 실측보다 밝아서 쓰지 않는다.
///
/// 왜 [SoriColors] 가 아닌가: 이건 기능색이 아니라 **한 오브젝트의 재질색**이다.
/// 팔레트 kill-switch(`palette_variant`) 로 teal 로 돌아가도 두루마리의 나무와
/// 금은 그대로여야 한다.
abstract final class SoriScrollPalette {
  // ── 한지 본지 ────────────────────────────────────────────────────────
  /// 글이 앉는 종이. `SoriColors.lightBg` 보다 반 톤 희다 — 종이가 배접 위로
  /// 떠올라야 두루마리로 읽힌다.
  static const Color paper = Color(0xFFFFFDF6);

  /// 종이 위 가로 괘선.
  static const Color rule = Color(0xFFEEE0C6);

  /// 종이 위 가장 작은 글씨(꼬리말).
  static const Color footnote = Color(0xFFB0A085);

  // ── 축(軸) — 짙은 옻칠 몸통 ──────────────────────────────────────────
  /// 위쪽 하이라이트(빛은 항상 왼쪽 위에서 — F-A camera 규약).
  static const Color rodTop = Color(0xFF7A5636);

  /// 몸통 중앙 옻칠.
  static const Color rodMid = Color(0xFF3E2B1B);

  /// 아래쪽 반사.
  static const Color rodBottom = Color(0xFF5C4028);

  // ── 마구리 — 금 ─────────────────────────────────────────────────────
  static const Color capTop = Color(0xFFE8BC6A);
  static const Color capBottom = Color(0xFFB98A34);

  // ── 단청 3색 (STYLE_LOCK F-A 실측) ───────────────────────────────────
  /// 청 — `deepMutedTeal`.
  static const Color dancheongTeal = Color(0xFF274A3F);

  /// 황 — `dancheongGold`.
  static const Color dancheongGold = Color(0xFFBD924C);

  /// 적 — `darkBrickRed`.
  static const Color dancheongBrick = Color(0xFF6A2316);
}
