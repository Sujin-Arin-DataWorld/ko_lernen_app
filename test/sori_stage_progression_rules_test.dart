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
    'offline cached Gye count is visible but cannot newly complete',
    () async {
      await Storage.setGyeUniqueMemberCount(5);
      final quests = await QuestTracker.computeAll(
        now: DateTime(2026, 6, 15),
        loadGyeMembers: () async =>
            const GyeMemberQuestResult(count: 5, verifiedOnline: false),
      );
      final friends = quests.singleWhere(
        (quest) => quest.questId == 'q_doldam',
      );
      expect(friends.current, 5);
      expect(friends.completed, isFalse);
      expect(friends.completionVerified, isFalse);
    },
  );

  test('server-verified unique Gye count can complete the quest', () async {
    final quests = await QuestTracker.computeAll(
      now: DateTime(2026, 6, 15),
      loadGyeMembers: () async =>
          const GyeMemberQuestResult(count: 5, verifiedOnline: true),
    );
    final friends = quests.singleWhere((quest) => quest.questId == 'q_doldam');
    expect(friends.completed, isTrue);
    expect(friends.completionVerified, isTrue);
  });

  test(
    'Gye refresh keeps the last count when server verification fails',
    () async {
      await Storage.setGyeUniqueMemberCount(4);
      final result = await GyeMemberQuestService.refreshOrCached(
        currentUid: 'me',
        loadGyeIds: () => Future<List<String>>.error(StateError('offline')),
      );
      expect(result.count, 4);
      expect(result.verifiedOnline, isFalse);
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

  test('pronunciation pass persists as one atomic bounded journal', () async {
    final store = _MemoryStringStore();
    expect(
      await Storage.recordPronunciationPass(
        'assessment-atomic',
        80,
        preferences: store,
      ),
      isTrue,
    );
    expect(store.writes, 1);
    expect(store.values.keys, ['kl_pronunciation_progress_v2']);
    expect(store.values.values.single, contains('assessment-atomic'));
    expect(
      await Storage.recordPronunciationPass(
        'assessment-atomic',
        95,
        preferences: store,
      ),
      isFalse,
    );
    expect(store.writes, 1);
  });

  test('failed pronunciation journal write does not report a pass', () async {
    final store = _MemoryStringStore(failWrites: true);
    await expectLater(
      Storage.recordPronunciationPass(
        'assessment-fail',
        80,
        preferences: store,
      ),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(store.values, isEmpty);
  });

  test('all quests resolve to an exact action or exact seasonal opening', () {
    for (final action in QuestActionResolver.all(now: DateTime(2026, 6, 15))) {
      expect(
        action.route != null || action.seasonOpensAt != null,
        isTrue,
        reason: action.questId,
      );
      expect(action.labelKey.name, isNotEmpty, reason: action.questId);
    }
  });
}

class _MemoryStringStore implements PreferenceStringStore {
  _MemoryStringStore({this.failWrites = false});

  final bool failWrites;
  final Map<String, String> values = <String, String>{};
  int writes = 0;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;

  @override
  Future<bool> setString(String key, String value) async {
    writes++;
    if (failWrites) {
      return false;
    }
    values[key] = value;
    return true;
  }
}
