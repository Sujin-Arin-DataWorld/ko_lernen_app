import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';

void main() {
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
