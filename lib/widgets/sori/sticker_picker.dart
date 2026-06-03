import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import 'tokens.dart';

/// 스티커 키보드 — 6 카테고리 탭 × 5종. 선택 시 [onPick](code). plan §8.2.
class StickerPicker extends StatelessWidget {
  final void Function(int code) onPick;

  const StickerPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    const cats = StickerCategory.values;
    return DefaultTabController(
      length: cats.length,
      child: SizedBox(
        height: 380,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final c in cats) Tab(text: _catLabel(t, c))],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final c in cats)
                    GridView.count(
                      crossAxisCount: 4,
                      padding: const EdgeInsets.all(Spacing.md),
                      children: [
                        for (final st
                            in kStickers.where((s) => s.category == c))
                          InkWell(
                            onTap: () => onPick(st.code),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                st.asset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.emoji_emotions_outlined,
                                  color: SoriColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(AppL10n t, StickerCategory c) => switch (c) {
        StickerCategory.tiger => t.gyeStickerCatTiger,
        StickerCategory.magpie => t.gyeStickerCatMagpie,
        StickerCategory.dancheong => t.gyeStickerCatDancheong,
        StickerCategory.hangul => t.gyeStickerCatHangul,
        StickerCategory.food => t.gyeStickerCatFood,
        StickerCategory.stamp => t.gyeStickerCatStamp,
      };
}
