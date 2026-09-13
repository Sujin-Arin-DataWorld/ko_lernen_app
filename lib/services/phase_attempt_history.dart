import '../models/phase_task.dart';

/// Bounded retention for Phase attempt evidence (PR #301 review, P1).
///
/// Every submission stores one [PhaseAttemptEvidence] of roughly 0.4 KB and
/// the catalogue publishes 902 tasks, so unbounded retention lets
/// `course_mastery_json` grow past the 1 MiB account-document read limit
/// (`CloudSyncService.readAccountDocument`) and makes every SharedPreferences
/// decode and cloud merge slower. The Phase panel only ever shows a task's
/// newest current pass or, failing that, its newest attempt, so retention
/// keeps exactly what the display needs plus a short recent history:
///
/// * per task: the [maxAttemptsPerTask] newest attempts, plus the newest
///   current pass when it is older than those — a pass is never dropped;
/// * overall: at most [maxRecentAttempts] non-pass attempts; the oldest are
///   dropped first. A task's protected pass never counts against this cap.
///
/// The result is deterministic for the same input set, so the cloud merge
/// (a union by attempt ID) converges back to the same bounded list on the
/// next write.
final class PhaseAttemptHistory {
  const PhaseAttemptHistory._();

  static const int maxAttemptsPerTask = 3;
  static const int maxRecentAttempts = 500;

  static List<PhaseAttemptEvidence> bound(
    Iterable<PhaseAttemptEvidence> attempts, {
    required bool Function(PhaseAttemptEvidence evidence) isCurrentPass,
  }) {
    final newestFirst = attempts.toList()..sort(_newestFirst);
    final byTask = <String, List<PhaseAttemptEvidence>>{};
    for (final evidence in newestFirst) {
      byTask.putIfAbsent(evidence.taskId, () => []).add(evidence);
    }
    final protectedIds = <String>{};
    final kept = <PhaseAttemptEvidence>[];
    for (final taskAttempts in byTask.values) {
      final recent = taskAttempts.take(maxAttemptsPerTask).toList();
      kept.addAll(recent);
      PhaseAttemptEvidence? newestPass;
      for (final evidence in taskAttempts) {
        if (isCurrentPass(evidence)) {
          newestPass = evidence;
          break;
        }
      }
      if (newestPass == null) {
        continue;
      }
      protectedIds.add(newestPass.attemptId);
      if (!recent.any((e) => e.attemptId == newestPass!.attemptId)) {
        kept.add(newestPass);
      }
    }
    final unprotected =
        kept.where((e) => !protectedIds.contains(e.attemptId)).toList()
          ..sort(_newestFirst);
    final dropped = unprotected
        .skip(maxRecentAttempts)
        .map((e) => e.attemptId)
        .toSet();
    return List.unmodifiable(
      kept.where((e) => !dropped.contains(e.attemptId)).toList()
        ..sort((a, b) => a.attemptId.compareTo(b.attemptId)),
    );
  }

  static int _newestFirst(PhaseAttemptEvidence a, PhaseAttemptEvidence b) {
    final byTime = b.occurredAt.compareTo(a.occurredAt);
    return byTime != 0 ? byTime : b.attemptId.compareTo(a.attemptId);
  }
}
