import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hanok_preview_screen.dart';
import 'package:ko_lernen_app/screens/ildu_world_screen.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
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
      await tester.pumpAndSettle();

      expect(find.byType(HanokPreviewScreen), findsOneWidget, reason: route);
      expect(find.byType(IlDuWorldScreen), findsNothing, reason: route);
    }

    expect(tester.takeException(), isNull);
  });
}
