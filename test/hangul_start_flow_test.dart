import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_start_screen.dart';
import 'package:ko_lernen_app/screens/phase_task_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hangul_foundation_catalog.dart';
import 'package:ko_lernen_app/services/hangul_start_progress.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/hangul_start_material.dart';
import 'package:ko_lernen_app/widgets/sori/image_navigation_bar.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_test_support.dart' as fixtures;
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = HangulFoundationCatalog.parse(
    jsonDecode(File(HangulFoundationCatalog.assetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
  late AppL10n t;
  const captureDirectory = String.fromEnvironment('HANGUL_START_CAPTURE_DIR');
  final capture = GlobalKey();
  setUpAll(() async {
    t = await AppL10n.delegate.load(const Locale('en'));
    SharedPreferences.setMockInitialValues({});
    await GuideRuntime.progress.load();
    if (captureDirectory.isNotEmpty) {
      await loadSoriRealFonts(materialIcons: true);
    }
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_home_tour': true});
    await Storage.init();
  });

  Future<void> render(
    WidgetTester tester,
    HangulStartEntry entry, {
    double scale = 1,
    Size viewport = const Size(320, 640),
    Locale locale = const Locale('en'),
    Future<bool> Function(String, double?)? play,
    Widget? screen,
    RouteFactory? onGenerateRoute,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final host = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      onGenerateRoute: onGenerateRoute,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: viewport,
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home:
          screen ??
          HangulStartScreen(
            entry: entry,
            loadCatalog: () async => catalog,
            playAudio: play ?? (_, _) async => true,
          ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(RepaintBoundary(key: capture, child: host));
      for (var attempt = 0; attempt < 20; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    await tester.pumpAndSettle(
      const Duration(milliseconds: 30),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  Future<void> saveCapture(WidgetTester tester, String name) async {
    if (captureDirectory.isEmpty) return;
    final boundary =
        capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      await Directory(captureDirectory).create(recursive: true);
      await File('$captureDirectory/$name.png').writeAsBytes(bytes);
      image.dispose();
    });
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final matches = find.text(text);
    if (matches.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        matches,
        200,
        maxScrolls: 30,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    final finder = matches.first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder.hitTestable(),
        120,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 30,
      );
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test(
    'progress serializes retries and selects the next actual lesson',
    () async {
      final store = HangulStartProgressStore();
      await Future.wait([
        store.setCursor(const HangulStartCursor('F06', 3, 1)),
        store.complete('F02'),
        store.complete('F02'),
      ]);
      final progress = await HangulStartProgressStore().load();
      expect(progress.completed, {'F02'});
      expect(progress.cursor?.stage, 3);
      final home = HangulStartHome(catalog, progress);
      expect(home.nextLesson?.id, 'F06');
      expect(
        todayLearningDestinationFor(HangulIntroPick(start: home)),
        const TodayLearningDestination(
          route: '/hangul-start',
          arguments: HangulStartEntry.resume,
        ),
      );
    },
  );

  testWidgets(
    'beginner Today opens Hangul Start and puts shortcuts below Hanok and games',
    (tester) async {
      const locale = Locale('de');
      final labels = await AppL10n.delegate.load(locale);
      final pick = HangulIntroPick(
        start: HangulStartHome(catalog, const HangulStartProgress()),
      );
      final destination = todayLearningDestinationFor(pick)!;
      final focus = LearningFocus(
        today: TodayLearningSnapshot(pick: pick, destination: destination),
        destination: destination,
      );
      final controller = LearningFocusController(loader: () async => focus)
        ..value = focus;
      addTearDown(controller.dispose);
      TodayLearningDestination? opened;
      String? route;
      var games = 0;
      final fixture = fixtures.catalogSnapshot();
      await render(
        tester,
        HangulStartEntry.map,
        locale: locale,
        onGenerateRoute: (settings) {
          route = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.expand()),
          );
        },
        screen: Scaffold(
          body: LearningFocusScope(
            controller: controller,
            open: (_, destination, {focus, activityId}) async {
              opened = destination;
            },
            child: SoriStageTodayScreen(
              loadSnapshot: () async => fixture,
              now: () => DateTime(2026, 11, 24, 9),
              forceStaticHero: true,
              onOpenGames: () => games++,
            ),
          ),
          bottomNavigationBar: SoriImageNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            labels: [
              labels.soriStageNavToday,
              labels.soriStageNavLearn,
              labels.soriStageNavGames,
              labels.soriStageNavHanok,
              labels.soriStageNavGye,
            ],
            assets: const [
              ApprovedChromeAssets.today,
              ApprovedChromeAssets.learn,
              ApprovedChromeAssets.games,
              ApprovedChromeAssets.hanok,
              ApprovedChromeAssets.gye,
            ],
          ),
        ),
      );
      if (captureDirectory.isNotEmpty) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 160)),
        );
        await tester.pump();
        await saveCapture(tester, 'flutter-S1a-de-320x640');
      }
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('today-dashboard-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<Finder> reveal(String label) async {
        final target = find.text(label);
        await tester.scrollUntilVisible(target, 100, scrollable: scroll);
        await tester.pumpAndSettle();
        return target;
      }

      await tester.tap(await reveal(labels.todayStartHangul));
      expect(opened, destination);
      await tester.tap(await reveal(labels.hangulStartAlreadyRead));
      expect(opened?.arguments, HangulStartEntry.quiz);
      final hanok = await reveal(labels.hangulStartTodayHanok);
      final play = await reveal(labels.todayExploreGames);
      final atelier = await reveal(labels.hangulStartTodayAtelier);
      final a11 = await reveal(labels.hangulStartTodayDirectA11);
      expect(
        tester.getTopLeft(atelier).dy,
        greaterThan(tester.getTopLeft(hanok).dy),
      );
      expect(
        tester.getTopLeft(a11).dy,
        greaterThan(tester.getTopLeft(play).dy),
      );
      await saveCapture(tester, 'flutter-S1a-de-shortcuts-320x640');
      await tester.tap(play);
      expect(games, 1);
      await tester.tap(atelier);
      await tester.pumpAndSettle();
      expect(route, '/hangul');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map offers all fourteen lessons and exposes the nominated lesson at 200%',
    (tester) async {
      await render(tester, HangulStartEntry.map, scale: 2);
      expect(find.byType(HangulStartTile), findsNWidgets(14));
      await tap(tester, t.todayStartHangul);
      expect(find.text('Lesson 1'), findsOneWidget);
      expect(find.text('1 / 7'), findsOneWidget);
      await tap(tester, t.hangulStartBeginLesson);
      expect(find.text(t.hangulStartFirstSyllableExplanation), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a saved lesson resumes the right stage and increments only after completing the exercise',
    (tester) async {
      await tester.runAsync(
        () => HangulStartProgressStore().setCursor(
          const HangulStartCursor('F05', 2, 0),
        ),
      );
      await render(tester, HangulStartEntry.resume);
      expect(find.text('Lesson 5'), findsOneWidget);
      expect(find.text('3 / 7'), findsOneWidget);
      await tap(tester, 'ㄴ');
      await tap(tester, 'ㅏ');
      expect(find.text('나'), findsOneWidget);
      await tap(tester, t.hangulStartNext);
      expect(find.text('3 / 7'), findsOneWidget);
      final saved = await HangulStartProgressStore().load();
      expect(saved.cursor?.stage, 2);
      expect(saved.cursor?.item, 1);
      expect(saved.completed, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final passing in [false, true]) {
    testWidgets(
      '${passing ? '8/10 passes' : '7/10 stays optional'} with replay limit and no reading aids',
      (tester) async {
        var attempts = 0;
        await render(
          tester,
          HangulStartEntry.quiz,
          play: (_, _) async => ++attempts > 1,
        );
        await tap(tester, t.hangulStartTestAction);
        final first = catalog.kurztest.items.first;
        await tap(tester, t.hangulStartTestListen);
        expect(find.text(t.hangulStartAudioError), findsOneWidget);
        expect(find.text(t.hangulStartPlaysLeft(2, 2)), findsOneWidget);
        await tap(tester, t.hangulStartTestListen);
        await tap(tester, t.hangulStartTestListen);
        expect(find.text(t.hangulStartPlaysLeft(0, 2)), findsOneWidget);
        expect(
          tester
              .widget<HangulStartAction>(
                find.widgetWithText(HangulStartAction, t.hangulStartTestListen),
              )
              .onTap,
          isNull,
        );
        expect(find.text(t.phaseTaskRomanizationToggle), findsNothing);
        expect(find.text(t.hangulStartAssemblyHint), findsNothing);
        await tap(tester, first.answer);
        await tap(tester, t.hangulStartCheckAnswer);
        for (var index = 1; index < catalog.kurztest.items.length; index++) {
          final item = catalog.kurztest.items[index];
          final answer = index < (passing ? 8 : 7)
              ? item.answer
              : item.options.firstWhere((word) => word != item.answer);
          await tap(tester, t.hangulStartTestListen);
          await tap(tester, answer);
          await tap(tester, t.hangulStartCheckAnswer);
        }
        expect(find.text(passing ? '8 / 10' : '7 / 10'), findsOneWidget);
        expect(
          find.text(
            passing ? t.hangulStartContinueA11 : t.hangulStartSkipToA11,
          ),
          findsOneWidget,
        );
        expect((await HangulStartProgressStore().load()).passed, passing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'the A1.1 starter practice keeps its reading aid out of assessment',
    (tester) async {
      final tasks = PhaseTaskCatalog.parse(
        jsonDecode(File('assets/data/phase_tasks.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      await render(
        tester,
        HangulStartEntry.map,
        scale: 2,
        screen: PhaseTaskScreen(
          arguments: const PhaseTaskRoute(
            'KP01',
            'KP01:grammar:01',
            hangulStart: true,
          ),
          loader: () async => tasks,
          playAudio: (_) async => true,
          saveAttempt: (_) async {},
        ),
      );
      expect(
        find.byKey(const ValueKey('phase-task-romanization-toggle')),
        findsOneWidget,
      );
      expect(find.text('jeoneun haksaengieyo.'), findsOneWidget);
      await tap(tester, t.phaseTaskAssessment);
      expect(
        find.byKey(const ValueKey('phase-task-romanization-toggle')),
        findsNothing,
      );
      expect(find.text('jeoneun haksaengieyo.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  if (captureDirectory.isNotEmpty) {
    testWidgets(
      'export actual Flutter map and teaching layouts at 320 by 640',
      (tester) async {
        const locale = Locale('de');
        final labels = await AppL10n.delegate.load(locale);
        await render(tester, HangulStartEntry.map, locale: locale);
        expect(
          find.text(labels.todayStartHangul).hitTestable(),
          findsOneWidget,
        );
        await saveCapture(tester, 'flutter-S2-de-320x640');
        await tap(tester, labels.todayStartHangul);
        await tap(tester, labels.hangulStartBeginLesson);
        await saveCapture(tester, 'flutter-S3a-de-320x640');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'export Flutter lesson two and quiz at the approved Figma viewport',
      (tester) async {
        const locale = Locale('de');
        final labels = await AppL10n.delegate.load(locale);
        const viewport = Size(402, 934);
        await tester.runAsync(
          () => HangulStartProgressStore().setCursor(
            const HangulStartCursor('F02', 1, 0),
          ),
        );
        await render(
          tester,
          HangulStartEntry.resume,
          locale: locale,
          viewport: viewport,
        );
        expect(find.text('Lektion 2'), findsOneWidget);
        expect(find.text('오'), findsOneWidget);
        await saveCapture(tester, 'flutter-lesson-02-de-402x934');
        await tester.pumpWidget(const SizedBox.shrink());
        await render(
          tester,
          HangulStartEntry.quiz,
          locale: locale,
          viewport: viewport,
        );
        await tap(tester, labels.hangulStartTestAction);
        await saveCapture(tester, 'flutter-kurztest-de-402x934');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
