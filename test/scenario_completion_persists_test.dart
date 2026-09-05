// 지시서 4.15 — "시나리오 하나 끝냈는데 0/2로 저장이 안 돼".
//
// 근본 원인(재현 확정): lib/screens/scenarios_list_screen.dart 의 레벨 진행
// 배지("{level}: done/total ★", ARB scenariosPathLevelProgress)가
//   all.where((sc) => sc.level == lvl)
//      .where((sc) => (stars[sc.id] ?? 0) > 0)   // ← 0성 완료를 "미완료"로 셈
//      .length
// 로 done 개수를 센다. 그런데 storage_service.dart의 setScenarioStars()는
// (T7, 코스 체크포인트 "0/2→1/2" 판정을 위해) 0성 최초 완료도 반드시 키로
// 기록한다 — "완료 여부 = 키 존재"가 이미 확정된 계약이다
// (test/scenario_onboarding_completion_test.dart 참고). 목록 화면만 그 계약을
// 어기고 stars 값이 0보다 커야 "완료"로 셈해, 퀘스트 과반(≥60%) 미만을 맞혀
// 0성으로 끝낸 정상 완료가 레벨 배지에서 "0/2"에 머무는 버그가 난다.
// "2"는 해당 레벨(A1)에 존재하는 시나리오 총 개수 — 여기서는 테스트가
// loadScenarios로 주입하는 2개(A1 두 개)다.
//
// 완료 조건 자체(퀘스트 채점·별 계산)는 바꾸지 않는다 — done/total 판정만
// storage 계약(키 존재)에 맞춘다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/sori_speech_stubs.dart';

const _questWord = '실패 단어';
const _wrongWord = '오답 단어';

/// 재생 가능한 A1 시나리오 1개 — 퀘스트 1개(luecken), 두 선택지 중 오답만
/// 골라 60% 미만(0/1)으로 끝내면 0성 완료가 된다.
const _playableA1 = Scenario(
  id: 'scenario-completion-persists-a',
  level: LearnerLevel.a1,
  emoji: '🐯',
  register: Register.polite,
  title: LocalizedText(
    ko: '완료 확인',
    de: 'Abschlussprüfung',
    en: 'Completion check',
  ),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [VocabRef(korean: _questWord), VocabRef(korean: _wrongWord)],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '___ 입니다.',
        'options': [_questWord, _wrongWord],
        'correctIndex': 0,
      },
    ),
  ],
);

