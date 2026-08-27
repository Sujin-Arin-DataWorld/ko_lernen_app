import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/cloud_restore_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_auto_sync.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('runs restore-merge then backup once for a durable account', () async {
    final events = <String>[];
    final preferences = await SharedPreferences.getInstance();

    final ran = await CloudAutoSync.runStartupSync(
      currentUid: () => 'durable-uid',
      restore: () async {
        events.add('restore');
        return CloudRestoreResult.completed;
      },
      backup: () async {
        events.add('backup');
        return CloudWriteResult.completed;
      },
      now: () => DateTime(2026, 8, 10, 9),
      preferences: preferences,
    );

    expect(ran, isTrue);
    expect(events, <String>['restore', 'backup']);
    expect(
      preferences.getString(CloudAutoSync.lastAutoSyncDayPreferenceKey),
      '2026-08-10',
    );
  });

  test('skips entirely without a durable cloud account', () async {
    final events = <String>[];
    final preferences = await SharedPreferences.getInstance();

    final ran = await CloudAutoSync.runStartupSync(
      currentUid: () => null,
      restore: () async {
        events.add('restore');
        return CloudRestoreResult.completed;
      },
      backup: () async {
        events.add('backup');
        return CloudWriteResult.completed;
      },
      now: () => DateTime(2026, 8, 10, 9),
      preferences: preferences,
    );

    expect(ran, isFalse);
    expect(events, isEmpty);
    expect(
      preferences.getString(CloudAutoSync.lastAutoSyncDayPreferenceKey),
      isNull,
    );
  });

  test('throttles to one successful sync per calendar day', () async {
    final events = <String>[];
    final preferences = await SharedPreferences.getInstance();
    Future<bool> run(DateTime at) => CloudAutoSync.runStartupSync(
      currentUid: () => 'durable-uid',
      restore: () async {
        events.add('restore');
        return CloudRestoreResult.completed;
      },
      backup: () async {
        events.add('backup');
        return CloudWriteResult.completed;
      },
      now: () => at,
      preferences: preferences,
    );

    expect(await run(DateTime(2026, 8, 10, 9)), isTrue);
    expect(await run(DateTime(2026, 8, 10, 21)), isFalse);
    expect(events, hasLength(2));

    expect(await run(DateTime(2026, 8, 11, 7)), isTrue);
    expect(events, hasLength(4));
  });

  for (final restoreResult in <CloudRestoreResult>[
    CloudRestoreResult.blocked,
    CloudRestoreResult.stale,
  ]) {
    test(
      '$restoreResult aborts before backup and does not consume the day',
      () async {
        final events = <String>[];
        final preferences = await SharedPreferences.getInstance();

        final ran = await CloudAutoSync.runStartupSync(
          currentUid: () => 'durable-uid',
          restore: () async {
            events.add('restore');
            return restoreResult;
          },
          backup: () async {
            events.add('backup');
            return CloudWriteResult.completed;
          },
          now: () => DateTime(2026, 8, 10, 9),
          preferences: preferences,
        );

        expect(ran, isFalse);
        expect(events, <String>['restore']);
        expect(
          preferences.getString(CloudAutoSync.lastAutoSyncDayPreferenceKey),
          isNull,
        );
      },
    );
  }

  test(
    'local reset during restore cancels backup and the daily marker',
    () async {
      final restoreStarted = Completer<void>();
      final restoreMayFinish = Completer<void>();
      var backupCalls = 0;
      final preferences = await SharedPreferences.getInstance();

      final run = CloudAutoSync.runStartupSync(
        currentUid: () => 'durable-uid',
        restore: () async {
          restoreStarted.complete();
          await restoreMayFinish.future;
          return CloudRestoreResult.completed;
        },
        backup: () async {
          backupCalls += 1;
          return CloudWriteResult.completed;
        },
        now: () => DateTime(2026, 8, 10, 9),
        preferences: preferences,
      );
      await restoreStarted.future;
      await Storage.resetAll();
      restoreMayFinish.complete();

      expect(await run, isFalse);
      expect(backupCalls, 0);
      expect(
        preferences.getString(CloudAutoSync.lastAutoSyncDayPreferenceKey),
        isNull,
      );
    },
  );

  test('never throws when restore or backup throw', () async {
    final preferences = await SharedPreferences.getInstance();

    final ran = await CloudAutoSync.runStartupSync(
      currentUid: () => 'durable-uid',
      restore: () async => throw StateError('offline'),
      backup: () async => CloudWriteResult.completed,
      now: () => DateTime(2026, 8, 10, 9),
      preferences: preferences,
    );

    expect(ran, isFalse);
    expect(
      preferences.getString(CloudAutoSync.lastAutoSyncDayPreferenceKey),
      isNull,
    );
  });
}
