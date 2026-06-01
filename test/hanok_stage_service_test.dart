// Phase 3 (stately-rising-jongga) — HanokStageService integration tests.
//
// Verifiziert die Schnittstelle Storage (lokale pack progress) →
// LevelRatios → currentStage. Lädt das echte vocab CSV via VocabPackService.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
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

  group('HanokStageService', () {
    test('keine Fortschritte → empty', () async {
      final stage = await HanokStageService.currentStage();
      expect(stage, HanokStage.empty);
    });

    test('Level-Ratios sind 0 bei leerem Storage', () async {
      final ratios = await HanokStageService.levelRatios();
      expect(ratios.a1, 0.0);
      expect(ratios.a2, 0.0);
      expect(ratios.b1, 0.0);
      expect(ratios.b2, 0.0);
    });

    test('25% A1 cleared → foundation', () async {
      final packs = await VocabPackService.packsForLevel('A1');
      final clearCount = (packs.length * 0.25).ceil();
      for (var i = 0; i < clearCount; i++) {
        await Storage.setPackProgressJson(
          packs[i].id,
          PackProgress(
            packId: packs[i].id, level: 'A1', status: PackStatus.cleared,
            wordsLearned: packs[i].total, wordsTotal: packs[i].total,
            bossAccuracy: 0.9, attempts: 1,
            clearedAtIso: '2026-05-31T00:00:00Z',
          ).toJson(),
        );
      }
      final stage = await HanokStageService.currentStage();
      expect(stage, HanokStage.foundation);
    });

    test('100% A1 cleared → thatchRoof', () async {
      final packs = await VocabPackService.packsForLevel('A1');
      for (final p in packs) {
        await Storage.setPackProgressJson(
          p.id,
          PackProgress(
            packId: p.id, level: 'A1', status: PackStatus.cleared,
            wordsLearned: p.total, wordsTotal: p.total,
            bossAccuracy: 0.9, attempts: 1,
            clearedAtIso: '2026-05-31T00:00:00Z',
          ).toJson(),
        );
      }
      final stage = await HanokStageService.currentStage();
      expect(stage, HanokStage.thatchRoof);
    });

    test('inProgress Packs zählen nicht als cleared', () async {
      final packs = await VocabPackService.packsForLevel('A1');
      // ein Pack als inProgress markieren — sollte NICHT in cleared-Zählung
      await Storage.setPackProgressJson(
        packs.first.id,
        PackProgress(
          packId: packs.first.id, level: 'A1', status: PackStatus.inProgress,
          wordsLearned: 3, wordsTotal: packs.first.total,
          bossAccuracy: 0.4, attempts: 1, clearedAtIso: null,
        ).toJson(),
      );
      final ratios = await HanokStageService.levelRatios();
      expect(ratios.a1, 0.0);
      final stage = await HanokStageService.currentStage();
      expect(stage, HanokStage.empty);
    });
  });

  group('Storage.seenHanokStages', () {
    test('default empty', () {
      expect(Storage.seenHanokStages, isEmpty);
      expect(Storage.hasSeenHanokStage('foundation'), isFalse);
    });

    test('markSeen persists', () async {
      await Storage.markHanokStageSeen('foundation');
      expect(Storage.hasSeenHanokStage('foundation'), isTrue);
      // duplicate mark is idempotent
      await Storage.markHanokStageSeen('foundation');
      expect(Storage.seenHanokStages.length, 1);
    });

    test('markSeen multi-stages preserved', () async {
      await Storage.markHanokStageSeen('empty');
      await Storage.markHanokStageSeen('foundation');
      await Storage.markHanokStageSeen('pillars');
      expect(Storage.seenHanokStages.toSet(),
          {'empty', 'foundation', 'pillars'});
    });
  });
}
