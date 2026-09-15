import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/access_snapshot_service.dart';

import '../support/access_sdk_harness.dart';

// S2 behavior test: a hung getUniversalAccessSnapshot callable must not hang
// the caller forever. `AccessSnapshotController.refresh()`'s pre-existing
// `on Object { ... }` catch (access_snapshot_controller.dart) already treats
// any transport failure as "keep the still-valid cached snapshot" — this
// proves a SoriNetTimeout from the new withNetTimeout wrap in
// access_snapshot_service.dart's `fetch` closure lands in that same branch
// within the configured limit, using the real platform-interface fake
// (`AccessSdkHarness` / `AccessFunctionsTransport`) `open_access_transport_test.dart`
// already exercises for the happy path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a hung access-snapshot fetch keeps the cached snapshot within the net '
      'timeout limit', () async {
    SharedPreferences.setMockInitialValues({});
    final harness = AccessSdkHarness();
    addTearDown(harness.dispose);

    await harness.initialize();
    final initialSnapshot = accessSnapshotNotifier.value;
    expect(initialSnapshot, isNotNull);
    expect(harness.functions.calls, hasLength(1));

    harness.functions.hangNextCall = Completer<void>();

    fakeAsync((async) {
      var refreshed = false;
      unawaited(
        AccessSnapshotService.refreshAccess().then((_) {
          refreshed = true;
        }),
      );

      // Well within the 8s default limit: the callable is still hanging.
      async.elapse(const Duration(seconds: 7));
      expect(refreshed, isFalse);

      // Past the limit: withNetTimeout has fired and the controller's
      // existing transport-failure branch has absorbed it.
      async.elapse(const Duration(seconds: 2));
      expect(refreshed, isTrue);
    });

    expect(harness.functions.calls, hasLength(2));
    // The still-valid cached snapshot from the first, successful fetch
    // survives — a hung retry never clears it and never crashes the app.
    expect(accessSnapshotNotifier.value, isNotNull);
    expect(accessSnapshotNotifier.value?.source, initialSnapshot?.source);
  });
}
