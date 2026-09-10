import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/sori_speech_stubs.dart';
import 'support/reward_preferences_platform.dart';

const _scenario = Scenario(
  id: 'completion-recovery-fixture',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(ko: '인사', de: 'Gruß', en: 'Greeting'),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '안녕하세요.',
        'correctIndex': 0,
        'options': [
          {'de': 'Hallo', 'en': 'Hello'},
        ],
      },
    ),
  ],
);

const _context = CoursePracticeContext(
  courseUnitId: 'a1_01_greetings_hangul',
  contentKind: CurriculumContentKind.scenario,
  initialContentId: 'completion-recovery-fixture',
  contentLinkId: 'recovery-checkpoint',
);

const _srsScenario = Scenario(
  id: 'srs-completion-recovery',
  level: LearnerLevel.a1,
  emoji: '',
  register: Register.polite,
  title: LocalizedText(ko: '', de: '', en: ''),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [VocabRef(korean: '사과')],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '___ 입니다.',
        'options': ['사과', '바나나'],
        'correctIndex': 0,
      },
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    CourseActivityReporter.resetOverridesForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  testWidgets('course checkpoint failure keeps completion retryable', (
    tester,
  ) async {
    var completions = 0;
    CourseActivityReporter.recordScenarioCheckpointForTesting =
        (_, _, _) async => throw StateError('course persistence unavailable');
    await _finish(
      tester,
      courseContext: _context,
      onCompleted: () => completions++,
    );

    final t = await AppL10n.delegate.load(const Locale('en'));
    expect(
      completions,
      0,
      reason: 'A failed course write is not a saved result.',
    );
    expect(find.text(t.scenarioResultSaveRetry), findsOneWidget);
    expect(Storage.xp, 0, reason: 'Course persistence precedes reward writes.');
    expect(Storage.completedScenarios, isNot(contains(_scenario.id)));
  });

  testWidgets('unlinked free practice can finish without course graph', (
    tester,
  ) async {
    var completions = 0;
    CourseActivityReporter.recordScenarioCheckpointForTesting =
        (_, _, context) async {
          expect(context, isNull);
          throw StateError('unlinked free practice');
        };
    await _finish(tester, onCompleted: () => completions++);
    expect(completions, 1);
    expect(Storage.completedScenarios, contains(_scenario.id));
  });

  testWidgets('retry after course recovery grants the result and reward once', (
    tester,
  ) async {
    var completions = 0;
    var checkpointCalls = 0;
    var available = false;
    CourseActivityReporter
        .recordScenarioCheckpointForTesting = (_, _, _) async {
      checkpointCalls++;
      if (!available) {
        throw StateError('course persistence unavailable');
      }
      return CourseUpdate(snapshot: CourseMasterySnapshot(), currentUnit: null);
    };
    await _finish(
      tester,
      courseContext: _context,
      onCompleted: () => completions++,
    );
    expect(completions, 0);
    expect(Storage.xp, 0);

    available = true;
    final t = await AppL10n.delegate.load(const Locale('en'));
    await tester.ensureVisible(find.text(t.scenarioResultSaveRetry));
    await tester.tap(find.text(t.scenarioResultSaveRetry));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(completions, 1);
    expect(checkpointCalls, 2);
    expect(Storage.xp, _scenario.xpReward);
    expect(Storage.scenarioStars[_scenario.id], 3);
    expect(Storage.completedScenarios, contains(_scenario.id));
    expect(find.text(t.scenarioResultSaveRetry), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
    expect(Storage.xp, _scenario.xpReward);
  });
  for (final key in [
    'kl_scenario_stars',
    'kl_completed_scenarios',
    'kl_earned_badges',
  ]) {
    testWidgets('rejected $key keeps the real player retryable before XP', (
      tester,
    ) async {
      var completions = 0;
      platform.rejectKey = key;
      CourseActivityReporter.recordScenarioCheckpointForTesting =
          (_, _, _) async => throw StateError('unlinked practice');
      await _finish(tester, onCompleted: () => completions++);
      expect(completions, 0);
      expect(Storage.xp, 0);
      final t = await AppL10n.delegate.load(const Locale('en'));
      expect(find.text(t.scenarioResultSaveRetry), findsOneWidget);
      platform.rejectKey = null;
      await tester.ensureVisible(find.text(t.scenarioResultSaveRetry));
      await tester.tap(find.text(t.scenarioResultSaveRetry));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(completions, 1);
      expect(Storage.xp, _scenario.xpReward);
      expect(Storage.scenarioStars[_scenario.id], 3);
      expect(Storage.earnedBadges, contains('cafe_starter'));
      expect(Storage.completedScenarios, contains(_scenario.id));
    });
  }

  for (final committed in [false, true]) {
    testWidgets(
      'real player recovers an unknown XP write once; committed=$committed',
      (tester) async {
        var completions = 0;
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..commitBeforeFailure = committed
          ..throwReply = true
          ..failReloadAfterWrite = true;
        CourseActivityReporter.recordScenarioCheckpointForTesting =
            (_, _, _) async => throw StateError('unlinked practice');
        await _finish(tester, onCompleted: () => completions++);
        expect(completions, 0);
        expect(Storage.xp, 0);
        platform
          ..rejectKey = null
          ..unavailable = false;
        final t = await AppL10n.delegate.load(const Locale('en'));
        await tester.ensureVisible(find.text(t.scenarioResultSaveRetry));
        await tester.tap(find.text(t.scenarioResultSaveRetry));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(completions, 1);
        expect(Storage.xp, _scenario.xpReward);
        expect(Storage.xpToday, _scenario.xpReward);
        expect(
          platform.writes[Storage.listeningRewardLedgerPreferenceKey],
          committed ? 1 : 2,
        );
        expect(platform.writes['kl_scenario_stars'], 1);
        expect(platform.writes['kl_completed_scenarios'], 1);
        expect(platform.writes['kl_earned_badges'], 1);
      },
    );
  }
  for (final committed in [false, true]) {
    testWidgets(
      'real player retries unknown failed-quest SRS; committed=$committed',
      (tester) async {
        var completions = 0;
        platform
          ..rejectKey = 'kl_srs_v1'
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        CourseActivityReporter.recordScenarioCheckpointForTesting =
            (_, _, _) async => throw StateError('unlinked practice');
        await _finish(
          tester,
          scenario: _srsScenario,
          failQuest: true,
          onCompleted: () => completions++,
        );
        expect(completions, 0);
        expect(Storage.srsCard('사과'), isNull);
        final t = await AppL10n.delegate.load(const Locale('en'));
        expect(find.text(t.scenarioResultSaveRetry), findsOneWidget);
        platform
          ..unavailable = false
          ..rejectKey = null;
        await tester.ensureVisible(find.text(t.scenarioResultSaveRetry));
        await tester.tap(find.text(t.scenarioResultSaveRetry));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(completions, 1);
        expect(Storage.srsCard('사과')!.reviewCount, 1);
        expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
        expect(platform.writes['kl_srs_v1'], committed ? 1 : 2);
      },
    );
  }
}

Future<void> _finish(
  WidgetTester tester, {
  CoursePracticeContext? courseContext,
  Scenario scenario = _scenario,
  bool failQuest = false,
  required VoidCallback onCompleted,
}) async {
  tester.view.physicalSize = const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  CourseProgressService.shared.resetForTesting();
  await tester.runAsync(() async {
    await CurriculumCatalog.load();
    await HanokStageService.levelRatios();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: ScenarioPlayerScreen(
        scenarioId: scenario.id,
        scenarioLoader: (_) async => scenario,
        courseContext: courseContext,
        mode: ScenarioPlayerMode.onboardingFirstScene,
        onCompleted: (_) => onCompleted(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (failQuest) {
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('answer-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    }
  } else {
    await tester.tap(find.byKey(const ValueKey('answer-0')));
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('quest-continue')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}
