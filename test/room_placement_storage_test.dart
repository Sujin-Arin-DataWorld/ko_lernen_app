import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_room_placement': jsonEncode({
        'wall_back': 'decoration_pyeonaek',
        'floor_center': 17,
      }),
    });
    await Storage.init();
  });

  test('keeps valid room placements when one stored entry is malformed', () {
    expect(Storage.roomPlacement, {'wall_back': 'decoration_pyeonaek'});
  });

  test(
    'wraps a legacy flat placement as sarangbang only when v2 is absent',
    () {
      expect(Storage.roomPlacements, {
        PersonalRoomSurface.sarangbang: {'wall_back': 'decoration_pyeonaek'},
      });
    },
  );

  test(
    'does not revive legacy placement when an empty v2 payload exists',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_room_placement': jsonEncode({'wall_back': 'decoration_pyeonaek'}),
        'kl_room_placements_v2': jsonEncode({}),
      });
      await Storage.init();

      expect(Storage.roomPlacements, isEmpty);
      expect(Storage.roomPlacement, isEmpty);
    },
  );

  test(
    'falls back to the legacy sarangbang when the v2 JSON is damaged',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_room_placement': jsonEncode({'wall_back': 'decoration_pyeonaek'}),
        'kl_room_placements_v2': '{not-json',
      });
      await Storage.init();

      expect(Storage.roomPlacements, {
        PersonalRoomSurface.sarangbang: {'wall_back': 'decoration_pyeonaek'},
      });
    },
  );
}
