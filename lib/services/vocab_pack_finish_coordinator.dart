import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/course_practice_context.dart';
import '../models/pack_progress.dart';
import '../models/curriculum.dart';
import '../models/vocab_pack.dart';
import 'course_activity_reporter.dart';
import 'decoration_reward_service.dart';
import 'local_data_lifetime.dart';
import 'pack_progress_service.dart';
import 'storage_service.dart';
import 'pack_completion_record.dart';
import 'pack_completion_owner.dart';
import 'course_mastery_service.dart';
import 'course_progress_service.dart';
import 'curriculum_catalog.dart';
import 'vocab_pack_service.dart';
import '../widgets/sori/dancheong_stamp.dart';

/// Immutable evidence captured when a vocab-pack assessment reaches its
/// terminal boundary. A screen keeps one instance so a retry cannot silently
/// switch to newer counters after some persistence steps have already passed.
class VocabPackFinishRequest {
  VocabPackFinishRequest({
    required this.pack,
    required this.siblingPacks,
    required this.bossAccuracy,
    required this.bossCorrect,
    required this.bossTotal,
    required this.quizCorrect,
    required this.quizTotal,
    required this.completionStampMotif,
    this.courseContext,
  });

  final VocabPack pack;
  final List<VocabPack> siblingPacks;
  final double bossAccuracy;
  final int bossCorrect;
  final int bossTotal;
  final int quizCorrect;
  final int quizTotal;
  final CoursePracticeContext? courseContext;
  final String completionStampMotif;
  final String completionId = const Uuid().v4();
  @visibleForTesting
  static DateTime Function()? clockForTesting;
  final DateTime _capturedAt = clockForTesting?.call() ?? DateTime.now();
  late final DateTime occurredAt = _capturedAt.toUtc();
  late final String earnedOn = Storage.todayIsoFor(_capturedAt);

  int get xpAward => pack.total * 5 + bossCorrect * 10;

  double get courseScore {
    final totalAnswers = quizTotal + bossTotal;
    return totalAnswers == 0 ? 0 : (quizCorrect + bossCorrect) / totalAnswers;
  }

  final LocalDataLifetimeLease _lifetime = LocalDataLifetime.capture();
  late final CourseContentAttempt? _courseAttempt = _createCourseAttempt();

  CourseContentAttempt? _createCourseAttempt() {
    final context = courseContext;
    if (context == null) {
      return null;
    }
    final passed = courseScore >= .70;
    return CourseContentAttempt(
      kind: CurriculumContentKind.vocab,
      contentId: context.initialContentId,
      isCorrect: passed,
      isApplicable: true,
      courseContext: context,
      // Legacy enum spelling only; the score is four-choice recognition.
      errorReason: passed ? null : MasteryErrorReason.vocabularyRecall,
      score: courseScore,
    );
  }

  void _admit() {
    _lifetime.assertCurrent();
    // Materialize before an earlier async finish leg can cross a local reset.
    _courseAttempt;
  }

  void _assertCurrent() {
    _lifetime.assertCurrent();
  }

  Future<void> _saveCourseAttempt() async {
    _lifetime.assertCurrent();
    await _courseAttempt?.save();
    _lifetime.assertCurrent();
  }
}

class VocabPackFinishOutcome {
  const VocabPackFinishOutcome({
    required this.justCleared,
    required this.nextUnlockedPackId,
  });

  final bool justCleared;
  final String? nextUnlockedPackId;
}

/// The five authoritative writes that must finish before result navigation.
///
/// The first operation returns the clear transition because the later stamp
/// and pending-reward steps, as well as the result screen, depend on it.
abstract interface class VocabPackFinishOperations {
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  );

  Future<void> recordCourseAttempt(VocabPackFinishRequest request);

  Future<void> awardXp(VocabPackFinishRequest request);

  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  );

  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  );
}

