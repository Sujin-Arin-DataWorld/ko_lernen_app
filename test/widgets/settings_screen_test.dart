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
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ValueNotifier<CloudBackupDeletionJournalState> cloudJournalState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    cloudJournalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
  });

  tearDown(() => cloudJournalState.dispose());

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
    await tester.scrollUntilVisible(
      link,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(operations.linkCalls, 0);
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    expect(operations.linkCalls, 1);
  });

  testWidgets('settings keeps pending resume visible and disables new link', (
    tester,
  ) async {
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
    await tester.scrollUntilVisible(
      find.text('Kontowechsel fortsetzen'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Fortsetzen'), findsOneWidget);
    expect(find.text('Wechsel abbrechen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mit Google sichern'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    final linkTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Mit Google sichern'),
        matching: find.byType(ListTile),
      ),
    );
    expect(linkTile.onTap, isNull);
    expect(operations.linkCalls, 0);
  });

  testWidgets('account transition pending locks durable backup and restore', (
    tester,
  ) async {
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
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNull, reason: label);
    }
  });

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

      for (final label in <String>[
        'Jetzt sichern',
        'Von Cloud wiederherstellen',
        'Abmelden',
        'Cloud-Daten löschen',
      ]) {
        await _expectSettingsTileDisabled(tester, label);
      }

      releasePersistedRead.complete(
        AccountUiPendingState.replacementCancellable,
      );
      await tester.pump();

      for (final label in <String>[
        'Jetzt sichern',
        'Von Cloud wiederherstellen',
        'Abmelden',
        'Cloud-Daten löschen',
      ]) {
        await _expectSettingsTileDisabled(tester, label);
      }
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
    await tester.scrollUntilVisible(
      backup,
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
      await tester.scrollUntilVisible(
        restore,
        200,
        scrollable: find.byType(Scrollable).first,
      );
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
    await tester.scrollUntilVisible(
      restore,
      200,
      scrollable: find.byType(Scrollable).first,
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
    await tester.scrollUntilVisible(
      restore,
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    await tester.scrollUntilVisible(
      delete,
      250,
      scrollable: find.byType(Scrollable).first,
    );
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
    await tester.scrollUntilVisible(
      delete,
      250,
      scrollable: find.byType(Scrollable).first,
    );
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
    await tester.scrollUntilVisible(
      delete,
      250,
      scrollable: find.byType(Scrollable).first,
    );
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

    for (final label in [
      'Jetzt sichern',
      'Von Cloud wiederherstellen',
      'Abmelden',
      'Alle Daten zurücksetzen',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNull, reason: label);
    }

    final retryLabel = find.text('Cloud-Daten l\u00f6schen');
    await tester.scrollUntilVisible(
      retryLabel,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final retryDelete = tester.widget<ListTile>(
      find.ancestor(of: retryLabel, matching: find.byType(ListTile)),
    );
    expect(retryDelete.onTap, isNull);

    journalState.value = CloudBackupDeletionJournalState.pending;
    await tester.pump();
    final retryAfterAuthoritativePending = tester.widget<ListTile>(
      find.ancestor(of: retryLabel, matching: find.byType(ListTile)),
    );
    expect(retryAfterAuthoritativePending.onTap, isNotNull);

    final accountDeleteLabel = find.text('Konto und alle Daten l\u00f6schen');
    await tester.scrollUntilVisible(
      accountDeleteLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final accountDelete = tester.widget<ListTile>(
      find.ancestor(of: accountDeleteLabel, matching: find.byType(ListTile)),
    );
    expect(accountDelete.onTap, isNull);
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
    await tester.scrollUntilVisible(
      delete,
      250,
      scrollable: find.byType(Scrollable).first,
    );
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
      await tester.scrollUntilVisible(
        reset,
        250,
        scrollable: find.byType(Scrollable).first,
      );
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
      await tester.scrollUntilVisible(
        reset,
        250,
        scrollable: find.byType(Scrollable).first,
      );
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
}

const _guest = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);

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

Future<void> _expectSettingsTileDisabled(
  WidgetTester tester,
  String label,
) async {
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  final tile = tester.widget<ListTile>(
    find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
  );
  expect(tile.onTap, isNull, reason: label);
}
