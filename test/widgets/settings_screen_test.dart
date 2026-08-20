import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_restore_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/app_version_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ValueNotifier<CloudBackupDeletionJournalState> cloudJournalState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
    cloudJournalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
  });

  tearDown(() => cloudJournalState.dispose());

  testWidgets('typed deletion entry scrolls to the protected Settings row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          initialFocus: SettingsInitialFocus.accountDeletion,
        ),
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final deletion = find.text('Konto und alle Daten löschen');
    expect(deletion, findsOneWidget);
    final rect = tester.getRect(deletion);
    expect(rect.top, greaterThan(0));
    expect(rect.bottom, lessThan(700));
  });

  testWidgets('settings shows the injected runtime release version', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
        ),
      ),
    );
    await tester.pump();

    final version = find.text('Version 2.0.5 (11)');
    await _ensureSettingsActionVisible(tester, version);

    expect(version, findsOneWidget);
  });

  testWidgets('settings retains a neutral version when the reader fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _ThrowingAppVersionReader(),
        ),
      ),
    );
    await tester.pump();

    // Der Platzhalter ist bewusst ein einfacher Bindestrich: sichtbare
    // deutsche und englische Texte tragen keinen Geviertstrich mehr
    // (Jin 2026-08-13), und `arb_l10n_guard_test.dart` hält das fest.
    final version = find.text('Version -');
    await _ensureSettingsActionVisible(tester, version);

    expect(version, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification permission follows the visible reminder action', (
    tester,
  ) async {
    final notifications = _FakeNotificationSettingsOperations(granted: false);
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
          appVersionReader: const _FixedAppVersionReader('2.0.5 (11)'),
          notificationOperations: notifications,
        ),
      ),
    );
    await tester.pump();

    final reminder = find.text('Tägliche Erinnerung');
    await _ensureSettingsActionVisible(tester, reminder);
    expect(find.text('Taego erinnert dich ans Lernen'), findsOneWidget);
    expect(notifications.permissionRequests, 0);

    await tester.tap(
      find.ancestor(of: reminder, matching: find.byType(SwitchListTile)),
    );
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(notifications.enableCalls, 0);
    expect(notifications.disableCalls, 1);
    expect(Storage.notificationsEnabled, isFalse);
    expect(
      find.textContaining('Benachrichtigungen sind deaktiviert'),
      findsOneWidget,
    );
  });

  testWidgets(
    'voice assessment can only be enabled after the separate disclosure',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final consentTitle = find.text('Einwilligung zur Sprachbewertung');
      await _ensureSettingsActionVisible(tester, consentTitle);
      final consentSwitch = find.ancestor(
        of: consentTitle,
        matching: find.byType(SwitchListTile),
      );

      await tester.tap(consentSwitch);
      await tester.pumpAndSettle();

      expect(Storage.pronunciationConsent, isFalse);
      expect(find.text('Deine Stimme bewerten lassen?'), findsOneWidget);

      await tester.tap(find.text('Ich stimme zu und möchte eine Bewertung'));
      await tester.pumpAndSettle();

      expect(Storage.pronunciationConsent, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('settings link entry confirms before safe operation starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final operations = _SettingsAccountOperations();

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: operations,
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final link = find.text('Mit Google sichern');
    await _ensureSettingsActionVisible(tester, link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(operations.linkCalls, 0);
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    expect(operations.linkCalls, 1);
  });

  testWidgets(
    'settings keeps pending resume visible and reroutes new link to resume',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.replacementCancellable;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();
      await _ensureSettingsActionVisible(
        tester,
        find.text('Kontowechsel fortsetzen'),
      );

      expect(find.text('Fortsetzen'), findsOneWidget);
      expect(find.text('Wechsel abbrechen'), findsOneWidget);
      await _ensureSettingsActionVisible(
        tester,
        find.text('Mit Google sichern'),
      );
      final linkTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Mit Google sichern'),
          matching: find.byType(ListTile),
        ),
      );
      // The locked tile stays tappable but explains the pending replacement
      // instead of starting provider OAuth (no dead buttons).
      expect(linkTile.onTap, isNotNull);
      await tester.tap(find.text('Mit Google sichern'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(operations.linkCalls, 0);
    },
  );

  testWidgets(
    'pending remote deletion offers retry but keeps reset actions locked',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.deletionRemotePending;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final retry = find.text('Erneut versuchen');
      await _ensureSettingsActionVisible(tester, retry);
      expect(retry, findsOneWidget);
      // The local reset stays available: its wipe preserves the deletion
      // journal, so a stuck remote deletion can no longer hold it hostage.
      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      expect(
        tester
            .widget<ListTile>(
              find.ancestor(of: reset, matching: find.byType(ListTile)),
            )
            .onTap,
        isNotNull,
      );
      // Account delete responds with the deletion-pending explanation and its
      // retry — never a new-deletion confirm while the journal is unresolved.
      final delete = find.text('Konto und alle Daten löschen');
      await _ensureSettingsActionVisible(tester, delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Löschung wird fortgesetzt'),
        ),
        findsOneWidget,
      );
      expect(find.text('Löschen'), findsNothing);
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account transition pending reroutes durable backup and restore to resume',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final operations = _SettingsAccountOperations()
        ..pending.value = AccountUiPendingState.replacementCancellable;

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      for (final label in ['Jetzt sichern', 'Von Cloud wiederherstellen']) {
        await _ensureSettingsActionVisible(tester, find.text(label));
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(tile.onTap, isNotNull, reason: label);
      }
      // A locked tap opens the resume dialog; the cloud operation never runs.
      // (Restore is the last tile ensured visible above, so tap that one.)
      await tester.tap(find.text('Von Cloud wiederherstellen'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Backup erfolgreich ✓'), findsNothing);
    },
  );

  testWidgets(
    'delayed persisted journal keeps every durable action locked on the first frame',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshStarted = Completer<void>();
      final releasePersistedRead = Completer<AccountUiPendingState>();
      final operations = _DelayedJournalAccountOperations(
        refreshStarted: refreshStarted,
        readPersistedState: () => releasePersistedRead.future,
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: operations,
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await refreshStarted.future;

      // Every account tile responds from the first frame, but while the
      // persisted journal is still being read a tap only explains the lock —
      // no durable operation may start.
      for (final label in <String>[
        'Jetzt sichern',
        'Von Cloud wiederherstellen',
        'Abmelden',
        'Cloud-Daten löschen',
        'Konto und alle Daten löschen',
      ]) {
        await _ensureSettingsActionVisible(tester, find.text(label));
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(tile.onTap, isNotNull, reason: label);
      }
      await _ensureSettingsActionVisible(
        tester,
        find.text('Jetzt sichern'),
        scrollDelta: -200,
      );
      await tester.tap(find.text('Jetzt sichern'));
      await tester.pumpAndSettle();
      expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
      expect(find.text('Backup erfolgreich ✓'), findsNothing);
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();

      releasePersistedRead.complete(
        AccountUiPendingState.replacementCancellable,
      );
      await tester.pump();

      // Once the journal is known, the account-delete tap reroutes to the
      // replacement resume dialog — still no new-deletion confirm.
      final delete = find.text('Konto und alle Daten löschen');
      await _ensureSettingsActionVisible(tester, delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Löschen'), findsNothing);
    },
  );

  testWidgets('backup shows success only for a completed cloud result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      backupWithResult: () async => CloudWriteResult.blocked,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final backup = find.text('Jetzt sichern');
    await _ensureSettingsActionVisible(tester, backup);
    await tester.tap(backup);
    await tester.pumpAndSettle();

    expect(find.text('Backup erfolgreich ✓'), findsNothing);
    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'restore shows retry feedback when a fresh admission finds a pending journal',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sessions = CloudWriteSessionController()..acquire('durable');
      final journal = _MutableCloudBackupDeletionJournalStore();
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _UnusedCloudBackupDeletionGateway(),
        ),
      );
      addTearDown(AuthService.resetCloudBackupDeletionForTesting);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: false,
              ),
            ),
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
          ),
        ),
      );
      await tester.pump();

      final restore = find.text('Von Cloud wiederherstellen');
      await _ensureSettingsActionVisible(tester, restore);
      final tile = tester.widget<ListTile>(
        find.ancestor(of: restore, matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNotNull);

      journal.current = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 2,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'P' * 43,
      );
      await tester.tap(restore);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Keine Cloud-Daten'), findsNothing);
    },
  );

  testWidgets('restore shows retry feedback for a typed stale result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      restoreWithResult: () async => CloudRestoreResult.stale,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final restore = find.text('Von Cloud wiederherstellen');
    await _ensureSettingsActionVisible(tester, restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsOneWidget,
    );
    expect(find.text('Keine Cloud-Daten'), findsNothing);
  });

  testWidgets('restore shows no-backup feedback for a typed empty result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = CloudWriteSessionController()..acquire('durable');
    AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
      CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _ClearCloudBackupDeletionJournalStore(),
        gateway: _UnusedCloudBackupDeletionGateway(),
      ),
    );
    CloudSync.overrideOperationsForTesting(
      restoreWithResult: () async => CloudRestoreResult.empty,
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final restore = find.text('Von Cloud wiederherstellen');
    await _ensureSettingsActionVisible(tester, restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(find.text('Keine Cloud-Daten'), findsOneWidget);
    expect(
      find.text(
        'Die sichere Prüfung konnte nicht abgeschlossen werden. '
        'Du kannst denselben Vorgang erneut versuchen.',
      ),
      findsNothing,
    );
  });

  testWidgets('deletion failure is recoverable and redacts private details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cleanup = _DeletionCleanup()
      ..failure = StateError('proof-secret-789 raw Firebase failure');

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          accountDeletionWorkflow: AccountDeletionWorkflow(cleanup),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Konto und alle Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(cleanup.deleteCalls, 0);

    await tester.tap(find.text('Löschen').last);
    await tester.pump();

    expect(cleanup.deleteCalls, 1);
    expect(find.textContaining('proof-secret-789'), findsNothing);
    expect(find.textContaining('raw Firebase failure'), findsNothing);
    expect(find.text('Löschung wird fortgesetzt'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('cloud-data deletion redacts provider errors', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async {
            throw StateError('proof-secret-456 raw Firestore detail');
          },
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Cloud-Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen').last);
    await tester.pump();

    expect(find.textContaining('proof-secret-456'), findsNothing);
    expect(find.textContaining('raw Firestore detail'), findsNothing);
    expect(
      find.text('Cloud-Daten konnten nicht gelöscht werden.'),
      findsOneWidget,
    );
  });

  testWidgets('cloud-data deletion reports success only when completed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async => CloudWriteResult.blocked,
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Cloud-Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('L\u00f6schen').last);
    await tester.pump();

    expect(find.text('Cloud-Daten wurden gel\u00f6scht.'), findsNothing);
    expect(
      find.text('Cloud-Daten konnten nicht gel\u00f6scht werden.'),
      findsOneWidget,
    );
  });

  testWidgets('loading cloud deletion locks backup restore sign-out and link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.loading,
    );
    addTearDown(journalState.dispose);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
          ),
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletion: () async => CloudWriteResult.blocked,
          cloudDataDeletionJournalState: journalState,
        ),
      ),
    );
    await tester.pump();

    // While the journal state is still loading, account tiles respond but a
    // tap only shows the generic protection notice — nothing may act on an
    // undisclosed journal.
    for (final label in [
      'Jetzt sichern',
      'Von Cloud wiederherstellen',
      'Abmelden',
    ]) {
      await _ensureSettingsActionVisible(tester, find.text(label));
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNotNull, reason: label);
    }

    final retryLabel = find.text('Cloud-Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, retryLabel, scrollDelta: -200);
    await tester.tap(retryLabel);
    await tester.pumpAndSettle();
    expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();

    journalState.value = CloudBackupDeletionJournalState.pending;
    await tester.pump();
    // A confirmed pending journal resumes the exact saved request.
    await _ensureSettingsActionVisible(tester, retryLabel, scrollDelta: -200);
    await tester.tap(retryLabel);
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Löschung fortsetzen'), findsOneWidget);
    await tester.tap(find.text('Jetzt fortsetzen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cloud-Daten konnten nicht gelöscht werden.'),
      findsOneWidget,
    );

    final accountDeleteLabel = find.text('Konto und alle Daten l\u00f6schen');
    await _ensureSettingsActionVisible(tester, accountDeleteLabel);
    // Account delete responds with the cloud-resume explanation instead of a
    // dead tap while that journal is unresolved.
    await tester.tap(accountDeleteLabel);
    await tester.pumpAndSettle();
    expect(find.text('Cloud-Löschung wird fortgesetzt'), findsOneWidget);
  });

  testWidgets('retry after local cleanup failure never deletes a new account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cleanup = _DeletionCleanup()..imageFailures = 1;

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          accountDeletionWorkflow: AccountDeletionWorkflow(cleanup),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final delete = find.text('Konto und alle Daten löschen');
    await _ensureSettingsActionVisible(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen').last);
    await tester.pump();
    expect(cleanup.deleteCalls, 1);

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(cleanup.deleteCalls, 1);
    expect(cleanup.imageCalls, 2);
  });

  testWidgets(
    'reset closes its dialog and shows a safe retry message when a journal appears',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            resetAllData: () async {
              throw const CloudBackupDeletionResetBlockedException();
            },
          ),
        ),
      );
      await tester.pump();

      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alle Daten zurücksetzen'), findsOneWidget);
      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'reset does not pop settings when its dialog was already dismissed',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final startedReset = Completer<void>();
      final releaseReset = Completer<void>();

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            account: _guest,
            accountOperations: _SettingsAccountOperations(),
            cloudDataDeletionJournalState: cloudJournalState,
            resetAllData: () async {
              startedReset.complete();
              await releaseReset.future;
              throw const CloudBackupDeletionResetBlockedException();
            },
          ),
        ),
      );
      await tester.pump();

      final reset = find.text('Alle Daten zurücksetzen');
      await _ensureSettingsActionVisible(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await startedReset.future;
      await tester.pump();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      releaseReset.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alle Daten zurücksetzen'), findsOneWidget);
      expect(
        find.text(
          'Die sichere Prüfung konnte nicht abgeschlossen werden. '
          'Du kannst denselben Vorgang erneut versuchen.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings exposes no-companion state and allows a later choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await MascotPreference.setNone();
    addTearDown(() => MascotPreference.set(MascotKind.tiger));

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          account: _guest,
          accountOperations: _SettingsAccountOperations(),
          cloudDataDeletionJournalState: cloudJournalState,
        ),
      ),
    );
    await tester.pump();

    final noCompanion = find.text('Keine Lernbegleitung');
    await _ensureSettingsActionVisible(tester, noCompanion);
    expect(noCompanion, findsOneWidget);
    await tester.tap(noCompanion);
    await tester.pumpAndSettle();
    await tester.tap(find.text('태고'));
    await tester.pumpAndSettle();

    expect(MascotPreference.selectedKind, MascotKind.tiger);
    expect(find.text('태고'), findsOneWidget);
  });
}

