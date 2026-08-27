import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordedEvent {
  const _RecordedEvent(this.name, this.parameters);
  final String name;
  final Map<String, Object>? parameters;
}

class _FakeAnalyticsClient implements AnalyticsEventClient {
  final List<_RecordedEvent> events = [];
  final List<String> screens = [];
  final List<MapEntry<String, String?>> props = [];
  bool throwOnNext = false;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (throwOnNext) {
      throwOnNext = false;
      throw StateError('analytics unavailable');
    }
    events.add(_RecordedEvent(name, parameters));
  }

  @override
  Future<void> logScreenView({required String screenName}) async {
    if (throwOnNext) {
      throwOnNext = false;
      throw StateError('analytics unavailable');
    }
    screens.add(screenName);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (throwOnNext) {
      throwOnNext = false;
      throw StateError('analytics unavailable');
    }
    props.add(MapEntry(name, value));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsController', () {
    test('forwards events and screen views when consent is granted', () async {
      final client = _FakeAnalyticsClient();
      final controller = AnalyticsController(
        hasConsent: () => true,
        client: client,
      );

      await controller.logEvent(
        'pack_completed',
        parameters: {'pack_id': 'a1'},
      );
      await controller.logScreenView('/vocab');

      expect(client.events, hasLength(1));
      expect(client.events.single.name, 'pack_completed');
      expect(client.events.single.parameters, {'pack_id': 'a1'});
      expect(client.screens, ['/vocab']);
    });

    test('no-ops entirely when consent is withheld', () async {
      final client = _FakeAnalyticsClient();
      final controller = AnalyticsController(
        hasConsent: () => false,
        client: client,
      );

      await controller.logEvent('pack_completed');
      await controller.logScreenView('/vocab');

      expect(client.events, isEmpty);
      expect(client.screens, isEmpty);
    });

    test('swallows client errors so a flow is never broken', () async {
      final client = _FakeAnalyticsClient()..throwOnNext = true;
      final controller = AnalyticsController(
        hasConsent: () => true,
        client: client,
      );

      // Must not throw even though the underlying client does.
      await controller.logEvent('gye_created');
      expect(client.events, isEmpty);
    });

    test('re-reads consent on every call (late opt-in is honoured)', () async {
      final client = _FakeAnalyticsClient();
      var consent = false;
      final controller = AnalyticsController(
        hasConsent: () => consent,
        client: client,
      );

      await controller.logEvent('gye_joined');
      expect(client.events, isEmpty);

      consent = true;
      await controller.logEvent('gye_joined');
      expect(client.events.single.name, 'gye_joined');
    });

    test('forwards user properties only while consent is granted', () async {
      final client = _FakeAnalyticsClient();
      var consent = true;
      final controller = AnalyticsController(
        hasConsent: () => consent,
        client: client,
      );

      await controller.setUserProperty('learner_level', 'A2');
      consent = false;
      await controller.setUserProperty('ui_language', 'de');

      expect(client.props, hasLength(1));
      expect(client.props.single.key, 'learner_level');
      expect(client.props.single.value, 'A2');
    });
  });

  test('book capture telemetry contains only bounded quality metadata', () {
    final parameters = Analytics.bookCaptureAnalysisParameters(
      targetLang: 'en',
      words: 3,
      grammar: 1,
      sentences: 2,
      offline: false,
      resultStatus: 'blocked_content',
      warningBucket: 'content',
      ocrQuality: 'warning',
    );

    expect(parameters, {
      'target_lang': 'en',
      'words': 3,
      'grammar': 1,
      'sentences': 2,
      'offline': 0,
      'result_status': 'blocked_content',
      'warning_bucket': 'content',
      'ocr_quality': 'warning',
    });
    expect(parameters.keys, isNot(contains('text')));
    expect(parameters.keys, isNot(contains('image_path')));
    expect(parameters.keys, isNot(contains('uid')));
  });

  group('Onboarding V2 bounded telemetry', () {
    test('story reach and dwell contain only stable page/exit buckets', () {
      expect(
        Analytics.onboardingStoryReachedParameters(
          StoryPageId.personalCurriculum,
        ),
        {'page': 'personal_curriculum'},
      );
      expect(
        Analytics.onboardingStoryDwellParameters(
          page: StoryPageId.heritageJourney,
          duration: const Duration(seconds: 12),
          exit: OnboardingStoryExit.dropped,
        ),
        {
          'page': 'heritage_journey',
          'duration_bucket': '10_29s',
          'exit': 'dropped',
        },
      );
    });

    test('story dwell duration boundaries stay low-cardinality', () {
      String bucket(Duration duration) =>
          Analytics.onboardingStoryDwellParameters(
                page: StoryPageId.learn,
                duration: duration,
                exit: OnboardingStoryExit.continued,
              )['duration_bucket']!
              as String;

      expect(bucket(Duration.zero), 'under_3s');
      expect(bucket(const Duration(seconds: 3)), '3_9s');
      expect(bucket(const Duration(seconds: 10)), '10_29s');
      expect(bucket(const Duration(seconds: 30)), '30s_plus');
    });

    test('purpose, level, and companion selections are closed enums', () {
      expect(
        Analytics.onboardingPurposeSelectionParameters(
          OnboardingPurpose.peopleCulture,
        ),
        {'kind': 'purpose', 'value': 'people_culture'},
      );
      expect(Analytics.onboardingLevelSelectionParameters(LearnerLevel.c2), {
        'kind': 'level',
        'value': 'C2',
      });
      expect(
        Analytics.onboardingCompanionSelectionParameters(
          OnboardingCompanion.joy,
        ),
        {'kind': 'companion', 'value': 'joy'},
      );
    });

    test('completion carries a bounded purpose for first-action cohorts', () {
      expect(
        Analytics.onboardingCompletedParameters(
          entryLevel: 'b1',
          hasPlacement: true,
          purpose: OnboardingPurpose.studyWork,
        ),
        {'entry_level': 'B1', 'has_placement': 1, 'purpose': 'study_work'},
      );
      expect(
        Analytics.onboardingCompletedParameters(
          entryLevel: 'unknown',
          hasPlacement: false,
        ),
        {'entry_level': 'UNKNOWN', 'has_placement': 0},
      );
    });

    test('total duration is bucketed and identifies the rollout flow', () {
      expect(
        Analytics.onboardingDurationParameters(
          duration: const Duration(minutes: 3),
          flow: OnboardingFlowVariant.full,
        ),
        {'duration_bucket': '3_4m', 'flow': 'full'},
      );
      expect(
        Analytics.onboardingDurationParameters(
          duration: const Duration(minutes: 5),
          flow: OnboardingFlowVariant.minimalSafe,
        ),
        {'duration_bucket': '5m_plus', 'flow': 'minimal_safe'},
      );
    });

    test('gate result schema has exactly one bounded terminal value', () {
      expect(
        [
          for (final result in OnboardingGateResult.values)
            Analytics.onboardingGateResultParameters(result),
        ],
        [
          {'result': 'completed'},
          {'result': 'skipped'},
          {'result': 'error'},
          {'result': 'fallback'},
        ],
      );
    });

    test('companion preview failures expose only a closed reason', () {
      expect(
        [
          for (final failure in OnboardingCompanionPreviewFailure.values)
            Analytics.onboardingCompanionPreviewFailureParameters(failure),
        ],
        [
          {'reason': 'initialization'},
          {'reason': 'playback'},
        ],
      );

      for (final failure in OnboardingCompanionPreviewFailure.values) {
        final parameters =
            Analytics.onboardingCompanionPreviewFailureParameters(failure);
        expect(parameters.keys, ['reason']);
        expect(parameters, isNot(contains('error')));
        expect(parameters, isNot(contains('asset')));
        expect(parameters, isNot(contains('device')));
      }
    });

    test('consented first learning action has only bounded cohort fields', () {
      expect(
        [
          for (final action in ConsentedFirstLearningAction.values)
            Analytics.consentedFirstLearningActionParameters(
              action,
              OnboardingPurpose.kContent,
            ),
        ],
        [
          {'action': 'course', 'purpose': 'k_content'},
          {'action': 'hangul', 'purpose': 'k_content'},
          {'action': 'scenario', 'purpose': 'k_content'},
          {'action': 'vocabulary', 'purpose': 'k_content'},
          {'action': 'grammar', 'purpose': 'k_content'},
          {'action': 'listening_pronunciation', 'purpose': 'k_content'},
          {'action': 'game', 'purpose': 'k_content'},
          {'action': 'personal_book', 'purpose': 'k_content'},
        ],
      );
      expect(
        Analytics.consentedFirstLearningActionParameters(
          ConsentedFirstLearningAction.hangul,
          null,
        ),
        {'action': 'hangul', 'purpose': 'unknown'},
      );
    });

    test('tracker never claims or buffers a pre-consent action', () async {
      var consent = false;
      var claimCount = 0;
      final recorded =
          <
            ({ConsentedFirstLearningAction action, OnboardingPurpose? purpose})
          >[];
      final tracker = ConsentedFirstLearningActionTracker(
        canCollect: () => consent,
        hasCompletedOnboarding: () => true,
        readPurpose: () => OnboardingPurpose.studyWork,
        claimDurably: () async {
          claimCount++;
          return true;
        },
        record: (action, purpose) async {
          recorded.add((action: action, purpose: purpose));
        },
      );

      await tracker.observe(ConsentedFirstLearningAction.hangul);
      expect(tracker.hasReserved, isFalse);
      expect(claimCount, 0);
      expect(recorded, isEmpty);

      consent = true;
      await tracker.observe(ConsentedFirstLearningAction.game);
      await tracker.observe(ConsentedFirstLearningAction.grammar);

      expect(tracker.hasReserved, isTrue);
      expect(claimCount, 1);
      expect(recorded, [
        (
          action: ConsentedFirstLearningAction.game,
          purpose: OnboardingPurpose.studyWork,
        ),
      ]);
    });

    test('tracker ignores actions before onboarding completes', () async {
      var completed = false;
      final recorded = <ConsentedFirstLearningAction>[];
      var claimCount = 0;
      final tracker = ConsentedFirstLearningActionTracker(
        canCollect: () => true,
        hasCompletedOnboarding: () => completed,
        readPurpose: () => OnboardingPurpose.dailyTravel,
        claimDurably: () async {
          claimCount++;
          return true;
        },
        record: (action, _) async => recorded.add(action),
      );

      await tracker.observe(ConsentedFirstLearningAction.scenario);
      completed = true;
      await tracker.observe(ConsentedFirstLearningAction.vocabulary);

      expect(recorded, [ConsentedFirstLearningAction.vocabulary]);
      expect(claimCount, 1);
    });

    test(
      'durable claim suppresses the event after a simulated restart',
      () async {
        var claimed = false;
        final recorded = <ConsentedFirstLearningAction>[];

        ConsentedFirstLearningActionTracker buildTracker() =>
            ConsentedFirstLearningActionTracker(
              canCollect: () => true,
              hasCompletedOnboarding: () => true,
              readPurpose: () => OnboardingPurpose.kContent,
              claimDurably: () async {
                if (claimed) {
                  return false;
                }
                claimed = true;
                return true;
              },
              record: (action, _) async => recorded.add(action),
            );

        await buildTracker().observe(ConsentedFirstLearningAction.game);
        await buildTracker().observe(ConsentedFirstLearningAction.grammar);

        expect(recorded, [ConsentedFirstLearningAction.game]);
      },
    );

    test(
      'concurrent observations reserve the first action synchronously',
      () async {
        final claim = Completer<bool>();
        var claimCount = 0;
        final recorded = <ConsentedFirstLearningAction>[];
        final tracker = ConsentedFirstLearningActionTracker(
          canCollect: () => true,
          hasCompletedOnboarding: () => true,
          readPurpose: () => OnboardingPurpose.peopleCulture,
          claimDurably: () {
            claimCount++;
            return claim.future;
          },
          record: (action, _) async => recorded.add(action),
        );

        final first = tracker.observe(ConsentedFirstLearningAction.scenario);
        final second = tracker.observe(ConsentedFirstLearningAction.game);
        claim.complete(true);
        await Future.wait([first, second]);

        expect(claimCount, 1);
        expect(recorded, [ConsentedFirstLearningAction.scenario]);
      },
    );

    test('claim failure is contained and a fresh process can retry', () async {
      final recorded = <ConsentedFirstLearningAction>[];
      final failing = ConsentedFirstLearningActionTracker(
        canCollect: () => true,
        hasCompletedOnboarding: () => true,
        readPurpose: () => OnboardingPurpose.studyWork,
        claimDurably: () => Future<bool>.error(StateError('write failed')),
        record: (action, _) async => recorded.add(action),
      );

      await expectLater(
        failing.observe(ConsentedFirstLearningAction.course),
        completes,
      );
      expect(recorded, isEmpty);

      final restarted = ConsentedFirstLearningActionTracker(
        canCollect: () => true,
        hasCompletedOnboarding: () => true,
        readPurpose: () => OnboardingPurpose.studyWork,
        claimDurably: () async => true,
        record: (action, _) async => recorded.add(action),
      );
      await restarted.observe(ConsentedFirstLearningAction.hangul);

      expect(recorded, [ConsentedFirstLearningAction.hangul]);
    });

    test('lesson types map only to closed first-action buckets', () {
      expect(
        {
          for (final type in [
            'course',
            'hangul',
            'scenario',
            'smalltalk',
            'vocab',
            'grammar',
            'listening',
            'pronunciation',
            'media_phrase',
          ])
            type: Analytics.firstLearningActionForLessonType(type),
        },
        {
          'course': ConsentedFirstLearningAction.course,
          'hangul': ConsentedFirstLearningAction.hangul,
          'scenario': ConsentedFirstLearningAction.scenario,
          'smalltalk': ConsentedFirstLearningAction.scenario,
          'vocab': ConsentedFirstLearningAction.vocabulary,
          'grammar': ConsentedFirstLearningAction.grammar,
          'listening': ConsentedFirstLearningAction.listeningPronunciation,
          'pronunciation': ConsentedFirstLearningAction.listeningPronunciation,
          'media_phrase': ConsentedFirstLearningAction.listeningPronunciation,
        },
      );
      expect(Analytics.firstLearningActionForLessonType('/smalltalk'), isNull);
      expect(
        Analytics.firstLearningActionForLessonType('learner text'),
        isNull,
      );
    });
  });

  group('Consented first learning action durable claim', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    tearDown(Storage.resetForTesting);

    test('persists one strict claim across Storage reinitialization', () async {
      expect(Storage.hasClaimedConsentedFirstLearningAction, isFalse);
      expect(await Storage.claimConsentedFirstLearningAction(), isTrue);
      expect(Storage.hasClaimedConsentedFirstLearningAction, isTrue);

      Storage.resetForTesting();
      await Storage.init();

      expect(Storage.hasClaimedConsentedFirstLearningAction, isTrue);
      expect(await Storage.claimConsentedFirstLearningAction(), isFalse);
    });

    test('serializes concurrent claims to one winner', () async {
      final claims = await Future.wait([
        Storage.claimConsentedFirstLearningAction(),
        Storage.claimConsentedFirstLearningAction(),
      ]);

      expect(claims.where((claimed) => claimed), hasLength(1));
      expect(Storage.hasClaimedConsentedFirstLearningAction, isTrue);
    });

    test('malformed non-empty marker fails closed', () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        Storage.consentedFirstLearningActionClaimPreferenceKey: 'future_value',
      });
      await Storage.init();

      expect(Storage.hasClaimedConsentedFirstLearningAction, isTrue);
      expect(await Storage.claimConsentedFirstLearningAction(), isFalse);
    });

    test('full local reset clears the install-scoped marker', () async {
      await Storage.claimConsentedFirstLearningAction();

      await Storage.resetAll();

      expect(Storage.hasClaimedConsentedFirstLearningAction, isFalse);
      expect(await Storage.claimConsentedFirstLearningAction(), isTrue);
    });
  });

  group('Onboarding V2 production privacy gate', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    tearDown(Storage.resetForTesting);

    test('requires analytics opt-in', () async {
      await Storage.setBirthYear(DateTime.now().year - 25);

      expect(Analytics.canCollect, isFalse);
    });

    test('unknown age fails closed despite a stored opt-in', () async {
      await Storage.setAnalyticsConsent(true);

      expect(Storage.birthYear, 0);
      expect(Analytics.canCollect, isFalse);
    });

    test('allows an opted-in adult', () async {
      await Storage.setBirthYear(DateTime.now().year - 25);
      await Storage.setAnalyticsConsent(true);

      expect(Analytics.canCollect, isTrue);
    });

    test('age gate overrides a stored opt-in for a minor', () async {
      await Storage.setBirthYear(DateTime.now().year - 12);
      await Storage.setAnalyticsConsent(true);

      expect(Storage.analyticsConsent, isTrue);
      expect(Analytics.canCollect, isFalse);
    });
  });

  group('Guide bounded telemetry', () {
    test('hub and topic-open events use bounded identities and open state', () {
      expect(Analytics.guideHubOpenedEventName, 'guide_hub_opened');
      expect(Analytics.guideHubOpenedParameters(), {'surface': 'guide_hub'});
      expect(
        Analytics.guideTopicOpenedParameters(
          topic: GuideAnalyticsSurface.learn,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
          openState: GuideTopicOpenState.firstOpen,
        ),
        {
          'surface': 'learn',
          'entry_surface': 'guide_hub',
          'open_state': 'first_open',
        },
      );
      expect(
        Analytics.guideTopicOpenedParameters(
          topic: GuideAnalyticsSurface.learn,
          entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
          openState: GuideTopicOpenState.reopen,
        ),
        {
          'surface': 'learn',
          'entry_surface': 'today_checklist',
          'open_state': 'reopen',
        },
      );
    });

    test('detail close uses a stable low-cardinality event name', () {
      expect(Analytics.guideTopicClosedEventName, 'guide_topic_closed');
      expect(Analytics.guideTopicClosedEventName.length, lessThanOrEqualTo(40));
    });

    test('topic events identify only topic and entry surface enums', () {
      expect(
        Analytics.guideTopicParameters(
          topic: GuideAnalyticsSurface.gamesAndRewards,
          entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
        ),
        {'surface': 'gamesAndRewards', 'entry_surface': 'today_checklist'},
      );
      expect(
        Analytics.guideTopicParameters(
          topic: GuideAnalyticsSurface.settings,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
        ),
        {'surface': 'settings', 'entry_surface': 'guide_hub'},
      );
    });

    test('Today card actions are a closed two-value contract', () {
      expect(
        [
          for (final action in GuideTodayCardAction.values)
            Analytics.guideTodayCardActionParameters(action),
        ],
        [
          {'action': 'dismissed'},
          {'action': 'restored'},
        ],
      );
    });

    test('routing failures expose only closed action and reason enums', () {
      final parameters = <Map<String, Object>>[
        for (final reason in GuideRoutingFailureReason.values)
          Analytics.guideRoutingFailureParameters(
            topic: GuideAnalyticsSurface.myBook,
            entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
            action: GuideRoutingAction.scenarioCategory,
            reason: reason,
          ),
      ];

      expect(parameters.map((value) => value['reason']), [
        'unavailable',
        'consent',
        'invalid_destination',
        'navigation',
        'rollback',
      ]);
      for (final value in parameters) {
        expect(value.keys, {'surface', 'entry_surface', 'action', 'reason'});
        expect(value['action'], 'scenario_category');
        expect(value.keys, isNot(contains('route')));
        expect(value.keys, isNot(contains('exception')));
        expect(value.keys, isNot(contains('content')));
      }
      expect(
        GuideRoutingAction.values
            .map(
              (action) => Analytics.guideRoutingFailureParameters(
                topic: GuideAnalyticsSurface.settings,
                entrySurface: GuideEntryAnalyticsSurface.guideHub,
                action: action,
                reason: GuideRoutingFailureReason.navigation,
              )['action'],
            )
            .toSet(),
        hasLength(GuideRoutingAction.values.length),
      );
    });

    test(
      'guide telemetry emits nothing while analytics consent is absent',
      () async {
        final client = _FakeAnalyticsClient();
        final controller = AnalyticsController(
          hasConsent: () => false,
          client: client,
        );

        await controller.logEvent(
          Analytics.guideTopicOpenedEventName,
          parameters: Analytics.guideTopicOpenedParameters(
            topic: GuideAnalyticsSurface.settings,
            entrySurface: GuideEntryAnalyticsSurface.guideHub,
            openState: GuideTopicOpenState.reopen,
          ),
        );
        await controller.logEvent(
          Analytics.guideRoutingFailedEventName,
          parameters: Analytics.guideRoutingFailureParameters(
            topic: GuideAnalyticsSurface.settings,
            entrySurface: GuideEntryAnalyticsSurface.guideHub,
            action: GuideRoutingAction.guideSettings,
            reason: GuideRoutingFailureReason.navigation,
          ),
        );
        await controller.logEvent(
          Analytics.guideHubOpenedEventName,
          parameters: Analytics.guideHubOpenedParameters(),
        );

        expect(client.events, isEmpty);
      },
    );
  });
}
