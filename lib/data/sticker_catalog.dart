/// 계 스티커 카탈로그 — 30종(코드 1~30, 6 카테고리 × 5). plan §8.2.
/// 자산: `assets/stickers/{slug}.png`.
enum StickerCategory { tiger, magpie, dancheong, hangul, food, stamp }

class StickerDef {
  final int code;
  final String slug;
  final StickerCategory category;
  const StickerDef(this.code, this.slug, this.category);

  String get asset => 'assets/stickers/$slug.png';
}

const List<StickerDef> kStickers = [
  // 호랑이 5
  StickerDef(1, 'tiger_cheer', StickerCategory.tiger),
  StickerDef(2, 'tiger_clap', StickerCategory.tiger),
  StickerDef(3, 'tiger_surprised', StickerCategory.tiger),
  StickerDef(4, 'tiger_sad', StickerCategory.tiger),
  StickerDef(5, 'tiger_love', StickerCategory.tiger),
  // 까치 5
  StickerDef(6, 'magpie_dance', StickerCategory.magpie),
  StickerDef(7, 'magpie_wave', StickerCategory.magpie),
  StickerDef(8, 'magpie_sleep', StickerCategory.magpie),
  StickerDef(9, 'magpie_sing', StickerCategory.magpie),
  StickerDef(10, 'magpie_encourage', StickerCategory.magpie),
  // 단청 모티프 5
  StickerDef(11, 'dancheong_flower', StickerCategory.dancheong),
  StickerDef(12, 'dancheong_star', StickerCategory.dancheong),
  StickerDef(13, 'dancheong_cloud', StickerCategory.dancheong),
  StickerDef(14, 'dancheong_lantern', StickerCategory.dancheong),
  StickerDef(15, 'dancheong_hanji', StickerCategory.dancheong),
  // 한글 자모 5
  StickerDef(16, 'hangul_kk', StickerCategory.hangul),
  StickerDef(17, 'hangul_hh', StickerCategory.hangul),
  StickerDef(18, 'hangul_fighting', StickerCategory.hangul),
  StickerDef(19, 'hangul_best', StickerCategory.hangul),
  StickerDef(20, 'hangul_good', StickerCategory.hangul),
  // 음식 5
  StickerDef(21, 'food_tteok', StickerCategory.food),
  StickerDef(22, 'food_tea', StickerCategory.food),
  StickerDef(23, 'food_kimbap', StickerCategory.food),
  StickerDef(24, 'food_hotteok', StickerCategory.food),
  StickerDef(25, 'food_sikhye', StickerCategory.food),
  // 도장 5
  StickerDef(26, 'stamp_sticker_well_done', StickerCategory.stamp),
  StickerDef(27, 'stamp_sticker_fighting', StickerCategory.stamp),
  StickerDef(28, 'stamp_sticker_love', StickerCategory.stamp),
  StickerDef(29, 'stamp_sticker_cheer', StickerCategory.stamp),
  StickerDef(30, 'stamp_sticker_happy', StickerCategory.stamp),
];

/// 코드(1~30) → 정의 (범위 밖이면 null).
StickerDef? stickerByCode(int code) =>
    (code >= 1 && code <= kStickers.length) ? kStickers[code - 1] : null;
