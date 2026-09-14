import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:ko_lernen_app/widgets/sori/activity_illustration.dart';
import 'package:ko_lernen_app/widgets/sori/localized_copy.dart';

import 'support/real_fonts.dart';

/// The production catalog uses natural-height cards. Every activity must remain
/// reachable, its title and description must render fully inside its card,
/// and card gestures must never compete with an inner scroll view.
///
/// Retain the 96-case locale / width / text-scale / progress-state matrix.
/// A tall viewport builds the entire catalog so a missing or duplicate entry
/// cannot pass just because another card remains visible.
enum _StateVariant { ready, inProgress, completed, locked }

void main() {
  setUpAll(loadSoriRealFonts);

  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  group('SoriStageCatalogScreen catalog cards', () {
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

                  final cards = tester
                      .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
                      .toList();
                  final expectedCards = entries
                      .where((entry) => entry.id != 'course')
                      .map((entry) => entry.id)
                      .toList();
                  expect(
                    cards.map((card) => card.entry.id),
                    unorderedEquals(expectedCards),
                    reason: 'Every catalog activity must appear exactly once.',
                  );
                  if (tab == SoriStageTab.learn) {
                    // The learning path is the focus action above the grouped
                    // catalog, with a route button when no shell scope exists.
                    final course = entries.singleWhere((e) => e.id == 'course');
                    final context = tester.element(
                      find.byType(SoriStageCatalogScreen),
                    );
                    final courseAction = find.widgetWithText(
                      TextButton,
                      localCopy(context, course.title),
                    );
                    expect(courseAction, findsOneWidget);
                    expect(
                      tester.widget<TextButton>(courseAction).onPressed,
                      isNotNull,
                    );
                  }

                  for (final card in cards) {
                    final cardFinder = find.byWidget(card);
                    expect(
                      find.descendant(
                        of: cardFinder,
                        matching: find.byType(Scrollable),
                      ),
                      findsNothing,
                      reason: '${card.entry.id} must use the page scroll.',
                    );
                    final context = tester.element(cardFinder);
                    final cardBounds = tester.getRect(cardFinder).inflate(.5);
                    for (final copy in [
                      card.entry.title,
                      card.entry.description,
                    ]) {
                      final label = find.descendant(
                        of: cardFinder,
                        matching: find.text(localCopy(context, copy)),
                      );
                      expect(label, findsOneWidget);
                      final text = tester.widget<Text>(label);
                      expect(text.maxLines, isNull);
                      expect(text.overflow, isNot(TextOverflow.ellipsis));
                      final paragraph = tester.renderObject<RenderParagraph>(
                        find.descendant(
                          of: label,
                          matching: find.byType(RichText),
                        ),
                      );
                      expect(paragraph.didExceedMaxLines, isFalse);
                      final bounds = tester.getRect(label);
                      expect(cardBounds.contains(bounds.topLeft), isTrue);
                      expect(cardBounds.contains(bounds.bottomRight), isTrue);
                    }
                    final art = tester.widget<Image>(
                      find.descendant(
                        of: cardFinder,
                        matching: find.byWidgetPredicate(
                          (widget) =>
                              widget is Image &&
                              widget.image is AssetImage &&
                              (widget.image as AssetImage).assetName ==
                                  activityIllustrationAsset(card.entry.id),
                        ),
                      ),
                    );
                    expect(art.fit, BoxFit.contain);
                    expect(tester.takeException(), isNull);
                  }
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
