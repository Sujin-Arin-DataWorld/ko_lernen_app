import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

Future<void> _boot([Map<String, Object> values = const {}]) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
}

void main() {
  late DateTime now;

  setUp(() async {
    now = DateTime.now();
    await _boot({
      'kl_xp': 100,
      'kl_xp_today_date': _isoDate(now),
      'kl_xp_today_raw': 5,
    });
  });

  test(
    'first listening completion atomically claims XP and completion',
    () async {
      final result = await Storage.claimListeningCompletionReward(
        scenarioId: 'cafe_order',
        earnedXp: 40,
        now: now,
      );

      expect(result, ListeningRewardClaimResult.awarded);
      expect(Storage.xp, 140);
      expect(Storage.xpToday, 45);
      expect(Storage.completedScenarios, contains('cafe_order'));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(Storage.listeningRewardLedgerPreferenceKey),
        isNotEmpty,
        reason:
            'The canonical claim and its XP must live in one durable value.',
      );
    },
  );

  test('concurrent duplicate claims award exactly once', () async {
    final results = await Future.wait([
      Storage.claimListeningCompletionReward(
        scenarioId: 'station_help',
        earnedXp: 40,
        now: now,
      ),
      Storage.claimListeningCompletionReward(
        scenarioId: 'station_help',
        earnedXp: 40,
        now: now,
      ),
    ]);

    expect(results, contains(ListeningRewardClaimResult.awarded));
    expect(results, contains(ListeningRewardClaimResult.alreadyClaimed));
    expect(Storage.xp, 140);
    expect(Storage.xpToday, 45);
  });

  test('same scenario re-entry cannot grant XP again', () async {
    await Storage.claimListeningCompletionReward(
      scenarioId: 'doctor_visit',
      earnedXp: 48,
      now: now,
    );

    final second = await Storage.claimListeningCompletionReward(
      scenarioId: 'doctor_visit',
      earnedXp: 48,
      now: now,
    );

    expect(second, ListeningRewardClaimResult.alreadyClaimed);
    expect(Storage.xp, 148);
    expect(Storage.xpToday, 53);
  });

  test('claim survives Storage restart without duplicate payout', () async {
    await Storage.claimListeningCompletionReward(
      scenarioId: 'family_dinner',
      earnedXp: 56,
      now: now,
    );

    Storage.resetForTesting();
    await Storage.init();

    expect(Storage.xp, 156);
    expect(Storage.completedScenarios, contains('family_dinner'));
    expect(
      await Storage.claimListeningCompletionReward(
        scenarioId: 'family_dinner',
        earnedXp: 56,
        now: now,
      ),
      ListeningRewardClaimResult.alreadyClaimed,
    );
    expect(Storage.xp, 156);
  });

  test('legacy completed scenario is treated as already claimed', () async {
    await _boot({
      'kl_xp': 100,
      'kl_completed_scenarios': <String>['legacy_finished'],
    });

    final result = await Storage.claimListeningCompletionReward(
      scenarioId: 'legacy_finished',
      earnedXp: 40,
      now: now,
    );

    expect(result, ListeningRewardClaimResult.alreadyClaimed);
    expect(Storage.xp, 100);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(Storage.listeningRewardLedgerPreferenceKey),
      isFalse,
      reason: 'Existing users do not receive retroactive listening XP.',
    );
  });

  test(
    'canonical claim recovers completion when the legacy mirror is lost',
    () async {
      await Storage.claimListeningCompletionReward(
        scenarioId: 'lost_mirror',
        earnedXp: 40,
        now: now,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('kl_completed_scenarios');

      Storage.resetForTesting();
      await Storage.init();

      expect(Storage.completedScenarios, contains('lost_mirror'));
      expect(
        await Storage.claimListeningCompletionReward(
          scenarioId: 'lost_mirror',
          earnedXp: 40,
          now: now,
        ),
        ListeningRewardClaimResult.alreadyClaimed,
      );
      expect(Storage.xp, 140);
    },
  );

  test('ordinary XP and cloud-style total updates preserve claims', () async {
    await Storage.claimListeningCompletionReward(
      scenarioId: 'bank_payment',
      earnedXp: 40,
      now: now,
    );
    await Storage.addXp(10);
    expect(Storage.xp, 150);
    expect(Storage.xpToday, 55);

    await Storage.setXp(220);
    expect(Storage.xp, 220);
    expect(Storage.completedScenarios, contains('bank_payment'));
    expect(
      await Storage.claimListeningCompletionReward(
        scenarioId: 'bank_payment',
        earnedXp: 40,
        now: now,
      ),
      ListeningRewardClaimResult.alreadyClaimed,
    );
    expect(Storage.xp, 220);
  });

  test(
    'corrupt ledger fails closed and an explicit retry can recover',
    () async {
      await _boot({
        'kl_xp': 100,
        Storage.listeningRewardLedgerPreferenceKey: '{broken',
      });

      await expectLater(
        Storage.claimListeningCompletionReward(
          scenarioId: 'safe_retry',
          earnedXp: 40,
          now: now,
        ),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.xp, 100);
      expect(Storage.completedScenarios, isNot(contains('safe_retry')));

      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(Storage.listeningRewardLedgerPreferenceKey);
      expect(
        await Storage.claimListeningCompletionReward(
          scenarioId: 'safe_retry',
          earnedXp: 40,
          now: now,
        ),
        ListeningRewardClaimResult.awarded,
      );
      expect(Storage.xp, 140);
    },
  );
}
