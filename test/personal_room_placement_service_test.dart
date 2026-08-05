import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/services/room_placement_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.addOwnedDecor('decoration_soban');
  });

  test('moves an owned decor out of another personal room', () async {
    expect(
      await RoomPlacementService.placeInSurfaceSlot(
        PersonalRoomSurface.sarangbang,
        'floor_center',
        'decoration_soban',
      ),
      RoomPlacementWriteResult.placed,
    );

    expect(
      await RoomPlacementService.placeInSurfaceSlot(
        PersonalRoomSurface.anbang,
        'floor_center',
        'decoration_soban',
      ),
      RoomPlacementWriteResult.placed,
    );

    expect(Storage.roomPlacements[PersonalRoomSurface.sarangbang], isNull);
    expect(Storage.roomPlacements[PersonalRoomSurface.anbang], {
      'floor_center': 'decoration_soban',
    });
  });

  test('does not offer the only candidate while it is in another room', () {
    final candidates = RoomPlacementService.candidatesForSurfaceSlot(
      PersonalRoomSurface.sarangbang,
      kSarangbangSlots.firstWhere((slot) => slot.id == 'floor_center'),
      owned: const {'decoration_soban'},
      placements: const {
        PersonalRoomSurface.anbang: {'floor_center': 'decoration_soban'},
      },
    );

    expect(candidates, isEmpty);
  });
}
