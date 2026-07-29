import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  group('CloudWriteSessionController', () {
    test('acquires a ready session for a uid', () {
      final controller = CloudWriteSessionController();

      final session = const CloudWriteSession(
        uid: 'uid-a',
        epoch: 1,
        mode: CloudWriteMode.ready,
      );

      controller.resume(session, expectedUid: 'uid-a');

      expect(session.uid, 'uid-a');
      expect(session.epoch, 1);
      expect(session.mode, CloudWriteMode.ready);
    });

    test('rejects a session asserted for a different uid', () {
      final controller = CloudWriteSessionController();
      final session = controller.acquire('uid-a');

      expect(
        () => controller.assertCurrent(
          CloudWriteSession(
            uid: 'uid-b',
            epoch: session.epoch,
            mode: CloudWriteMode.ready,
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects a stale session epoch', () {
      final controller = CloudWriteSessionController();
      final first = controller.acquire('uid-a');
      final second = controller.acquire('uid-a');

      expect(second.epoch, 2);
      expect(() => controller.assertCurrent(first), throwsStateError);
    });

    test('invalidates the prior session when the write mode transitions', () {
      final controller = CloudWriteSessionController();
      final ready = controller.acquire('uid-a');

      final quiesced = controller.transition(CloudWriteMode.quiesced);

      expect(quiesced.epoch, 2);
      expect(quiesced.mode, CloudWriteMode.quiesced);
      expect(() => controller.assertCurrent(ready), throwsStateError);
      controller.assertCurrent(quiesced);
    });

    test('rejects a session with a mode different from the current mode', () {
      final controller = CloudWriteSessionController();
      final ready = controller.acquire('uid-a');

      expect(
        () => controller.assertCurrent(
          CloudWriteSession(
            uid: ready.uid,
            epoch: ready.epoch,
            mode: CloudWriteMode.blocked,
          ),
        ),
        throwsStateError,
      );
    });

    test(
      'rejects a durable session for another authenticated account after restart',
      () {
        final restartedController = CloudWriteSessionController();
        final durableSession = const CloudWriteSession(
          uid: 'uid-a',
          epoch: 7,
          mode: CloudWriteMode.reconciling,
        );

        expect(
          () =>
              restartedController.resume(durableSession, expectedUid: 'uid-b'),
          throwsStateError,
        );
        expect(restartedController.current, isNull);
      },
    );
  });
}
