import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/c5_catalog_overview.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/approved_figma_scene.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

Map<String, Object> _spacingMetrics(
  WidgetTester tester,
  Rect primary,
  Rect all,
) {
  final root = find.byKey(const ValueKey('c5-catalog-overview'));
  final overview = tester.widget<C5CatalogOverview>(root);
  final hero = tester.getRect(find.byKey(const ValueKey('c5-overview-hero')));
  final caption = tester.getRect(
    find.descendant(of: root, matching: find.text(overview.heroLabel)).first,
  );
  final tileMetrics = <Map<String, Object>>[];
  for (final item in overview.tiles) {
    final tile = find.byKey(item.key);
    final box = tester.getRect(tile);
    final art = tester.getRect(find.byWidget(item.art));
    final label = tester.getRect(
      find.descendant(of: tile, matching: find.byType(Text)).last,
    );
    tileMetrics.add({
      'label': item.label,
      'height': box.height,
      'artHeight': art.height,
      'artTopInset': art.top - box.top,
      'artToLabel': label.top - art.bottom,
      'labelBottomInset': box.bottom - label.bottom,
    });
  }
  return {
    'overviewWidth': tester.getSize(root).width,
    'overviewHeight': tester.getSize(root).height,
    'heroWidth': hero.width,
    'heroHeight': hero.height,
    'heroToCaption': caption.top - hero.bottom,
    'primaryToAll': all.top - primary.bottom,
    'lastActionToAll':
        all.top -
        (overview.footer == null
            ? primary.bottom
            : tester.getRect(find.byKey(overview.footer!.key)).bottom),
    'tiles': tileMetrics,
    if (!overview.games)
      'stepsToHero':
          hero.top -
          overview.steps
              .map(
                (text) => tester
                    .getBottomLeft(
                      find
                          .descendant(of: root, matching: find.text(text))
                          .first,
                    )
                    .dy,
              )
              .reduce((a, b) => a > b ? a : b),
  };
}

