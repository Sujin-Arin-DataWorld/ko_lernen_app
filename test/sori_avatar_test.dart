import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/avatar.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
  });

  for (final language in ['de', 'en']) {
    testWidgets('$language header follows companion changes and restart', (
      tester,
    ) async {
      await tester.pumpWidget(_app(language));
      expect(tester.widget<Mascot>(find.byType(Mascot)).kind, MascotKind.tiger);

      await MascotPreference.set(MascotKind.magpie);
      await tester.pump();
      expect(
        tester.widget<Mascot>(find.byType(Mascot)).kind,
        MascotKind.magpie,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      MascotPreference.preference.value = CompanionPreference.tiger;
      MascotPreference.load();
      await tester.pumpWidget(_app(language));
      expect(
        tester.widget<Mascot>(find.byType(Mascot)).kind,
        MascotKind.magpie,
      );

      await MascotPreference.setNone();
      await tester.pump();
      expect(find.byType(Mascot), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(MascotPreference.chosenKind, MascotKind.magpie);

      final semantics = tester.ensureSemantics();
      final t = AppL10n.of(tester.element(find.byType(SoriAvatar)));
      expect(find.bySemanticsLabel(t.soriStageProfileTooltip), findsOneWidget);
      expect(tester.getSize(find.byType(SoriAvatar)), const Size(48, 48));
      await tester.tap(find.byType(SoriAvatar));
      await tester.pumpAndSettle();
      expect(find.text('Profile destination'), findsOneWidget);
      semantics.dispose();
    });
  }
}

Widget _app(String language) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(language),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  routes: {
    '/profile': (_) => const Scaffold(body: Text('Profile destination')),
  },
  home: const Scaffold(body: Center(child: SoriAvatar())),
);
