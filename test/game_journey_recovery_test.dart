import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  testWidgets(
    'retained reward retry completes one journey attempt and deducts only shown XP',
    (tester) async {
      final original = SharedPreferencesStorePlatform.instance;
      final observer = LearningJourneyObserver.shared;
      observer.cancel();
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final platform = RewardPreferencesPlatform();
      SharedPreferencesStorePlatform.instance = platform;
      SoundService.playImpl = (_) {};
      addTearDown(() {
        observer.cancel();
        SoundService.resetForTesting();
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = original;
      });
      await Storage.init();
      final nav = GlobalKey<NavigatorState>();
      late Route<dynamic> origin;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              origin = ModalRoute.of(context)!;
              return const Text('Origin');
            },
          ),
        ),
      );
      final journey = observer.begin(origin)!;
      final result = GameResultAttempt(gameId: 'cloze', xp: 10, score: 80);
      platform.rejectKey = 'kl_game_best';
      await expectLater(
        result.save(),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.xp, 10);
      expect(journey.result.completed, isFalse);
      expect(journey.result.failedSaves, 1);
      platform.rejectKey = null;
      final outcome = await result.save();
      await journey.settle();
      expect(journey.attempts, hasLength(1));
      expect(journey.result.completedAttempts, 1);
      expect(journey.result.failedSaves, 0);
      expect(outcome.attempt, same(journey.attempts.single));
      expect(Storage.xp, 10);
      const label = SoriLocalizedCopy(de: 'XP', en: 'XP');
      const receipt = RewardReceipt(
        activityId: 'cloze',
        receiptId: 'r',
        items: [
          RewardReceiptItem(kind: SoriRewardKind.xp, label: label, amount: 10),
          RewardReceiptItem(
            kind: SoriRewardKind.bojagi,
            label: label,
            amount: 1,
          ),
        ],
      );
      expect(journey.unshown(receipt).items, hasLength(2));
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: LearningRewardPresentation(
              attempt: outcome.attempt,
              kind: SoriRewardKind.xp,
              amount: outcome.xpGained,
              child: const Text('+10 XP'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(journey.unshown(receipt).items.single.kind, SoriRewardKind.bojagi);
      expect(await result.save(), same(outcome));
      expect(Storage.xp, 10);
      expect(journey.result.completedAttempts, 1);
    },
  );
}
