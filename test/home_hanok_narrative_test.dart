import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

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

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('shows the read-only verified can-do beside the existing Hanok', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox()),
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: HomeScreen(
            loadTodaySnapshot: () async => TodayLearningSnapshot(
              pick: const ReviewPick(dueCount: 1),
              dueCount: 1,
            ),
            loadHanokRatios: () async =>
                const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
            loadHanokProjection: (ratios) async =>
                PersonalHanokProjection.from(ratios),
            loadHanokNarrative: (projection) async =>
                HanokBuildNarrative.fromSnapshot(
                  projection: projection,
                  snapshot: const CourseMasterySnapshot(
                    completedUnitIds: ['a1_01'],
                  ),
                  courseUnits: [_unit],
                ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows course-backed structure when legacy packs are empty', (
    tester,
  ) async {
    final projection = _courseFoundationProjection();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox()),
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: HomeScreen(
            loadTodaySnapshot: () async => TodayLearningSnapshot(
              pick: const ReviewPick(dueCount: 1),
              dueCount: 1,
            ),
            loadHanokRatios: () async =>
                const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
            loadHanokProjection: (_) async => projection,
            loadHanokNarrative: (_) async => HanokBuildNarrative.fromSnapshot(
              projection: projection,
              snapshot: const CourseMasterySnapshot(
                completedUnitIds: ['a1_01'],
              ),
              courseUnits: [_unit],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      findsOneWidget,
    );
  });
}

PersonalHanokProjection _courseFoundationProjection() =>
    PersonalHanokProjection.from(
      const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      competence: HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot(completedUnitIds: ['a1_01']),
        courseUnits: [
          _unit,
          for (var index = 2; index <= 4; index++)
            CourseUnit(
              id: 'a1_0$index',
              level: 'a1',
              order: index,
              title: _unit.title,
              canDo: _unit.canDo,
            ),
        ],
      ),
    );
