import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
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
          onOpenRecommendation: (_) async => opens++,
        ),
      ),
    );
    await tester.pump();

    final mission = find.byKey(const ValueKey('sarangbang-study-mission'));
    expect(mission, findsOneWidget);
    await tester.tap(
      find.descendant(of: mission, matching: find.byType(SoriButton)),
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
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('sarangbang-study-room')), findsOneWidget);
    expect(find.byType(SoriDecorationImage), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

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
        ),
      ),
    );
    await tester.pump();

    final mission = find.byKey(const ValueKey('sarangbang-study-mission'));
    final room = find.byKey(const ValueKey('sarangbang-study-room'));
    expect(mission, findsOneWidget);
    expect(room, findsOneWidget);
    expect(
      tester.getTopLeft(room).dx,
      greaterThan(tester.getTopLeft(mission).dx),
    );
    expect(
      tester.getTopLeft(room).dy,
      closeTo(tester.getTopLeft(mission).dy, 0.1),
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
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PendingRewardCard), findsOneWidget);
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
