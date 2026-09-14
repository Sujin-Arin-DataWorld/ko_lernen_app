import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hanok_preview_screen.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  testWidgets('all unfinished Hanok deep links show the safe preview', (
    tester,
  ) async {
    for (final route in const ['/hanok', '/hanok/anbang', '/hanok/daecheong']) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(route),
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          initialRoute: route,
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute<void>(
                builder: (_) => const SizedBox.shrink(),
                settings: settings,
              );
            }
            return buildHanokPreviewRoute(settings);
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HanokPreviewScreen), findsOneWidget, reason: route);
      expect(find.byType(IlDuWorldScreen), findsNothing, reason: route);
    }

    expect(tester.takeException(), isNull);
  });
}
