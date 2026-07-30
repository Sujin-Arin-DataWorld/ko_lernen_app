import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('settings link entry confirms before safe operation starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final operations = _SettingsAccountOperations();

    await tester.pumpWidget(
      _wrap(SettingsScreen(account: _guest, accountOperations: operations)),
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
      _wrap(SettingsScreen(account: _guest, accountOperations: operations)),
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
