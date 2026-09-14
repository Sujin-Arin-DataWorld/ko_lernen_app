import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';

import 'support/real_fonts.dart';

// Full original portrait and readable status replace retired shrinking map chrome.
const _bottomTabReserve = 80.0;
const _viewportSize = Size(390, 844);

void main() {
  setUpAll(loadSoriRealFonts);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  Future<void> settle(WidgetTester tester) async {
    // The progression snapshot resolves asynchronously and feeds the shortcut
    // counts. Poll a few frames instead of guessing one fixed delay.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget app({double textScale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: SoriStageHanokScreen(loadSnapshot: () async => _snapshot()),
  );

  testWidgets('keeps header and complete original preview visible at 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = _viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await settle(tester);

    final fold = _viewportSize.height - _bottomTabReserve;

    // `SoriCollapsingHeader` itself builds a sliver (`SliverLayoutBuilder`),
    // which `tester.getRect` cannot measure directly — its own expanded
    // content layer (a plain `Opacity` box) carries this fixed key.
    expect(find.byType(SoriCollapsingHeader), findsOneWidget);
    final header = find.byKey(
      const ValueKey('sori-collapsing-header-expanded'),
    );
    final map = find.byKey(const ValueKey('hanok-full-preview'));
    final shortcut = find.byKey(const ValueKey('hanok-shortcut-quests'));

    expect(header, findsOneWidget);
    expect(map, findsOneWidget);
    expect(shortcut, findsOneWidget);

    // Header, preview, and shortcuts must be fully on-screen.
    for (final finder in [header, map]) {
      final rect = tester.getRect(finder);
      expect(
        rect.bottom,
        lessThanOrEqualTo(fold),
        reason: '$finder bottom ${rect.bottom} exceeds the fold $fold',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the complete portrait scrolls normally without shrinking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(textScale: 2));
    await settle(tester);

    final mapKey = find.byKey(const ValueKey('hanok-full-preview'));
    expect(mapKey, findsOneWidget);
    final expandedHeight = tester.getRect(mapKey).height;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(seconds: 1));

    final scrolledRect = tester.getRect(mapKey);
    expect(scrolledRect.height, expandedHeight);
    expect(scrolledRect.top, lessThan(kToolbarHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without exceptions at textScale 1.6', (tester) async {
    tester.view.physicalSize = _viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(textScale: 1.6));
    await settle(tester);

    // skipOffstage:false — at 1.6x text scale these can legitimately sit
    // beyond the fold; this test only asserts they exist and nothing threw.
    expect(
      find.byKey(const ValueKey('hanok-full-preview'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hanok-shortcut-quests'), skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 1),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 1,
  ),
  hanokCompetence: const HanokCompetenceProjection.empty(),
  quests: [
    QuestProgress(
      questId: 'q_jangdokdae',
      current: 3,
      target: 15,
      active: true,
      completed: false,
      completedAtIso: null,
    ),
  ],
  pendingBojagiCount: 1,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);
