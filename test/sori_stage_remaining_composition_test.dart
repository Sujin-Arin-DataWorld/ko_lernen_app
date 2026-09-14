import 'dart:async';
import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/features/guide/today_guide_checklist_card.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:ko_lernen_app/widgets/sori/stepper.dart';
import 'support/catalog_test_support.dart';
import 'support/sori_stage_pump.dart';
import 'support/real_fonts.dart';

void main() {
  late LearningFocus focus;
  late SarangchaeConstruction construction;
  late SoriStageProgressionSnapshot firstSnapshot;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    construction = await SarangchaeConstruction.load();
    focus = await loadFirstCatalogFocus();
    firstSnapshot = SoriStageProgressionSnapshot(
      today: focus.today,
      hanokCompetence: HanokCompetenceProjection.fromSnapshot(
        snapshot: const CourseMasterySnapshot.empty(),
        courseUnits: (await CurriculumCatalog.load()).courseUnits,
      ),
      quests: const [],
      pendingBojagiCount: 0,
      stampCount: 0,
      xp: 0,
      streakDays: 0,
      todayReward: null,
    );
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      GuideProgressService.completedTopicIdsKey: <String>[],
      GuideProgressService.openedTopicIdsKey: <String>[],
      GuideProgressService.todayCardDismissedKey: false,
    });
    await Storage.init();
    // Resolve the static service's initial queue outside the widget fake-async
    // zone, then explicitly establish the same newcomer guide for DE and EN.
    final guide = await GuideRuntime.progress.load();
    expect(guide.completedTopicIds, isEmpty);
    expect(guide.openedTopicIds, isEmpty);
    expect(guide.isTodayCardDismissed, isFalse);
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child,
    String locale,
    double scale,
    Size size,
    LearningFocusController controller, {
    GlobalKey? boundary,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(locale),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Builder(
            builder: (context) {
              final t = AppL10n.of(context);
              final rail = SoriAdaptiveNavigation.usesRailForWidth(size.width);
              final nav = SoriAdaptiveNavigation(
                selectedIndex: child is SoriStageTodayScreen
                    ? 0
                    : child is SoriStageHanokScreen
                    ? 3
                    : 4,
                onDestinationSelected: (_) {},
                items: [
                  SoriAdaptiveNavigationItem(
                    label: t.soriStageNavToday,
                    icon: Icons.today_outlined,
                    selectedIcon: Icons.today_rounded,
                  ),
                  SoriAdaptiveNavigationItem(
                    label: t.soriStageNavLearn,
                    icon: Icons.school_outlined,
                    selectedIcon: Icons.school_rounded,
                  ),
                  SoriAdaptiveNavigationItem(
                    label: t.soriStageNavGames,
                    icon: Icons.sports_esports_outlined,
                    selectedIcon: Icons.sports_esports_rounded,
                  ),
                  SoriAdaptiveNavigationItem(
                    label: t.soriStageNavHanok,
                    icon: Icons.home_work_outlined,
                    selectedIcon: Icons.home_work_rounded,
                  ),
                  SoriAdaptiveNavigationItem(
                    label: t.soriStageNavGye,
                    icon: Icons.groups_2_outlined,
                    selectedIcon: Icons.groups_2_rounded,
                  ),
                ],
              );
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: LearningFocusScope(
                  controller: controller,
                  open: (_, destination, {focus, activityId}) async {},
                  child: Scaffold(
                    body: Row(
                      children: [
                        if (rail)
                          SizedBox(
                            width: SoriAdaptiveNavigation.railWidthForWidth(
                              size.width,
                            ),
                            child: nav,
                          ),
                        Expanded(child: child),
                      ],
                    ),
                    bottomNavigationBar: rail ? null : nav,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Widget screen(
    String tab, {
    Future<SoriStageProgressionSnapshot> Function()? load,
    Future<List<GyeMeta>> Function()? groups,
    VoidCallback? solo,
  }) => switch (tab) {
    'today' => SoriStageTodayScreen(
      loadSnapshot: load ?? () async => firstSnapshot,
      forceStaticHero: true,
      now: () => DateTime(2026, 9, 14, 10),
    ),
    'hanok' => SoriStageHanokScreen(
      loadSnapshot: load ?? () async => firstSnapshot,
      loadConstruction: () async => construction,
    ),
    _ => SoriStageGyeScreen(
      loadGyeMetas: groups ?? () async => [],
      onContinueSolo: solo,
    ),
  };
  for (final tab in ['today', 'hanok', 'gye']) {
    for (final locale in ['de', 'en']) {
      testWidgets('$tab $locale real-font native layout and first action', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = LearningFocusController()
          ..value = focus
          ..loading = false;
        addTearDown(controller.dispose);
        final boundary = GlobalKey();
        var solo = 0;
        await mount(
          tester,
          screen(tab, solo: () => solo++),
          locale,
          1,
          const Size(390, 844),
          controller,
          boundary: boundary,
        );
        expect(tester.takeException(), isNull);
        if (tab == 'today') {
          await pumpUntilFound(tester, find.byType(TodayGuideChecklistCard));
          await tester.pump();
          expect(find.byType(TodayGuideChecklistCard), findsOneWidget);
          final action = find.text(
            lookupAppL10n(Locale(locale)).learningFocusStart,
          );
          expect(action.hitTestable(), findsOneWidget);
        } else if (tab == 'hanok') {
          expect(find.byType(HanokV3Preview), findsNothing);
          final artwork = tester.widget<SarangchaeStageArtwork>(
            find.byType(SarangchaeStageArtwork),
          );
          expect(artwork.earnedStageCount, 0);
          final image = tester.widget<Image>(
            find.byKey(const ValueKey('sarangchae-stage-artwork-1')),
          );
          expect(image.fit, BoxFit.contain);
          expect(
            (image.image as AssetImage).assetName,
            construction.stage(1).assetPath,
          );
          final art = tester.getRect(
            find.byKey(const ValueKey('hanok-full-preview')),
          );
          expect(find.byIcon(Icons.lock_rounded), findsWidgets);
          expect(
            find.byKey(const ValueKey('hanok-construction-entry')),
            findsOneWidget,
          );
          final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
          for (final id in ['quests', 'dojang', 'bojagi']) {
            final label = find.byKey(ValueKey('hanok-shortcut-label-$id'));
            final text = tester.widget<Text>(label).data!;
            final paragraph = tester.renderObject<RenderParagraph>(label);
            expect(
              paragraph
                  .getBoxesForSelection(
                    TextSelection(baseOffset: 0, extentOffset: text.length),
                  )
                  .map((box) => box.top)
                  .toSet(),
              hasLength(1),
              reason: '$id must read as one word',
            );
            expect(
              tester.getRect(find.byKey(ValueKey('hanok-shortcut-$id'))).bottom,
              lessThan(navTop),
            );
          }

          expect(
            art.bottom,
            lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
          );
        } else {
          expect(find.byType(SoriStepper), findsNothing);
          expect(
            find.byKey(const ValueKey('gye-empty-start')).hitTestable(),
            findsOneWidget,
          );
        }
        if (const bool.fromEnvironment('CAPTURE_REMAINING_TABS')) {
          await tester.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          await tester.pump();
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 3);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '${const String.fromEnvironment('REMAINING_OUTPUT')}/$tab-$locale.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (tab == 'gye') {
          await tester.tap(find.byKey(const ValueKey('gye-continue-solo')));
          expect(solo, 1);
        }
      });
    }
    testWidgets(
      '$tab DE EN 100 160 200 responsive matrix keeps actions reachable',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = LearningFocusController()
          ..value = focus
          ..loading = false;
        addTearDown(controller.dispose);
        for (final locale in ['de', 'en']) {
          for (final size in [
            const Size(360, 640),
            const Size(390, 844),
            const Size(430, 932),
            const Size(800, 1280),
            const Size(1280, 800),
          ]) {
            for (final scale in [1.0, 1.6, 2.0]) {
              await tester.pumpWidget(const SizedBox.shrink());
              await mount(tester, screen(tab), locale, scale, size, controller);
              final key = tab == 'today'
                  ? 'learning-focus-start'
                  : tab == 'hanok'
                  ? 'hanok-shortcut-bojagi'
                  : 'gye-continue-solo';
              final action = tab == 'today'
                  ? find.text(lookupAppL10n(Locale(locale)).learningFocusStart)
                  : find.byKey(ValueKey(key));
              if (action.evaluate().isEmpty) {
                await tester.scrollUntilVisible(
                  action,
                  240,
                  scrollable: find.byType(Scrollable).first,
                );
              }
              await Scrollable.ensureVisible(
                tester.element(action),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(
                action.hitTestable(),
                findsOneWidget,
                reason: '$tab $locale $size $scale',
              );
              expect(
                tester.takeException(),
                isNull,
                reason: '$tab $locale $size $scale',
              );
            }
          }
        }
      },
    );
  }
  testWidgets('Hanok failed reads show retry and no invented zero', (
    tester,
  ) async {
    final controller = LearningFocusController()
      ..value = focus
      ..loading = false;
    addTearDown(controller.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      screen('hanok', load: () async => throw StateError('read failed')),
      'en',
      1,
      const Size(390, 844),
      controller,
    );
    expect(find.byKey(const ValueKey('hanok-progress-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('hanok-confirmed-units')), findsNothing);
    expect(
      find.text(lookupAppL10n(const Locale('en')).btnRetry),
      findsOneWidget,
    );
  });
  testWidgets('Gye loading and error never masquerade as newcomer state', (
    tester,
  ) async {
    final controller = LearningFocusController()
      ..value = focus
      ..loading = false;
    addTearDown(controller.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<List<GyeMeta>>();
    await mount(
      tester,
      screen('gye', groups: () => pending.future),
      'en',
      1,
      const Size(390, 844),
      controller,
      settle: false,
    );
    expect(find.byKey(const ValueKey('gye-empty-start')), findsNothing);
    expect(find.byType(SoriStepper), findsNothing);
    pending.completeError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gye-empty-start')), findsNothing);
    expect(find.byType(SoriStepper), findsNothing);
  });
  testWidgets('Hanok healthy empty source uses neutral copy without 0/0', (
    tester,
  ) async {
    final controller = LearningFocusController()
      ..value = focus
      ..loading = false;
    addTearDown(controller.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      screen('hanok', load: () async => catalogSnapshot()),
      'en',
      1,
      const Size(390, 844),
      controller,
    );
    expect(
      find.text(lookupAppL10n(const Locale('en')).soriStageHanokNoUnits),
      findsOneWidget,
    );
    expect(find.textContaining('0 / 0'), findsNothing);
  });
  for (final schema in [0, 1, 2]) {
    testWidgets(
      'Gye schema $schema retains actual goal selection above preview',
      (tester) async {
        final controller = LearningFocusController()
          ..value = focus
          ..loading = false;
        addTearDown(controller.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final meta = GyeMeta(
          id: 'fixture',
          name: 'Mondhof',
          code: 'ABC123',
          ownerId: 'fixture',
          memberCount: 3,
          weeklyGoalPacks: 5,
          weeklyGoalProgress: 2,
          weeklyPromiseSchemaVersion: schema,
          weeklyPromiseId: 'cafe_order',
          weeklyPromiseTarget: 3,
          weeklyPromiseProgress: 1,
        );
        await mount(
          tester,
          screen('gye', groups: () async => [meta]),
          'en',
          1,
          const Size(390, 844),
          controller,
        );
        final count = find.text(schema == 1 ? '1 / 3' : '2 / 5');
        expect(count, findsOneWidget);
        final art = find.byType(Image).last;
        expect(
          tester.getTopLeft(find.text('Mondhof')).dy,
          lessThan(tester.getTopLeft(count).dy),
        );
        expect(
          tester.getBottomLeft(count).dy,
          lessThan(tester.getTopLeft(art).dy),
        );
        expect(find.byKey(const ValueKey('gye-empty-start')), findsNothing);
      },
    );
  }
}
