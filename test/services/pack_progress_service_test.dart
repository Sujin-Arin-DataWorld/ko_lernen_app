import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  const catalog = {
    'pack-a': PackCatalogEntry(packId: 'pack-a', level: 'A1', wordsTotal: 10),
  };

  test('merge rejects progress for an unknown catalog id', () {
    final result = PackProgressService.mergeForReconciliation(
      local: const {},
      remote: {'unknown': _progress(packId: 'unknown')},
      catalog: catalog,
    );

    expect(result.isValid, isFalse);
    expect(result.invalidPackIds, ['unknown']);
  });

  test('merge rejects impossible cleared status and attempt semantics', () {
    final result = PackProgressService.mergeForReconciliation(
      local: const {},
      remote: {
        'pack-a': _progress(
          status: PackStatus.cleared,
          bossAccuracy: 0.4,
          attempts: 0,
          clearedAtIso: 'not-a-date',
        ),
      },
      catalog: catalog,
    );

    expect(result.isValid, isFalse);
    expect(result.invalidPackIds, ['pack-a']);
  });

  test('merge rejects an in-progress status with clearing accuracy', () {
    final result = PackProgressService.mergeForReconciliation(
      local: const {},
      remote: {
        'pack-a': _progress(
          status: PackStatus.inProgress,
          bossAccuracy: 0.8,
          attempts: 1,
        ),
      },
      catalog: catalog,
    );

    expect(result.isValid, isFalse);
    expect(result.invalidPackIds, ['pack-a']);
  });

  test('merge is deterministic and monotonic for valid attempts', () {
    final local = _progress(
      wordsLearned: 4,
      bossAccuracy: 0.5,
      attempts: 1,
      status: PackStatus.inProgress,
    );
    final remote = _progress(
      wordsLearned: 6,
      bossAccuracy: 0.8,
      attempts: 2,
      status: PackStatus.cleared,
      clearedAtIso: '2026-07-29T12:00:00.000Z',
    );

    final left = PackProgressService.mergeForReconciliation(
      local: {'pack-a': local},
      remote: {'pack-a': remote},
      catalog: catalog,
    );
    final right = PackProgressService.mergeForReconciliation(
      local: {'pack-a': remote},
      remote: {'pack-a': local},
      catalog: catalog,
    );

    expect(left.isValid, isTrue);
    expect(left.merged?['pack-a']?.wordsLearned, 6);
    expect(left.merged?['pack-a']?.attempts, 2);
    expect(left.merged?['pack-a']?.bossAccuracy, 0.8);
    expect(left.merged?['pack-a']?.status, PackStatus.cleared);
    expect(left.merged?['pack-a']?.toJson(), right.merged?['pack-a']?.toJson());
  });

  test(
    'first-link upload writes only local progress under its exact session',
    () async {
      await Storage.setPackProgressJson(
        'pack-a',
        _progress(
          status: PackStatus.inProgress,
          wordsLearned: 4,
          attempts: 1,
          bossAccuracy: 0.5,
        ).toJson(),
      );
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      final uploaded = <PackProgress>[];

      final result =
          await PackProgressService.uploadLocalProgressForFirstDurableLink(
            session: session,
            sessions: sessions,
            writeRemote: (progresses) async {
              uploaded.addAll(progresses);
              return CloudWriteResult.completed;
            },
          );

      expect(result, CloudWriteResult.completed);
      expect(uploaded.map((progress) => progress.packId), ['pack-a']);
      expect(uploaded.single.wordsLearned, 4);
    },
  );

  test('first-link upload rejects a newer session for the same UID', () async {
    final sessions = CloudWriteSessionController();
    final session = sessions.acquire('source');
    sessions.acquire('source');
    var remoteWrites = 0;

    final result =
        await PackProgressService.uploadLocalProgressForFirstDurableLink(
          session: session,
          sessions: sessions,
          writeRemote: (progresses) async {
            remoteWrites += 1;
            return CloudWriteResult.completed;
          },
        );

    expect(result, CloudWriteResult.stale);
    expect(remoteWrites, 0);
  });

  test('typed pack restore reports remote progress as restorable', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final session = sessions.current!;
    Map<String, Map<String, dynamic>>? persisted;

    final result =
        await PackProgressService.pullTypedFromCloudWithSessionResult(
          sessions: sessions,
          uid: 'uid-a',
          expectedSession: session,
          loadRemote: () async => CloudReadResult.present(
            FirestorePackSnapshot(
              progress: {'pack-a': _progress(wordsLearned: 4)},
              revisions: const {'pack-a': 1},
              membershipRevision: 1,
            ),
          ),
          loadLocal: () => const <String, PackProgress>{},
          persistLocal: (progress) async => persisted = progress,
        );

    expect(result.status, CloudWriteResult.completed);
    expect(result.hasRemoteData, isTrue);
    expect(persisted?['pack-a']?['wordsLearned'], 4);
  });
}

PackProgress _progress({
  String packId = 'pack-a',
  PackStatus status = PackStatus.available,
  int wordsLearned = 0,
  double bossAccuracy = 0,
  int attempts = 0,
  String? clearedAtIso,
}) {
  return PackProgress(
    packId: packId,
    level: 'A1',
    status: status,
    wordsLearned: wordsLearned,
    wordsTotal: 10,
    bossAccuracy: bossAccuracy,
    attempts: attempts,
    clearedAtIso: clearedAtIso,
  );
}
