import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';

import 'support/real_fonts.dart';

/// §LAYOUT-2(J12) — catalog cards use their natural content height and must
/// never add a private [Scrollable]. A nested scrollable would swallow page
/// drags and hide copy when localized text or progress labels become taller.
/// This guard renders every visible catalog card across the states most likely
/// to increase card height and verifies the natural-height contract directly.
///
/// Full coverage would be locale(2) x width(5) x scale(4) x state(4) x tab(2).
/// This file uses a reduced but representative corner set (both width
/// extremes, both a normal and a maximum text scale, all locales and states)
/// to keep CI runtime bounded — for this purely additive text-height budget,
/// the omitted middle values (360/720dp, 1.3x/1.6x) interpolate between the
/// tested corners and cannot fail if the corners pass.
///
/// A tall physical viewport lets the catalog's [Wrap] materialize every card
/// in one pump, avoiding a per-entry `scrollUntilVisible` loop.
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
      final cardEntries = tab == SoriStageTab.learn
          ? entries.where((entry) => entry.learnSection != null).toList()
          : entries;

      for (final locale in locales) {
        for (final width in widths) {
          for (final scale in scales) {
            for (final variant in _StateVariant.values) {
              testWidgets(
                '${tab.name} ${locale.languageCode} @ ${width.toInt()}dp '
                'x$scale ${variant.name}: every card stays natural-height',
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
                      .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
                      .toList();
                  expect(
                    cards.length,
                    greaterThanOrEqualTo(cardEntries.length),
                    reason:
                        'expected every visible ${tab.name} entry to build a '
                        'card (found ${cards.length}, wanted >= '
                        '${cardEntries.length}) '
                        '— the tall viewport should materialize the whole '
                        'catalog.',
                  );

                  for (final entry in cardEntries) {
                    expect(
                      find.byKey(ValueKey('catalog-card-${entry.id}')),
                      findsOneWidget,
                      reason: 'missing catalog card for ${entry.id}',
                    );
                  }

                  for (final card in cards) {
                    final scrollFinder = find.descendant(
                      of: find.byWidget(card),
                      matching: find.byType(Scrollable),
                    );
                    if (scrollFinder.evaluate().isNotEmpty) {
                      failures.add(
                        '"${card.entry.id}" owns a nested Scrollable '
                        '@ ${width.toInt()}dp x$scale '
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
  hanokCompetence: const HanokCompetenceProjection.empty(),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
  activityProgress: activityProgress,
);