void main() {
  const output = String.fromEnvironment('C5_EVIDENCE_DIR');
  final records = <Map<String, Object>>[];
  late LearningFocus focus;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    focus = await loadFirstCatalogFocus();
    await ApprovedFigmaScene.load('lernen-65.json');
    await ApprovedFigmaScene.load('spiele-65.json');
    final map = await ApprovedFigmaScene.load('figma-assets.json');
    await Future.wait(map.values.cast<String>().map(CImageCache.load));
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  tearDownAll(() {
    if (output.isNotEmpty) {
      File('$output/measurements.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(records),
        );
    }
  });

  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(393, 873),
      const Size(1280, 900),
    ]) {
      for (final scale in [1.0, 2.0]) {
        for (final tab in [SoriStageTab.learn, SoriStageTab.games]) {
          testWidgets('C5 ${tab.name} $language ${size.width} $scale', (
            tester,
          ) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            tester.view.viewPadding = const FakeViewPadding(
              top: 24,
              bottom: 24,
            );
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            addTearDown(tester.view.resetViewPadding);
            final owner = LearningFocusController()..value = focus;
            addTearDown(owner.dispose);
            final scroll = ScrollController();
            addTearDown(scroll.dispose);
            final opened = <String>[];
            final boundary = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundary,
                child: catalogTestApp(
                  tab: tab,
                  locale: language,
                  scale: scale,
                  showAll: false,
                  controller: owner,
                  scrollController: scroll,
                  onOpen: (_, id) => opened.add(id!),
                ),
              ),
            );
            await pumpSoriStage(tester);
            await tester.runAsync(() async {
              for (final image in find.byType(Image).evaluate()) {
                await precacheImage((image.widget as Image).image, image);
              }
            });
            await pumpSoriStage(tester);
            final primary = find.byKey(
              ValueKey(
                tab == SoriStageTab.learn ? 'c5-course-start' : 'c5-game-start',
              ),
            );
            final all = find.byKey(const ValueKey('c5-catalog-all'));
            final navigation = find.byType(NavigationBar);
            final navTop = navigation.evaluate().isEmpty
                ? size.height - 24
                : tester.getTopLeft(navigation).dy;
            final primaryRect = tester.getRect(primary);
            final allRect = tester.getRect(all);
            final spacing = _spacingMetrics(tester, primaryRect, allRect);
            expect(primaryRect.height, greaterThanOrEqualTo(48 - 1e-9));
            expect(allRect.height, greaterThanOrEqualTo(48 - 1e-9));
            expect(spacing['overviewWidth'], lessThanOrEqualTo(480 + .01));
            expect(spacing['heroHeight'], lessThanOrEqualTo(180 + .01));
            expect(spacing['heroToCaption'], closeTo(4, .01));
            expect(spacing['lastActionToAll'], inInclusiveRange(4.0, 12.0));
            if (scale == 1) {
              expect(primaryRect.bottom, lessThanOrEqualTo(navTop + 1));
              expect(allRect.bottom, lessThanOrEqualTo(navTop + 1));
              expect(scroll.position.maxScrollExtent, lessThanOrEqualTo(1));
              for (final tile
                  in spacing['tiles']! as List<Map<String, Object>>) {
                expect(tile['artToLabel'], closeTo(4, .01));
                expect(tile['artTopInset'], lessThanOrEqualTo(5 + .01));
                expect(tile['labelBottomInset'], lessThanOrEqualTo(5 + .01));
              }
              if (tab == SoriStageTab.learn) {
                expect(spacing['stepsToHero'], closeTo(4, .01));
              }
            }
            expect(find.byType(SoriCatalogCard), findsNothing);
            if (tab == SoriStageTab.games) {
              final hero = tester.getRect(
                find.byKey(const ValueKey('c5-overview-hero')),
              );
              final details = tester.getRect(
                find.byKey(const ValueKey('c5-overview-details')),
              );
              expect(details.height, greaterThanOrEqualTo(48 - 1e-9));
              expect(details.bottom, lessThanOrEqualTo(hero.bottom + .01));
              for (final id in [
                'daily_game',
                'chosung',
                'cloze',
                'speed_match',
                'sentence_arcade',
                'kkeunmari',
                'custom_practice',
              ]) {
                final tile = find.byKey(ValueKey('c5-game-$id'));
                expect(tile, findsOneWidget);
                expect(
                  tester.getSize(tile).height,
                  greaterThanOrEqualTo(48 - 1e-9),
                );
              }
            }
            expect(tester.takeException(), isNull);
            final name =
                '${tab.name}-$language-${size.width.toInt()}-${scale.toInt()}x';
            records.add({
              'capture': '$name.png',
              'primaryBottom': primaryRect.bottom,
              'allButtonBottom': allRect.bottom,
              'navigationTop': navTop,
              'scrollExtent': scroll.position.maxScrollExtent,
              'language': language,
              'textScale': scale,
              'topInset': 24,
              'bottomInset': 24,
              ...spacing,
            });
            if (output.isNotEmpty) {
              await tester.runAsync(() async {
                final render =
                    boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                final image = await render.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File('$output/$name.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await Scrollable.ensureVisible(
              tester.element(primary),
              alignment: .6,
            );
            await pumpSoriStage(tester);
            await tester.tap(primary);
            await pumpSoriStage(tester);
            expect(opened, [
              tab == SoriStageTab.learn ? 'course' : 'syllable_cross',
            ]);
            await Scrollable.ensureVisible(tester.element(all), alignment: .8);
            await pumpSoriStage(tester);
            final overviewOffset = scroll.offset;
            await tester.tap(all);
            await pumpSoriStage(tester);
            final expected = soriActivityCatalog.where(
              (entry) =>
                  entry.tab == tab &&
                  (tab != SoriStageTab.learn || entry.id != 'course'),
            );
            expect(
              tester
                  .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
                  .map((card) => card.entry.id),
              unorderedEquals(expected.map((entry) => entry.id)),
            );
            await tester.tap(find.byKey(const ValueKey('c5-catalog-close')));
            await pumpSoriStage(tester);
            expect(
              find.byKey(const ValueKey('c5-catalog-overview')),
              findsOneWidget,
            );
            expect(scroll.offset, closeTo(overviewOffset, 1));
            await Scrollable.ensureVisible(tester.element(all), alignment: .8);
            await pumpSoriStage(tester);
            await tester.tap(all);
            await pumpSoriStage(tester);
            await tester.binding.handlePopRoute();
            await pumpSoriStage(tester);
            expect(find.byType(SoriCatalogCard), findsNothing);
            expect(
              find.byKey(const ValueKey('c5-catalog-overview')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          });
        }
      }
    }
  }
  testWidgets('C5 reflows above the keyboard and keeps the catalog reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      catalogTestApp(showAll: false, locale: 'de', scrollController: scroll),
    );
    await pumpSoriStage(tester);
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    final all = find.byKey(const ValueKey('c5-catalog-all'));
    await Scrollable.ensureVisible(tester.element(all), alignment: 1);
    await pumpSoriStage(tester);
    expect(all.hitTestable(), findsOneWidget);
    await tester.tap(all);
    await pumpSoriStage(tester);
    expect(find.byType(SoriCatalogCard), findsNWidgets(12));
    expect(tester.takeException(), isNull);
  });
}
