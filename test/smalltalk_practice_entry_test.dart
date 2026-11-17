import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_scholar_art.dart';
import 'package:ko_lernen_app/widgets/smalltalk_practice_entry.dart';

void main() {
  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final textScale in const [1.0, 2.0]) {
      testWidgets('Smalltalk entry preserves art slot and level route '
          '${locale.languageCode} at $textScale', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SmalltalkContextRequest? request;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: textScale,
              maxScaleFactor: textScale,
              child: const Scaffold(
                bottomNavigationBar: SmalltalkPracticeEntry(level: 'B2'),
              ),
            ),
            routes: {
              '/smalltalk/context': (context) {
                request =
                    ModalRoute.of(context)!.settings.arguments
                        as SmalltalkContextRequest;
                return const Scaffold(body: Text('context destination'));
              },
            },
          ),
        );
        await tester.pump();
        final art = find.byType(PracticeScholarArt);
        expect(
          tester.widget<PracticeScholarArt>(art).pose,
          PracticeScholarPose.inviting,
        );
        expect(tester.getSize(art), const Size(32, 48));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('smalltalk-context-entry')));
        await tester.pumpAndSettle();
        expect(find.text('context destination'), findsOneWidget);
        expect(request!.level, 'b2');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
