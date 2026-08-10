import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_step_plan.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/course_mission_path_overview.dart';

void main() {
  ContentLink link(
    String id,
    CurriculumContentKind kind,
    ContentLinkRole role,
  ) => ContentLink(
    id: id,
    contentKind: kind,
    contentId: 'content-$id',
    courseUnitId: 'a1-01',
    conceptIds: ['concept-$id'],
    role: role,
  );

  testWidgets('keeps the first graph links visible before optional details', (
    tester,
  ) async {
    final plan = CourseMissionStepPlan.fromLinks([
      link('one', CurriculumContentKind.vocab, ContentLinkRole.introduce),
      link('two', CurriculumContentKind.grammar, ContentLinkRole.practice),
      link('three', CurriculumContentKind.scenario, ContentLinkRole.assess),
      link('four', CurriculumContentKind.smalltalk, ContentLinkRole.review),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: CourseMissionPathOverview(steps: plan.steps)),
      ),
    );

    expect(find.text('Your mission path'), findsOneWidget);
    expect(find.textContaining('1. Introduced'), findsOneWidget);
    expect(find.textContaining('2. Practice'), findsOneWidget);
    expect(find.textContaining('3. Check your understanding'), findsOneWidget);
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.textContaining('4. Quick repair'), findsNothing);
  });
}
