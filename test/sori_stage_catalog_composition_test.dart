import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/c_fonts.dart';

void main() {
  late LearningFocus focus;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await loadCFonts();
    focus = await loadFirstCatalogFocus();
    expect(focus.ready, isTrue);
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  Future<void> viewport(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  for (final state in ['loading', 'error', 'empty', 'ready']) {
    testWidgets('all13 Learn activities remain reachable with $state focus', (
      tester,
    ) async {
      await viewport(tester, const Size(390, 844));
      final controller = LearningFocusController()
        ..value = switch (state) {
          'ready' => focus,
          'empty' => const LearningFocus(
            today: TodayLearningSnapshot(pick: null),
          ),
          _ => null,
        }
        ..loading = state == 'loading'
        ..error = state == 'error' ? StateError('source read failed') : null;
      addTearDown(controller.dispose);
      final opened = <String>[];
      await tester.pumpWidget(
        catalogTestApp(
          controller: controller,
          onOpen: (destination, id) {
            expect(id, 'course');
            opened.add(destination.route);
          },
        ),
      );
      await tester.pump();
      final overview = find.byKey(
        const ValueKey('learning-focus-course-overview'),
      );
      expect(overview, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(overview), alignment: .5);
      await tester.pump();
      expect(overview.hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('catalog-card-course')), findsNothing);
      expect(opened, isEmpty);
      await tester.tap(overview);
      expect(opened, ['/path']);
      final ordinary = soriActivityCatalog.where(
        (entry) => entry.tab == SoriStageTab.learn && entry.id != 'course',
      );
      expect(ordinary, hasLength(12));
      for (final entry in ordinary) {
        final start = find.byKey(ValueKey('catalog-start-${entry.id}'));
        expect(start, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(start), alignment: .5);
        await tester.pump();
        expect(start.hitTestable(), findsOneWidget, reason: entry.id);
        expect(tester.widget<CImageTap>(start).onTap, isNotNull);
      }
      expect(opened, ['/path']);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['de', 'en']) {
    for (final tab in [SoriStageTab.learn, SoriStageTab.games]) {
      testWidgets('${tab.name} $language real catalog first row fits at390x844', (
        tester,
      ) async {
        await viewport(tester, const Size(390, 844));
        final controller = LearningFocusController()..value = focus;
        addTearDown(controller.dispose);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: catalogTestApp(
              tab: tab,
              locale: language,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
        final keys = tab == SoriStageTab.learn
            ? [
                'c-learn-category-words',
                'c-learn-category-listen',
                'c-learn-category-hangul',
                'c-learn-category-review',
              ]
            : [
                'catalog-card-chosung',
                'catalog-card-cloze',
                'catalog-card-speed_match',
                'catalog-card-sentence_arcade',
                'catalog-card-kkeunmari',
              ];
        for (final key in keys) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(
            rect.bottom,
            lessThanOrEqualTo(navTop),
            reason: '$key bottom=${rect.bottom} nav=$navTop',
          );
        }
        if (tab == SoriStageTab.learn) {
          expect(
            find.text(focus.brief!.unit.title.pick(language)),
            findsOneWidget,
          );
          expect(
            tester
                .getRect(find.byKey(const ValueKey('learning-focus-surface')))
                .bottom,
            lessThan(
              tester
                  .getTopLeft(
                    find.byKey(const ValueKey('catalog-card-vocab_packs')),
                  )
                  .dy,
            ),
          );
        }
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_CATALOG_COMPOSITION')) {
          await tester.runAsync(() async {
            for (final element in find.byType(Image).evaluate()) {
              await precacheImage((element.widget as Image).image, element);
            }
          });
          await tester.pump();
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 3);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final path =
                '${const String.fromEnvironment('CATALOG_OUTPUT', defaultValue: 'build/catalog-production')}/${tab.name}-$language.png';
            final file = File(path);
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  testWidgets(
    'Details pointer, long press and keyboard never start the activity; sheet retains full art',
    (tester) async {
      await viewport(tester, const Size(390, 844));
      final controller = LearningFocusController()..value = focus;
      addTearDown(controller.dispose);
      final opened = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          controller: controller,
          onOpen: (_, id) => opened.add(id),
        ),
      );
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('catalog-details-vocab_packs'));
      await Scrollable.ensureVisible(tester.element(details), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      final art = find.descendant(
        of: find.byType(SoriSheetShell),
        matching: find.byType(CReferenceArt),
      );
      final image = tester.widget<CReferenceArt>(art);
      expect(image.part, CReferencePart.words);
      expect(image.fit, BoxFit.contain);
      expect(tester.getSize(art).aspectRatio, closeTo(2, .001));
      Navigator.of(tester.element(find.byType(SoriSheetShell))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-start-vocab_packs')),
      );
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('catalog-start-vocab_packs')),
      );
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      Navigator.of(tester.element(find.byType(SoriSheetShell))).pop();
      await tester.pumpAndSettle();
      final detailText = find
          .descendant(of: details, matching: find.byType(Text))
          .first;
      Focus.of(tester.element(detailText)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SoriSheetShell), findsOneWidget);
      expect(opened, isEmpty);
      Navigator.of(tester.element(find.byType(SoriSheetShell))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-start-vocab_packs')));
      await tester.pumpAndSettle();
      expect(opened, ['vocab_packs']);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(360, 400),
    const Size(720, 1024),
    const Size(1280, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'catalog natural cards and section jumps ${size.width} at${scale}x',
        (tester) async {
          await viewport(tester, size);
          final controller = LearningFocusController()..value = focus;
          addTearDown(controller.dispose);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          await tester.pumpWidget(
            catalogTestApp(
              controller: controller,
              scale: scale,
              locale: 'de',
              scrollController: scroll,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('catalog-card-vocab_packs')),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(find.byType(SoriCatalogCard), findsNWidgets(12));
          expect(
            find.descendant(
              of: find.byType(SoriCatalogCard),
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
          final a = tester.getRect(
            find.byKey(const ValueKey('catalog-card-vocab_packs')),
          );
          final b = tester.getRect(
            find.byKey(const ValueKey('catalog-card-grammar')),
          );
          // C keeps a single 600dp paper surface; the ordinary catalog below
          // its compact illustrated overview stacks without fixed heights.
          expect(b.top, greaterThan(a.bottom));
          for (final section in SoriLearnSection.values) {
            final chip = find.byKey(ValueKey('learn-category-${section.name}'));
            await Scrollable.ensureVisible(tester.element(chip), alignment: .5);
            await tester.pumpAndSettle();
            await tester.tap(chip);
            await tester.pumpAndSettle();
            expect(
              tester.widget<ChoiceChip>(chip).selected,
              isTrue,
              reason: section.name,
            );
          }
          expect(scroll.offset, greaterThan(0));
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('learn-category-review')),
                )
                .selected,
            isTrue,
          );
          scroll.jumpTo(0);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('learn-category-words')),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('learn-category-words')),
                )
                .selected,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'C level picker changes browse level without moving the actual course',
    (tester) async {
      await viewport(tester, const Size(320, 640));
      await Storage.setBrowseLevelCode('a1');
      final controller = LearningFocusController()..value = focus;
      addTearDown(controller.dispose);
      final courseBefore = Storage.courseMasterySnapshotRawJson;
      final xpBefore = Storage.xp;
      await tester.pumpWidget(catalogTestApp(controller: controller, scale: 2));
      await tester.pumpAndSettle();
      final filter = find.byKey(const ValueKey('c-learn-level-filter'));
      await tester.tap(filter);
      await tester.pumpAndSettle();
      final t = AppL10n.of(tester.element(find.byType(SoriStageCatalogScreen)));
      expect(find.text(t.lernenFree), findsWidgets);
      expect(find.text(t.settingsBrowseLevelDescription), findsOneWidget);
      expect(
        tester
            .widget<CMaterialAction>(
              find.byKey(const ValueKey('c-browse-level-a1')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<CMaterialAction>(
              find.byKey(const ValueKey('c-browse-level-b2')),
            )
            .selected,
        isFalse,
      );
      final level = find.byKey(const ValueKey('c-browse-level-b2'));
      await tester.ensureVisible(level);
      await tester.pumpAndSettle();
      await tester.tap(level);
      await tester.pumpAndSettle();
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.courseMasterySnapshotRawJson, courseBefore);
      expect(controller.value, same(focus));
      expect(Storage.xp, xpBefore);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown and zero stay neutral; real counts and game bests have their actual meaning',
    (tester) async {
      await tester.pumpWidget(catalogTestApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SoriStageCatalogScreen));
      final t = AppL10n.of(context);
      final snapshot = catalogSnapshot(
        progress: {
          'vocab_packs': const SoriActivityProgress(
            activityId: 'vocab_packs',
            state: SoriActivityState.completed,
            current: 2,
            target: 2,
          ),
          'srs': const SoriActivityProgress(
            activityId: 'srs',
            state: SoriActivityState.completed,
            current: 200,
            target: 200,
          ),
          'pronunciation': const SoriActivityProgress(
            activityId: 'pronunciation',
            state: SoriActivityState.completed,
            current: 100,
            target: 100,
          ),
        },
        bests: {'chosung': 42, 'daily': 0},
      );
      String? status(String id, SoriStageProgressionSnapshot? data) =>
          catalogActivityStatus(
            context,
            soriActivityCatalog.singleWhere((e) => e.id == id),
            data,
          );
      expect(status('vocab_packs', null), isNull);
      expect(status('vocab_packs', catalogSnapshot()), isNull);
      expect(status('vocab_packs', snapshot), t.catalogPacksCompleted(2));
      expect(status('srs', snapshot), isNull);
      expect(
        status('pronunciation', snapshot),
        t.catalogPronunciationPassed(100),
      );
      expect(status('chosung', snapshot), t.catalogBestScore(42));
      expect(status('daily_game', snapshot), isNull);
      // The retired status label must not return when no progress is known.
      expect(find.text('New'), findsNothing);
      expect(find.text('Neu'), findsNothing);
    },
  );

  testWidgets(
    'unavailable progress exposes retry while original routes remain usable',
    (tester) async {
      final controller = LearningFocusController()..value = focus;
      addTearDown(controller.dispose);
      var attempts = 0;
      final opened = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          controller: controller,
          onOpen: (_, id) => opened.add(id),
          loadSnapshot: () async {
            if (attempts++ == 0) {
              throw StateError('read unavailable');
            }
            return catalogSnapshot();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Your progress could not be loaded. You can still practice.'),
        findsOneWidget,
      );
      final t = AppL10n.of(tester.element(find.byType(SoriStageCatalogScreen)));
      await Scrollable.ensureVisible(
        tester.element(find.text(t.btnRetry)),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.btnRetry));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text(t.catalogProgressUnavailable), findsNothing);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('catalog-start-vocab_packs'))),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-start-vocab_packs')));
      await tester.pumpAndSettle();
      expect(opened, ['vocab_packs']);
    },
  );

  testWidgets(
    'image failure is named inside the original slot and does not remove launch or Details',
    (tester) async {
      var starts = 0;
      var details = 0;
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _MissingArtBundle(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: SoriCatalogCard(
                  entry: soriActivityCatalog.singleWhere(
                    (e) => e.id == 'vocab_packs',
                  ),
                  onStart: () => starts++,
                  onDetails: () => details++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No image'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AspectRatio)).aspectRatio,
        closeTo(4 / 3, .001),
      );
      await tester.tap(find.text('No image'));
      await tester.pump();
      expect(starts, 1);
      await tester.tap(
        find.byKey(const ValueKey('catalog-details-vocab_packs')),
      );
      expect(details, 1);
      expect(starts, 1);
    },
  );
  testWidgets(
    'a late old-account return cannot release a newer catalog launch',
    (tester) async {
      await viewport(tester, const Size(390, 844));
      final controller = LearningFocusController()..value = focus;
      addTearDown(controller.dispose);
      addTearDown(cloudWriteSessionController.clear);
      final first = Completer<void>();
      final second = Completer<void>();
      final opened = <String?>[];
      await tester.pumpWidget(
        catalogTestApp(
          controller: controller,
          onOpen: (_, id) async {
            opened.add(id);
            final wait = opened.length == 1
                ? first.future
                : opened.length == 2
                ? second.future
                : Future<void>.value();
            await wait;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-quick-vocab_packs')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-quick-vocab_packs')));
      await tester.pump();
      cloudWriteSessionController.acquire('new-account');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-quick-grammar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-quick-grammar')));
      await tester.pump();
      first.complete();
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-quick-vocab_packs')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-quick-vocab_packs')));
      expect(opened, ['vocab_packs', 'grammar']);
      second.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-quick-vocab_packs')));
      await tester.pumpAndSettle();
      expect(opened, ['vocab_packs', 'grammar', 'vocab_packs']);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _MissingArtBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('illustrations/activities/')) {
      return Future.error(StateError('image unavailable'));
    }
    return rootBundle.load(key);
  }
}