const _guest = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);

class _FakeNotificationSettingsOperations
    implements NotificationSettingsOperations {
  _FakeNotificationSettingsOperations({required this.granted});

  final bool granted;
  int permissionRequests = 0;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> enable({
    required int hour,
    required String title,
    required String body,
    required String streakTitle,
    required String streakBody,
  }) async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

class _FixedAppVersionReader implements AppVersionReader {
  const _FixedAppVersionReader(this.version);

  final String version;

  @override
  Future<String> readVersion() async => version;
}

class _ThrowingAppVersionReader implements AppVersionReader {
  const _ThrowingAppVersionReader();

  @override
  Future<String> readVersion() async {
    throw StateError('native package metadata unavailable');
  }
}

class _SettingsAccountOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  int linkCalls = 0;
  final ValueNotifier<AccountUiPendingState> pending =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.none);

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<bool> cancelReplacement() async => true;

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountTransitionResult(AccountTransitionStatus.completed);

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    linkCalls += 1;
    return const AccountUiLinkCompleted();
  }

  @override
  Future<AccountTransitionResult> resumeReplacement() async =>
      const AccountTransitionResult(AccountTransitionStatus.completed);
}

class _DelayedJournalAccountOperations extends _SettingsAccountOperations {
  _DelayedJournalAccountOperations({
    required this.refreshStarted,
    required this.readPersistedState,
  });

