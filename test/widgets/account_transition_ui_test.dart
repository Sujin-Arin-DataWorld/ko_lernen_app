import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';
import 'package:ko_lernen_app/widgets/sori/account_operation_ui.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_profile': true});
    await Storage.init();
  });

  testWidgets(
    'Apple-only profile offers Google and requires association consent',
    (tester) async {
      final operations = _FakeAccountUiOperations();
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          ProfileScreen(
            account: const AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: true,
              ),
            ),
            accountOperations: operations,
          ),
        ),
      );
      await tester.pump();
      await _revealProfile(tester, find.text('Mit Google sichern'));
      await tester.tap(find.text('Mit Google sichern'));
      await tester.pumpAndSettle();
      expect(find.text('Weitere Anmeldemethode verbinden'), findsOneWidget);
      expect(operations.linkCalls, isEmpty);
      await tester.tap(find.text('Sicher verbinden'));
      await tester.pump();
      expect(operations.linkCalls, [AccountLinkProvider.google]);
      expect(operations.switchCalls, 0);
    },
  );

  test('Gye actions are disabled for every non-ready account session', () {
    expect(gyeActionsAvailable(null), isFalse);
    expect(
      gyeActionsAvailable(
        const CloudWriteSession(
          uid: 'source',
          epoch: 1,
          mode: CloudWriteMode.ready,
        ),
      ),
      isTrue,
    );
    for (final mode in CloudWriteMode.values.where(
      (mode) => mode != CloudWriteMode.ready,
    )) {
      expect(
        gyeActionsAvailable(
          CloudWriteSession(uid: 'source', epoch: 1, mode: mode),
        ),
        isFalse,
        reason: mode.name,
      );
    }
  });

  testWidgets('durable provider collision never starts account replacement', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..linkResult = const AccountUiProviderCollision();
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => runConfirmedAccountLink(
              context,
              operations: operations,
              provider: AccountLinkProvider.google,
              additionalProvider: true,
            ),
            child: const Text('connect'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bereits mit einem anderen Konto verbunden'),
      findsOneWidget,
    );
    expect(operations.switchCalls, 0);
  });

  testWidgets('profile starts no account work before explicit confirmation', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    await _revealProfile(tester, find.text('Mit Google sichern'));
    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(operations.linkCalls, isEmpty);
    expect(find.text('Konto sicher verbinden?'), findsOneWidget);

    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();

    expect(operations.linkCalls, <AccountLinkProvider>[
      AccountLinkProvider.google,
    ]);
  });

  testWidgets(
    'a link conflict shows the switch dialog and does nothing until confirmed',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..linkResult = const AccountUiLinkConflict(
          ExistingAccountLinkConflict(AccountLinkProvider.google),
        );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => runConfirmedAccountLink(
                context,
                operations: operations,
                provider: AccountLinkProvider.google,
              ),
              child: const Text('connect'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('connect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sicher verbinden'));
      await tester.pumpAndSettle();

      expect(find.text('Mit bestehendem Konto fortfahren?'), findsOneWidget);
      expect(operations.switchCalls, 0);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(operations.switchCalls, 0);
    },
  );

  testWidgets(
    'confirming the switch dialog calls switchToExisting once and completes',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..linkResult = const AccountUiLinkConflict(
          ExistingAccountLinkConflict(AccountLinkProvider.google),
        )
        ..switchResult = const AccountSwitchResult(
          AccountSwitchStatus.completed,
          targetUid: 'durable-target',
        );
      var completedCalls = 0;
      final sessions = CloudWriteSessionController()..acquire('durable-target');
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable-target',
          journalStore: _ClearCloudBackupDeletionJournalStore(),
          gateway: _UnusedCloudBackupDeletionGateway(),
        ),
      );
      CloudSync.overrideOperationsForTesting(
        backupWithResult: () async => CloudWriteResult.completed,
      );
      addTearDown(() {
        CloudSync.resetOperationsForTesting();
        AuthService.resetCloudBackupDeletionForTesting();
      });

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => runConfirmedAccountLink(
                context,
                operations: operations,
                provider: AccountLinkProvider.google,
                onCompleted: () async {
                  completedCalls += 1;
                },
              ),
              child: const Text('connect'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('connect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sicher verbinden'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konto wechseln'));
      for (var i = 0; i < 8; i += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(operations.switchCalls, 1);
      expect(completedCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a deferred merge shows the merge-pending dialog and still completes',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..linkResult = const AccountUiLinkConflict(
          ExistingAccountLinkConflict(AccountLinkProvider.google),
        )
        ..switchResult = const AccountSwitchResult(
          AccountSwitchStatus.mergeDeferred,
          targetUid: 'durable-target',
        );
      var completedCalls = 0;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => runConfirmedAccountLink(
                context,
                operations: operations,
                provider: AccountLinkProvider.google,
                onCompleted: () async {
                  completedCalls += 1;
                },
              ),
              child: const Text('connect'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('connect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sicher verbinden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konto wechseln'));
      await tester.pumpAndSettle();

      expect(operations.switchCalls, 1);
      final l10n = AppL10n.of(tester.element(find.text('Schließen')));
      expect(find.text(l10n.accountSwitchDeferredTitle), findsOneWidget);

      await tester.tap(find.text('Schließen'));
      await tester.pump();

      expect(completedCalls, 1);
    },
  );

  testWidgets('a failed switch shows the safe-failure dialog with retry', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..linkResult = const AccountUiLinkConflict(
        ExistingAccountLinkConflict(AccountLinkProvider.google),
      )
      ..switchResult = const AccountSwitchResult(AccountSwitchStatus.failed);

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => runConfirmedAccountLink(
              context,
              operations: operations,
              provider: AccountLinkProvider.google,
            ),
            child: const Text('connect'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konto wechseln'));
    await tester.pumpAndSettle();

    expect(operations.switchCalls, 1);
    expect(find.text('Verbindung nicht abgeschlossen'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);

    // Retry restarts the whole confirmed-link flow from its safe-connect
    // confirmation, not just the switch step.
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konto wechseln'));
    await tester.pumpAndSettle();

    expect(operations.switchCalls, 2);
  });

  testWidgets(
    'raw Firebase errors and proof material never reach the UI',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..linkFailure = FirebaseAuthException(
          code: 'internal-error',
          message: 'proof-secret-123 private server detail',
        );
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
      );
      await tester.pump();

      await _revealProfile(tester, find.text('Mit Google sichern'));
      await tester.tap(find.text('Mit Google sichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Sicher verbinden'));
      await tester.pump();

      await _revealProfile(tester, find.text('Verbindung nicht abgeschlossen'));
      expect(find.textContaining('proof-secret-123'), findsNothing);
      expect(find.textContaining('private server detail'), findsNothing);
      expect(find.text('Verbindung nicht abgeschlossen'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
    },
  );

  testWidgets('account nudge uses the same confirmed safe operation flow', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations();
    await tester.pumpWidget(_wrap(const SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    final shown = showAccountNudgeSheet(
      context,
      account: _guest,
      accountOperations: operations,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Mit Google verbinden'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(operations.linkCalls, isEmpty);
    expect(find.text('Konto sicher verbinden?'), findsOneWidget);

    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    expect(operations.linkCalls, <AccountLinkProvider>[
      AccountLinkProvider.google,
    ]);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shown;
  });

  testWidgets('account nudge disables new link while a durable journal blocks it', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..pending.value = AccountUiPendingState.blocked;
    await tester.pumpWidget(_wrap(const SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    final shown = showAccountNudgeSheet(
      context,
      account: _guest,
      accountOperations: operations,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final connect = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Mit Google verbinden'),
    );
    expect(connect.onTap, isNull);
    expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
    expect(find.text('Status aktualisieren'), findsOneWidget);
    expect(operations.linkCalls, isEmpty);

    Navigator.of(context).pop();
    await tester.pump(const Duration(milliseconds: 300));
    await shown;
  });

  testWidgets(
    'pending local-cleanup deletion retries through its exact callback',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..pending.value = AccountUiPendingState.deletionLocalCleanup;
      var retryCalls = 0;

      await tester.pumpWidget(
        _wrap(
          AccountPendingOperationPanel(
            operations: operations,
            retryLocalDeletion: () async {
              retryCalls += 1;
              operations.pending.value = AccountUiPendingState.none;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();

      expect(retryCalls, 1);
      expect(find.text('Erneut versuchen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocked panel resumes a pending cloud deletion journal',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..pending.value = AccountUiPendingState.blocked;
      final cloudState = ValueNotifier<CloudBackupDeletionJournalState>(
        CloudBackupDeletionJournalState.pending,
      );
      addTearDown(cloudState.dispose);
      var resumeCalls = 0;

      await tester.pumpWidget(
        _wrap(
          AccountPendingOperationPanel(
            operations: operations,
            cloudDeletionState: cloudState,
            resumeCloudDeletion: () async {
              resumeCalls += 1;
              cloudState.value = CloudBackupDeletionJournalState.clear;
              operations.pending.value = AccountUiPendingState.none;
            },
          ),
        ),
      );
      await tester.pump();

      // The blocked card names the resumable journal and offers its resume —
      // the old text-only dead end is gone.
      expect(find.text('Cloud-Löschung wird fortgesetzt'), findsOneWidget);
      await tester.tap(find.text('Jetzt fortsetzen'));
      await tester.pump();

      expect(resumeCalls, 1);
      expect(find.text('Jetzt fortsetzen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blocked panel without a cloud journal offers a status refresh',
    (tester) async {
      final operations = _FakeAccountUiOperations()
        ..pending.value = AccountUiPendingState.blocked;

      await tester.pumpWidget(
        _wrap(AccountPendingOperationPanel(operations: operations)),
      );
      await tester.pump();

      expect(find.text('Dein Konto ist geschützt'), findsOneWidget);
      await tester.tap(find.text('Status aktualisieren'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('successful link fires one best-effort root backup', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations();
    var backupCalls = 0;
    // A fresh coordinator gives this test its own serial admission lane —
    // the shared static lane may hold futures stranded by earlier tests'
    // abandoned fake-async zones (same pattern as the settings tests).
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
      backupWithResult: () async {
        backupCalls += 1;
        return CloudWriteResult.completed;
      },
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    await _revealProfile(tester, find.text('Mit Google sichern'));
    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sicher verbinden'));
    // The backup is fire-and-forget behind the cloud-deletion admission lane;
    // pump a few frames so its microtask chain completes.
    for (var i = 0; i < 8; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(operations.linkCalls, <AccountLinkProvider>[
      AccountLinkProvider.google,
    ]);
    expect(backupCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing auto backup never fails the completed link', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations();
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
      backupWithResult: () async => throw StateError('backup offline'),
    );
    addTearDown(() {
      CloudSync.resetOperationsForTesting();
      AuthService.resetCloudBackupDeletionForTesting();
    });
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    await _revealProfile(tester, find.text('Mit Google sichern'));
    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sicher verbinden'));
    for (var i = 0; i < 8; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(operations.linkCalls, <AccountLinkProvider>[
      AccountLinkProvider.google,
    ]);
    // No failure dialog — the link completed; the backup failure is logged.
    expect(find.text('Verbindung nicht abgeschlossen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mounting the pending panel next to a guard never notifies during build',
    (tester) async {
      // The real operations synchronously clear the *shared static* notifier to
      // `loading` at the top of refreshPendingState(). The fake never did, so it
      // could not reproduce the Settings-screen crash. Use production here.
      const operations = ProductionAccountUiOperations(
        pendingStateReader: _readsNone,
      );
      final children = <Widget>[
        AccountNewLinkGuard(
          operations: operations,
          builder: (_, __) => const SizedBox(height: 40),
        ),
      ];
      late StateSetter rebuild;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ListView(children: List<Widget>.of(children));
            },
          ),
        ),
      );
      // Let the guard's initial refresh drive the shared notifier to `none`.
      await tester.pumpAndSettle();

      // Adding the panel makes a lazy SliverList create it during layout. Its
      // initState flips the shared notifier none -> loading; before the fix that
      // fired notifyListeners() while the sibling guard was mid-build, throwing
      // "setState() called during build".
      children.add(const AccountPendingOperationPanel(operations: operations));
      rebuild(() {});
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    },
  );
}

Future<AccountUiPendingState> _readsNone() async => AccountUiPendingState.none;

const _guest = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);

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

class _UnusedCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeAccountUiOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  final List<AccountLinkProvider> linkCalls = <AccountLinkProvider>[];
  AccountUiLinkResult linkResult = const AccountUiLinkCompleted();
  Object? linkFailure;
  AccountSwitchResult switchResult = const AccountSwitchResult(
    AccountSwitchStatus.completed,
  );
  int switchCalls = 0;
  final ValueNotifier<AccountUiPendingState> pending =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.none);

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    linkCalls.add(provider);
    if (linkFailure case final failure?) throw failure;
    return linkResult;
  }

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async {
    switchCalls += 1;
    return switchResult;
  }
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

Future<void> _revealProfile(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}