/// Production adapter for the existing local-first progress services.
class DefaultVocabPackFinishOperations implements VocabPackFinishOperations {
  DefaultVocabPackFinishOperations();

  final Expando<XpAwardAttempt> _xpAttempts = Expando<XpAwardAttempt>();

  static void initializeRecovery() {
    PackCompletionStorage.confirmOwner = PackCompletionOwner.confirm;
    PackCompletionStorage.onSettled =
        CourseProgressService.shared.invalidatePackCompletionCache;
    PackCompletionStorage.validateContent = () async {
      final record = PackCompletionStorage.record!;
      final packs = await VocabPackService.loadAll();
      final matches = packs.where((p) => p.id == record.packId).toList();
      if (matches.length != 1 ||
          await _contentHash(
                matches.single,
                packs.where((p) => p.level == matches.single.level).toList(),
                record.courseContext != null,
              ) !=
              record.contentHash) {
        throw const PackCompletionPendingException();
      }
    };
  }

  static Future<String> _contentHash(
    VocabPack pack,
    List<VocabPack> siblings,
    bool course,
  ) async {
    final catalog = course ? await CurriculumCatalog.load() : null;
    return PackCompletionRecord.digest({
      'policy': 1,
      'pack': pack.id,
      'level': pack.level,
      'siblings': [
        for (final p in siblings) [p.id, p.level, p.total],
      ],
      'words': [
        for (final w in pack.words)
          [
            w.id,
            w.korean,
            w.romanization,
            w.german,
            w.english,
            w.packId,
            w.level,
            w.packOrder,
            w.isReviewBoss,
          ],
      ],
      if (catalog != null)
        'course': {
          'generation': catalog.scenarioCorpusGeneration,
          'units': [for (final u in catalog.courseUnits) u.toJson()],
          'links': [for (final l in catalog.contentLinks) l.toJson()],
          'concepts': [for (final c in catalog.concepts) c.toJson()],
        },
    });
  }

  Future<VocabPackFinishOutcome> finishDurably(
    VocabPackFinishRequest request,
  ) async {
    initializeRecovery();
    final retained = PackCompletionStorage.record;
    if (retained != null) {
      if (retained.id != request.completionId ||
          !await PackCompletionStorage.retry()) {
        throw const PackCompletionPendingException();
      }
    } else {
      // Capture tails before admission; reset may hold the course wipe barrier
      // later, but recovery never queues back into that barrier (no cycle).
      await PackCompletionStorage.admit(
        (owner) => _prepare(request, owner),
        drains: [
          CourseProgressService.shared.packCompletionDrain,
          Storage.packCompletionXpDrain,
          Storage.packCompletionPackDrain,
          DecorationRewardService.packCompletionDrain,
        ],
      ).timeout(const Duration(seconds: 3));
    }
    request._assertCurrent();
    final result = PackCompletionStorage.result;
    if (result == null || result.id != request.completionId) {
      throw const PackCompletionPendingException();
    }
    return VocabPackFinishOutcome(
      justCleared: result.justCleared,
      nextUnlockedPackId: result.nextPackId,
    );
  }

