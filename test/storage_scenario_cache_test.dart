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

  test(
    'XP 보상 원장 클레임 직후 completedScenarios 캐시가 무효화되어 즉시 반영된다 '
    '(fix round 1 — 검토 지적: _mirrorListeningCompletion 의 실패-삼킴 try/catch 에 '
    '기대지 않고 원장 클레임 저장 직후 무조건 무효화해야 한다)',
    () async {
      // completedScenarios 를 먼저 읽어 캐시를 채워둔다 — 이렇게 해야
      // claimListeningCompletionReward() 가 실제로 캐시를 무효화하는지 검증된다
      // (캐시가 애초에 비어있었다면 무효화 없이도 우연히 통과할 수 있다).
      expect(Storage.completedScenarios, isNot(contains('scn_e')));

      final result = await Storage.claimListeningCompletionReward(
        scenarioId: 'scn_e',
        earnedXp: 10,
      );

      expect(result, ListeningRewardClaimResult.awarded);
      // 참고(주입 한계): `_sl`(로컬 리스트 쓰기, `_mirrorListeningCompletion` 내부)이
      // 실제로 실패하는 경로는 공개 `Storage` API 로는 결함을 주입할 수 없어 이
      // 테스트로 직접 재현하지 못한다. 대신 성공 경로에서 캐시가 mirror 호출과
      // 별개로 즉시 무효화됨을 검증한다 — 구현이 무효화를
      // `_mirrorListeningCompletion` 의 try/catch 안이 아니라 그 호출 직전(무조건)
      // 으로 옮겼다면 이 성공 경로에서도 여전히 통과해야 하고, 만약 무효화가
      // try/catch 안으로 되돌아가 실패 시에만 건너뛰는 형태로 회귀하더라도 이
      // 성공 경로 자체는 감지하지 못한다 — 그 회귀를 막는 것은 코드 리뷰의 몫이다.
      expect(Storage.completedScenarios, contains('scn_e'));
    },
  );

  test('setScenarioStars 는 0성도 최초 1회는 기록한다', () async {
    Storage.resetForTesting();
    expect(Storage.scenarioStars.containsKey('s1'), isFalse);
    await Storage.setScenarioStars('s1', 0);
    expect(Storage.scenarioStars['s1'], 0);
  });

  test('setScenarioStars 는 여전히 단조 증가만 허용한다', () async {
    Storage.resetForTesting();
    await Storage.setScenarioStars('s1', 2);
    await Storage.setScenarioStars('s1', 1); // 낮은 재도전 — 무시
    expect(Storage.scenarioStars['s1'], 2);
    await Storage.setScenarioStars('s1', 3); // 더 높은 재도전 — 반영
    expect(Storage.scenarioStars['s1'], 3);
  });
}
