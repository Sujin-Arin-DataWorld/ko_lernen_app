import 'package:flutter/material.dart';

import '../../models/personal_room.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/room_placement_service.dart';
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
  /// The private room that owns [slots].
  final PersonalRoomSurface surface;

  /// 이 표면의 슬롯 정의.
  final List<SlotDef> slots;

  /// Compatibility input for a single room. New callers pass [placements] so
  /// candidates can see decorations displayed on every personal surface.
  final RoomPlacement? placement;

  /// All private room placements. A decoration in another room must count as
  /// used here too, otherwise empty slots turn into dead markers.
  final RoomPlacements placements;

  /// 유저가 보유한 장식 슬러그. 빈 슬롯 표식 여부를 여기서 판단한다.
  final Set<String> owned;

  /// 슬롯을 탭했을 때. null 이면 보기 전용(탭 불가).
  final void Function(SlotDef slot)? onTapSlot;

  /// Furnishing screens show available empty slots. Read-only scenes keep the
  /// placed decor but hide those affordances because they cannot be acted on.
  final bool showEmptyMarkers;
  final ValueChanged<String>? onInspectDecoration;
  final Set<String> inspectableDecorationSlugs;

  const RoomLayer({
    super.key,
    this.surface = PersonalRoomSurface.sarangbang,
    required this.slots,
    this.placement,
    this.placements = const {},
    this.owned = const {},
    this.onTapSlot,
    this.showEmptyMarkers = true,
    this.onInspectDecoration,
    this.inspectableDecorationSlugs = const {},
  });

  RoomPlacement get _placement =>
      placement ?? placements[surface] ?? const <String, String>{};

  RoomPlacements get _placements => <PersonalRoomSurface, RoomPlacement>{
    ...placements,
    if (placement != null) surface: _placement,
  };

  /// [slot] 에 지금 놓을 수 있는 보유 장식이 하나라도 있는가.
  ///
  /// 판단을 [RoomPlacementService] 에 맡긴다. 카테고리만 보면 다른 슬롯에
  /// 이미 놓인 장식까지 세어 **누르면 빈 목록이 뜨는 죽은 마커** 가 생긴다.
  /// 마커와 시트가 같은 규칙을 써야 하므로 규칙은 한 곳에만 둔다.
  bool _hasCandidate(SlotDef slot) =>
      RoomPlacementService.candidatesForSurfaceSlot(
        surface,
        slot,
        owned: owned,
        placements: _placements,
      ).isNotEmpty;

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
                final storedSlug = _placement[slot.id];
                // SharedPreferences 는 신뢰 경계가 아니다. 예전 버전/손상된
                // 저장값이 다른 카테고리의 장식을 가리켜도 그 슬롯에 그리지
                // 않는다 — 슬롯 카테고리 계약을 화면에서도 fail-closed 한다.
                final slug =
                    storedSlug != null &&
                        decorCategoryOf(storedSlug) == slot.accepts
                    ? storedSlug
                    : null;
                return _SlotView(
                  slot: slot,
                  slug: slug,
                  showMarker:
                      showEmptyMarkers && slug == null && _hasCandidate(slot),
                  canvasWidth: w,
                  canvasHeight: h,
                  onTap: onTapSlot == null ? null : () => onTapSlot!(slot),
                  onInspect:
                      slug != null &&
                          onInspectDecoration != null &&
                          inspectableDecorationSlugs.contains(slug)
                      ? () => onInspectDecoration!(slug)
                      : null,
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
  final VoidCallback? onInspect;

  const _SlotView({
    required this.slot,
    required this.slug,
    required this.showMarker,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onTap,
    required this.onInspect,
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

    final content = slug != null
        ? SoriDecorationImage(slug: slug!, size: itemW)
        : _SlotMarker(width: boxW);

    // ⚠️ `Positioned` 는 Stack 의 **직계 자식**이어야 한다. 바깥을 다른 위젯으로
    // 감싸면 좌표가 통째로 무시되고 전부 좌상단에 겹친다 — 반드시 최상위로 반환.
    if (slot.anchor == DecorAnchor.center && slot.heightFrac > 0) {
      // 박스를 먼저 정하고 그 안에서 가운데 정렬. 높이를 몰라도 안정적이고,
      // `BoxFit.contain` 이라 큰 병풍도 슬롯 밖으로 안 넘친다.
      final boxH = canvasHeight * slot.heightFrac;
      final centeredContent = Align(
        alignment: Alignment.center,
        child: SizedBox(width: itemW, height: boxH, child: content),
      );
      return Positioned(
        left: left,
        bottom: bottom,
        width: boxW,
        height: boxH,
        child: onTap != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: centeredContent,
              )
            : onInspect == null
            ? centeredContent
            : _RoomDecorationTapTarget(
                label: decorName(AppL10n.of(context), slug!),
                onTap: onInspect!,
                child: centeredContent,
              ),
      );
    }

    // 바닥 앵커 — 마당(`DecorationLayer`)과 같은 규약: 폭만 고정, 높이는 비율대로.
    if (onTap == null && onInspect == null) {
      return Positioned(
        left: left,
        bottom: bottom,
        width: itemW,
        child: content,
      );
    }

    // A PNG has no stable intrinsic height until its first decode completes.
    // Bind the gesture to the logical slot instead: the visual stays aligned
    // to its original bottom-left position while the whole intended placement
    // region remains tappable (including a minimum 48dp touch height).
    final tapHeight = boxW * 0.62 < 48.0 ? 48.0 : boxW * 0.62;
    return Positioned(
      left: left,
      bottom: bottom,
      width: boxW,
      height: tapHeight,
      child: onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(width: itemW, child: content),
              ),
            )
          : _RoomDecorationTapTarget(
              label: decorName(AppL10n.of(context), slug!),
              onTap: onInspect!,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(width: itemW, child: content),
              ),
            ),
    );
  }
}

class _RoomDecorationTapTarget extends StatelessWidget {
  const _RoomDecorationTapTarget({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppL10n.of(context).culturalHelpSemantics(label),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
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
