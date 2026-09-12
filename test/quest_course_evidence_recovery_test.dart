import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/uebersetzen_quest.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPreferences = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    CourseActivityReporter.resetOverridesForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    CourseProgressService.shared.resetForTesting();
    CourseActivityReporter.resetOverridesForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferencesStorePlatform.instance = originalPreferences;
  });

  for (final outcome
      in const <({String label, bool throws, bool commits, int finalWrites})>[
        (label: 'rejection', throws: false, commits: false, finalWrites: 2),
        (
          label: 'committed unknown',
          throws: true,
          commits: true,
          finalWrites: 1,
        ),
        (
          label: 'uncommitted unknown',
          throws: true,
          commits: false,
          finalWrites: 2,
        ),
      ]) {
    testWidgets('linked cloze retains feedback until native course '
        '${outcome.label} is recovered', (tester) async {
      final fixture = await _loadLinkedCloze(tester);
      platform.writes.clear();
      platform
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..throwReply = outcome.throws
        ..commitBeforeFailure = outcome.commits
        ..failReloadAfterWrite = outcome.throws;

      await tester.pumpWidget(
        _host(
          ClozeGameScreen(
            items: <ClozeItem>[fixture.item],
            courseUnitId: fixture.link.courseUnitId,
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () => find.text(fixture.item.answer).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(fixture.item.answer));
      await _flush(tester);

      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        1,
        reason: 'the real canonical native course setter must be reached',
      );
      expect(find.byType(AppError), findsOneWidget);
      expect(
        find.text(fixture.item.fullKo),
        findsNothing,
        reason: 'answer feedback must wait for confirmed course evidence',
      );
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      if (outcome.throws) {
        final writesBefore = Map<String, int>.of(platform.writes);
        retry();
        await _flush(tester);
        expect(find.byType(AppError), findsOneWidget);
        expect(platform.writes, writesBefore);
      }
      platform
        ..rejectKey = null
        ..unavailable = false;
      retry();
      retry();
      await _pumpUntil(
        tester,
        () => find.text(fixture.item.fullKo).evaluate().isNotEmpty,
      );

      expect(find.byType(AppError), findsNothing);
      expect(find.text(fixture.item.fullKo), findsOneWidget);
      expect(Storage.srsCard(fixture.item.answer)?.reviewCount, 1);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        outcome.finalWrites,
      );
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == fixture.item.id)
          .toList();
      expect(evidence, isNotEmpty);
      expect(evidence.every((entry) => entry.isCorrect), isTrue);
      await tester.pump(const Duration(milliseconds: 1200));
    });
  }

  testWidgets(
    'linked cloze keeps wrong-first evidence when the learner corrects it',
    (tester) async {
      final fixture = await _loadLinkedCloze(tester);
      platform.writes.clear();
      await tester.pumpWidget(
        _host(
          ClozeGameScreen(
            items: <ClozeItem>[fixture.item],
            courseUnitId: fixture.link.courseUnitId,
            courseContext: CoursePracticeContext.fromLink(fixture.link),
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () => find.text(fixture.item.distractors.first).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(fixture.item.distractors.first));
      await _flush(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text(fixture.item.answer));
      await tester.pump(const Duration(milliseconds: 1100));
      await _flush(tester);

      final t = AppL10n.of(tester.element(find.byType(ClozeGameScreen)));
      expect(find.text(t.quizScore(0, 1)), findsOneWidget);
      expect(Storage.srsCard(fixture.item.answer)?.reviewCount, 1);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == fixture.item.id)
          .toList();
      expect(evidence, isNotEmpty);
      expect(evidence.every((entry) => !entry.isCorrect), isTrue);
      expect(
        evidence.every(
          (entry) => entry.errorReason == MasteryErrorReason.vocabularyRecall,
        ),
        isTrue,
      );
    },
  );

  testWidgets('cloze rejects an invalid supplied course route before input', (
    tester,
  ) async {
    final fixture = await _loadLinkedCloze(tester);
    platform.writes.clear();
    final valid = CoursePracticeContext.fromLink(fixture.link);
    final invalid = CoursePracticeContext(
      courseUnitId: valid.courseUnitId,
      contentKind: valid.contentKind,
      initialContentId: valid.initialContentId,
      contentLinkId: '${valid.contentLinkId}-invalid',
    );
    await tester.pumpWidget(
      _host(
        ClozeGameScreen(
          items: <ClozeItem>[fixture.item],
          courseUnitId: fixture.link.courseUnitId,
          courseContext: invalid,
        ),
      ),
    );
    await _pumpUntil(tester, () => find.byType(AppError).evaluate().isNotEmpty);

    expect(find.text(fixture.item.answer), findsNothing);
    expect(Storage.srsCard(fixture.item.answer), isNull);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
  });

  testWidgets('unlinked cloze browse is explicitly not applicable', (
    tester,
  ) async {
    CourseProgressService.shared.resetForTesting();
    await tester.runAsync(CurriculumCatalog.load);
    const item = ClozeItem(
      id: 'task42_unlinked_cloze',
      level: 'a1',
      sentenceKo: '저는 ＿＿＿ 가요.',
      answer: '집에',
      fullKo: '저는 집에 가요.',
      de: 'Ich gehe nach Hause.',
      en: 'I go home.',
      distractors: <String>['학교에', '회사에', '시장에'],
      topic: 'task42_unlinked',
    );
    platform.writes.clear();
    await tester.pumpWidget(
      _host(const ClozeGameScreen(items: <ClozeItem>[item])),
    );
    await _pumpUntil(
      tester,
      () => find.text(item.answer).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(item.answer));
    await _pumpUntil(
      tester,
      () => find.text(item.fullKo).evaluate().isNotEmpty,
    );

    expect(find.text(item.fullKo), findsOneWidget);
    expect(Storage.srsCard(item.answer)?.reviewCount, 1);
    expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], isNull);
    await tester.pump(const Duration(milliseconds: 1200));
  });

  for (final outcome
      in const <({String label, bool throws, bool commits, int finalWrites})>[
        (label: 'rejection', throws: false, commits: false, finalWrites: 3),
        (
          label: 'committed unknown',
          throws: true,
          commits: true,
          finalWrites: 2,
        ),
        (
          label: 'uncommitted unknown',
          throws: true,
          commits: false,
          finalWrites: 3,
        ),
      ]) {
    testWidgets(
      'audited standard scenario quest retains continuation until native course '
      '${outcome.label} is recovered',
      (tester) async {
        final fixture = await _loadAuditedScenario(tester);
        var resultPersistenceCalls = 0;
        ScenarioCompletionSummary? summary;
        platform.writes.clear();
        final writeEntered = Completer<void>();
        final releaseWrite = Completer<void>();
        platform
          ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
          ..throwReply = outcome.throws
          ..commitBeforeFailure = outcome.commits
          ..failReloadAfterWrite = outcome.throws
          ..writeEntered = writeEntered
          ..releaseWrite = releaseWrite;

        await tester.pumpWidget(
          _host(
            ScenarioPlayerScreen(
              scenarioId: fixture.scenario.id,
              courseContext: CoursePracticeContext.fromLink(fixture.link),
              scenarioLoader: (_) async => fixture.scenario,
              grammarLoader: () async => const <Grammar>[],
              resultPersister: (_, _, _) async {
                resultPersistenceCalls++;
                return null;
              },
              onCompleted: (value) => summary = value,
            ),
          ),
        );
        await _pumpUntil(
          tester,
          () => find
              .text(
                AppL10n.of(
                  tester.element(find.byType(ScenarioPlayerScreen)),
                ).scenarioStartBtn,
              )
              .evaluate()
              .isNotEmpty,
        );
        final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));
        await _tapText(tester, t.scenarioStartBtn);
        await _tapText(tester, t.scenarioNextBtn);
        await _tapText(tester, t.scenarioNextBtn);
        await _pumpUntil(
          tester,
          () => find.byType(SatzBauenQuest).evaluate().isNotEmpty,
        );

        final quest = tester.widget<SatzBauenQuest>(
          find.byType(SatzBauenQuest),
        );
        final questState = tester.state(find.byType(SatzBauenQuest));
        quest.onComplete(const QuestResult(passed: true, firstTry: true));
        await _pumpUntil(tester, () => writeEntered.isCompleted);
        expect(tester.state(find.byType(SatzBauenQuest)), same(questState));
        try {
          quest.onContinue!();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            resultPersistenceCalls,
            0,
            reason:
                'a child continuation callback cannot pass pending evidence',
          );
        } finally {
          releaseWrite.complete();
        }
        await _flush(tester);

        expect(
          platform.writes[Storage.courseMasterySnapshotPreferenceKey],
          greaterThanOrEqualTo(1),
          reason: 'the real canonical native course setter must be reached',
        );
        expect(find.byType(AppError), findsOneWidget);
        expect(tester.state(find.byType(SatzBauenQuest)), same(questState));
        expect(
          find.text(t.scenarioNextBtn),
          findsNothing,
          reason:
              'quest continuation must stay closed while evidence is pending',
        );
        final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
        if (outcome.throws) {
          final writesBefore = Map<String, int>.of(platform.writes);
          retry();
          await _flush(tester);
          expect(find.byType(AppError), findsOneWidget);
          expect(platform.writes, writesBefore);
        }
        platform
          ..rejectKey = null
          ..unavailable = false;
        retry();
        retry();
        await _flush(tester);

        expect(find.byType(AppError), findsNothing);
        expect(tester.state(find.byType(SatzBauenQuest)), same(questState));
        quest.onComplete(const QuestResult(passed: false, firstTry: false));
        quest.onContinue!();
        await _flush(tester);
        expect(resultPersistenceCalls, 1);
        expect(summary?.passed, 1);
        expect(summary?.total, 1);
        expect(
          platform.writes[Storage.courseMasterySnapshotPreferenceKey],
          outcome.finalWrites,
        );
        final snapshot = await CourseProgressService.shared.readForDisplay();
        final evidence = snapshot!.evidence
            .where((entry) => entry.contentId == fixture.scenario.id)
            .toList();
        expect(evidence, hasLength(fixture.quest.conceptIds.length));
        expect(evidence.every((entry) => entry.isCorrect), isTrue);
        quest.onComplete(const QuestResult(passed: false, firstTry: false));
        quest.onContinue!();
        await _flush(tester);
        expect(resultPersistenceCalls, 1);
        expect(summary?.passed, 1);
      },
    );
  }

  testWidgets(
    'scenario retry resumes at the rejected second concept without replaying '
    'the confirmed first concept',
    (tester) async {
      final partialPlatform = _OrdinalCourseFailurePlatform(
        rejectCourseWrite: 2,
      );
      Storage.resetForTesting();
      Storage.resetCourseMasteryForTesting();
      CourseProgressService.shared.resetForTesting();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      SharedPreferencesStorePlatform.instance = partialPlatform;
      platform = partialPlatform;
      await Storage.init();
      final fixture = await _loadAuditedScenario(tester);
      partialPlatform.resetCourseWriteTracking();
      var resultPersistenceCalls = 0;

      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen(
            scenarioId: fixture.scenario.id,
            courseContext: CoursePracticeContext.fromLink(fixture.link),
            scenarioLoader: (_) async => fixture.scenario,
            grammarLoader: () async => const <Grammar>[],
            resultPersister: (_, _, _) async {
              resultPersistenceCalls++;
              return null;
            },
          ),
        ),
      );
      await _advanceToAuditedQuest(tester);
      final quest = tester.widget<SatzBauenQuest>(find.byType(SatzBauenQuest));
      final questState = tester.state(find.byType(SatzBauenQuest));

      quest.onComplete(const QuestResult(passed: true, firstTry: true));
      await _pumpUntil(
        tester,
        () => find.byType(AppError).evaluate().isNotEmpty,
      );

      expect(partialPlatform.courseWrites, 2);
      expect(tester.state(find.byType(SatzBauenQuest)), same(questState));
      var snapshot = await CourseProgressService.shared.readForDisplay();
      var evidence = snapshot!.evidence
          .where((entry) => entry.contentId == fixture.scenario.id)
          .toList();
      expect(evidence, hasLength(1));
      expect(evidence.single.contentKind, CurriculumContentKind.scenario);
      expect(evidence.single.conceptId, fixture.quest.conceptIds.first);
      expect(evidence.single.courseUnitId, fixture.link.courseUnitId);
      expect(evidence.single.missionContentLinkId, fixture.link.id);
      expect(evidence.single.courseEligible, isTrue);

      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _pumpUntil(tester, () => partialPlatform.courseWrites == 3);
      await tester.pump();

      expect(partialPlatform.courseWrites, 3);
      expect(tester.state(find.byType(SatzBauenQuest)), same(questState));
      snapshot = await CourseProgressService.shared.readForDisplay();
      evidence = snapshot!.evidence
          .where((entry) => entry.contentId == fixture.scenario.id)
          .toList();
      expect(evidence, hasLength(fixture.quest.conceptIds.length));
      quest.onContinue!();
      await _flush(tester);
      expect(resultPersistenceCalls, 1);
    },
  );

  testWidgets(
    'two audited quests keep distinct outcomes and reject a stale first quest '
    'callback',
    (tester) async {
      final fixture = await _loadTwoAuditedQuests(tester);
      var resultPersistenceCalls = 0;
      ScenarioCompletionSummary? summary;
      platform.writes.clear();
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen(
            scenarioId: fixture.scenario.id,
            scenarioLoader: (_) async => fixture.scenario,
            grammarLoader: () async => const <Grammar>[],
            resultPersister: (_, _, _) async {
              resultPersistenceCalls++;
              return null;
            },
            onCompleted: (value) => summary = value,
          ),
        ),
      );
      await _advanceToQuest(tester, find.byType(HoerverstehenQuest));
      final first = tester.widget<HoerverstehenQuest>(
        find.byType(HoerverstehenQuest),
      );
      first.onComplete(const QuestResult(passed: true, firstTry: true));
      await _pumpUntil(
        tester,
        () => platform.writes[Storage.courseMasterySnapshotPreferenceKey] == 1,
      );
      first.onContinue!();
      await _pumpUntil(
        tester,
        () => find.byType(UebersetzenQuest).evaluate().isNotEmpty,
      );
      final second = tester.widget<UebersetzenQuest>(
        find.byType(UebersetzenQuest),
      );
      second.onComplete(const QuestResult(passed: false, firstTry: false));
      await _pumpUntil(
        tester,
        () => platform.writes[Storage.courseMasterySnapshotPreferenceKey] == 2,
      );

      first.onComplete(const QuestResult(passed: false, firstTry: false));
      first.onContinue!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(UebersetzenQuest), findsOneWidget);
      expect(resultPersistenceCalls, 0);

      second.onContinue!();
      await _flush(tester);
      expect(resultPersistenceCalls, 1);
      expect(summary?.passed, 1);
      expect(summary?.total, 2);
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final evidence = snapshot!.evidence
          .where((entry) => entry.contentId == fixture.scenario.id)
          .toList();
      expect(evidence, hasLength(2));
      expect(evidence.map((entry) => entry.id).toSet(), hasLength(2));
      expect(evidence.first.conceptId, fixture.quests.first.conceptIds.single);
      expect(evidence.first.isCorrect, isTrue);
      expect(evidence.first.errorReason, isNull);
      expect(evidence.last.conceptId, fixture.quests.last.conceptIds.single);
      expect(evidence.last.isCorrect, isFalse);
      expect(
        evidence.last.errorReason,
        masteryErrorForQuestType(fixture.quests.last.type),
      );
    },
  );

  testWidgets(
    'local reset during the first scenario concept stops later concepts and '
    'parent completion',
    (tester) async {
      final fixture = await _loadAuditedScenario(tester);
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      var resultPersistenceCalls = 0;
      platform
        ..writes.clear()
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = true
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen(
            scenarioId: fixture.scenario.id,
            courseContext: CoursePracticeContext.fromLink(fixture.link),
            scenarioLoader: (_) async => fixture.scenario,
            grammarLoader: () async => const <Grammar>[],
            resultPersister: (_, _, _) async {
              resultPersistenceCalls++;
              return null;
            },
          ),
        ),
      );
      await _advanceToAuditedQuest(tester);
      final quest = tester.widget<SatzBauenQuest>(find.byType(SatzBauenQuest));
      quest.onComplete(const QuestResult(passed: true, firstTry: true));
      await _pumpUntil(tester, () => writeEntered.isCompleted);

      final priorLifetime = LocalDataLifetime.capture();
      final reset = Storage.resetAllStrict();
      await _pumpUntil(tester, () => !priorLifetime.isCurrent);
      releaseWrite.complete();
      await _flush(tester);
      await reset;

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));
      expect(find.byType(AppError), findsOneWidget);
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
      await tester.ensureVisible(find.text(t.homeActionConfirmStay));
      await tester.tap(find.text(t.homeActionConfirmStay));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.homeActionConfirmTitle), findsNothing);
      quest.onContinue!();
      await _flush(tester);
      expect(resultPersistenceCalls, 0);
    },
  );

  testWidgets(
    'popping a scenario during the first concept write retires every later '
    'concept and parent completion',
    (tester) async {
      final fixture = await _loadAuditedScenario(tester);
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      final navigatorKey = GlobalKey<NavigatorState>();
      var resultPersistenceCalls = 0;
      platform
        ..writes.clear()
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = true
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;
      await tester.pumpWidget(_navigationHost(navigatorKey));
      final route = MaterialPageRoute<void>(
        builder: (_) => ScenarioPlayerScreen(
          scenarioId: fixture.scenario.id,
          courseContext: CoursePracticeContext.fromLink(fixture.link),
          scenarioLoader: (_) async => fixture.scenario,
          grammarLoader: () async => const <Grammar>[],
          resultPersister: (_, _, _) async {
            resultPersistenceCalls++;
            return null;
          },
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pump(const Duration(milliseconds: 400));
      await _advanceToAuditedQuest(tester);
      tester
          .widget<SatzBauenQuest>(find.byType(SatzBauenQuest))
          .onComplete(const QuestResult(passed: true, firstTry: true));
      await _pumpUntil(tester, () => writeEntered.isCompleted);

      navigatorKey.currentState!.removeRoute(route);
      await tester.pump();
      releaseWrite.complete();
      await _flush(tester);

      expect(find.byType(ScenarioPlayerScreen), findsNothing);
      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      expect(resultPersistenceCalls, 0);
    },
  );

  testWidgets(
    'popping cloze while the SRS write is pending prevents the course write',
    (tester) async {
      final fixture = await _loadLinkedCloze(tester);
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      final navigatorKey = GlobalKey<NavigatorState>();
      platform
        ..writes.clear()
        ..rejectKey = 'kl_srs_v1'
        ..successfulReply = true
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;
      await tester.pumpWidget(_navigationHost(navigatorKey));
      final route = MaterialPageRoute<void>(
        builder: (_) => ClozeGameScreen(
          items: <ClozeItem>[fixture.item],
          courseUnitId: fixture.link.courseUnitId,
          courseContext: CoursePracticeContext.fromLink(fixture.link),
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pump(const Duration(milliseconds: 400));
      await _pumpUntil(
        tester,
        () => find.text(fixture.item.answer).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(fixture.item.answer));
      await _pumpUntil(tester, () => writeEntered.isCompleted);

      navigatorKey.currentState!.removeRoute(route);
      await tester.pump();
      releaseWrite.complete();
      await _flush(tester);

      expect(find.byType(ClozeGameScreen), findsNothing);
      expect(platform.writes['kl_srs_v1'], 1);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
      );
    },
  );

  testWidgets(
    'scenario rejects an invalid supplied course route before quest admission',
    (tester) async {
      final fixture = await _loadAuditedScenario(tester);
      platform.writes.clear();
      final valid = CoursePracticeContext.fromLink(fixture.link);
      final invalid = CoursePracticeContext(
        courseUnitId: valid.courseUnitId,
        contentKind: valid.contentKind,
        initialContentId: valid.initialContentId,
        contentLinkId: '${valid.contentLinkId}-invalid',
      );
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen(
            scenarioId: fixture.scenario.id,
            courseContext: invalid,
            scenarioLoader: (_) async => fixture.scenario,
            grammarLoader: () async => const <Grammar>[],
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () => find.byType(AppError).evaluate().isNotEmpty,
      );

      expect(find.byType(SatzBauenQuest), findsNothing);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
      );
      expect(Storage.scenarioStars, isEmpty);
      expect(Storage.completedScenarios, isEmpty);
    },
  );

  for (final audited in <bool>[true, false]) {
    testWidgets('scenario rejects mismatched initial content before '
        '${audited ? 'audited' : 'untagged'} quest admission', (tester) async {
      final fixture = await _loadAuditedScenario(tester);
      final scenario = audited
          ? fixture.scenario
          : _copyScenarioWithQuests(fixture.scenario, <QuestSpec>[
              QuestSpec(type: fixture.quest.type, data: fixture.quest.data),
            ]);
      platform.writes.clear();
      final valid = CoursePracticeContext.fromLink(fixture.link);
      final mismatched = CoursePracticeContext(
        courseUnitId: valid.courseUnitId,
        contentKind: valid.contentKind,
        initialContentId: '${valid.initialContentId}-mismatched',
        contentLinkId: valid.contentLinkId,
      );
      await tester.pumpWidget(
        _host(
          ScenarioPlayerScreen(
            scenarioId: scenario.id,
            courseContext: mismatched,
            scenarioLoader: (_) async => scenario,
            grammarLoader: () async => const <Grammar>[],
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () => find.byType(AppError).evaluate().isNotEmpty,
      );

      expect(find.byType(SatzBauenQuest), findsNothing);
      expect(
        platform.writes[Storage.courseMasterySnapshotPreferenceKey],
        isNull,
      );
      expect(Storage.scenarioStars, isEmpty);
      expect(Storage.completedScenarios, isEmpty);
    });
  }

  testWidgets(
    'system back has one recovery confirmation and preserves Stay then Leave',
    (tester) async {
      final fixture = await _loadAuditedScenario(tester);
      final writeEntered = Completer<void>();
      final releaseWrite = Completer<void>();
      final navigatorKey = GlobalKey<NavigatorState>();
      var resultPersistenceCalls = 0;
      var exitCalls = 0;
      platform
        ..writes.clear()
        ..rejectKey = Storage.courseMasterySnapshotPreferenceKey
        ..successfulReply = true
        ..writeEntered = writeEntered
        ..releaseWrite = releaseWrite;
      await tester.pumpWidget(_navigationHost(navigatorKey));
      late final MaterialPageRoute<void> route;
      route = MaterialPageRoute<void>(
        builder: (_) => ScenarioPlayerScreen(
          scenarioId: fixture.scenario.id,
          courseContext: CoursePracticeContext.fromLink(fixture.link),
          scenarioLoader: (_) async => fixture.scenario,
          grammarLoader: () async => const <Grammar>[],
          resultPersister: (_, _, _) async {
            resultPersistenceCalls++;
            return null;
          },
          onExit: () {
            exitCalls++;
            if (route.isActive) {
              navigatorKey.currentState!.removeRoute(route);
            }
          },
        ),
      );
      navigatorKey.currentState!.push(route);
      await tester.pump(const Duration(milliseconds: 400));
      await _advanceToAuditedQuest(tester);
      final quest = tester.widget<SatzBauenQuest>(find.byType(SatzBauenQuest));
      final questState = tester.state(find.byType(SatzBauenQuest));
      quest.onComplete(const QuestResult(passed: true, firstTry: true));
      await _pumpUntil(tester, () => writeEntered.isCompleted);
      final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));

      try {
        unawaited(navigatorKey.currentState!.maybePop());
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
        await tester.ensureVisible(find.text(t.homeActionConfirmStay));
        await tester.tap(find.text(t.homeActionConfirmStay));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(t.homeActionConfirmTitle), findsNothing);
        expect(exitCalls, 0);
        expect(route.isCurrent, isTrue);
        expect(tester.state(find.byType(SatzBauenQuest)), same(questState));

        unawaited(navigatorKey.currentState!.maybePop());
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
        await tester.ensureVisible(find.text(t.homeActionConfirmLeave));
        await tester.tap(find.text(t.homeActionConfirmLeave));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(exitCalls, 1);
        expect(find.byType(ScenarioPlayerScreen), findsNothing);
      } finally {
        if (route.isActive) {
          navigatorKey.currentState!.removeRoute(route);
        }
        if (!releaseWrite.isCompleted) {
          releaseWrite.complete();
        }
        await _flush(tester);
      }

      expect(platform.writes[Storage.courseMasterySnapshotPreferenceKey], 1);
      expect(resultPersistenceCalls, 0);
    },
  );
}

