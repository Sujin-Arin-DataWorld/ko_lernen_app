import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/access_snapshot_service.dart';

import 'support/access_sdk_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'open access snapshot uses limited-use App Check and highest quotas',
    () async {
      SharedPreferences.setMockInitialValues({});
      final harness = AccessSdkHarness();
      addTearDown(harness.dispose);

      await harness.initialize();
      await AccessSnapshotService.refreshAccess();

      expect(accessSnapshotNotifier.value?.source, 'universal');
      expect(accessSnapshotNotifier.value?.contentAccess, 'all');
      expect(accessSnapshotNotifier.value?.aiPolicyId, 'universal_v1');
      expect(accessSnapshotNotifier.value?.bookDailyLimit, 20);
      expect(accessSnapshotNotifier.value?.pronunciationDailyLimit, 50);
      expect(harness.functions.calls, isNotEmpty);
      for (final call in harness.functions.calls) {
        expect(call.name, 'getUniversalAccessSnapshot');
        expect(call.region, 'europe-west3');
        expect(call.limitedUse, isTrue);
        expect(call.data, isNull);
      }
    },
  );
}
