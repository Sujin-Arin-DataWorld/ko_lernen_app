import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_learning_start.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/foundation_learning_screen.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/sori_stage_pump.dart';
import 'support/sori_speech_stubs.dart';

const _course = CourseUnit(
  id: 'a1_intro',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greetings'),
  canDo: CurriculumText(ko: '인사해요', de: 'Ich grüße.', en: 'I greet.'),
);
const _placement = CourseMasterySnapshot(
  placementLevel: 'a1',
  currentCourseUnitId: 'a1_intro',
);
final _link = ContentLink(
  id: 'intro-grammar',
  contentKind: CurriculumContentKind.grammar,
  contentId: 'intro',
  courseUnitId: _course.id,
  conceptIds: [],
  role: ContentLinkRole.practice,
);

OnboardingJourneyState _completed({bool beginner = true}) =>
    OnboardingJourneyState.initial(DateTime.utc(2026, 9, 14)).copyWith(
      phase: OnboardingPhase.complete,
      levelDraft: LearnerLevel.a1,
      beginnerDraft: beginner,
      companionDraft: OnboardingCompanion.taego,
      commitStage: OnboardingCommitStage.completed,
      gateIntroAttempted: true,
      gateIntroConsumed: true,
    );

Future<void> _seed(
  OnboardingJourneyState? state, {
  Map<String, Object> values = const {},
}) async {
  Storage.resetForTesting();
  CourseProgressService.shared.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'kl_tut_home_tour': true,
    if (state != null)
      SharedPreferencesOnboardingJourneyRepository.preferenceKey: jsonEncode(
        state.toJson(),
      ),
    ...values,
  });
  await Storage.init();
}

Future<TodayLearningSnapshot> _today({
  CourseMasterySnapshot? course = _placement,
  int due = 0,
  TodayNetworkStatus network = TodayNetworkStatus.online,
}) => TodayLearningSnapshotLoader.load(
  readers: TodayLearningSourceReaders(
    course: () async => (units: [_course], snapshot: course),
    nowNode: () async => null,
    scenario: () async =>
        (current: null, completed: <String>{}, userLevel: LearnerLevel.a1),
    review: () async => (dueCount: due, hardCount: 0),
  ),
  networkStatusReader: () async => network,
);

