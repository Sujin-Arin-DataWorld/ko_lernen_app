import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/theme.dart';

final _fiveQuestScene = Scenario(
  id: 'airport_arrival_test',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항 입국',
    de: 'Einreise am Flughafen',
    en: 'Airport arrival',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: List.generate(
    5,
    (_) => const QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'correctIndex': 0,
        'options': [
          {'de': 'Richtig', 'en': 'Correct'},
          {'de': 'Falsch', 'en': 'Wrong'},
        ],
      },
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding completes once after all five quests are persisted', (
    tester,
  ) async {
    final saveGate = Completer<void>();
    var saveCalls = 0;
    var completionCalls = 0;
    ScenarioCompletionSummary? summary;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _fiveQuestScene.id,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          scenarioLoader: (_) async => _fiveQuestScene,
          resultPersister: (_, _, _) async {
            saveCalls++;
            await saveGate.future;
            return null;
          },
          onCompleted: (value) {
            completionCalls++;
            summary = value;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('quest-dont-know')), findsOneWidget);

    for (var index = 0; index < 5; index++) {
      expect(find.text('${index + 1} of 5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('answer-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quest-submit')));
      await tester.pump();
      expect(completionCalls, 0);
      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(saveCalls, 1);
    expect(completionCalls, 0);
    saveGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(completionCalls, 1);
    expect(summary?.passed, 5);
    expect(summary?.total, 5);
    expect(summary?.firstSuccess?.phrase, '한국 처음이세요?');
    await tester.pump(const Duration(seconds: 1));
    expect(completionCalls, 1);
  });

  testWidgets('production airport exposes no-credit help on all five quests', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ScenarioLoader.reset();
    late Scenario airport;
    await tester.runAsync(() async {
      await ScenarioLoader.load();
      airport = ScenarioLoader.byId('airport_arrival')!;
    });

    ScenarioCompletionSummary? summary;
    var saveCalls = 0;
    var evidenceCalls = 0;
    CourseActivityReporter.recordContentAttemptForTesting =
        (kind, contentId, isCorrect, context, error, conceptId, score) async {
          evidenceCalls++;
          throw StateError('onboarding must not write course evidence');
        };
    addTearDown(CourseActivityReporter.resetOverridesForTesting);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: airport.id,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          scenarioLoader: (_) async => airport,
          resultPersister: (_, _, _) async {
            saveCalls++;
            return null;
          },
          onCompleted: (value) => summary = value,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (var index = 0; index < airport.quests.length; index++) {
      expect(find.text('${index + 1} of 5'), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-dont-know')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quest-dont-know')));
      await tester.pump();
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(saveCalls, 1);
    expect(summary?.passed, 0);
    expect(summary?.total, 5);
    expect(summary?.firstSuccess, isNull);
    expect(evidenceCalls, 0);
  });
}