Future<({ClozeItem item, ContentLink link})> _loadLinkedCloze(
  WidgetTester tester,
) async {
  late CurriculumCatalog catalog;
  late List<ClozeItem> items;
  CourseProgressService.shared.resetForTesting();
  await tester.runAsync(() async {
    catalog = await CurriculumCatalog.load();
    items = await ClozeLoader.load();
  });
  await CourseProgressService.shared.initializeForPlacement('a1');
  final link = catalog.contentLinks.firstWhere(
    (candidate) =>
        candidate.contentKind == CurriculumContentKind.cloze &&
        candidate.courseUnitId == 'a1_01_greetings_hangul',
  );
  final item = items.firstWhere((candidate) => candidate.id == link.contentId);
  return (item: item, link: link);
}

Future<({Scenario scenario, QuestSpec quest, ContentLink link})>
_loadAuditedScenario(WidgetTester tester) async {
  late CurriculumCatalog catalog;
  late Scenario source;
  CourseProgressService.shared.resetForTesting();
  ScenarioLoader.reset();
  await tester.runAsync(() async {
    catalog = await CurriculumCatalog.load();
    await ScenarioLoader.load();
    source = ScenarioLoader.byId('airport_arrival')!;
  });
  await CourseProgressService.shared.initializeForPlacement('a1');
  final link = catalog.contentLinks.firstWhere(
    (candidate) =>
        candidate.contentKind == CurriculumContentKind.scenario &&
        candidate.contentId == source.id,
  );
  final auditedQuest = source.quests.firstWhere(
    (quest) => quest.hasExplicitId && quest.conceptIds.isNotEmpty,
  );
  final scenario = Scenario(
    id: source.id,
    level: source.level,
    emoji: source.emoji,
    register: source.register,
    title: source.title,
    intro: source.intro,
    vocab: source.vocab,
    grammarIds: const <String>[],
    dialog: const <DialogLine>[],
    quests: <QuestSpec>[auditedQuest],
    courseUnitId: source.courseUnitId,
    speechStyle: source.speechStyle,
    relationshipContext: source.relationshipContext,
    intent: source.intent,
    playerCharacterId: source.playerCharacterId,
    participantIds: source.participantIds,
    shelf: source.shelf,
    backdrop: source.backdrop,
    conceptIds: source.conceptIds,
    surfaceFormIds: source.surfaceFormIds,
    xpReward: source.xpReward,
    sidekick: source.sidekick,
    preferredVoice: source.preferredVoice,
  );
  return (scenario: scenario, quest: auditedQuest, link: link);
}

