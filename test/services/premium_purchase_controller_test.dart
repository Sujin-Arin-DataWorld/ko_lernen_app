import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/premium_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const monthly = Package(
  'monthly',
  PackageType.monthly,
  StoreProduct(
    'monthly',
    'Monthly',
    'Monthly',
    5,
    '5,00 €',
    'EUR',
    subscriptionPeriod: 'P1M',
  ),
  PresentedOfferingContext('default', null, null),
);
const annual = Package(
  'annual',
  PackageType.annual,
  StoreProduct(
    'annual',
    'Annual',
    'Annual',
    50,
    '50,00 €',
    'EUR',
    subscriptionPeriod: 'P1Y',
  ),
  PresentedOfferingContext('default', null, null),
);

void main() {
  late CloudWriteSessionController sessions;
  late _Client sdk;
  late PremiumIdentityBinder binder;
  late PremiumPurchaseController controller;
  late ({String? uid, bool isAnonymous}) identity;
  late bool premium;
  late bool enabled;
  late int purchases;
  late int restores;
  late int refreshes;
  Future<bool> Function()? buying;
  Future<bool> Function()? restoring;
  Future<void> Function()? refresh;
  setUp(() {
    sessions = CloudWriteSessionController()..acquire('a');
    identity = (uid: 'a', isAnonymous: false);
    premium = false;
    enabled = true;
    purchases = restores = refreshes = 0;
    buying = restoring = null;
    refresh = null;
    sdk = _Client();
    binder = PremiumIdentityBinder(
      sdk,
      sessions: sessions,
      initialUid: 'old',
      identityMatches: (uid) async => sdk.current == uid && !sdk.anonymous,
    );
    controller = PremiumPurchaseController(
      sessions: sessions,
      binder: binder,
      identity: () => identity,
      enabled: () => enabled,
      hasPremium: () => premium,
      refreshAccess: () async {
        refreshes++;
        await refresh?.call();
      },
      purchasePackage: (_) async {
        purchases++;
        return await buying?.call() ?? true;
      },
      restorePurchases: () async {
        restores++;
        return await restoring?.call() ?? true;
      },
    );
  });
  tearDown(() => binder.dispose());

  test('guest purchases and restores never invoke the SDK', () async {
    identity = (uid: 'a', isAnonymous: true);
    expect(
      await controller.purchase(monthly),
      PremiumPurchaseOutcome.signInRequired,
    );
    expect(await controller.restore(), PremiumRestoreOutcome.signInRequired);
    expect(purchases + restores + sdk.logins, 0);
  });
  test('purchase waits for completed serialized identity binding', () async {
    final login = Completer<void>();
    sdk.login = login.future;
    final pending = controller.purchase(monthly);
    await Future<void>.delayed(Duration.zero);
    expect(purchases, 0);
    login.complete();
    expect(await pending, PremiumPurchaseOutcome.pending);
    expect(purchases, 1);
    expect(sdk.current, 'a');
    expect(refreshes, 1);
  });
  test('failed login never opens a store purchase', () async {
    sdk.fail = true;
    expect(await controller.purchase(monthly), PremiumPurchaseOutcome.failed);
    expect(purchases, 0);
  });
  test('SDK current identity mismatch blocks a purchase', () async {
    sdk.keepWrongIdentity = true;
    expect(await controller.purchase(monthly), PremiumPurchaseOutcome.failed);
    expect(purchases, 0);
  });
  test(
    'account epoch changes while binding discard purchase before store',
    () async {
      final login = Completer<void>();
      sdk.login = login.future;
      final pending = controller.purchase(monthly);
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('a');
      login.complete();
      expect(await pending, PremiumPurchaseOutcome.stale);
      expect(purchases, 0);
    },
  );
  test(
    'account changes during store action cannot refresh or unlock next user',
    () async {
      final purchase = Completer<bool>();
      buying = () => purchase.future;
      final pending = controller.purchase(monthly);
      await Future<void>.delayed(Duration.zero);
      identity = (uid: 'b', isAnonymous: false);
      sessions.acquire('b');
      purchase.complete(true);
      expect(await pending, PremiumPurchaseOutcome.stale);
      expect(refreshes, 0);
    },
  );
  test(
    'same account becoming anonymous during store action fails closed',
    () async {
      final purchase = Completer<bool>();
      buying = () => purchase.future;
      final pending = controller.purchase(monthly);
      await Future<void>.delayed(Duration.zero);
      identity = (uid: 'a', isAnonymous: true);
      purchase.complete(true);
      expect(await pending, PremiumPurchaseOutcome.stale);
    },
  );
  test(
    'server-confirmed snapshot is required for successful purchase',
    () async {
      refresh = () async => premium = true;
      expect(
        await controller.purchase(monthly),
        PremiumPurchaseOutcome.purchased,
      );
      expect(refreshes, 1);
    },
  );
  test(
    'active subscription or tester never starts a duplicate purchase',
    () async {
      premium = true;
      expect(
        await controller.purchase(monthly),
        PremiumPurchaseOutcome.purchased,
      );
      expect(purchases + sdk.logins, 0);
    },
  );
  test(
    'free launch disabled billing and annual-only offerings cannot purchase',
    () async {
      enabled = false;
      expect(await controller.purchase(monthly), PremiumPurchaseOutcome.failed);
      enabled = true;
      expect(await controller.purchase(annual), PremiumPurchaseOutcome.failed);
      expect(
        monthlyOfferingPackage(
          const Offering('a', 'a', {}, [annual], annual: annual),
        ),
        isNull,
      );
      expect(purchases, 0);
    },
  );
  test('pending cancellation and error remain distinct', () async {
    buying = () async => throw PlatformException(code: '1');
    expect(
      await controller.purchase(monthly),
      PremiumPurchaseOutcome.cancelled,
    );
    buying = () async => throw PlatformException(code: '20');
    expect(await controller.purchase(monthly), PremiumPurchaseOutcome.pending);
    buying = () async => throw PlatformException(code: '10');
    expect(await controller.purchase(monthly), PremiumPurchaseOutcome.failed);
  });
  test(
    'restore none pending verified error and cancellation remain distinct',
    () async {
      restoring = () async => false;
      expect(await controller.restore(), PremiumRestoreOutcome.none);
      restoring = () async => true;
      expect(await controller.restore(), PremiumRestoreOutcome.pending);
      refresh = () async => premium = true;
      expect(await controller.restore(), PremiumRestoreOutcome.restored);
      restoring = () async => throw PlatformException(code: '1');
      expect(await controller.restore(), PremiumRestoreOutcome.cancelled);
      restoring = () async => throw StateError('offline');
      expect(await controller.restore(), PremiumRestoreOutcome.failed);
    },
  );
  test('competing purchase and restore cannot execute together', () async {
    final purchase = Completer<bool>();
    buying = () => purchase.future;
    final pending = controller.purchase(monthly);
    await Future<void>.delayed(Duration.zero);
    expect(await controller.purchase(monthly), PremiumPurchaseOutcome.failed);
    expect(await controller.restore(), PremiumRestoreOutcome.failed);
    purchase.complete(true);
    await pending;
    expect(purchases, 1);
    expect(restores, 0);
  });
}

class _Client implements RevenueCatIdentityClient {
  String current = 'old';
  bool anonymous = false;
  bool keepWrongIdentity = false;
  bool fail = false;
  int logins = 0;
  Future<void>? login;
  @override
  Future<void> logIn(String uid) async {
    logins++;
    await login;
    if (fail) {
      throw StateError('login failed');
    }
    if (!keepWrongIdentity) {
      current = uid;
    }
  }

  @override
  Future<void> logOut() async {
    anonymous = true;
  }
}
