import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/hanok_competence_fixture.dart';

final class _WalletStore implements PreferenceStringStore {
  String? durable;
  String? cache;
  bool reject = false;
  bool commitThenThrow = false;
  bool acknowledgeWithoutCommit = false;
  bool failReload = false;
  Completer<void>? heldWrite;
  Completer<void>? heldReload;
  Completer<void>? reloadEntered;

  @override
  bool containsKey(String key) => cache != null;

  @override
  String? getString(String key) => cache;

  @override
  Future<void> reload() async {
    reloadEntered?.complete();
    reloadEntered = null;
    if (heldReload case final held?) {
      await held.future;
    }
    if (failReload) throw StateError('native reload failed');
    cache = durable;
  }

  @override
  Future<bool> setString(String key, String value) async {
    cache = value; // SharedPreferences is optimistic before native reply.
    if (heldWrite case final held?) await held.future;
    if (commitThenThrow) {
      durable = value;
      throw StateError('lost native reply');
    }
    if (reject) return false;
    if (acknowledgeWithoutCommit) return true;
    durable = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    durable = null;
    cache = null;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'grandfathers only already qualified stages and survives reload',
    () async {
      final store = _WalletStore();
      final old = hanokCompetenceFixture(a1Completed: 3, b2Completed: 1);
      final first = await YeopjeonService.loadCurrent(
        competenceLoader: () async => old,
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(first.balance, 0);
      expect(first.sarangchaeOwnedStage, 4);
      expect(first.b2OwnedStage, 8);
      expect(YeopjeonWallet.decode(store.durable!).encode(), first.encode());

      final replay = await YeopjeonService.loadCurrent(
        competenceLoader: () async => old,
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(replay.encode(), first.encode());
    },
  );

  test(
    'newly qualified stages get 40 each and purchases own one stage',
    () async {
      final store = _WalletStore();
      final empty = hanokCompetenceFixture();
      final earned = hanokCompetenceFixture(a1Completed: 2);
      await YeopjeonService.loadCurrent(
        competenceLoader: () async => empty,
        evidenceScanner: () async => {},
        preferences: store,
      );
      final wallet = await YeopjeonService.loadCurrent(
        competenceLoader: () async => earned,
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(wallet.balance, 80);
      expect(wallet.sarangchaeEligibleStage, 2);
      expect(wallet.sarangchaeOwnedStage, 0);

      final first = await YeopjeonService.buildNext(
        YeopjeonBuilding.sarangchae,
        competenceLoader: () async => earned,
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(first.status, YeopjeonTransactionStatus.built);
      expect(first.amount, -40);
      expect(first.wallet!.balance, 40);
      expect(first.wallet!.sarangchaeOwnedStage, 1);
      final second = await YeopjeonService.buildNext(
        YeopjeonBuilding.sarangchae,
        competenceLoader: () async => earned,
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(second.wallet!.balance, 0);
      expect(second.wallet!.sarangchaeOwnedStage, 2);
      expect(
        (await YeopjeonService.buildNext(
          YeopjeonBuilding.sarangchae,
          competenceLoader: () async => earned,
          evidenceScanner: () async => {},
          preferences: store,
        )).status,
        YeopjeonTransactionStatus.locked,
      );
    },
  );

  test('first, second, replay, third and new day are source-safe', () async {
    final store = _WalletStore();
    final projection = hanokCompetenceFixture();
    Future<YeopjeonTransactionResult> grant(String id, DateTime at) =>
        YeopjeonService.grantConfirmedCompletion(
          unitId: id,
          completedAt: at,
          competenceLoader: () async => projection,
          evidenceScanner: () async => {},
          completionVerifier: (_) async => true,
          preferences: store,
        );
    final day1 = DateTime(2026, 10, 1, 12);
    final first = await grant('u1', day1);
    expect(first.amount, 20);
    expect(first.confirmedClaimIds, ['daily:2026-10-01:first']);
    expect(() => first.confirmedClaimIds.add('bad'), throwsUnsupportedError);
    expect(
      (await grant('u1', day1)).status,
      YeopjeonTransactionStatus.alreadyClaimed,
    );
    final second = await grant('u2', day1);
    expect(second.amount, 10);
    expect(second.confirmedClaimIds, ['daily:2026-10-01:second']);
    expect(
      (await grant('u3', day1)).status,
      YeopjeonTransactionStatus.noReward,
    );
    expect((await grant('u3', DateTime(2026, 10, 2))).amount, 0);
    expect((await grant('u4', DateTime(2026, 10, 2))).amount, 20);
    expect(YeopjeonWallet.decode(store.durable!).balance, 50);
  });

  test(
    'lesson proof uses persisted date and shares the daily budget',
    () async {
      final store = _WalletStore();
      final projection = hanokCompetenceFixture();
      final lesson = await YeopjeonService.grantConfirmedLesson(
        lessonId: 'lesson-a',
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        lessonVerifier: (_) async => DateTime(2026, 10, 1, 9),
        preferences: store,
      );
      expect(lesson.amount, 20);
      final unit = await YeopjeonService.grantConfirmedCompletion(
        unitId: 'unit-a',
        completedAt: DateTime(2026, 10, 1, 10),
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        completionVerifier: (_) async => true,
        preferences: store,
      );
      expect(unit.amount, 10);
      expect(
        (await YeopjeonService.grantConfirmedLesson(
          lessonId: 'lesson-a',
          competenceLoader: () async => projection,
          evidenceScanner: () async => {},
          lessonVerifier: (_) async => DateTime(2026, 10, 1, 9),
          preferences: store,
        )).status,
        YeopjeonTransactionStatus.alreadyClaimed,
      );
    },
  );

  test('unverified completion and review cannot mint money', () async {
    final store = _WalletStore();
    final projection = hanokCompetenceFixture();
    final unit = await YeopjeonService.grantConfirmedCompletion(
      unitId: 'not-completed',
      completedAt: DateTime(2026, 10, 1),
      competenceLoader: () async => projection,
      evidenceScanner: () async => {},
      completionVerifier: (_) async => false,
      preferences: store,
    );
    expect(unit.status, YeopjeonTransactionStatus.unverified);
    final review = await YeopjeonService.grantConfirmedDueReview(
      reviewId: 'some-review',
      completedAt: DateTime(2026, 10, 1),
      competenceLoader: () async => projection,
      evidenceScanner: () async => {},
      preferences: store,
    );
    expect(review.status, YeopjeonTransactionStatus.unverified);
    expect(YeopjeonWallet.decode(store.durable!).balance, 0);
  });

  test(
    'native refusal has no confirmed grant; uncertain reply reconciles',
    () async {
      final store = _WalletStore();
      final projection = hanokCompetenceFixture();
      await YeopjeonService.loadCurrent(
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        preferences: store,
      );
      store.reject = true;
      Future<YeopjeonTransactionResult> grant() =>
          YeopjeonService.grantConfirmedCompletion(
            unitId: 'u1',
            completedAt: DateTime(2026, 10, 1),
            competenceLoader: () async => projection,
            evidenceScanner: () async => {},
            completionVerifier: (_) async => true,
            preferences: store,
          );
      expect((await grant()).status, YeopjeonTransactionStatus.failed);
      expect(YeopjeonWallet.decode(store.durable!).balance, 0);
      store.reject = false;
      store.commitThenThrow = true;
      expect((await grant()).status, YeopjeonTransactionStatus.granted);
      expect(YeopjeonWallet.decode(store.durable!).balance, 20);
      expect((await grant()).status, YeopjeonTransactionStatus.alreadyClaimed);
    },
  );

  test(
    'lying success and failed readback never expose optimistic balance',
    () async {
      final store = _WalletStore();
      final projection = hanokCompetenceFixture();
      await YeopjeonService.loadCurrent(
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        preferences: store,
      );
      store.acknowledgeWithoutCommit = true;
      final result = await YeopjeonService.grantConfirmedCompletion(
        unitId: 'u1',
        completedAt: DateTime(2026, 10, 1),
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        completionVerifier: (_) async => true,
        preferences: store,
      );
      expect(result.status, YeopjeonTransactionStatus.unknown);
      expect(result.confirmedClaimIds, isEmpty);
      expect(YeopjeonWallet.decode(store.durable!).balance, 0);
      store.acknowledgeWithoutCommit = false;
      expect(
        (await YeopjeonService.grantConfirmedCompletion(
          unitId: 'u1',
          completedAt: DateTime(2026, 10, 1),
          competenceLoader: () async => projection,
          evidenceScanner: () async => {},
          completionVerifier: (_) async => true,
          preferences: store,
        )).amount,
        20,
      );
    },
  );

  test('rapid purchase calls serialize and cannot overspend', () async {
    final store = _WalletStore();
    final empty = hanokCompetenceFixture();
    final two = hanokCompetenceFixture(a1Completed: 2);
    await YeopjeonService.loadCurrent(
      competenceLoader: () async => empty,
      evidenceScanner: () async => {},
      preferences: store,
    );
    await YeopjeonService.loadCurrent(
      competenceLoader: () async => two,
      evidenceScanner: () async => {},
      preferences: store,
    );
    final calls = await Future.wait(
      List.generate(
        4,
        (_) => YeopjeonService.buildNext(
          YeopjeonBuilding.sarangchae,
          competenceLoader: () async => two,
          evidenceScanner: () async => {},
          preferences: store,
        ),
      ),
    );
    expect(
      calls.where((c) => c.status == YeopjeonTransactionStatus.built).length,
      2,
    );
    expect(YeopjeonWallet.decode(store.durable!).balance, 0);
    expect(YeopjeonWallet.decode(store.durable!).sarangchaeOwnedStage, 2);
  });

  test(
    'legacy cloud course proof rebases only a pristine startup wallet',
    () async {
      final store = _WalletStore();
      final empty = hanokCompetenceFixture();
      final earned = hanokCompetenceFixture(a1Completed: 2);
      await YeopjeonService.loadCurrent(
        competenceLoader: () async => empty,
        evidenceScanner: () async => {'lesson:historic': DateTime(2026, 9, 1)},
        preferences: store,
      );
      await YeopjeonService.grandfatherLegacyCloudProgress(
        competenceLoader: () async => earned,
        evidenceScanner: () async => {'unit:historic': null},
        preferences: store,
      );
      expect(YeopjeonWallet.decode(store.durable!).sarangchaeOwnedStage, 2);
      expect(YeopjeonWallet.decode(store.durable!).balance, 0);
      expect(
        YeopjeonWallet.decode(store.durable!).completedSourceIds,
        containsAll({'lesson:historic', 'unit:historic'}),
      );
      await YeopjeonService.grantConfirmedLesson(
        lessonId: 'lesson-a',
        competenceLoader: () async => earned,
        evidenceScanner: () async => {},
        lessonVerifier: (_) async => DateTime(2026, 10, 1),
        preferences: store,
      );
      await YeopjeonService.grandfatherLegacyCloudProgress(
        competenceLoader: () async => hanokCompetenceFixture(a1Completed: 3),
        evidenceScanner: () async => {},
        preferences: store,
      );
      expect(YeopjeonWallet.decode(store.durable!).sarangchaeOwnedStage, 2);
    },
  );

  test(
    'baseline consumes historic proof and recovery pays only new sources',
    () async {
      final store = _WalletStore();
      final projection = hanokCompetenceFixture();
      var sources = <String, DateTime?>{
        'lesson:historic': DateTime(2026, 9, 1),
        'unit:historic': null,
      };
      Future<Map<String, DateTime?>> scan() async => sources;
      final baseline = await YeopjeonService.loadCurrent(
        competenceLoader: () async => projection,
        evidenceScanner: scan,
        preferences: store,
      );
      expect(baseline.balance, 0);
      expect(baseline.completedSourceIds, containsAll(sources.keys));
      sources = {
        ...sources,
        'lesson:new': DateTime(2026, 10, 1, 9),
        'unit:new': null,
      };
      final recovered = await YeopjeonService.recoverConfirmedLearningRewards(
        competenceLoader: () async => projection,
        evidenceScanner: scan,
        preferences: store,
        clock: () => DateTime(2026, 10, 1, 10),
      );
      expect(recovered.status, YeopjeonTransactionStatus.granted);
      expect(recovered.amount, 30);
      expect(recovered.confirmedClaimIds, [
        'daily:2026-10-01:first',
        'daily:2026-10-01:second',
      ]);
      expect(recovered.wallet!.balance, 30);
      expect(
        (await YeopjeonService.recoverConfirmedLearningRewards(
          competenceLoader: () async => projection,
          evidenceScanner: scan,
          preferences: store,
          clock: () => DateTime(2026, 10, 2),
        )).amount,
        0,
      );
    },
  );

  test(
    'failed grant is recoverable from durable proof after restart',
    () async {
      final store = _WalletStore();
      final projection = hanokCompetenceFixture();
      var sources = <String, DateTime?>{};
      Future<Map<String, DateTime?>> scan() async => sources;
      await YeopjeonService.loadCurrent(
        competenceLoader: () async => projection,
        evidenceScanner: scan,
        preferences: store,
      );
      sources = {'lesson:durable': DateTime(2026, 10, 1)};
      store.reject = true;
      final refused = await YeopjeonService.recoverConfirmedLearningRewards(
        competenceLoader: () async => projection,
        evidenceScanner: scan,
        preferences: store,
      );
      expect(refused.status, YeopjeonTransactionStatus.failed);
      expect(YeopjeonWallet.decode(store.durable!).balance, 0);
      store.reject = false;
      final retried = await YeopjeonService.recoverConfirmedLearningRewards(
        competenceLoader: () async => projection,
        evidenceScanner: scan,
        preferences: store,
      );
      expect(retried.amount, 20);
      expect(YeopjeonWallet.decode(store.durable!).balance, 20);
    },
  );

  test(
    'remote wallet restores to empty local and rejects divergence',
    () async {
      final remote = _WalletStore();
      final local = _WalletStore();
      final projection = hanokCompetenceFixture();
      final wallet = await YeopjeonService.loadCurrent(
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        preferences: remote,
      );
      await YeopjeonService.restoreFromCloudJson(
        wallet.encode(),
        preferences: local,
      );
      expect(YeopjeonWallet.decode(local.durable!).encode(), wallet.encode());
      await YeopjeonService.restoreFromCloudJson(
        wallet.encode(),
        preferences: local,
      );
      await YeopjeonService.grantConfirmedCompletion(
        unitId: 'local-unit',
        completedAt: DateTime(2026, 10, 1),
        competenceLoader: () async => projection,
        evidenceScanner: () async => {},
        completionVerifier: (_) async => true,
        preferences: local,
      );
      final different = wallet.copyWith(
        balance: 20,
        claims: {'daily:2026-10-02:first': 20},
        completedSourceIds: {'unit:remote-unit'},
      );
      await expectLater(
        YeopjeonService.restoreFromCloudJson(
          different.encode(),
          preferences: local,
        ),
        throwsStateError,
      );
      expect(YeopjeonWallet.decode(local.durable!).balance, 20);
    },
  );

  test('strict reset discards ledger and source claims', () async {
    await Storage.init();
    final projection = hanokCompetenceFixture();
    await YeopjeonService.grantConfirmedCompletion(
      unitId: 'u1',
      completedAt: DateTime(2026, 10, 1),
      competenceLoader: () async => projection,
      evidenceScanner: () async => {},
      completionVerifier: (_) async => true,
    );
    expect((await YeopjeonService.captureBackupJson()), isNotNull);
    await Storage.resetAllStrict();
    expect(await YeopjeonService.captureBackupJson(), isNull);
  });

  test('backup and restore carry one validated wallet document', () async {
    await Storage.init();
    final projection = hanokCompetenceFixture();
    await YeopjeonService.loadCurrent(competenceLoader: () async => projection);
    await YeopjeonService.grantConfirmedCompletion(
      unitId: 'u1',
      completedAt: DateTime(2026, 10, 1),
      competenceLoader: () async => projection,
      evidenceScanner: () async => {},
      completionVerifier: (_) async => true,
    );
    final payload = await CloudSync.buildBackupPayload();
    final remoteRaw = payload['yeopjeon_wallet_json'] as String;
    expect(YeopjeonWallet.decode(remoteRaw).balance, 20);
    await Storage.resetAllStrict();
    await CloudSync.applyRestorePayload({'yeopjeon_wallet_json': remoteRaw});
    expect(
      YeopjeonWallet.decode(
        (await YeopjeonService.captureBackupJson())!,
      ).balance,
      20,
    );
  });

  test(
    'invalid cloud wallet rejects before unrelated progress writes',
    () async {
      await Storage.init();
      await expectLater(
        CloudSync.applyRestorePayload({
          'yeopjeon_wallet_json': '{broken',
          'progress': {'xp': 77},
        }),
        throwsFormatException,
      );
      expect(Storage.xp, 0);
      expect(await YeopjeonService.captureBackupJson(), isNull);
    },
  );

  test('malformed or unbacked ledger never becomes spendable', () async {
    final store = _WalletStore()..durable = '{broken';
    await expectLater(
      YeopjeonService.loadCurrent(
        competenceLoader: () async => hanokCompetenceFixture(),
        evidenceScanner: () async => {},
        preferences: store,
      ),
      throwsFormatException,
    );
    final valid = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0);
    store.durable = jsonEncode({...valid.toJson(), 'balance': 20});
    await expectLater(
      YeopjeonService.loadCurrent(
        competenceLoader: () async => hanokCompetenceFixture(),
        evidenceScanner: () async => {},
        preferences: store,
      ),
      throwsFormatException,
    );
  });

  test(
    'snapshot rejects an overlapping wallet write after native read',
    () async {
      final store = _WalletStore()
        ..durable = YeopjeonWallet.grandfather(
          sarangchaeStage: 0,
          b2Stage: 0,
        ).encode()
        ..heldReload = Completer<void>()
        ..reloadEntered = Completer<void>();
      final entered = store.reloadEntered!.future;
      final read = YeopjeonService.captureBackupJson(preferences: store);
      final checked = expectLater(read, throwsStateError);
      await entered;
      await Storage.runYeopjeonMutation(() async {});
      store.heldReload!.complete();
      await checked;
    },
  );

  test('read-only snapshot cannot hold reset admission open', () async {
    final store = _WalletStore()
      ..heldReload = Completer<void>()
      ..reloadEntered = Completer<void>();
    final entered = store.reloadEntered!.future;
    final read = YeopjeonService.captureBackupJson(preferences: store);
    final checked = expectLater(
      read,
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    await entered;
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init().timeout(const Duration(seconds: 1));
    store.heldReload!.complete();
    await checked;
  });
}
