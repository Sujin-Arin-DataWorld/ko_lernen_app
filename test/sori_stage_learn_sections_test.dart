import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/widgets/sori/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// W10 T-L1: the Learn tab renders its catalog in three labeled sections —
/// "Learn today" (the hero + core path), "Explore & practice", and "Review"
/// — in that order, top to bottom. The Games tab is untouched: no section
/// titles at all.
///
/// Note: the `srs` activity's own card title is *also* "Review" in English
/// (same word as the Review section title) — [sectionHeader] below matches
/// the [SoriSectionHeader] widget itself (by its `title` field) so it can
/// never collide with a card's `Text`.
void main() {
  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpCatalog(WidgetTester tester, SoriStageTab tab) async {
    // A tall viewport so every section, hero, and grid card renders in one
    // pass — the grid is a lazily-built SliverChildBuilderDelegate, so a
    // device-sized viewport would leave lower sections unbuilt and their
    // Y positions would be meaningless to compare.
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1), disableAnimations: true),
          child: child!,
        ),
        home: SoriStageCatalogScreen(
          tab: tab,
          loadSnapshot: () async => _snapshot(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  Finder sectionHeader(String title) => find.byWidgetPredicate(
    (widget) => widget is SoriSectionHeader && widget.title == title,
  );

  testWidgets('Learn 탭은 오늘/탐색/복습 세 섹션 제목을 이 순서대로 렌더한다', (tester) async {
    await pumpCatalog(tester, SoriStageTab.learn);

    final todayTitle = sectionHeader('Learn today');
    final exploreTitle = sectionHeader('Explore & practice');
    final reviewTitle = sectionHeader('Review');

    expect(todayTitle, findsOneWidget);
    expect(exploreTitle, findsOneWidget);
    expect(reviewTitle, findsOneWidget);

    final todayY = topOf(tester, todayTitle);
    final exploreY = topOf(tester, exploreTitle);
    final reviewY = topOf(tester, reviewTitle);

    expect(exploreY, greaterThan(todayY));
    expect(reviewY, greaterThan(exploreY));
  });

  testWidgets('각 카드는 자기 섹션 제목보다 아래, 다음 섹션 제목보다 위에 있다', (tester) async {
    await pumpCatalog(tester, SoriStageTab.learn);

    final todayY = topOf(tester, sectionHeader('Learn today'));
    final exploreY = topOf(tester, sectionHeader('Explore & practice'));
    final reviewY = topOf(tester, sectionHeader('Review'));

    // Today section: hero (Vocabulary packs, default hero) + grid cards
    // (Learning path, Grammar) all sit between the Today title and the
    // Explore title.
    for (final title in const ['Vocabulary packs', 'Learning path', 'Grammar']) {
      final y = topOf(tester, find.text(title));
      expect(
        y,
        greaterThan(todayY),
        reason: '$title should be under Learn today',
      );
      expect(
        y,
        lessThan(exploreY),
        reason: '$title should be above Explore & practice',
      );
    }

    // Explore section: representative cards sit between the Explore title
    // and the Review title.
    for (final title in const ['Hangul', 'Nuances & opposites']) {
      final y = topOf(tester, find.text(title));
      expect(
        y,
        greaterThan(exploreY),
        reason: '$title should be under Explore & practice',
      );
      expect(y, lessThan(reviewY), reason: '$title should be above Review');
    }

    // Review section: cards sit below the Review title.
    for (final title in const ['My words']) {
      final y = topOf(tester, find.text(title));
      expect(
        y,
        greaterThan(reviewY),
        reason: '$title should be under Review',
      );
    }
  });

  testWidgets('Review 섹션 제목은 복습 카드가 아닌 모든 카드보다 아래에 있다', (tester) async {
    await pumpCatalog(tester, SoriStageTab.learn);

    final reviewY = topOf(tester, sectionHeader('Review'));

    for (final title in const [
      'Vocabulary packs',
      'Learning path',
      'Grammar',
      'Hangul',
      'Character of the day',
      'Pronunciation',
      'Listening',
      'Real-life scenarios',
      'Small Talk',
      'Nuances & opposites',
    ]) {
      final y = topOf(tester, find.text(title));
      expect(y, lessThan(reviewY), reason: '$title should be above Review');
    }
  });

  testWidgets('Games 탭은 섹션 제목을 렌더하지 않는다', (tester) async {
    await pumpCatalog(tester, SoriStageTab.games);

    expect(find.byType(SoriSectionHeader), findsNothing);
  });
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(pick: null),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  ),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);
