import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/scenario_result_preparation.dart';

void main() {
  final checkpoint = CourseUpdate(
    snapshot: CourseMasterySnapshot(),
    currentUnit: null,
  );
  const result = ScenarioCanDoResult(
    status: ScenarioCanDoStatus.practiceOnly,
    score: .5,
  );

  test(
    'failed course persistence is retried before preparation succeeds',
    () async {
      var writes = 0;
      var projections = 0;
      final preparation = ScenarioResultPreparation(
        requiresCheckpoint: true,
        recordCheckpoint: () async => ++writes == 1 ? null : checkpoint,
        buildResult: (_) async {
          projections++;
          return result;
        },
      );

      await expectLater(preparation.prepare(), throwsStateError);
      expect(projections, 0);
      expect(await preparation.prepare(), same(result));
      expect(await preparation.prepare(), same(result));
      expect(writes, 2);
      expect(projections, 1);
    },
  );

  test(
    'projection retry uses the saved checkpoint without another write',
    () async {
      var writes = 0;
      var projections = 0;
      final preparation = ScenarioResultPreparation(
        requiresCheckpoint: true,
        recordCheckpoint: () async {
          writes++;
          return checkpoint;
        },
        buildResult: (saved) async {
          expect(saved, same(checkpoint));
          if (++projections == 1) {
            throw StateError('result data unavailable');
          }
          return result;
        },
      );

      await expectLater(preparation.prepare(), throwsStateError);
      expect(await preparation.prepare(), same(result));
      expect(writes, 1);
      expect(projections, 2);
    },
  );

  test('concurrent preparation shares the checkpoint and its result', () async {
    final gate = Completer<CourseUpdate?>();
    var writes = 0;
    var projections = 0;
    final preparation = ScenarioResultPreparation(
      requiresCheckpoint: true,
      recordCheckpoint: () {
        writes++;
        return gate.future;
      },
      buildResult: (_) async {
        projections++;
        return result;
      },
    );
    final first = preparation.prepare();
    final second = preparation.prepare();
    expect(second, same(first));
    gate.complete(checkpoint);
    expect(await first, same(result));
    expect(await second, same(result));
    expect(writes, 1);
    expect(projections, 1);
  });

  test('free practice can prepare without creating course evidence', () async {
    final preparation = ScenarioResultPreparation(
      requiresCheckpoint: false,
      recordCheckpoint: () async => null,
      buildResult: (_) async =>
          throw StateError('must not project absent evidence'),
    );
    expect(await preparation.prepare(), isNull);
    expect(await preparation.prepare(), isNull);
  });

  test(
    'a thrown checkpoint failure does not poison the next attempt',
    () async {
      var writes = 0;
      final preparation = ScenarioResultPreparation(
        requiresCheckpoint: true,
        recordCheckpoint: () async {
          if (++writes == 1) {
            throw StateError('checkpoint failed');
          }
          return checkpoint;
        },
        buildResult: (_) async => result,
      );
      await expectLater(preparation.prepare(), throwsStateError);
      expect(await preparation.prepare(), same(result));
      expect(writes, 2);
    },
  );
}
