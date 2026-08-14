import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/services/quest_tracker.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// [QuestTracker.syncEarnedRewards] is the screen-agnostic seam that lets
/// studying alone (via Home/Sarangbang) produce the bojagi a learner earned,
/// without ever opening the Quests screen. It must be best-effort (never throw)
/// and idempotent (no double-grant across surfaces).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('persistNewCompletions enqueues one bojagi for a freshly completed '
      'quest, marks it, and is idempotent', () async {
    final questId = kQuestById.keys.first;
    final done = QuestProgress(
      questId: questId,
      current: 1,
      target: 1,
      active: true,
      completed: true,
      completedAtIso: null,
    );

    await QuestTracker.persistNewCompletions([done]);
    expect(Storage.pendingBoxes, contains(questId));
    expect(Storage.questCompletions.containsKey(questId), isTrue);

    final boxes = Storage.pendingBoxes.length;
    // Second run: the quest is now marked (completedAtIso != null), so nothing
    // new is granted.
    final again = QuestProgress(
      questId: questId,
      current: 1,
      target: 1,
      active: true,
      completed: true,
      completedAtIso: Storage.questCompletions[questId],
    );
    await QuestTracker.persistNewCompletions([again]);
    expect(Storage.pendingBoxes.length, boxes);
  });

  test(
    'syncEarnedRewards never throws and is idempotent on a clean state',
    () async {
      await QuestTracker.syncEarnedRewards();
      final boxes = Storage.pendingBoxes.length;
      await QuestTracker.syncEarnedRewards();
      expect(Storage.pendingBoxes.length, boxes);
    },
  );
}
