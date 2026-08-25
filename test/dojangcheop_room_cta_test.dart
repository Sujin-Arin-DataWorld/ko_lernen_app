import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_stamps_earned': <String>['lotus'],
      'kl_tut_dojang': true,
    });
    await Storage.init();
  });

  testWidgets('earned stamps link to the free room editor and are named', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        routes: {
          '/': (_) => const DojangcheopScreen(),
          '/sarangbang/furnish': (_) =>
              const Scaffold(body: Text('free-room-editor')),
        },
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Lotus dancheong, collected'), findsOneWidget);
    await tester.tap(find.text('Decorate the Sarangbang'));
    await tester.pumpAndSettle();

    expect(find.text('free-room-editor'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'album exposes both named series and locked living-culture stamps',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const DojangcheopScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Dancheong patterns'), findsOneWidget);
      expect(find.text('Korean everyday culture'), findsOneWidget);
      expect(find.text('Soban table'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Soban table, not collected yet'),
        findsOneWidget,
      );

      semantics.dispose();
    },
  );
}
