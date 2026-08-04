import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/room_placement_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

const _twoFloorSlots = <SlotDef>[
  (
    id: 'floor_one',
    leftFrac: 0.0,
    bottomFrac: 0.0,
    widthFrac: 0.4,
    heightFrac: 0.0,
    accepts: DecorCategory.floor,
    anchor: DecorAnchor.bottom,
  ),
  (
    id: 'floor_two',
    leftFrac: 0.5,
    bottomFrac: 0.0,
    widthFrac: 0.4,
    heightFrac: 0.0,
    accepts: DecorCategory.floor,
    anchor: DecorAnchor.bottom,
  ),
  (
    id: 'wall',
    leftFrac: 0.0,
    bottomFrac: 0.5,
    widthFrac: 0.4,
    heightFrac: 0.3,
    accepts: DecorCategory.wall,
    anchor: DecorAnchor.center,
  ),
];

void main() {
  group('RoomPlacementService.sanitize', () {
    test('keeps only compatible unique placements in slot order', () {
      final placement = RoomPlacementService.sanitize({
        'floor_two': 'decoration_soban',
        'floor_one': 'decoration_soban',
        'wall': 'decoration_chaekgado',
        'obsolete': 'decoration_seoan',
      }, slots: _twoFloorSlots);

      expect(placement, {
        'floor_one': 'decoration_soban',
        'wall': 'decoration_chaekgado',
      });
    });
  });

  group('RoomPlacementService.candidatesForSlot', () {
    test('offers compatible owned decor that is not used in another slot', () {
      final candidates = RoomPlacementService.candidatesForSlot(
        _twoFloorSlots[1],
        owned: const [
          'decoration_soban',
          'decoration_soban',
          'decoration_seoan',
          'decoration_chaekgado',
        ],
        placement: const {'floor_one': 'decoration_soban'},
        slots: _twoFloorSlots,
      );

      expect(candidates, ['decoration_seoan']);
    });
  });

  group('RoomPlacementService.placeInSlot', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.addOwnedDecor('decoration_soban');
    });

    test('persists only an owned decor in its compatible slot', () async {
      expect(
        await RoomPlacementService.placeInSlot(
          'floor_center',
          'decoration_soban',
        ),
        RoomPlacementWriteResult.placed,
      );
      expect(Storage.roomPlacement, {'floor_center': 'decoration_soban'});

      expect(
        await RoomPlacementService.placeInSlot(
          'floor_center',
          'decoration_seoan',
        ),
        RoomPlacementWriteResult.notOwned,
      );
      expect(Storage.roomPlacement, {'floor_center': 'decoration_soban'});

      expect(
        await RoomPlacementService.placeInSlot('wall_back', 'decoration_soban'),
        RoomPlacementWriteResult.incompatible,
      );
      expect(Storage.roomPlacement, {'floor_center': 'decoration_soban'});

      expect(
        await RoomPlacementService.placeInSlot('missing', null),
        RoomPlacementWriteResult.unknownSlot,
      );

      expect(
        await RoomPlacementService.placeInSlot('floor_center', null),
        RoomPlacementWriteResult.cleared,
      );
      expect(Storage.roomPlacement, isEmpty);
    });
  });
}
