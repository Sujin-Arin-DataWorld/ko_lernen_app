import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mission_step_plan.dart';
import 'package:ko_lernen_app/models/curriculum.dart';

void main() {
  ContentLink link(String id, ContentLinkRole role) => ContentLink(
    id: id,
    contentKind: CurriculumContentKind.vocab,
    contentId: 'content-$id',
    courseUnitId: 'a1-01',
    conceptIds: ['concept-$id'],
    role: role,
  );

  test('preserves every catalog link and its original order', () {
    final links = [
      link('introduce', ContentLinkRole.introduce),
      link('practice', ContentLinkRole.practice),
      link('assess', ContentLinkRole.assess),
      link('review', ContentLinkRole.review),
    ];

    final plan = CourseMissionStepPlan.fromLinks(links);

    expect(plan.steps.map((step) => step.link.id), [
      'introduce',
      'practice',
      'assess',
      'review',
    ]);
    expect(plan.steps.map((step) => step.displayIndex), [1, 2, 3, 4]);
    expect(plan.steps.every((step) => step.total == 4), isTrue);
    expect(plan.steps.last.progress, 1);
  });

  test('finds only the captured graph link and handles an empty plan', () {
    final plan = CourseMissionStepPlan.fromLinks([
      link('a', ContentLinkRole.introduce),
      link('b', ContentLinkRole.assess),
    ]);

    expect(plan.stepForContentLinkId('b')?.displayIndex, 2);
    expect(plan.stepForContentLinkId('missing'), isNull);
    expect(CourseMissionStepPlan.fromLinks(const []).steps, isEmpty);
  });
}
