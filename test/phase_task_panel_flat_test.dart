import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/phase_task_panel.dart';

Future<void> _pump(WidgetTester tester, String phaseId, String locale) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Real asset I/O must finish outside the fake-async test zone.
  await tester.runAsync(() async {
    await LearningPhaseCatalog.load();
    await PhaseTaskCatalog.load();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(locale),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(child: PhaseTaskPanel(phaseId: phaseId)),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearningPhaseCatalog.resetForTesting();
    PhaseTaskCatalog.resetForTesting();
    CurriculumCatalog.reset();
    rootBundle.clear();
  });

  testWidgets('a Phase without steps stays one flat list', (tester) async {
    await _pump(tester, 'KP02', 'en');
    expect(find.byKey(const ValueKey('phase-next-step')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('phase-step-'),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('phase-task-KP02:'),
      ),
      findsWidgets,
    );
  });
}
