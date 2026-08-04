import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_room_catalog.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  test(
    'anbang and daecheong preserve the five collectible slot categories',
    () {
      for (final surface in const [
        PersonalRoomSurface.anbang,
        PersonalRoomSurface.daecheongmaru,
      ]) {
        final room = personalRoomFor(surface);
        expect(room.slots, hasLength(5));
        expect(room.slots.map((slot) => slot.accepts), const [
          DecorCategory.wall,
          DecorCategory.floor,
          DecorCategory.shelf,
          DecorCategory.shelf,
          DecorCategory.peg,
        ]);
      }
    },
  );
}
