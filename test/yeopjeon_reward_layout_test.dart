import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_ildu_house_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_reward_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_reward_movie.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_reward_style.dart';
import 'support/real_fonts.dart';
import 'support/yeopjeon_reward_fixture.dart';

const _first = 'daily:2026-10-10:first';
const _second = 'daily:2026-10-10:second';
const _review = 'daily:2026-10-10:review';
const _support = 'milestone:s:1';

YeopjeonWallet _wallet(Map<String, int> claims) => YeopjeonWallet(
  balance: claims.values.fold(0, (sum, amount) => sum + amount),
  sarangchaeEligibleStage: claims.containsKey(_support) ? 1 : 0,
  b2EligibleStage: 0,
  sarangchaeOwnedStage: 0,
  b2OwnedStage: 0,
  grandfatheredSarangchaeStage: 0,
  grandfatheredB2Stage: 0,
  claims: claims,
  completedSourceIds: {
    if (claims.containsKey(_first)) 'lesson:first',
    if (claims.containsKey(_second)) 'lesson:second',
  },
  reviewedSourceIds: {if (claims.containsKey(_review)) 'review:first'},
);

RewardReceipt _receipt(String kind) {
  final claims = <String, int>{
    if (kind != 'support') _first: 20,
    if (['second', 'review', 'combined'].contains(kind)) _second: 10,
    if (['review', 'combined'].contains(kind)) _review: 10,
    if (['support', 'combined'].contains(kind)) _support: 40,
  };
  final earned = kind == 'second'
      ? {_second: 10}
      : kind == 'review'
      ? {_review: 10}
      : claims;
  final wallet = _wallet(claims);
  return RewardReceipt(
    activityId: 'layout-$kind',
    receiptId: 'layout-$kind',
    yeopjeonWalletAfter: wallet,
    yeopjeonBalanceBefore: kind == 'no-baseline'
        ? null
        : wallet.balance - earned.values.fold(0, (sum, amount) => sum + amount),
    items: [
      for (final entry in earned.entries)
        RewardReceiptItem(
          kind: SoriRewardKind.yeopjeon,
          identity: entry.key,
          amount: entry.value,
          label: const SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
        ),
      if (kind == 'combined')
        const RewardReceiptItem(
          kind: SoriRewardKind.xp,
          amount: 15,
          label: SoriLocalizedCopy(de: 'Lern-XP', en: 'XP'),
        ),
    ],
  );
}

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
    Widget screen,
    String lang, {
    double height = 874,
    double scale = 1,
    bool reduced = true,
  }) async {
    tester.view.physicalSize = Size(402, height);
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
            disableAnimations: reduced,
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

  void fits(WidgetTester tester, {double height = 874}) {
    expect(
      find.byKey(const ValueKey('reward-accessibility-scroll')),
      findsNothing,
    );
    final pane = tester.getRect(
      find.byKey(const ValueKey('yeopjeon-paper-pane')),
    );
    final goal = tester.getRect(find.byType(YeopjeonGoalPanel));
    final actions = find.byType(YeopjeonAction);
    var previous = goal.bottom;
    var first = true;
    for (final element in actions.evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(rect.top - previous, greaterThanOrEqualTo(first ? 10 : 8));
      expect(rect.bottom, lessThanOrEqualTo(height - 34));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(pane.left));
      expect(rect.right, lessThanOrEqualTo(pane.right));
      previous = rect.bottom;
      first = false;
    }
    expect(tester.takeException(), isNull);
  }

  for (final lang in ['de', 'en']) {
    testWidgets('$lang playing controls fit below the full movie', (
      tester,
    ) async {
      await render(
        tester,
        YeopjeonRewardScreen(receipt: _receipt('first'), reviewControls: true),
        lang,
        reduced: false,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      final controls = find.byType(YeopjeonMediaControl);
      expect(controls, findsNWidgets(3));
      final amount = tester.getRect(
        find.byKey(const ValueKey('reward-confirmed-amount')),
      );
      final movie = tester.getRect(find.byType(DokkaebiRewardMovie));
      expect(movie.size, const Size(220, 220));
      expect(amount.left - movie.right, greaterThanOrEqualTo(8));
      expect(amount.width, 112);
      expect(amount.top, greaterThanOrEqualTo(movie.top));
      expect(amount.bottom, lessThanOrEqualTo(movie.bottom));
      expect(find.text(lang == 'de' ? 'Belohnung' : 'Reward'), findsOneWidget);
      for (final element in controls.evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.top, greaterThanOrEqualTo(movie.bottom));
        expect(rect.left, greaterThanOrEqualTo(31));
        expect(rect.right, lessThanOrEqualTo(371));
      }
      fits(tester);
      final finalMessage = find.byKey(
        const ValueKey('reward-final-announcement'),
      );
      expect(finalMessage, findsOneWidget);
      expect(
        tester.widget<Semantics>(finalMessage).properties.liveRegion,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('reward-replay-skip')));
      await tester.pump();
      await tester.pump();
      final announcement = tester.widget<Semantics>(finalMessage);
      expect(announcement.properties.liveRegion, isTrue);
      expect(announcement.properties.label, contains('+20'));
      expect(tester.getSize(finalMessage).height, greaterThan(0));
      expect(find.text('+20'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reward-replay-skip')));
      await tester.pump();
      expect(
        tester.widget<Semantics>(finalMessage).properties.label,
        announcement.properties.label,
      );
      expect(find.text('+20'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      '$lang shower cue counts the confirmed amount in a fixed slot',
      (tester) async {
        await render(
          tester,
          YeopjeonRewardScreen(
            receipt: _receipt('first'),
            reviewControls: true,
          ),
          lang,
          reduced: false,
        );
        final earned = find.byKey(const ValueKey('reward-earned-value'));
        final slot = find.byKey(const ValueKey('reward-confirmed-amount'));
        final initialRect = tester.getRect(slot);
        tester
            .widget<DokkaebiRewardMovie>(find.byType(DokkaebiRewardMovie))
            .onCreditCue();
        await tester.pump();
        expect(tester.widget<Text>(earned).data, '+0');
        await tester.pump(const Duration(milliseconds: 300));
        final middle = int.parse(
          tester.widget<Text>(earned).data!.substring(1),
        );
        expect(middle, greaterThan(0));
        expect(middle, lessThan(20));
        expect(tester.getRect(slot), initialRect);
        expect(
          tester
              .widget<Semantics>(
                find.byKey(const ValueKey('reward-final-announcement')),
              )
              .properties
              .label,
          '+20 Yeopjeon',
        );
        await tester.tap(find.byKey(const ValueKey('reward-replay-skip')));
        await tester.pump();
        await tester.pump();
        expect(tester.widget<Text>(earned).data, '+20');
        expect(tester.getRect(slot), initialRect);
        await tester.tap(find.byKey(const ValueKey('reward-replay-skip')));
        await tester.pump();
        expect(tester.widget<Text>(earned).data, '+20');
        fits(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    for (final kind in [
      'first',
      'second',
      'review',
      'support',
      'combined',
      'no-baseline',
    ]) {
      testWidgets(
        '$lang $kind receipt keeps all copy and actions in one page',
        (tester) async {
          await render(
            tester,
            YeopjeonRewardScreen(
              receipt: _receipt(kind),
              onOtherRewards: kind == 'combined' ? () {} : null,
            ),
            lang,
          );
          fits(tester);
          if (kind == 'combined') {
            expect(
              tester
                  .getRect(find.byKey(const ValueKey('reward-other-rewards')))
                  .bottom,
              lessThanOrEqualTo(840),
            );
          }
        },
      );
    }
    for (final state in [
      'zero',
      'locked',
      'ready',
      'owned',
      'loading',
      'failed',
    ]) {
      testWidgets(
        '$lang $state house fits and never reveals future construction',
        (tester) async {
          final wallet =
              state == 'ready' || state == 'loading' || state == 'failed'
              ? rewardWallet()
              : state == 'owned'
              ? rewardWallet(owned: 1)
              : state == 'locked'
              ? _wallet({_first: 20, _second: 10, _review: 10})
              : _wallet({});
          final pending = Completer<YeopjeonWallet>();
          await render(
            tester,
            YeopjeonIlduHouseScreen(
              initialWallet: wallet,
              loader: () => state == 'loading'
                  ? pending.future
                  : state == 'failed'
                  ? Future.error(StateError('offline'))
                  : Future.value(wallet),
            ),
            lang,
          );
          fits(tester);
          expect(find.textContaining('Sarangchae'), findsNothing);
          expect(find.textContaining('von 16'), findsNothing);
          expect(find.textContaining('of 16'), findsNothing);
        },
      );
    }
    testWidgets(
      '$lang compact 668px height shrinks the full movie and keeps both CTAs',
      (tester) async {
        await render(
          tester,
          YeopjeonRewardScreen(receipt: _receipt('first')),
          lang,
          height: 668,
        );
        fits(tester, height: 668);
        final movie = tester.getRect(
          find.byKey(const ValueKey('reward-movie-full-frame')),
        );
        expect(movie.width, movie.height);
        expect(movie.height, greaterThan(100));
      },
    );
    testWidgets(
      '$lang 200% reward title and wallet have separate readable rows',
      (tester) async {
        await render(
          tester,
          YeopjeonRewardScreen(receipt: _receipt('first')),
          lang,
          scale: 2,
        );
        final title = tester.getRect(
          find.byKey(const ValueKey('yeopjeon-screen-title')),
        );
        final wallet = tester.getRect(
          find.byKey(const ValueKey('yeopjeon-credit-badge')),
        );
        expect(title.height, lessThanOrEqualTo(120.1));
        expect(wallet.top - title.bottom, greaterThanOrEqualTo(4));
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byKey(const ValueKey('yeopjeon-screen-title'))),
          ).scale(24),
          48,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('receipt-close')));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('$lang 200% house and confirmation retain real text size', (
      tester,
    ) async {
      await render(
        tester,
        YeopjeonIlduHouseScreen(
          initialWallet: rewardWallet(),
          loader: () async => rewardWallet(),
        ),
        lang,
        scale: 2,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('house-build')));
      await tester.tap(find.byKey(const ValueKey('house-build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Dialog), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('house-confirm-spend')),
      );
      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(YeopjeonAction).last),
        ).scale(16),
        32,
      );
    });
  }
}
