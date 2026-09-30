import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    DataLoader.reset();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_grammar': true,
      'kl_tut_soriDeck': true,
    });
    await Storage.init();
    await DataLoader.loadGrammar();
  });

  test('grammar route retains typed course provenance and rejects bad IDs', () {
    const context = CoursePracticeContext(
      courseUnitId: 'a1_03_topic_subject_particles',
      contentKind: CurriculumContentKind.grammar,
      initialContentId: 'grammar_a1_topic_particle',
      contentLinkId: 'test-link',
    );
    final course = GrammarScreen.fromRouteArguments(context);
    expect(course.courseContext, same(context));
    expect(course.initialGrammarId, isNull);
    for (final bad in [
      null,
      12,
      'grammar_a2_ability',
      {'grammarId': 42},
      {'grammarId': '  '},
      {'courseContext': context},
    ]) {
      final screen = GrammarScreen.fromRouteArguments(bad);
      expect(screen.initialGrammarId, isNull);
      expect(screen.courseContext, isNull);
    }
  });

  for (final completedPlan in [false, true]) {
    testWidgets(
      'unknown direct ID shows no unrelated card, completedPlan=$completedPlan',
      (tester) async {
        if (completedPlan) {
          final rows = (await DataLoader.loadGrammar())
              .where((g) => g.level == 'A1')
              .toList();
          await Storage.setGrammarPlanRawJson(
            GrammarPlanService.encodePlans({
              'a1': GrammarStudyPlan(
                level: 'a1',
                itemsPerDay: 10,
                servedIdsByDate: {
                  for (var i = 0; i * 10 < rows.length; i++)
                    DateTime(2026, 1, i + 1).toIso8601String().substring(0, 10):
                        rows.skip(i * 10).take(10).map((g) => g.id).toList(),
                },
              ),
            }),
          );
        }
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: GrammarScreen.fromRouteArguments({
              'grammarId': 'removed-card',
            }),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(FlipCard), findsNothing);
        expect(
          find.text(lookupAppL10n(const Locale('en')).emptyGrammar),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('grammar-plan-onboarding-sheet')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets('actual application route forwards the canonical grammar ID', (
    tester,
  ) async {
    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
      ),
    );
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(
      '/grammar',
      arguments: {'grammarId': 'grammar_a2_ability'},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final screen = tester.widget<GrammarScreen>(
      find.byType(GrammarScreen, skipOffstage: false),
    );
    expect(screen.initialGrammarId, 'grammar_a2_ability');
    expect(screen.courseContext, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
