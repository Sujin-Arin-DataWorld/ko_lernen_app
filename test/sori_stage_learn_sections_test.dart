import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
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
  test(
    'all twelve practice entries belong to one catalog-owned group; course is separate',
    () {
      final expected = {
        SoriLearnSection.words: [
          'vocab_packs',
          'grammar',
          'book_capture',
          'word_web',
        ],
        SoriLearnSection.listen: [
          'pronunciation',
          'listening',
          'scenarios',
          'smalltalk',
        ],
        SoriLearnSection.hangul: ['hangul', 'calligraphy'],
        SoriLearnSection.review: ['srs', 'my_words'],
      };
      for (final group in expected.entries) {
        expect(
          soriActivityCatalog
              .where((e) => e.learnSection == group.key)
              .map((e) => e.id),
          group.value,
        );
      }
      expect(
        soriActivityCatalog.singleWhere((e) => e.id == 'course').learnSection,
        isNull,
      );
      expect(
        soriActivityCatalog
            .where((e) => e.tab == SoriStageTab.games)
            .every((e) => e.learnSection == null),
        isTrue,
      );
    },
  );
  testWidgets('Learn exposes four ordered groups with every activity once', (
    tester,
  ) async {
    final opened = <TodayLearningDestination>[];
    final controller = LearningFocusController()
      ..value = const LearningFocus(today: TodayLearningSnapshot(pick: null));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      catalogTestApp(
        controller: controller,
        onOpen: (destination, id) {
          expect(id, 'course');
          opened.add(destination);
        },
      ),
    );
    await pumpSoriStage(tester);
    final headings = [
      'Words & sentences',
      'Listen & speak',
      'Hangul & writing',
      'Review & my words',
    ];
    final tops = headings
        .map((title) => tester.getTopLeft(find.text(title)).dy)
        .toList();
    expect(tops.toList()..sort(), tops);
    final cards = tester
        .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
        .toList();
    expect(cards, hasLength(12));
    expect(cards.map((c) => c.entry.id).toSet(), hasLength(12));
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    for (final entry in soriActivityCatalog.where(
      (entry) => entry.tab == SoriStageTab.learn && entry.id != 'course',
    )) {
      final start = find.byKey(ValueKey('catalog-start-${entry.id}'));
      expect(start, findsOneWidget, reason: entry.id);
      await Scrollable.ensureVisible(tester.element(start), alignment: .5);
      await pumpSoriStage(tester);
      expect(start.hitTestable(), findsOneWidget, reason: entry.id);
      expect(tester.widget<CImageTap>(start).onTap, isNotNull);
      expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
    }
    for (final section in SoriLearnSection.values) {
      final jump = find.byKey(ValueKey('c-learn-category-${section.name}'));
      await Scrollable.ensureVisible(tester.element(jump), alignment: .5);
      await pumpSoriStage(tester);
      await tester.tap(jump);
      await pumpSoriStage(tester);
      expect(find.text(headings[section.index]).hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(ValueKey('learn-category-${section.name}')),
            )
            .selected,
        isTrue,
      );
    }
    final course = find.byKey(const ValueKey('learning-focus-course-overview'));
    await Scrollable.ensureVisible(tester.element(course), alignment: .5);
    await pumpSoriStage(tester);
    expect(tester.getSize(course).height, greaterThanOrEqualTo(48));
    await tester.tap(course);
    await pumpSoriStage(tester);
    expect(opened, [const TodayLearningDestination(route: '/path')]);
    expect(Storage.xp, 0);
    expect(Storage.pendingBoxes, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Games retains eight catalog entries without learning chips', (
    tester,
  ) async {
    final controller = LearningFocusController()
      ..value = const LearningFocus(today: TodayLearningSnapshot(pick: null));
    addTearDown(controller.dispose);
    final routes = <RouteSettings>[];
    final openedIds = <String?>[];
    await tester.pumpWidget(
      catalogTestApp(
        tab: SoriStageTab.games,
        controller: controller,
        onOpen: (destination, id) {
          openedIds.add(id);
          return Navigator.of(
                tester.element(find.byType(SoriStageCatalogScreen)),
              )
              .pushNamed<void>(
                destination.route,
                arguments: destination.arguments,
              )
              .then((_) {});
        },
        onGenerateRoute: (settings) {
          routes.add(settings);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('opened ${settings.name}')),
          );
        },
      ),
    );
    await pumpSoriStage(tester);
    expect(find.byType(ChoiceChip), findsNothing);
    const ids = [
      'syllable_cross',
      'chosung',
      'cloze',
      'speed_match',
      'sentence_arcade',
      'kkeunmari',
      'custom_practice',
      'daily_game',
    ];
    expect(
      soriActivityCatalog
          .where((entry) => entry.tab == SoriStageTab.games)
          .map((entry) => entry.id),
      unorderedEquals(ids),
    );
    for (final id in ids) {
      expect(find.byKey(ValueKey('catalog-card-$id')), findsOneWidget);
    }
    final t = AppL10n.of(tester.element(find.byType(SoriStageCatalogScreen)));
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    final semantics = tester.ensureSemantics();
    for (final id in ids) {
      final entry = soriActivityCatalog.singleWhere((entry) => entry.id == id);
      final target = id == 'syllable_cross'
          ? find.byWidgetPredicate(
              (widget) =>
                  widget is CMaterialAction &&
                  widget.label == t.catalogViewGame,
            )
          : find.byKey(
              ValueKey(
                id == 'daily_game' ? 'catalog-start-$id' : 'catalog-card-$id',
              ),
            );
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await pumpSoriStage(tester);
      expect(target.hitTestable(), findsOneWidget, reason: id);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      final data = tester.getSemantics(target).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue, reason: id);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: id);
      await tester.tap(target);
      await pumpSoriStage(tester);
      if (id != 'daily_game') {
        expect(find.text(t.soriStageActivityTitle(id)), findsWidgets);
        final start = find.byWidgetPredicate(
          (widget) =>
              widget is CMaterialAction &&
              widget.label == t.soriStageActivityStart,
        );
        await Scrollable.ensureVisible(tester.element(start), alignment: .5);
        await pumpSoriStage(tester);
        expect(start.hitTestable(), findsOneWidget, reason: id);
        expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
        await tester.tap(start);
        await pumpSoriStage(tester);
      }
      expect(routes.last.name, entry.route, reason: id);
      expect(routes.last.arguments, entry.arguments, reason: id);
      expect(openedIds.last, id);
      final destination = find.text('opened ${entry.route}');
      expect(destination, findsOneWidget);
      Navigator.of(tester.element(destination)).pop();
      await pumpSoriStage(tester);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    }
    semantics.dispose();
    expect(routes, hasLength(8));
    expect(openedIds, ids);
    expect(Storage.xp, 0);
    expect(Storage.pendingBoxes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
