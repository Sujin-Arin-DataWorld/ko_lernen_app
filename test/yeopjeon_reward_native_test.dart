import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_reward_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_ildu_house_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_reward_receipt_sheet.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_credit_badge.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_reward_style.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_reward_movie.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';
import 'support/yeopjeon_reward_fixture.dart';

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_haptics_enabled': false});
    await Storage.init();
    await Storage.setSndMaster(false);
  });
  Future<void> render(
    WidgetTester tester,
    Widget screen, {
    String lang = 'de',
    double scale = 1,
    bool reduce = true,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(lang),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 62, bottom: 34),
            disableAnimations: reduce,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final lang in ['de', 'en']) {
    testWidgets(
      '$lang native receipt fits iPhone viewport with full movie and 12px bar',
      (tester) async {
        await render(
          tester,
          YeopjeonRewardScreen(receipt: rewardReceipt()),
          lang: lang,
        );
        expect(
          find.byKey(const ValueKey('reward-accessibility-scroll')),
          findsNothing,
        );
        final movie = tester.getRect(
          find.byKey(const ValueKey('reward-movie-full-frame')),
        );
        expect(movie.width, movie.height);
        expect(movie.width, greaterThan(200));
        expect(movie.width, 220);
        expect(find.byType(YeopjeonMediaControl), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('yeopjeon-house-progress')))
              .height,
          12,
        );
        for (final key in ['reward-visit-house', 'receipt-close']) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(rect.bottom, lessThanOrEqualTo(840));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        expect(find.text('60'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$lang native house keeps future art secret and confirms 40 coin cost',
      (tester) async {
        await render(
          tester,
          YeopjeonIlduHouseScreen(
            initialWallet: rewardWallet(),
            loader: () async => rewardWallet(),
          ),
          lang: lang,
        );
        expect(
          find.byKey(const ValueKey('reward-accessibility-scroll')),
          findsNothing,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('house-close'))).bottom,
          lessThanOrEqualTo(840),
        );
        expect(find.byType(DokkaebiRewardMovie), findsNothing);
        expect(find.textContaining('Sarangchae'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$lang at 200% keeps real text and scrolls to both actions', (
      tester,
    ) async {
      await render(
        tester,
        YeopjeonRewardScreen(receipt: rewardReceipt()),
        lang: lang,
        scale: 2,
      );
      final scroll = find.byKey(const ValueKey('reward-accessibility-scroll'));
      expect(scroll, findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('receipt-close')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(YeopjeonRewardScreen)),
        ).scale(16),
        32,
      );
    });
  }

  testWidgets(
    'wallet reserves width, credits once, and accessibility settles final balance',
    (tester) async {
      Widget badge(bool start, {bool reduce = false}) => Scaffold(
        body: Center(
          child: YeopjeonCreditBadge(
            receiptId: 'credit-1',
            balance: 100,
            fromBalance: 80,
            start: start,
            onTap: () {},
            reduceMotion: reduce,
          ),
        ),
      );
      await render(tester, badge(false), reduce: false);
      final initial = tester.getSize(
        find.byKey(const ValueKey('yeopjeon-credit-badge')),
      );
      expect(find.text('80'), findsOneWidget);
      await render(tester, badge(true), reduce: false);
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        tester.getSize(find.byKey(const ValueKey('yeopjeon-credit-badge'))),
        initial,
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('100'), findsOneWidget);
      await render(tester, badge(false), reduce: false);
      await render(tester, badge(true), reduce: false);
      expect(find.text('100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'construction waits for explicit confirmation and durable result; duplicate taps spend once',
    (tester) async {
      final pending = Completer<YeopjeonTransactionResult>();
      var calls = 0, built = 0;
      await render(
        tester,
        YeopjeonIlduHouseScreen(
          initialWallet: rewardWallet(),
          loader: () async => rewardWallet(),
          builder: (_) {
            calls++;
            return pending.future;
          },
          onBuilt: () => built++,
        ),
        lang: 'en',
      );
      final button = find.byKey(const ValueKey('house-build'));
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 0);
      expect(find.text('Your balance now: 40'), findsOneWidget);
      expect(find.text('After building: 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('house-confirm-spend')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(button);
      await tester.pump();
      expect(calls, 1);
      expect(built, 0);
      expect(find.text('40'), findsOneWidget);
      pending.complete(
        YeopjeonTransactionResult(
          status: YeopjeonTransactionStatus.built,
          amount: -40,
          wallet: rewardWallet(owned: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0'), findsOneWidget);
      expect(built, 1);
      expect(find.text('Build progress saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown construction retains confirmed balance and exposes safe refresh',
    (tester) async {
      await render(
        tester,
        YeopjeonIlduHouseScreen(
          initialWallet: rewardWallet(),
          loader: () async => rewardWallet(),
          builder: (_) async => const YeopjeonTransactionResult(
            status: YeopjeonTransactionStatus.unknown,
            amount: 0,
          ),
        ),
        lang: 'en',
      );
      await tester.tap(find.byKey(const ValueKey('house-build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('house-confirm-spend')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('40'), findsOneWidget);
      expect(find.byKey(const ValueKey('house-save-failed')), findsOneWidget);
      expect(find.text('Something new has taken shape!'), findsNothing);
    },
  );

  testWidgets('C action exposes an executable accessibility tap', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await render(
      tester,
      Scaffold(
        body: YeopjeonAction(label: 'Test action', onTap: () => taps++),
      ),
    );
    final node = tester.getSemantics(find.byType(YeopjeonAction));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.binding.rootPipelineOwner.visitChildren(
      (owner) =>
          owner.semanticsOwner?.performAction(node.id, SemanticsAction.tap),
    );
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets(
    'account identity switch removes an old balance and receipt subtree',
    (tester) async {
      cloudWriteSessionController.acquire('reward-account-a');
      await render(tester, YeopjeonRewardScreen(receipt: rewardReceipt()));
      expect(find.text('60'), findsOneWidget);
      cloudWriteSessionController.acquire('reward-account-b');
      await tester.pump();
      expect(find.byType(DokkaebiRewardMovie), findsNothing);
      expect(
        find.byKey(const ValueKey('reward-confirmed-amount')),
        findsNothing,
      );
      expect(find.text('60'), findsNothing);
      cloudWriteSessionController.clear();
    },
  );
  testWidgets(
    'already-presented daily credit leaves only the actual milestone delta',
    (tester) async {
      final observer = LearningJourneyObserver();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      final attempt = journey.beginAttempt()..complete();
      attempt.shown(
        SoriRewardKind.yeopjeon,
        20,
        identity: 'daily:2026-10-10:first',
      );
      final receipt = RewardReceipt(
        activityId: 'unit',
        receiptId: 'real-two-claims',
        yeopjeonBalanceBefore: 0,
        yeopjeonWalletAfter: rewardWallet(daily: true),
        items: [
          const RewardReceiptItem(
            kind: SoriRewardKind.yeopjeon,
            amount: 20,
            identity: 'daily:2026-10-10:first',
            label: SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
          ),
          const RewardReceiptItem(
            kind: SoriRewardKind.yeopjeon,
            amount: 40,
            identity: 'milestone:s:1',
            label: SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
          ),
        ],
      );
      expect(receipt.canRollYeopjeon, isTrue);
      final remaining = journey.unshown(receipt);
      expect(remaining.earnedYeopjeon, 40);
      expect(remaining.yeopjeonBalanceBefore, 20);
      expect(remaining.yeopjeonWalletAfter!.balance, 60);
      expect(remaining.canRollYeopjeon, isTrue);
      expect(remaining.items.single.identity, 'milestone:s:1');
    },
  );
  testWidgets(
    'confirmed coins use a full route; XP remains available separately',
    (tester) async {
      var presented = 0;
      await render(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSoriStageRewardReceipt(
                context,
                rewardReceipt(other: true),
                onPresented: () => presented++,
              ),
              child: const Text('Open receipt'),
            ),
          ),
        ),
        lang: 'en',
      );
      await tester.tap(find.text('Open receipt'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(YeopjeonRewardScreen), findsOneWidget);
      expect(presented, 1);
      await tester.tap(find.byKey(const ValueKey('reward-other-rewards')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('+15 XP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sarangchae-before-artwork')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'repeat house visits are serialized and a purchase returns the exact lower balance',
    (tester) async {
      final pending = Completer<YeopjeonWallet?>();
      var visits = 0;
      await render(
        tester,
        YeopjeonRewardScreen(
          receipt: rewardReceipt(),
          visitHouse: (_, __) {
            visits++;
            return pending.future;
          },
        ),
      );
      final visit = find.byKey(const ValueKey('reward-visit-house'));
      await tester.tap(visit);
      await tester.pump();
      await tester.tap(visit);
      await tester.pump();
      expect(visits, 1);
      pending.complete(rewardWallet(daily: true, owned: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
