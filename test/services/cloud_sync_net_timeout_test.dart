import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/net/sori_net.dart';

// S2 behavior test: a write whose Firestore call hangs must not retry (the
// write may still be queued locally and would double-write if retried) — it
// must resolve to the existing CloudWriteResult.blocked/stale within the
// configured limit. This exercises `CloudSync.backupWithSession`'s new
// `on SoriNetTimeout` handling directly, with the same `withNetTimeout`
// wrapping production code uses around `ref!.set(...)` — the concrete
// production call site is exercised via dependency injection here because
// `backupWithSession` is the `@visibleForTesting` seam production's
// `_backupWithResultAfterCloudBackupAdmission` funnels through.
void main() {
  test(
    'a hung backup write resolves to blocked within the net timeout limit',
    () {
      fakeAsync((async) {
        final sessions = CloudWriteSessionController()..acquire('uid-a');
        CloudWriteResult? result;

        unawaited(
          CloudSync.backupWithSession(
            sessions: sessions,
            uid: 'uid-a',
            prepare: () async {},
            write: () => withNetTimeout(
              Completer<void>().future, // never completes — simulates a
              // hung Firestore ref.set() the way production wraps it.
              scope: 'cloud_sync.backup_write',
              limit: const Duration(seconds: 8),
            ),
          ).then((value) {
            result = value;
          }),
        );

        // Well within the limit: still pending.
        async.elapse(const Duration(seconds: 7));
        expect(result, isNull);

        // Past the limit: the timeout has fired and been mapped to the
        // existing typed failure, not left as an uncaught exception.
        async.elapse(const Duration(seconds: 2));
        expect(result, CloudWriteResult.blocked);
      });
    },
  );

  test(
    'a write that completes just under the limit still reports completed',
    () {
      fakeAsync((async) {
        final sessions = CloudWriteSessionController()..acquire('uid-a');
        final completer = Completer<void>();
        CloudWriteResult? result;

        unawaited(
          CloudSync.backupWithSession(
            sessions: sessions,
            uid: 'uid-a',
            prepare: () async {},
            write: () => withNetTimeout(
              completer.future,
              scope: 'cloud_sync.backup_write',
              limit: const Duration(seconds: 8),
            ),
          ).then((value) {
            result = value;
          }),
        );

        async.elapse(const Duration(seconds: 5));
        completer.complete();
        async.elapse(const Duration(seconds: 1));

        expect(result, CloudWriteResult.completed);
      });
    },
  );
}
