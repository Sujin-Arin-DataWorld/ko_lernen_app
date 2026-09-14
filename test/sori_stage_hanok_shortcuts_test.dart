import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

import 'support/hanok_competence_fixture.dart';

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

    expect(find.byType(SarangchaeStageArtwork), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sarangchae-stage-artwork-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hanok-map-tap-hint')), findsNothing);

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

    await tester.tap(find.text('Tasks'));
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
      tester.getSemantics(find.bySemanticsLabel('Tasks, 1 / 1')),
      matchesSemantics(
        label: 'Tasks, 1 / 1',
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

  testWidgets('selecting earned history updates the hero and lesson together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final construction = _constructionFixture();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: SoriStageHanokScreen(
          loadConstruction: () async => construction,
          loadSnapshot: () async => _snapshot(
            questDone: false,
            pendingBojagi: 0,
            hanokCompetence: hanokCompetenceFixture(
              a1Completed: 8,
              a1Total: 16,
            ),
          ),
        ),
        routes: {
          '/quests': (routeContext) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(routeContext).pop(),
                child: const Text('Return from history test'),
              ),
            ),
          ),
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('sarangchae-stage-artwork-8')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sarangchae-stage-choice-5')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('sarangchae-stage-choice-5')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sarangchae-stage-artwork-5')),
      findsOneWidget,
    );
    expect(find.text('Title 5'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hanok-shortcut-quests')),
      -240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('hanok-shortcut-quests')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return from history test'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sarangchae-stage-artwork-8')),
      findsOneWidget,
    );
    expect(find.text('Title 8'), findsOneWidget);
  });

  testWidgets('Hanok Stage shortcuts stay complete at 320dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: SoriStageHanokScreen(
          loadSnapshot: () async =>
              _snapshot(questDone: false, pendingBojagi: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hanok-shortcut-bojagi')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    for (final id in const ['quests', 'dojang', 'bojagi']) {
      final tile = find.byKey(ValueKey('hanok-shortcut-$id'));
      final label = tester.widget<Text>(
        find.byKey(ValueKey('hanok-shortcut-label-$id')),
      );
      expect(tester.getSize(tile).width, greaterThanOrEqualTo(270));
      expect(label.maxLines, isNull);
      expect(label.overflow, isNull);
    }
    expect(tester.takeException(), isNull);
  });
}

SoriStageProgressionSnapshot _snapshot({
  required bool questDone,
  required int pendingBojagi,
  HanokCompetenceProjection? hanokCompetence,
}) => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 1),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 1,
  ),
  hanokCompetence: hanokCompetence ?? const HanokCompetenceProjection.empty(),
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

SarangchaeConstruction
_constructionFixture() => SarangchaeConstruction.fromJson({
  'id': 'sarangchae-v3-16',
  'canonicalSha256': SarangchaeConstruction.canonicalSha256,
  'completedStage': SarangchaeConstruction.stageCount,
  'stages': [
    for (
      var sequence = 1;
      sequence <= SarangchaeConstruction.stageCount;
      sequence++
    )
      {
        'stageId': sequence == SarangchaeConstruction.stageCount
            ? 'sarangchae-complete'
            : 'stage-$sequence',
        'sequence': sequence,
        'assetPath':
            'assets/illustrations/personal_hanok_v3/sarangchae/stage_01_site.png',
        'sha256': sequence == SarangchaeConstruction.stageCount
            ? SarangchaeConstruction.canonicalSha256
            : 'fixture-$sequence',
        'term': '부재',
        for (final field in const [
          'gloss',
          'chapter',
          'question',
          'body',
          'caption',
        ])
          field: const {'ko': '설명', 'en': 'Detail', 'de': 'Detail'},
        'title': {
          'ko': '제목 $sequence',
          'en': 'Title $sequence',
          'de': 'Titel $sequence',
        },
      },
  ],
});
