import 'dart:async';

import '../models/foundation_progress.dart';
import 'account/cloud_write_session.dart';
import 'local_data_lifetime.dart';
import 'storage_service.dart';

typedef FoundationProgressReader = FutureOr<String> Function();
typedef FoundationProgressMutator =
    Future<void> Function(
      String Function(String before) update, {
      void Function()? assertCurrentWrite,
    });

/// Captured before the first await of an exercise and retained through save.
/// Account A -> B -> A and a destructive reset cannot revive old practice.
final class FoundationLearningLease {
  FoundationLearningLease.capture()
    : _lifetime = LocalDataLifetime.capture(),
      _identityEpoch = cloudWriteSessionController.identityEpoch,
      _session = cloudWriteSessionController.current;

  final LocalDataLifetimeLease _lifetime;
  final int _identityEpoch;
  final CloudWriteSession? _session;

  bool get isCurrent =>
      _lifetime.isCurrent &&
      _identityEpoch == cloudWriteSessionController.identityEpoch &&
      _session == cloudWriteSessionController.current &&
      (_session == null || _session.mode == CloudWriteMode.ready);

  void assertCurrent() {
    if (!isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
  }
}

/// These checks record a practiced action and the learner's explicit save;
/// they do not certify pronunciation or handwriting mastery.
final class FoundationPracticeEvidence {
  const FoundationPracticeEvidence.listen(
    this.task, {
    required bool playbackSucceeded,
    required bool spokenConfirmation,
  }) : _step = FoundationStep.sounds,
       _acted = playbackSucceeded,
       confirmed = spokenConfirmation;

  const FoundationPracticeEvidence.read(
    this.task, {
    required bool correctComposition,
    required bool spokenConfirmation,
  }) : _step = FoundationStep.syllables,
       _acted = correctComposition,
       confirmed = spokenConfirmation;

  const FoundationPracticeEvidence.trace(
    this.task, {
    required bool matchedStrokes,
    required this.confirmed,
  }) : _step = FoundationStep.tracing,
       _acted = matchedStrokes;

  const FoundationPracticeEvidence.word(
    this.task, {
    required bool playbackSucceeded,
    required bool spokenConfirmation,
  }) : _step = FoundationStep.firstWords,
       _acted = playbackSucceeded,
       confirmed = spokenConfirmation;

  final FoundationTask task;
  final FoundationStep _step;
  final bool _acted;
  final bool confirmed;
  bool get isValid => task.step == _step && _acted && confirmed;
}

final class FoundationProgressService {
  FoundationProgressService({
    FoundationProgressReader? read,
    FoundationProgressMutator? mutate,
    DateTime Function()? clock,
  }) : _read = read ?? FoundationProgressStorage.readRawJson,
       _mutate =
           mutate ??
           ((update, {assertCurrentWrite}) => FoundationProgressStorage.mutate(
             update,
             assertCurrentWrite: assertCurrentWrite,
           )),
       _clock = clock ?? DateTime.now;

  static final shared = FoundationProgressService();
  final FoundationProgressReader _read;
  final FoundationProgressMutator _mutate;
  final DateTime Function() _clock;

  Future<FoundationProgress> load({FoundationLearningLease? lease}) async {
    final captured = lease ?? FoundationLearningLease.capture();
    captured.assertCurrent();
    final raw = await _read();
    captured.assertCurrent();
    return FoundationProgress.decode(raw);
  }

  Future<void> markStepOpened(
    FoundationStep step, {
    FoundationLearningLease? lease,
  }) => _update((before) {
    final now = _clock().toUtc().millisecondsSinceEpoch;
    return before.withOpened(
      step,
      cursorUpdatedAt: now > before.cursorUpdatedAt
          ? now
          : before.cursorUpdatedAt + 1,
    );
  }, lease: lease ?? FoundationLearningLease.capture());

  Future<void> chooseContinueA1({required FoundationLearningLease lease}) =>
      _update((before) => before.withContinueA1(), lease: lease);

  Future<void> savePractice(
    FoundationPracticeEvidence evidence, {
    required FoundationLearningLease lease,
  }) {
    if (!evidence.isValid) {
      return Future<void>.error(
        StateError('Foundation practice needs an action and confirmation.'),
      );
    }
    return _update(
      (before) => before.withPractice(evidence.task),
      lease: lease,
    );
  }

  Future<void> _update(
    FoundationProgress Function(FoundationProgress) update, {
    required FoundationLearningLease lease,
  }) async {
    lease.assertCurrent();
    await _mutate(
      (raw) => update(FoundationProgress.decode(raw)).encode(),
      assertCurrentWrite: lease.assertCurrent,
    );
    lease.assertCurrent();
  }

  static Future<String?> captureBackupJson() async {
    await FoundationProgressStorage.drain();
    final raw = FoundationProgressStorage.readRawJson();
    if (raw.isEmpty) {
      return null;
    }
    return FoundationProgress.decode(raw).encode();
  }

  static Future<void> mergeCloudJson(
    String raw, {
    required void Function() beforeWrite,
  }) async {
    if (raw.isEmpty) {
      throw const FormatException('Invalid foundation progress backup.');
    }
    final remote = FoundationProgress.decode(raw);
    beforeWrite();
    await FoundationProgressStorage.mutate(
      (local) => FoundationProgress.decode(local).merge(remote).encode(),
      restoring: true,
      assertCurrentWrite: beforeWrite,
    );
  }
}