Future<({Scenario scenario, List<QuestSpec> quests})> _loadTwoAuditedQuests(
  WidgetTester tester,
) async {
  late Scenario source;
  CourseProgressService.shared.resetForTesting();
  ScenarioLoader.reset();
  await tester.runAsync(() async {
    await CurriculumCatalog.load();
    await ScenarioLoader.load();
    source = ScenarioLoader.byId('a1_theme_park_date_choices')!;
  });
  await CourseProgressService.shared.initializeForPlacement('a1');
  final quests = source.quests
      .where((quest) => quest.hasExplicitId && quest.conceptIds.isNotEmpty)
      .take(2)
      .toList(growable: false);
  expect(quests, hasLength(2));
  final scenario = Scenario(
    id: source.id,
    level: source.level,
    emoji: source.emoji,
    register: source.register,
    title: source.title,
    intro: source.intro,
    vocab: source.vocab,
    grammarIds: const <String>[],
    dialog: const <DialogLine>[],
    quests: quests,
    courseUnitId: source.courseUnitId,
    speechStyle: source.speechStyle,
    relationshipContext: source.relationshipContext,
    intent: source.intent,
    playerCharacterId: source.playerCharacterId,
    participantIds: source.participantIds,
    shelf: source.shelf,
    backdrop: source.backdrop,
    conceptIds: source.conceptIds,
    surfaceFormIds: source.surfaceFormIds,
    xpReward: source.xpReward,
    sidekick: source.sidekick,
    preferredVoice: source.preferredVoice,
  );
  return (scenario: scenario, quests: quests);
}

