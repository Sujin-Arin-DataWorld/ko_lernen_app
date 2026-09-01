import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'production A1 unlocks only from exact assessed answers and checkpoint',
    () async {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();
      final service = CourseMasteryService(catalog);
      await service.initializeForPlacement('a1');
      final links = catalog.linksForCourseUnit('a1_01_greetings_hangul');
      final vocab = links.firstWhere(
        (link) => link.contentKind == CurriculumContentKind.vocab,
      );
      final scene = links.firstWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.scenario &&
            link.contentId == 'airport_arrival' &&
            link.exactlyAssesses(service.currentUnit!),
      );
      final airport = scenarios.firstWhere(
        (scenario) => scenario.id == 'airport_arrival',
      );
      expect(
        airport.quests
            .where((quest) => quest.hasExplicitId)
            .expand((quest) => quest.conceptIds),
        containsAll(service.currentUnit!.requiredConceptIds),
      );

      final packResult = await service.recordContentAttempt(
        CurriculumContentKind.vocab,
        vocab.contentId,
        true,
        courseContext: CoursePracticeContext.fromLink(vocab),
        score: .70,
        occurredAt: DateTime.utc(2026, 8, 12, 8),
      );
      expect(packResult.newlyUnlockedUnit, isNull);
      expect(
        service.snapshot.evidence
            .where((item) => item.contentId == vocab.contentId)
            .every(
              (item) =>
                  !item.courseEligible && item.missionContentLinkId == vocab.id,
            ),
        isTrue,
      );

      for (final conceptId in service.currentUnit!.requiredConceptIds) {
        await service.recordContentAttempt(
          CurriculumContentKind.scenario,
          scene.contentId,
          true,
          courseContext: CoursePracticeContext.fromLink(scene),
          conceptId: conceptId,
          occurredAt: DateTime.utc(2026, 8, 12, 8, 2),
        );
      }

      final verified = await service.recordScenarioCheckpoint(
        'airport_arrival',
        .70,
        courseContext: CoursePracticeContext.fromLink(scene),
        occurredAt: DateTime.utc(2026, 8, 12, 8, 5),
      );

      expect(verified.newlyUnlockedUnit?.id, 'a1_02_self_intro_identity');
      expect(verified.currentUnit?.id, 'a1_02_self_intro_identity');
    },
  );

  test('browse answers plus a checkpoint stay history-only', () async {
    final catalog = await CurriculumCatalog.load();
    final service = CourseMasteryService(catalog);
    await service.initializeForPlacement('a1');
    final links = catalog.linksForCourseUnit('a1_01_greetings_hangul');
    final vocab = links.firstWhere(
      (link) => link.contentKind == CurriculumContentKind.vocab,
    );
    final scene = links.firstWhere(
      (link) =>
          link.contentKind == CurriculumContentKind.scenario &&
          link.contentId == 'airport_arrival' &&
          link.exactlyAssesses(service.currentUnit!),
    );

    await service.recordContentAttempt(
      CurriculumContentKind.vocab,
      vocab.contentId,
      true,
      score: 1,
      occurredAt: DateTime.utc(2026, 8, 12, 9),
    );
    for (final conceptId in service.currentUnit!.requiredConceptIds) {
      await service.recordContentAttempt(
        CurriculumContentKind.scenario,
        scene.contentId,
        true,
        conceptId: conceptId,
        occurredAt: DateTime.utc(2026, 8, 12, 9, 2),
      );
    }
    final result = await service.recordScenarioCheckpoint(
      'airport_arrival',
      1,
      courseContext: CoursePracticeContext.fromLink(scene),
      occurredAt: DateTime.utc(2026, 8, 12, 9, 5),
    );

    expect(
      service.snapshot.evidence.every((item) => !item.courseEligible),
      isTrue,
    );
    expect(result.newlyUnlockedUnit, isNull);
    expect(result.currentUnit?.id, 'a1_01_greetings_hangul');
  });

  test(
    'the canonical checkpoint has one exact scenario assessment edge',
    () async {
      final catalog = await CurriculumCatalog.load();
      final service = CourseMasteryService(catalog);
      await service.initializeForPlacement('a1');
      final unit = service.currentUnit!;
      final exact = catalog
          .linksForCourseUnit(unit.id)
          .where(
            (link) =>
                link.contentKind == CurriculumContentKind.scenario &&
                link.contentId == 'airport_arrival' &&
                link.role == ContentLinkRole.assess &&
                link.exactlyAssesses(unit),
          )
          .toList(growable: false);

      expect(exact, hasLength(1));
      expect(exact.single.conceptIds.toSet(), unit.requiredConceptIds.toSet());
      expect(service.snapshot.evidence, isEmpty);
    },
  );
}