  Future<PackCompletionRecord> _prepare(
    VocabPackFinishRequest request,
    String owner,
  ) async {
    request._assertCurrent();
    final pack = request.pack;
    final packs = await VocabPackService.loadAll();
    final matching = packs.where((p) => p.id == pack.id).toList();
    if (matching.length != 1 ||
        pack.total == 0 ||
        pack.total > 256 ||
        request.quizTotal != pack.normalWords.length ||
        request.bossTotal != pack.bossWords.length ||
        request.bossCorrect < 0 ||
        request.bossCorrect > request.bossTotal ||
        request.quizCorrect < 0 ||
        request.quizCorrect > request.quizTotal ||
        request.bossAccuracy !=
            (request.bossTotal == 0
                ? 1
                : request.bossCorrect / request.bossTotal) ||
        request.completionStampMotif != motifForPackId(pack.id).name) {
      throw const FormatException('Invalid pack terminal evidence.');
    }
    final siblings = packs.where((p) => p.level == pack.level).toList();
    final fingerprint = await _contentHash(
      pack,
      request.siblingPacks,
      request.courseContext != null,
    );
    if (fingerprint !=
        await _contentHash(
          matching.single,
          siblings,
          request.courseContext != null,
        )) {
      throw const FormatException('Pack assessment authority changed.');
    }
    final before = PackCompletionStorage.nativeState();
    if (before['kl_reward_claim_v1'] != null &&
        before['kl_reward_claim_v1'] != '') {
      throw const PackCompletionPendingException();
    }
    final rawPacks = before[PackCompletionRecord.packKey];
    final map = rawPacks == null || rawPacks == ''
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(rawPacks as String) as Map);
    final existing = map.map(
      (id, body) => MapEntry(
        id,
        PackProgress.fromJson(id, Map<String, dynamic>.from(body as Map)),
      ),
    );
    final boss = PackProgressService.prepareBossAttempt(
      pack,
      siblings,
      bossAccuracy: request.bossAccuracy,
      existing: existing,
      earnedAt: request.occurredAt,
    );
    map[pack.id] = boss.progress.toJson();
    final bossRaw = jsonEncode(map);
    if (boss.nextProgress case final next?) {
      map[next.packId] = next.toJson();
    }
    final after = Map<String, Object?>.of(before)
      ..[PackCompletionRecord.packKey] = jsonEncode(map)
      ..[PackCompletionRecord.xpKey] = Storage.preparePackCompletionXp(
        request.xpAward,
        request.earnedOn,
      );
    final context = request.courseContext;
    Map<String, String>? provenance;
    if (context != null) {
      if (!pack.words.any((w) => w.id == context.initialContentId) ||
          !context.isFor(CurriculumContentKind.vocab)) {
        throw const FormatException('Pack course provenance does not match.');
      }
      final catalog = await CurriculumCatalog.load();
      final snapshot = await CourseMasteryService(catalog)
          .preparePackCompletion(
            context: context,
            score: request.courseScore,
            occurredAt: request.occurredAt,
            completionId: request.completionId,
          );
      after['kl_placement_level_v1'] = snapshot.placementLevel;
      if (snapshot.placementLevel != null) {
        after['kl_user_level'] = snapshot.placementLevel;
      }
      after['kl_course_unit_v1'] = snapshot.currentCourseUnitId;
      after['kl_course_mastery_v2'] = jsonEncode(snapshot.toJson());
      provenance = {
        'unit': context.courseUnitId,
        'link': context.contentLinkId,
        'kind': 'vocab',
        'content': context.initialContentId,
      };
    }
    if (boss.justCleared) {
      final stamps = Storage.earnedStamps;
      if (!stamps.contains(request.completionStampMotif)) {
        stamps.add(request.completionStampMotif);
        after[PackCompletionRecord.stampKey] = stamps;
      }
      final boxes = Storage.pendingBoxes;
      final source = '${DecorationRewardService.kPackSourcePrefix}${pack.id}';
      if (!boxes.contains(source)) {
        after[PackCompletionRecord.boxKey] = [...boxes, source];
      }
    }
    return PackCompletionRecord(
      id: request.completionId,
      owner: owner,
      occurredAt: request.occurredAt.toIso8601String(),
      earnedOn: request.earnedOn,
      packId: pack.id,
      level: pack.level,
      contentHash: fingerprint,
      quizCorrect: request.quizCorrect,
      quizTotal: request.quizTotal,
      bossCorrect: request.bossCorrect,
      bossTotal: request.bossTotal,
      wordCount: pack.total,
      xp: request.xpAward,
      justCleared: boss.justCleared,
      nextPackId: boss.nextUnlocked?.id,
      stampMotif: request.completionStampMotif,
      courseContext: provenance,
      before: before,
      boss: bossRaw,
      after: after,
    );
  }

  @override
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  ) async {
    final result = await PackProgressService.recordBossAttempt(
      request.pack,
      request.siblingPacks,
      bossAccuracy: request.bossAccuracy,
    );
    return VocabPackFinishOutcome(
      justCleared: result.justCleared,
      nextUnlockedPackId: result.nextUnlocked?.id,
    );
  }

  @override
  Future<void> recordCourseAttempt(VocabPackFinishRequest request) async {
    await request._saveCourseAttempt();
  }

  @override
  Future<void> awardXp(VocabPackFinishRequest request) =>
      (_xpAttempts[request] ??= XpAwardAttempt(request.xpAward)).save();

  @override
  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {
    if (!outcome.justCleared) {
      return;
    }
    await Storage.addEarnedStamp(request.completionStampMotif);
  }

  @override
  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {
    if (!outcome.justCleared) {
      return;
    }
    await DecorationRewardService.ensurePendingBox(
      '${DecorationRewardService.kPackSourcePrefix}${request.pack.id}',
    );
  }
}

