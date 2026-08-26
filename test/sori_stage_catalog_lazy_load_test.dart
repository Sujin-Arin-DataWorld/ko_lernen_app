import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

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

void main() {
  testWidgets(
    'active:false 탭은 loadSnapshot 을 호출하지 않는다 (P4-2 lazy load)',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SoriStageCatalogScreen(
            tab: SoriStageTab.games,
            active: false,
            loadSnapshot: () async {
              calls++;
              return _snapshot();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, 0);
    },
  );

  testWidgets(
    '탭이 나중에 active 가 되면 그때 loadSnapshot 을 1회 호출한다',
    (tester) async {
      var calls = 0;
      var active = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => active = true),
                  child: const Text('activate'),
                ),
                Expanded(
                  child: SoriStageCatalogScreen(
                    tab: SoriStageTab.games,
                    active: active,
                    loadSnapshot: () async {
                      calls++;
                      return _snapshot();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);

      await tester.tap(find.text('activate'));
      await tester.pumpAndSettle();

      expect(calls, 1);
    },
  );

  testWidgets(
    '비활성화 후 재활성화하면 재활성화마다 정확히 1회씩 로드한다 '
    '(재활성화 계약 — 3회 이상 금지)',
    (tester) async {
      var calls = 0;
      var active = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => active = true),
                  child: const Text('activate'),
                ),
                TextButton(
                  onPressed: () => setState(() => active = false),
                  child: const Text('deactivate'),
                ),
                Expanded(
                  child: SoriStageCatalogScreen(
                    tab: SoriStageTab.games,
                    active: active,
                    loadSnapshot: () async {
                      calls++;
                      return _snapshot();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);

      await tester.tap(find.text('activate'));
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.tap(find.text('deactivate'));
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.tap(find.text('activate'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    },
  );
}
