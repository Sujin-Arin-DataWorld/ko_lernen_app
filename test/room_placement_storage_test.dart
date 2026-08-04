import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
