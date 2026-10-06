import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/media_phrase_link.dart';
import 'package:ko_lernen_app/widgets/sori/study_library_button.dart';
import 'support/catalog_test_support.dart';
import 'support/c_fonts.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

void main() {
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await loadCFonts();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  for (final language in ['de', 'en']) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('library is reachable at $language/$width/$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final routes = <String?>[];
          await tester.pumpWidget(
            catalogTestApp(
              locale: language,
              scale: scale,
              onGenerateRoute: (settings) {
                routes.add(settings.name);
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => Scaffold(
                    body: Text(
                      settings.name == '/study-library'
                          ? 'saved materials'
                          : settings.name!,
                    ),
                  ),
                );
              },
            ),
          );
          await pumpSoriStage(tester);
          final semantics = tester.ensureSemantics();
          await tester.pump();
          final library = find.byKey(const ValueKey('study-library-entry'));
          final t = AppL10n.of(tester.element(library));
          final prefs = await SharedPreferences.getInstance();
          final before = {
            for (final key in prefs.getKeys()) key: prefs.get(key),
          };
          for (final entry in {
            t.soriStageProfileTooltip: '/profile',
            t.settingsTitle: '/settings',
          }.entries) {
            final button = find.byWidgetPredicate(
              (widget) => widget is CImageTap && widget.label == entry.key,
            );
            expect(button.hitTestable(), findsOneWidget);
            final rect = tester.getRect(button);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.right, lessThanOrEqualTo(width));
            final data = tester.getSemantics(button).getSemanticsData();
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            await tester.tap(button);
            await pumpSoriStage(tester);
            expect(find.text(entry.value), findsOneWidget);
            Navigator.of(tester.element(find.text(entry.value))).pop();
            await pumpSoriStage(tester);
          }
          await tester.scrollUntilVisible(
            library,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await Scrollable.ensureVisible(
            tester.element(library),
            alignment: .5,
          );
          await pumpSoriStage(tester);
          expect(library.hitTestable(), findsOneWidget);
          final rect = tester.getRect(library.hitTestable());
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.right, lessThanOrEqualTo(width));
          final librarySemantics = tester
              .getSemantics(library)
              .getSemanticsData();
          expect(librarySemantics.flagsCollection.isButton, isTrue);
          expect(librarySemantics.hasAction(SemanticsAction.tap), isTrue);
          expect(
            find.bySemanticsLabel(t.studyLibraryAppBarTitle),
            findsWidgets,
          );
          semantics.dispose();
          await tester.tap(library.hitTestable());
          await pumpSoriStage(tester);
          expect(routes, ['/profile', '/settings', '/study-library']);
          expect(find.text('saved materials'), findsOneWidget);
          expect({
            for (final key in prefs.getKeys()) key: prefs.get(key),
          }, before);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'media entrance opens the existing route without learning writes',
    (tester) async {
      final routes = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          onGenerateRoute: (settings) {
            routes.add(settings.name);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('media expressions')),
            );
          },
        ),
      );
      await pumpSoriStage(tester);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final media = find.byType(SoriMediaPhraseLink);
      await tester.scrollUntilVisible(
        media,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(tester.element(media), alignment: .25);
      await pumpSoriStage(tester);
      await tester.tap(find.byKey(const ValueKey('media-phrase-entry')));
      await pumpSoriStage(tester);
      expect(routes, ['/media_phrases']);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'games keeps its eight activities without learning-only entrances',
    (tester) async {
      await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
      await pumpSoriStage(tester);
      expect(find.byType(SoriStudyLibraryButton), findsNothing);
      expect(find.byType(SoriMediaPhraseLink), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
