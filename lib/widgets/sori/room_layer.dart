import 'package:flutter/material.dart';

import 'placed_decoration.dart';
import 'tokens.dart';

/// 방 표면의 슬롯 렌더 — 배치된 장식 + 비어 있는 슬롯의 표식.
///
/// ADR-002 개정(보자기): **미리 보여주지 않는다.** 실루엣은 폐기했다.
/// 빈 슬롯은 그 카테고리에 **놓을 게 실제로 있을 때만** 표식을 띄운다 —
/// 아무것도 없는데 표식을 띄우면 할 수 없는 일을 광고하는 셈이라 소음이다.
/// 방의 빈 벽감과 빈 횃대는 그림 자체가 이미 "여기 뭔가 온다"고 말한다.
///
/// 마당(`DecorationLayer`)과 좌표 규약이 같아 렌더 부품을 공유한다.
class RoomLayer extends StatelessWidget {
  /// 이 표면의 슬롯 정의.
  final List<SlotDef> slots;

  /// 슬롯 id → 장식 슬러그.
  final RoomPlacement placement;

  /// 유저가 보유한 장식 슬러그. 빈 슬롯 표식 여부를 여기서 판단한다.
  final Set<String> owned;

  /// 슬롯을 탭했을 때. null 이면 보기 전용(탭 불가).
  final void Function(SlotDef slot)? onTapSlot;

  const RoomLayer({
    super.key,
    required this.slots,
    required this.placement,
    this.owned = const {},
    this.onTapSlot,
  });

  /// [slot] 에 놓을 수 있는 보유 장식이 하나라도 있는가.
  bool _hasCandidate(SlotDef slot) =>
      owned.any((s) => decorCategoryOf(s) == slot.accepts);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          children: [
            for (final slot in slots)
              () {
                final storedSlug = placement[slot.id];
                // SharedPreferences 는 신뢰 경계가 아니다. 예전 버전/손상된
                // 저장값이 다른 카테고리의 장식을 가리켜도 그 슬롯에 그리지
                // 않는다 — 슬롯 카테고리 계약을 화면에서도 fail-closed 한다.
                final slug = storedSlug != null &&
                        decorCategoryOf(storedSlug) == slot.accepts
                    ? storedSlug
                    : null;
                return _SlotView(
                  slot: slot,
                  slug: slug,
                  showMarker: slug == null && _hasCandidate(slot),
                  canvasWidth: w,
                  canvasHeight: h,
                  onTap: onTapSlot == null ? null : () => onTapSlot!(slot),
                );
              }(),
          ],
        );
      },
    );
  }
}

class _SlotView extends StatelessWidget {
  final SlotDef slot;
  final String? slug;
  final bool showMarker;
  final double canvasWidth;
  final double canvasHeight;
  final VoidCallback? onTap;

  const _SlotView({
    required this.slot,
    required this.slug,
    required this.showMarker,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 빈 슬롯인데 놓을 것도 없으면 아무것도 그리지 않는다 — 탭 영역도 없다.
    if (slug == null && !showMarker) return const SizedBox.shrink();

    final boxW = canvasWidth * slot.widthFrac;
    final left = canvasWidth * slot.leftFrac;
    final bottom = canvasHeight * slot.bottomFrac;

    // 아이템 폭 = 슬롯 폭 × 상대 크기. 같은 슬롯에 소반과 문갑이 번갈아 들어가도
    // 각자의 자연스러운 크기로 그려진다.
    final itemW = slug == null ? boxW : boxW * decorScale(slug!);

    Widget content = slug != null
        ? SoriDecorationImage(slug: slug!, size: itemW)
        : _SlotMarker(width: boxW);

    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    // ⚠️ `Positioned` 는 Stack 의 **직계 자식**이어야 한다. 바깥을 다른 위젯으로
    // 감싸면 좌표가 통째로 무시되고 전부 좌상단에 겹친다 — 반드시 최상위로 반환.
    if (slot.anchor == DecorAnchor.center && slot.heightFrac > 0) {
      // 박스를 먼저 정하고 그 안에서 가운데 정렬. 높이를 몰라도 안정적이고,
      // `BoxFit.contain` 이라 큰 병풍도 슬롯 밖으로 안 넘친다.
      final boxH = canvasHeight * slot.heightFrac;
      return Positioned(
        left: left,
        bottom: bottom,
        width: boxW,
        height: boxH,
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(width: itemW, height: boxH, child: content),
        ),
      );
    }

    // 바닥 앵커 — 마당(`DecorationLayer`)과 같은 규약: 폭만 고정, 높이는 비율대로.
    return Positioned(left: left, bottom: bottom, width: itemW, child: content);
  }
}

/// 빈 슬롯 표식 — 놓을 게 있을 때만 나온다.
///
/// 조용해야 한다. 그림 위에 얹히는 UI 라 세게 그리면 한옥 방이 편집 도구처럼
/// 보인다. 얇은 테두리 + 작은 ⊕ 정도로 "여기 누를 수 있다"만 전달한다.
class _SlotMarker extends StatelessWidget {
  final double width;

  const _SlotMarker({required this.width});

  @override
  Widget build(BuildContext context) {
    final r = (width * 0.13).clamp(9.0, 18.0);
    return Container(
      width: width,
      height: width * 0.62,
      decoration: BoxDecoration(
        border: Border.all(
          color: SoriColors.primary.withValues(alpha: 0.38),
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.add_circle_outline,
        size: r * 2,
        color: SoriColors.primary.withValues(alpha: 0.55),
      ),
    );
  }
}
