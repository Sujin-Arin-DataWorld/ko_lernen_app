import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mission_context_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('scenario');
    ScenarioLoader.reset();
    CurriculumCatalog.reset();
  });

  testWidgets('shows mission context for its exact scenario link', (
    tester,
  ) async {
    late ContentLink link;
    late Scenario scenario;
    await tester.runAsync(() async {
      await ScenarioLoader.load();
      final catalog = await CurriculumCatalog.load();
      link = catalog.contentLinks.firstWhere((entry) {
        if (entry.contentKind != CurriculumContentKind.scenario ||
            entry.role != ContentLinkRole.assess ||
            !entry.courseUnitId.startsWith('a1_')) {
          return false;
        }
        final unit = catalog.courseUnitFor(entry.courseUnitId);
        final candidate = ScenarioLoader.byId(entry.contentId);
        return candidate?.level == LearnerLevel.a1 &&
            unit?.checkpointContentIds.contains(entry.contentKey) == true;
      });
      scenario = ScenarioLoader.byId(link.contentId)!;
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: scenario.id,
          courseContext: CoursePracticeContext.fromLink(link),
          scenarioLoader: (_) async => scenario,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MissionContextBar), findsOneWidget);
    expect(find.text('Current mission'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
