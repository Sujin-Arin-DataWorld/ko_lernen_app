import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_reward_moment.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';

void main() {
  final now = DateTime(2026, 10, 4, 23, 59);
  final day = YeopjeonRewardMoment.dayKey(now);
  final id = 'daily:$day:first';
  final wallet = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0)
      .copyWith(
        balance: 20,
        claims: {id: 20},
        completedSourceIds: {'lesson:test'},
      );
  test(
    'amount alone never qualifies a film; committed identity and origin do',
    () {
      final legacy = YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.granted,
        amount: 20,
        wallet: wallet,
      );
      expect(
        legacy.rewardMoment(
          source: YeopjeonRewardSource.currentActivity,
          observedAt: now,
        ),
        isNull,
      );
      final confirmed = YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.granted,
        amount: 20,
        wallet: wallet,
        confirmedClaimIds: [id],
      );
      final moment = confirmed.rewardMoment(
        source: YeopjeonRewardSource.currentActivity,
        observedAt: now,
      )!;
      expect(moment.playMintVideo, isTrue);
      expect(moment.balance, 20);
      expect(
        confirmed
            .rewardMoment(
              source: YeopjeonRewardSource.recovery,
              observedAt: now,
            )!
            .playMintVideo,
        isFalse,
      );
      expect(
        confirmed
            .rewardMoment(
              source: YeopjeonRewardSource.currentActivity,
              observedAt: now.add(const Duration(minutes: 2)),
            )!
            .playMintVideo,
        isFalse,
      );
      expect(
        moment.playMintVideo,
        isTrue,
        reason: 'The chosen presentation survives a midnight crossing.',
      );
      expect(() => moment.claims[id] = 100, throwsUnsupportedError);
    },
  );
  test(
    'unknown, rejected, purchase and no-reward results have no display grant',
    () {
      for (final status in [
        YeopjeonTransactionStatus.failed,
        YeopjeonTransactionStatus.unknown,
        YeopjeonTransactionStatus.noReward,
        YeopjeonTransactionStatus.alreadyClaimed,
        YeopjeonTransactionStatus.built,
      ]) {
        final result = YeopjeonTransactionResult(
          status: status,
          amount: 20,
          wallet: wallet,
          confirmedClaimIds: [id],
        );
        expect(
          result.rewardMoment(
            source: YeopjeonRewardSource.currentActivity,
            observedAt: now,
          ),
          isNull,
        );
      }
    },
  );
  test(
    'removing a shown first claim prevents the movie in the remaining receipt',
    () {
      final moment = YeopjeonRewardMoment(
        claims: {id: 20, 'daily:$day:second': 10},
        balance: 30,
        source: YeopjeonRewardSource.currentActivity,
        day: day,
      );
      final second = moment.retaining({'daily:$day:second'})!;
      expect(second.amount, 10);
      expect(second.balance, 30);
      expect(second.playMintVideo, isFalse);
      expect(moment.retaining({}), isNull);
    },
  );
}
