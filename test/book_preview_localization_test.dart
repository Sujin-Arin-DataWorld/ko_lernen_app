import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';

void main() {
  testWidgets('book preview text field hint follows the app locale', (
    tester,
  ) async {
    const expectations = <(Locale, String)>[
      (Locale('de'), 'Koreanischer Text …'),
      (Locale('en'), 'Korean text…'),
    ];

    for (final entry in expectations) {
      await tester.pumpWidget(
        MaterialApp(
          locale: entry.$1,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const BookPreviewScreen(
            args: <String, dynamic>{'text': '', 'blockCount': 0},
          ),
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, entry.$2);
    }
  });
}
