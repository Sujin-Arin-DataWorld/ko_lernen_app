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
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
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
          const TodayLearningDestination(route: '/hangul'),
        );
        expect(focus.activityId, 'hangul');
        expect(focus.brief, isNull);
        expect(focus.ready, isTrue);
      }
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
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
    test('prior $history learning suppresses the introductory offer', () async {
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
      expect(today.pick, isA<CoursePick>());
    });
  }

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
      '$locale first CTA opens real Hangul; Back and restart restore course',
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
                builder: (_) => settings.name == '/hangul'
                    ? HangulScreen(
                        textPrefetcher: (_) async {},
                        speechPlayer: (_) async => true,
                      )
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
            matching: find.text(t.screenHangulTitle),
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
        expect(opened, ['/hangul']);
        expect(find.byType(HangulScreen), findsOneWidget);
        expect(Storage.recentCatalogActivityId(SoriStageTab.learn), 'hangul');
        expect(Storage.xp, 0);
        nav.currentState!.popUntil((route) => route.isFirst);
        await pumpSoriStage(tester, frames: 4);
        expect(find.byType(HangulScreen), findsNothing);
        expect(
          find.descendant(
            of: focusCard,
            matching: find.text(locale == 'de' ? 'Begrüßung' : 'Greetings'),
          ),
          findsOneWidget,
        );
        expect((await _focus()).destination?.route, '/grammar');
        final state = await SharedPreferencesOnboardingJourneyRepository()
            .load();
        expect(
          state?.beginnerDraft,
          isTrue,
          reason:
              'The learner preference is retained; activity history consumes the offer.',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        Storage.resetForTesting();
        await Storage.init();
        expect((await _focus()).today.pick, isA<CoursePick>());
        expect(Storage.xp, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
