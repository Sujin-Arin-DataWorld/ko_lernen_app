import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('earnedStamps: add, dedup, persist (도장첩)', () async {
    expect(Storage.earnedStamps, isEmpty);
    await Storage.addEarnedStamp('lotus');
    await Storage.addEarnedStamp('plum');
    await Storage.addEarnedStamp('lotus'); // 중복 무시
    final stamps = Storage.earnedStamps;
    expect(stamps, containsAll(<String>['lotus', 'plum']));
    expect(stamps.length, 2);
  });
}
