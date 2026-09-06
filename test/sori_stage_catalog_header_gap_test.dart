import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';
import 'package:ko_lernen_app/widgets/sori/section_header.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §LAYOUT-1(J10) — the header-to-first-content gap on the catalog root must
/// be exactly one section gap (`Spacing.xl` = 24dp), not the pre-fix
/// `Spacing.xl + padding.bottom` (72dp) double-count. `Storage.lastActivityId`
/// must be null for this measurement — a non-null value inserts an eyebrow +
/// `Spacing.xs` + `SoriPulse` continue-hero band that changes the gap.
///
/// §W10 T-L1 (DECLARED CONTRACT CHANGE): the Learn tab now renders its first
/// section title (`SoriSectionHeader`, "Learn today") right after the
/// collapsing header, and the first card sits under *that* title — not
/// directly under the collapsing header. The single "header-to-first-card"
/// assertion below is split into two for the Learn tab: header → first
/// section title stays `Spacing.xl` (the same gap, just landing on a
/// different widget), and section title → first card is a new, smaller
/// `Spacing.md` gap. The Games tab is untouched (no sections) and keeps the
/// original single-gap assertion.
///
/// Measured before/after this change, at both widths (see W10 PR-B report):
/// - 390dp: old firstCardTop=441 (delta from the pre-change formula=+82,
///   i.e. the inserted section title + its own Spacing.md gap); new
///   sectionTitleTop=359 (== old formula, unchanged), firstCardTop-
///   sectionTitleBottom=12 (Spacing.md).
/// - 1280dp: old firstCardTop=249 (delta +53); new sectionTitleTop=196
///   (== old formula, unchanged), firstCardTop-sectionTitleBottom=12
///   (Spacing.md).
void main() {
  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpCatalog(
    WidgetTester tester,
    SoriStageTab tab, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
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

  double headerPaintExtent(WidgetTester tester) {
    final renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SoriCollapsingHeader),
    );
    return renderSliver.geometry!.paintExtent;
  }

  for (final tab in const [SoriStageTab.learn, SoriStageTab.games]) {
    for (final width in const [390.0, 1280.0]) {
      testWidgets('${tab.name} @ ${width.toInt()}dp: header-to-first-card gap is '
          'Spacing.xl only', (tester) async {
        await pumpCatalog(tester, tab, width: width);

        const paddingTop = 20.0; // Spacing.page.top
        final headerExtent = headerPaintExtent(tester);

        if (tab == SoriStageTab.learn) {
          // §W10 T-L1 (DECLARED CONTRACT CHANGE): first content after the
          // header is now the "Learn today" section title, not a card.
          final sectionTitle = find.byType(SoriSectionHeader).first;
          final sectionTitleTop = tester.getTopLeft(sectionTitle).dy;
          expect(
            sectionTitleTop,
            closeTo(paddingTop + headerExtent + Spacing.xl, 1),
            reason:
                'header paintExtent=$headerExtent; expected header-to-first-'
                'section-title gap Spacing.xl(24) — unchanged from the '
                'pre-T-L1 header-to-first-card gap, just landing on the new '
                'section title widget instead of directly on a card.',
          );

          final sectionTitleBottom = tester.getRect(sectionTitle).bottom;
          final firstCardTop = tester
              .getTopLeft(find.byType(SoriIllustratedCard).first)
              .dy;
          expect(
            firstCardTop,
            closeTo(sectionTitleBottom + Spacing.md, 1),
            reason:
                'expected section-title-to-first-card gap Spacing.md(12) — '
                'new in T-L1, the hero card sits directly under its section '
                'title.',
          );
        } else {
          final firstCardTop = tester
              .getTopLeft(find.byType(SoriIllustratedCard).first)
              .dy;
          expect(
            firstCardTop,
            closeTo(paddingTop + headerExtent + Spacing.xl, 1),
            reason:
                'Games tab is untouched by T-L1 — header paintExtent='
                '$headerExtent; expected gap Spacing.xl(24), not the pre-fix '
                'Spacing.xl + padding.bottom(72) double-count.',
          );
        }

        // Grid-end padding.bottom(48) lives only after the last card — pull it
        // into view first (the grid is a lazily-built SliverChildBuilderDelegate),
        // then jump all the way to the scroll end. At `maxScrollExtent` the
        // content's bottom edge is, by definition, flush with the viewport's
        // bottom edge — so comparing on-screen (paint) coordinates there sidesteps
        // converting between paint position and scroll-content position, which a
        // *pinned* SliverPersistentHeader (this screen's header) makes non-linear.
        final lastCard = find.byType(SoriIllustratedCard).last;
        await tester.scrollUntilVisible(
          lastCard,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        final scrollable = find.byType(Scrollable).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();

        final viewportBottom =
            tester.getTopLeft(scrollable).dy + position.viewportDimension;
        final lastCardBottom = tester.getRect(lastCard).bottom;
        expect(
          viewportBottom - lastCardBottom,
          closeTo(48, 1),
          reason:
              'the 48dp scroll-end margin must live only after the last card '
              '(grid SliverPadding.bottom), not duplicated at the header.',
        );
      });
    }
  }
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