Future<LearningFocus> _focus() => LearningFocus.load(
  loadToday: _today,
  loadBrief: (_) async => CourseMissionBrief.from(
    unit: _course,
    links: [_link],
    scenarios: [],
    isCurrent: true,
  ),
  resolve: (_) async => const CourseMissionDestination(route: '/grammar'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // The production wallet bootstrap loads these before opening a route.
    // Keep bundle I/O outside the widget's fake clock in this route fixture.
    await CurriculumCatalog.load();
    for (final kind in LearningContentKind.values) {
      await ContentLearningCatalog.load(kind);
    }
  });
  setUp(() async {
    stubSoriSpeech();
    LearningJourneyObserver.shared.cancel();
    await _seed(_completed());
  });
  tearDown(() {
    LearningJourneyObserver.shared.cancel();
    CourseProgressService.shared.resetForTesting();
    Storage.resetForTesting();
  });

  test(
    'completed beginner resumes its unread first Hangul offer without writes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      for (var read = 0; read < 3; read++) {
        final focus = await _focus();
        expect(focus.today.pick, isA<HangulIntroPick>());
        expect(
          focus.destination,
          const TodayLearningDestination(route: '/foundation'),
        );
        expect(focus.activityId, 'hangul');
        expect(focus.brief, isNull);
        expect(focus.ready, isTrue);
      }
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  test(
    'production Today loader keeps completed foundation until explicit A1 choice',
    () async {
      final catalog = await CurriculumCatalog.load();
      final placement = await CourseProgressService.shared
          .initializeForPlacement(LearnerLevel.a1.code);
      final courseBefore = Storage.courseMasterySnapshotRawJson;
      expect(placement.placementLevel, LearnerLevel.a1.code);
      expect(placement.completedUnitIds, isEmpty);
      expect(placement.evidence, isEmpty);
      expect(placement.phaseTaskEvidence, isEmpty);
      expect(
        catalog.courseUnits.map((unit) => unit.id),
        contains(placement.currentCourseUnitId),
      );

      final initial = await TodayLearningSnapshotLoader.load();
      expect(initial.isUnavailable, isFalse);
      // Fresh cards in the daily deck are distinct from actual reviewed cards.
      expect(Storage.srsReviewedIds, isEmpty);
      expect(initial.hardCount, 0);
      expect(initial.pick, isA<HangulIntroPick>());
      expect(
        initial.destination,
        const TodayLearningDestination(route: '/foundation'),
      );

      final lease = FoundationLearningLease.capture();
      final service = FoundationProgressService.shared;
      for (final step in FoundationStep.values) {
        await service.markStepOpened(step, lease: lease);
        for (final task in step.tasks) {
          // Simulate each accepted action through the real durable practice
          // API. The production loader decides the recommendation itself.
          final evidence = switch (step) {
            FoundationStep.sounds => FoundationPracticeEvidence.listen(
              task,
              playbackSucceeded: true,
              spokenConfirmation: true,
            ),
            FoundationStep.syllables => FoundationPracticeEvidence.read(
              task,
              correctComposition: true,
              spokenConfirmation: true,
            ),
            FoundationStep.tracing => FoundationPracticeEvidence.trace(
              task,
              matchedStrokes: true,
              confirmed: true,
            ),
            FoundationStep.firstWords => FoundationPracticeEvidence.word(
              task,
              playbackSucceeded: true,
              spokenConfirmation: true,
            ),
          };
          await service.savePractice(evidence, lease: lease);
        }
      }
      final practiced = await service.load(lease: lease);
      expect(practiced.practicedCount, 12);
      expect(practiced.isComplete, isTrue);
      expect(practiced.continuedToA1, isFalse);
      final completedPractice = await TodayLearningSnapshotLoader.load();
      expect(completedPractice.isUnavailable, isFalse);
      expect(completedPractice.pick, isA<HangulIntroPick>());
      expect(completedPractice.destination, initial.destination);
      expect(Storage.courseMasterySnapshotRawJson, courseBefore);

      await service.chooseContinueA1(lease: lease);
      final continued = await TodayLearningSnapshotLoader.load();
      expect(continued.isUnavailable, isFalse);
      expect(continued.pick, isA<CoursePick>());
      expect(
        (continued.pick! as CoursePick).unit.id,
        placement.currentCourseUnitId,
      );
      expect(
        continued.destination,
        const TodayLearningDestination(route: '/course/mission'),
      );
      expect(Storage.courseMasterySnapshotRawJson, courseBefore);
      expect(Storage.xp, 0);
      expect((await service.load()).practicedCount, 12);
    },
  );

  for (final state in [
    null,
    _completed(beginner: false),
    _completed().copyWith(
      phase: OnboardingPhase.gate,
      gateIntroConsumed: false,
    ),
  ]) {
    test(
      'missing, ordinary A1 or unfinished journey keeps the course: ${state?.phase}/${state?.beginnerDraft}',
      () async {
        await _seed(state);
        final focus = await _focus();
        expect(focus.today.pick, isA<CoursePick>());
        expect(focus.destination?.route, '/grammar');
      },
    );
  }

  for (final history in [
    'hangul',
    'grammar',
    'game',
    'coach',
    'xp',
    'words',
    'course',
    'review',
  ]) {
    test(
      'prior $history activity cannot manufacture foundation completion',
      () async {
        switch (history) {
          case 'hangul':
            await Storage.recordCatalogActivity('hangul');
          case 'grammar':
            await Storage.recordCatalogActivity('grammar');
          case 'game':
            await Storage.recordCatalogActivity('chosung');
          case 'coach':
            await Storage.setTutSeen('hangul');
          case 'xp':
            await Storage.setXp(3);
          case 'words':
            await _seed(
              _completed(),
              values: {
                'kl_vok_seen_ids': ['word'],
              },
            );
        }
        final today = await _today(
          course: history == 'course'
              ? _placement.copyWith(completedUnitIds: ['a1_prior'])
              : _placement,
          due: history == 'review' ? 1 : 0,
        );
        if (history == 'course' || history == 'review') {
          expect(today.pick, isA<CoursePick>());
        } else {
          expect(today.pick, isA<HangulIntroPick>());
        }
      },
    );
  }

  test(
    'explicit account-scoped A1 choice resumes course without assessment',
    () async {
      await FoundationProgressService.shared.chooseContinueA1(
        lease: FoundationLearningLease.capture(),
      );
      expect((await _focus()).today.pick, isA<CoursePick>());
      Storage.resetForTesting();
      await Storage.init();
      expect((await _focus()).today.pick, isA<CoursePick>());
      expect((await FoundationProgressService.shared.load()).practicedCount, 0);
      expect(Storage.xp, 0);
    },
  );

  test(
    'unknown onboarding and unavailable data keep the existing fallback',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SharedPreferencesOnboardingJourneyRepository.preferenceKey,
        'malformed',
      );
      expect(
        await OnboardingLearningStart.shouldOfferHangul(course: _placement),
        isFalse,
      );
      await _seed(_completed());
      final unavailable = await _today(network: TodayNetworkStatus.offline);
      expect(unavailable.isUnavailable, isTrue);
      expect(unavailable.pick, isA<CoursePick>());
    },
  );

  for (final locale in ['de', 'en']) {
    testWidgets(
      '$locale first CTA opens actual foundation; Back and restart retain its recommendation',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1152);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final nav = GlobalKey<NavigatorState>();
        final replay = ValueNotifier(0);
        addTearDown(replay.dispose);
        final opened = <String?>[];
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: nav,
            theme: AppTheme.light,
            locale: Locale(locale),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: SoriStageShell(
              replayHomeTour: replay,
              loadLearningFocus: _focus,
              loadTodaySnapshot: () async => SoriStageProgressionSnapshot(
                today: await _today(),
                hanokCompetence: const HanokCompetenceProjection.empty(),
                quests: [],
                pendingBojagiCount: 0,
                stampCount: 0,
                xp: 0,
                streakDays: 0,
                todayReward: null,
              ),
              loadReceiptNetworkBefore: () async =>
                  throw StateError('optional receipt'),
            ),
            onGenerateRoute: (settings) {
              opened.add(settings.name);
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => settings.name == '/foundation'
                    ? FoundationLearningScreen(speechPlayer: (_) async => true)
                    : const Scaffold(body: Text('course activity')),
              );
            },
          ),
        );
        await pumpSoriStage(tester, frames: 4);
        final t = lookupAppL10n(Locale(locale));
        final focusCard = find
            .byKey(const ValueKey('learning-focus-surface'))
            .first;
        expect(
          find.descendant(
            of: focusCard,
            matching: find.text(t.foundationTitle),
          ),
          findsOneWidget,
        );
        final start = find.descendant(
          of: focusCard,
          matching: find.text(t.learningFocusStart),
        );
        await tester.ensureVisible(start);
        await tester.tap(start);
        await pumpSoriStage(tester, frames: 3);
        expect(opened, ['/foundation']);
        expect(find.byType(FoundationLearningScreen), findsOneWidget);
        expect(Storage.recentCatalogActivityId(SoriStageTab.learn), 'hangul');
        expect(Storage.xp, 0);
        nav.currentState!.popUntil((route) => route.isFirst);
        await pumpSoriStage(tester, frames: 4);
        expect(find.byType(FoundationLearningScreen), findsNothing);
        expect(
          find.descendant(
            of: focusCard,
            matching: find.text(t.foundationTitle),
          ),
          findsOneWidget,
        );
        expect((await _focus()).destination?.route, '/foundation');
        final state = await SharedPreferencesOnboardingJourneyRepository()
            .load();
        expect(
          state?.beginnerDraft,
          isTrue,
          reason:
              'Route visits retain the preference and never complete foundation practice.',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        Storage.resetForTesting();
        await Storage.init();
        expect((await _focus()).today.pick, isA<HangulIntroPick>());
        expect(Storage.xp, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
