// T2.6 (plan §4.4) — PackProgressService alias-migration tests.
//
// A relevel renames a vocab pack's id; `kPackProgressAliases` (new → old,
// lib/data/pack_progress_aliases.dart) records that. These tests verify:
//   - `get()` migrates progress stored under an old id to the new id/level
//     (other fields unchanged) and persists the migrated copy once.
//   - `getAll()` applies the same rewrite without touching Storage, and
//     never returns an old id — a directly-stored new id always wins.
//   - `mergeForReconciliation` normalizes both `local` and `remote` through
//     the alias table before validating against the catalog, so a remote
//     snapshot holding an old id still reconciles cleanly.
//   - Alias-chain resolution (`resolveAliasChain`) is transitive and
//     cycle-safe. `kPackProgressAliases` has no real multi-hop chain today,
//     so that specific behaviour is exercised against a synthetic table
//     passed via `resolveAliasChain`'s `edges` parameter — the same
//     algorithm `get`/`getAll`/`mergeForReconciliation` use internally
//     (against the real table) to walk a possible future chain.
//
// Hinweis: FirestoreProgressService wird im Test-Kontext ohne Firebase
// initialisiert → alle Firestore-Aufrufe sind no-ops (Web-Guard pattern).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
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

  // Real kPackProgressAliases entry (2026-09 relevel batch):
  //   'b1_neighbors_hall_1' (new, level B1) → 'a1_neighbors_hall_1' (old, level A1)
  const oldId = 'a1_neighbors_hall_1';
  const newId = 'b1_neighbors_hall_1';

  group('get()', () {
    test(
      'old key only -> migrated copy (id/level updated, rest kept), '
      'persisted under the new key, old record left in place',
      () async {
        final old = _progress(
          packId: oldId,
          level: 'A1',
          status: PackStatus.inProgress,
          wordsLearned: 3,
          wordsTotal: 8,
          bossAccuracy: 0.4,
          attempts: 1,
        );
        await Storage.setPackProgressJson(oldId, old.toJson());

        final migrated = PackProgressService.get(newId);

        expect(migrated, isNotNull);
        expect(migrated!.packId, newId);
        expect(migrated.level, 'B1');
        // Everything else carries over unchanged.
        expect(migrated.status, old.status);
        expect(migrated.wordsLearned, old.wordsLearned);
        expect(migrated.wordsTotal, old.wordsTotal);
        expect(migrated.bossAccuracy, old.bossAccuracy);
        expect(migrated.attempts, old.attempts);
        expect(migrated.clearedAtIso, old.clearedAtIso);

        // Write-through: the new key is now directly readable from Storage.
        final persisted = Storage.packProgressJson(newId);
        expect(persisted, isNotNull);
        final persistedProgress = PackProgress.fromJson(newId, persisted!);
        expect(persistedProgress.level, 'B1');
        expect(persistedProgress.wordsLearned, 3);

        // The old record is untouched, not deleted.
        final oldRaw = Storage.packProgressJson(oldId);
        expect(oldRaw, isNotNull);
        expect(PackProgress.fromJson(oldId, oldRaw!).level, 'A1');

        await Future<void>.delayed(Duration.zero);
      },
    );

    test('new+old both present -> new wins, old is ignored', () async {
      final old = _progress(
        packId: oldId,
        level: 'A1',
        wordsLearned: 1,
        attempts: 1,
        bossAccuracy: 0.1,
      );
      final current = _progress(
        packId: newId,
        level: 'B1',
        status: PackStatus.cleared,
        wordsLearned: 5,
        attempts: 3,
        bossAccuracy: 0.9,
        clearedAtIso: '2026-05-01T00:00:00.000Z',
      );
      await Storage.setPackProgressJson(oldId, old.toJson());
      await Storage.setPackProgressJson(newId, current.toJson());

      final result = PackProgressService.get(newId);

      expect(result, isNotNull);
      expect(result!.wordsLearned, 5);
      expect(result.attempts, 3);
      expect(result.status, PackStatus.cleared);
      expect(result.clearedAtIso, '2026-05-01T00:00:00.000Z');
    });

    test('neither old nor new stored -> null, no alias crash', () {
      expect(PackProgressService.get(newId), isNull);
    });
  });

  group('getAll()', () {
    test('old key only -> surfaces under the new id, not the old one', () async {
      final old = _progress(packId: oldId, level: 'A1', wordsLearned: 6);
      await Storage.setPackProgressJson(oldId, old.toJson());

      final all = PackProgressService.getAll();

      expect(all.containsKey(oldId), isFalse);
      expect(all.containsKey(newId), isTrue);
      expect(all[newId]!.packId, newId);
      expect(all[newId]!.level, 'B1');
      expect(all[newId]!.wordsLearned, 6);
    });

    test('new+old both present -> new wins, old key never returned', () async {
      final old = _progress(packId: oldId, level: 'A1', wordsLearned: 1);
      final current = _progress(packId: newId, level: 'B1', wordsLearned: 5);
      await Storage.setPackProgressJson(oldId, old.toJson());
      await Storage.setPackProgressJson(newId, current.toJson());

      final all = PackProgressService.getAll();

      expect(all.containsKey(oldId), isFalse);
      expect(all[newId]!.wordsLearned, 5);
    });

    test('unrelated keys pass through untouched', () async {
      final unrelated = _progress(
        packId: 'a1_greetings_1',
        level: 'A1',
        wordsLearned: 2,
        status: PackStatus.inProgress,
        attempts: 1,
        bossAccuracy: 0.3,
      );
      await Storage.setPackProgressJson('a1_greetings_1', unrelated.toJson());

      final all = PackProgressService.getAll();

      expect(all.keys, {'a1_greetings_1'});
      final result = all['a1_greetings_1']!;
      expect(result.wordsLearned, 2);
      expect(result.attempts, 1);
      expect(result.bossAccuracy, 0.3);
      expect(result.level, 'A1');
    });
  });

  group('mergeForReconciliation', () {
    test('remote map with an old key normalizes -> valid and merged', () {
      final remoteOld = _progress(
        packId: oldId,
        level: 'A1',
        wordsTotal: 8,
        wordsLearned: 4,
        attempts: 1,
        bossAccuracy: 0.5,
        status: PackStatus.inProgress,
      );
      final catalog = {
        newId: const PackCatalogEntry(
          packId: newId,
          level: 'B1',
          wordsTotal: 8,
        ),
      };

      final result = PackProgressService.mergeForReconciliation(
        local: const {},
        remote: {oldId: remoteOld},
        catalog: catalog,
      );

      expect(result.isValid, isTrue);
      expect(result.invalidPackIds, isEmpty);
      expect(result.merged!.containsKey(oldId), isFalse);
      final merged = result.merged![newId];
      expect(merged, isNotNull);
      expect(merged!.packId, newId);
      expect(merged.level, 'B1');
      expect(merged.wordsLearned, 4);
      expect(merged.attempts, 1);
      expect(merged.bossAccuracy, 0.5);
    });

    test(
      'local (new, current) + remote (old) both present -> merges by id, '
      'old key absent from the result',
      () {
        final localCurrent = _progress(
          packId: newId,
          level: 'B1',
          wordsTotal: 8,
          wordsLearned: 6,
          attempts: 2,
          bossAccuracy: 0.6,
          status: PackStatus.inProgress,
        );
        final remoteOld = _progress(
          packId: oldId,
          level: 'A1',
          wordsTotal: 8,
          wordsLearned: 4,
          attempts: 1,
          bossAccuracy: 0.5,
          status: PackStatus.inProgress,
        );
        final catalog = {
          newId: const PackCatalogEntry(
            packId: newId,
            level: 'B1',
            wordsTotal: 8,
          ),
        };

        final result = PackProgressService.mergeForReconciliation(
          local: {newId: localCurrent},
          remote: {oldId: remoteOld},
          catalog: catalog,
        );

        expect(result.isValid, isTrue);
        expect(result.merged!.keys, {newId});
        // Monotonic merge picks the higher value per field once both sides
        // resolve to the same id.
        expect(result.merged![newId]!.wordsLearned, 6);
        expect(result.merged![newId]!.attempts, 2);
        expect(result.merged![newId]!.bossAccuracy, 0.6);
      },
    );
  });

  group('resolveAliasChain', () {
    test('resolves a multi-hop chain transitively', () {
      // kPackProgressAliases itself has no real multi-hop chain yet, so the
      // algorithm is exercised directly against a synthetic table via the
      // `edges` parameter — the same code path get()/getAll() drive with
      // the real table.
      final chain = PackProgressService.resolveAliasChain(
        'c1_pack',
        edges: const {'c1_pack': 'b1_pack', 'b1_pack': 'a1_pack'},
      );
      expect(chain, ['b1_pack', 'a1_pack']);
    });

    test('a cyclic alias table does not loop', () {
      final chain = PackProgressService.resolveAliasChain(
        'x',
        edges: const {'x': 'y', 'y': 'x'},
      );
      expect(chain, ['y']);
    });

    test('the real kPackProgressAliases resolves the neighbors_hall entry', () {
      final chain = PackProgressService.resolveAliasChain(newId);
      expect(chain, [oldId]);
    });
  });
}

PackProgress _progress({
  required String packId,
  required String level,
  PackStatus status = PackStatus.inProgress,
  int wordsLearned = 0,
  int wordsTotal = 8,
  double bossAccuracy = 0,
  int attempts = 0,
  String? clearedAtIso,
}) {
  return PackProgress(
    packId: packId,
    level: level,
    status: status,
    wordsLearned: wordsLearned,
    wordsTotal: wordsTotal,
    bossAccuracy: bossAccuracy,
    attempts: attempts,
    clearedAtIso: clearedAtIso,
  );
}
