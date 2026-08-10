import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_gye_tab': true});
    await Storage.init();
  });

  testWidgets('empty Gye landing makes participation and visibility optional', (
    tester,
  ) async {
    await _pump(tester, () async => const <GyeMeta>[]);

    expect(
      find.text('Allein lernen ist vollständig. Zusammen kann es wärmer sein.'),
      findsOneWidget,
    );
    expect(find.text('Was andere sehen können'), findsOneWidget);
    expect(find.textContaining('niemals deine Antworten'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gye erstellen'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gye erstellen'), findsOneWidget);
    expect(find.text('Mit Code beitreten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing Gye list keeps the optional shared-courtyard context', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => const [
        GyeMeta(
          id: 'ABC234',
          name: 'Mondhof',
          code: 'ABC234',
          ownerId: 'owner',
        ),
      ],
    );

    expect(find.text('Euer Hof'), findsOneWidget);
    expect(find.textContaining('Wochenziel-Daten'), findsOneWidget);
    expect(find.text('Mondhof'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Future<List<GyeMeta>> Function() loadGyeMetas,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: GyeTabScreen(loadGyeMetas: loadGyeMetas),
    ),
  );
  // The existing shared-hanok preview intentionally has a repeating pulse,
  // so `pumpAndSettle` would never terminate here.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
