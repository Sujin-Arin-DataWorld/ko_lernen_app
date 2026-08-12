import 'dart:async';
import 'dart:ui' show SemanticsAction;

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

    expect(find.text('Give your safe sentences a voice.'), findsOneWidget);
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
      await tester.ensureVisible(find.text('Review'));
      await tester.tap(find.text('Review'));
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
    expect(find.text('Today first'), findsOneWidget);
    expect(find.text('Give your safe sentences a voice.'), findsOneWidget);
    expect(
      find.text('12 words are ready before anything new is added.'),
      findsOneWidget,
    );
    expect(find.text('Your next action'), findsOneWidget);
    expect(find.text('Review 12 words in context'), findsOneWidget);
    expect(
      find.text('About 3 minutes · then your path continues.'),
      findsOneWidget,
    );
    expect(find.text('Why review today?'), findsOneWidget);
    expect(
      find.text(
        'So greetings, requests, and answers are easier to reach in the next '
        'scene.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review'), findsOneWidget);

    await tester.ensureVisible(find.text('Review'));
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(openedRoute, '/review');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('local Today failure keeps review without claiming offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => throw StateError('offline'),
          loadHanokRatios: () async =>
              const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        ),
        textScale: 1.3,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Connection paused'), findsNothing);
    expect(find.text('Today needs another try'), findsOneWidget);
    expect(find.text('Your saved learning is still safe.'), findsOneWidget);
    expect(
      find.text(
        'Today could not be prepared from the local learning data. Try loading '
        'it again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review saved words'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      tester
          .widget<SoriButton>(find.widgetWithText(SoriButton, 'Try again'))
          .variant,
      SoriButtonVariant.filled,
    );
    expect(find.widgetWithText(TextButton, 'Try again'), findsNothing);

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
            if (loads == 1) {
              return const TodayLearningSnapshot(
                pick: ReviewPick(dueCount: 12),
                destination: TodayLearningDestination(route: '/review'),
                dueCount: 12,
                availability: TodayLearningAvailability.unavailable,
                unavailableReason: TodayLearningUnavailableReason.offline,
              );
            }
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
    expect(find.text('Give your safe sentences a voice.'), findsOneWidget);
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
            unavailableReason: TodayLearningUnavailableReason.offline,
            unavailableSources: {TodayLearningSource.course},
          ),
          onOpenSavedReview: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Connection paused'), findsOneWidget);
    expect(find.text('Give your safe sentences a voice.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('offline without saved reviews exposes retry as the only CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => const TodayLearningSnapshot(
            pick: null,
            availability: TodayLearningAvailability.unavailable,
            unavailableReason: TodayLearningUnavailableReason.offline,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final hero = find.byKey(const ValueKey('home-primary-today'));
    expect(find.text('Connection paused'), findsOneWidget);
    expect(find.text('Review saved words'), findsNothing);
    expect(
      find.descendant(of: hero, matching: find.byType(SoriButton)),
      findsOneWidget,
    );
    expect(find.widgetWithText(SoriButton, 'Try again'), findsOneWidget);
    expect(
      find.descendant(of: hero, matching: find.byType(TextButton)),
      findsNothing,
    );

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

  testWidgets(
    'German 308dp Home distinguishes degraded and healthy-empty states',
    (tester) async {
      tester.view.physicalSize = const Size(308, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          HomeScreen(
            previewMode: true,
            loadTodaySnapshot: () async => const TodayLearningSnapshot(
              pick: ReviewPick(dueCount: 12),
              destination: TodayLearningDestination(route: '/review'),
              dueCount: 12,
              availability: TodayLearningAvailability.unavailable,
              unavailableReason: TodayLearningUnavailableReason.offline,
              unavailableSources: {TodayLearningSource.course},
            ),
            onOpenSavedReview: () async {},
          ),
          locale: const Locale('de'),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('Verbindung pausiert'), findsOneWidget);
      expect(find.text('Dein Weg wartet auf dich.'), findsOneWidget);
      expect(
        find.text(
          'Neue Gruppen- und Kontoaktionen brauchen kurz Internet. Deine '
          'gespeicherten Wiederholungen sind bereit.',
        ),
        findsOneWidget,
      );
      expect(find.text('Jetzt sicher möglich'), findsOneWidget);
      expect(
        find.text(
          'Gespeicherte Wörter wiederholen und bisherige Inhalte ansehen.',
        ),
        findsOneWidget,
      );
      final savedReview = find.widgetWithText(
        SoriButton,
        'Gespeicherte Wörter wiederholen',
      );
      final retry = find.widgetWithText(TextButton, 'Erneut verbinden');
      expect(savedReview, findsOneWidget);
      expect(retry, findsOneWidget);
      expect(tester.getSize(savedReview).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      final savedReviewSemantics = tester
          .getSemantics(savedReview)
          .getSemanticsData();
      expect(savedReviewSemantics.label, 'Gespeicherte Wörter wiederholen');
      expect(savedReviewSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(find.text('Für heute geschafft'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(
        _host(
          HomeScreen(
            previewMode: true,
            loadTodaySnapshot: () async =>
                const TodayLearningSnapshot(pick: null),
            onOpenSavedReview: () async {},
          ),
          locale: const Locale('de'),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final hero = find.byKey(const ValueKey('home-primary-today'));
      expect(find.text('Verbindung pausiert'), findsNothing);
      expect(find.text('Für heute geschafft'), findsOneWidget);
      expect(
        find.descendant(of: hero, matching: find.byType(TextButton)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: hero, matching: find.byType(SoriButton)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('German review-first hierarchy stays accessible at 308dp 1.3x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        HomeScreen(
          previewMode: true,
          loadTodaySnapshot: () async => const TodayLearningSnapshot(
            pick: ReviewPick(dueCount: 12),
            destination: TodayLearningDestination(route: '/review'),
            dueCount: 12,
          ),
          onOpenSavedReview: () async {},
        ),
        locale: const Locale('de'),
        textScale: 1.3,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Heute zuerst'), findsOneWidget);
    expect(
      find.text('Gib deinen sicheren Sätzen eine Stimme.'),
      findsOneWidget,
    );
    expect(
      find.text('12 Wörter sind bereit, bevor etwas Neues dazukommt.'),
      findsOneWidget,
    );
    expect(find.text('Deine nächste Handlung'), findsOneWidget);
    expect(find.text('12 Wörter im Kontext wiederholen'), findsOneWidget);
    expect(
      find.text('ca. 3 Minuten · danach geht dein Weg weiter'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.widgetWithText(SoriButton, 'Wiederholen'));
    await tester.pump();
    final review = find.widgetWithText(SoriButton, 'Wiederholen');
    expect(review, findsOneWidget);
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
    final reviewSemantics = tester.getSemantics(review).getSemanticsData();
    expect(reviewSemantics.label, 'Wiederholen');
    expect(reviewSemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(tester.takeException(), isNull);

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'production connectivity transition opens offline state and reloads on reconnect',
    (tester) async {
      final connectivity = StreamController<TodayNetworkStatus>.broadcast();
      addTearDown(connectivity.close);
      var online = true;
      var loads = 0;

      await tester.pumpWidget(
        _host(
          HomeScreen(
            previewMode: true,
            connectivityUpdates: connectivity.stream,
            loadTodaySnapshot: () async {
              loads++;
              return TodayLearningSnapshot(
                pick: const ReviewPick(dueCount: 12),
                destination: const TodayLearningDestination(route: '/review'),
                dueCount: 12,
                availability: online
                    ? TodayLearningAvailability.ready
                    : TodayLearningAvailability.unavailable,
                unavailableReason: online
                    ? null
                    : TodayLearningUnavailableReason.offline,
              );
            },
            onOpenSavedReview: () async {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Give your safe sentences a voice.'), findsOneWidget);

      online = false;
      connectivity.add(TodayNetworkStatus.offline);
      await tester.pump();
      expect(find.text('Connection paused'), findsOneWidget);
      final beforeReconnect = loads;

      online = true;
      connectivity.add(TodayNetworkStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(loads, greaterThan(beforeReconnect));
      expect(find.text('Give your safe sentences a voice.'), findsOneWidget);
      expect(find.text('Connection paused'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

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
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
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