/// 같은 레벨의 두 번째 시나리오 — 이 파일은 이걸 직접 플레이하지 않는다.
/// 레벨 총계(total)를 2로 고정해 "0/2" 재현을 정확히 만든다.
const _otherA1 = Scenario(
  id: 'scenario-completion-persists-b',
  level: LearnerLevel.a1,
  emoji: '🍚',
  register: Register.polite,
  title: LocalizedText(
    ko: '다른 시나리오',
    de: 'Anderes Szenario',
    en: 'Other scenario',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // ScenarioPlayerScreen은 content_audio_policy_guard_test.dart의 자동
    // 발화 화면 목록에 있다 — 이 파일의 두 시나리오는 dialog가 비어 있어
    // 실제로 speak가 걸리지 않지만, auto_speech_test_stub_guard_test.dart는
    // 정적 스캔이라 실행 여부와 무관하게 스텁 증거를 요구한다(T3 교훈).
    stubSoriSpeech();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 900);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    // 익명(비로그인) 기본 상태 — 계정/클라우드 관련 키를 일부러 심지 않는다.
    // 완료 저장 경로(_persistResult → Storage.setScenarioStars /
    // addCompletedScenario)에는 FirebaseAuth/계정 분기가 없다(코드 확인 완료)
    // — 이 setUp 자체가 이미 "익명 사용자" 경로다.
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
    // 코스 그래프(CurriculumCatalog/CourseMasterySnapshot)는 이 버그와 무관한
    // 별도 시스템이다 — 체크포인트 리포터를 끊어 결과 저장 경로만 격리한다
    // (test/scenario_srs_persistence_flow_test.dart와 동일 패턴).
    CourseActivityReporter.recordScenarioCheckpointForTesting = (
      _,
      _,
      _,
    ) async => throw StateError('course graph skipped for this test');
  });

  tearDown(() {
    CourseActivityReporter.resetOverridesForTesting();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    '정상 완료: 퀘스트 과반 미만(0성)이어도 레벨 배지가 0/2→1/2로 갱신된다',
    (tester) async {
      await _expectLevelBadge(tester, 'A1: 0/2 ★');

      await _warmUpCourseGraph(tester);
      await _failTheOnlyQuest(tester, _playableA1);

      // 쓰기 경로(스토리지)는 이미 올바르다 — T7 계약 그대로.
      expect(Storage.scenarioStars[_playableA1.id], 0);
      expect(Storage.completedScenarios, contains(_playableA1.id));

      // 읽기 경로(목록 배지)가 그 완료를 세는지가 이 버그의 핵심.
      await _expectLevelBadge(tester, 'A1: 1/2 ★');
    },
  );

  testWidgets('중간 이탈 후 재진입해 완료해도 배지가 1/2로 반영된다', (
    tester,
  ) async {
    await _warmUpCourseGraph(tester);
    // 1) 진입 후 한 스테이지 진행하고(스테이지>0) 닫기 → 확인 시트에서
    //    "떠나기"를 골라 결과를 저장하지 않고 이탈한다. 이 화면이 테스트
    //    트리의 루트(home)라 실제 Navigator.pop은 히스토리가 비어 크래시
    //    하므로 onExit 콜백으로 이탈만 관측한다(§ scenario_player_screen.dart
    //    'onExit이 있으면 그리로' 규칙) — 저장 여부 검증에는 영향 없다.
    var exitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        // 이 테스트는 서로 다른 화면(목록 ↔ 플레이어)을 각각 새 MaterialApp
        // 루트로 여러 번 pumpWidget 한다. 매번 다른 key가 없으면 Flutter가
        // 이전 Navigator/Overlay 엘리먼트를 재사용해(같은 타입 트리로 보임)
        // 이전 화면의 코치마크 오버레이(RenderAbsorbPointer)가 다음 화면
        // 위에 그대로 남아 탭을 가로챈다 — UniqueKey로 매번 완전히 새로
        // 마운트해 이전 Overlay를 확실히 dispose한다.
        key: UniqueKey(),
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _playableA1.id,
          scenarioLoader: (_) async => _playableA1,
          onExit: () => exitCalls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _tapText(tester, "Los geht's!");
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
    await tester.tap(find.text(t.homeActionConfirmLeave));
    await tester.pumpAndSettle();

    expect(exitCalls, 1);
    expect(Storage.scenarioStars.containsKey(_playableA1.id), isFalse);
    await _expectLevelBadge(tester, 'A1: 0/2 ★');

    // 2) 재진입 후 이번엔 끝까지 완료한다.
    await _failTheOnlyQuest(tester, _playableA1);

    expect(Storage.scenarioStars[_playableA1.id], 0);
    expect(Storage.completedScenarios, contains(_playableA1.id));
    await _expectLevelBadge(tester, 'A1: 1/2 ★');
  });
}

/// ScenarioPlayerScreen._load()는 항상 activeScenarioCheckpointContext(→
/// CurriculumCatalog.load())를 시도한다(T8, 지시서 4.15) — 그 안의
/// ScenarioLoader.load()가 compute() 격리를 쓰므로, 위젯 안에서 콜드로 처음
/// 호출되면 FakeAsync 존에서 영원히 응답하지 않는다. runAsync로 감싸 같은
/// 테스트 Zone 안에서 미리 예열해야 한다(다른 4.15 관련 테스트들과 동일한
/// 패턴) — 각 testWidgets 본문에서 첫 ScenarioPlayerScreen을 띄우기 전에
/// 한 번만 호출한다.
Future<void> _warmUpCourseGraph(WidgetTester tester) async {
  CourseProgressService.shared.resetForTesting();
  await tester.runAsync(() async {
    await CurriculumCatalog.load();
  });
}

