import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_room_catalog.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  test('Sarangbang preserves the five collectible slot categories', () {
    final room = personalRoomFor(PersonalRoomSurface.sarangbang);
    expect(room.slots, hasLength(5));
    expect(room.slots.map((slot) => slot.accepts), const [
      DecorCategory.wall,
      DecorCategory.floor,
      DecorCategory.shelf,
      DecorCategory.shelf,
      DecorCategory.peg,
    ]);
  });

  test('each personal room points to an available opaque room shell', () {
    for (final surface in const [PersonalRoomSurface.sarangbang]) {
      expect(
        File(personalRoomFor(surface).backgroundAsset).existsSync(),
        isTrue,
      );
    }
  });
}
