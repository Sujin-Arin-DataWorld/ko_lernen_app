import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production A1 brief projects exactly three truthful phases', () async {
    final catalog = await CurriculumCatalog.load();
    final scenarios = await ScenarioLoader.load();
    final unit = catalog.courseUnitFor('a1_01_greetings_hangul')!;
    final links = catalog.linksForCourseUnit(unit.id);

    final brief = CourseMissionBrief.from(
      unit: unit,
      links: links,
      scenarios: scenarios,
      isCurrent: true,
      snapshot: CourseMasterySnapshot(currentCourseUnitId: unit.id),
    );

    expect(brief.visibleSteps.map((step) => step.phase), [
      CourseMissionPhase.listen,
      CourseMissionPhase.build,
      CourseMissionPhase.scene,
    ]);
    expect(brief.totalStepCount, 3);
    expect(brief.visibleSteps.first.displayIndex, 1);
    expect(brief.visibleSteps.first.total, 3);
    expect(brief.estimatedMinutesToScene, 4);
    expect(brief.firstLink?.contentKind, CurriculumContentKind.vocab);
    expect(brief.targetScenario?.id, 'airport_arrival');
  });

  test(
    'a scored production pack advances to build; a CTA alone does not',
    () async {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();
      final unit = catalog.courseUnitFor('a1_01_greetings_hangul')!;
      final links = catalog.linksForCourseUnit(unit.id);
      final vocab = links.firstWhere(
        (link) => link.contentKind == CurriculumContentKind.vocab,
      );
      final unchanged = CourseMasterySnapshot(currentCourseUnitId: unit.id);

      final before = CourseMissionBrief.from(
        unit: unit,
        links: links,
        scenarios: scenarios,
        isCurrent: true,
        snapshot: unchanged,
      );
      final afterClickOnly = CourseMissionBrief.from(
        unit: unit,
        links: links,
        scenarios: scenarios,
        isCurrent: true,
        snapshot: unchanged,
      );
      expect(afterClickOnly.firstLink?.id, before.firstLink?.id);

      final completedPack = CourseMasterySnapshot(
        currentCourseUnitId: unit.id,
        evidence: [
          for (final conceptId in vocab.conceptIds)
            MasteryEvidence(
              conceptId: conceptId,
              contentKind: CurriculumContentKind.vocab,
              contentId: vocab.contentId,
              courseUnitId: unit.id,
              missionContentLinkId: vocab.id,
              isCorrect: true,
              occurredAt: DateTime.utc(2026, 8, 12),
              score: .70,
              courseEligible: false,
            ),
        ],
      );
      final afterPack = CourseMissionBrief.from(
        unit: unit,
        links: links,
        scenarios: scenarios,
        isCurrent: true,
        snapshot: completedPack,
      );

      expect(
        afterPack.firstLink?.contentKind,
        isNot(CurriculumContentKind.vocab),
      );
      expect(afterPack.visibleSteps.first.phase, CourseMissionPhase.build);
      expect(afterPack.visibleSteps.first.displayIndex, 2);
      expect(afterPack.visibleSteps.first.total, 3);
      expect(afterPack.estimatedMinutesToScene, 3);

      final build = afterPack.firstLink!;
      final completedBuild = completedPack.copyWith(
        evidence: [
          ...completedPack.evidence,
          for (final conceptId in build.conceptIds)
            MasteryEvidence(
              conceptId: conceptId,
              contentKind: build.contentKind,
              contentId: build.contentId,
              courseUnitId: unit.id,
              missionContentLinkId: build.id,
              isCorrect: true,
              occurredAt: DateTime.utc(2026, 8, 12, 0, 2),
              courseEligible: false,
            ),
        ],
      );
      final afterBuild = CourseMissionBrief.from(
        unit: unit,
        links: links,
        scenarios: scenarios,
        isCurrent: true,
        snapshot: completedBuild,
      );
      expect(afterBuild.visibleSteps.first.phase, CourseMissionPhase.scene);
      expect(afterBuild.visibleSteps.first.displayIndex, 3);
      expect(afterBuild.visibleSteps.first.total, 3);
      expect(afterBuild.firstLink?.contentKind, CurriculumContentKind.scenario);
      final fullCoverageScene = links.singleWhere(
        (link) =>
            link.contentKind == CurriculumContentKind.scenario &&
            link.contentId == 'airport_arrival' &&
            link.exactlyAssesses(unit),
      );
      final subsetScene = links.where(
        (link) =>
            link.contentKind == CurriculumContentKind.scenario &&
            link.contentId == 'airport_arrival' &&
            link.role == ContentLinkRole.assess &&
            !link.exactlyAssesses(unit),
      );
      expect(subsetScene, isNotEmpty);
      expect(afterBuild.firstLink?.id, fullCoverageScene.id);
    },
  );

  test('production A1 order mission still chooses a sentence build', () async {
    final catalog = await CurriculumCatalog.load();
    final scenarios = await ScenarioLoader.load();
    final unit = catalog.courseUnitFor('a1_04_order_request_object')!;
    final links = catalog.linksForCourseUnit(unit.id);
    final listen = links.firstWhere(
      (link) => link.contentKind == CurriculumContentKind.vocab,
    );
    final afterListen = CourseMasterySnapshot(
      currentCourseUnitId: unit.id,
      evidence: [
        for (final conceptId in listen.conceptIds)
          MasteryEvidence(
            conceptId: conceptId,
            contentKind: listen.contentKind,
            contentId: listen.contentId,
            courseUnitId: unit.id,
            missionContentLinkId: listen.id,
            isCorrect: true,
            occurredAt: DateTime.utc(2026, 8, 12),
            score: unit.passThreshold,
          ),
      ],
    );

    final brief = CourseMissionBrief.from(
      unit: unit,
      links: links,
      scenarios: scenarios,
      isCurrent: true,
      snapshot: afterListen,
    );

    expect(brief.visibleSteps.first.phase, CourseMissionPhase.build);
    expect(
      brief.firstLink?.contentKind,
      anyOf(CurriculumContentKind.cloze, CurriculumContentKind.satz),
    );
  });

  test(
    'advanced missions expose their exact checkpoint as the final CTA',
    () async {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();
      final advancedUnits = catalog.courseUnits.where(
        (unit) => const {'c1', 'c2'}.contains(unit.level),
      );

      for (final unit in advancedUnits) {
        final links = catalog.linksForCourseUnit(unit.id);
        final before = CourseMissionBrief.from(
          unit: unit,
          links: links,
          scenarios: scenarios,
          isCurrent: true,
          snapshot: CourseMasterySnapshot(currentCourseUnitId: unit.id),
        );
        expect(before.visibleSteps.map((step) => step.phase), [
          CourseMissionPhase.listen,
          CourseMissionPhase.build,
          CourseMissionPhase.checkpoint,
        ], reason: unit.id);

        final listen = before.firstLink!;
        final afterListenSnapshot = CourseMasterySnapshot(
          currentCourseUnitId: unit.id,
          evidence: _correctEvidence(listen, unit, DateTime.utc(2026, 8, 16)),
        );
        final afterListen = CourseMissionBrief.from(
          unit: unit,
          links: links,
          scenarios: scenarios,
          isCurrent: true,
          snapshot: afterListenSnapshot,
        );
        expect(afterListen.visibleSteps.first.phase, CourseMissionPhase.build);

        final build = afterListen.firstLink!;
        final readyForCheckpoint = CourseMissionBrief.from(
          unit: unit,
          links: links,
          scenarios: scenarios,
          isCurrent: true,
          snapshot: afterListenSnapshot.copyWith(
            evidence: [
              ...afterListenSnapshot.evidence,
              ..._correctEvidence(build, unit, DateTime.utc(2026, 8, 16, 0, 1)),
            ],
          ),
        );
        expect(
          readyForCheckpoint.visibleSteps.first.phase,
          CourseMissionPhase.checkpoint,
          reason: unit.id,
        );
        expect(
          readyForCheckpoint.firstLink?.contentKey,
          unit.checkpointContentIds.single,
          reason: unit.id,
        );
        expect(readyForCheckpoint.firstLink?.exactlyAssesses(unit), isTrue);
      }
    },
  );
}

List<MasteryEvidence> _correctEvidence(
  ContentLink link,
  CourseUnit unit,
  DateTime occurredAt,
) => [
  for (final conceptId in link.conceptIds)
    MasteryEvidence(
      conceptId: conceptId,
      contentKind: link.contentKind,
      contentId: link.contentId,
      courseUnitId: unit.id,
      missionContentLinkId: link.id,
      isCorrect: true,
      occurredAt: occurredAt,
      score: link.contentKind == CurriculumContentKind.vocab
          ? unit.passThreshold
          : null,
      courseEligible: link.role == ContentLinkRole.assess,
    ),
];