/// [scenario]의 유일한 luecken 퀘스트를 오답으로 두 번 채워 0/1(0성)로
/// 완료까지 진행한다. 실제 ScenarioPlayerScreen을 대화 없이(빈 dialog)
/// intro → 단어 → 문법 → 퀘스트 → 결과 순으로 밟는다
/// (test/scenario_srs_persistence_flow_test.dart와 동일한 스테이지 수).
///
/// 지시서 4.11(A2)로 luecken 퀘스트가 "옵션 탭 즉시 판정"으로 바뀌어
/// 별도 확인 버튼(`Antwort prüfen`/`onSubmit`)이 사라졌다
/// (lib/screens/quest_engines/luecken_quest.dart의 `_select`가 바로
/// `_check()`를 호출 — hoerverstehen_quest.dart와 동일한 계약). 오답 탭을
/// 두 번(첫 탭=1회차 오답 허용, 두 번째 탭=시도 소진→정답 공개) 반복해
/// 예전에 "오답 선택 + 확인 버튼 2회"로 만들던 0/1(0성) 결과와 동일한
/// 판정을 재현한다. 정답 공개 뒤에 뜨는 CTA(`quest-continue`, 이 시나리오는
/// 퀘스트가 1개뿐이라 isLast=true → 라벨은 `Ergebnis ansehen`)만 탭한다.
Future<void> _failTheOnlyQuest(WidgetTester tester, Scenario scenario) async {
  await tester.pumpWidget(
    MaterialApp(
      // 화면 전환마다 새 Overlay를 강제한다 — 위 주석 참고.
      key: UniqueKey(),
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: ScenarioPlayerScreen(
        scenarioId: scenario.id,
        scenarioLoader: (_) async => scenario,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  await _tapText(tester, "Los geht's!");
  await tester.pump(const Duration(milliseconds: 400));
  await _tapText(tester, 'Weiter');
  await tester.pump(const Duration(milliseconds: 400));
  await _tapText(tester, 'Weiter');
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('Lücke füllen'), findsOneWidget);

  final wrongAnswer = find.byKey(const ValueKey('answer-1'));
  await tester.ensureVisible(wrongAnswer);
  // 1회차 오답 — 즉시 판정되지만 아직 시도가 남아 재탭을 허용한다
  // (luecken_quest.dart `_check()`의 `_tries >= 2` 게이트).
  await tester.tap(wrongAnswer);
  await tester.pump(const Duration(milliseconds: 220));
  // 2회차 오답 — 시도 소진으로 정답이 공개되고 결과가 즉시 보고된다.
  await tester.tap(wrongAnswer);
  await tester.pump(const Duration(milliseconds: 220));
  await _tapText(tester, 'Ergebnis ansehen');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// 목록 화면을 새로 렌더링해 레벨 진행 배지 텍스트를 단언한다. 매번 새
/// 위젯 트리를 띄워 화면이 실제로 Storage를 다시 읽는지(캐시 고착 없이)도
/// 함께 확인한다.
Future<void> _expectLevelBadge(WidgetTester tester, String label) async {
  await tester.pumpWidget(
    MaterialApp(
      // 화면 전환마다 새 Overlay를 강제한다 — 위 주석 참고.
      key: UniqueKey(),
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: ScenariosListScreen(
        ignoreLevelLock: true,
        loadScenarios: () async => const [_playableA1, _otherA1],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text(label), findsOneWidget);
  // 코치마크(ScreenCoachMixin) 예약 콜백이 다음에 올려질 위젯 트리 위로
  // 늦게 겹쳐 뜨는 것을 막는다 — 다음 pumpWidget 전에 보류 중인 프레임을
  // 비운다. 앰비언트 루프(HanokHeader)는 계속 반복되므로 무제한
  // pumpAndSettle()은 절대 안정화되지 않는다 — 짧은 상한을 둔다.
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
  } on FlutterError {
    // 앰비언트 루프가 계속 프레임을 예약해 상한 안에 안정화되지 않는 것은
    // 정상이다 — 코치마크 콜백만 비우면 충분하다.
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
  await tester.pump();
}
