import 'dart:convert';
import '../models/course_mastery.dart';
import '../models/yeopjeon_reward_moment.dart';
import '../models/yeopjeon_wallet.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'local_data_lifetime.dart';
import 'storage_service.dart';
import 'yeopjeon_service.dart';

/// Canonical course evidence at the learning boundary, never route names,
/// animation callbacks or XP deltas. Existing units are not paid retroactively.
final class YeopjeonLearningCheckpoint {
  YeopjeonLearningCheckpoint._(this.wallet, this._units, this._lifetime);
  final YeopjeonWallet wallet;
  final Set<String> _units;
  final LocalDataLifetimeLease _lifetime;
  final List<YeopjeonRewardMoment> _moments = [];
  final Set<String> _pendingSources = {};
  YeopjeonPendingReward? get pendingReward => _pendingSources.isEmpty
      ? null
      : YeopjeonPendingReward(
          sourceIds: _pendingSources,
          baselineClaimIds: wallet.claims.keys.toSet(),
        );
  List<YeopjeonRewardMoment> get rewardMoments => List.unmodifiable(_moments);

  static Future<Set<String>> _completedUnits() async {
    final service = CourseMasteryService(await CurriculumCatalog.load());
    await service.confirmDurableState();
    return service.readForReconciliation()?.completedUnitIds.toSet() ?? {};
  }

  static Future<YeopjeonLearningCheckpoint> capture({
    PreferenceStringStore? preferences,
  }) async {
    final lifetime = LocalDataLifetime.capture();
    // Freeze provenance in the synchronous segment before navigation. A late
    // native read must neither absorb this activity's completion into the
    // baseline nor initialize/grandfather a missing wallet after learning.
    Storage.assertCourseMasteryStateConfirmed();
    final canonical = Storage.courseMasterySnapshotRawJson.trim();
    final rawCourse = canonical.isEmpty
        ? Storage.legacyCourseMasteryRawJson.trim()
        : canonical;
    final units = rawCourse.isEmpty
        ? <String>{}
        : CourseMasterySnapshot.fromJson(
            jsonDecode(rawCourse) as Map<String, dynamic>,
          ).completedUnitIds.toSet();
    final frozenWallet = Storage.captureConfirmedYeopjeonRawJson();
    if (frozenWallet == null) {
      throw StateError('Yeopjeon baseline is unavailable.');
    }
    final wallet = YeopjeonWallet.decode(frozenWallet);
    final verifiedWallet = await YeopjeonService.captureBackupJson(
      preferences: preferences,
    );
    if (verifiedWallet != frozenWallet) {
      throw StateError('Yeopjeon baseline changed during capture.');
    }
    lifetime.assertCurrent();
    return YeopjeonLearningCheckpoint._(wallet, units, lifetime);
  }

  Future<YeopjeonWallet> settle() async {
    _lifetime.assertCurrent();
    final newlyCompleted = (await _completedUnits()).difference(_units);
    _lifetime.assertCurrent();
    _pendingSources.addAll(newlyCompleted.map((id) => 'unit:$id'));
    for (final unitId in newlyCompleted) {
      final result = await YeopjeonService.grantConfirmedCompletion(
        unitId: unitId,
        completedAt: DateTime.now(),
      );
      _lifetime.assertCurrent();
      _pendingSources.removeAll(
        result.wallet?.completedSourceIds ?? const <String>{},
      );
      final moment = result.rewardMoment(
        source: YeopjeonRewardSource.currentActivity,
      );
      if (moment != null) {
        _moments.add(moment);
      }
    }
    final recovered = await YeopjeonService.recoverConfirmedLearningRewards();
    _lifetime.assertCurrent();
    _pendingSources.removeAll(
      recovered.wallet?.completedSourceIds ?? const <String>{},
    );
    final recovery = recovered.rewardMoment(
      source: YeopjeonRewardSource.recovery,
    );
    if (recovery != null) {
      _moments.add(recovery);
    }
    return recovered.wallet ?? await YeopjeonService.loadCurrent();
  }
}
