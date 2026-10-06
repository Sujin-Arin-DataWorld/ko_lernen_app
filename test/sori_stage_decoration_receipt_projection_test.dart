import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/sori_stage_progression_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';

const _source = 'q_punggyeong';
const _today = TodayLearningSnapshot(pick: null);

Future<SoriStageProgressionSnapshot> _project({
  Future<TodayLearningSnapshot> Function()? loadToday,
}) => SoriStageProgressionService.load(
  loadToday: loadToday ?? () async => _today,
  loadHanokCompetence: () async => const HanokCompetenceProjection.empty(),
);

Future<DecorationRewardReceipt> _claimLastBox() async {
  await Storage.setPendingBoxes([_source]);
  final offer = await DecorationRewardService.loadSingleOffer();
  expect(offer.state, SingleDecorationRewardOfferState.ready);
  final claim = await DecorationRewardService.claimSingleOffer(offer);
  expect(claim.result, DecorationRewardClaimResult.claimed);
  expect(Storage.pendingBoxes, isEmpty);
  expect(Storage.ownedDecor, contains(claim.receipt!.decorationSlug));
  return claim.receipt!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform native;

  setUpAll(DataLoader.loadVocab);

  setUp(() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    await Storage.setXp(123);
  });

  tearDown(() async {
    await DecorationRewardService.packCompletionDrain;
    SharedPreferencesStorePlatform.instance = originalPlatform;
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
  });

  test(
    'last real claim leaves a receipt to resume after the box count is zero',
    () async {
      await Storage.setPendingBoxes([_source]);
      final unopened = await _project();
      expect(unopened.pendingBojagiCount, 1);
      expect(unopened.hasPendingDecorationReceipt, isFalse);

      final claim = await DecorationRewardService.claimSingleOffer(
        await DecorationRewardService.loadSingleOffer(),
      );
      expect(claim.result, DecorationRewardClaimResult.claimed);
      final owned = List<String>.of(Storage.ownedDecor);
      final beforeValues = Map<String, Object>.of(native.values);
      final beforeWrites = Map<String, int>.of(native.writes);
      final receipt = claim.receipt!;

      for (var read = 0; read < 2; read++) {
        final snapshot = await _project();
        expect(snapshot.pendingBojagiCount, 0);
        expect(snapshot.hasPendingDecorationReceipt, isTrue);
        expect(snapshot.xp, 123);
        expect(Storage.xp, 123);
        expect(Storage.ownedDecor, owned);
        expect(Storage.pendingBoxes, isEmpty);
        expect(
          DecorationRewardReceiptHistory.decode(
            Storage.decorationRewardReceiptRawJson,
          ).pending!.id,
          receipt.id,
        );
        expect(native.values, beforeValues);
        expect(native.writes, beforeWrites);
      }
    },
  );

  test(
    'acknowledging the real receipt hides resume without a new award',
    () async {
      final receipt = await _claimLastBox();
      expect((await _project()).hasPendingDecorationReceipt, isTrue);
      final owned = List<String>.of(Storage.ownedDecor);
      expect(
        await DecorationRewardService.acknowledgeSingleReward(receipt),
        isTrue,
      );
      final beforeValues = Map<String, Object>.of(native.values);
      final beforeWrites = Map<String, int>.of(native.writes);

      final snapshot = await _project();

      expect(snapshot.hasPendingDecorationReceipt, isFalse);
      expect(snapshot.pendingBojagiCount, 0);
      expect(snapshot.xp, 123);
      expect(Storage.xp, 123);
      expect(Storage.ownedDecor, owned);
      expect(Storage.pendingBoxes, isEmpty);
      expect(
        DecorationRewardReceiptHistory.decode(
          Storage.decorationRewardReceiptRawJson,
        ).find(receipt.id)!.acknowledged,
        isTrue,
      );
      expect(native.values, beforeValues);
      expect(native.writes, beforeWrites);
    },
  );

  test(
    'corrupt native receipt fails instead of using the valid cached receipt',
    () async {
      final receipt = await _claimLastBox();
      expect(
        DecorationRewardReceiptHistory.decode(
          Storage.decorationRewardReceiptRawJson,
        ).pending!.id,
        receipt.id,
      );
      native.values[Storage.decorationRewardReceiptPreferenceKey] = '{corrupt';
      final beforeWrites = Map<String, int>.of(native.writes);

      await expectLater(_project(), throwsA(isA<FormatException>()));

      expect(native.writes, beforeWrites);
      expect(Storage.xp, 123);
      expect(Storage.ownedDecor, contains(receipt.decorationSlug));
    },
  );

  test(
    'unreadable native receipt remains unavailable instead of empty',
    () async {
      await _claimLastBox();
      final beforeValues = Map<String, Object>.of(native.values);
      final beforeWrites = Map<String, int>.of(native.writes);
      native.unavailable = true;

      await expectLater(
        _project(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      expect(native.values, beforeValues);
      expect(native.writes, beforeWrites);
    },
  );

  test(
    'account change during a deferred aggregate rejects the mixed snapshot',
    () async {
      cloudWriteSessionController.acquire('account-a');
      await _claimLastBox();
      final todayEntered = Completer<void>();
      final releaseToday = Completer<TodayLearningSnapshot>();
      final projection = _project(
        loadToday: () {
          todayEntered.complete();
          return releaseToday.future;
        },
      );
      final rejected = expectLater(projection, throwsA(isA<StateError>()));
      await todayEntered.future;
      cloudWriteSessionController.acquire('account-b');
      await Storage.setXp(900);
      releaseToday.complete(_today);

      await rejected;

      expect(cloudWriteSessionController.current!.uid, 'account-b');
      expect(Storage.xp, 900);
      expect(Storage.pendingBoxes, isEmpty);
    },
  );
}
