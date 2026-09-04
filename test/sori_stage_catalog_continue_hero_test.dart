import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sori_stage_pump.dart';

/// §E4: 마지막으로 연 활동이 있으면 그 활동이 "Weiter mit …" 히어로로
/// 승격한다 — 없거나 다른 탭 활동이면 기존 기본(vocab_packs/daily_game)
/// 으로 되돌아간다.
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

Widget _app(SoriStageTab tab) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: SoriStageCatalogScreen(
    tab: tab,
    loadSnapshot: () async => _snapshot(),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
  });

  testWidgets('기록이 없으면 히어로는 기존 기본(vocab_packs)이다', (tester) async {
    await Storage.init();
    await tester.pumpWidget(_app(SoriStageTab.learn));
    await pumpSoriStage(tester);

    expect(find.text('Vocabulary packs'), findsOneWidget);
    expect(find.text('Continue with'), findsNothing);
  });

  testWidgets('기록한 활동이 이 탭에 있으면 히어로로 승격하고 이어하기 라벨이 보인다', (
    tester,
  ) async {
    await Storage.init();
    await Storage.setLastActivityId('hangul');

    await tester.pumpWidget(_app(SoriStageTab.learn));
    // §E4: 이어하기 히어로는 SoriPulse(끝없이 반복되는 AnimationController)로
    // 감싸인다 — pumpAndSettle()은 무한 애니메이션이 있으면 절대 안정되지
    // 않는다(§MOTION-2 J6, test/support/sori_stage_pump.dart).
    await pumpSoriStage(tester);

    // "Hangul"은 이제 히어로로 승격돼 정확히 한 번만 나온다 — 그리드에
    // 중복되지 않는다.
    expect(find.text('Hangul'), findsOneWidget);
    expect(find.text('CONTINUE WITH'), findsOneWidget);
    // 기본 히어로(단어팩)는 이제 일반 그리드 카드로 내려간다 —
    // scrollUntilVisible은 고정 duration의 pump 를 쓰므로(pumpAndSettle과
    // 달리) 무한 SoriPulse 애니메이션과 안전하게 공존한다.
    await tester.scrollUntilVisible(
      find.text('Vocabulary packs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vocabulary packs'), findsOneWidget);
  });

  testWidgets('기록한 활동이 다른 탭 것이면 이 탭은 기존 기본으로 되돌아간다', (
    tester,
  ) async {
    await Storage.init();
    // 'chosung'은 Games 탭 활동이다 — Learn 탭엔 없다.
    await Storage.setLastActivityId('chosung');

    await tester.pumpWidget(_app(SoriStageTab.learn));
    await pumpSoriStage(tester);

    expect(find.text('Vocabulary packs'), findsOneWidget);
    expect(find.text('Continue with'), findsNothing);
  });
}
