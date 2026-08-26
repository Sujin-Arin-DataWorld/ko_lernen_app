import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test('scenarioStars 는 쓰기 전까지 같은 맵 인스턴스를 재사용한다(캐시)', () async {
    await Storage.setScenarioStars('scn_a', 2);
    final first = Storage.scenarioStars;
    final second = Storage.scenarioStars;
    expect(identical(first, second), isTrue);
    expect(second['scn_a'], 2);
  });

  test('setScenarioStars 이후 값이 즉시 반영된다(캐시 무효화)', () async {
    await Storage.setScenarioStars('scn_b', 1);
    expect(Storage.scenarioStars['scn_b'], 1);
    await Storage.setScenarioStars('scn_b', 3);
    expect(Storage.scenarioStars['scn_b'], 3);
  });

  test('completedScenarios 는 addCompletedScenario 직후 값을 포함한다', () async {
    expect(Storage.completedScenarios, isNot(contains('scn_c')));
    await Storage.addCompletedScenario('scn_c');
    expect(Storage.completedScenarios, contains('scn_c'));
  });

  test(
    '캐시된 scenarioStars 맵을 밖에서 변형해도 다음 setScenarioStars 결과가 오염되지 않는다',
    () async {
      await Storage.setScenarioStars('scn_d', 1);
      final cached = Storage.scenarioStars;
      expect(
        () => cached['scn_d'] = 99,
        throwsUnsupportedError,
        reason: '게터가 반환하는 맵은 불변이어야 캐시가 실수로 오염되지 않는다',
      );
    },
  );
}
