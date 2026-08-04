import 'package:flutter/material.dart';

import '../../data/quest_catalog.dart';
import '../../models/quest.dart';
import '../../services/storage_service.dart';
import 'placed_decoration.dart';

// 공통 부품은 `placed_decoration.dart` 로 옮겼다(ADR-002 — 마당·방이 공유).
// `kAvailableDecorations` 는 `quests_screen.dart` 가 여기서 import 하고 있어
// 재수출로 기존 호출부를 그대로 둔다.
export 'placed_decoration.dart'
    show kAvailableDecorations, DecorCategory, decorCategoryOf;

/// Phase 4 (stately-rising-jongga) — 클리어된 퀘스트 장식을 마당에 합성.
///
/// **사용처**: 홈 마당 배경 위에 stack. 장식 PNG (`assets/illustrations/
/// decorations/{slug}.png`) 가 없으면 작은 동그란 아이콘 fallback.
///
/// **위치**: 각 퀘스트 정의의 `layout` (leftFrac, bottomFrac, widthFrac)
/// 사용. 부모 위젯의 BoxConstraints 가 maxWidth/maxHeight 으로 변환된다.
class DecorationLayer extends StatelessWidget {
  /// 표시할 퀘스트 IDs. null 이면 `Storage.questCompletions` 키 자동 사용.
  final Iterable<String>? completedQuestIds;

  const DecorationLayer({super.key, this.completedQuestIds});

  @override
  Widget build(BuildContext context) {
    final ids = completedQuestIds ?? Storage.questCompletions.keys;
    if (ids.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final id in ids)
              if (kQuestById[id] != null)
                _PositionedDecoration(
                  def: kQuestById[id]!,
                  canvasWidth: w,
                  canvasHeight: h,
                ),
          ],
        );
      },
    );
  }
}

class _PositionedDecoration extends StatelessWidget {
  final QuestDefinition def;
  final double canvasWidth;
  final double canvasHeight;
  const _PositionedDecoration({
    required this.def,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    final w = canvasWidth * def.layout.widthFrac;
    final left = canvasWidth * def.layout.leftFrac;
    final bottom = canvasHeight * def.layout.bottomFrac;

    return Positioned(
      left: left,
      bottom: bottom,
      width: w,
      child: IgnorePointer(
        child: SoriDecorationImage(slug: def.decorationSlug, size: w),
      ),
    );
  }
}
