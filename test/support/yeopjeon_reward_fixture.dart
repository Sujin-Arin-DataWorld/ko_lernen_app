import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';

YeopjeonWallet rewardWallet({int owned = 0, bool daily = false}) =>
    YeopjeonWallet(
      balance: 40 - owned * 40 + (daily ? 20 : 0),
      sarangchaeEligibleStage: 1,
      b2EligibleStage: 0,
      sarangchaeOwnedStage: owned,
      b2OwnedStage: 0,
      grandfatheredSarangchaeStage: 0,
      grandfatheredB2Stage: 0,
      claims: {'milestone:s:1': 40, if (daily) 'daily:2026-10-10:first': 20},
      completedSourceIds: {if (daily) 'lesson:test-a'},
      reviewedSourceIds: const {},
    );

RewardReceipt rewardReceipt({bool daily = true, bool other = false}) =>
    RewardReceipt(
      activityId: 'native-test',
      receiptId: 'confirmed-native-test',
      yeopjeonBalanceBefore: daily ? 40 : 0,
      yeopjeonWalletAfter: rewardWallet(daily: daily),
      items: [
        RewardReceiptItem(
          kind: SoriRewardKind.yeopjeon,
          identity: daily ? 'daily:2026-10-10:first' : 'milestone:s:1',
          amount: daily ? 20 : 40,
          label: const SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
        ),
        if (other)
          const RewardReceiptItem(
            kind: SoriRewardKind.xp,
            amount: 15,
            label: SoriLocalizedCopy(
              key: SoriCopyKey.rewardXp,
              de: 'Lern-XP',
              en: 'XP',
            ),
          ),
      ],
    );
