import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

import 'support/hanok_competence_fixture.dart';
import 'support/real_fonts.dart';

/// Today's compact Hanok summary reports confirmed learning-path units and
/// opens the full Hanok tab. Detailed construction terms belong to that tab.
void main() {
  setUpAll(() async {
    await loadSoriRealFonts();
    // Warm the real mapping outside the widget test's fake clock.
    await SarangchaeConstruction.load();
  });
  testWidgets(
    'Hanok summary uses learning-path terminology and opens the Hanok tab',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SoriStageTodayScreen(
              loadSnapshot: () async => _snapshot(),
              now: () => DateTime(2026, 8, 14, 9),
            ),
          ),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: Text(settings.name ?? 'route')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final summary = find.byKey(const ValueKey('today-hanok-summary'));
      expect(summary, findsOneWidget);
      expect(
        find.textContaining('Lernpfad-Einheiten bestätigt'),
        findsOneWidget,
      );
      final owned = tester.widget<Text>(
        find.byKey(const ValueKey('today-hanok-owned-stages')),
      );
      final t = AppL10n.of(tester.element(summary));
      expect(owned.data, t.sarangchaeConstructionProgress(8, 16));
      expect(find.byType(HanokV3Preview), findsNothing);
      expect(find.text(t.soriStageHanokUpdating), findsNothing);
      expect(tester.getSize(summary).height, greaterThanOrEqualTo(48));

      await tester.tap(summary);
      await tester.pumpAndSettle();

      expect(find.text('/hanok'), findsOneWidget);
    },
  );

  for (final language in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final owned in [0, 1, 8, 16]) {
        testWidgets(
          'Today reports owned $owned separately from learning in $language at $scale',
          (tester) async {
            tester.view.physicalSize = const Size(320, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                locale: Locale(language),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: SoriStageTodayScreen(
                  loadSnapshot: () async => _snapshot(owned: owned),
                  now: () => DateTime(2026, 10, 31, 9),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            final summary = find.byKey(const ValueKey('today-hanok-summary'));
            await tester.scrollUntilVisible(
              summary,
              240,
              scrollable: find.byType(Scrollable).first,
            );
            await Scrollable.ensureVisible(
              tester.element(summary),
              alignment: .5,
            );
            await tester.pump();
              if (owned > 0) {
                await tester.runAsync(() => SarangchaeConstruction.load());
                await tester.pump();
              }
            final t = AppL10n.of(tester.element(summary));
            expect(
              find.text(t.sarangchaeConstructionProgress(owned, 16)),
              findsOneWidget,
            );
            expect(
              find.text(
                t.soriStageConfirmedUnits(
                  12,
                  _snapshot().hanokCompetence.totalUnitCount,
                ),
              ),
              findsOneWidget,
            );
            expect(find.byType(HanokV3Preview), findsNothing);
            expect(find.text(t.soriStageHanokUpdating), findsNothing);
              if (owned <= 1) {
              expect(find.byType(SarangchaeStageArtwork), findsNothing);
            } else {
              final artwork = tester.widget<SarangchaeStageArtwork>(
                find.byType(SarangchaeStageArtwork),
              );
              expect(artwork.earnedStageCount, owned);
            }
            expect(tester.getSize(summary).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

SoriStageProgressionSnapshot _snapshot({int owned = 8}) =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      // a1/a2/b1 완료 + b2 < 50% → computeStage 는 HanokStage.sideBuilding
      // (hanok_stage.dart:94) — hanokStageTerm 이 hanokStageDisplayName 과
      // 달라지는 세 단계 중 하나(hanok_stage_names.dart 주석).
      hanokCompetence: hanokCompetenceFixture(
        a1Completed: 4,
        a2Completed: 4,
        b1Completed: 4,
      ),
      wallet: YeopjeonWallet.grandfather(sarangchaeStage: owned, b2Stage: 0),
      quests: const [],
      pendingBojagiCount: 0,
      stampCount: 0,
      xp: 0,
      streakDays: 0,
      todayReward: null,
    );
