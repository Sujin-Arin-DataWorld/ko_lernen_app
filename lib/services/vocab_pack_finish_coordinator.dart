import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import '../models/vocab_pack.dart';
import 'course_activity_reporter.dart';
import 'decoration_reward_service.dart';
import 'pack_progress_service.dart';
import 'storage_service.dart';

/// Immutable evidence captured when a vocab-pack assessment reaches its
/// terminal boundary. A screen keeps one instance so a retry cannot silently
/// switch to newer counters after some persistence steps have already passed.
class VocabPackFinishRequest {
  const VocabPackFinishRequest({
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

  int get xpAward => pack.total * 5 + bossCorrect * 10;

  double get courseScore {
    final totalAnswers = quizTotal + bossTotal;
    return totalAnswers == 0 ? 0 : (quizCorrect + bossCorrect) / totalAnswers;
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
  const DefaultVocabPackFinishOperations();

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
    final courseContext = request.courseContext;
    if (courseContext == null) {
      return;
    }
    final passed = request.courseScore >= .70;
    await CourseActivityReporter.recordContentAttempt(
      CurriculumContentKind.vocab,
      courseContext.initialContentId,
      passed,
      courseContext: courseContext,
      // Legacy enum spelling only; the score is four-choice recognition.
      errorReason: passed ? null : MasteryErrorReason.vocabularyRecall,
      score: request.courseScore,
    );
  }

  @override
  Future<void> awardXp(VocabPackFinishRequest request) =>
      Storage.addXp(request.xpAward);

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
    if (!_completed.contains(_VocabPackFinishStep.boss)) {
      _outcome = await _operations.recordBossAttempt(request);
      _completed.add(_VocabPackFinishStep.boss);
    }
    final outcome = _outcome!;

    if (!_completed.contains(_VocabPackFinishStep.course)) {
      await _operations.recordCourseAttempt(request);
      _completed.add(_VocabPackFinishStep.course);
    }
    if (!_completed.contains(_VocabPackFinishStep.xp)) {
      await _operations.awardXp(request);
      _completed.add(_VocabPackFinishStep.xp);
    }
    if (!_completed.contains(_VocabPackFinishStep.stamp)) {
      await _operations.recordCompletionStamp(request, outcome);
      _completed.add(_VocabPackFinishStep.stamp);
    }
    if (!_completed.contains(_VocabPackFinishStep.pending)) {
      await _operations.persistPendingState(request, outcome);
      _completed.add(_VocabPackFinishStep.pending);
    }
    return outcome;
  }
}
