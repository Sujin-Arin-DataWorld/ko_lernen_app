// The Flutter test SDK already supplies fake_async; no runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/premium_service.dart';

import 'support/access_sdk_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production access callable always requests limited-use App Check tokens',
    () async {
      SharedPreferences.setMockInitialValues({});
      final harness = AccessSdkHarness();
      addTearDown(harness.dispose);
      await harness.initialize();
      expect(PremiumService.isPremium, isFalse);
      await harness.setPremium(true);
      expect(PremiumService.isPremium, isTrue);
      expect(harness.functions.calls.length, greaterThanOrEqualTo(2));
      await harness.setPremium(false);
      fakeAsync((clock) {
        var purchases = 0;
        final binder = PremiumIdentityBinder(
          _IdentityClient(),
          sessions: cloudWriteSessionController,
          initialUid: AccessSdkHarness.uid,
          identityMatches: (_) async => true,
        );
        final controller = PremiumPurchaseController(
          sessions: cloudWriteSessionController,
          binder: binder,
          identity: () => (uid: AccessSdkHarness.uid, isAnonymous: false),
          enabled: () => true,
          hasPremium: () => PremiumService.isPremium,
          refreshAccess: PremiumService.refreshAccess,
          purchasePackage: (_) async {
            purchases++;
            return true;
          },
          restorePurchases: () async => false,
        );
        PremiumPurchaseOutcome? outcome;
        controller.purchase(_monthly).then((value) => outcome = value);
        clock.flushMicrotasks();
        expect(outcome, PremiumPurchaseOutcome.pending);
        expect(PremiumService.isPremium, isFalse);
        harness.functions.premium =
            true; // Simulated later server webhook state.
        clock.elapse(const Duration(seconds: 2));
        expect(PremiumService.isPremium, isTrue);
        expect(accessSnapshotNotifier.value?.hasPremium, isTrue);
        expect(purchases, 1);
        controller.dispose();
        binder.dispose();
      });
      for (final call in harness.functions.calls) {
        expect(call.name, 'getAccessSnapshot');
        expect(call.region, 'europe-west3');
        expect(call.limitedUse, isTrue);
        expect(call.data, isNull);
      }
    },
  );
}

class _IdentityClient implements RevenueCatIdentityClient {
  @override
  Future<void> logIn(String uid) async {}
  @override
  Future<void> logOut() async {}
}

const _monthly = Package(
  'monthly',
  PackageType.monthly,
  StoreProduct(
    'monthly',
    'Monthly',
    'Monthly',
    5,
    '€5.00',
    'EUR',
    subscriptionPeriod: 'P1M',
  ),
  PresentedOfferingContext('default', null, null),
);
