import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/phase_task.dart';
import 'package:ko_lernen_app/services/phase_attempt_history.dart';

/// PR #301 review (P1) — Phase attempt evidence must stay bounded while the
/// newest current pass of every task survives, because the Phase panel shows
/// exactly that pass (or, failing one, the newest attempt).
void main() {
  PhaseAttemptEvidence attempt(
    String id, {
    String task = 'KP01:writing:01',
    required int minute,
    bool assessment = true,
    double? score = 1,
  }) => PhaseAttemptEvidence.fromJson({
    'attemptId': id,
    'phaseId': task.split(':').first,
    'taskId': task,
    'contentHash': 'a' * 64,
    'contentRevision': 1,
    'rubricVersion': 1,
    'minimumScore': 0.8,
    'evaluatorVersion': PhaseTaskResult.evaluatorVersion,
    'mode': assessment ? 'assessment' : 'practice',
    'score': score,
    'passedCriterionIds': score == null ? <String>[] : ['q1'],
    'occurredAt': DateTime.utc(
      2026,
      9,
      1,
    ).add(Duration(minutes: minute)).toIso8601String(),
  });
  List<String> ids(Iterable<PhaseAttemptEvidence> evidence) =>
      evidence.map((e) => e.attemptId).toList();
  bool never(PhaseAttemptEvidence _) => false;

  test('keeps only the newest attempts of a task', () {
    final kept = PhaseAttemptHistory.bound([
      for (var minute = 1; minute <= 6; minute++)
        attempt('a$minute', minute: minute, assessment: minute.isEven),
    ], isCurrentPass: never);
    expect(ids(kept), ['a4', 'a5', 'a6']);
    expect(() => kept.add(kept.first), throwsUnsupportedError);
  });

  test('the newest current pass survives older than the recent window', () {
    final kept = PhaseAttemptHistory.bound([
      attempt('pass-old', minute: 1),
      attempt('pass-new', minute: 2),
      for (var minute = 3; minute <= 7; minute++)
        attempt('fail$minute', minute: minute, score: 0.5),
    ], isCurrentPass: (e) => e.attemptId.startsWith('pass'));
    expect(ids(kept), ['fail5', 'fail6', 'fail7', 'pass-new']);
  });

  test('a pass inside the recent window is not duplicated', () {
    final kept = PhaseAttemptHistory.bound([
      attempt('fail', minute: 1, score: 0.1),
      attempt('pass', minute: 2),
    ], isCurrentPass: (e) => e.attemptId == 'pass');
    expect(ids(kept), ['fail', 'pass']);
  });

  test('tasks are bounded independently', () {
    final kept = PhaseAttemptHistory.bound([
      for (var minute = 1; minute <= 5; minute++) ...[
        attempt('w$minute', minute: minute),
        attempt('r$minute', task: 'KP01:reading:01', minute: minute),
      ],
    ], isCurrentPass: never);
    expect(ids(kept), ['r3', 'r4', 'r5', 'w3', 'w4', 'w5']);
  });

  test('the overall cap drops the oldest non-pass attempts, never a pass', () {
    final many = [
      attempt('pass', task: 'KP30:reading:01', minute: 0),
      for (var i = 1; i <= PhaseAttemptHistory.maxRecentAttempts + 40; i++)
        attempt(
          'try${i.toString().padLeft(4, '0')}',
          task: 'KP01:reading:${i.toString().padLeft(4, '0')}',
          minute: i,
          score: 0.2,
        ),
    ];
    final kept = PhaseAttemptHistory.bound(
      many,
      isCurrentPass: (e) => e.attemptId == 'pass',
    );
    expect(kept, hasLength(PhaseAttemptHistory.maxRecentAttempts + 1));
    expect(ids(kept), contains('pass'));
    expect(ids(kept), isNot(contains('try0001')));
    expect(ids(kept), isNot(contains('try0040')));
    expect(ids(kept), contains('try0041'));
    expect(ids(kept), contains('try0540'));
    expect(
      PhaseAttemptHistory.bound(
        kept.reversed,
        isCurrentPass: (e) => e.attemptId == 'pass',
      ).map((e) => e.attemptId),
      ids(kept),
      reason: 'Bounding is idempotent and order-independent.',
    );
  });

  test('ties on time fall back to the attempt ID', () {
    final kept = PhaseAttemptHistory.bound([
      for (final id in ['b', 'd', 'a', 'c']) attempt(id, minute: 1),
    ], isCurrentPass: never);
    expect(ids(kept), ['b', 'c', 'd']);
  });
}
