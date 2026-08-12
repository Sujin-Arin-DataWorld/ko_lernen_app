import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
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
      expect(brief.estimatedMinutesToScene, 4);
      expect(brief.totalStepCount, 3);
      expect(brief.remainingStepCount, 0);
      expect(brief.firstLink?.id, 'listen');
      expect(brief.targetScenario?.id, _scenario.id);
    },
  );

  test('brief collapses repeated phases and advances only after evidence', () {
    final firstVocab = _link('listen-one', CurriculumContentKind.vocab);
    final secondVocab = _link('listen-two', CurriculumContentKind.vocab);
    final grammar = _link('build', CurriculumContentKind.grammar);
    final scenario = _link('speak', CurriculumContentKind.scenario);
    final before = CourseMissionBrief.from(
      unit: _unit,
      links: [firstVocab, secondVocab, grammar, scenario],
      scenarios: const [_scenario],
      isCurrent: true,
    );

    expect(before.visibleSteps.map((step) => step.link.id), [
      'listen-one',
      'build',
      'speak',
    ]);
    expect(before.totalStepCount, 3);
    expect(before.estimatedMinutesToScene, 4);
    expect(before.firstLink?.id, 'listen-one');

    final after = CourseMissionBrief.from(
      unit: _unit,
      links: [firstVocab, secondVocab, grammar, scenario],
      scenarios: const [_scenario],
      isCurrent: true,
      snapshot: CourseMasterySnapshot(
        currentCourseUnitId: _unit.id,
        evidence: [
          MasteryEvidence(
            conceptId: 'concept-food',
            contentKind: CurriculumContentKind.vocab,
            contentId: firstVocab.contentId,
            courseUnitId: _unit.id,
            missionContentLinkId: firstVocab.id,
            isCorrect: true,
            occurredAt: DateTime.utc(2026, 8, 12),
            courseEligible: false,
            score: .8,
          ),
        ],
      ),
    );

    expect(after.visibleSteps.map((step) => step.link.id), ['build', 'speak']);
    expect(after.firstLink?.id, 'build');
    expect(after.estimatedMinutesToScene, 3);
  });

  test('a later wrong answer reopens the exact mission step', () {
    final vocab = _link('listen', CurriculumContentKind.vocab);
    final brief = CourseMissionBrief.from(
      unit: _unit,
      links: [vocab, _link('speak', CurriculumContentKind.scenario)],
      scenarios: const [_scenario],
      isCurrent: true,
      snapshot: CourseMasterySnapshot(
        currentCourseUnitId: _unit.id,
        evidence: [
          MasteryEvidence(
            conceptId: 'concept-food',
            contentKind: CurriculumContentKind.vocab,
            contentId: vocab.contentId,
            courseUnitId: _unit.id,
            missionContentLinkId: vocab.id,
            isCorrect: true,
            occurredAt: DateTime.utc(2026, 8, 12, 9),
            courseEligible: false,
            score: .8,
          ),
          MasteryEvidence(
            conceptId: 'concept-food',
            contentKind: CurriculumContentKind.vocab,
            contentId: vocab.contentId,
            courseUnitId: _unit.id,
            missionContentLinkId: vocab.id,
            isCorrect: false,
            occurredAt: DateTime.utc(2026, 8, 12, 10),
            courseEligible: false,
            score: .4,
          ),
        ],
      ),
    );

    expect(brief.firstLink?.id, 'listen');
  });

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
    expect(find.text('Hear the situation'), findsOneWidget);
    expect(find.text('Recognize the polite form'), findsOneWidget);
    expect(find.text('Build your sentence'), findsOneWidget);
    expect(find.text('Choose the missing words'), findsOneWidget);
    expect(find.text('Speak in the scene'), findsOneWidget);
    expect(find.text('One real answer, no guessing'), findsOneWidget);
    expect(find.text('1 min'), findsNWidgets(2));
    expect(find.text('2 min'), findsOneWidget);
    expect(find.textContaining('more step stays ready'), findsNothing);

    await tester.tap(find.text('Listen now'));
    await tester.pump();
    expect(opened?.id, 'listen');
  });
}
