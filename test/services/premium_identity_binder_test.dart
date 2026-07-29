import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

void main() {
  test(
    'late RevenueCat completion cannot advance stale binding state',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('uid-a');
      final client = _RevenueCatClient();
      final login = Completer<void>();
      client.nextLogin = login.future;
      final binder = PremiumIdentityBinder(client, sessions: sessions);

      final result = binder.bind('uid-a');
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      login.complete();

      expect(await result, CloudWriteResult.stale);
      expect(binder.boundUid, isNull);
      expect(client.events, <String>['login:uid-a']);
    },
  );

  test('quiesced sessions do not call RevenueCat', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    sessions.transition(CloudWriteMode.quiesced);
    final client = _RevenueCatClient();
    final binder = PremiumIdentityBinder(client, sessions: sessions);

    expect(await binder.bind('uid-a'), CloudWriteResult.blocked);
    expect(client.events, isEmpty);
  });

  test('stream binding resumes the paused UID when the session becomes ready', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    sessions.transition(CloudWriteMode.quiesced);
    final identities = StreamController<String?>();
    final client = _RevenueCatClient();
    final binder = PremiumIdentityBinder(client, sessions: sessions);
    binder.start(identities.stream);

    identities.add('uid-a');
    await Future<void>.delayed(Duration.zero);
    expect(client.events, isEmpty);
    sessions.transition(CloudWriteMode.ready);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(client.events, <String>['login:uid-a']);
    await binder.dispose();
    await identities.close();
  });

  test('same UID is blocked while its session is non-ready', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final client = _RevenueCatClient();
    final binder = PremiumIdentityBinder(client, sessions: sessions);
    expect(await binder.bind('uid-a'), CloudWriteResult.completed);
    sessions.transition(CloudWriteMode.quiesced);

    expect(await binder.bind('uid-a'), CloudWriteResult.blocked);
  });

  test('cross-UID binding logs out before login instead of aliasing', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final client = _RevenueCatClient();
    final binder = PremiumIdentityBinder(client, sessions: sessions);
    expect(await binder.bind('uid-a'), CloudWriteResult.completed);
    sessions.acquire('uid-b');

    expect(await binder.bind('uid-b'), CloudWriteResult.completed);
    expect(client.events, <String>['login:uid-a', 'logout', 'login:uid-b']);
    expect(binder.boundUid, 'uid-b');
  });
}

class _RevenueCatClient implements RevenueCatIdentityClient {
  final List<String> events = <String>[];
  Future<void>? nextLogin;

  @override
  Future<void> logIn(String uid) async {
    events.add('login:$uid');
    final result = nextLogin;
    nextLogin = null;
    if (result != null) {
      await result;
    }
  }

  @override
  Future<void> logOut() async => events.add('logout');
}
