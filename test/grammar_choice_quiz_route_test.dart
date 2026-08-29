import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  testWidgets('actual grammar-choice route normalizes plan maps safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
      ),
    );
    await tester.pump();
    for (
      var frame = 0;
      frame < 20 && find.byType(GrammarChoiceQuizScreen).evaluate().isEmpty;
      frame++
    ) {
      if (find.byType(Navigator).evaluate().isNotEmpty &&
          find.byType(GrammarChoiceQuizScreen).evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pushNamed(
      '/grammar_choice_quiz',
      arguments: <String, dynamic>{
        'level': 'A1',
        'planDayLabel': 'Day 4',
        'allowedTargetIds': <Object>['grammar_a1_one', 42, 'grammar_a1_two'],
      },
    );
    await tester.pump(const Duration(milliseconds: 350));

    var screen = tester.widget<GrammarChoiceQuizScreen>(
      find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
    );
    expect(screen.initialLevel, 'A1');
    expect(screen.planDayLabel, 'Day 4');
    expect(screen.allowedTargetIds, <String>{
      'grammar_a1_one',
      'grammar_a1_two',
    });

    navigator.pop();
    await tester.pump();
    navigator.pushNamed(
      '/grammar_choice_quiz',
      arguments: <String, dynamic>{'allowedTargetIds': <String>[]},
    );
    await tester.pump(const Duration(milliseconds: 350));
    screen = tester.widget<GrammarChoiceQuizScreen>(
      find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
    );
    expect(screen.allowedTargetIds, isEmpty);
    expect(screen.initialLevel, isNull);

    navigator.pop();
    await tester.pump();
    navigator.pushNamed(
      '/grammar_choice_quiz',
      arguments: <String, dynamic>{
        'level': 1,
        'planDayLabel': true,
        'allowedTargetIds': <String, String>{'not': 'an iterable'},
      },
    );
    await tester.pump(const Duration(milliseconds: 350));
    screen = tester.widget<GrammarChoiceQuizScreen>(
      find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
    );
    expect(screen.initialLevel, isNull);
    expect(screen.planDayLabel, isNull);
    expect(screen.allowedTargetIds, isNull);

    navigator.pop();
    await tester.pump();
    navigator.pushNamed('/grammar_choice_quiz');
    await tester.pump(const Duration(milliseconds: 350));
    screen = tester.widget<GrammarChoiceQuizScreen>(
      find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
    );
    expect(screen.initialLevel, isNull);
    expect(screen.planDayLabel, isNull);
    expect(screen.allowedTargetIds, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
