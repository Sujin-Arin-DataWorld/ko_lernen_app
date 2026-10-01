import 'dart:convert';

import '../models/course_mastery.dart';
import '../models/yeopjeon_wallet.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'local_data_lifetime.dart';
import 'yeopjeon_service.dart';
import 'storage_service.dart';

/// Canonical course evidence at the learning boundary, never route names,
/// animation callbacks or XP deltas. Existing units are not paid retroactively.
final class YeopjeonLearningCheckpoint {
  YeopjeonLearningCheckpoint._(this.wallet, this._units, this._lifetime);
  final YeopjeonWallet wallet;
  final Set<String> _units;
  final LocalDataLifetimeLease _lifetime;

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
    for (final unitId in newlyCompleted) {
      await YeopjeonService.grantConfirmedCompletion(
        unitId: unitId,
        completedAt: DateTime.now(),
      );
      _lifetime.assertCurrent();
    }
    final recovered = await YeopjeonService.recoverConfirmedLearningRewards();
    _lifetime.assertCurrent();
    return recovered.wallet ?? await YeopjeonService.loadCurrent();
  }
}
