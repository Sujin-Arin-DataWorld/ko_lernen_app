import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/main.dart'
    show
        runPostMigrationStudyLogMaintenance,
        runStartupMigrationBeforeCloudServices;
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

  test('cloud reconciliation starts only after migration completes', () async {
    final migrationCompleter = Completer<DataMigrationResult>();
    final events = <String>[];

    final startup = runStartupMigrationBeforeCloudServices(
      migrate: () {
        events.add('migration:start');
        return migrationCompleter.future;
      },
      startCloudServices: () async {
        events.add('cloud:start');
      },
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, ['migration:start']);

    events.add('migration:complete');
    migrationCompleter.complete(writable);
    expect(await startup, writable);
    expect(events, ['migration:start', 'migration:complete', 'cloud:start']);
  });

  test('cloud startup still follows a failed migration attempt', () async {
    final events = <String>[];
    final failures = <Object>[];

    final result = await runStartupMigrationBeforeCloudServices(
      migrate: () async {
        events.add('migration:start');
        throw StateError('migration failed');
      },
      startCloudServices: () async {
        events.add('cloud:start');
      },
      onMigrationFailure: failures.add,
    );

    expect(result, isNull);
    expect(events, ['migration:start', 'cloud:start']);
    expect(failures.single, isA<StateError>());
  });

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
