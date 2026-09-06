import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill_journal.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test(
    'ordinary and strict local resets clear the canonical course cache',
    () async {
      for (final reset in <Future<void> Function()>[
        () => Storage.resetAll(),
        () => Storage.resetAllStrict(),
      ]) {
        await Storage.setCourseMasterySnapshotRawJson(
          '{"version":3,"placementLevel":"a1"}',
        );
        expect(Storage.courseMasterySnapshotRawJson, isNotEmpty);

        await reset();

        expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      }
    },
  );

  test(
    'ordinary and strict resets invalidate admitted restore leases',
    () async {
      final beforeOrdinaryReset = LocalDataLifetime.capture();
      await Storage.resetAll();
      expect(beforeOrdinaryReset.isCurrent, isFalse);

      final beforeStrictReset = LocalDataLifetime.capture();
      await Storage.resetAllStrict();
      expect(beforeStrictReset.isCurrent, isFalse);
    },
  );

  test('programmatic reset completes beside a pending cloud deletion journal '
      'and preserves that journal', () async {
    final journal = _pendingJournal();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      CloudBackupDeletionJournal.storageKey,
      jsonEncode(journal.toJson()),
    );
    await preferences.setString('kl_progress_for_reset_test', 'remove-me');

    await Storage.resetAll();

    expect(
      preferences.getString(CloudBackupDeletionJournal.storageKey),
      jsonEncode(journal.toJson()),
    );
    expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
  });

  test(
    'programmatic reset preserves a persisted account-switch journal',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountSwitchJournal.storageKey,
        'pending-switch',
      );
      await preferences.setString('kl_progress_for_reset_test', 'keep-me');

      await expectLater(
        Storage.resetAll(),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(
        preferences.getString(AccountSwitchJournal.storageKey),
        'pending-switch',
      );
      expect(preferences.getString('kl_progress_for_reset_test'), 'keep-me');
    },
  );

  test(
    'programmatic reset preserves a persisted switch-reconciliation journal',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.switchReconciliationStorageKey,
        'merge-in-progress',
      );
      await preferences.setString('kl_progress_for_reset_test', 'keep-me');

      await expectLater(
        Storage.resetAll(),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(
        preferences.getString(
          AccountTransitionJournal.switchReconciliationStorageKey,
        ),
        'merge-in-progress',
      );
      expect(preferences.getString('kl_progress_for_reset_test'), 'keep-me');
    },
  );

  test(
    'a leftover legacy replacement journal no longer fences a programmatic '
    'reset and is wiped with the rest of the local data',
    () async {
      // The legacy key is never written since the 2026-09-05 redesign and is
      // discarded at startup, so it must not block or survive a reset.
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.storageKey,
        'legacy-replacement',
      );
      await preferences.setString('kl_progress_for_reset_test', 'remove-me');

      await Storage.resetAll();

      expect(
        preferences.containsKey(AccountTransitionJournal.storageKey),
        isFalse,
      );
      expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
    },
  );

  test('programmatic reset completes beside an account deletion checkpoint '
      'and preserves that checkpoint', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      Storage.accountDeletionCheckpointPreferenceKey,
      'pending-account-deletion',
    );
    await preferences.setString('kl_progress_for_reset_test', 'remove-me');

    await Storage.resetAll();

    expect(
      preferences.getString(Storage.accountDeletionCheckpointPreferenceKey),
      'pending-account-deletion',
    );
    expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
  });

  test('programmatic reset completes beside a feedback-activation checkpoint '
      'and preserves that checkpoint', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      Storage.accountDeletionFeedbackActivationCheckpointPreferenceKey,
      'completed-feedback-activation',
    );
    await preferences.setString('kl_progress_for_reset_test', 'remove-me');

    await Storage.resetAll();

    expect(
      preferences.getString(
        Storage.accountDeletionFeedbackActivationCheckpointPreferenceKey,
      ),
      'completed-feedback-activation',
    );
    expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
  });

  test(
    'strict reset also preserves a persisted pending cloud deletion journal',
    () async {
      final store = const SharedPreferencesCloudBackupDeletionJournalStore();
      await store.write(_pendingJournal());

      await expectLater(
        Storage.resetAllStrict(),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(await store.read(), isNotNull);
    },
  );

  test(
    'strict reset blocks an account deletion checkpoint without its cleanup canonicalizer',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        Storage.accountDeletionCheckpointPreferenceKey,
        'pending-account-deletion',
      );
      await preferences.setString('kl_progress_for_reset_test', 'keep-me');

      await expectLater(
        Storage.resetAllStrict(),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(
        preferences.getString(Storage.accountDeletionCheckpointPreferenceKey),
        'pending-account-deletion',
      );
      expect(preferences.getString('kl_progress_for_reset_test'), 'keep-me');
    },
  );

  test(
    'strict account-deletion cleanup retains and canonicalizes its completed checkpoint',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        Storage.accountDeletionCheckpointPreferenceKey,
        'completed-account-deletion',
      );
      await preferences.setString('kl_progress_for_reset_test', 'remove-me');

      await Storage.resetAllStrict(
        canonicalizeAccountDeletionCheckpoint: (raw) => 'canonical:$raw',
      );

      expect(
        preferences.getString(Storage.accountDeletionCheckpointPreferenceKey),
        'canonical:completed-account-deletion',
      );
      expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
    },
  );

  test(
    'strict cleanup preserves a feedback-activation checkpoint after restart',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        Storage.accountDeletionFeedbackActivationCheckpointPreferenceKey,
        'completed-feedback-activation',
      );
      await preferences.setString('kl_progress_for_reset_test', 'remove-me');

      await Storage.resetAllStrict(
        canonicalizeAccountDeletionCheckpoint: (raw) => 'canonical:$raw',
      );

      expect(
        preferences.getString(
          Storage.accountDeletionFeedbackActivationCheckpointPreferenceKey,
        ),
        'canonical:completed-feedback-activation',
      );
      expect(preferences.containsKey('kl_progress_for_reset_test'), isFalse);
    },
  );

  test(
    'explicit reset and account-deletion cleanup intentionally discard first-link receipts',
    () async {
      const store = SharedPreferencesFirstDurableLinkBackfillJournalStore();
      final pending = FirstDurableLinkBackfillJournal.pending(
        uid: 'source',
        token: 'first-link-token',
      );

      expect(await store.createIfAbsent(pending), isTrue);
      await Storage.resetAll();
      expect(await store.read(), isNull);

      expect(await store.createIfAbsent(pending), isTrue);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        Storage.accountDeletionCheckpointPreferenceKey,
        'completed-account-deletion',
      );
      await Storage.resetAllStrict(
        canonicalizeAccountDeletionCheckpoint: (raw) => 'canonical:$raw',
      );

      expect(await store.read(), isNull);
    },
  );

  test(
    'strict account-deletion cleanup blocks a pending account switch',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountSwitchJournal.storageKey,
        'pending-switch',
      );
      await preferences.setString(
        Storage.accountDeletionCheckpointPreferenceKey,
        'completed-account-deletion',
      );
      await preferences.setString('kl_progress_for_reset_test', 'keep-me');

      await expectLater(
        Storage.resetAllStrict(
          canonicalizeAccountDeletionCheckpoint: (raw) => 'canonical:$raw',
        ),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(
        preferences.getString(AccountSwitchJournal.storageKey),
        'pending-switch',
      );
      expect(
        preferences.getString(Storage.accountDeletionCheckpointPreferenceKey),
        'completed-account-deletion',
      );
      expect(preferences.getString('kl_progress_for_reset_test'), 'keep-me');
    },
  );

  test(
    'reset remains available after confirmed cloud deletion completion',
    () async {
      final store = const SharedPreferencesCloudBackupDeletionJournalStore();
      final journal = _pendingJournal();
      await store.write(journal);
      expect(await store.clearIfCurrent(journal), isTrue);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('kl_progress_after_completion', 'remove-me');

      await Storage.resetAll();

      expect(preferences.containsKey('kl_progress_after_completion'), isFalse);
    },
  );

  test(
    'ordinary reset retains a journal written after the admission check',
    () async {
      final store = _InterleavingPreferenceRemovalStore();

      await Storage.resetAll(preferences: store);

      expect(
        store.durable.containsKey(
          Storage.cloudBackupDeletionJournalPreferenceKey,
        ),
        isTrue,
      );
      expect(
        store.removals,
        isNot(contains(Storage.cloudBackupDeletionJournalPreferenceKey)),
      );
      expect(store.durable.containsKey('kl_progress'), isFalse);
    },
  );

  test(
    'strict reset retains a journal written after the admission check',
    () async {
      final store = _InterleavingPreferenceRemovalStore();

      await Storage.resetAllStrict(preferences: store);

      expect(
        store.durable.containsKey(
          Storage.cloudBackupDeletionJournalPreferenceKey,
        ),
        isTrue,
      );
      expect(
        store.removals,
        isNot(contains(Storage.cloudBackupDeletionJournalPreferenceKey)),
      );
      expect(store.durable.containsKey('kl_progress'), isFalse);
    },
  );

  test(
    'ordinary reset retains an account-switch journal written after admission',
    () async {
      final store = _InterleavingPreferenceRemovalStore(
        insertedJournalKey: AccountSwitchJournal.storageKey,
      );

      await Storage.resetAll(preferences: store);

      expect(
        store.durable.containsKey(AccountSwitchJournal.storageKey),
        isTrue,
      );
      expect(
        store.removals,
        isNot(contains(AccountSwitchJournal.storageKey)),
      );
      expect(store.durable.containsKey('kl_progress'), isFalse);
    },
  );

  test(
    'ordinary reset retains an account deletion checkpoint written after admission',
    () async {
      final store = _InterleavingPreferenceRemovalStore(
        insertedJournalKey: Storage.accountDeletionCheckpointPreferenceKey,
      );

      await Storage.resetAll(preferences: store);

      expect(
        store.durable.containsKey(
          Storage.accountDeletionCheckpointPreferenceKey,
        ),
        isTrue,
      );
      expect(
        store.removals,
        isNot(contains(Storage.accountDeletionCheckpointPreferenceKey)),
      );
      expect(store.durable.containsKey('kl_progress'), isFalse);
    },
  );

  test(
    'ordinary reset fails closed when its final journal reload fails',
    () async {
      final store = _InterleavingPreferenceRemovalStore()..reloadFails = true;

      await expectLater(
        Storage.resetAll(preferences: store),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(store.removals, isEmpty);
      expect(store.durable['kl_progress'], 'remove-me');
    },
  );
}

