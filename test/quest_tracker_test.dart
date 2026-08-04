// Phase 4 (stately-rising-jongga) — QuestTracker integration tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/quest_tracker.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    DataLoader.reset();
    VocabPackService.reset();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('QuestTracker.computeAll', () {
    test('empty state — all standing quests at 0', () async {
      final list = await QuestTracker.computeAll(
        now: DateTime(2026, 6, 15), // außerhalb aller Saison-Fenster
      );
      final standing = list.where((q) => q.target > 0);
      for (final q in standing) {
        expect(q.current, 0, reason: q.questId);
      }
    });

    test('completed quests stay completed even if counter drops', () async {
      // Marker setzen — simuliert "schon mal geklärt"
      await Storage.markQuestCompleted('q_kkachi_nest');
      final list = await QuestTracker.computeAll();
      final q = list.firstWhere((p) => p.questId == 'q_kkachi_nest');
      expect(q.completed, isTrue);
      expect(q.completedAtIso, isNotNull);
    });

    test('streak triggers kkachi_nest progress', () async {
      // Storage hat keinen direkten setter — wir simulieren via int set
      // Da streakDays nur read-only getter ist, manuell via _prefs key:
      SharedPreferences.setMockInitialValues({'kl_streak_days': 12});
      Storage.resetForTesting();
      await Storage.init();
      final list = await QuestTracker.computeAll();
      final q = list.firstWhere((p) => p.questId == 'q_kkachi_nest');
      expect(q.current, 12);
      expect(q.completed, isFalse);
    });

    test('kkeunmari wins counter feeds q_punggyeong', () async {
      for (var i = 0; i < 4; i++) {
        await Storage.incKkeunmariWins();
      }
      final list = await QuestTracker.computeAll();
      final q = list.firstWhere((p) => p.questId == 'q_punggyeong');
      expect(q.current, 4);
      expect(q.fraction, closeTo(0.4, 0.001));
      expect(q.completed, isFalse);
    });

    test('reaching target marks completed', () async {
      // 10 wins → q_punggyeong target = 10 → completed
      for (var i = 0; i < 10; i++) {
        await Storage.incKkeunmariWins();
      }
      final list = await QuestTracker.computeAll();
      final q = list.firstWhere((p) => p.questId == 'q_punggyeong');
      expect(q.completed, isTrue);
      expect(q.fraction, 1.0);
    });

    test('seasonal quest reports active=false outside window', () async {
      final summer = DateTime(2026, 7, 1);
      final list = await QuestTracker.computeAll(now: summer);
      final seollal = list.firstWhere((p) => p.questId == 'q_seollal');
      expect(seollal.active, isFalse);
      final chuseok = list.firstWhere((p) => p.questId == 'q_chuseok');
      expect(chuseok.active, isFalse);
    });

    test('seasonal quest reports active=true inside window', () async {
      final chuseokTime = DateTime(2026, 9, 15);
      final list = await QuestTracker.computeAll(now: chuseokTime);
      final chuseok = list.firstWhere((p) => p.questId == 'q_chuseok');
      expect(chuseok.active, isTrue);
    });
  });

  group('persistNewCompletions', () {
    test('marks newly-completed quests in Storage', () async {
      // 10 wins → fresh completion in computeAll, completedAtIso == null
      for (var i = 0; i < 10; i++) {
        await Storage.incKkeunmariWins();
      }
      final list = await QuestTracker.computeAll();
      await QuestTracker.persistNewCompletions(list);
      expect(Storage.hasQuestCompleted('q_punggyeong'), isTrue);
    });

    test('grants one pending reward box for a newly-completed quest', () async {
      for (var i = 0; i < 10; i++) {
        await Storage.incKkeunmariWins();
      }

      final list = await QuestTracker.computeAll();
      await QuestTracker.persistNewCompletions(list);

      expect(Storage.pendingBoxes, ['q_punggyeong']);

      // A repeat call must not turn one quest completion into two rewards.
      await QuestTracker.persistNewCompletions(list);
      expect(Storage.pendingBoxes, ['q_punggyeong']);
    });

    test('finishes a completion with an already-persisted reward box', () async {
      for (var i = 0; i < 10; i++) {
        await Storage.incKkeunmariWins();
      }
      await Storage.addPendingBox('q_punggyeong');

      final list = await QuestTracker.computeAll();
      await QuestTracker.persistNewCompletions(list);

      expect(Storage.hasQuestCompleted('q_punggyeong'), isTrue);
      expect(Storage.pendingBoxes, ['q_punggyeong']);
    });

    test('idempotent — second call no-op', () async {
      await Storage.markQuestCompleted('q_kkachi_nest');
      final firstMark = Storage.questCompletions['q_kkachi_nest'];
      final list = await QuestTracker.computeAll();
      await QuestTracker.persistNewCompletions(list);
      // The timestamp should not be overwritten — markQuestCompleted
      // is idempotent.
      expect(Storage.questCompletions['q_kkachi_nest'], firstMark);
    });
  });
}
