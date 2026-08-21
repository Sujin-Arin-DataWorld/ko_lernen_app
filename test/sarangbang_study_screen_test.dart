import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pending_reward_card.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  testWidgets('opens the recommendation chosen by the existing engine', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: ReviewPick(dueCount: 12)),
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
          onOpenRecommendation: (_) async => opens++,
        ),
      ),
    );
    await tester.pump();

    final todayLink = find.byKey(const ValueKey('sarangbang-today-link'));
    expect(todayLink, findsOneWidget);
    final openToday = find.byKey(const ValueKey('sarangbang-open-today'));
    await tester.scrollUntilVisible(
      openToday,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(openToday);
    await tester.pump();
    await tester.tap(openToday);

    expect(opens, 1);
  });

  testWidgets('renders the saved room without normalizing storage', (
    tester,
  ) async {
    const rawPlacements =
        '{"sarangbang":{"floor_center":"decoration_soban"},'
        '"anbang":{"floor_center":"decoration_soban"}}';
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_owned_decor': <String>['decoration_soban'],
      'kl_room_placements_v2': rawPlacements,
    });
    await Storage.init();

    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: const ReviewPick(dueCount: 12)),
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('sarangbang-study-room')), findsOneWidget);
    expect(find.byType(SoriDecorationImage), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(
      find.byKey(const ValueKey('sarangbang-furnish-card')),
      findsOneWidget,
    );
    expect(find.text('Furnish'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_room_placements_v2'), rawPlacements);
  });

  testWidgets('uses a side-by-side study and room layout at tablet width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: const ReviewPick(dueCount: 12)),
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
        ),
      ),
    );
    await tester.pump();

    final todayLink = find.byKey(const ValueKey('sarangbang-today-link'));
    final room = find.byKey(const ValueKey('sarangbang-study-room'));
    expect(todayLink, findsOneWidget);
    expect(room, findsOneWidget);
    expect(
      tester.getTopLeft(todayLink).dx,
      greaterThan(tester.getTopLeft(room).dx),
    );
    expect(
      tester.getTopLeft(todayLink).dy,
      closeTo(tester.getTopLeft(room).dy, 0.1),
    );
  });

  testWidgets('hides the reward banner when no bojagi is openable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: const ReviewPick(dueCount: 12)),
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PendingRewardCard), findsNothing);
  });

  testWidgets('surfaces the reward banner when a bojagi is openable', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
    // Seed one openable box from a real quest so the discovery banner shows
    // at the study surface without ever opening the Quests screen.
    await Storage.addPendingBox(kQuestById.keys.first);

    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: const ReviewPick(dueCount: 12)),
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PendingRewardCard), findsOneWidget);
  });

  testWidgets('03C preview shows the actual earned expression and record', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await SharedPreferences.getInstance();
    final before = preferences.getKeys();
    var opens = 0;

    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen.preview(
          todaySnapshot: TodayLearningSnapshot(
            pick: const ReviewPick(dueCount: 12),
          ),
          receipt: const HanokLearningReceipt(
            safeSceneCount: 1,
            safeScenesTowardNextBeam: 1,
            plannedBeamCount: 1,
            earnedExpressionCount: 1,
            latestSafeScenarioId: 'restaurant_scene',
            latestSafeExpressionKo: '안 맵게 해 주세요.',
          ),
          room: const SarangbangRoomState(
            placements: {
              PersonalRoomSurface.sarangbang: {
                'floor_center': 'decoration_soban',
              },
            },
            ownedDecor: {'decoration_soban'},
          ),
          onOpenRecommendation: (_) async => opens++,
        ),
        locale: const Locale('de'),
        textScale: 2,
        size: const Size(320, 640),
        safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );

    final appBar = tester.widget<SoriAppBar>(find.byType(SoriAppBar));
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(SoriAppBar),
        matching: find.text(appBar.title),
      ),
    );
    expect(appBar.title, 'Sarangbang');
    expect(title.maxLines, isNotNull);
    expect(title.overflow, TextOverflow.clip);

    final welcome = find.byKey(const ValueKey('sarangbang-welcome'));
    expect(
      find.descendant(of: welcome, matching: find.text('Dein Lernzimmer')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Dein Lernzimmer')).dy,
      lessThan(tester.getTopLeft(find.text('Was du heute gelernt hast')).dy),
    );
    final room = find.byKey(const ValueKey('sarangbang-study-room'));
    await tester.scrollUntilVisible(
      room,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    final expression = find.text('안 맵게 해 주세요.');
    expect(expression, findsOneWidget);
    expect(find.descendant(of: room, matching: expression), findsOneWidget);
    expect(
      find.text('1 Ausdruck · 1 gemeisterte Szene · 1 Balken im Bauplan'),
      findsOneWidget,
    );
    final record = find.byKey(const ValueKey('sarangbang-today-link'));
    final furnish = find.byKey(const ValueKey('sarangbang-furnish-card'));
    expect(tester.getTopLeft(room).dy, lessThan(tester.getTopLeft(record).dy));
    expect(
      tester.getTopLeft(record).dy,
      lessThan(tester.getTopLeft(furnish).dy),
    );
    final actions = find.byKey(const ValueKey('sarangbang-return-actions'));
    await tester.scrollUntilVisible(
      actions,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      tester.getTopLeft(furnish).dy,
      lessThan(tester.getTopLeft(actions).dy),
    );
    expect(find.text('Zur heutigen Szene'), findsOneWidget);
    expect(find.text('Zum Hof'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final openToday = find.byKey(const ValueKey('sarangbang-open-today'));
    await tester.ensureVisible(openToday);
    await tester.pumpAndSettle();
    await tester.tap(openToday);
    expect(opens, 1);
    expect(preferences.getKeys(), before);
  });

  testWidgets('partial Today data is retryable and never opens a stale route', (
    tester,
  ) async {
    var attempts = 0;
    var opens = 0;
    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async {
            attempts += 1;
            if (attempts == 1) {
              return TodayLearningSnapshot(
                pick: const ReviewPick(dueCount: 12),
                destination: const TodayLearningDestination(route: '/review'),
                dueCount: 12,
                availability: TodayLearningAvailability.unavailable,
                unavailableReason: TodayLearningUnavailableReason.localData,
                unavailableSources: const {TodayLearningSource.review},
              );
            }
            return TodayLearningSnapshot(
              pick: const ReviewPick(dueCount: 12),
              destination: const TodayLearningDestination(route: '/review'),
              dueCount: 12,
            );
          },
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
          loadRoomState: () async => const SarangbangRoomState(),
          onOpenRecommendation: (_) async => opens += 1,
        ),
        locale: const Locale('en'),
        size: const Size(390, 844),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sarangbang-today-unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sarangbang-open-today')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('sarangbang-today-unavailable-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sarangbang-today-unavailable')),
      findsNothing,
    );
    final openToday = find.byKey(const ValueKey('sarangbang-open-today'));
    await tester.scrollUntilVisible(
      openToday,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(openToday);
    expect(opens, 1);
  });

  testWidgets('loading and failed reads use canonical retry states', (
    tester,
  ) async {
    final pending = Completer<TodayLearningSnapshot>();
    var attempts = 0;
    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () {
            attempts += 1;
            if (attempts == 1) {
              return pending.future;
            }
            return Future.value(
              TodayLearningSnapshot(pick: const ReviewPick(dueCount: 3)),
            );
          },
          loadLearningReceipt: () async => const HanokLearningReceipt.empty(),
          loadRoomState: () async => const SarangbangRoomState(),
        ),
        locale: const Locale('de'),
        size: const Size(320, 640),
        textScale: 2,
      ),
    );

    expect(find.byType(AppLoading), findsOneWidget);
    pending.completeError(StateError('fixture failure'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppError), findsOneWidget);
    expect(
      find.text('Etwas ist schiefgelaufen. Bitte versuche es erneut.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppError), findsNothing);
    expect(find.byKey(const ValueKey('sarangbang-welcome')), findsOneWidget);
  });

  testWidgets('DE and EN content reflows across the locked viewport matrix', (
    tester,
  ) async {
    const viewports = <({Size size, double scale})>[
      (size: Size(320, 640), scale: 2),
      (size: Size(360, 400), scale: 1),
      (size: Size(390, 844), scale: 1.3),
      (size: Size(720, 1024), scale: 1.3),
      (size: Size(1280, 900), scale: 1.3),
    ];
    const receipt = HanokLearningReceipt(
      safeSceneCount: 1,
      safeScenesTowardNextBeam: 1,
      plannedBeamCount: 1,
      earnedExpressionCount: 1,
      latestSafeScenarioId: 'restaurant_scene',
      latestSafeExpressionKo: '안 맵게 해 주세요.',
    );

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final viewport in viewports) {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          _host(
            SarangbangStudyScreen.preview(
              key: ValueKey(
                'sarangbang-${locale.languageCode}-${viewport.size.width}',
              ),
              todaySnapshot: TodayLearningSnapshot(
                pick: const ReviewPick(dueCount: 12),
                destination: const TodayLearningDestination(route: '/review'),
              ),
              receipt: receipt,
            ),
            locale: locale,
            textScale: viewport.scale,
            size: viewport.size,
            safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
          ),
        );

        final actions = find.byKey(const ValueKey('sarangbang-return-actions'));
        await tester.scrollUntilVisible(
          actions,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(const ValueKey('sarangbang-study-room')),
          findsOneWidget,
        );
        expect(find.text('안 맵게 해 주세요.'), findsOneWidget);
        expect(actions, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = Size.zero,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: safeInsets,
      viewPadding: safeInsets,
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child,
  ),
);
