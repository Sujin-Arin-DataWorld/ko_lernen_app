import '../features/content_learning/content_learning_catalog.dart';
import '../features/content_learning/content_learning_models.dart';
import '../features/content_learning/content_learning_service.dart';
import '../features/content_learning/content_learning_state.dart';
import '../models/hanok_competence.dart';
import '../models/yeopjeon_reward_moment.dart';
import '../models/yeopjeon_wallet.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'hanok_competence_projection_service.dart';
import 'local_data_lifetime.dart';
import 'storage_service.dart';

typedef YeopjeonCompetenceLoader = Future<HanokCompetenceProjection> Function();
typedef YeopjeonCompletionVerifier = Future<bool> Function(String unitId);
typedef YeopjeonLessonVerifier = Future<DateTime?> Function(String lessonId);
typedef YeopjeonEvidenceScanner = Future<Map<String, DateTime?>> Function();

enum YeopjeonTransactionStatus {
  granted,
  noReward,
  alreadyClaimed,
  built,
  alreadyBuilt,
  locked,
  insufficientFunds,
  unverified,
  failed,
  unknown,
  stale,
}

final class YeopjeonTransactionResult {
  const YeopjeonTransactionResult({
    required this.status,
    required this.amount,
    this.wallet,
    this.confirmedClaimIds = const [],
  });

  final YeopjeonTransactionStatus status;

  /// Positive for a grant, negative for a confirmed purchase, otherwise zero.
  final int amount;
  final YeopjeonWallet? wallet;

  /// Only claim IDs committed by this successful transaction.
  final List<String> confirmedClaimIds;

  YeopjeonRewardMoment? rewardMoment({
    required YeopjeonRewardSource source,
    DateTime? observedAt,
  }) {
    final confirmedWallet = wallet;
    if (status != YeopjeonTransactionStatus.granted ||
        amount <= 0 ||
        confirmedWallet == null) {
      return null;
    }
    final claims = <String, int>{
      for (final id in confirmedClaimIds)
        if ((confirmedWallet.claims[id] ?? 0) > 0)
          id: confirmedWallet.claims[id]!,
    };
    if (claims.values.fold<int>(0, (sum, value) => sum + value) != amount) {
      return null;
    }
    return YeopjeonRewardMoment(
      claims: claims,
      balance: confirmedWallet.balance,
      source: source,
      day: YeopjeonRewardMoment.dayKey(observedAt ?? DateTime.now()),
    );
  }

  bool get confirmed =>
      wallet != null &&
      (status == YeopjeonTransactionStatus.granted ||
          status == YeopjeonTransactionStatus.built);
}

/// All ledger mutations run in Storage's reset-aware queue. No UI callback,
/// animation, or receipt ID has authority to mint money or build a stage.
abstract final class YeopjeonService {
  /// Captures only a pre-existing, validated ledger. Backup must not create a
  /// zero-stage baseline before the learning catalog has been loaded.
  static Future<String?> captureBackupJson({
    PreferenceStringStore? preferences,
  }) async {
    final lifetime = LocalDataLifetime.capture();
    final revision = Storage.captureYeopjeonReadRevision();
    final raw = await Storage.readYeopjeonRawJsonStrict(
      preferences: preferences,
    );
    lifetime.assertCurrent();
    if (raw != null) {
      YeopjeonWallet.decode(raw);
    }
    Storage.assertYeopjeonReadRevision(revision);
    return raw;
  }

