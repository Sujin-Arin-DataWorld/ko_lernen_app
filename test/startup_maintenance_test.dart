import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/main.dart'
    show runPostMigrationStudyLogMaintenance;
import 'package:ko_lernen_app/services/data_migration_service.dart';

void main() {
  const writable = DataMigrationResult(
    status: DataMigrationStatus.upToDate,
    fromVersion: 1,
    toVersion: 1,
  );
  const readOnly = DataMigrationResult(
    status: DataMigrationStatus.futureVersion,
    fromVersion: 2,
    toVersion: 1,
  );

  test(
    'post-migration maintenance skips pruning without writable migration',
    () async {
      var pruneCalls = 0;
      Future<void> prune() async => pruneCalls++;

      await runPostMigrationStudyLogMaintenance(null, pruneStudyLog: prune);
      await runPostMigrationStudyLogMaintenance(readOnly, pruneStudyLog: prune);

      expect(pruneCalls, 0);
    },
  );

  test(
    'post-migration maintenance runs pruning after a writable migration',
    () async {
      var pruneCalls = 0;

      await runPostMigrationStudyLogMaintenance(
        writable,
        pruneStudyLog: () async => pruneCalls++,
      );

      expect(pruneCalls, 1);
    },
  );

  test(
    'post-migration maintenance reports a prune failure and completes',
    () async {
      final reported = <Object>[];

      await runPostMigrationStudyLogMaintenance(
        writable,
        pruneStudyLog: () async => throw StateError('prune failed'),
        onPruneFailure: reported.add,
      );

      expect(reported, hasLength(1));
      expect(reported.single, isA<StateError>());
    },
  );
}
