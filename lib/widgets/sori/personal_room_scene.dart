import 'package:flutter/material.dart';

import '../../data/personal_room_catalog.dart';
import '../../models/personal_room.dart';
import 'placed_decoration.dart';
import 'room_layer.dart';
import 'tokens.dart';

/// Shared visual projection of a private Hanok interior.
///
/// It receives already-read placement data and never fetches storage, opens a
/// route, or writes a placement. Furnishing callers opt into slot interaction;
/// study callers get the exact same room as a read-only scene.
class PersonalRoomScene extends StatelessWidget {
  final PersonalRoomSurface surface;
  final RoomPlacements placements;
  final Set<String> owned;
  final bool interactive;
  final void Function(SlotDef slot)? onTapSlot;

  const PersonalRoomScene({
    super.key,
    required this.surface,
    required this.placements,
    required this.owned,
    required this.interactive,
    this.onTapSlot,
  }) : assert(!interactive || onTapSlot != null);

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
