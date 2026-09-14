import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/net/sori_net.dart';

// S2 behavior test: a read whose Firestore call hangs must resolve to the
// existing "unavailable" read state within the configured limit, exactly
// like any other read failure — never left pending forever, never retried.
// `loadAllTyped`'s injected `reader` is the same dependency-injection seam
// `test/services/firestore_progress_service_test.dart` already uses in
// place of a real Firestore SDK; here it applies `withNetTimeout` to a
// never-completing future the same way the production default reader
// (`_readFirestorePacks`) now wraps its real `.get()` call, so this proves
// `loadAllTyped`'s pre-existing `catch (_) { return unavailable(); }` (see
// firestore_progress_service.dart) correctly absorbs a SoriNetTimeout.
void main() {
  test('a hung pack query resolves to CloudReadState.unavailable within the '
      'net timeout limit', () {
    fakeAsync((async) {
      CloudReadResult<FirestorePackSnapshot>? result;

      unawaited(
        FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) => withNetTimeout(
            Completer<List<FirestorePackDocument>>().future,
            scope: 'firestore_progress.read_packs',
            limit: const Duration(seconds: 8),
          ),
        ).then((value) {
          result = value;
        }),
      );

      async.elapse(const Duration(seconds: 7));
      expect(result, isNull);

      async.elapse(const Duration(seconds: 2));
      expect(result?.state, CloudReadState.unavailable);
    });
  });

  test('a hung membership read resolves to CloudReadState.unavailable within '
      'the net timeout limit', () {
    fakeAsync((async) {
      CloudReadResult<FirestorePackSnapshot>? result;

      unawaited(
        FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) async => const [],
          membershipReader: (_) => withNetTimeout(
            Completer<FirestorePackMembership?>().future,
            scope: 'firestore_progress.read_membership',
            limit: const Duration(seconds: 8),
          ),
        ).then((value) {
          result = value;
        }),
      );

      async.elapse(const Duration(seconds: 9));
      expect(result?.state, CloudReadState.unavailable);
    });
  });

  test('a read that completes just under the limit still resolves', () {
    fakeAsync((async) {
      final completer = Completer<List<FirestorePackDocument>>();
      CloudReadResult<FirestorePackSnapshot>? result;

      unawaited(
        FirestoreProgressService.loadAllTyped(
          uid: 'uid-a',
          reader: (_) => withNetTimeout(
            completer.future,
            scope: 'firestore_progress.read_packs',
            limit: const Duration(seconds: 8),
          ),
        ).then((value) {
          result = value;
        }),
      );

      async.elapse(const Duration(seconds: 5));
      completer.complete(const []);
      async.elapse(const Duration(seconds: 1));

      expect(result?.state, CloudReadState.absent);
    });
  });
}
