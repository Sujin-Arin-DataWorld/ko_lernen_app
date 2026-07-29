import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/push_service.dart';

void main() {
  group('PushService', () {
    test(
      'retries after a failed initialization and then becomes idempotent',
      () async {
        final messaging = _FakePushMessaging()
          ..getTokenFailures.add(StateError('transient'))
          ..token = 'token-1';
        final tokens = _FakePushTokenRepository();
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth('uid-1'),
          tokens: tokens,
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {},
        );

        expect(await service.enable(), isFalse);
        expect(service.isReady, isFalse);
        expect(await service.enable(), isTrue);
        expect(await service.enable(), isTrue);

        expect(messaging.permissionRequests, 2);
        expect(messaging.getTokenCalls, 2);
        expect(tokens.additions, <String>['uid-1:token-1']);
      },
    );

    test(
      'does not enable FCM auto-init before notification permission',
      () async {
        final messaging = _FakePushMessaging()
          ..permissionStatus = PushPermissionStatus.denied;
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth('uid-1'),
          tokens: _FakePushTokenRepository(),
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {},
        );

        expect(await service.enable(), isFalse);

        expect(messaging.events, <String>['permission', 'auto-init:false']);
        expect(messaging.getTokenCalls, 0);
      },
    );

    test(
      'disable removes and deletes the token and cancels subscriptions',
      () async {
        final messaging = _FakePushMessaging()..token = 'token-1';
        final tokens = _FakePushTokenRepository();
        final shown = <String>[];
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth('uid-1'),
          tokens: tokens,
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {
            shown.add('$title:$body');
          },
        );
        await service.enable();

        await service.disable();
        messaging.tokenRefreshController.add('token-2');
        messaging.messageController.add(
          const PushNotification(title: 'Title', body: 'Body'),
        );
        await Future<void>.delayed(Duration.zero);

        expect(tokens.removals, <String>['uid-1:token-1']);
        expect(messaging.deleteTokenCalls, 1);
        expect(messaging.autoInitValues, <bool>[true, false]);
        expect(tokens.additions, <String>['uid-1:token-1']);
        expect(shown, isEmpty);
        expect(service.isReady, isFalse);
      },
    );

    test('a later disable wins over an in-flight enable', () async {
      final permissionGate = Completer<PushPermissionStatus>();
      final messaging = _FakePushMessaging()
        ..permissionResult = permissionGate.future
        ..token = 'token-1';
      final service = PushService(
        messaging: messaging,
        auth: _FakePushAuth('uid-1'),
        tokens: _FakePushTokenRepository(),
        sessions: _readySessions('uid-1'),
        showNotification: ({required title, required body}) async {},
      );

      final enabling = service.enable();
      await Future<void>.delayed(Duration.zero);
      final disabling = service.disable();
      permissionGate.complete(PushPermissionStatus.authorized);

      expect(await enabling, isFalse);
      await disabling;

      expect(messaging.autoInitValues, isNot(contains(true)));
      expect(messaging.autoInitValues.last, isFalse);
      expect(service.isReady, isFalse);
      expect(messaging.tokenRefreshController.hasListener, isFalse);
      expect(messaging.messageController.hasListener, isFalse);
    });

    test(
      'strict disable attempts every cleanup and aggregates failures',
      () async {
        final messaging = _FakePushMessaging()
          ..token = 'token-1'
          ..autoInitFailures.add(StateError('auto-init failed'))
          ..deleteTokenFailures.add(StateError('delete failed'));
        final tokens = _FakePushTokenRepository()
          ..removalFailures.add(StateError('repository failed'));
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth('uid-1'),
          tokens: tokens,
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {},
        );

        await expectLater(
          service.disableStrict(),
          throwsA(
            isA<PushCleanupException>().having(
              (error) => error.causes.length,
              'cause count',
              3,
            ),
          ),
        );

        expect(tokens.removals, <String>['uid-1:token-1']);
        expect(messaging.deleteTokenCalls, 1);
        expect(messaging.autoInitValues, <bool>[false]);
        expect(service.isReady, isFalse);
      },
    );

    test(
      'binding fails without a current UID and never becomes ready',
      () async {
        final messaging = _FakePushMessaging()..token = 'token-1';
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth(null),
          tokens: _FakePushTokenRepository(),
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {},
        );

        await expectLater(
          service.bindCurrentUser(),
          throwsA(isA<StateError>()),
        );

        expect(service.isReady, isFalse);
        expect(messaging.permissionRequests, 0);
      },
    );

    test(
      'binding keeps notification permission denial as a non-error',
      () async {
        final messaging = _FakePushMessaging()
          ..permissionStatus = PushPermissionStatus.denied;
        final service = PushService(
          messaging: messaging,
          auth: _FakePushAuth('uid-1'),
          tokens: _FakePushTokenRepository(),
          sessions: _readySessions('uid-1'),
          showNotification: ({required title, required body}) async {},
        );

        await service.bindCurrentUser();

        expect(service.isReady, isFalse);
        expect(messaging.permissionRequests, 1);
        expect(messaging.getTokenCalls, 0);
      },
    );
  });

  test('plain transition success does not restore source ownership', () async {
    final events = <String>[];
    final push = _FakePushTokenOwner(events);
    final coordinator = PushOwnershipTransitionCoordinator(
      push: push,
      notificationsEnabled: () => true,
      sessions: _readySessions('old-uid'),
    );

    await coordinator.run(
      oldUid: 'old-uid',
      transition: () async {
        events.add('auth-transition');
      },
    );

    expect(events, <String>['remove:old-uid', 'auth-transition']);
  });

  test(
    'transition-only failure preserves the original error and stack',
    () async {
      final events = <String>[];
      final failure = StateError('transition failed');
      late StackTrace originalStackTrace;
      final coordinator = PushOwnershipTransitionCoordinator(
        push: _FakePushTokenOwner(events),
        notificationsEnabled: () => true,
        sessions: _readySessions('old-uid'),
      );

      Object? caughtError;
      StackTrace? caughtStackTrace;
      try {
        await coordinator.run(
          oldUid: 'old-uid',
          transition: () async {
            try {
              throw failure;
            } catch (_, stackTrace) {
              originalStackTrace = stackTrace;
              rethrow;
            }
          },
        );
      } catch (error, stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      }

      expect(caughtError, same(failure));
      expect(caughtStackTrace.toString(), originalStackTrace.toString());
      expect(events, <String>['remove:old-uid']);
    },
  );

  test('explicit rejection preserves transition and rebind failures', () async {
    final events = <String>[];
    final failure = StateError('rebind failed');
    final push = _FakePushTokenOwner(events)..bindFailure = failure;
    final coordinator = PushOwnershipTransitionCoordinator(
      push: push,
      notificationsEnabled: () => true,
      sessions: _readySessions('old-uid'),
    );

    Object? caughtError;
    StackTrace? caughtStackTrace;
    try {
      await coordinator.run(
        oldUid: 'old-uid',
        transition: () async {
          events.add('auth-transition');
          throw const ServerConfirmedPreMarkerRejection('rejected');
        },
      );
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
    }

    expect(caughtError, isA<PushOwnershipTransitionException>());
    final combined = caughtError! as PushOwnershipTransitionException;
    expect(combined.transitionError, isA<ServerConfirmedPreMarkerRejection>());
    expect(combined.rebindError, same(failure));
    expect(
      combined.rebindStackTrace.toString(),
      push.bindFailureStackTrace.toString(),
    );
    expect(caughtStackTrace, isNotNull);
  });

  test(
    'transition failure freezes ownership before a possible rebind',
    () async {
      final events = <String>[];
      final transitionFailure = StateError('transition failed');
      final rebindFailure = StateError('rebind failed');
      final push = _FakePushTokenOwner(events)..bindFailure = rebindFailure;
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => true,
        sessions: _readySessions('old-uid'),
      );

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async => throw transitionFailure,
        ),
        throwsA(same(transitionFailure)),
      );
      expect(events, <String>['remove:old-uid']);
      expect(push.bindFailureStackTrace, isNull);
    },
  );

  test(
    'ownership transition blocks auth when local token invalidation fails',
    () async {
      final messaging = _FakePushMessaging()
        ..token = 'token-1'
        ..deleteTokenFailures.add(StateError('delete failed'));
      final service = PushService(
        messaging: messaging,
        auth: _FakePushAuth('old-uid'),
        tokens: _FakePushTokenRepository(),
        sessions: _readySessions('old-uid'),
        showNotification: ({required title, required body}) async {},
      );
      final coordinator = PushOwnershipTransitionCoordinator(
        push: service,
        notificationsEnabled: () => true,
        sessions: _readySessions('old-uid'),
      );
      var transitioned = false;

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async {
            transitioned = true;
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(transitioned, isFalse);
      expect(messaging.autoInitValues, <bool>[false]);
      expect(messaging.deleteTokenCalls, 1);
    },
  );

  test(
    'stored notification off still blocks auth when invalidation fails',
    () async {
      final events = <String>[];
      final push = _FakePushTokenOwner(events)
        ..removalFailure = StateError('invalidation failed');
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => false,
        sessions: _readySessions('old-uid'),
      );
      var transitioned = false;

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async {
            transitioned = true;
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(transitioned, isFalse);
      expect(events, <String>['remove:old-uid']);
    },
  );

  test(
    'notification off during auth transition suppresses rebinding',
    () async {
      var notificationsEnabled = true;
      final events = <String>[];
      final push = _FakePushTokenOwner(events);
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => notificationsEnabled,
        sessions: _readySessions('old-uid'),
      );

      await coordinator.run(
        oldUid: 'old-uid',
        transition: () async {
          events.add('auth-transition');
          notificationsEnabled = false;
        },
      );

      expect(events, <String>['remove:old-uid', 'auth-transition']);
    },
  );

  test(
    'explicit rejection fails safely when source UID cannot be rebound',
    () async {
      final auth = _FakePushAuth('old-uid');
      final service = PushService(
        messaging: _FakePushMessaging()..token = 'token-1',
        auth: auth,
        tokens: _FakePushTokenRepository(),
        sessions: _readySessions('old-uid'),
        showNotification: ({required title, required body}) async {},
      );
      final coordinator = PushOwnershipTransitionCoordinator(
        push: service,
        notificationsEnabled: () => true,
        sessions: _readySessions('old-uid'),
      );

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async {
            auth.currentUid = null;
            throw const ServerConfirmedPreMarkerRejection('rejected');
          },
        ),
        throwsA(isA<PushOwnershipTransitionException>()),
      );

      expect(service.isReady, isFalse);
    },
  );
}