Scenario _copyScenarioWithQuests(Scenario source, List<QuestSpec> quests) =>
    Scenario(
      id: source.id,
      level: source.level,
      emoji: source.emoji,
      register: source.register,
      title: source.title,
      intro: source.intro,
      vocab: source.vocab,
      grammarIds: const <String>[],
      dialog: const <DialogLine>[],
      quests: quests,
      courseUnitId: source.courseUnitId,
      speechStyle: source.speechStyle,
      relationshipContext: source.relationshipContext,
      intent: source.intent,
      playerCharacterId: source.playerCharacterId,
      participantIds: source.participantIds,
      shelf: source.shelf,
      backdrop: source.backdrop,
      conceptIds: source.conceptIds,
      surfaceFormIds: source.surfaceFormIds,
      xpReward: source.xpReward,
      sidekick: source.sidekick,
      preferredVoice: source.preferredVoice,
    );

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: child,
);

Widget _navigationHost(GlobalKey<NavigatorState> navigatorKey) => MaterialApp(
  navigatorKey: navigatorKey,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: const SizedBox.shrink(),
);

Future<void> _advanceToAuditedQuest(WidgetTester tester) async {
  await _advanceToQuest(tester, find.byType(SatzBauenQuest));
}

Future<void> _advanceToQuest(WidgetTester tester, Finder questFinder) async {
  await _pumpUntil(
    tester,
    () => find.byType(ScenarioPlayerScreen).evaluate().isNotEmpty,
  );
  final t = AppL10n.of(tester.element(find.byType(ScenarioPlayerScreen)));
  await _pumpUntil(
    tester,
    () => find.text(t.scenarioStartBtn).evaluate().isNotEmpty,
  );
  await _tapText(tester, t.scenarioStartBtn);
  await _tapText(tester, t.scenarioNextBtn);
  await _tapText(tester, t.scenarioNextBtn);
  await _pumpUntil(tester, () => questFinder.evaluate().isNotEmpty);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 30 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue);
}

final class _OrdinalCourseFailurePlatform extends RewardPreferencesPlatform {
  _OrdinalCourseFailurePlatform({required this.rejectCourseWrite});

  final int rejectCourseWrite;
  int courseWrites = 0;

  void resetCourseWriteTracking() {
    courseWrites = 0;
    writes.clear();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    final name = key.substring('flutter.'.length);
    if (name == Storage.courseMasterySnapshotPreferenceKey) {
      courseWrites++;
      if (courseWrites == rejectCourseWrite) {
        writes.update(name, (count) => count + 1, ifAbsent: () => 1);
        return Future<bool>.value(false);
      }
    }
    return super.setValue(valueType, key, value);
  }
}
