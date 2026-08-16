import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/sticker_localizations.dart';
import 'responsive.dart';
import 'sticker_image.dart';
import 'tokens.dart';

/// 스티커 키보드 — 6 카테고리 탭 × 5종. 선택 시 [onPick](code). plan §8.2.
class StickerPicker extends StatelessWidget {
  final void Function(int code) onPick;

  const StickerPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final media = MediaQuery.of(context);
    final availableHeight = math.max(
      0.0,
      media.size.height - media.padding.vertical - media.viewInsets.bottom,
    );
    final pickerHeight = math.min(380.0, availableHeight * 0.72);
    final tabHeight = math.max(
      kMinInteractiveDimension,
      media.textScaler.scale(14) * 1.25 + Spacing.lg,
    );
    const cats = StickerCategory.values;
    return DefaultTabController(
      length: cats.length,
      child: SizedBox(
        height: pickerHeight,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final c in cats)
                  Tab(
                    height: tabHeight,
                    child: Text(
                      _catLabel(t, c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final c in cats)
                    _StickerGrid(
                      stickers: kStickers
                          .where((sticker) => sticker.category == c)
                          .toList(growable: false),
                      onPick: onPick,
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

class _StickerGrid extends StatelessWidget {
  final List<StickerSpec> stickers;
  final void Function(int code) onPick;

  const _StickerGrid({required this.stickers, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = soriGridColumns(
          constraints.maxWidth,
          target: 80,
          min: 3,
          max: 5,
          outerPadding: Spacing.md * 2,
          spacing: Spacing.sm,
        );
        return GridView.builder(
          key: PageStorageKey(stickers.first.category),
          padding: const EdgeInsets.all(Spacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
          ),
          itemCount: stickers.length,
          semanticChildCount: stickers.length,
          itemBuilder: (context, index) {
            final sticker = stickers[index];
            final label = stickerName(t, sticker);
            void pick() => onPick(sticker.code);
            return Semantics(
              key: ValueKey('sticker-button-${sticker.code}'),
              container: true,
              button: true,
              label: label,
              onTap: pick,
              excludeSemantics: true,
              child: Tooltip(
                message: label,
                child: InkWell(
                  onTap: pick,
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xs),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StickerImage(
                        spec: sticker,
                        size: 72,
                        semantic: '',
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
