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
  static const Color hanjiCream = Color(0xFFFAF6EC);

  /// 짙은 종이톤 (그림자/borders).
  static const Color hanjiCreamDark = Color(0xFFE8E0CC);

  /// dark mode 한지 (어두운 종이/장지).
  static const Color hanjiNight = Color(0xFF2A2418);

  /// 먹 (ink) — 한지 위 글씨 색.
  static const Color hanjiInk = Color(0xFF2C2419);

  // ── 단청 5색 (Obangsaek 오방색 — 정통 한국 5색) ────────────────────────
  /// 청 (동방, 봄, 나무) — 청록.
  /// teal primary와 family 같음 — 보색 충돌 X.
  static const Color cheong = Color(0xFF3D9A7F);

  /// 적 (남방, 여름, 불) — 진한 주홍.
  static const Color jeok = Color(0xFFC24A45);

  /// 황 (중앙, 토) — 황금.
  /// SoriColors.gold와 의도적으로 비슷 — 갓끈/별/XP 톤 일관.
  static const Color hwang = Color(0xFFDFA951);

  /// 백 (서방, 가을, 금) — 한지 백.
  static const Color baek = Color(0xFFF5F0E6);

  /// 흑 (북방, 겨울, 물) — 먹.
  static const Color heuk = Color(0xFF2C2419);

  // ── 단청 muted 변형 (alpha 0.55) ─────────────────────────────────────
  // dancheong_divider 등 décor에서 인라인 `.withValues(alpha: 0.55)` 패턴을
  // 토큰화. const 컴파일 가능하도록 Color.fromARGB로 미리 합성.
  // 0.55 ≈ 140/255 (8-bit 알파).
  static const Color cheongMuted = Color(0x8C3D9A7F); // 0x8C = 140
  static const Color jeokMuted = Color(0x8CC24A45);
  static const Color hwangMuted = Color(0x8CDFA951);

  // ── 기와 (roof tiles) ─────────────────────────────────────────────────
  static const Color giwaGray = Color(0xFF5C6470);
  static const Color giwaShadow = Color(0xFF3A4148);

  /// 기와 highlight (햇빛 반사).
  static const Color giwaHi = Color(0xFF7A828E);

  // ── 황토 (earth, 한옥 기둥/대들보) ────────────────────────────────────
  static const Color hwangtoLight = Color(0xFFC9A77F);
  static const Color hwangto = Color(0xFFA87E5E);
  static const Color hwangtoDark = Color(0xFF6B4A35);

  // ── 마당 그라데이션 (Home 배경 madang painter) ─────────────────────────
  /// 마당 sky (위쪽, 밤하늘 어두운 teal)
  static const Color madangSkyDark = Color(0xFF0A2E3A);

  /// 마당 sky light (낮시간 밝은 cream)
  static const Color madangSkyLight = Color(0xFFE8EFE9);

  /// 마당 ground (아래쪽 한지 크림)
  static const Color madangGround = Color(0xFFEDE2C8);

  /// 마당 ground dark (밤 한옥 마당 색)
  static const Color madangGroundDark = Color(0xFF15201A);
}

