import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';

void main() {
  group('VocabPackFinishCoordinator', () {
    for (var failingStep = 0; failingStep < _stepNames.length; failingStep++) {
      test(
        'retry resumes after ${_stepNames[failingStep]} without repeating prior steps',
        () async {
          final operations = _FakeFinishOperations(failOnceAt: failingStep);
          final coordinator = VocabPackFinishCoordinator(operations);
          final request = _request();

          await expectLater(
            coordinator.finish(request),
            throwsA(isA<StateError>()),
          );

          final result = await coordinator.finish(request);

          expect(result.justCleared, isTrue);
          expect(result.nextUnlockedPackId, 'a1_next');
          for (var step = 0; step < _stepNames.length; step++) {
            expect(
              operations.callCount(_stepNames[step]),
              step == failingStep ? 2 : 1,
              reason: 'step ${_stepNames[step]} at failure $failingStep',
            );
          }
        },
      );
    }

    test('concurrent finish calls share one in-flight execution', () async {
      final bossGate = Completer<void>();
      final operations = _FakeFinishOperations(bossGate: bossGate);
      final coordinator = VocabPackFinishCoordinator(operations);
      final request = _request();

      final first = coordinator.finish(request);
      final second = coordinator.finish(request);

      expect(operations.callCount('boss'), 1);
      bossGate.complete();

      final results = await Future.wait([first, second]);
      expect(results[0].justCleared, isTrue);
      expect(results[1].justCleared, isTrue);
      for (final step in _stepNames) {
        expect(operations.callCount(step), 1);
      }
    });
  });
}

const _stepNames = <String>['boss', 'course', 'xp', 'stamp', 'pending'];

VocabPackFinishRequest _request() {
  const pack = VocabPack(id: 'a1_pack', level: 'A1', words: []);
  return const VocabPackFinishRequest(
    pack: pack,
    siblingPacks: [pack],
    bossAccuracy: 1,
    bossCorrect: 1,
    bossTotal: 1,
    quizCorrect: 2,
    quizTotal: 2,
    completionStampMotif: 'test_stamp',
  );
}

class _FakeFinishOperations implements VocabPackFinishOperations {
  _FakeFinishOperations({this.failOnceAt, this.bossGate});

  final int? failOnceAt;
  final Completer<void>? bossGate;
  final List<String> calls = <String>[];
  bool _failed = false;

  int callCount(String step) => calls.where((call) => call == step).length;

  Future<void> _run(String step) async {
    calls.add(step);
    final index = _stepNames.indexOf(step);
    if (!_failed && failOnceAt == index) {
      _failed = true;
      throw StateError('fail once at $step');
    }
  }

  @override
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  ) async {
    await _run('boss');
    await bossGate?.future;
    return const VocabPackFinishOutcome(
      justCleared: true,
      nextUnlockedPackId: 'a1_next',
    );
  }

  @override
  Future<void> recordCourseAttempt(VocabPackFinishRequest request) =>
      _run('course');

  @override
  Future<void> awardXp(VocabPackFinishRequest request) => _run('xp');

  @override
  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) => _run('stamp');

  @override
  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) => _run('pending');
}
