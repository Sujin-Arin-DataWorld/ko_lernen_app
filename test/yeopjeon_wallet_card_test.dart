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
