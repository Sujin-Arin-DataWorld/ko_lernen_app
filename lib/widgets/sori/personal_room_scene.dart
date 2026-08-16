import 'package:flutter/material.dart';

import '../../data/personal_room_catalog.dart';
import '../../models/personal_room.dart';
import '../../models/room_layout.dart';
import 'free_room_layer.dart';
import 'placed_decoration.dart';
import 'room_layer.dart';
import 'tokens.dart';

/// Shared visual projection of a private Hanok interior.
///
/// It receives already-read placement data and never fetches storage, opens a
/// route, or writes a placement. Production callers use the marker-free v3
/// canvas; the slot path remains only for rollback-compatible projections and
/// tests. Study callers get the exact same room as a read-only scene.
class PersonalRoomScene extends StatelessWidget {
  final PersonalRoomSurface surface;
  final RoomLayouts? layouts;
  final RoomPlacements placements;
  final Set<String> owned;
  final bool interactive;
  final void Function(SlotDef slot)? onTapSlot;
  final String? selectedId;
  final ValueChanged<String>? onSelectItem;
  final RoomItemTransformCallback? onTransformItem;
  final RoomItemTransformCallback? onTransformEnd;

  const PersonalRoomScene({
    super.key,
    required this.surface,
    this.layouts,
    this.placements = const {},
    this.owned = const {},
    required this.interactive,
    this.onTapSlot,
    this.selectedId,
    this.onSelectItem,
    this.onTransformItem,
    this.onTransformEnd,
  }) : assert(
         !interactive ||
             (layouts != null ? onSelectItem != null : onTapSlot != null),
       );

  @override
  Widget build(BuildContext context) {
    final room = personalRoomFor(surface);
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: SoriRadius.brLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              room.backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) =>
                  ColoredBox(color: SoriSurfaces.of(ctx).surfaceAlt),
            ),
            if (layouts case final freeLayouts?)
              FreeRoomLayer(
                items: freeLayouts[surface] ?? const <RoomLayoutItem>[],
                interactive: interactive,
                selectedId: selectedId,
                onSelect: interactive ? onSelectItem : null,
                onTransform: interactive ? onTransformItem : null,
                onTransformEnd: interactive ? onTransformEnd : null,
              )
            else
              RoomLayer(
                surface: surface,
                slots: room.slots,
                placements: placements,
                owned: owned,
                showEmptyMarkers: interactive,
                onTapSlot: interactive ? onTapSlot : null,
              ),
          ],
        ),
      ),
    );
  }
}
