import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/push_service.dart';

void main() {
  test('a stale transition completion cannot rebind push ownership', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('old-uid');
    final push = _PushOwner();
    final coordinator = PushOwnershipTransitionCoordinator(
      push: push,
      notificationsEnabled: () => true,
      sessions: sessions,
    );

    final result = await coordinator.run(
      oldUid: 'old-uid',
      transition: () async {
        sessions.acquire('new-uid');
      },
    );

    expect(result, CloudWriteResult.stale);
    expect(push.events, <String>['remove:old-uid']);
  });

  test(
    'unknown transition failure freezes ownership without rebinding',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('old-uid');
      final push = _PushOwner();
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => true,
        sessions: sessions,
      );

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async => throw StateError('timeout'),
        ),
        throwsStateError,
      );

      expect(push.events, <String>['remove:old-uid']);
      expect(sessions.current?.mode, CloudWriteMode.blocked);
    },
  );

  test('accepted server outcome remains frozen for resume', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('old-uid');
    final push = _PushOwner();
    final coordinator = PushOwnershipTransitionCoordinator(
      push: push,
      notificationsEnabled: () => true,
      sessions: sessions,
    );

    final result = await coordinator.run(
      oldUid: 'old-uid',
      transition: () async => const ServerAcceptedOwnershipFreeze(),
    );

    expect(result, CloudWriteResult.completed);
    expect(push.events, <String>['remove:old-uid']);
    expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
  });

  test('plain successful transition is also accepted and frozen', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('old-uid');
    final push = _PushOwner();
    final coordinator = PushOwnershipTransitionCoordinator(
      push: push,
      notificationsEnabled: () => true,
      sessions: sessions,
    );

    final result = await coordinator.run<void>(
      oldUid: 'old-uid',
      transition: () async {},
    );

    expect(result, CloudWriteResult.completed);
    expect(push.events, <String>['remove:old-uid']);
    expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
  });

  test(
    'successful target sign-in stays quiesced until source cleanup is frozen',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('old-uid');
      final push = _PushOwner();
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => true,
        sessions: sessions,
      );
      final synchronizer = CloudWriteSessionSynchronizer(sessions);
      var transitionWrites = 0;

      final result = await coordinator.run<void>(
        oldUid: 'old-uid',
        transition: () async {
          expect(sessions.current?.uid, 'old-uid');
          expect(sessions.current?.mode, CloudWriteMode.quiesced);
          expect(
            synchronizer.synchronizeReady('target-uid'),
            CloudWriteResult.blocked,
          );
          expect(
            await CloudWriteFence(
              sessions,
            ).run(uid: 'old-uid', action: () async => transitionWrites++),
            CloudWriteResult.blocked,
          );
        },
      );

      expect(result, CloudWriteResult.completed);
      expect(transitionWrites, 0);
      expect(sessions.current?.uid, 'old-uid');
      expect(sessions.current?.mode, CloudWriteMode.cleanupPending);
    },
  );

  test(
    'only explicit pre-marker rejection may restore old ownership',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('old-uid');
      final push = _PushOwner();
      final coordinator = PushOwnershipTransitionCoordinator(
        push: push,
        notificationsEnabled: () => true,
        sessions: sessions,
      );

      await expectLater(
        coordinator.run(
          oldUid: 'old-uid',
          transition: () async {
            throw const ServerConfirmedPreMarkerRejection('rejected');
          },
        ),
        throwsA(isA<ServerConfirmedPreMarkerRejection>()),
      );

      expect(push.events, <String>['remove:old-uid', 'bind-current']);
      expect(sessions.current?.mode, CloudWriteMode.ready);
    },
  );
}

class _PushOwner implements PushTokenOwner {
  final List<String> events = <String>[];

  @override
  Future<void> bindCurrentUser() async => events.add('bind-current');

  @override
  Future<void> removeTokenFrom(String uid) async => events.add('remove:$uid');
}
