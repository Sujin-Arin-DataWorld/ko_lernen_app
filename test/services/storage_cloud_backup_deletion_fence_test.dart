import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test(
    'programmatic reset preserves a persisted pending cloud deletion journal',
    () async {
      final journal = _pendingJournal();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        CloudBackupDeletionJournal.storageKey,
        jsonEncode(journal.toJson()),
      );
      await preferences.setString('kl_progress_for_reset_test', 'keep-me');

      await expectLater(
        Storage.resetAll(),
        throwsA(isA<CloudBackupDeletionResetBlockedException>()),
      );

      expect(
        preferences.getString(CloudBackupDeletionJournal.storageKey),
        jsonEncode(journal.toJson()),
      );
      expect(preferences.getString('kl_progress_for_reset_test'), 'keep-me');
    },
  );

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
    'reset remains available after confirmed cloud deletion completion',
    () async {
      final store = const SharedPreferencesCloudBackupDeletionJournalStore();
      await store.write(_pendingJournal());
      await store.clear();
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
  final Map<String, Object> values = <String, Object>{
    'kl_progress': 'remove-me',
  };
  final Map<String, Object> durable = <String, Object>{
    'kl_progress': 'remove-me',
  };
  final List<String> removals = <String>[];
  bool _journalInserted = false;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Set<String> getKeys() {
    if (!_journalInserted) {
      _journalInserted = true;
      values[Storage.cloudBackupDeletionJournalPreferenceKey] = 'retry-key';
      durable[Storage.cloudBackupDeletionJournalPreferenceKey] = 'retry-key';
    }
    return values.keys.toSet();
  }

  @override
  Object? getValue(String key) => values[key];

  @override
  Future<void> reload() async {
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
