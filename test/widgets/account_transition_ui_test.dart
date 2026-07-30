import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_profile': true});
    await Storage.init();
  });

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

  testWidgets('profile surfaces persisted replacement before a new link', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..pending.value = AccountUiPendingState.replacementResumable;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    expect(find.text('Kontowechsel fortsetzen'), findsOneWidget);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();

    expect(operations.resumeCalls, 1);
    expect(operations.linkCalls, isEmpty);
  });

  testWidgets('collision is confirmed through coordinator and can be resumed', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..linkResult = const AccountUiLinkConflict(
        ExistingAccountLinkConflict(AccountLinkProvider.google),
      )
      ..replacementResult = const AccountTransitionResult(
        AccountTransitionStatus.reconciliationPending,
      );
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    await tester.pump();

    expect(operations.confirmCalls, 1);
    expect(find.text('Kontowechsel fortsetzen'), findsOneWidget);

    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();

    expect(operations.resumeCalls, 1);
  });

  testWidgets('failed cancellation becomes a recoverable safe state', (
    tester,
  ) async {
    final operations = _FakeAccountUiOperations()
      ..linkResult = const AccountUiLinkConflict(
        ExistingAccountLinkConflict(AccountLinkProvider.google),
      )
      ..replacementResult = const AccountTransitionResult(
        AccountTransitionStatus.reconciliationPending,
      )
      ..cancelResult = false;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _wrap(ProfileScreen(account: _guest, accountOperations: operations)),
    );
    await tester.pump();

    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Wechsel abbrechen'));
    await tester.pump();

    expect(operations.cancelCalls, 1);
    expect(find.text('Verbindung nicht abgeschlossen'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('raw Firebase errors and proof material never reach the UI', (
    tester,
  ) async {
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

    await tester.tap(find.text('Mit Google sichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sicher verbinden'));
    await tester.pump();

    expect(find.textContaining('proof-secret-123'), findsNothing);
    expect(find.textContaining('private server detail'), findsNothing);
    expect(find.text('Verbindung nicht abgeschlossen'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

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
}

const _guest = AuthAccountSnapshot(
  providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
);

class _FakeAccountUiOperations
    implements AccountUiOperations, AccountUiPendingStateSource {
  final List<AccountLinkProvider> linkCalls = <AccountLinkProvider>[];
  AccountUiLinkResult linkResult = const AccountUiLinkCompleted();
  Object? linkFailure;
  AccountTransitionResult replacementResult = const AccountTransitionResult(
    AccountTransitionStatus.completed,
  );
  int confirmCalls = 0;
  int resumeCalls = 0;
  int cancelCalls = 0;
  bool cancelResult = true;
  final ValueNotifier<AccountUiPendingState> pending =
      ValueNotifier<AccountUiPendingState>(AccountUiPendingState.none);

  @override
  ValueListenable<AccountUiPendingState> get pendingState => pending;

  @override
  Future<AccountUiPendingState> refreshPendingState() async => pending.value;

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<bool> cancelReplacement() async {
    cancelCalls += 1;
    return cancelResult;
  }

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async {
    confirmCalls += 1;
    return replacementResult;
  }

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async {
    linkCalls.add(provider);
    if (linkFailure case final failure?) throw failure;
    return linkResult;
  }

  @override
  Future<AccountTransitionResult> resumeReplacement() async {
    resumeCalls += 1;
    return replacementResult;
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
