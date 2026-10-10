// Review entry point only. Production routes receive confirmed service wallets.
import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_ildu_house_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/yeopjeon_reward_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const NativeRewardReview());
}

YeopjeonWallet reviewWallet({bool spent = false}) => YeopjeonWallet(
  balance: spent ? 70 : 110,
  sarangchaeEligibleStage: 2,
  b2EligibleStage: 0,
  sarangchaeOwnedStage: spent ? 1 : 0,
  b2OwnedStage: 0,
  grandfatheredSarangchaeStage: 0,
  grandfatheredB2Stage: 0,
  claims: const {
    'milestone:s:1': 40,
    'milestone:s:2': 40,
    'daily:2026-10-09:first': 20,
    'daily:2026-10-09:second': 10,
  },
  completedSourceIds: const {'lesson:review-a', 'lesson:review-b'},
  reviewedSourceIds: const {},
);

class NativeRewardReview extends StatelessWidget {
  const NativeRewardReview({super.key});
  @override
  Widget build(BuildContext context) {
    final query = Uri.base.queryParameters;
    final reviewTextScale = double.tryParse(query['text'] ?? '') ?? 1;
    final support = query['receipt'] == 'support';
    final locked = query['eligible'] == '0';
    var houseWallet = reviewWallet();
    final after = support
        ? reviewWallet()
        : YeopjeonWallet(
            balance: locked ? 40 : 90,
            // Review-only unlocked/locked snapshots match the HTML controls.
            // Production eligibility comes exclusively from confirmed wallets.
            sarangchaeEligibleStage: locked ? 0 : 1,
            b2EligibleStage: 0,
            sarangchaeOwnedStage: 0,
            b2OwnedStage: 0,
            grandfatheredSarangchaeStage: 0,
            grandfatheredB2Stage: 0,
            claims: {
              if (!locked) 'milestone:s:1': 40,
              'daily:2026-10-08:first': 20,
              if (!locked) 'daily:2026-10-08:second': 10,
              'daily:2026-10-09:first': 20,
            },
            completedSourceIds: const {
              'lesson:review-a',
              'lesson:review-b',
              'lesson:review-c',
            },
            reviewedSourceIds: const {},
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: Locale(query['lang'] == 'en' ? 'en' : 'de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      navigatorObservers: [soriRouteObserver],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(reviewTextScale),
          disableAnimations: query['motion'] == 'off',
          // Browser-only device review reserves OS-owned space without fake UI.
          padding: query['safe'] == '1'
              ? const EdgeInsets.only(top: 62, bottom: 34)
              : MediaQuery.paddingOf(context),
        ),
        child: Stack(
          children: [
            child!,
            if (reviewTextScale > 1 || query['reviewControls'] == '1')
              Positioned(
                top: 14,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  child: Text(
                    query['reviewControls'] == '1'
                        ? 'Playback QA · ${(reviewTextScale * 100).round()}%'
                        : 'Accessibility QA · ${(reviewTextScale * 100).round()}%',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xfff8efd9),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      home: query['view'] == 'house'
          ? YeopjeonIlduHouseScreen(
              initialWallet: houseWallet,
              loader: () async => houseWallet,
              builder: (_) async {
                houseWallet = houseWallet.copyWith(
                  balance: houseWallet.balance - 40,
                  sarangchaeOwnedStage: houseWallet.sarangchaeOwnedStage + 1,
                );
                return YeopjeonTransactionResult(
                  status: YeopjeonTransactionStatus.built,
                  amount: -40,
                  wallet: houseWallet,
                );
              },
            )
          : YeopjeonRewardScreen(
              reviewControls: query['reviewControls'] == '1',
              visitHouse: (context, wallet) async {
                var saved = wallet;
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => YeopjeonIlduHouseScreen(
                      initialWallet: saved,
                      loader: () async => saved,
                      builder: (_) async {
                        saved = saved.copyWith(
                          balance: saved.balance - 40,
                          sarangchaeOwnedStage: saved.sarangchaeOwnedStage + 1,
                        );
                        return YeopjeonTransactionResult(
                          status: YeopjeonTransactionStatus.built,
                          amount: -40,
                          wallet: saved,
                        );
                      },
                    ),
                  ),
                );
                return saved;
              },
              receipt: RewardReceipt(
                activityId: 'review-only',
                receiptId: 'review-only:${support ? 'support' : 'first'}',
                yeopjeonBalanceBefore: support || !locked ? 70 : 20,
                yeopjeonWalletAfter: after,
                items: [
                  RewardReceiptItem(
                    kind: SoriRewardKind.yeopjeon,
                    amount: support ? 40 : 20,
                    identity: support
                        ? 'milestone:s:2'
                        : 'daily:2026-10-09:first',
                    label: const SoriLocalizedCopy(
                      de: 'Yeopjeon',
                      en: 'Yeopjeon',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
