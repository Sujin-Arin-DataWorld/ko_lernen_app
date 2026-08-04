import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/sarangbang_study_recommendation.dart';

void main() {
  const course = CourseUnit(
    id: 'a1_hello',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greetings'),
    canDo: CurriculumText(ko: '인사해요', de: 'Ich grüße', en: 'I greet'),
  );
  const pack = VocabPack(id: 'a2_cafe', level: 'A2', words: []);

  group('Sarangbang study destinations', () {
    test('keeps each recommendation pointed at its established surface', () {
      expect(
        sarangbangDestinationFor(
          const CoursePick(
            unit: course,
            missionNumber: 1,
            totalMissions: 1,
            fraction: 0,
            started: false,
          ),
        ),
        const SarangbangStudyDestination(route: '/course/mission'),
      );
      expect(
        sarangbangDestinationFor(const PackPick(pack: pack, fraction: .4)),
        const SarangbangStudyDestination(
          route: '/vocab/pack',
          arguments: 'a2_cafe',
          packAccessLevel: 'A2',
        ),
      );
      expect(
        sarangbangDestinationFor(const ReviewPick(dueCount: 12)),
        const SarangbangStudyDestination(route: '/review'),
      );
      expect(
        sarangbangDestinationFor(
          const ScenarioPick(scenarioId: 'at_cafe', level: LearnerLevel.a2),
        ),
        const SarangbangStudyDestination(
          route: '/scenario',
          arguments: 'at_cafe',
        ),
      );
    });

    test('does not invent a route when the current engine has no mission', () {
      expect(sarangbangDestinationFor(null), isNull);
    });
  });
}
