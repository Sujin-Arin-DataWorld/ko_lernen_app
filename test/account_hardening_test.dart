import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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

    test('pre-delete remote failure stops destructive local cleanup', () async {
      final events = <String>[];
      final remoteOperations = _FakeRemoteAccountOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: true,
          isAppleLinked: false,
        )
        ..cloudFailure = StateError('cleanup failed');
      final remoteCoordinator = _remoteCoordinator(remoteOperations, events);
      final adapter = AccountDeletionCleanupAdapter(
        deleteRemote: remoteCoordinator.deleteAccount,
        resetStorage: () async => events.add('local-reset'),
        disablePush: () async => events.add('push-disable'),
        deleteImages: () async => events.add('image-delete'),
        clearTts: () async => events.add('tts-clear'),
        resetMemory: () => events.add('memory-reset'),
      );

      await expectLater(
        AccountDeletionWorkflow(adapter).run(),
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
      'post-delete Google sign-out failure still restores anonymous identity',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: true,
            isAppleLinked: false,
          )
          ..signOutFailure = StateError('Google sign-out failed');
        final coordinator = _remoteCoordinator(operations, events);

        await expectLater(
          coordinator.deleteAccount(),
          throwsA(isA<AccountDeletionRecoveryException>()),
        );

        expect(events, <String>[
          'google-reauth',
          'push-remove:user-1',
          'cloud-delete',
          'firebase-delete',
          'google-sign-out',
          'ensure-anonymous',
          'push-bind',
        ]);
        expect(operations.deleteCalls, 1);
      },
    );

    test(
      'post-delete recovery failure still runs every local privacy cleanup',
      () async {
        final events = <String>[];
        final remoteOperations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: true,
            isAppleLinked: false,
          )
          ..signOutFailure = StateError('Google sign-out failed');
        final remoteCoordinator = _remoteCoordinator(remoteOperations, events);
        final adapter = AccountDeletionCleanupAdapter(
          deleteRemote: remoteCoordinator.deleteAccount,
          resetStorage: () async => events.add('local-reset'),
          disablePush: () async => events.add('push-disable'),
          deleteImages: () async => events.add('image-delete'),
          clearTts: () async => events.add('tts-clear'),
          resetMemory: () => events.add('memory-reset'),
        );

        await expectLater(
          AccountDeletionWorkflow(adapter).run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (error) => error.causes.length,
              'cause count',
              1,
            ),
          ),
        );

        expect(events, <String>[
          'google-reauth',
          'push-remove:user-1',
          'cloud-delete',
          'firebase-delete',
          'google-sign-out',
          'ensure-anonymous',
          'push-bind',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
        expect(remoteOperations.deleteCalls, 1);
      },
    );

    test(
      'anonymous identity creation retries after irreversible deletion',
      () async {
        final events = <String>[];
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = 'apple-code'
          ..anonymousFailures.add(StateError('anonymous failed once'));
        final coordinator = _remoteCoordinator(operations, events);

        await coordinator.deleteAccount();

        expect(events, <String>[
          'apple-reauth',
          'push-remove:user-1',
          'apple-revoke:apple-code',
          'cloud-delete',
          'firebase-delete',
          'ensure-anonymous',
          'ensure-anonymous',
          'push-bind',
        ]);
        expect(operations.deleteCalls, 1);
      },
    );

    test(
      'anonymous recovery and missing-UID rebind failures are all retained',
      () async {
        final events = <String>[];
        final firstAnonymousFailure = StateError('anonymous failed once');
        final secondAnonymousFailure = StateError('anonymous failed twice');
        final pushAuth = _MutableAccountDeletionPushAuth('user-1');
        final operations = _FakeRemoteAccountOperations(events)
          ..providers = const AuthProviderState(
            isGoogleLinked: false,
            isAppleLinked: true,
          )
          ..appleAuthorizationCode = 'apple-code'
          ..anonymousFailures.addAll([
            firstAnonymousFailure,
            secondAnonymousFailure,
          ])
          ..onFirebaseDeleted = () => pushAuth.currentUid = null;
        final push = PushService(
          messaging: _AccountDeletionPushMessaging(),
          auth: pushAuth,
          tokens: _AccountDeletionPushTokenRepository(),
          showNotification: ({required title, required body}) async {},
        );
        final coordinator = AccountDeletionCoordinator(
          operations: operations,
          ownershipTransitions: PushOwnershipTransitionCoordinator(
            push: push,
            notificationsEnabled: () => true,
          ),
        );
        final workflow = AccountDeletionWorkflow(
          AccountDeletionCleanupAdapter(
            deleteRemote: coordinator.deleteAccount,
            resetStorage: () async => events.add('local-reset'),
            disablePush: () async => events.add('push-disable'),
            deleteImages: () async => events.add('image-delete'),
            clearTts: () async => events.add('tts-clear'),
            resetMemory: () => events.add('memory-reset'),
          ),
        );

        await expectLater(
          workflow.run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (failure) =>
                  (failure.causes.single as AccountDeletionRecoveryException)
                      .causes,
              'post-delete recovery causes',
              <Matcher>[
                same(firstAnonymousFailure),
                same(secondAnonymousFailure),
                isA<StateError>().having(
                  (error) => error.toString(),
                  'message',
                  contains('without a user ID'),
                ),
              ],
            ),
          ),
        );

        expect(operations.deleteCalls, 1);
        expect(events.where((event) => event == 'ensure-anonymous').length, 2);
        expect(
          events,
          containsAll(<String>[
            'local-reset',
            'push-disable',
            'image-delete',
            'tts-clear',
            'memory-reset',
          ]),
        );
      },
    );

    test('recent-login retry obtains and revokes a fresh Apple code', () async {
      final events = <String>[];
      final operations = _FakeRemoteAccountOperations(events)
        ..providers = const AuthProviderState(
          isGoogleLinked: false,
          isAppleLinked: true,
        )
        ..appleAuthorizationCodes.addAll(['first-code', 'retry-code'])
        ..deleteFailures.add(
          FirebaseAuthException(code: 'requires-recent-login'),
        );
      final coordinator = _remoteCoordinator(operations, events);

      await coordinator.deleteAccount();

      expect(events, <String>[
        'apple-reauth',
        'push-remove:user-1',
        'apple-revoke:first-code',
        'cloud-delete',
        'firebase-delete',
        'apple-reauth',
        'apple-revoke:retry-code',
        'firebase-delete',
        'ensure-anonymous',
        'push-bind',
      ]);
      expect(operations.deleteCalls, 2);
    });

    test(
      'required local cleanup attempts every independent step before failing',
      () async {
        final events = <String>[];
        final operations = _FakeAccountCleanupOperations(events)
          ..imageCleanupFailure = StateError('image cleanup failed');
        final workflow = AccountDeletionWorkflow(operations);

        await expectLater(
          workflow.run(),
          throwsA(
            isA<AccountDeletionFailure>().having(
              (error) => error.causes.length,
              'cause count',
              1,
            ),
          ),
        );

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
        ]);
      },
    );

    test(
      'production cleanup adapter invokes every injected strict operation',
      () async {
        final events = <String>[];
        final adapter = AccountDeletionCleanupAdapter(
          deleteRemote: () async => events.add('remote-delete'),
          resetStorage: () async => events.add('local-reset'),
          disablePush: () async => events.add('push-disable'),
          deleteImages: () async => events.add('image-delete'),
          clearTts: () async => events.add('tts-clear'),
          resetMemory: () => events.add('memory-reset'),
        );

        await AccountDeletionWorkflow(adapter).run();

        expect(events, <String>[
          'remote-delete',
          'local-reset',
          'push-disable',
          'image-delete',
          'tts-clear',
          'memory-reset',
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

    test('unsupported and web platforms do not receive a store route', () {
      expect(subscriptionManagementUri(TargetPlatform.windows), isNull);
      expect(subscriptionManagementUri(TargetPlatform.linux), isNull);
      expect(subscriptionManagementUri(TargetPlatform.fuchsia), isNull);
      expect(
        subscriptionManagementUri(TargetPlatform.iOS, isWeb: true),
        isNull,
      );
    });

    test('launcher false result is surfaced as a failure', () async {
      final attempted = <Uri>[];
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (uri) async {
          attempted.add(uri);
          return false;
        },
      );

      await expectLater(
        manager.open(),
        throwsA(isA<SubscriptionManagementException>()),
      );

      expect(attempted, <Uri>[
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      ]);
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

    testWidgets('launcher false result shows localized management failure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final manager = SubscriptionManagementLauncher(
        platform: TargetPlatform.android,
        isWeb: false,
        launchExternal: (_) async => false,
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountDeletionWorkflow: AccountDeletionWorkflow(
              _FakeAccountCleanupOperations(<String>[]),
            ),
            subscriptionManager: manager,
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
      await tester.tap(find.text('Store-Abo verwalten'));
      await tester.pump();

      expect(
        find.text('Die Aboverwaltung konnte nicht geöffnet werden.'),
        findsOneWidget,
      );
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
  final List<String?> appleAuthorizationCodes = <String?>[];
  Object? revokeFailure;
  Object? cloudFailure;
  Object? signOutFailure;
  final List<Object> anonymousFailures = <Object>[];
  final List<Object> deleteFailures = <Object>[];
  void Function()? onFirebaseDeleted;
  int deleteCalls = 0;

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
    deleteCalls += 1;
    if (deleteFailures.isNotEmpty) {
      throw deleteFailures.removeAt(0);
    }
    onFirebaseDeleted?.call();
  }

  @override
  Future<void> ensureAnonymousUser() async {
    events.add('ensure-anonymous');
    if (anonymousFailures.isNotEmpty) {
      throw anonymousFailures.removeAt(0);
    }
  }

  @override
  Future<String?> reauthenticateWithApple() async {
    events.add('apple-reauth');
    if (appleAuthorizationCodes.isNotEmpty) {
      return appleAuthorizationCodes.removeAt(0);
    }
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
    if (signOutFailure case final failure?) {
      throw failure;
    }
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

class _MutableAccountDeletionPushAuth implements PushAuthClient {
  _MutableAccountDeletionPushAuth(this.currentUid);

  @override
  String? currentUid;
}

class _AccountDeletionPushTokenRepository implements PushTokenRepository {
  @override
  Future<void> addToken(String uid, String token) async {}

  @override
  Future<void> removeToken(String uid, String token) async {}
}

class _AccountDeletionPushMessaging implements PushMessagingClient {
  @override
  bool get isSupported => true;

  @override
  Stream<PushNotification> get messages => const Stream.empty();

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> getToken() async => 'token-1';

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.authorized;

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}
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
