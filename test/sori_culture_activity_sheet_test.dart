import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/activity_illustration.dart';
import 'package:ko_lernen_app/widgets/sori/activity_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  for (final locale in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$locale/$scale culture art follows the activity context', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final t = lookupAppL10n(Locale(locale));

        for (final id in [
          'smalltalk',
          'cloze',
          'daily_game',
          'syllable_cross',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(locale),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showSoriActivitySheet(
                      context,
                      entry: soriActivityCatalog.singleWhere((e) => e.id == id),
                      progress: null,
                      onStart: () {},
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Details'));
          await tester.pumpAndSettle();

          if (id == 'smalltalk') {
            expect(find.text(t.cultureHahoeMaskName), findsOneWidget);
            expect(find.text(t.cultureHahoeMaskHintKo), findsOneWidget);
            expect(find.text(t.cultureHahoeMaskHint), findsOneWidget);
            final mask = tester.widget<Image>(
              find.descendant(
                of: find.byKey(const ValueKey('culture-comment-hahoeMask')),
                matching: find.byType(Image),
              ),
            );
            expect((mask.image as AssetImage).assetName, SoriArtwork.hahoeMask);
            expect(mask.width, 64);
            expect(mask.height, 64);
            // The readable object name supplies semantics; the image must not
            // imply a separate speaking person or duplicate the label.
            expect(mask.excludeFromSemantics, isTrue);
          } else if (id == 'cloze') {
            expect(find.byType(SoriCultureComment), findsNothing);
          } else {
            expect(find.text(t.cultureDokkaebiName), findsOneWidget);
            expect(
              find.byKey(const ValueKey('culture-comment-dokkaebi')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull, reason: '$locale/$scale/$id');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
