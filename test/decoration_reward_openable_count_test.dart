import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';

/// [DecorationRewardService.openableBoxCount] 는 홈 배지가 "선물 N개"로
/// 세는 값이다. 존재하지 않는 보상을 약속하지 않도록, 알 수 없는 퀘스트
/// 출처의 상자는 세지 않아야 한다.
void main() {
  test('빈 큐는 0', () {
    expect(
      DecorationRewardService.openableBoxCount(pending: const <String>[]),
      0,
    );
  });

  test('알 수 없는 퀘스트 상자는 세지 않는다', () {
    expect(
      DecorationRewardService.openableBoxCount(
        pending: const <String>['__nope__', 'still_not_a_quest'],
      ),
      0,
    );
  });

  test('알려진 퀘스트 출처 상자만, 개수 그대로 센다', () {
    final known = kQuestById.keys.first;
    expect(
      DecorationRewardService.openableBoxCount(
        pending: <String>[known, '__nope__', known],
      ),
      2,
    );
  });
}