CloudBackupDeletionJournal _pendingJournal() =>
    CloudBackupDeletionJournal.pending(
      session: const CloudWriteSession(
        uid: 'durable-user',
        epoch: 3,
        mode: CloudWriteMode.cleanupPending,
      ),
      requestKey: List<String>.filled(43, 'A').join(),
    );

class _InterleavingPreferenceRemovalStore implements PreferenceRemovalStore {
  _InterleavingPreferenceRemovalStore({
    this.insertedJournalKey = Storage.cloudBackupDeletionJournalPreferenceKey,
  });

  final String insertedJournalKey;
  final Map<String, Object> values = <String, Object>{
    'kl_progress': 'remove-me',
  };
  final Map<String, Object> durable = <String, Object>{
    'kl_progress': 'remove-me',
  };
  final List<String> removals = <String>[];
  bool _journalInserted = false;
  bool reloadFails = false;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Set<String> getKeys() {
    if (!_journalInserted) {
      _journalInserted = true;
      values[insertedJournalKey] = 'retry-key';
      durable[insertedJournalKey] = 'retry-key';
    }
    return values.keys.toSet();
  }

  @override
  Object? getValue(String key) => values[key];

  @override
  Future<void> reload() async {
    if (reloadFails) {
      throw StateError('native reload failed');
    }
    values
      ..clear()
      ..addAll(durable);
  }

  @override
  Future<bool> remove(String key) async {
    removals.add(key);
    values.remove(key);
    durable.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    durable[key] = value;
    return true;
  }
}
