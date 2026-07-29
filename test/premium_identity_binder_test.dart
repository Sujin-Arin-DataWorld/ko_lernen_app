import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

void main() {
  test(
    'retries the same UID after a transient RevenueCat login failure',
    () async {
      final identities = StreamController<String?>();
      final revenueCat = _FakeRevenueCatIdentityClient()
        ..loginFailures.add(StateError('transient'));
      final binder = PremiumIdentityBinder(revenueCat);
      final errors = <Object>[];
      binder.start(identities.stream, onError: errors.add);

      identities.add('uid-1');
      await Future<void>.delayed(Duration.zero);
      identities.add('uid-1');
      await Future<void>.delayed(Duration.zero);

      expect(revenueCat.loginAttempts, <String>['uid-1', 'uid-1']);
      expect(binder.boundUid, 'uid-1');
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
