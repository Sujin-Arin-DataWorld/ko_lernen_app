import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  testWidgets('Hanok shortcut counts refresh after a destination returns', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loads = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: SoriStageHanokScreen(
          worldForTesting: const ColoredBox(color: Colors.transparent),
          loadSnapshot: () async {
            loads++;
            return loads == 1
                ? _snapshot(questDone: false, pendingBojagi: 1)
                : _snapshot(questDone: true, pendingBojagi: 2);
          },
        ),
        routes: {
          '/quests': (routeContext) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(routeContext).pop(),
                child: const Text('Return from quests'),
              ),
            ),
          ),
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(loads, 1);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('hanok-shortcut-count-quests')),
          )
          .data,
      '0 / 1',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('hanok-shortcut-count-bojagi')),
          )
          .data,
      '1',
    );

    await tester.tap(find.text('Quests'));
    await tester.pumpAndSettle();
    expect(find.text('Return from quests'), findsOneWidget);

    await tester.tap(find.text('Return from quests'));
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('hanok-shortcut-count-quests')),
          )
          .data,
      '1 / 1',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('hanok-shortcut-count-bojagi')),
          )
          .data,
      '2',
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Quests, 1 / 1')),
      matchesSemantics(
        label: 'Quests, 1 / 1',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('inactive Hanok defers loading and refreshes on activation', (
    tester,
  ) async {
    var loads = 0;
    Future<SoriStageProgressionSnapshot> loader() async {
      loads++;
      return _snapshot(questDone: true, pendingBojagi: loads);
    }

    Widget app(bool active) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: SoriStageHanokScreen(active: active, loadSnapshot: loader),
    );

    await tester.pumpWidget(app(false));
    await tester.pump();
    expect(loads, 0);

    await tester.pumpWidget(app(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(loads, 1);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('hanok-shortcut-count-bojagi')),
          )
          .data,
      '1',
    );
  });
}

SoriStageProgressionSnapshot _snapshot({
  required bool questDone,
  required int pendingBojagi,
}) => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 1),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 1,
  ),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: 0, b1: 0, b2: 0),
  ),
  quests: [
    QuestProgress(
      questId: 'q_jangdokdae',
      current: questDone ? 15 : 3,
      target: 15,
      active: true,
      completed: questDone,
      completedAtIso: questDone ? '2026-08-15T10:00:00Z' : null,
    ),
  ],
  pendingBojagiCount: pendingBojagi,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);
