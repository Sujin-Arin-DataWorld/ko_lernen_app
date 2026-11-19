import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_wallet_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

YeopjeonWallet wallet({bool spent = false}) => YeopjeonWallet(
  balance: spent ? 0 : 40,
  sarangchaeEligibleStage: 1,
  b2EligibleStage: 0,
  sarangchaeOwnedStage: spent ? 1 : 0,
  b2OwnedStage: 0,
  grandfatheredSarangchaeStage: 0,
  grandfatheredB2Stage: 0,
  claims: const {'milestone:s:1': 40},
  completedSourceIds: const {},
  reviewedSourceIds: const {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'refresh reads confirmed money without creating or changing the ledger',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        Storage.yeopjeonWalletPreferenceKey: wallet().encode(),
      });
      await Storage.init();
      final owner = YeopjeonWalletNotifier();
      addTearDown(owner.dispose);
      await owner.refresh();
      expect(owner.value.wallet!.balance, 40);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(Storage.yeopjeonWalletPreferenceKey),
        wallet().encode(),
      );
      await Storage.writeYeopjeonRawJsonStrict(wallet(spent: true).encode());
      await owner.refresh();
      expect(owner.value.wallet!.balance, 0);
      expect(
        prefs.getString(Storage.yeopjeonWalletPreferenceKey),
        wallet(spent: true).encode(),
      );
    },
  );

  test(
    'a local/account lifetime change immediately retires money and late reads',
    () async {
      final pending = Completer<YeopjeonWallet?>();
      var reads = 0;
      final owner = YeopjeonWalletNotifier(
        loader: () => ++reads == 1 ? Future.value(wallet()) : pending.future,
      );
      addTearDown(owner.dispose);
      await owner.refresh();
      expect(owner.value.wallet!.balance, 40);
      final oldRead = owner.refresh();
      LocalDataLifetime.invalidate();
      expect(owner.value.wallet, isNull);
      pending.complete(wallet());
      await oldRead;
      expect(owner.value.wallet, isNull);
    },
  );

  test(
    'a newer account read wins and failed or absent ledgers never invent zero',
    () async {
      final old = Completer<YeopjeonWallet?>();
      var reads = 0;
      final owner = YeopjeonWalletNotifier(
        loader: () async {
          reads++;
          if (reads == 1) return old.future;
          if (reads == 2) return wallet(spent: true);
          if (reads == 3) throw StateError('unavailable');
          return null;
        },
      );
      addTearDown(owner.dispose);
      final beforeSwitch = owner.refresh();
      await owner.refresh(clear: true);
      old.complete(wallet());
      await beforeSwitch;
      expect(owner.value.wallet!.balance, 0);
      await owner.refresh();
      expect(owner.value.failed, isTrue);
      expect(owner.value.wallet, isNull);
      await owner.refresh();
      expect(owner.value.failed, isFalse);
      expect(owner.value.wallet, isNull);
    },
  );
}
