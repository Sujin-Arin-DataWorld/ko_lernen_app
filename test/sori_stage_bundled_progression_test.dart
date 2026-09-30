import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/hanok_competence_projection_service.dart';
import 'package:ko_lernen_app/services/sori_stage_progression_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  tearDown(DiagnosticsService.resetForTesting);

  for (final consent in [false, true]) {
    for (final source in ['today', 'hanok']) {
      test(
        'failed $source keeps progress and respects diagnostic consent=$consent',
        () async {
          final sink = _FailureSink();
          DiagnosticsService.configureForTesting(
            sink: sink,
            consent: () => consent,
          );
          await Storage.setXp(120);
          const failure = FormatException(
            'private learner answer',
            'private progress',
          );
          for (var attempt = 0; attempt < 2; attempt++) {
            await expectLater(
              SoriStageProgressionService.load(
                loadToday: source == 'today' ? () async => throw failure : null,
                loadHanokCompetence: source == 'hanok'
                    ? () async => throw failure
                    : HanokCompetenceProjectionService.readCurrent,
              ),
              throwsA(same(failure)),
            );
          }
          expect(Storage.xp, 120);
          expect(Storage.pendingBoxes, isEmpty);
          final reports = sink.errors
              .where((entry) => entry.$1.startsWith('stage_progression.'))
              .toList();
          expect(reports, hasLength(consent ? 1 : 0));
          if (!consent) {
            expect(sink.errors, isEmpty);
          }
          if (consent) {
            expect(reports.single.$1, 'stage_progression.$source');
            expect(reports.single.$2.toString(), contains('FormatException'));
            expect(reports.single.$2.toString(), isNot(contains('private')));
          }
        },
      );
    }
  }

  test('bundled data loads Today and Hanok for a new learner', () async {
    final snapshot = await SoriStageProgressionService.load();

    expect(snapshot.xp, 0);
    expect(snapshot.activityProgress, isNotEmpty);
    expect(Storage.xp, 0);
  });
}

class _FailureSink implements DiagnosticsSink {
  final errors = <(String, Object, StackTrace)>[];
  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, String value) async {}
  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) async {
    errors.add((scope, error, stackTrace));
  }
}
