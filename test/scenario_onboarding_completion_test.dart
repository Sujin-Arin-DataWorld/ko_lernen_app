import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

final _fiveQuestScene = Scenario(
  id: 'airport_arrival_test',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항 입국',
    de: 'Einreise am Flughafen',
    en: 'Airport arrival',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: List.generate(
    5,
    (_) => const QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'correctIndex': 0,
        'options': [
          {'de': 'Richtig', 'en': 'Correct'},
          {'de': 'Falsch', 'en': 'Wrong'},
        ],
      },
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('leaving mid-onboarding does not persist a result', (
    tester,
  ) async {
    var saveCalls = 0;
    var exitCalls = 0;
    // _load()가 이제 항상 activeScenarioCheckpointContext(→
    // CourseProgressService.shared, CurriculumCatalog.load())를 거친다(T8,
    // 지시서 4.15). 그 서비스의 직렬화 큐(_tail)/캐시된 서비스는
    // testWidgets 마다 새로 생기는 Zone 을 넘나들면 응답하지 않으므로
    // (courseContext 없이 여는 테스트가 이 파일에 여럿 있다) 이 테스트
    // 자신의 Zone 안에서 매번 새로 시작한다 — setUp()에 두면 그 자체가
    // 다른 Zone 이라 소용없다(직접 확인됨).
    CourseProgressService.shared.resetForTesting();
    // ScenarioLoader.load()는 compute() 격리를 쓰므로 위젯 내부에서
    // 콜드로 처음 호출되면 FakeAsync 존에서 영원히 응답하지 않는다 —
    // runAsync로 감싸 미리 예열한다.
    await tester.runAsync(() async {
      await CurriculumCatalog.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _fiveQuestScene.id,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          scenarioLoader: (_) async => _fiveQuestScene,
          resultPersister: (_, _, _) async {
            saveCalls++;
            return null;
          },
          onExit: () => exitCalls++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 of 5'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(exitCalls, 1);
    expect(saveCalls, 0);
  });

  testWidgets('onboarding completes once after all five quests are persisted', (
    tester,
  ) async {
    final saveGate = Completer<void>();
    var saveCalls = 0;
    var completionCalls = 0;
    ScenarioCompletionSummary? summary;

    // 이 테스트 자신의 Zone 안에서 CourseProgressService.shared 를 새로
    // 시작한다 — 위 "leaving mid-onboarding" 테스트가 이미 그 큐를
    // 사용했다(다른 Zone). 상세 사유는 그 테스트의 주석 참고.
    CourseProgressService.shared.resetForTesting();
    // _load()가 이제 항상 activeScenarioCheckpointContext(→
    // CurriculumCatalog.load())를 시도한다(T8, 지시서 4.15). runAsync 없이
    // 위젯 내부에서 콜드로 처음 호출되면 compute() 격리 때문에 FakeAsync
    // 존에서 영원히 응답하지 않는다 — 미리 예열한다.
    await tester.runAsync(() async {
      await CurriculumCatalog.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen(
          scenarioId: _fiveQuestScene.id,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          scenarioLoader: (_) async => _fiveQuestScene,
          resultPersister: (_, _, _) async {
            saveCalls++;
            await saveGate.future;
            return null;
          },
          onCompleted: (value) {
            completionCalls++;
            summary = value;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('quest-dont-know')), findsOneWidget);

    for (var index = 0; index < 5; index++) {
      expect(find.text('${index + 1} of 5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('answer-0')));
      await tester.pump();
      expect(find.byKey(const ValueKey('quest-submit')), findsNothing);
      expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
      expect(completionCalls, 0);
      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(saveCalls, 1);
    expect(completionCalls, 0);
    saveGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(completionCalls, 1);
    expect(summary?.passed, 5);
    expect(summary?.total, 5);
    expect(summary?.firstSuccess?.phrase, '한국 처음이세요?');
    await tester.pump(const Duration(seconds: 1));
    expect(completionCalls, 1);
  });

  for (final locale in const [
    (code: 'en', dontKnow: 'I don’t know yet', progress: 'of 5'),
    (code: 'de', dontKnow: 'Weiß ich noch nicht', progress: 'von 5'),
  ]) {
    testWidgets(
      'production airport exposes ${locale.code} no-credit help on all five quests',
      (tester) async {
        final airport = await _loadAirport(tester);
        final summary = await _tapDontKnowOnEveryAirportQuest(
          tester,
          airport: airport,
          locale: Locale(locale.code),
        );

        expect(airport.quests, hasLength(5));
        expect(summary.passed, 0);
        expect(summary.total, 5);
        expect(summary.firstSuccess, isNull);
        expect(find.text(locale.dontKnow), findsNothing);
      },
    );
  }

  testWidgets('airport dont-know completion writes no mastery or XP, '
      'but records first-attempt 0 stars (T7: 0성 최초 기록 허용)', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    addTearDown(Storage.resetForTesting);

    final airport = await _loadAirport(tester);
    final checkpoints = <({String id, double score, bool hasCourseContext})>[];
    var evidenceCalls = 0;
    CourseActivityReporter.recordContentAttemptForTesting =
        (kind, contentId, isCorrect, context, error, conceptId, score) async {
          evidenceCalls++;
          throw StateError('onboarding must not write course evidence');
        };
    CourseActivityReporter.recordScenarioCheckpointForTesting =
        (scenarioId, score, courseContext) async {
          checkpoints.add((
            id: scenarioId,
            score: score,
            hasCourseContext: courseContext != null,
          ));
          throw StateError('skip hanok projection after capturing score');
        };
    addTearDown(CourseActivityReporter.resetOverridesForTesting);

    final summary = await _tapDontKnowOnEveryAirportQuest(
      tester,
      airport: airport,
      locale: const Locale('en'),
      persistForReal: true,
    );

    expect(summary.passed, 0);
    expect(summary.total, 5);
    expect(summary.firstSuccess, isNull);
    expect(evidenceCalls, 0);
    expect(checkpoints, hasLength(1));
    expect(checkpoints.single.id, 'airport_arrival');
    expect(checkpoints.single.score, 0);
    expect(checkpoints.single.hasCourseContext, isFalse);
    expect(Storage.xp, 0);
    // T7(지시서 4.15): 0성 완료도 최초 1회는 기록된다 — 완료 여부(키 존재)가
    // 코스 체크포인트 "0/2→1/2" 판정의 입력이라 더 이상 null 로 빠지면 안 된다.
    expect(Storage.scenarioStars['airport_arrival'], 0);
    expect(Storage.completedScenarios, contains('airport_arrival'));
  });
}

Future<Scenario> _loadAirport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // 이 테스트 자신의 Zone 안에서 CourseProgressService.shared 를 새로
  // 시작한다 — 이 파일의 다른(앞선) testWidgets 가 이미 그 큐를 사용했을
  // 수 있다(다른 Zone). 상세 사유는 첫 번째 테스트의 주석 참고.
  CourseProgressService.shared.resetForTesting();
  ScenarioLoader.reset();
  late Scenario airport;
  await tester.runAsync(() async {
    await ScenarioLoader.load();
    airport = ScenarioLoader.byId('airport_arrival')!;
    // _load()가 이제 항상 activeScenarioCheckpointContext(→
    // CurriculumCatalog.load())를 시도한다(T8, 지시서 4.15). 그 카탈로그를
    // 위젯 내부에서 콜드로 처음 로드하면(= compute() 격리를 쓰는
    // ScenarioLoader.load() 하위 호출 때문에) FakeAsync 존에서 영원히
    // 응답하지 않는다 — 여기서 함께 예열해 둔다.
    await CurriculumCatalog.load();
  });
  return airport;
}

Future<ScenarioCompletionSummary> _tapDontKnowOnEveryAirportQuest(
  WidgetTester tester, {
  required Scenario airport,
  required Locale locale,
  bool persistForReal = false,
}) async {
  ScenarioCompletionSummary? summary;
  var saveCalls = 0;
  var evidenceCalls = 0;
  if (!persistForReal) {
    CourseActivityReporter.recordContentAttemptForTesting =
        (kind, contentId, isCorrect, context, error, conceptId, score) async {
          evidenceCalls++;
          throw StateError('onboarding must not write course evidence');
        };
    addTearDown(CourseActivityReporter.resetOverridesForTesting);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: ScenarioPlayerScreen(
        scenarioId: airport.id,
        mode: ScenarioPlayerMode.onboardingFirstScene,
        scenarioLoader: (_) async => airport,
        resultPersister: persistForReal
            ? null
            : (_, _, _) async {
                saveCalls++;
                return null;
              },
        onCompleted: (value) => summary = value,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  final progressSuffix = locale.languageCode == 'de' ? 'von 5' : 'of 5';
  final dontKnowLabel = locale.languageCode == 'de'
      ? 'Weiß ich noch nicht'
      : 'I don’t know yet';
  for (var index = 0; index < airport.quests.length; index++) {
    expect(find.text('${index + 1} $progressSuffix'), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-dont-know')), findsOneWidget);
    expect(find.text(dontKnowLabel), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quest-dont-know')));
    await tester.pump();
    expect(find.byKey(const ValueKey('quest-continue')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quest-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  if (persistForReal) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  expect(summary, isNotNull);
  if (!persistForReal) {
    expect(saveCalls, 1);
    expect(evidenceCalls, 0);
  }
  return summary!;
}
