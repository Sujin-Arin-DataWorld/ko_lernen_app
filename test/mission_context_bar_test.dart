import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mission_step_plan.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/widgets/sori/mission_context_bar.dart';

void main() {
  testWidgets('states the mission and the exact graph-link position', (
    tester,
  ) async {
    final link = ContentLink(
      id: 'a1-01-grammar',
      contentKind: CurriculumContentKind.grammar,
      contentId: 'grammar-a',
      courseUnitId: 'a1-01',
      conceptIds: ['concept-a'],
      role: ContentLinkRole.assess,
    );
    final step = CourseMissionStep(link: link, index: 1, total: 3);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MissionContextBar(
            missionTitle: 'Ordering at a cafe',
            step: step,
          ),
        ),
      ),
    );

    expect(find.text('Current mission'), findsOneWidget);
    expect(find.text('Ordering at a cafe'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Current mission: Ordering at a cafe'),
      findsOneWidget,
    );
  });

  testWidgets('fits German progress copy at 308dp and 1.3x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final link = ContentLink(
      id: 'preview-less-spicy-assess',
      contentKind: CurriculumContentKind.scenario,
      contentId: 'preview_less_spicy',
      courseUnitId: 'a1_preview_less_spicy',
      conceptIds: ['request_less_spicy'],
      role: ContentLinkRole.assess,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('de'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MissionContextBar(
                missionTitle: 'Weniger scharf bestellen',
                step: CourseMissionStep(link: link, index: 2, total: 3),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Aktuelle Mission'), findsOneWidget);
    expect(find.text('Schritt 3 von 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
