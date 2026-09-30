import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';

import 'support/scenario_stock_fixtures.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_scenario': true});
    await Storage.init();
  });

  for (final locale in ['de', 'en']) {
    testWidgets('$locale direct route with four items cannot start or reward', (
      tester,
    ) async {
      final speech = stubSoriSpeech();
      final corpus = List.generate(4, scene);
      var exits = 0;
      var completions = 0;
      await tester.pumpWidget(
        _app(
          locale,
          ScenarioPlayerScreen(
            scenarioId: corpus.first.id,
            scenarioLoader: (_) async => corpus.first,
            questCorpusLoader: (_) async => corpus,
            onCompleted: (_) => completions++,
            onExit: () => exits++,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SoriEmptyState), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
      expect(speech.spoken, isEmpty);
      expect(speech.prefetched, isEmpty);
      expect(Storage.xp, 0);
      expect(Storage.completedScenarios, isEmpty);
      expect(completions, 0);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.bySemanticsLabel(locale == 'de' ? 'Schließen' : 'Close'),
      );
      await tester.pump();
      expect(exits, 1);
      expect(completions, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('five distinct questions allow the existing intro', (
    tester,
  ) async {
    stubSoriSpeech();
    CourseProgressService.shared.resetForTesting();
    await tester.runAsync(() => CurriculumCatalog.load());
    final corpus = List.generate(5, scene);
    await tester.pumpWidget(
      _app(
        'en',
        ScenarioPlayerScreen(
          scenarioId: corpus.first.id,
          scenarioLoader: (_) async => corpus.first,
          questCorpusLoader: (_) async => corpus,
          grammarLoader: () async => [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SoriEmptyState), findsNothing);
    expect(find.text("Let's go"), findsOneWidget);
    expect(Storage.xp, 0);
    expect(Storage.completedScenarios, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stock read failure retries without progress or fake completion',
    (tester) async {
      final speech = stubSoriSpeech();
      CourseProgressService.shared.resetForTesting();
      await tester.runAsync(() => CurriculumCatalog.load());
      final corpus = List.generate(5, scene);
      var reads = 0;
      await tester.pumpWidget(
        _app(
          'en',
          ScenarioPlayerScreen(
            scenarioId: corpus.first.id,
            scenarioLoader: (_) async => corpus.first,
            questCorpusLoader: (_) async {
              if (++reads == 1) {
                throw StateError('stock read failed');
              }
              return corpus;
            },
            grammarLoader: () async => [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text("Let's go"), findsNothing);
      expect(speech.spoken, isEmpty);
      expect(speech.prefetched, isEmpty);
      expect(Storage.xp, 0);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(reads, 2);
      expect(find.text("Let's go"), findsOneWidget);
      expect(Storage.completedScenarios, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late stock response after exit cannot speak or reward', (
    tester,
  ) async {
    final speech = stubSoriSpeech();
    CourseProgressService.shared.resetForTesting();
    await tester.runAsync(() => CurriculumCatalog.load());
    final corpus = List.generate(5, scene);
    final pending = Completer<List<Scenario>>();
    await tester.pumpWidget(
      _app(
        'en',
        ScenarioPlayerScreen(
          scenarioId: corpus.first.id,
          scenarioLoader: (_) async => corpus.first,
          questCorpusLoader: (_) => pending.future,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(corpus);
    await tester.pump();
    expect(speech.spoken, isEmpty);
    expect(speech.prefetched, isEmpty);
    expect(Storage.xp, 0);
    expect(Storage.completedScenarios, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding cannot skip a sparse assessment gate', (
    tester,
  ) async {
    final speech = stubSoriSpeech();
    final corpus = List.generate(4, scene);
    var completions = 0;
    await tester.pumpWidget(
      _app(
        'en',
        ScenarioPlayerScreen(
          scenarioId: corpus.first.id,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          scenarioLoader: (_) async => corpus.first,
          questCorpusLoader: (_) async => corpus,
          onCompleted: (_) => completions++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SoriEmptyState), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
    expect(speech.spoken, isEmpty);
    expect(completions, 0);
    expect(Storage.xp, 0);
    expect(Storage.completedScenarios, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(String locale, Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: child,
);
