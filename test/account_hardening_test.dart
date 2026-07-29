import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/push_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/account_nudge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('durable account providers', () {
    test('Apple alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['apple.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isTrue);
      expect(providers.isGoogleLinked, isFalse);
    });

    test('Google alone is a durable linked account', () {
      final providers = AuthProviderState.fromProviderIds(const ['google.com']);

      expect(providers.isDurable, isTrue);
      expect(providers.isAppleLinked, isFalse);
      expect(providers.isGoogleLinked, isTrue);
    });

    testWidgets('profile presents an Apple-only account as connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: false,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mit Apple verbunden'), findsOneWidget);
      expect(find.text('Angemeldet: Apple'), findsOneWidget);
      expect(find.text('Mit Google sichern'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('profile presents both linked providers deterministically', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileScreen(
            account: AuthAccountSnapshot(
              providers: AuthProviderState(
                isGoogleLinked: true,
                isAppleLinked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Mit Google und Apple verbunden'), findsOneWidget);
      expect(find.text('Angemeldet: Google und Apple'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('account nudge is suppressed for an Apple-only account', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      await showAccountNudgeSheet(
        context,
        account: const AuthAccountSnapshot(
          providers: AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Speichere deinen Fortschritt'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets(
      'settings uses the Apple provider label for Apple-only account',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            const SettingsScreen(
              account: AuthAccountSnapshot(
                providers: AuthProviderState(
                  isGoogleLinked: false,
                  isAppleLinked: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Angemeldet: Apple'), findsOneWidget);
        expect(find.text('Mit Google sichern'), findsNothing);
      },
    );
  });

  group('account deletion', () {
    test(
      'Apple authorization is revoked before cloud and Firebase deletion',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = 'apple-code';
        final coordinator = _remoteCoordinator(operations, events);

        await coordinator.deleteAccount();

        expect(events, <String>[
          'apple-reauth',
          'push-remove:user-1',
          'apple-revoke:apple-code',
          'cloud-delete',
          'firebase-delete',
          'google-sign-out',
          'ensure-anonymous',
          'push-bind',
        ]);
      },
    );

    test(
      'missing Apple authorization code fails before user deletion',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = null;
        final coordinator = _remoteCoordinator(operations, events);

        await expectLater(
          coordinator.deleteAccount(),
          throwsA(isA<StateError>()),
        );

        expect(events, <String>['apple-reauth']);
      },
    );

    test(
      'dual-linked account uses Apple authorization for revocation',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: true,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = 'dual-apple-code';
        final coordinator = _remoteCoordinator(operations, events);

        await coordinator.deleteAccount();

        expect(events, <String>[
          'apple-reauth',
          'push-remove:user-1',
          'apple-revoke:dual-apple-code',
          'cloud-delete',
          'firebase-delete',
          'google-sign-out',
          'ensure-anonymous',
          'push-bind',
        ]);
      },
    );

    test(
      'Apple revocation failure prevents cloud and Firebase deletion',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = 'apple-code'
          ..revokeFailure = StateError('revocation failed');
        final coordinator = _remoteCoordinator(operations, events);

        await expectLater(
          coordinator.deleteAccount(),
          throwsA(isA<StateError>()),
        );

        expect(events, <String>[
          'apple-reauth',
          'push-remove:user-1',
          'apple-revoke:apple-code',
          'push-bind',
        ]);
      },
    );

    test('cloud cleanup failure prevents Firebase user deletion', () async {
      final events = <String>[];
      final operations = _FakeRemoteAccountOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..cloudFailure = StateError('cleanup failed');
      final coordinator = _remoteCoordinator(operations, events);

      await expectLater(
        coordinator.deleteAccount(),
        throwsA(isA<StateError>()),
      );

      expect(events, <String>[
        'google-reauth',
        'push-remove:user-1',
        'cloud-delete',
        'push-bind',
      ]);
    });

    test(
      'required local cleanup failure stops the deletion workflow',
      () async {
        final events = <String>[];
        final operations = _FakeAccountCleanupOperations(events)
          ..imageCleanupFailure = StateError('image cleanup failed');
        final workflow = AccountDeletionWorkflow(operations);

        await expectLater(workflow.run(), throwsA(isA<StateError>()));

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
        ]);
      },
    );
  });

  group('subscription management', () {
    test('uses the App Store subscriptions route on Apple platforms', () {
      expect(
        subscriptionManagementUri(TargetPlatform.iOS),
        Uri.parse('https://apps.apple.com/account/subscriptions'),
      );
    });

    test('uses the Play Store subscriptions route on Android', () {
      expect(
        subscriptionManagementUri(TargetPlatform.android),
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      );
    });

    testWidgets(
      'account deletion warns about subscriptions and exposes management',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final workflow = AccountDeletionWorkflow(
          _FakeAccountCleanupOperations(<String>[]),
        );

        await tester.pumpWidget(
          _wrap(SettingsScreen(accountDeletionWorkflow: workflow)),
        );
        await tester.pump();

        final deleteTile = find.text('Konto und alle Daten löschen');
        await tester.scrollUntilVisible(
          deleteTile,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(deleteTile);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Ein App-Store- oder Play-Store-Abo wird dadurch nicht gekündigt.',
          ),
          findsOneWidget,
        );
        expect(find.text('Store-Abo verwalten'), findsOneWidget);
      },
    );

    testWidgets('local cleanup failure never shows account deletion success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final operations = _FakeAccountCleanupOperations(<String>[])
        ..imageCleanupFailure = StateError('image cleanup failed');

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(operations),
          ),
        ),
      );
      await tester.pump();

      final deleteTile = find.text('Konto und alle Daten löschen');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen').last);
      await tester.pump();

      expect(find.textContaining('Löschung fehlgeschlagen:'), findsOneWidget);
      expect(find.text('Konto und Daten gelöscht'), findsNothing);
    });
  });
}

