import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/course_progress_evidence_note.dart';

void main() {
  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets('states the evidence boundary in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const Scaffold(body: CourseProgressEvidenceNote()),
        ),
      );

      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
      expect(find.textContaining('70'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
