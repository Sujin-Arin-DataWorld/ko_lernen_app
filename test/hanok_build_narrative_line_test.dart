import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_build_narrative_line.dart';

const _unit = CourseUnit(
  id: 'a1_01',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greeting'),
  canDo: CurriculumText(
    ko: '인사할 수 있어요.',
    de: 'Ich kann jemanden begrüßen.',
    en: 'I can greet someone.',
  ),
);

final _projection = PersonalHanokProjection.from(
  const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
);

final _courseProjection = PersonalHanokProjection.from(
  const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  competence: HanokCompetenceProjection.fromSnapshot(
    snapshot: const CourseMasterySnapshot(completedUnitIds: ['a1_01']),
    courseUnits: [
      _unit,
      CourseUnit(
        id: 'a1_02',
        level: 'a1',
        order: 2,
        title: _unit.title,
        canDo: _unit.canDo,
      ),
      CourseUnit(
        id: 'a1_03',
        level: 'a1',
        order: 3,
        title: _unit.title,
        canDo: _unit.canDo,
      ),
      CourseUnit(
        id: 'a1_04',
        level: 'a1',
        order: 4,
        title: _unit.title,
        canDo: _unit.canDo,
      ),
    ],
  ),
);

Widget _app(HanokBuildNarrative narrative) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: HanokBuildNarrativeLine(narrative: narrative)),
);

void main() {
  testWidgets('names a verified can-do without rewriting the structure stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HanokBuildNarrative.fromSnapshot(
          projection: _projection,
          snapshot: const CourseMasterySnapshot(completedUnitIds: ['a1_01']),
          courseUnits: [_unit],
        ),
      ),
    );

    expect(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Course scenes shape the structure. Packs, reviews, and quests add materials and decor.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the next can-do when no completed course unit exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HanokBuildNarrative.fromSnapshot(
          projection: _projection,
          snapshot: const CourseMasterySnapshot(currentCourseUnitId: 'a1_01'),
          courseUnits: [_unit],
        ),
      ),
    );

    expect(
      find.text(
        'Structure: Laying foundation stones. Next: I can greet someone.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses verified course structure instead of a lower pack stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HanokBuildNarrative.fromSnapshot(
          projection: _courseProjection,
          snapshot: const CourseMasterySnapshot(completedUnitIds: ['a1_01']),
          courseUnits: [_unit],
        ),
      ),
    );

    expect(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      findsOneWidget,
    );
  });
}