  final Completer<void> refreshStarted;
  final Future<AccountUiPendingState> Function() readPersistedState;

  @override
  Future<AccountUiPendingState> refreshPendingState() async {
    if (!refreshStarted.isCompleted) {
      refreshStarted.complete();
    }
    final state = await readPersistedState();
    pending.value = state;
    return state;
  }
}

class _ClearCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async =>
      true;

  @override
  Future<CloudBackupDeletionJournal?> read() async => null;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    throw UnimplementedError();
  }
}

class _MutableCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  CloudBackupDeletionJournal? current;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    if (current != expected) return false;
    current = null;
    return true;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async => current;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    current = journal;
  }
}

class _UnusedCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    throw UnimplementedError();
  }
}

class _DeletionCleanup implements AccountDeletionCleanupOperations {
  Object? failure;
  int deleteCalls = 0;
  int imageFailures = 0;
  int imageCalls = 0;

  @override
  Future<void> clearTtsCache() async {}

  @override
  Future<void> deleteLocalImages() async {
    imageCalls += 1;
    if (imageFailures > 0) {
      imageFailures -= 1;
      throw StateError('private local image failure');
    }
  }

  @override
  Future<void> deleteRemoteAccount() async {
    deleteCalls += 1;
    if (failure case final value?) throw value;
  }

  @override
  Future<void> disablePush() async {}

  @override
  void resetInMemoryData() {}

  @override
  Future<void> resetLocalStorage() async {}
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}

Future<void> _ensureSettingsActionVisible(
  WidgetTester tester,
  Finder finder, {
  double scrollDelta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    scrollDelta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}
