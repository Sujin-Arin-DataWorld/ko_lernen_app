import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

const _failedTarget = '실패 단어';
const _passivelyShownWord = '소개만 단어';
const _wrongOption = '다른 단어';
const _roleplayTrackedWord = '안녕하세요';

const _scenario = Scenario(
  id: 'scenario-srs-persistence-flow',
  level: LearnerLevel.a1,
  emoji: '🐯',
  register: Register.polite,
  title: LocalizedText(ko: '증거 확인', de: 'Evidenzprüfung', en: 'Evidence'),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [
    VocabRef(korean: _failedTarget),
    VocabRef(korean: _passivelyShownWord),
  ],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '___ 입니다.',
        'options': [_failedTarget, _wrongOption],
        'correctIndex': 0,
      },
    ),
  ],
);

const _roleplayScenario = Scenario(
  id: 'scenario-roleplay-writing-skip',
  level: LearnerLevel.a1,
  emoji: '✍️',
  register: Register.polite,
  title: LocalizedText(ko: '쓰기 건너뛰기', de: 'Schreiben', en: 'Writing'),
  intro: LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: [VocabRef(korean: _roleplayTrackedWord)],
  grammarIds: [],
  dialog: [
    DialogLine(speaker: 'partner', ko: '안녕하세요?', de: 'Hallo?', en: 'Hello?'),
    DialogLine(speaker: 'user', ko: '안녕하세요.', de: 'Guten Tag.', en: 'Hello.'),
  ],
  quests: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 900);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_scenario': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();

    // Keep the screen on its real default persistence path while isolating the
    // unrelated course graph write. No resultPersister is injected below.
    CourseActivityReporter.recordScenarioCheckpointForTesting =
        (_, _, _) async => const CourseUpdate(
          snapshot: CourseMasterySnapshot.empty(),
          currentUnit: null,
        );
  });

  tearDown(() {
    CourseActivityReporter.resetOverridesForTesting();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    'completion only records negative SRS for the failed direct quest target',
    (tester) async {
      // Both words begin at the one-day first-success state. A former
      // scenario-wide positive write would promote the passive word to three
      // days, while the failed target must stay due soon with one extra review.
      await Storage.setSrsRawJson(
        '{"실패 단어":{"e":2.55,"i":1,"n":"2099-01-01","r":1},'
        '"소개만 단어":{"e":2.55,"i":1,"n":"2099-01-01","r":1}}',
      );

      // 이 테스트 자신의 Zone 안에서 CourseProgressService.shared 를 새로
      // 시작한다 — 다른 courseContext-없는 testWidgets 가 먼저 실행되면
      // 그 서비스의 직렬화 큐가 다른 Zone 에 묶여 응답하지 않게 된다.
      CourseProgressService.shared.resetForTesting();
      // _load()가 이제 항상 activeScenarioCheckpointContext(→
      // CurriculumCatalog.load())를 시도한다(T8, 지시서 4.15). 그 안의
      // ScenarioLoader.load()는 compute() 격리를 쓰므로 위젯 내부에서
      // 콜드로 처음 호출되면 FakeAsync 존에서 영원히 응답하지 않는다 —
      // runAsync로 감싸 미리 예열한다(scenario_mission_context_test.dart와
      // 동일 패턴). 이 시나리오는 아무 코스 유닛도 활성화하지 않으므로
      // 유도 결과는 여전히 null(courseContext 없는 기존 동작 그대로).
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ScenarioPlayerScreen(
            scenarioId: _scenario.id,
            scenarioLoader: (_) async => _scenario,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await _tapText(tester, "Los geht's!");
      await tester.pump(const Duration(seconds: 2));
      await _tapText(tester, 'Weiter');
      await tester.pump(const Duration(seconds: 2));
      await _tapText(tester, 'Weiter');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Lücke füllen'), findsOneWidget);

      // Two wrong attempts complete the real Lückentext quest as failed.
      // 지시서 4.11 — 옵션 탭 1회로 즉시 판정되므로 별도 확인 버튼
      // ("Antwort prüfen")이 더 이상 없다 — 오답 타일을 두 번 탭한다.
      final wrongAnswer = find.byKey(const ValueKey('answer-1'));
      await tester.ensureVisible(wrongAnswer);
      await tester.tap(wrongAnswer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.ensureVisible(wrongAnswer);
      await tester.tap(wrongAnswer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await _tapText(tester, 'Ergebnis ansehen');

      await _pumpUntil(
        tester,
        () => Storage.srsCard(_failedTarget)?.reviewCount == 2,
      );

      final failed = Storage.srsCard(_failedTarget)!;
      final passive = Storage.srsCard(_passivelyShownWord)!;
      expect(failed.intervalDays, 1);
      expect(failed.reviewCount, 2);
      expect(
        passive.intervalDays,
        1,
        reason:
            'passively shown scenario vocab must not receive success credit',
      );
      expect(passive.reviewCount, 1);
      expect(
        Storage.studyLogIdsFor(Storage.todayIso()),
        isEmpty,
        reason:
            'scenario auto-fail SRS evidence is not a user-reviewed ledger item',
      );
    },
  );

  testWidgets(
    'roleplay writing Skip changes no score, SRS, or completion state',
    (tester) async {
      await Storage.setSrsRawJson(
        '{"안녕하세요":{"e":2.55,"i":1,"n":"2099-01-01","r":1}}',
      );
      final before = Storage.srsCard(_roleplayTrackedWord)!;
      var persistenceCalls = 0;
      var completionCalls = 0;

      CourseProgressService.shared.resetForTesting();
      await tester.runAsync(() async {
        await CurriculumCatalog.load();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: ScenarioPlayerScreen(
            scenarioId: _roleplayScenario.id,
            scenarioLoader: (_) async => _roleplayScenario,
            grammarLoader: () async => const [],
            resultPersister: (_, _, _) async {
              persistenceCalls += 1;
              return null;
            },
            onCompleted: (_) => completionCalls += 1,
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

      await tester.tap(find.text(_roleplayTrackedWord));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quest-submit')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('quest-continue')));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(
          const ValueKey<String>('scenario-write-after-roleplay-card'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('scenario-write-skip')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('scenario-write-skip')),
      );
      await tester.pump();

      final after = Storage.srsCard(_roleplayTrackedWord)!;
      expect(persistenceCalls, 0);
      expect(completionCalls, 0);
      expect(Storage.xp, 0);
      expect(Storage.scenarioStars, isEmpty);
      expect(Storage.completedScenarios, isEmpty);
      expect(after.reviewCount, before.reviewCount);
      expect(after.intervalDays, before.intervalDays);
    },
  );
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
  await tester.pump();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(condition(), isTrue, reason: 'scenario persistence did not finish');
}
