import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('renders the injected shared today snapshot on Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const ReviewPick(dueCount: 12),
            dueCount: 12,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review 12 words in context'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'preview fixture uses injected actions without production writes',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in prefs.getKeys()) key: prefs.get(key),
      };
      String? openedRoute;

      await tester.pumpWidget(
        _host(
          HomeScreen(
            previewMode: true,
            loadTodaySnapshot: () async => const TodayLearningSnapshot(
              pick: ReviewPick(dueCount: 12),
              destination: TodayLearningDestination(route: '/review'),
              dueCount: 12,
            ),
            ensureTodayPackAccess: (_) async => true,
            openTodayRoute: (route, _) async {
              openedRoute = route;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.ensureVisible(find.text('Review now'));
      await tester.tap(find.text('Review now'));
      await tester.pump();

      expect(openedRoute, '/review');
      expect(<String, Object?>{
        for (final key in prefs.getKeys()) key: prefs.get(key),
      }, before);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('keeps one Today action without a legacy dashboard escape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedRoute;
    await tester.pumpWidget(
      _host(
        HomeScreen(
          now: () => DateTime(2026, 8, 11),
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const ReviewPick(dueCount: 12),
            destination: const TodayLearningDestination(route: '/review'),
            dueCount: 12,
          ),
          loadHanokRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
        textScale: 1.3,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final primary = find.byKey(const ValueKey('home-primary-today'));
    final todayHeading = find.byKey(const ValueKey('home-today-heading'));
    final preview = find.byKey(const ValueKey('home-hanok-preview'));
    expect(todayHeading, findsOneWidget);
    expect(find.text('Today · Tuesday'), findsOneWidget);
    expect(primary, findsOneWidget);
    expect(find.byKey(const ValueKey('home-hanok-build-note')), findsOneWidget);
    expect(preview, findsNothing);
    expect(find.byKey(const ValueKey('home-legacy-dashboard')), findsNothing);
    expect(
      find.byKey(const ValueKey('home-legacy-dashboard-toggle')),
      findsNothing,
    );
    final buildNote = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey('home-hanok-build-note')),
        matching: find.byType(SoriCard),
      ),
    );
    expect(buildNote.onTap, isNull);
    expect(
      tester.getTopLeft(todayHeading).dy,
      lessThan(tester.getTopLeft(primary).dy),
    );
    expect(find.text('Review now'), findsOneWidget);
    expect(find.text('Give your safe sentences a voice.'), findsOneWidget);
    expect(find.text('Why review today?'), findsOneWidget);
    expect(
      find.text(
        'So greetings, requests, and answers are easier to reach in the next '
        'matching situation. About 3 minutes · then your path continues.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review now'), findsOneWidget);

    await tester.ensureVisible(find.text('Review now'));
    await tester.pump();
    await tester.tap(find.text('Review now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(openedRoute, '/review');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('keeps one local review action when Today cannot refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? openedRoute;
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => throw StateError('offline'),
          loadHanokRatios: () async =>
              const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
        textScale: 1.3,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Connection paused'), findsOneWidget);
    expect(find.text('Your path is waiting for you.'), findsOneWidget);
    expect(
      find.text(
        'New group and account actions briefly need internet. Your saved '
        'reviews are ready.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review saved words'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      tester
          .widget<SoriButton>(
            find.widgetWithText(SoriButton, 'Review saved words'),
          )
          .variant,
      SoriButtonVariant.filled,
    );

    await tester.ensureVisible(find.text('Review saved words'));
    await tester.pump();
    await tester.tap(find.text('Review saved words'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(openedRoute, '/review');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('offline retry reloads the fixture and restores Today', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async {
            loads++;
            if (loads == 1) throw StateError('offline');
            return const TodayLearningSnapshot(
              pick: ReviewPick(dueCount: 12),
              destination: TodayLearningDestination(route: '/review'),
              dueCount: 12,
            );
          },
          onOpenSavedReview: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(loads, 1);
    final retry = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Try again'),
    );
    retry.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(loads, 2);
    expect(find.text('Review 12 words in context'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('degraded production snapshot uses the offline-safe state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => const TodayLearningSnapshot(
            pick: ReviewPick(dueCount: 12),
            destination: TodayLearningDestination(route: '/review'),
            dueCount: 12,
            availability: TodayLearningAvailability.unavailable,
            unavailableSources: {TodayLearningSource.course},
          ),
          onOpenSavedReview: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Connection paused'), findsOneWidget);
    expect(find.text('Review 12 words in context'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ready empty Today state has exactly one safe CTA', (
    tester,
  ) async {
    var reviewCalls = 0;
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async =>
              const TodayLearningSnapshot(pick: null),
          onOpenSavedReview: () async => reviewCalls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final hero = find.byKey(const ValueKey('home-primary-today'));
    expect(find.text('Review saved words'), findsOneWidget);
    expect(
      find.descendant(of: hero, matching: find.byType(TextButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hero, matching: find.byType(SoriButton)),
      findsNothing,
    );
    tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, 'Review saved words'),
        )
        .onPressed!();
    await tester.pump();
    expect(reviewCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('puts a course can-do ahead of mission numbering', (
    tester,
  ) async {
    String? openedRoute;
    const unit = CourseUnit(
      id: 'a1_ordering',
      level: 'a1',
      order: 3,
      title: CurriculumText(
        ko: '주문과 부탁',
        de: 'Bestellen und bitten',
        en: 'Ordering and requests',
      ),
      canDo: CurriculumText(
        ko: '공손하게 덜 맵게 주문할 수 있어요.',
        de: 'Ich kann weniger scharf bestellen.',
        en: 'I can order less spicy food politely.',
      ),
    );

    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => TodayLearningSnapshot(
            pick: const CoursePick(
              unit: unit,
              missionNumber: 3,
              totalMissions: 36,
              fraction: .25,
              started: false,
            ),
            destination: const TodayLearningDestination(
              route: '/course/mission',
            ),
          ),
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Your real-life action today'), findsOneWidget);
    expect(find.text('Ordering and requests'), findsOneWidget);
    expect(find.text('I can order less spicy food politely.'), findsOneWidget);
    expect(find.text('Practice this action'), findsOneWidget);
    expect(find.text('Mission 3 of 36'), findsNothing);

    await tester.tap(find.text('Practice this action'));
    await tester.pumpAndSettle();
    expect(openedRoute, '/course/mission');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

Widget _host(
  Widget child, {
  RouteFactory? onGenerateRoute,
  double textScale = 1,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateRoute: onGenerateRoute,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child,
  ),
);
