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

  // §W10 T-L1 (declared contract change, explicit in the T-L1 brief's
  // "Continue-hero rule change"): Learn 탭에서 이어하기 히어로는 마지막
  // 활동이 "오늘" 섹션 소속일 때만 승격한다. `hangul`은 이제 "탐색" 섹션
  // 소속이라 더 이상 히어로로 오르지 않는다 — 이 케이스는 그 경계를
  // 검증하도록 다시 썼다(이전엔 반대로 "탐색 활동도 승격한다"를 검증했다).
  testWidgets('기록한 활동이 탐색/복습 섹션 소속이면 히어로로 승격하지 않는다(오늘 섹션만 승격)', (
    tester,
  ) async {
    await Storage.init();
    await Storage.setLastActivityId('hangul');

    await tester.pumpWidget(_app(SoriStageTab.learn));
    // §E4: 이어하기 히어로는 SoriPulse(끝없이 반복되는 AnimationController)로
    // 감싸인다 — pumpAndSettle()은 무한 애니메이션이 있으면 절대 안정되지
    // 않는다(§MOTION-2 J6, test/support/sori_stage_pump.dart).
    await pumpSoriStage(tester);

    // 기본 히어로(단어팩)가 그대로 유지된다 — "탐색" 활동 기록은 히어로
    // 자리를 바꾸지 않는다.
    expect(find.text('Vocabulary packs'), findsOneWidget);
    expect(find.text('CONTINUE WITH'), findsNothing);
    // "Hangul"은 여전히 카탈로그에 있다 — 그리드에서(탐색 섹션의 평범한
    // 카드로) 보인다.
    await tester.scrollUntilVisible(
      find.text('Hangul'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hangul'), findsOneWidget);
  });

  testWidgets('기록한 활동이 "오늘" 섹션 소속이면 히어로로 승격하고 이어하기 라벨이 보인다', (
    tester,
  ) async {
    await Storage.init();
    await Storage.setLastActivityId('grammar');

    await tester.pumpWidget(_app(SoriStageTab.learn));
    await pumpSoriStage(tester);

    // "Grammar"는 이제 히어로로 승격돼 정확히 한 번만 나온다 — 그리드에
    // 중복되지 않는다.
    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('CONTINUE WITH'), findsOneWidget);
    // 기본 히어로(단어팩)는 이제 일반 그리드 카드로 내려간다.
    await tester.scrollUntilVisible(
      find.text('Vocabulary packs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vocabulary packs'), findsOneWidget);
  });

  testWidgets('기록한 활동이 "복습" 섹션 소속이면 히어로는 그대로이고 그 활동은 복습 섹션에 보인다', (
    tester,
  ) async {
    await Storage.init();
    await Storage.setLastActivityId('srs');

    await tester.pumpWidget(_app(SoriStageTab.learn));
    await pumpSoriStage(tester);

    expect(find.text('Vocabulary packs'), findsOneWidget);
    expect(find.text('CONTINUE WITH'), findsNothing);
    // "srs"의 카드 타이틀도 "Review"라 섹션 제목과 같은 문자열이다 —
    // SoriSectionHeader 위젯 자체로 섹션 제목을, find.text로 카드를 잡아
    // 서로 구분한다.
    final reviewSectionTitle = find.byWidgetPredicate(
      (widget) => widget is SoriSectionHeader && widget.title == 'Review',
    );
    await tester.scrollUntilVisible(
      reviewSectionTitle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(reviewSectionTitle, findsOneWidget);
    // 섹션 제목 자신의 Text("Review") + srs 카드 타이틀 Text("Review"),
    // 정확히 둘 — srs가 그리드에서 빠지지 않았다는 증거.
    expect(find.text('Review'), findsNWidgets(2));
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