/// **레벨 사다리 팔레트 (사계 단청)** — CEFR 4단계를 봄·여름·가을·겨울
/// 단청 4색으로 매핑한다. 온보딩 레벨 선택 화면과 이후 레벨 배지가 공유하는
/// 단일 소스.
///
/// **왜 [SoriColors]를 그대로 못 쓰는가 (2026-07-31 감사)**
/// 기존 온보딩은 A1=`SoriColors.success`, A2=`SoriColors.primary`를 썼는데
/// 두 토큰은 v6.0에서 **같은 값 `#1F7A6B`** 이 되었다 → A1·A2 배지가 픽셀
/// 단위로 동일해 레벨 구분이 사라져 있었다. 또 B1=`warning`(황),
/// B2는 `hangul`(석간주 적)이라 "초록=안전 / 노랑=주의 / 빨강=위험"이라는
/// 신호등 의미가 얹혀, 상급 레벨이 *위험*으로 읽히는 부작용이 있었다.
/// 이 팔레트는 기능색(success/warning/danger)과 완전히 분리된 **서열색**이다.
///
/// **대비 검증 (한지 크림 `#FAF6EC` 기준, WCAG 2.1)**
/// | 레벨 | 색 | 흰 글씨 대비 | 크림 위 도형 대비 |
/// |------|-----|------------|-----------------|
/// | A1 청 | `#2E7D68` | 4.94:1 ✅ | 4.58:1 ✅ |
/// | A2 황 | `#8F6C14` | 4.86:1 ✅ | 4.50:1 ✅ |
/// | B1 적 | `#A0403C` | 6.38:1 ✅ | 5.91:1 ✅ |
/// | B2 청금 | `#44607F` | 6.51:1 ✅ | 6.03:1 ✅ |
///
/// ⚠️ **색만으로 서열을 전달하지 말 것.** 네 색의 상호 명도 대비는
/// 1.02~1.34:1로, 색각 이상 사용자에게는 서열이 보이지 않는다. 반드시
/// [rankOf]가 주는 채움 도트(1~4개) 같은 **비색상 신호**를 함께 쓴다.
class HanokLevelPalette {
  HanokLevelPalette._();

  /// A1 — 봄 청(靑). 시작·새싹.
  static const Color a1 = Color(0xFF2E7D68);

  /// A2 — 여름 황(黃). 자람. (`HanokColors.hwang`를 흰 글씨 AA까지 어둡게)
  static const Color a2 = Color(0xFF8F6C14);

  /// B1 — 가을 적(赤). 여묾. (`HanokColors.jeok` 어둡게)
  static const Color b1 = Color(0xFFA0403C);

  /// B2 — 겨울 청금(靑金). 완숙. (`SoriColors.highlight` 어둡게)
  static const Color b2 = Color(0xFF44607F);

  /// 레벨 코드(`a1`/`a2`/`b1`/`b2`, 대소문자 무관) → 사계 색.
  /// 미지의 코드는 A1 색으로 안전 폴백한다.
  static Color of(String levelCode) {
    switch (levelCode.toLowerCase()) {
      case 'a2':
        return a2;
      case 'b1':
        return b1;
      case 'b2':
        return b2;
      default:
        return a1;
    }
  }

  /// 레벨 코드 → 서열(1~4). 채움 도트 개수·`Semantics` 라벨에 쓴다.
  static int rankOf(String levelCode) {
    switch (levelCode.toLowerCase()) {
      case 'a2':
        return 2;
      case 'b1':
        return 3;
      case 'b2':
        return 4;
      default:
        return 1;
    }
  }

  /// 서열 총 단계 수 — 도트 개수·"n / 4" 라벨의 분모.
  static const int rankCount = 4;
}

/// 한옥 décor 치수 단위 — [Spacing]과 별도로 décor 전용.
class HanokSizing {
  HanokSizing._();

  /// 처마 (eaves) 상단 BorderRadius 추가 보정.
  /// SoriRadius.lg(20) + eavesBoost(8) = 28pt 위쪽만 더 큰 비대칭 corner.
  static const double eavesBoostTop = 8;

  /// 한지 섬유 강도(intensity, 0~0.2). "은은 크림" 룩 — 카드·헤로 기본(살짝 또렷).
  /// 전체 화면 배경(SoriScreenBackground)은 더 낮은 값(0.11)을 넘겨 더 은은.
  static const double hanjiNoiseAlpha = 0.13;

  /// 단청 도트 sizes.
  static const double dancheongDotSm = 3;
  static const double dancheongDotMd = 4;
  static const double dancheongDotLg = 6;

  /// 기와 (roof tile) row 높이.
  static const double giwaRowHeight = 12;

  /// 단청 stripe 두께.
  static const double dancheongStripeThin = 1.2;
  static const double dancheongStripeThick = 2.5;
}
