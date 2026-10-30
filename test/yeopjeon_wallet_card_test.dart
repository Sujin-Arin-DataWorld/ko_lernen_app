import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_wallet_card.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/video_lease.dart';
import 'support/real_fonts.dart';

YeopjeonWallet wallet({int owned = 0}) => YeopjeonWallet(
  balance: owned == 0 ? 40 : 0,
  sarangchaeEligibleStage: 1,
  b2EligibleStage: 0,
  sarangchaeOwnedStage: owned,
  b2OwnedStage: 0,
  grandfatheredSarangchaeStage: 0,
  grandfatheredB2Stage: 0,
  claims: const {'milestone:s:1': 40},
  completedSourceIds: const {},
  reviewedSourceIds: const {},
);

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_haptics_enabled': false});
    await Storage.init();
    await Storage.setSndMaster(false);
  });
  Future<void> render(
    WidgetTester tester, {
    required String language,
    required Future<YeopjeonTransactionResult> Function(YeopjeonBuilding) build,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(language),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: YeopjeonWalletCard(
              loader: () async => wallet(),
              builder: build,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'read-only ledger snapshots update header and card for earned and different owner balances',
    (tester) async {
      final empty = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0);
      final firstOwner = _ReadOnlyWalletStore(empty.encode());
      final secondOwner = _ReadOnlyWalletStore(wallet().encode());
      Future<YeopjeonWallet> read(_ReadOnlyWalletStore store) async =>
          YeopjeonWallet.decode(
            (await YeopjeonService.captureBackupJson(preferences: store))!,
          );
      var activeStore = firstOwner;
      final displayed = ValueNotifier(await read(activeStore));
      addTearDown(displayed.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ValueListenableBuilder(
            valueListenable: displayed,
            builder: (_, current, __) => Scaffold(
              body: Column(
                children: [
                  YeopjeonWalletBadge(wallet: current),
                  Expanded(
                    child: SingleChildScrollView(
                      child: YeopjeonWalletCard(
                        // Matches the production parent's snapshot-keyed card.
                        key: ObjectKey(current),
                        compact: true,
                        loader: () => read(activeStore),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Future<void> expectBalance(int amount) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('yeopjeon-header-balance')),
            matching: find.text('$amount'),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('yeopjeon-balance')))
              .data,
          '$amount yeopjeon',
        );
        expect(find.text('80'), findsNothing);
        expect(find.text('80 yeopjeon'), findsNothing);
        expect(
          tester
              .widgetList<ApprovedChromeImage>(find.byType(ApprovedChromeImage))
              .where((image) => image.asset == ApprovedChromeAssets.coinFront),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
      }

      await expectBalance(0);
      firstOwner.document = empty
          .copyWith(
            balance: 20,
            claims: const {'daily:2026-10-30:first': 20},
            completedSourceIds: const {'unit:confirmed-completion-a'},
          )
          .encode();
      displayed.value = await read(firstOwner);
      await expectBalance(20);

      activeStore = secondOwner;
      displayed.value = await read(secondOwner);
      await expectBalance(40);
      expect(find.text('20 yeopjeon'), findsNothing);

      activeStore = firstOwner;
      displayed.value = await read(firstOwner);
      await expectBalance(20);
      expect(firstOwner.writeAttempts, 0);
      expect(secondOwner.writeAttempts, 0);
      expect(firstOwner.lastReadKey, Storage.yeopjeonWalletPreferenceKey);
      expect(secondOwner.lastReadKey, Storage.yeopjeonWalletPreferenceKey);
    },
  );

  testWidgets(
    'purchase never spends or celebrates before durable confirmation and blocks double tap',
    (tester) async {
      final pending = Completer<YeopjeonTransactionResult>();
      var calls = 0;
      await render(
        tester,
        language: 'en',
        build: (_) {
          calls++;
          return pending.future;
        },
      );
      final build = find.byKey(const ValueKey('yeopjeon-build-sarangchae'));
      await tester.tap(build);
      await tester.pump();
      await tester.tap(build);
      await tester.pump();
      expect(calls, 1);
      expect(find.text('40 yeopjeon'), findsOneWidget);
      expect(find.text('A new part of your hanok is ready!'), findsNothing);
      pending.complete(
        YeopjeonTransactionResult(
          status: YeopjeonTransactionStatus.built,
          amount: -40,
          wallet: wallet(owned: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('0 yeopjeon'), findsOneWidget);
      expect(find.text('A new part of your hanok is ready!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unknown purchase keeps saved money visible and offers safe retry',
    (tester) async {
      await render(
        tester,
        language: 'de',
        build: (_) async => const YeopjeonTransactionResult(
          status: YeopjeonTransactionStatus.unknown,
          amount: 0,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('yeopjeon-build-sarangchae')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('40 Yeopjeon'), findsOneWidget);
      expect(
        find.textContaining('Transaktion konnte nicht bestätigt'),
        findsOneWidget,
      );
      expect(
        find.text('Ein neuer Teil deines Hanok ist fertig!'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'explicit reduced motion revokes video eligibility independently of OS flags',
    (tester) async {
      await render(
        tester,
        language: 'en',
        build: (_) async => const YeopjeonTransactionResult(
          status: YeopjeonTransactionStatus.locked,
          amount: 0,
        ),
      );
      final context = tester.element(find.byType(YeopjeonWalletCard));
      final eligibility = VideoLeaseEligibilityBinding(onChanged: () {});
      eligibility.attach(context);
      expect(eligibility.isEligible(context, videoReady: true), isTrue);
      await Storage.setReducedMotion(true);
      expect(eligibility.isEligible(context, videoReady: true), isFalse);
      eligibility.disposeBinding();
    },
  );
  for (final language in ['de', 'en']) {
    testWidgets(
      '$language at 390dp and 200% text keeps wallet and build action accessible',
      (tester) async {
        await render(
          tester,
          language: language,
          scale: 2,
          build: (_) async => const YeopjeonTransactionResult(
            status: YeopjeonTransactionStatus.locked,
            amount: 0,
          ),
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('yeopjeon-build-sarangchae')),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('yeopjeon-build-sarangchae')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

/// Explicit read-only native preference seam: this test cannot mint or spend.
class _ReadOnlyWalletStore implements PreferenceStringStore {
  _ReadOnlyWalletStore(this.document);

  String document;
  String? lastReadKey;
  var writeAttempts = 0;

  @override
  bool containsKey(String key) => key == Storage.yeopjeonWalletPreferenceKey;

  @override
  String? getString(String key) {
    lastReadKey = key;
    return containsKey(key) ? document : null;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> setString(String key, String value) {
    writeAttempts++;
    throw StateError('Read-only wallet test store');
  }

  @override
  Future<bool> remove(String key) {
    writeAttempts++;
    throw StateError('Read-only wallet test store');
  }
}
