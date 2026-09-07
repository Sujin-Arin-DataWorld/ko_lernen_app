// Phase 2 (stately-rising-jongga) — PackProgressService Unlock-Logik &
// recordBossAttempt round-trip Tests.
//
// Hinweis: FirestoreProgressService wird im Test-Kontext ohne Firebase
// initialisiert → alle Firestore-Aufrufe sind no-ops (Web-Guard pattern).
// Lokale Storage-Pfad bleibt voll funktional → testbar.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  final pack1 = _pack('a1_greetings_1', 'A1', wordCount: 6, bossCount: 2);
  final pack2 = _pack('a1_greetings_2', 'A1', wordCount: 6, bossCount: 2);
  final pack3 = _pack('a1_self_intro', 'A1', wordCount: 6, bossCount: 2);
  final allPacks = [pack1, pack2, pack3];

  group('effectiveStatus (first-time)', () {
    test('first pack in level → available', () {
      final progress = PackProgressService.effectiveStatus(pack1, allPacks, {});
      expect(progress.status, PackStatus.available);
    });

    test('every pack in the level → available', () {
      final p2 = PackProgressService.effectiveStatus(pack2, allPacks, {});
      final p3 = PackProgressService.effectiveStatus(pack3, allPacks, {});
      expect(p2.status, PackStatus.available);
      expect(p3.status, PackStatus.available);
    });

    test('stored cleared → respects stored', () {
      final existing = {
        pack1.id: PackProgress.fresh(
          packId: pack1.id,
          level: 'A1',
          wordsTotal: 6,
          status: PackStatus.cleared,
        ),
      };
      final p1 = PackProgressService.effectiveStatus(pack1, allPacks, existing);
      expect(p1.status, PackStatus.cleared);
      // Clearing another pack is unrelated to direct access.
      final p2 = PackProgressService.effectiveStatus(pack2, allPacks, existing);
      expect(p2.status, PackStatus.available);
    });

    test('stored legacy lock is normalized without losing progress fields', () {
      const clearedAt = '2026-05-31T12:00:00Z';
      final legacy = PackProgress(
        packId: pack2.id,
        level: pack2.level,
        status: PackStatus.locked,
        wordsLearned: 4,
        wordsTotal: pack2.total,
        bossAccuracy: 0.5,
        attempts: 2,
        clearedAtIso: clearedAt,
      );

      final normalized = PackProgressService.effectiveStatus(pack2, allPacks, {
        pack2.id: legacy,
      });

      expect(normalized.status, PackStatus.available);
      expect(normalized.wordsLearned, legacy.wordsLearned);
      expect(normalized.wordsTotal, legacy.wordsTotal);
      expect(normalized.bossAccuracy, legacy.bossAccuracy);
      expect(normalized.attempts, legacy.attempts);
      expect(normalized.clearedAtIso, clearedAt);
      expect(normalized.isUnlocked, isTrue);
      expect(
        PackProgressService.isUnlocked(pack2.id, allPacks, {pack2.id: legacy}),
        isTrue,
      );
    });
  });

  group('recordBossAttempt', () {
    test('accuracy ≥ 0.70 → cleared + next pack unlocked', () async {
      final r = await PackProgressService.recordBossAttempt(
        pack1,
        allPacks,
        bossAccuracy: 0.75,
      );
      expect(r.progress.status, PackStatus.cleared);
      expect(r.justCleared, isTrue);
      expect(r.nextUnlocked?.id, pack2.id);

      // pack2 should now be available in storage.
      final p2Stored = PackProgressService.get(pack2.id);
      expect(p2Stored, isNotNull);
      expect(p2Stored!.status, PackStatus.available);
    });

    test('accuracy < 0.70 → inProgress, no next unlock', () async {
      final r = await PackProgressService.recordBossAttempt(
        pack1,
        allPacks,
        bossAccuracy: 0.40,
      );
      expect(r.progress.status, PackStatus.inProgress);
      expect(r.justCleared, isFalse);
      expect(r.nextUnlocked, isNull);

      final p2Stored = PackProgressService.get(pack2.id);
      expect(p2Stored, isNull);
    });

    test(
      'cleared once, second attempt below threshold → still cleared',
      () async {
        await PackProgressService.recordBossAttempt(
          pack1,
          allPacks,
          bossAccuracy: 0.90,
        );
        final r2 = await PackProgressService.recordBossAttempt(
          pack1,
          allPacks,
          bossAccuracy: 0.30,
        );
        expect(r2.progress.status, PackStatus.cleared);
        expect(r2.justCleared, isFalse);
        // bestAccuracy preserved (0.90)
        expect(r2.progress.bossAccuracy, 0.90);
      },
    );

    test('attempts counter increments', () async {
      await PackProgressService.recordBossAttempt(
        pack1,
        allPacks,
        bossAccuracy: 0.50,
      );
      await PackProgressService.recordBossAttempt(
        pack1,
        allPacks,
        bossAccuracy: 0.60,
      );
      final stored = PackProgressService.get(pack1.id)!;
      expect(stored.attempts, 2);
    });

    test('boundary: exactly 0.70 → cleared', () async {
      final r = await PackProgressService.recordBossAttempt(
        pack1,
        allPacks,
        bossAccuracy: 0.70,
      );
      expect(r.justCleared, isTrue);
      expect(r.progress.status, PackStatus.cleared);
    });

    test(
      'first time cleared sets clearedAt; subsequent clears preserve it',
      () async {
        final r1 = await PackProgressService.recordBossAttempt(
          pack1,
          allPacks,
          bossAccuracy: 0.80,
        );
        expect(r1.progress.clearedAtIso, isNotNull);
        final firstClearedAt = r1.progress.clearedAtIso;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final r2 = await PackProgressService.recordBossAttempt(
          pack1,
          allPacks,
          bossAccuracy: 0.95,
        );
        expect(r2.progress.clearedAtIso, firstClearedAt);
      },
    );

    test('last pack in level → no next unlock', () async {
      final r = await PackProgressService.recordBossAttempt(
        pack3,
        allPacks,
        bossAccuracy: 0.90,
      );
      expect(r.justCleared, isTrue);
      expect(r.nextUnlocked, isNull);
    });
  });

  group('nextPackInLevel / previousPackInLevel', () {
    test('first pack: no previous, has next', () {
      expect(
        PackProgressService.previousPackInLevel(pack1.id, allPacks),
        isNull,
      );
      expect(
        PackProgressService.nextPackInLevel(pack1.id, allPacks)?.id,
        pack2.id,
      );
    });

    test('last pack: no next, has previous', () {
      expect(PackProgressService.nextPackInLevel(pack3.id, allPacks), isNull);
      expect(
        PackProgressService.previousPackInLevel(pack3.id, allPacks)?.id,
        pack2.id,
      );
    });

    test('unknown pack: both null', () {
      expect(PackProgressService.nextPackInLevel('not_real', allPacks), isNull);
      expect(
        PackProgressService.previousPackInLevel('not_real', allPacks),
        isNull,
      );
    });
  });

  group('wordsLearnedIn', () {
    test('counts seen words from Storage.vokSeenIds', () async {
      await Storage.addVokSeen(pack1.words[0].korean);
      await Storage.addVokSeen(pack1.words[1].korean);
      // pack2 word should NOT count for pack1
      await Storage.addVokSeen(pack2.words[0].korean);

      expect(PackProgressService.wordsLearnedIn(pack1), 2);
      expect(PackProgressService.wordsLearnedIn(pack2), 1);
    });

    test(
      'learning all current-pack words preserves Boss clear and unlock',
      () async {
        for (final word in pack1.learnWords) {
          await Storage.addVokSeen(word.korean);
        }
        await PackProgressService.recordWordLearned(pack1);

        final learned = PackProgressService.get(pack1.id)!;
        expect(learned.wordsLearned, pack1.total);

        final result = await PackProgressService.recordBossAttempt(
          pack1,
          allPacks,
          bossAccuracy: PackProgressService.bossClearThreshold,
        );
        expect(result.progress.status, PackStatus.cleared);
        expect(result.nextUnlocked?.id, pack2.id);
      },
    );
  });

  group('Storage.packProgressJson round-trip', () {
    test('save → load yields same JSON', () async {
      final p = PackProgress(
        packId: 'a1_x',
        level: 'A1',
        status: PackStatus.cleared,
        wordsLearned: 5,
        wordsTotal: 8,
        bossAccuracy: 0.83,
        attempts: 1,
        clearedAtIso: '2026-05-31T12:00:00Z',
      );
      await Storage.setPackProgressJson(p.packId, p.toJson());
      final loaded = Storage.packProgressJson('a1_x');
      expect(loaded, isNotNull);
      final p2 = PackProgress.fromJson('a1_x', loaded!);
      expect(p2.status, p.status);
      expect(p2.wordsLearned, p.wordsLearned);
      expect(p2.bossAccuracy, p.bossAccuracy);
      expect(p2.clearedAtIso, p.clearedAtIso);
    });

    test('allPackProgressJson returns all', () async {
      await Storage.setPackProgressJson('a', {
        'level': 'A1',
        'status': 'cleared',
        'wordsLearned': 5,
        'wordsTotal': 5,
        'bossAccuracy': 0.9,
        'attempts': 1,
        'clearedAt': null,
      });
      await Storage.setPackProgressJson('b', {
        'level': 'A1',
        'status': 'inProgress',
        'wordsLearned': 2,
        'wordsTotal': 6,
        'bossAccuracy': 0.4,
        'attempts': 1,
        'clearedAt': null,
      });
      final all = Storage.allPackProgressJson();
      expect(all.keys.toSet(), {'a', 'b'});
    });
  });
}

VocabPack _pack(
  String id,
  String level, {
  required int wordCount,
  required int bossCount,
}) {
  final words = List.generate(wordCount, (i) {
    return Vocab(
      korean: '${id}_w$i',
      romanization: 'rom$i',
      german: 'Wort$i',
      level: level,
      posDe: 'Nomen',
      exampleKorean: '',
      exampleGerman: '',
      topic: 'Test',
      packId: id,
      packOrder: i + 1,
      isReviewBoss: i >= wordCount - bossCount,
    );
  });
  return VocabPack(id: id, level: level, words: words);
}
