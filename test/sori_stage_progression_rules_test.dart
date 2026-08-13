import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/gye_member_quest_service.dart';
import 'package:ko_lernen_app/services/pronunciation_progress_service.dart';
import 'package:ko_lernen_app/services/quest_action_resolver.dart';
import 'package:ko_lernen_app/services/quest_tracker.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('word quest counts only SRS strong cards, not seen cards', () async {
    SharedPreferences.setMockInitialValues({
      'kl_vok_seen_ids': ['김치', '밥'],
      'kl_srs_v1': '{"김치":{"e":2.5,"i":8,"n":"2099-01-01","r":4}}',
    });
    Storage.resetForTesting();
    await Storage.init();

    final quests = await QuestTracker.computeAll(now: DateTime(2026, 6, 15));
    final food = quests.singleWhere((quest) => quest.questId == 'q_jangdokdae');
    expect(food.current, 1);
  });

  test(
    'active Gye members are deduplicated across groups and exclude self',
    () {
      final count = uniqueActiveGyeMemberCount(
        currentUid: 'me',
        memberships: [
          [
            const GyeMember(uid: 'me', nickname: 'Me'),
            const GyeMember(uid: 'a', nickname: 'A'),
            const GyeMember(uid: 'b', nickname: 'B'),
          ],
          [
            const GyeMember(uid: 'a', nickname: 'A again'),
            const GyeMember(uid: 'c', nickname: 'C'),
            const GyeMember(
              uid: 'x',
              nickname: 'X',
              status: GyeMemberStatus.suspended,
            ),
          ],
        ],
      );
      expect(count, 3);
    },
  );

  test(
    'pronunciation threshold rejects 79 and accepts 80 once per assessment',
    () async {
      expect(pronunciationScorePasses(79), isFalse);
      expect(pronunciationScorePasses(80), isTrue);
      expect(
        await PronunciationProgressService.recordPass('assessment-1', 80),
        isTrue,
      );
      expect(
        await PronunciationProgressService.recordPass('assessment-1', 95),
        isFalse,
      );
      expect(Storage.pronunciationPassCount, 1);
    },
  );

  test('all quests resolve to an exact action or exact seasonal opening', () {
    for (final action in QuestActionResolver.all(now: DateTime(2026, 6, 15))) {
      expect(
        action.route != null || action.seasonOpensAt != null,
        isTrue,
        reason: action.questId,
      );
      expect(action.label.de, isNotEmpty, reason: action.questId);
      expect(action.label.en, isNotEmpty, reason: action.questId);
    }
  });
}
