import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/sticker_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/l10n/sticker_localizations.dart';

void main() {
  test('catalog exposes all 30 stickers exactly once', () {
    expect(kStickers, hasLength(30));
    expect(kStickers.map((sticker) => sticker.code).toSet(), hasLength(30));
    expect(kStickers.map((sticker) => sticker.slug).toSet(), hasLength(30));
    expect(
      kStickers.map((sticker) => sticker.code),
      orderedEquals(List<int>.generate(30, (index) => index + 1)),
    );

    for (final category in StickerCategory.values) {
      expect(
        kStickers.where((sticker) => sticker.category == category),
        hasLength(5),
        reason: '$category must stay reachable as one complete picker page',
      );
    }
  });

  test('every sticker has meaningful German and English labels', () {
    final de = AppL10nDe();
    final en = AppL10nEn();
    for (final sticker in kStickers) {
      expect(stickerName(de, sticker).trim(), isNotEmpty);
      expect(stickerName(en, sticker).trim(), isNotEmpty);
    }

    expect(stickerName(en, stickerByCode(16)!), contains('ㅋㅋ'));
    expect(stickerName(en, stickerByCode(17)!), contains('ㅎㅎ'));
    expect(stickerName(en, stickerByCode(18)!), contains('화이팅'));
    expect(stickerName(en, stickerByCode(19)!), contains('최고'));
    expect(stickerName(en, stickerByCode(20)!), contains('굿'));
  });

  test('code lookup keeps its wire-format boundary', () {
    expect(stickerByCode(1)?.slug, 'tiger_cheer');
    expect(stickerByCode(3)?.slug, 'tiger_surprised_new');
    expect(stickerByCode(30)?.slug, 'stamp_sticker_happy');
    expect(stickerByCode(0), isNull);
    expect(stickerByCode(31), isNull);
  });
}
