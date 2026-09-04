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

void main() {
  testWidgets('catalog shows a receipt after returning with a real delta', (
    tester,
  ) async {
    // §W2-Task2 (검수#7): capture() 의 "before" 로컬 절반은 이제 주입된
    // loadSnapshot 이 아니라 실제 Storage.xp 를 동기로 읽는다(fail-open 설계상
    // 의도된 결합). 이 위젯 테스트가 진짜 활동 흐름을 검증하려면 real Storage
    // 도 같은 시작값(4)을 갖고 있어야 delta 가 예상한 +20 으로 나온다.
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setXp(4);

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
    // §E3: 기본 ensureVisible(alignment 0)은 타깃을 뷰포트 맨 위에 맞춘다 —
    // 그 자리는 이제 SoriCollapsingHeader의 pinned 56dp 크롬 바 밑이라 탭이
    // 안 먹는다. alignment 0.5(가운데 정렬)로 그 밴드를 확실히 벗어난다.
    await Scrollable.ensureVisible(
      tester.element(find.text('Course')),
      alignment: 0.5,
    );
    await pumpSoriStage(tester);
    // §W2-Task2 (검수#7 Step 7): capture() 의 기본 네트워크 절반
    // (SoriStageProgressionService.loadNetworkBeforeFields)은 실제
    // QuestTracker.computeAll()/HanokStructureProjectionService.loadCurrent()
    // 를 거쳐 진짜 에셋 I/O(rootBundle.loadString, 여러 샤드)를 수행한다.
    // tap() 을 AutomatedTestWidgetsFlutterBinding 의 가짜 시계 안에서 부르면
    // 그 안에서 시작된 real I/O future 의 이어달리기(continuation)가 가짜
    // 마이크로태스크 큐에 묶여 pump() 를 반복해도 절대 안 풀린다(fail-open 은
    // 예외만 흡수할 뿐 완료되지 않는 Future 는 구제하지 못한다) — runAsync 로
    // 진짜 존(zone) 안에서 tap 을 실행해 그 이어달리기를 진짜 이벤트 루프에
    // 묶는다.
    await tester.runAsync(() async {
      await tester.tap(find.text('Course'));
      await tester.pump();
    });
    await pumpSoriStage(tester);
    await tester.tap(find.text('Complete activity'));
    // §W2 후속: 여기서 기다리는 것은 capture() 의 나머지 절반이다 — pop 으로
    // openActivity() 가 끝난 뒤 진짜 존에 묶인 networkFuture 가 풀리고,
    // compare() 가 delta 를 만들고, 리시트 시트가 push 된다. 고정 3초 실시간
    // 대기는 느린 CI 에서 부족(플레이크)하고 빠른 머신에선 낭비였다 —
    // pumpUntilFound(§MOTION-2 J6, test/support/sori_stage_pump.dart)가
    // 100ms 간격으로 폴링하고(상한 10초) 뜨는 즉시 빠져나온다 — 상한을
    // 넘겨도 아래 단언은 그대로 실패한다(가드 불변).
    await pumpUntilFound(tester, find.text('+20 XP'));
    // §E4: returning from 'course' makes it this catalog's "Weiter mit…"
    // hero, wrapped in the endlessly repeating SoriPulse — pumpAndSettle()
    // never quiesces with an indefinite AnimationController running behind
    // the receipt sheet. A few bounded pumps let the sheet's own entrance
    // transition finish without waiting on that unrelated idle animation.
    await pumpSoriStage(tester, settle: const Duration(milliseconds: 400));

    expect(find.text('+20 XP'), findsOneWidget);
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
