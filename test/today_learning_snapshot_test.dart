import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  const course = CourseUnit(
    id: 'a1_hello',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greetings'),
    canDo: CurriculumText(ko: '인사해요', de: 'Ich grüße', en: 'I greet'),
  );
  const pack = VocabPack(id: 'a2_cafe', level: 'A2', words: []);
  const scenario = Scenario(
    id: 'at_cafe',
    level: LearnerLevel.a1,
    emoji: '☕',
    register: Register.polite,
    title: LocalizedText(ko: '카페에서', de: 'Im Café', en: 'At the cafe'),
    intro: LocalizedText(
      ko: '커피를 주문해요.',
      de: 'Du bestellst Kaffee.',
      en: 'You order coffee.',
    ),
    vocab: [],
    grammarIds: [],
    dialog: [],
    quests: [],
  );
  final node = (
    pack: pack,
    progress: const PackProgress(
      packId: 'a2_cafe',
      level: 'A2',
      status: PackStatus.inProgress,
      wordsLearned: 4,
      wordsTotal: 10,
      bossAccuracy: 0,
      attempts: 0,
      clearedAtIso: null,
    ),
  );

  test('uses the existing priority once for every today surface', () {
    final snapshot = TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        courseUnits: [course],
        currentCourseUnitId: 'a1_hello',
        nowNode: node,
        dueCount: 12,
        scenarioCompleted: false,
        userLevel: LearnerLevel.a2,
      ),
      hardCount: 3,
    );

    expect(snapshot.pick, isA<CoursePick>());
    expect((snapshot.pick as CoursePick).unit.id, 'a1_hello');
    expect(
      snapshot.destination,
      const TodayLearningDestination(route: '/course/mission'),
    );
    expect(
      snapshot.presentationRevision,
      TodayLearningSnapshot.currentPresentationRevision,
    );
    expect(snapshot.dueCount, 12);
    expect(snapshot.hardCount, 3);
  });

  test('keeps a read-only copy of recommendation inputs', () {
    final units = <CourseUnit>[course];
    final inputs = TodayLearningInputs(
      courseUnits: units,
      dueCount: 11,
      scenarioCompleted: false,
      userLevel: LearnerLevel.a1,
    );

    units.clear();

    expect(inputs.courseUnits, hasLength(1));
    expect(() => inputs.courseUnits.clear(), throwsUnsupportedError);
  });

  test('keeps the established in-progress pack destination', () {
    final snapshot = TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        nowNode: node,
        dueCount: 20,
        scenario: scenario,
        scenarioCompleted: false,
        userLevel: LearnerLevel.a2,
      ),
    );

    final pick = snapshot.pick;
    expect(pick, isA<PackPick>());
    expect((pick as PackPick).pack.id, 'a2_cafe');
    expect(
      snapshot.destination,
      const TodayLearningDestination(
        route: '/vocab/pack',
        arguments: 'a2_cafe',
        packAccessLevel: 'A2',
      ),
    );
  });

  test('keeps the established due-review destination', () {
    final snapshot = TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        dueCount: 10,
        scenario: scenario,
        scenarioCompleted: false,
        userLevel: LearnerLevel.a1,
      ),
    );

    final pick = snapshot.pick;
    expect(pick, isA<ReviewPick>());
    expect((pick as ReviewPick).dueCount, 10);
    expect(
      snapshot.destination,
      const TodayLearningDestination(route: '/review'),
    );
  });

  test('carries the selected scenario and its existing destination', () {
    final snapshot = TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        dueCount: 9,
        scenario: scenario,
        scenarioCompleted: false,
        userLevel: LearnerLevel.a1,
      ),
    );

    final pick = snapshot.pick;
    expect(pick, isA<ScenarioPick>());
    expect((pick as ScenarioPick).scenarioId, scenario.id);
    expect(identical(snapshot.scenario, scenario), isTrue);
    expect(
      snapshot.destination,
      const TodayLearningDestination(route: '/scenario', arguments: 'at_cafe'),
    );
  });

  test('does not invent a destination when the existing engine is done', () {
    final snapshot = TodayLearningSnapshot.fromInputs(
      TodayLearningInputs(
        dueCount: 9,
        scenario: scenario,
        scenarioCompleted: true,
        userLevel: LearnerLevel.a1,
      ),
    );

    expect(snapshot.pick, isNull);
    expect(snapshot.destination, isNull);
  });

  test('returns the same recommendation signature for the same inputs', () {
    final inputs = TodayLearningInputs(
      nowNode: node,
      dueCount: 10,
      scenario: scenario,
      scenarioCompleted: false,
      userLevel: LearnerLevel.a2,
    );

    final first = TodayLearningSnapshot.fromInputs(inputs, hardCount: 2);
    final second = TodayLearningSnapshot.fromInputs(inputs, hardCount: 2);

    expect(first.pick, isA<PackPick>());
    expect(second.pick, isA<PackPick>());
    expect((first.pick as PackPick).pack.id, (second.pick as PackPick).pack.id);
    expect(first.destination, second.destination);
    expect(first.dueCount, second.dueCount);
    expect(first.hardCount, second.hardCount);
  });
}