  /// A distinct wallet history cannot be added or max-merged safely. An
  /// account switch with divergent local/cloud money therefore stops for
  /// reconciliation rather than duplicating grants or erasing a purchase.
  static Future<void> restoreFromCloudJson(
    String raw, {
    void Function()? beforeWrite,
    PreferenceStringStore? preferences,
  }) {
    final remote = YeopjeonWallet.decode(raw);
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      beforeWrite?.call();
      final current = await Storage.readYeopjeonRawJsonStrict(
        preferences: preferences,
      );
      lifetime.assertCurrent();
      var restored = remote;
      if (current != null) {
        final local = YeopjeonWallet.decode(current);
        if (local.dominates(remote)) {
          return;
        }
        if (!remote.dominates(local) && !local.isPristineZero) {
          throw StateError('Conflicting Yeopjeon wallet histories.');
        }
        if (local.isPristineZero) {
          restored = remote.copyWith(
            completedSourceIds: {
              ...remote.completedSourceIds,
              ...local.completedSourceIds,
            },
          );
        }
      }
      beforeWrite?.call();
      await Storage.writeYeopjeonRawJsonStrict(
        restored.encode(),
        preferences: preferences,
        assertCurrentWrite: () {
          lifetime.assertCurrent();
          beforeWrite?.call();
        },
      );
      lifetime.assertCurrent();
    });
  }

  /// Early restore preflight avoids changing other account fields before a
  /// known wallet conflict. The writer repeats this check under its queue.
  static Future<void> assertRestoreCompatible(String raw) async {
    final remote = YeopjeonWallet.decode(raw);
    final localRaw = await captureBackupJson();
    if (localRaw == null) {
      return;
    }
    final local = YeopjeonWallet.decode(localRaw);
    if (!local.dominates(remote) &&
        !remote.dominates(local) &&
        !local.isPristineZero) {
      throw StateError('Conflicting Yeopjeon wallet histories.');
    }
  }

  /// Older cloud backups have course proof but no economy document. A zero
  /// baseline created during app startup is still replaceable with the
  /// already-earned construction. Any real claim or purchase blocks rebasing.
  static Future<void> grandfatherLegacyCloudProgress({
    void Function()? beforeWrite,
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      beforeWrite?.call();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final raw = await Storage.readYeopjeonRawJsonStrict(
        preferences: preferences,
      );
      lifetime.assertCurrent();
      final local = raw == null ? null : YeopjeonWallet.decode(raw);
      if (local != null && !local.isPristineZero) {
        return;
      }
      final baseline =
          YeopjeonWallet.grandfather(
            sarangchaeStage: projection.sarangchaeConstructionStage,
            b2Stage: projection.b2ConstructionStage,
          ).copyWith(
            completedSourceIds: {
              ...?local?.completedSourceIds,
              ...(await (evidenceScanner ?? _scanCompletedSources)()).keys,
            },
          );
      beforeWrite?.call();
      await _write(baseline, preferences, () {
        lifetime.assertCurrent();
        beforeWrite?.call();
      });
    });
  }

  static Future<YeopjeonWallet> loadCurrent({
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      return _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
    });
  }

  /// The lesson engine's confirmed `completedAt` is the award date and the
  /// authored catalog ID is the source. Reopening a lesson is never another
  /// completion. This shares the day's first/second budget with course units.
  static Future<YeopjeonTransactionResult> grantConfirmedLesson({
    required String lessonId,
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonLessonVerifier? lessonVerifier,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) => _result(() async {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final wallet = await _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
      if (lessonId.isEmpty ||
          lessonId.length > 248 ||
          lessonId.trim() != lessonId) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      final source = 'lesson:$lessonId';
      if (wallet.completedSourceIds.contains(source)) {
        return _out(YeopjeonTransactionStatus.alreadyClaimed, wallet);
      }
      final completedAt = await (lessonVerifier ?? _verifyCompletedLesson)(
        lessonId,
      );
      lifetime.assertCurrent();
      if (completedAt == null) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      return _awardCompletion(
        wallet,
        source,
        completedAt,
        preferences,
        lifetime.assertCurrent,
      );
    });
  });

  /// `unitId` must be in the canonical persisted course-completion set and
  /// absent from placement bypasses. First distinct unit/day earns 20; second
  /// earns 10. Every unit ID is consumed once, including units beyond that cap.
  static Future<YeopjeonTransactionResult> grantConfirmedCompletion({
    required String unitId,
    required DateTime completedAt,
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonCompletionVerifier? completionVerifier,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) => _result(() async {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final wallet = await _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
      if (unitId.isEmpty || unitId.length > 256 || unitId.trim() != unitId) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      if (wallet.completedSourceIds.contains('unit:$unitId')) {
        return _out(YeopjeonTransactionStatus.alreadyClaimed, wallet);
      }
      final verified = await (completionVerifier ?? _verifyCompletedUnit)(
        unitId,
      );
      lifetime.assertCurrent();
      if (!verified) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      return _awardCompletion(
        wallet,
        'unit:$unitId',
        completedAt,
        preferences,
        lifetime.assertCurrent,
      );
    });
  });

  /// There is currently no durable due-review completion receipt in the
  /// learning engine. Until one is passed through a trusted verifier, this
  /// method fails closed and never awards its 10-coin optional objective.
  static Future<YeopjeonTransactionResult> grantConfirmedDueReview({
    required String reviewId,
    required DateTime completedAt,
    YeopjeonCompletionVerifier? dueReviewVerifier,
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) => _result(() async {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final wallet = await _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
      if (reviewId.isEmpty ||
          reviewId.length > 256 ||
          reviewId.trim() != reviewId ||
          dueReviewVerifier == null) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      final day = _day(completedAt);
      final key = 'daily:$day:review';
      if (wallet.reviewedSourceIds.contains(reviewId) ||
          wallet.claims.containsKey(key)) {
        return _out(YeopjeonTransactionStatus.alreadyClaimed, wallet);
      }
      final verified = await dueReviewVerifier(reviewId);
      lifetime.assertCurrent();
      if (!verified) {
        return _out(YeopjeonTransactionStatus.unverified, wallet);
      }
      final candidate = wallet.copyWith(
        balance: wallet.balance + 10,
        claims: {...wallet.claims, key: 10},
        reviewedSourceIds: {...wallet.reviewedSourceIds, reviewId},
      );
      await _write(candidate, preferences, lifetime.assertCurrent);
      return YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.granted,
        amount: 10,
        wallet: candidate,
        confirmedClaimIds: List.unmodifiable([key]),
      );
    });
  });

  static Future<YeopjeonTransactionResult> buildNext(
    YeopjeonBuilding building, {
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
  }) => _result(() async {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final wallet = await _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
      final owned = wallet.ownedStage(building);
      final max = building == YeopjeonBuilding.sarangchae ? 16 : 34;
      if (owned >= max) {
        return _out(YeopjeonTransactionStatus.alreadyBuilt, wallet);
      }
      if (owned >= wallet.eligibleStage(building)) {
        return _out(YeopjeonTransactionStatus.locked, wallet);
      }
      if (wallet.balance < YeopjeonWallet.nextConstructionCost) {
        return _out(YeopjeonTransactionStatus.insufficientFunds, wallet);
      }
      final candidate = wallet.copyWith(
        balance: wallet.balance - YeopjeonWallet.nextConstructionCost,
        sarangchaeOwnedStage: building == YeopjeonBuilding.sarangchae
            ? owned + 1
            : null,
        b2OwnedStage: building == YeopjeonBuilding.b2 ? owned + 1 : null,
      );
      await _write(candidate, preferences, lifetime.assertCurrent);
      return YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.built,
        amount: -YeopjeonWallet.nextConstructionCost,
        wallet: candidate,
      );
    });
  });

  /// Retries durable learning proofs that completed after the wallet baseline
  /// but whose money commit failed or lost its native reply. Existing sources
  /// are consumed at baseline, so this cannot pay pre-economy progress.
  static Future<YeopjeonTransactionResult> recoverConfirmedLearningRewards({
    YeopjeonCompetenceLoader? competenceLoader,
    YeopjeonEvidenceScanner? evidenceScanner,
    PreferenceStringStore? preferences,
    DateTime Function()? clock,
  }) => _result(() async {
    final lifetime = LocalDataLifetime.capture();
    return Storage.runYeopjeonMutation(() async {
      lifetime.assertCurrent();
      final projection =
          await (competenceLoader ??
              HanokCompetenceProjectionService.readCurrent)();
      lifetime.assertCurrent();
      final wallet = await _reconcile(
        projection,
        evidenceScanner: evidenceScanner,
        preferences: preferences,
        assertCurrent: lifetime.assertCurrent,
      );
      final sources = await (evidenceScanner ?? _scanCompletedSources)();
      lifetime.assertCurrent();
      final missing =
          sources.entries
              .where((entry) => !wallet.completedSourceIds.contains(entry.key))
              .toList()
            ..sort((a, b) {
              final byTime = (a.value ?? DateTime(9999)).compareTo(
                b.value ?? DateTime(9999),
              );
              return byTime != 0 ? byTime : a.key.compareTo(b.key);
            });
      if (missing.isEmpty) {
        return _out(YeopjeonTransactionStatus.alreadyClaimed, wallet);
      }
      final claims = {...wallet.claims};
      final completed = {...wallet.completedSourceIds};
      var total = 0;
      for (final entry in missing) {
        final source = entry.key;
        if (!_validCompletionSource(source)) {
          throw const FormatException('Invalid confirmed learning source.');
        }
        final day = _day(entry.value ?? (clock ?? DateTime.now)());
        final first = 'daily:$day:first';
        final second = 'daily:$day:second';
        if (!claims.containsKey(first)) {
          claims[first] = 20;
          total += 20;
        } else if (!claims.containsKey(second)) {
          claims[second] = 10;
          total += 10;
        }
        completed.add(source);
      }
      final candidate = wallet.copyWith(
        balance: wallet.balance + total,
        claims: claims,
        completedSourceIds: completed,
      );
      await _write(candidate, preferences, lifetime.assertCurrent);
      return YeopjeonTransactionResult(
        status: total > 0
            ? YeopjeonTransactionStatus.granted
            : YeopjeonTransactionStatus.noReward,
        amount: total,
        wallet: candidate,
        confirmedClaimIds: List.unmodifiable(
          claims.keys.where((key) => !wallet.claims.containsKey(key)),
        ),
      );
    });
  });

  static Future<YeopjeonWallet> _reconcile(
    HanokCompetenceProjection projection, {
    required YeopjeonEvidenceScanner? evidenceScanner,
    required PreferenceStringStore? preferences,
    required void Function() assertCurrent,
  }) async {
    final raw = await Storage.readYeopjeonRawJsonStrict(
      preferences: preferences,
    );
    assertCurrent();
    if (raw == null) {
      final baseline =
          YeopjeonWallet.grandfather(
            sarangchaeStage: projection.sarangchaeConstructionStage,
            b2Stage: projection.b2ConstructionStage,
          ).copyWith(
            completedSourceIds:
                (await (evidenceScanner ?? _scanCompletedSources)()).keys
                    .toSet(),
          );
      await _write(baseline, preferences, assertCurrent);
      return baseline;
    }
    final current = YeopjeonWallet.decode(raw);
    final sarangchae = projection.sarangchaeConstructionStage;
    final b2 = projection.b2ConstructionStage;
    if (sarangchae <= current.sarangchaeEligibleStage &&
        b2 <= current.b2EligibleStage) {
      return current;
    }
    final claims = {...current.claims};
    var amount = 0;
    for (
      var stage = current.sarangchaeEligibleStage + 1;
      stage <= sarangchae;
      stage++
    ) {
      claims['milestone:s:$stage'] = YeopjeonWallet.nextConstructionCost;
      amount += YeopjeonWallet.nextConstructionCost;
    }
    for (var stage = current.b2EligibleStage + 1; stage <= b2; stage++) {
      claims['milestone:b:$stage'] = YeopjeonWallet.nextConstructionCost;
      amount += YeopjeonWallet.nextConstructionCost;
    }
    final candidate = current.copyWith(
      balance: current.balance + amount,
      sarangchaeEligibleStage: sarangchae > current.sarangchaeEligibleStage
          ? sarangchae
          : null,
      b2EligibleStage: b2 > current.b2EligibleStage ? b2 : null,
      claims: claims,
    );
    await _write(candidate, preferences, assertCurrent);
    return candidate;
  }

  static Future<void> _write(
    YeopjeonWallet candidate,
    PreferenceStringStore? preferences,
    void Function() assertCurrent,
  ) async {
    assertCurrent();
    await Storage.writeYeopjeonRawJsonStrict(
      candidate.encode(),
      preferences: preferences,
      assertCurrentWrite: assertCurrent,
    );
    assertCurrent();
  }

  static Future<bool> _verifyCompletedUnit(String unitId) async {
    final catalog = await CurriculumCatalog.load();
    if (!catalog.courseUnits.any((unit) => unit.id == unitId)) {
      return false;
    }
    final service = CourseMasteryService(catalog);
    await service.confirmDurableState();
    final snapshot = service.readForReconciliation();
    return snapshot != null &&
        snapshot.completedUnitIds.contains(unitId) &&
        !snapshot.bypassedPrerequisiteUnitIds.contains(unitId);
  }

  static Future<DateTime?> _verifyCompletedLesson(String lessonId) async {
    var inCatalog = false;
    for (final kind in LearningContentKind.values) {
      final catalog = await ContentLearningCatalog.load(kind);
      if (catalog.any((lesson) => lesson.id == lessonId)) {
        inCatalog = true;
        break;
      }
    }
    if (!inCatalog) {
      return null;
    }
    return ContentLearningService.progress(lessonId).completedAt;
  }

  static bool _validCompletionSource(String source) =>
      source.length <= 256 &&
      source.trim() == source &&
      (source.startsWith('unit:') && source.length > 5 ||
          source.startsWith('lesson:') && source.length > 7);

  static Future<Map<String, DateTime?>> _scanCompletedSources() async {
    final sources = <String, DateTime?>{};
    final catalog = await CurriculumCatalog.load();
    final course = CourseMasteryService(catalog);
    await course.confirmDurableState();
    final snapshot = course.readForReconciliation();
    if (snapshot != null) {
      final valid = catalog.courseUnits.map((unit) => unit.id).toSet();
      final bypassed = snapshot.bypassedPrerequisiteUnitIds.toSet();
      for (final id in snapshot.completedUnitIds) {
        if (valid.contains(id) && !bypassed.contains(id)) {
          sources['unit:$id'] = null;
        }
      }
    }
    final state = ContentLearningState.decode(Storage.contentLearningRawJson);
    final lessons = state['lessons'] as Map<String, dynamic>;
    for (final kind in LearningContentKind.values) {
      for (final lesson in await ContentLearningCatalog.load(kind)) {
        final completedAt =
            (lessons[lesson.id] as Map<String, dynamic>?)?['completedAt'];
        if (completedAt is String) {
          sources['lesson:${lesson.id}'] = DateTime.parse(completedAt);
        }
      }
    }
    return sources;
  }

  static Future<YeopjeonTransactionResult> _awardCompletion(
    YeopjeonWallet wallet,
    String source,
    DateTime completedAt,
    PreferenceStringStore? preferences,
    void Function() assertCurrent,
  ) async {
    final day = _day(completedAt);
    final first = 'daily:$day:first';
    final second = 'daily:$day:second';
    final claims = {...wallet.claims};
    final amount = !claims.containsKey(first)
        ? 20
        : !claims.containsKey(second)
        ? 10
        : 0;
    if (amount > 0) {
      claims[amount == 20 ? first : second] = amount;
    }
    final candidate = wallet.copyWith(
      balance: wallet.balance + amount,
      claims: claims,
      completedSourceIds: {...wallet.completedSourceIds, source},
    );
    await _write(candidate, preferences, assertCurrent);
    return YeopjeonTransactionResult(
      status: amount > 0
          ? YeopjeonTransactionStatus.granted
          : YeopjeonTransactionStatus.noReward,
      amount: amount,
      wallet: candidate,
      confirmedClaimIds: List.unmodifiable(
        amount > 0 ? [amount == 20 ? first : second] : <String>[],
      ),
    );
  }

  static String _day(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static YeopjeonTransactionResult _out(
    YeopjeonTransactionStatus status,
    YeopjeonWallet wallet,
  ) => YeopjeonTransactionResult(status: status, amount: 0, wallet: wallet);

  static Future<YeopjeonTransactionResult> _result(
    Future<YeopjeonTransactionResult> Function() operation,
  ) async {
    try {
      return await operation();
    } on StaleLocalDataLifetimeException {
      return const YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.stale,
        amount: 0,
      );
    } on PreferenceOutcomeUnknownException {
      return const YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.unknown,
        amount: 0,
      );
    } catch (_) {
      return const YeopjeonTransactionResult(
        status: YeopjeonTransactionStatus.failed,
        amount: 0,
      );
    }
  }
}