enum _VocabPackFinishStep { boss, course, xp, stamp, pending }

/// Resumes the first incomplete authoritative write after a recoverable error.
///
/// Completed steps stay recorded for this coordinator's one immutable request.
/// Concurrent calls share one future, and retries never replay an earlier
/// successful write such as XP or the boss attempt.
final class VocabPackFinishCoordinator {
  VocabPackFinishCoordinator(this._operations);

  final VocabPackFinishOperations _operations;
  final Set<_VocabPackFinishStep> _completed = <_VocabPackFinishStep>{};

  VocabPackFinishRequest? _request;
  VocabPackFinishOutcome? _outcome;
  Future<VocabPackFinishOutcome>? _inFlight;

  Future<VocabPackFinishOutcome> finish(VocabPackFinishRequest request) {
    final accepted = _request;
    if (accepted != null && !identical(accepted, request)) {
      return Future<VocabPackFinishOutcome>.error(
        StateError('A finish coordinator can only serve one request.'),
      );
    }
    _request ??= request;
    try {
      request._admit();
    } catch (error, stackTrace) {
      return Future<VocabPackFinishOutcome>.error(error, stackTrace);
    }

    final running = _inFlight;
    if (running != null) {
      return running;
    }

    late final Future<VocabPackFinishOutcome> resumed;
    resumed = _resume(request).whenComplete(() {
      if (identical(_inFlight, resumed)) {
        _inFlight = null;
      }
    });
    _inFlight = resumed;
    return resumed;
  }

  Future<VocabPackFinishOutcome> _resume(VocabPackFinishRequest request) async {
    request._assertCurrent();
    if (_operations case final DefaultVocabPackFinishOperations production) {
      return production.finishDurably(request);
    }
    if (!_completed.contains(_VocabPackFinishStep.boss)) {
      _outcome = await _operations.recordBossAttempt(request);
      request._assertCurrent();
      _completed.add(_VocabPackFinishStep.boss);
    }
    final outcome = _outcome!;

    if (!_completed.contains(_VocabPackFinishStep.course)) {
      await _operations.recordCourseAttempt(request);
      request._assertCurrent();
      _completed.add(_VocabPackFinishStep.course);
    }
    if (!_completed.contains(_VocabPackFinishStep.xp)) {
      await _operations.awardXp(request);
      request._assertCurrent();
      _completed.add(_VocabPackFinishStep.xp);
    }
    if (!_completed.contains(_VocabPackFinishStep.stamp)) {
      await _operations.recordCompletionStamp(request, outcome);
      request._assertCurrent();
      _completed.add(_VocabPackFinishStep.stamp);
    }
    if (!_completed.contains(_VocabPackFinishStep.pending)) {
      await _operations.persistPendingState(request, outcome);
      request._assertCurrent();
      _completed.add(_VocabPackFinishStep.pending);
    }
    return outcome;
  }
}