CloudWriteSessionController _readySessions(String uid) {
  final sessions = CloudWriteSessionController();
  sessions.acquire(uid);
  return sessions;
}

class _FakePushMessaging implements PushMessagingClient {
  PushPermissionStatus permissionStatus = PushPermissionStatus.authorized;
  Future<PushPermissionStatus>? permissionResult;
  String? token;
  final List<Object> getTokenFailures = <Object>[];
  final List<String> events = <String>[];
  final List<bool> autoInitValues = <bool>[];
  final List<Object> autoInitFailures = <Object>[];
  final StreamController<String> tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<PushNotification> messageController =
      StreamController<PushNotification>.broadcast();
  int permissionRequests = 0;
  int getTokenCalls = 0;
  int deleteTokenCalls = 0;
  final List<Object> deleteTokenFailures = <Object>[];

  @override
  bool get isSupported => true;

  @override
  Stream<PushNotification> get messages => messageController.stream;

  @override
  Stream<String> get tokenRefreshes => tokenRefreshController.stream;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls += 1;
    if (deleteTokenFailures.isNotEmpty) {
      throw deleteTokenFailures.removeAt(0);
    }
  }

  @override
  Future<String?> getToken() async {
    getTokenCalls += 1;
    if (getTokenFailures.isNotEmpty) {
      throw getTokenFailures.removeAt(0);
    }
    return token;
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    events.add('permission');
    final result = permissionResult;
    if (result != null) {
      return result;
    }
    return permissionStatus;
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    events.add('auto-init:$enabled');
    autoInitValues.add(enabled);
    if (autoInitFailures.isNotEmpty) {
      throw autoInitFailures.removeAt(0);
    }
  }
}

class _FakePushAuth implements PushAuthClient {
  _FakePushAuth(this.currentUid);

  @override
  String? currentUid;
}

class _FakePushTokenRepository implements PushTokenRepository {
  final List<String> additions = <String>[];
  final List<String> removals = <String>[];
  final List<Object> removalFailures = <Object>[];

  @override
  Future<void> addToken(String uid, String token) async {
    additions.add('$uid:$token');
  }

  @override
  Future<void> removeToken(String uid, String token) async {
    removals.add('$uid:$token');
    if (removalFailures.isNotEmpty) {
      throw removalFailures.removeAt(0);
    }
  }
}

class _FakePushTokenOwner implements PushTokenOwner {
  _FakePushTokenOwner(this.events);

  final List<String> events;
  Object? removalFailure;
  Object? bindFailure;
  StackTrace? bindFailureStackTrace;

  @override
  Future<void> bindCurrentUser() async {
    events.add('bind-current');
    if (bindFailure case final failure?) {
      final stackTrace = StackTrace.current;
      bindFailureStackTrace = stackTrace;
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  @override
  Future<void> removeTokenFrom(String uid) async {
    events.add('remove:$uid');
    if (removalFailure case final failure?) {
      throw failure;
    }
  }
}
