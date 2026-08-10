import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario_can_do_result.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/can_do_result_card.dart';

void main() {
  const unit = CourseUnit(
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

  Future<void> pumpCard(WidgetTester tester, ScenarioCanDoResult result) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Scaffold(body: CanDoResultCard(result: result)),
        ),
      );

  testWidgets('shows the can-do statement only for verified evidence', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const ScenarioCanDoResult(
        status: ScenarioCanDoStatus.verified,
        score: .7,
        courseUnit: unit,
      ),
    );

    expect(find.text('You can do this now.'), findsOneWidget);
    expect(find.text('I can greet someone new.'), findsOneWidget);
  });

  testWidgets('does not turn practice-only history into a can-do claim', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const ScenarioCanDoResult(
        status: ScenarioCanDoStatus.practiceOnly,
        score: 1,
      ),
    );

    expect(find.text('Practice saved.'), findsOneWidget);
    expect(find.text('I can greet someone new.'), findsNothing);
  });
}
