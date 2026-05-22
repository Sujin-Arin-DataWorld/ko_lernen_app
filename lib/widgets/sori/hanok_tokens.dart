import 'package:flutter/material.dart';

/// **Hanok Tokens** — 한옥 visual vocabulary 전용 색·치수 const.
///
/// **v6.0 변경**: [SoriColors] 가 이제 단청 muted 팔레트(녹청 #1F7A6B 등)임.
/// [HanokColors] 는 그 위 vivid한 *장식 reference* 톤 — 둘은 의도적으로 다른 채도.
/// - SoriColors.primary `#1F7A6B` ← 기능 (button, CTA, AA contrast on hanji bg)
/// - HanokColors.cheong `#3D9A7F` ← 장식 dot, divider stripe (alpha 0.55 적용 후 적정)
///
/// 한옥 décor 전용 palette:
/// - 한지 (cream paper tones) — light bg는 SoriColors.lightBg와 중복(`#FAF6EC`), 의도적 alias.
/// - 단청 5색 (obangsaek — 청적황백흑, 정통 saturated reference)
/// - 기와 (roof tile grays)
/// - 황토 (earth tones, 한옥 기둥)
/// - 마당 (배경 그라데이션)
///
/// 사용 예:
/// ```dart
/// Container(
///   color: HanokColors.hanjiCream,   // == SoriColors.lightBg
///   child: DancheongDivider(),
/// )
/// ```
///
/// 룰:
/// - 기능적 컴포넌트 (버튼/카드 기본/CTA) → [SoriColors] (muted 단청)
/// - 장식적 décor (divider 도트/배경 texture/한옥 hero) → [HanokColors] (vivid 단청)
/// - 둘 동시 사용 시 기능은 muted, 장식은 vivid → 시각 위계 확보.
class HanokColors {
  HanokColors._();

  // ── 한지 (paper / cream) ──────────────────────────────────────────────
  /// 따뜻한 한지 종이톤. light mode surface 대체용.
  static const Color hanjiCream     = Color(0xFFFAF6EC);
  /// 짙은 종이톤 (그림자/borders).
  static const Color hanjiCreamDark = Color(0xFFE8E0CC);
  /// dark mode 한지 (어두운 종이/장지).
  static const Color hanjiNight     = Color(0xFF2A2418);
  /// 먹 (ink) — 한지 위 글씨 색.
  static const Color hanjiInk       = Color(0xFF2C2419);

  // ── 단청 5색 (Obangsaek 오방색 — 정통 한국 5색) ────────────────────────
  /// 청 (동방, 봄, 나무) — 청록.
  /// teal primary와 family 같음 — 보색 충돌 X.
  static const Color cheong = Color(0xFF3D9A7F);
  /// 적 (남방, 여름, 불) — 진한 주홍.
  static const Color jeok   = Color(0xFFC24A45);
  /// 황 (중앙, 토) — 황금.
  /// SoriColors.gold와 의도적으로 비슷 — 갓끈/별/XP 톤 일관.
  static const Color hwang  = Color(0xFFDFA951);
  /// 백 (서방, 가을, 금) — 한지 백.
  static const Color baek   = Color(0xFFF5F0E6);
  /// 흑 (북방, 겨울, 물) — 먹.
  static const Color heuk   = Color(0xFF2C2419);

  // ── 단청 muted 변형 (alpha 0.55) ─────────────────────────────────────
  // dancheong_divider 등 décor에서 인라인 `.withValues(alpha: 0.55)` 패턴을
  // 토큰화. const 컴파일 가능하도록 Color.fromARGB로 미리 합성.
  // 0.55 ≈ 140/255 (8-bit 알파).
  static const Color cheongMuted = Color(0x8C3D9A7F);  // 0x8C = 140
  static const Color jeokMuted   = Color(0x8CC24A45);
  static const Color hwangMuted  = Color(0x8CDFA951);

  // ── 기와 (roof tiles) ─────────────────────────────────────────────────
  static const Color giwaGray    = Color(0xFF5C6470);
  static const Color giwaShadow  = Color(0xFF3A4148);
  /// 기와 highlight (햇빛 반사).
  static const Color giwaHi      = Color(0xFF7A828E);

  // ── 황토 (earth, 한옥 기둥/대들보) ────────────────────────────────────
  static const Color hwangtoLight = Color(0xFFC9A77F);
  static const Color hwangto      = Color(0xFFA87E5E);
  static const Color hwangtoDark  = Color(0xFF6B4A35);

  // ── 마당 그라데이션 (Home 배경 madang painter) ─────────────────────────
  /// 마당 sky (위쪽, 밤하늘 어두운 teal)
  static const Color madangSkyDark   = Color(0xFF0A2E3A);
  /// 마당 sky light (낮시간 밝은 cream)
  static const Color madangSkyLight  = Color(0xFFE8EFE9);
  /// 마당 ground (아래쪽 한지 크림)
  static const Color madangGround    = Color(0xFFEDE2C8);
  /// 마당 ground dark (밤 한옥 마당 색)
  static const Color madangGroundDark = Color(0xFF15201A);
}

/// 한옥 décor 치수 단위 — [Spacing]과 별도로 décor 전용.
class HanokSizing {
  HanokSizing._();

  /// 처마 (eaves) 상단 BorderRadius 추가 보정.
  /// SoriRadius.lg(20) + eavesBoost(8) = 28pt 위쪽만 더 큰 비대칭 corner.
  static const double eavesBoostTop = 8;

  /// 한지 텍스처 noise 강도 (0~1, 0.04 = 거의 안 보이는 미세 grain).
  static const double hanjiNoiseAlpha = 0.04;

  /// 단청 도트 sizes.
  static const double dancheongDotSm = 3;
  static const double dancheongDotMd = 4;
  static const double dancheongDotLg = 6;

  /// 기와 (roof tile) row 높이.
  static const double giwaRowHeight = 12;

  /// 단청 stripe 두께.
  static const double dancheongStripeThin  = 1.2;
  static const double dancheongStripeThick = 2.5;
}
