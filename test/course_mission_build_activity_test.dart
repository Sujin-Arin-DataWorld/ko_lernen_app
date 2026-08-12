import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    CourseActivityReporter.resetOverridesForTesting();
  });

  tearDown(CourseActivityReporter.resetOverridesForTesting);

  testWidgets('real A1 typed cloze answer advances build to scene', (
    tester,
  ) async {
    final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
    final scenarios = (await tester.runAsync(ScenarioLoader.load))!;
    final unit = catalog.courseUnitFor('a1_01_greetings_hangul')!;
    final links = catalog.linksForCourseUnit(unit.id);
    final vocabLink = links.firstWhere(
      (link) => link.contentKind == CurriculumContentKind.vocab,
    );
    final service = CourseMasteryService(catalog);
    await service.initializeForPlacement('a1');
    await service.recordContentAttempt(
      CurriculumContentKind.vocab,
      vocabLink.contentId,
      true,
      courseContext: CoursePracticeContext.fromLink(vocabLink),
      score: unit.passThreshold,
    );

    final afterPack = CourseMissionBrief.from(
      unit: unit,
      links: links,
      scenarios: scenarios,
      isCurrent: true,
      snapshot: service.snapshot,
    );
    final buildLink = afterPack.firstLink!;
    expect(afterPack.visibleSteps.first.phase, CourseMissionPhase.build);
    expect(buildLink.contentKind, CurriculumContentKind.cloze);

    final allCloze = (await tester.runAsync(ClozeLoader.load))!;
    final linkedIds = links
        .where((link) => link.contentKind == CurriculumContentKind.cloze)
        .map((link) => link.contentId)
        .toSet();
    final linkedCloze = allCloze
        .where((item) => linkedIds.contains(item.id))
        .toList(growable: false);
    final requestedItem = linkedCloze.firstWhere(
      (item) => item.id == buildLink.contentId,
    );
    final recorded = Completer<CourseUpdate>();
    CourseActivityReporter.recordContentAttemptForTesting =
        (
          kind,
          contentId,
          isCorrect,
          courseContext,
          errorReason,
          conceptId,
          score,
        ) async {
          final update = await service.recordContentAttempt(
            kind,
            contentId,
            isCorrect,
            courseContext: courseContext,
            errorReason: errorReason,
            conceptId: conceptId,
            score: score,
          );
          if (!recorded.isCompleted) recorded.complete(update);
          return update;
        };

    await tester.pumpWidget(
      _host(
        ClozeGameScreen(
          items: linkedCloze,
          courseContext: CoursePracticeContext.fromLink(buildLink),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final prompt = tester.widget<ClozePromptCard>(find.byType(ClozePromptCard));
    expect(prompt.item.id, requestedItem.id);
    final answer = find.byWidgetPredicate(
      (widget) => widget is QuizChoice && widget.text == requestedItem.answer,
    );
    expect(answer, findsOneWidget);
    await tester.tap(answer);
    await tester.pump();
    final update = await tester.runAsync(
      () => recorded.future.timeout(const Duration(seconds: 5)),
    );

    expect(update, isNotNull);
    expect(update!.snapshot.evidence.last.courseEligible, isFalse);
    expect(update.snapshot.evidence.last.courseUnitId, unit.id);
    expect(update.snapshot.evidence.last.missionContentLinkId, buildLink.id);
    final afterBuild = CourseMissionBrief.from(
      unit: unit,
      links: links,
      scenarios: scenarios,
      isCurrent: true,
      snapshot: update.snapshot,
    );
    expect(afterBuild.visibleSteps.first.phase, CourseMissionPhase.scene);
    expect(afterBuild.firstLink?.contentKind, CurriculumContentKind.scenario);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('legacy scoped cloze remains browse history', (tester) async {
    final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
    final unit = catalog.courseUnitFor('a1_01_greetings_hangul')!;
    final links = catalog.linksForCourseUnit(unit.id);
    final buildLink = links.firstWhere(
      (link) => link.contentKind == CurriculumContentKind.cloze,
    );
    final requestedItem = (await tester.runAsync(
      ClozeLoader.load,
    ))!.firstWhere((item) => item.id == buildLink.contentId);
    final service = CourseMasteryService(catalog);
    await service.initializeForPlacement('a1');
    final recorded = Completer<CourseUpdate>();
    CourseActivityReporter.recordContentAttemptForTesting =
        (
          kind,
          contentId,
          isCorrect,
          courseContext,
          errorReason,
          conceptId,
          score,
        ) async {
          expect(courseContext, isNull);
          final update = await service.recordContentAttempt(
            kind,
            contentId,
            isCorrect,
            courseContext: courseContext,
            errorReason: errorReason,
            conceptId: conceptId,
            score: score,
          );
          if (!recorded.isCompleted) recorded.complete(update);
          return update;
        };

    await tester.pumpWidget(
      _host(ClozeGameScreen(items: [requestedItem], courseUnitId: unit.id)),
    );
    await tester.pumpAndSettle();
    final answer = find.byWidgetPredicate(
      (widget) => widget is QuizChoice && widget.text == requestedItem.answer,
    );
    await tester.tap(answer);
    await tester.pump();
    final update = await tester.runAsync(
      () => recorded.future.timeout(const Duration(seconds: 5)),
    );

    expect(update, isNotNull);
    expect(update!.snapshot.evidence.last.courseEligible, isFalse);
    expect(update.snapshot.evidence.last.courseUnitId, isNull);
    expect(update.snapshot.evidence.last.missionContentLinkId, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(size: Size(800, 1280), disableAnimations: true),
    child: child,
  ),
);
