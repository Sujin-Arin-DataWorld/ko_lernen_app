import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/can_do_result_card.dart';

const _unit = CourseUnit(
  id: 'a1_01',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Gruß', en: 'Greeting'),
  canDo: CurriculumText(
    ko: '처음 만난 사람에게 인사할 수 있어요.',
    de: 'Ich kann eine neue Person begrüßen.',
    en: 'I can greet someone new.',
  ),
);

const _scenario = Scenario(
  id: 'result-flow-scenario',
  level: LearnerLevel.a1,
  emoji: '🐯',
  register: Register.polite,
  title: LocalizedText(ko: '인사', de: 'Gruß', en: 'Greeting'),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(speaker: 'guide', ko: '안녕', de: 'Hallo', en: 'Hello'),
    DialogLine(speaker: 'User', ko: '안녕하세요.', de: 'Guten Tag.', en: 'Hello.'),
  ],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '안녕',
        'correctIndex': 0,
        'options': [
          {'de': 'Correct response', 'en': 'Correct response'},
        ],
      },
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 900);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_scenario': true});
    await Storage.init();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  test('first-correct gate reports once per current screen attempt', () {
    final gate = FirstCorrectAttemptGate();

    expect(gate.accept(correct: false), isFalse);
    expect(gate.accept(correct: true), isTrue);
    expect(gate.accept(correct: true), isFalse);
  });

  test('first-success copy is derived from the exact completed quest', () {
    final heard = scenarioFirstSuccessForQuest(
      const QuestSpec(
        type: QuestType.hoerverstehen,
        data: {'audioKo': '한국 처음이세요?'},
      ),
    );
    final completed = scenarioFirstSuccessForQuest(
      const QuestSpec(
        type: QuestType.particlePop,
        data: {
          'prefix': '저',
          'suffix': ' 레나예요.',
          'options': ['은', '는'],
          'correctIndex': 1,
        },
      ),
    );

    expect(heard?.phrase, '한국 처음이세요?');
    expect(heard?.kind, ScenarioFirstSuccessKind.listening);
    expect(completed?.phrase, '저는 레나예요.');
    expect(completed?.kind, ScenarioFirstSuccessKind.completion);
  });

  testWidgets('system back delegates to the explicit scenario exit', (
    tester,
  ) async {
    var exitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _scenario.id,
          scenarioLoader: (_) async => _scenario,
          onExit: () => exitCalls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();

    expect(exitCalls, 1);
    expect(find.byType(ScenarioPlayerScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(exitCalls, 1);
  });

  testWidgets('saves once, then shows the persisted can-do before returning', (
    tester,
  ) async {
    var saveCalls = 0;
    var completionCalls = 0;
    ScenarioFirstSuccess? firstSuccess;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _scenario.id,
          onCompleted: (summary) {
            completionCalls++;
            firstSuccess = summary.firstSuccess;
          },
          scenarioLoader: (_) async => _scenario,
          resultPersister: (_, _, _) async {
            saveCalls++;
            return const ScenarioCanDoResult(
              status: ScenarioCanDoStatus.verified,
              score: 1,
              courseUnit: _unit,
              structureStageBefore: HanokStage.foundation,
              structureStageAfter: HanokStage.pillars,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _tapText(tester, "Los geht's!");
    await _advanceUntilText(tester, 'Correct response');
    await _tapText(tester, 'Correct response');
    await tester.pump();
    expect(completionCalls, 0);
    await _tapText(tester, 'Überprüfen');
    await tester.pump();
    expect(completionCalls, 0);
    await _tapText(tester, 'Ergebnis ansehen');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.pump(const Duration(milliseconds: 500));

    expect(saveCalls, 1);
    expect(completionCalls, 1);
    expect(firstSuccess?.phrase, '안녕');
    expect(firstSuccess?.kind, ScenarioFirstSuccessKind.listening);
    expect(find.byType(CanDoResultCard), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.text('Du kannst jetzt zum Hanok zurück.'), findsOneWidget);
    expect(find.text('Das kannst du jetzt.'), findsOneWidget);
    expect(find.text('Dein Hanok hat sich verändert.'), findsOneWidget);
    expect(find.textContaining('Säulen aufstellen'), findsOneWidget);
    expect(find.text('안녕하세요.'), findsOneWidget);
    expect(
      find.text(
        'Deine Übung ist gespeichert und steht für die Wiederholung bereit.',
      ),
      findsOneWidget,
    );
    expect(find.text('Zurück zum Hanok'), findsOneWidget);
    expect(find.text('Diese Szene noch einmal üben'), findsOneWidget);
    expect(find.text('Zurück zu meinem Weg'), findsNothing);
    expect(find.text('Abschließen'), findsNothing);
  });
}

Future<void> _advanceUntilText(
  WidgetTester tester,
  String target, {
  int maxSteps = 5,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text(target).evaluate().isNotEmpty) return;
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }
  expect(find.text(target), findsWidgets);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
}
