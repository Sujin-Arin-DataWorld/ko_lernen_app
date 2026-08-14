import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  testWidgets('catalog shows a receipt after returning with a real delta', (
    tester,
  ) async {
    var xp = 4;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: SoriStageCatalogScreen(
          tab: SoriStageTab.learn,
          loadSnapshot: () async => _snapshot(xp),
        ),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  xp += 20;
                  Navigator.pop(context);
                },
                child: const Text('Complete activity'),
              ),
            ),
          ),
        ),
      ),
    );

    // §C-1-11 히어로 카드(단어팩 대형 진입)가 상단에 추가되어 'Course' 타일이
    // 기본 뷰포트의 lazy sliver 밖에 있을 수 있다 — 빌드시킨 뒤(scrollUntil)
    // 뷰포트 안으로 정렬(ensureVisible)하고 탭.
    await tester.scrollUntilVisible(
      find.text('Course'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete activity'));
    await tester.pumpAndSettle();

    expect(find.text('+20 Learning XP'), findsOneWidget);
    expect(
      find.text('Your learning moved the journey forward.'),
      findsOneWidget,
    );
  });
}

SoriStageProgressionSnapshot _snapshot(int xp) => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(pick: null),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  ),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: xp,
  streakDays: 0,
  todayReward: null,
);
