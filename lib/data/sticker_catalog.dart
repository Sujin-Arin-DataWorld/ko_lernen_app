/// 계 스티커 카탈로그 — 30종(코드 1~30, 6 카테고리 × 5). plan §8.2.
/// 자산: `assets/stickers/{slug}.png`.
enum StickerCategory { tiger, magpie, dancheong, hangul, food, stamp }

/// Stable sticker wire identity and asset metadata.
///
/// User-facing names live in ARB and are projected by `stickerName` so every
/// screen and semantics node uses the same localized copy.
class StickerSpec {
  final int code;
  final String slug;
  final StickerCategory category;

  const StickerSpec(this.code, this.slug, this.category);

  String get asset => 'assets/stickers/$slug.png';
}

/// Backwards-compatible name for code that predates the semantic catalog.
@Deprecated('Use StickerSpec')
typedef StickerDef = StickerSpec;

const List<StickerSpec> kStickers = [
  StickerSpec(1, 'tiger_cheer', StickerCategory.tiger),
  StickerSpec(2, 'tiger_clap', StickerCategory.tiger),
  StickerSpec(3, 'tiger_surprised_new', StickerCategory.tiger),
  StickerSpec(4, 'tiger_sad', StickerCategory.tiger),
  StickerSpec(5, 'tiger_love', StickerCategory.tiger),
  StickerSpec(6, 'magpie_dance', StickerCategory.magpie),
  StickerSpec(7, 'magpie_wave', StickerCategory.magpie),
  StickerSpec(8, 'magpie_sleep', StickerCategory.magpie),
  StickerSpec(9, 'magpie_sing', StickerCategory.magpie),
  StickerSpec(10, 'magpie_encourage', StickerCategory.magpie),
  StickerSpec(11, 'dancheong_flower', StickerCategory.dancheong),
  StickerSpec(12, 'dancheong_star', StickerCategory.dancheong),
  StickerSpec(13, 'dancheong_cloud', StickerCategory.dancheong),
  StickerSpec(14, 'dancheong_lantern', StickerCategory.dancheong),
  StickerSpec(15, 'dancheong_hanji', StickerCategory.dancheong),
  StickerSpec(16, 'hangul_kk', StickerCategory.hangul),
  StickerSpec(17, 'hangul_hh', StickerCategory.hangul),
  StickerSpec(18, 'hangul_fighting', StickerCategory.hangul),
  StickerSpec(19, 'hangul_best', StickerCategory.hangul),
  StickerSpec(20, 'hangul_good', StickerCategory.hangul),
  StickerSpec(21, 'food_tteok', StickerCategory.food),
  StickerSpec(22, 'food_tea', StickerCategory.food),
  StickerSpec(23, 'food_kimbap', StickerCategory.food),
  StickerSpec(24, 'food_hotteok', StickerCategory.food),
  StickerSpec(25, 'food_sikhye', StickerCategory.food),
  StickerSpec(26, 'stamp_sticker_well_done', StickerCategory.stamp),
  StickerSpec(27, 'stamp_sticker_fighting', StickerCategory.stamp),
  StickerSpec(28, 'stamp_sticker_love', StickerCategory.stamp),
  StickerSpec(29, 'stamp_sticker_cheer', StickerCategory.stamp),
  StickerSpec(30, 'stamp_sticker_happy', StickerCategory.stamp),
];

/// 코드(1~30) → 정의 (범위 밖이면 null).
StickerSpec? stickerByCode(int code) =>
    (code >= 1 && code <= kStickers.length) ? kStickers[code - 1] : null;
