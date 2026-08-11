import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/theme.dart';

const _unit = CourseUnit(
  id: 'a1_food',
  level: 'a1',
  order: 4,
  title: CurriculumText(
    ko: '음식 주문',
    de: 'Essen bestellen',
    en: 'Ordering food',
  ),
  canDo: CurriculumText(
    ko: '덜 맵게 부탁할 수 있어요.',
    de: 'Ich kann weniger scharf bestellen.',
    en: 'I can ask for less spicy food.',
  ),
);

const _scenario = Scenario(
  id: 'cafe_order',
  level: LearnerLevel.a1,
  emoji: '☕',
  register: Register.polite,
  title: LocalizedText(ko: '카페 주문', de: 'Im Café', en: 'At the café'),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
);

ContentLink _link(String id, CurriculumContentKind kind) => ContentLink(
  id: id,
  contentKind: kind,
  contentId: kind == CurriculumContentKind.scenario
      ? _scenario.id
      : 'content-$id',
  courseUnitId: _unit.id,
  conceptIds: const ['concept-food'],
  role: kind == CurriculumContentKind.scenario
      ? ContentLinkRole.assess
      : ContentLinkRole.practice,
);

void main() {
  test(
    'brief keeps displayed order, time, and first action on one contract',
    () {
      final brief = CourseMissionBrief.from(
        unit: _unit,
        links: [
          _link('listen', CurriculumContentKind.vocab),
          _link('build', CurriculumContentKind.grammar),
          _link('speak', CurriculumContentKind.scenario),
          _link('later', CurriculumContentKind.smalltalk),
        ],
        scenarios: const [_scenario],
        isCurrent: true,
      );

      expect(brief.visibleSteps.map((step) => step.link.id), [
        'listen',
        'build',
        'speak',
      ]);
      expect(brief.visibleSteps.map((step) => step.estimatedMinutes), [
        1,
        2,
        1,
      ]);
      expect(brief.visibleEstimatedMinutes, 4);
      expect(brief.totalStepCount, 4);
      expect(brief.remainingStepCount, 1);
      expect(brief.firstLink?.id, 'listen');
      expect(brief.targetScenario?.id, _scenario.id);
    },
  );

  testWidgets('preview screen starts the same first step it describes', (
    tester,
  ) async {
    final brief = CourseMissionBrief.from(
      unit: _unit,
      links: [
        _link('listen', CurriculumContentKind.vocab),
        _link('build', CurriculumContentKind.grammar),
        _link('speak', CurriculumContentKind.scenario),
        _link('later', CurriculumContentKind.smalltalk),
      ],
      scenarios: const [_scenario],
      isCurrent: true,
    );
    ContentLink? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: CourseMissionScreen.preview(
          brief: brief,
          openLink: (link) async => opened = link,
        ),
      ),
    );

    expect(find.text('A1 · Ordering food'), findsOneWidget);
    expect(find.text('Your next scene: At the café'), findsOneWidget);
    expect(find.text('Step 1 of 4 · 1 min'), findsOneWidget);
    expect(find.text('Step 2 of 4 · 2 min'), findsOneWidget);
    expect(find.text('Step 3 of 4 · 1 min'), findsOneWidget);
    expect(find.text('4 min to the scene'), findsOneWidget);
    expect(
      find.text('1 more step stays ready after this brief.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Start step 1'));
    await tester.pump();
    expect(opened?.id, 'listen');
  });
}
