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
import 'package:ko_lernen_app/widgets/sori/button.dart';
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
    await tester.tap(
      find.descendant(of: todayLink, matching: find.byType(SoriButton)),
    );

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
    tester.view.physicalSize = const Size(390, 900);
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
      ),
    );

    expect(find.text('안 맵게 해 주세요.'), findsOneWidget);
    expect(
      find.text(
        '1 expression · 1 secure scene · 1 beam in the construction plan',
      ),
      findsOneWidget,
    );
    final room = find.byKey(const ValueKey('sarangbang-study-room'));
    final record = find.byKey(const ValueKey('sarangbang-today-link'));
    expect(tester.getTopLeft(room).dy, lessThan(tester.getTopLeft(record).dy));

    final openToday = find.text("Open today's scene");
    await tester.ensureVisible(openToday);
    await tester.pumpAndSettle();
    await tester.tap(openToday);
    expect(opens, 1);
    expect(preferences.getKeys(), before);
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
