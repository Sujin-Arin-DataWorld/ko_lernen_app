import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
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
  dialog: [],
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

  testWidgets('saves once, then shows the persisted can-do before returning', (
    tester,
  ) async {
    var saveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _scenario.id,
          scenarioLoader: (_) async => _scenario,
          resultPersister: (_, _, _) async {
            saveCalls++;
            return const ScenarioCanDoResult(
              status: ScenarioCanDoStatus.verified,
              score: 1,
              courseUnit: _unit,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _tapText(tester, "Los geht's!");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _tapText(tester, 'Correct response');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1201));
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Abschließen'), findsOneWidget);
    expect(find.byType(CanDoResultCard), findsNothing);

    await _tapText(tester, 'Abschließen');
    await tester.pump();

    expect(saveCalls, 1);
    expect(find.byType(CanDoResultCard), findsOneWidget);
    expect(find.text('Du kannst jetzt zum Hanok zurück.'), findsOneWidget);
    expect(find.text('Das kannst du jetzt.'), findsOneWidget);
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

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
}
