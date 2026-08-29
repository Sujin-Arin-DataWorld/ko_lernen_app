import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mission_context_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('scenario');
    ScenarioLoader.reset();
    CurriculumCatalog.reset();
  });

  testWidgets('shows mission context for its exact scenario link', (
    tester,
  ) async {
    late ContentLink link;
    late Scenario scenario;
    await tester.runAsync(() async {
      await ScenarioLoader.load();
      final catalog = await CurriculumCatalog.load();
      link = catalog.contentLinks.firstWhere((entry) {
        if (entry.contentKind != CurriculumContentKind.scenario ||
            entry.role != ContentLinkRole.assess ||
            !entry.courseUnitId.startsWith('a1_')) {
          return false;
        }
        final unit = catalog.courseUnitFor(entry.courseUnitId);
        final candidate = ScenarioLoader.byId(entry.contentId);
        return candidate?.level == LearnerLevel.a1 &&
            unit?.checkpointContentIds.contains(entry.contentKey) == true;
      });
      scenario = ScenarioLoader.byId(link.contentId)!;
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: scenario.id,
          courseContext: CoursePracticeContext.fromLink(link),
          scenarioLoader: (_) async => scenario,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MissionContextBar), findsOneWidget);
    expect(find.text('Current mission'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '리스트/추천에서 courseContext 없이 열려도 활성 체크포인트면 자동 유도된다',
    (tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // given: CourseProgressService.shared 가 currentCourseUnitId 로
      // 'a1_01_greetings_hangul' 을 갖고, 그 유닛이 'airport_arrival' 을
      // checkpointContentIds 로 선언(실제 커리큘럼 매니페스트).
      //
      // 이 테스트 자신의 Zone 안에서 CourseProgressService.shared 를 새로
      // 시작한다 — 이 파일에 courseContext 없이 ScenarioPlayerScreen 을
      // 여는 테스트가 나중에 추가되더라도(또는 실행 순서가 바뀌더라도)
      // 서로의 Zone 을 침범하지 않도록 항상 명시적으로 초기화해 둔다.
      CourseProgressService.shared.resetForTesting();
      // CurriculumCatalog.load()는 내부적으로 ScenarioLoader.load()의
      // compute() 격리를 거치므로 runAsync로 감싸 미리 예열한다 — 이 파일의
      // 첫 번째 테스트와 동일한 패턴. CourseProgressService.shared는 위에서
      // 이미 초기화했으므로 여기서는 건드리지 않는다: 그 서비스의 직렬화
      // 큐(_tail)를 runAsync 존에서 생성한 뒤 밖(FakeAsync 존)에서 처음
      // await 하면 응답이 오지 않는다(재현 확인됨 — 위젯 내부의 첫
      // CourseProgressService.shared 호출이 영원히 pending 상태로 남는다).
      // 대신 그 서비스가 내부적으로 읽는 원시 Storage 스칼라만 직접
      // 세팅해, 위젯이 FakeAsync 존 안에서
      // CourseProgressService.shared 를 처음부터 끝까지 스스로 예열하게
      // 한다.
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });
      await Storage.setCourseUnitId('a1_01_greetings_hangul');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ScenarioPlayerScreen(
            scenarioId: _checkpointScenario.id,
            scenarioLoader: (_) async => _checkpointScenario,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 시나리오를 끝까지 진행 후 결과 화면에서 courseEligible 체크포인트가
      // 기록됐는지 확인 (기존 완주 헬퍼 재사용).
      await _tapText(tester, "Los geht's!");
      await _advanceUntilText(tester, 'Correct response');
      await _tapText(tester, 'Correct response');
      await tester.pump();
      await _tapText(tester, 'Antwort prüfen');
      await tester.pump();
      await _tapText(tester, 'Ergebnis ansehen');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));

      final snapshot = await CourseProgressService.shared.readForDisplay();
      expect(snapshot?.scenarioCheckpoints.last.courseEligible, isTrue);
    },
  );
}

/// `airport_arrival`은 실제 커리큘럼 매니페스트에서 `a1_01_greetings_hangul`
/// 유닛의 체크포인트로 선언돼 있다. 콘텐츠 자체는 최소 픽스처로 대체해 실제
/// 시나리오 콘텐츠의 정확한 문구/정답에 의존하지 않게 한다
/// (`scenario_can_do_result_flow_test.dart`의 완주 픽스처와 동일한 형태).
const _checkpointScenario = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: '🐯',
  register: Register.polite,
  title: LocalizedText(ko: '인사', de: 'Gruß', en: 'Greeting'),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(speaker: 'guide', ko: '안녕', de: 'Hallo', en: 'Hello'),
    DialogLine(speaker: 'User', ko: '안녕하세요.', de: 'Guten Tag.', en: 'Hello.'),
  ],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '안녕',
        'correctIndex': 0,
        'options': [
          {'de': 'Correct response', 'en': 'Correct response'},
        ],
      },
    ),
  ],
);

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
  await tester.pump();
}

Future<void> _advanceUntilText(
  WidgetTester tester,
  String target, {
  int maxSteps = 5,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text(target).evaluate().isNotEmpty) return;
    await _tapText(tester, 'Weiter');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }
  expect(find.text(target), findsWidgets);
}
