import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/yeopjeon_learning_checkpoint.dart';
import 'package:ko_lernen_app/services/yeopjeon_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import '../support/reward_preferences_platform.dart';

final class _HeldRead implements PreferenceStringStore {
  _HeldRead(this.raw);
  final String raw;
  final entered = Completer<void>();
  final released = Completer<void>();
  @override
  bool containsKey(String key) => true;
  @override
  String getString(String key) => raw;
  @override
  Future<void> reload() async {
    entered.complete();
    await released.future;
  }

  @override
  Future<bool> remove(String key) => throw UnsupportedError('read only');
  @override
  Future<bool> setString(String key, String value) =>
      throw UnsupportedError('read only');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'missing wallet capture never initializes a late legacy baseline',
    () async {
      await Storage.init();
      await expectLater(YeopjeonLearningCheckpoint.capture(), throwsStateError);
      expect(await YeopjeonService.captureBackupJson(), isNull);
    },
  );

  test(
    'completion during native read pays once from frozen pre-route proof',
    () async {
      final catalog = await CurriculumCatalog.load();
      final units = catalog.courseUnits.where((u) => u.level == 'a1').toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final before = CourseMasterySnapshot(
        curriculumGeneration: catalog.scenarioCorpusGeneration,
        placementLevel: 'a1',
        currentCourseUnitId: units.first.id,
      );
      final rawWallet = YeopjeonWallet.grandfather(
        sarangchaeStage: 0,
        b2Stage: 0,
      ).encode();
      SharedPreferences.setMockInitialValues({
        Storage.yeopjeonWalletPreferenceKey: rawWallet,
        Storage.courseMasterySnapshotPreferenceKey: jsonEncode(before.toJson()),
      });
      await Storage.init();
      final native = _HeldRead(rawWallet);
      final reading = YeopjeonLearningCheckpoint.capture(preferences: native);
      await native.entered.future;
      await Storage.setCourseMasterySnapshotRawJson(
        jsonEncode(
          CourseMasterySnapshot(
            curriculumGeneration: catalog.scenarioCorpusGeneration,
            placementLevel: 'a1',
            currentCourseUnitId: units[1].id,
            completedUnitIds: [units.first.id],
          ).toJson(),
        ),
      );
      native.released.complete();
      final checkpoint = await reading;
      final paid = await checkpoint.settle();
      expect(paid.completedSourceIds, contains('unit:${units.first.id}'));
      expect(paid.claims.values, contains(20));
      expect(paid.balance, greaterThanOrEqualTo(20));
      final retried = await checkpoint.settle();
      expect(retried.encode(), paid.encode());
      expect(await YeopjeonService.captureBackupJson(), paid.encode());
    },
  );
  test(
    'unconfirmed course payout retains pending sources until a durable retry succeeds',
    () async {
      final original = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = original;
        SharedPreferences.resetStatic();
      });
      final catalog = await CurriculumCatalog.load();
      final units = catalog.courseUnits.where((u) => u.level == 'a1').toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final before = CourseMasterySnapshot(
        curriculumGeneration: catalog.scenarioCorpusGeneration,
        placementLevel: 'a1',
        currentCourseUnitId: units.first.id,
      );
      final native = RewardPreferencesPlatform();
      native.values[Storage.yeopjeonWalletPreferenceKey] =
          YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0).encode();
      native.values[Storage.courseMasterySnapshotPreferenceKey] = jsonEncode(
        before.toJson(),
      );
      SharedPreferencesStorePlatform.instance = native;
      SharedPreferences.resetStatic();
      await Storage.init();
      final checkpoint = await YeopjeonLearningCheckpoint.capture();
      await Storage.setCourseMasterySnapshotRawJson(
        jsonEncode(
          CourseMasterySnapshot(
            curriculumGeneration: catalog.scenarioCorpusGeneration,
            placementLevel: 'a1',
            currentCourseUnitId: units[1].id,
            completedUnitIds: [units.first.id],
          ).toJson(),
        ),
      );
      native.rejectKey = Storage.yeopjeonWalletPreferenceKey;
      await expectLater(
        checkpoint.settle(),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(
        checkpoint.pendingReward?.sourceIds,
        contains('unit:${units.first.id}'),
      );
      expect(checkpoint.rewardMoments, isEmpty);
      expect(Storage.courseMasterySnapshotRawJson, contains(units.first.id));
      native.rejectKey = null;
      final result = await YeopjeonService.recoverConfirmedLearningRewards();
      expect(result.amount, greaterThanOrEqualTo(20));
      await checkpoint.settle();
      expect(checkpoint.pendingReward, isNull);
      final wallet = await YeopjeonService.loadCurrent();
      expect(wallet.completedSourceIds, contains('unit:${units.first.id}'));
    },
  );
}
