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
