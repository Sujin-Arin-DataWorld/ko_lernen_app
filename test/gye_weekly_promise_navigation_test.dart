import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/gye_weekly_promise_navigation.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  const promiseMeta = GyeMeta(
    id: 'gye-1',
    name: 'Mondhof',
    code: 'ABC234',
    ownerId: 'owner',
    weeklyPromiseSchemaVersion: 1,
    weeklyPromiseId: 'cafe_order',
    weeklyPromiseTarget: 3,
    weeklyPromiseProgress: 1,
  );
  const activeUnit = CourseUnit(
    id: 'a1_04_order_request_object',
    level: 'a1',
    order: 4,
    title: CurriculumText(ko: '주문', de: 'Bestellen', en: 'Ordering'),
    canDo: CurriculumText(
      ko: '공손하게 주문해요.',
      de: 'Ich kann höflich bestellen.',
      en: 'I can order politely.',
    ),
  );
  const staleUnit = CourseUnit(
    id: 'a1_02_self_intro_identity',
    level: 'a1',
    order: 2,
    title: CurriculumText(ko: '소개', de: 'Vorstellen', en: 'Introductions'),
    canDo: CurriculumText(
      ko: '자기소개해요.',
      de: 'Ich kann mich vorstellen.',
      en: 'I can introduce myself.',
    ),
  );

  ContentLink exactScenarioLink() => ContentLink(
    contentKind: CurriculumContentKind.scenario,
    contentId: 'bunshik_tteokbokki',
    courseUnitId: activeUnit.id,
    conceptIds: const ['concept_order_request'],
    role: ContentLinkRole.assess,
  );

  TodayLearningSnapshot courseToday(CourseUnit unit) => TodayLearningSnapshot(
    pick: CoursePick(
      unit: unit,
      missionNumber: unit.order,
      totalMissions: 36,
      fraction: 0.25,
      started: true,
    ),
    destination: TodayLearningDestination(
      route: '/course/mission',
      arguments: unit.id,
    ),
  );

  test('opens the exact active promise scene with typed course provenance', () {
    final resolution = GyeWeeklyPromiseNavigation.resolve(
      meta: promiseMeta,
      today: courseToday(activeUnit),
      contentLinks: [exactScenarioLink()],
    );

    expect(resolution.kind, GyePromiseNavigationKind.eligibleScene);
    expect(resolution.destination?.route, '/scenario');
    final context = resolution.destination?.arguments as CoursePracticeContext;
    expect(context.courseUnitId, activeUnit.id);
    expect(context.contentKind, CurriculumContentKind.scenario);
    expect(context.initialContentId, 'bunshik_tteokbokki');
    expect(context.contentLinkId, exactScenarioLink().id);
  });

  test('falls back to Today when the exact scenario link is absent', () {
    final today = courseToday(activeUnit);
    final resolution = GyeWeeklyPromiseNavigation.resolve(
      meta: promiseMeta,
      today: today,
      contentLinks: const [],
    );

    expect(resolution.kind, GyePromiseNavigationKind.todayFallback);
    expect(resolution.destination, today.destination);
  });

  test('falls back to Today when the active course unit is stale', () {
    final today = courseToday(staleUnit);
    final resolution = GyeWeeklyPromiseNavigation.resolve(
      meta: promiseMeta,
      today: today,
      contentLinks: [exactScenarioLink()],
    );

    expect(resolution.kind, GyePromiseNavigationKind.todayFallback);
    expect(resolution.destination, today.destination);
  });

  test('does not choose an ambiguous promise scene link', () {
    final today = courseToday(activeUnit);
    final first = exactScenarioLink();
    final duplicate = ContentLink(
      id: '${first.id}_duplicate',
      contentKind: first.contentKind,
      contentId: first.contentId,
      courseUnitId: first.courseUnitId,
      conceptIds: first.conceptIds,
      role: first.role,
    );
    final resolution = GyeWeeklyPromiseNavigation.resolve(
      meta: promiseMeta,
      today: today,
      contentLinks: [first, duplicate],
    );

    expect(resolution.kind, GyePromiseNavigationKind.todayFallback);
    expect(resolution.destination, today.destination);
  });
}