AccountDeletionCoordinator _remoteCoordinator(
  _FakeRemoteAccountOperations operations,
  List<String> events,
) {
  return AccountDeletionCoordinator(
    operations: operations,
    ownershipTransitions: PushOwnershipTransitionCoordinator(
      push: _FakePushTokenOwner(events),
      notificationsEnabled: () => true,
    ),
  );
}

class _FakeRemoteAccountOperations implements AccountDeletionOperations {
  _FakeRemoteAccountOperations(this.events);

  final List<String> events;
  AuthProviderState providers = const AuthProviderState(
    isGoogleLinked: false,
    isAppleLinked: false,
  );
  String? appleAuthorizationCode;
  Object? revokeFailure;
  Object? cloudFailure;

  @override
  String get userId => 'user-1';

  @override
  AuthProviderState get providerState => providers;

  @override
  Future<void> deleteCloudData() async {
    events.add('cloud-delete');
    if (cloudFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> deleteFirebaseUser() async {
    events.add('firebase-delete');
  }

  @override
  Future<void> ensureAnonymousUser() async {
    events.add('ensure-anonymous');
  }

  @override
  Future<String?> reauthenticateWithApple() async {
    events.add('apple-reauth');
    return appleAuthorizationCode;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    events.add('google-reauth');
  }

  @override
  Future<void> revokeAppleAuthorizationCode(String authorizationCode) async {
    events.add('apple-revoke:$authorizationCode');
    if (revokeFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> signOutGoogle() async {
    events.add('google-sign-out');
  }
}

class _FakePushTokenOwner implements PushTokenOwner {
  _FakePushTokenOwner(this.events);

  final List<String> events;

  @override
  Future<void> bindCurrentUser() async {
    events.add('push-bind');
  }

  @override
  Future<void> removeTokenFrom(String uid) async {
    events.add('push-remove:$uid');
  }
}

class _FakeAccountCleanupOperations
    implements AccountDeletionCleanupOperations {
  _FakeAccountCleanupOperations(this.events);

  final List<String> events;
  Object? imageCleanupFailure;

  @override
  Future<void> clearTtsCache() async {
    events.add('tts-clear');
  }

  @override
  Future<void> deleteLocalImages() async {
    events.add('image-delete');
    if (imageCleanupFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<void> deleteRemoteAccount() async {
    events.add('remote-delete');
  }

  @override
  Future<void> disablePush() async {
    events.add('push-disable');
  }

  @override
  void resetInMemoryData() {
    events.add('memory-reset');
  }

  @override
  Future<void> resetLocalStorage() async {
    events.add('local-reset');
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
