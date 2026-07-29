import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
  });

  test(
    'ownership transition removes old UID before rebinding new UID',
    () async {
      final events = <String>[];
      final push = _FakePushTokenOwner(events);
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => true,
      );

      await coordinator.run(
        oldUid: 'old-uid',
        transition: () async {
          events.add('auth-transition');
        },
      );

      expect(events, <String>[
        'remove:old-uid',
        'auth-transition',
        'bind-current',
      ]);
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
        showNotification: ({required title, required body}) async {},
      );
      final coordinator = PushOwnershipTransitionCoordinator(
        push: service,
        notificationsEnabled: () => true,
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
}

class _FakePushMessaging implements PushMessagingClient {
  PushPermissionStatus permissionStatus = PushPermissionStatus.authorized;
  Future<PushPermissionStatus>? permissionResult;
  String? token;
  final List<Object> getTokenFailures = <Object>[];
  final List<String> events = <String>[];
  final List<bool> autoInitValues = <bool>[];
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

  @override
  Future<void> addToken(String uid, String token) async {
    additions.add('$uid:$token');
  }

  @override
  Future<void> removeToken(String uid, String token) async {
    removals.add('$uid:$token');
  }
}

class _FakePushTokenOwner implements PushTokenOwner {
  _FakePushTokenOwner(this.events);

  final List<String> events;

  @override
  Future<void> bindCurrentUser() async {
    events.add('bind-current');
  }

  @override
  Future<void> removeTokenFrom(String uid) async {
    events.add('remove:$uid');
  }
}
