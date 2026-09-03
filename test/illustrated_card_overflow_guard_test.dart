import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';

import 'support/real_fonts.dart';

/// §LAYOUT-2(J12) — `illustrated_card.dart`'s `SingleChildScrollView`
/// fallback (`ValueKey('sori-illustrated-card-body-scroll')`) is a safety
/// net for when `_cellAspectRatio`'s `TextPainter` measurement undershoots
/// the actual rendered footer. If it is ever *scrollable*
/// (`maxScrollExtent > 0`), the measurement contract is broken — a card
/// silently swallowed vertical drags meant for the page scroll instead of
/// starting/stopping a start button press. This guard keeps that net dark
/// across the states most likely to defeat the title-height-dominated cell
/// budget — in particular the numeric progress suffix (`_StateLabel`'s
/// ` · $current / $target`), which `footerLabels` did not measure before
/// this PR.
///
/// Full coverage would be locale(2) x width(5) x scale(4) x state(4) x tab(2).
/// This file uses a reduced but representative corner set (both width
/// extremes, both a normal and a maximum text scale, all locales and states)
/// to keep CI runtime bounded — for this purely additive text-height budget,
/// the omitted middle values (360/720dp, 1.3x/1.6x) interpolate between the
/// tested corners and cannot fail if the corners pass.
///
/// A tall physical viewport is used so the whole lazily-built
/// `SliverChildBuilderDelegate` grid materializes in a single pump —
/// avoiding a per-entry `scrollUntilVisible` loop while still exercising
/// every card.
///
/// `PackCard` (vocab_packs grid) shares `SoriIllustratedCard`'s fallback but
/// is sized by a *different*, private measurer
/// (`vocab_packs_screen.dart:_packCardMainAxisExtent`) that this file does
/// not attempt to reproduce — a fixture height picked by hand here would
/// test this file's own guess, not that measurer's real contract. Left as a
/// follow-up (flagged separately) rather than shipped inaccurate.
enum _StateVariant { ready, inProgress, completed, locked }

void main() {
  setUpAll(loadSoriRealFonts);

  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  group('SoriStageCatalogScreen grid cards', () {
    const widths = [320.0, 390.0, 1280.0];
    const scales = [1.0, 2.0];
    const locales = [Locale('de'), Locale('en')];

    Map<String, SoriActivityProgress> progressFor(
      List<ActivityCatalogEntry> entries,
      _StateVariant variant,
    ) {
      final map = <String, SoriActivityProgress>{};
      for (final entry in entries) {
        switch (variant) {
          case _StateVariant.ready:
            map[entry.id] = SoriActivityProgress(
              activityId: entry.id,
              state: SoriActivityState.ready,
            );
          case _StateVariant.inProgress:
            map[entry.id] = SoriActivityProgress(
              activityId: entry.id,
              state: SoriActivityState.inProgress,
              current: 37,
              target: 100,
            );
          case _StateVariant.completed:
            map[entry.id] = SoriActivityProgress(
              activityId: entry.id,
              state: SoriActivityState.completed,
              current: 999,
              target: 999,
            );
          case _StateVariant.locked:
            // Forcing `locked` on an entry whose `unlock.explanation` is
            // null would null-check-crash `_StateLabel` — only override
            // entries that actually carry a locked explanation; the rest
            // keep their natural (unlocked) state for this pass.
            if (entry.unlock.explanation != null) {
              map[entry.id] = SoriActivityProgress(
                activityId: entry.id,
                state: SoriActivityState.locked,
              );
            }
        }
      }
      return map;
    }

    for (final tab in const [SoriStageTab.learn, SoriStageTab.games]) {
      final entries = soriActivityCatalog
          .where((entry) => entry.tab == tab)
          .toList();

      for (final locale in locales) {
        for (final width in widths) {
          for (final scale in scales) {
            for (final variant in _StateVariant.values) {
              testWidgets(
                '${tab.name} ${locale.languageCode} @ ${width.toInt()}dp '
                'x$scale ${variant.name}: no card scrolls its body',
                (tester) async {
                  tester.view.physicalSize = Size(width, 12000);
                  tester.view.devicePixelRatio = 1;
                  addTearDown(tester.view.resetPhysicalSize);
                  addTearDown(tester.view.resetDevicePixelRatio);

                  await tester.pumpWidget(
                    MaterialApp(
                      theme: AppTheme.light,
                      locale: locale,
                      supportedLocales: AppL10n.supportedLocales,
                      localizationsDelegates: AppL10n.localizationsDelegates,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(scale),
                          disableAnimations: true,
                        ),
                        child: child!,
                      ),
                      home: SoriStageCatalogScreen(
                        tab: tab,
                        loadSnapshot: () async =>
                            _snapshot(progressFor(entries, variant)),
                      ),
                    ),
                  );
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));

                  final failures = <String>[];
                  final cards = tester
                      .widgetList<SoriIllustratedCard>(
                        find.byType(SoriIllustratedCard),
                      )
                      .toList();
                  expect(
                    cards.length,
                    greaterThanOrEqualTo(entries.length),
                    reason:
                        'expected every ${tab.name} entry to build a card '
                        '(found ${cards.length}, wanted >= ${entries.length}) '
                        '— the tall viewport should force the whole lazy '
                        'grid to materialize.',
                  );

                  for (final card in cards) {
                    if (card.shrinkWrap) {
                      continue; // hero card — no fallback scroll possible.
                    }
                    final scrollFinder = find.descendant(
                      of: find.byWidget(card),
                      matching: find.byType(Scrollable),
                    );
                    if (scrollFinder.evaluate().isEmpty) {
                      continue;
                    }
                    final position = tester
                        .state<ScrollableState>(scrollFinder.first)
                        .position;
                    if (position.maxScrollExtent > 0.5) {
                      failures.add(
                        '"${card.title}": maxScrollExtent='
                        '${position.maxScrollExtent.toStringAsFixed(1)}px '
                        'over budget @ ${width.toInt()}dp x$scale '
                        '${locale.languageCode} ${variant.name}',
                      );
                    }
                  }

                  expect(failures, isEmpty, reason: failures.join('\n'));
                },
              );
            }
          }
        }
      }
    }
  });
}

SoriStageProgressionSnapshot _snapshot(
  Map<String, SoriActivityProgress> activityProgress,
) => SoriStageProgressionSnapshot(
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
  activityProgress: activityProgress,
);
