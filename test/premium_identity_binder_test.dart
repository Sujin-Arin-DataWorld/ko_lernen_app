import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

void main() {
  test(
    'retries the same UID after a transient RevenueCat login failure',
    () async {
      final identities = StreamController<String?>();
      final revenueCat = _FakeRevenueCatIdentityClient()
        ..loginFailures.add(StateError('transient'));
      final sessions = CloudWriteSessionController()..acquire('uid-1');
      final binder = PremiumIdentityBinder(
        revenueCat,
        sessions: sessions,
        initialUid: 'uid-1',
      );
      final errors = <Object>[];
      binder.start(identities.stream, onError: errors.add);
      sessions.acquire('uid-2');

      identities.add('uid-2');
      await Future<void>.delayed(Duration.zero);
      identities.add('uid-2');
      await Future<void>.delayed(Duration.zero);

      expect(revenueCat.loginAttempts, <String>['uid-2', 'uid-2']);
      expect(binder.boundUid, 'uid-2');
      expect(errors, hasLength(1));
      await binder.dispose();
      await identities.close();
    },
  );
}

class _FakeRevenueCatIdentityClient implements RevenueCatIdentityClient {
  final List<String> loginAttempts = <String>[];
  final List<Object> loginFailures = <Object>[];

  @override
  Future<void> logIn(String uid) async {
    loginAttempts.add(uid);
    if (loginFailures.isNotEmpty) {
      throw loginFailures.removeAt(0);
    }
  }

  @override
  Future<void> logOut() async {}
}
