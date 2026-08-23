import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/course_mastery.dart';
import '../models/course_mission_brief.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../models/gye.dart';
import '../models/hanok_build_narrative.dart';
import '../models/hanok_stage.dart';
import '../models/personal_hanok.dart';
import '../models/personal_room.dart';
import '../models/scenario.dart';
import '../models/scenario_can_do_result.dart';
import '../models/sori_stage_progression.dart';
import '../models/ux_preview_catalog.dart';
import '../services/account/account_transition_coordinator.dart';
import '../services/account/account_ui_operations.dart';
import '../services/account/cloud_backup_deletion.dart';
import '../services/account/cloud_write_session.dart';
import '../services/gye_weekly_promise_navigation.dart';
import '../services/hanok_stage_service.dart';
import '../services/mission_recommender.dart';
import '../services/today_learning_snapshot.dart';
import '../theme.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/standard_page.dart';
import 'character_selection_screen.dart';
import 'consent_screen.dart';
import 'course_mission_screen.dart';
import 'discover_screen.dart';
import 'first_voice_success_screen.dart';
import 'gye_screen.dart';
import 'gye_tab_screen.dart';
import 'hanok_world_screen.dart';
import 'learning_path_screen.dart';
import 'onboarding_start_screen.dart';
import 'practice_hub_screen.dart';
import 'profile_screen.dart';
import 'sarangbang_screen.dart';
import 'scenario_player_screen.dart';
import 'sori_stage/sori_stage_preview_screens.dart';
import 'sori_stage/sori_stage_today_screen.dart';
import 'ux_preview_gallery_screen.dart';

/// Maps every documented UX panel to its production widget and a deterministic
/// read-only fixture. No builder reads a catalog, Firebase, or learner storage.
class UxPreviewRegistry {
  const UxPreviewRegistry();

  List<String> get panelIds =>
      List.unmodifiable(uxPreviewPanels.map((panel) => panel.id));

  String routeFor(UxPreviewPanel panel) => '/ux_gallery/${panel.id}';

  Widget buildPanel(UxPreviewPanel panel) => switch (panel.id) {
    '01A' => ConsentScreen.preview(onPreviewAccepted: _ignore),
    '01B' => OnboardingStartScreen.preview(
      initialMotivation: LearnerMotivation.travel,
      openPlacement: () async {},
    ),
    '01C' => FirstVoiceSuccessScreen(
      canDo: _greetingUnit.canDo.de,
      phrase: '안녕하세요.',
      finishOverride: (_) async {},
      chooseCompanionOverride: _ignoreAsync,
    ),
    '01D' => CharacterSelectionScreen.preview(onPreviewComplete: (_) {}),
    '02A' => const SoriStageTodayPreviewScreen(),
    '02B' => CourseMissionScreen.preview(
      brief: _missionBrief(),
      openLink: (_) async {},
    ),
    '02C' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _lessSpicyScenario,
        stage: ScenarioStage.quest,
        missionStep: _lessSpicySceneStep,
        missionTitle: 'Weniger scharf bestellen',
      ),
    ),
    '02D' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.result(
        scenario: _lessSpicyScenario,
        result: _verifiedLessSpicyResult,
        missionStep: _lessSpicySceneStep,
        missionTitle: 'Weniger scharf bestellen',
        onReturn: _ignore,
        onRepeat: _ignore,
      ),
    ),
    '02E' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _airportArrivalScenario,
        stage: ScenarioStage.quest,
        questIndex: 0,
      ),
    ),
    '02F' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _airportArrivalScenario,
        stage: ScenarioStage.quest,
        questIndex: 1,
      ),
    ),
    '02G' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _airportArrivalScenario,
        stage: ScenarioStage.quest,
        questIndex: 2,
      ),
    ),
    '02H' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _airportArrivalScenario,
        stage: ScenarioStage.quest,
        questIndex: 3,
      ),
    ),
    '02I' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _airportArrivalScenario,
        stage: ScenarioStage.quest,
        questIndex: 4,
      ),
    ),
    '02J' => ScenarioPlayerScreen.preview(
      fixture: ScenarioPlayerPreviewFixture.action(
        scenario: _businessMeetingIntroScenario,
        stage: ScenarioStage.rollenspiel,
      ),
    ),
    '03A' => _earlyHanok(),
    '03B' => _hanokMap(),
    '03C' => _sarangbang(),
    '04A' => const PracticeHubScreen.preview(previewDueCount: 12),
    '04B' => const DiscoverScreen.preview(),
    '04C' => LearningPathScreen.preview(
      courseUnits: _pathUnits,
      snapshot: const CourseMasterySnapshot(
        completedUnitIds: ['a1_01', 'a1_02'],
        currentCourseUnitId: 'a1_03',
      ),
      stage: HanokStage.pillars,
    ),
    '05A' => GyeTabScreen(
      loadGyeMetas: _emptyGyes,
      onFindOrCreate: _ignore,
      onContinueSolo: _ignore,
      enableCoach: false,
    ),
    '05B' => _gyePanel(courtyardFocus: false),
    '05C' => _gyePanel(courtyardFocus: true),
    '06A' => ProfileScreen.preview(
      accountOperations: const _PreviewAccountUiOperations(),
      cloudDataDeletionJournalState: const _FixedValueListenable(
        CloudBackupDeletionJournalState.clear,
      ),
      loadGyeMetas: _emptyGyes,
      previewMotivation: LearnerMotivation.travel,
      previewLevel: LearnerLevel.a1,
      previewCompanion: CompanionPreference.none,
    ),
    // Offline is a real Today availability state, rather than a visual mock.
    // The injected snapshot keeps the gallery read-only while exercising the
    // same safe-review and retry boundary as the canonical Stage home.
    '06B' => SoriStageTodayScreen(
      loadSnapshot: _loadOfflineTodayPreview,
      now: _previewTodayNow,
    ),
    '06C' => const SoriStageTodayPreviewScreen(),
    '07A' => const SoriStageTodayPreviewScreen(),
    '07B' => const SoriStageLessonPreviewScreen(),
    '07C' => const SoriStageRewardReceiptPreviewScreen(),
    '07D' => const SoriStageJourneyPreviewScreen(),
    _ => throw ArgumentError.value(panel.id, 'panel.id', 'Unknown UX panel'),
  };
}

/// Standalone debug app for visual review of the documented 01A–06C states.
///
/// Named navigation from a production preview is deliberately intercepted by
/// a read-only boundary. This keeps exploratory taps inside the gallery rather
/// than opening a production screen that could load or mutate learner state.
class UxPreviewApp extends StatelessWidget {
  const UxPreviewApp({
    super.key,
    this.initialPanelId,
    this.textScaler,
    this.registry = const UxPreviewRegistry(),
  });

  final String? initialPanelId;
  final TextScaler? textScaler;
  final UxPreviewRegistry registry;

  @override
  Widget build(BuildContext context) {
    final initialPanel = initialPanelId == null
        ? null
        : uxPreviewPanels.cast<UxPreviewPanel?>().firstWhere(
            (panel) => panel?.id == initialPanelId,
            orElse: () => null,
          );
    return MaterialApp(
      title: 'Hangul Sori · UX Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        final scaler = textScaler;
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: true,
            textScaler: scaler ?? media.textScaler,
          ),
          child: child!,
        );
      },
      home: initialPanel == null
          ? UxPreviewGalleryScreen(buildPanel: registry.buildPanel)
          : registry.buildPanel(initialPanel),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _UxPreviewNavigationBoundary(routeName: settings.name),
      ),
    );
  }
}

class _UxPreviewNavigationBoundary extends StatelessWidget {
  const _UxPreviewNavigationBoundary({this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) => SoriStandardFrame(
    appBarTitle: 'UX Gallery',
    padding: const EdgeInsets.all(24),
    builder: (context, padding) => Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Text(
          '${routeName ?? 'Diese Aktion'} ist in der Vorschau schreibgeschützt.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

CourseMissionBrief _missionBrief() => CourseMissionBrief.from(
  unit: _lessSpicyUnit,
  links: _lessSpicyMissionLinks,
  scenarios: const [_lessSpicyScenario],
  isCurrent: true,
);

Widget _earlyHanok() {
  final projection = PersonalHanokProjection.from(
    const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
  );
  return HanokWorldScreen.preview(
    projection: projection,
    narrative: HanokBuildNarrative(
      projection: projection,
      verifiedUnit: _greetingUnit,
      safeSceneCount: 1,
      safeScenesTowardNextBeam: 1,
      scenesPerBeam: 2,
      plannedBeamCount: 1,
    ),
    onOpenZone: (_) {},
  );
}

Widget _hanokMap() {
  final projection = PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
  );
  return HanokWorldScreen.preview(
    projection: projection,
    narrative: HanokBuildNarrative(
      projection: projection,
      receipt: const HanokLearningReceipt(
        nextScenarioId: 'bunshik_tteokbokki',
        nextExpressionKo: '안 맵게 해 주세요.',
      ),
    ),
    selectedZone: PersonalHanokZone.sarangbang,
    onOpenZone: (_) {},
  );
}

Widget _sarangbang() => SarangbangStudyScreen.preview(
  todaySnapshot: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  receipt: const HanokLearningReceipt(
    safeSceneCount: 1,
    safeScenesTowardNextBeam: 1,
    plannedBeamCount: 1,
    earnedExpressionCount: 1,
    latestSafeScenarioId: 'bunshik_tteokbokki',
    latestSafeExpressionKo: '안 맵게 해 주세요.',
  ),
  room: const SarangbangRoomState(
    placements: {
      PersonalRoomSurface.sarangbang: {'floor_center': 'decoration_soban'},
    },
    ownedDecor: {'decoration_soban'},
  ),
  onOpenRecommendation: (_) async {},
);

/// The Offline gallery panel must exercise the actual Sori Stage fallback,
/// without consulting storage or a remote source. The snapshot deliberately
/// carries no reward contract: a partial Today read never promises a reward.
Future<SoriStageProgressionSnapshot> _loadOfflineTodayPreview() async =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
        availability: TodayLearningAvailability.unavailable,
        unavailableReason: TodayLearningUnavailableReason.offline,
        unavailableSources: {TodayLearningSource.course},
      ),
      hanok: PersonalHanokProjection.from(
        const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
      ),
      quests: const [],
      pendingBojagiCount: 0,
      stampCount: 4,
      xp: 320,
      streakDays: 6,
      todayReward: null,
    );

DateTime _previewTodayNow() => DateTime(2026, 8, 14, 9);

Widget _gyePanel({required bool courtyardFocus}) {
  final meta = GyeMeta(
    id: courtyardFocus ? 'HOF506' : 'LICHT5',
    name: courtyardFocus ? 'Sori-Hof' : 'Laternen-Gye',
    code: courtyardFocus ? 'HOF506' : 'LICHT5',
    ownerId: 'preview-owner',
    memberCount: 4,
    weeklyPromiseSchemaVersion: 1,
    weeklyPromiseId: 'cafe_order',
    weeklyPromiseTarget: 3,
    weeklyPromiseProgress: courtyardFocus ? 3 : 2,
    lifetimeGoalsAchieved: courtyardFocus ? 4 : 2,
  );
  return GyeScreen(
    gyeId: meta.id,
    accountSessions: const _FixedValueListenable<CloudWriteSession?>(null),
    metaUpdates: Stream.value(meta),
    memberUpdates: Stream.value(const <GyeMember>[]),
    currentMemberUpdates: Stream.value(null),
    dedicationUpdates: Stream.value(const []),
    blockedUidUpdates: Stream.value(const <String>{}),
    feedUpdates: Stream.value(_gyePreviewFeed),
    loadTodaySnapshot: () async => const TodayLearningSnapshot(
      pick: CoursePick(
        unit: _gyePromiseUnit,
        missionNumber: 4,
        totalMissions: 36,
        fraction: 0.25,
        started: true,
      ),
      destination: TodayLearningDestination(
        route: '/course/mission',
        arguments: 'a1_04_order_request_object',
      ),
    ),
    resolvePromiseNavigation: (meta, today) async =>
        GyeWeeklyPromiseNavigation.resolve(
          meta: meta,
          today: today,
          contentLinks: [_gyePromiseAssessLink],
        ),
    ensureTodayPackAccess: (_) async => true,
    openTodayRoute: (_, __) async {},
    onOpenMembers: _ignore,
    onOpenSafeMessage: _ignore,
    onOpenReaction: _ignore,
    readOnlyPreview: true,
    enableCoach: false,
  );
}

Future<List<GyeMeta>> _emptyGyes() async => const [];

void _ignore([Object? _]) {}

Future<void> _ignoreAsync() async {}

class _FixedValueListenable<T> implements ValueListenable<T> {
  const _FixedValueListenable(this.value);

  @override
  final T value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _PreviewAccountUiOperations implements AccountUiOperations {
  const _PreviewAccountUiOperations();

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<bool> cancelReplacement() async => false;

  @override
  Future<AccountTransitionResult> confirmReplacement(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountTransitionResult(AccountTransitionStatus.blocked);

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async =>
      const AccountUiLinkBlocked();

  @override
  Future<AccountTransitionResult> resumeReplacement() async =>
      const AccountTransitionResult(AccountTransitionStatus.blocked);
}

const _greetingUnit = CourseUnit(
  id: 'a1_01_greeting',
  level: 'a1',
  order: 1,
  title: CurriculumText(
    ko: '인사와 한글',
    de: 'Begrüßen & Hangul',
    en: 'Greetings & Hangul',
  ),
  canDo: CurriculumText(
    ko: '공손하게 인사할 수 있어요.',
    de: 'Ich kann höflich begrüßen.',
    en: 'I can greet someone politely.',
  ),
  requiredConceptIds: ['greeting'],
  checkpointContentIds: ['scenario:preview_greeting'],
);

const _lessSpicyUnit = CourseUnit(
  id: 'a1_preview_less_spicy',
  level: 'a1',
  order: 1,
  title: CurriculumText(
    ko: '덜 맵게 주문하기',
    de: 'Weniger scharf bestellen',
    en: 'Order less spicy food',
  ),
  canDo: CurriculumText(
    ko: '공손하게 덜 맵게 해 달라고 부탁할 수 있어요.',
    de: 'Ich kann höflich um weniger scharfes Essen bitten.',
    en: 'I can politely ask for less spicy food.',
  ),
  requiredConceptIds: ['request_less_spicy'],
  checkpointContentIds: ['scenario:preview_less_spicy'],
);

const _lessSpicyScenario = Scenario(
  id: 'preview_less_spicy',
  level: LearnerLevel.a1,
  emoji: '🍲',
  register: Register.polite,
  title: LocalizedText(
    ko: '덜 맵게 부탁하기',
    de: 'Weniger scharf bestellen',
    en: 'Order less spicy food',
  ),
  intro: LocalizedText(
    ko: '',
    de: 'Erkenne die höfliche Bitte.',
    en: 'Recognize the polite request.',
  ),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '안 맵게 해 주세요.',
        'question': {
          'de': 'Was sagt die Person?',
          'en': 'What is the person saying?',
        },
        'instruction': {
          'de': 'Tippe erst, wenn du die Bitte erkannt hast.',
          'en': 'Tap only after you recognize the request.',
        },
        'options': [
          {'de': '매워요.', 'en': '매워요.'},
          {'de': '안 맵게 해 주세요.', 'en': '안 맵게 해 주세요.'},
          {'de': '감사합니다.', 'en': '감사합니다.'},
        ],
        'correctIndex': 1,
        'confirmSelection': true,
        'checkLabel': {'de': 'Meine Antwort prüfen', 'en': 'Check my answer'},
      },
    ),
  ],
);

const _airportArrivalScenario = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항에서 입국심사',
    de: 'Einreise am Flughafen',
    en: 'Airport immigration',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'options': [
          {'de': 'Erstes Mal in Korea?', 'en': 'First time in Korea?'},
          {'de': 'Wie lange bleiben Sie?', 'en': 'How long are you staying?'},
          {'de': 'Wo kommen Sie her?', 'en': 'Where are you from?'},
          {
            'de': 'Sind Sie geschäftlich hier?',
            'en': 'Are you here on business?',
          },
        ],
        'correctIndex': 0,
      },
    ),
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '한국 처음___?',
        'options': ['이세요', '이에요', '예요', '이요'],
        'correctIndex': 0,
      },
    ),
    QuestSpec(
      type: QuestType.uebersetzen,
      data: {
        'promptDe': 'Eine Woche.',
        'promptEn': 'A week.',
        'options': [
          {'ko': '일주일이요.'},
          {'ko': '처음이에요.'},
          {'ko': '관광이에요.'},
          {'ko': '여권이요.'},
        ],
        'correctIndex': 0,
      },
    ),
    QuestSpec(
      type: QuestType.satzBauen,
      data: {
        'targetKo': '안녕하세요. 처음 뵙겠습니다.',
        'promptDe': 'Begrüße eine unbekannte Person sicher.',
        'promptEn': 'Greet a new person safely.',
        'distractors': ['여권 보여 주세요', '일주일이요', '관광이에요'],
        'audioKo': '안녕하세요. 처음 뵙겠습니다.',
      },
    ),
    QuestSpec(
      type: QuestType.diktat,
      data: {
        'targetKo': '여권 보여주세요.',
        'audioKo': '여권 보여주세요.',
        'promptDe': 'Bitte Ihren Pass.',
        'promptEn': 'Passport, please.',
      },
    ),
  ],
);

const _businessMeetingIntroScenario = Scenario(
  id: 'business_meeting_intro',
  level: LearnerLevel.b2,
  emoji: '💼',
  register: Register.business,
  title: LocalizedText(
    ko: '비즈니스 미팅 — 첫 인사',
    de: 'Vorstellung beim Geschäftsmeeting',
    en: 'Business meeting: first introduction',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(
      speaker: 'minsu',
      ko: '어서 오세요. 먼 길 오셨네요. 저는 김은수라고 합니다. 프로젝트 총괄 담당입니다.',
      de: 'Herzlich willkommen. Mein Name ist Kim Eun-su.',
      en: 'Welcome. My name is Kim Eun-su.',
    ),
    DialogLine(
      speaker: 'user',
      ko: '처음 뵙겠습니다. 명함 드려도 될까요?',
      de: 'Freut mich sehr, Sie kennenzulernen. Darf ich Ihnen meine Visitenkarte überreichen?',
      en: 'Very pleased to meet you. May I give you my business card?',
    ),
    DialogLine(
      speaker: 'minsu',
      ko: '감사합니다. 저도 드릴게요. 어떤 분야를 담당하고 계세요?',
      de: 'Danke: hier ist auch meine.',
      en: "Thank you: here's mine as well.",
    ),
    DialogLine(
      speaker: 'user',
      ko: '저는 해외 마케팅을 담당하고 있습니다.',
      de: 'Ich bin für internationales Marketing zuständig.',
      en: 'I handle international marketing.',
    ),
    DialogLine(
      speaker: 'minsu',
      ko: '좋습니다. 이번 프로젝트 제안서 검토해 보셨나요?',
      de: 'Haben Sie die Projektunterlagen bereits durchgesehen?',
      en: 'Have you had a chance to look through the project proposal?',
    ),
    DialogLine(
      speaker: 'user',
      ko: '네, 읽어봤습니다.',
      de: 'Ja, ich habe sie gelesen.',
      en: "Yes, I've read them.",
    ),
  ],
  quests: [],
);

final _lessSpicyAssessLink = ContentLink(
  id: 'preview-less-spicy-assess',
  contentKind: CurriculumContentKind.scenario,
  contentId: _lessSpicyScenario.id,
  courseUnitId: _lessSpicyUnit.id,
  conceptIds: const ['request_less_spicy'],
  role: ContentLinkRole.assess,
);

final _lessSpicyMissionLinks = <ContentLink>[
  ContentLink(
    id: 'preview-less-spicy-vocab',
    contentKind: CurriculumContentKind.vocab,
    contentId: 'preview_less_spicy_phrase',
    courseUnitId: _lessSpicyUnit.id,
    conceptIds: const ['request_less_spicy'],
    role: ContentLinkRole.introduce,
  ),
  ContentLink(
    id: 'preview-less-spicy-cloze',
    contentKind: CurriculumContentKind.cloze,
    contentId: 'preview_less_spicy_build',
    courseUnitId: _lessSpicyUnit.id,
    conceptIds: const ['request_less_spicy'],
    role: ContentLinkRole.practice,
  ),
  _lessSpicyAssessLink,
];

final _lessSpicySceneStep = _requiredLessSpicySceneStep();

CourseMissionStep _requiredLessSpicySceneStep() {
  final step = CourseMissionStepPlan.fromLinks(
    _lessSpicyMissionLinks,
  ).stepForContentLinkId(_lessSpicyAssessLink.id);
  if (step == null) {
    throw StateError('The less-spicy assess step must stay in the mission.');
  }
  return step;
}

final _verifiedLessSpicySnapshot = CourseMasterySnapshot(
  currentCourseUnitId: _lessSpicyUnit.id,
  completedUnitIds: const ['a1_preview_less_spicy'],
  scenarioCheckpoints: [
    ScenarioCheckpointEvidence(
      id: 'preview-less-spicy-checkpoint',
      scenarioId: _lessSpicyScenario.id,
      courseUnitId: _lessSpicyUnit.id,
      missionContentLinkId: _lessSpicyAssessLink.id,
      score: 1,
      occurredAt: DateTime.utc(2026, 8, 12, 7, 45),
      courseEligible: true,
    ),
  ],
);

final _verifiedLessSpicyResult =
    ScenarioCanDoResult.fromSnapshot(
      snapshot: _verifiedLessSpicySnapshot,
      scenarioId: _lessSpicyScenario.id,
      courseUnits: const [_lessSpicyUnit],
      contentLinks: [_lessSpicyAssessLink],
      structureStageBefore: HanokStage.foundation,
      structureStageAfter: HanokStage.pillars,
    ) ??
    (throw StateError('The less-spicy preview checkpoint must stay valid.'));

const _gyePromiseUnit = CourseUnit(
  id: 'a1_04_order_request_object',
  level: 'a1',
  order: 4,
  title: CurriculumText(ko: '주문', de: 'Bestellen', en: 'Ordering'),
  canDo: CurriculumText(
    ko: '공손하게 주문해요.',
    de: 'Ich kann höflich bestellen.',
    en: 'I can order politely.',
  ),
  requiredConceptIds: ['concept_object_particle', 'concept_request_polite'],
  checkpointContentIds: ['scenario:bunshik_tteokbokki'],
);

final _gyePromiseAssessLink = ContentLink(
  id: 'link:e6a9f1197b48c79f58655c9a',
  contentKind: CurriculumContentKind.scenario,
  contentId: 'bunshik_tteokbokki',
  courseUnitId: _gyePromiseUnit.id,
  conceptIds: const ['concept_object_particle', 'concept_request_polite'],
  role: ContentLinkRole.assess,
);

const _gyePreviewFeed = <GyeFeedEvent>[
  GyeFeedEvent(
    id: 'preview-reaction',
    type: GyeFeedType.sticker,
    actorUid: 'preview-jina',
    actorNickname: 'Jina',
    payload: {'stickerCode': 2, 'targetEventId': 'preview-contribution'},
  ),
  GyeFeedEvent(
    id: 'preview-contribution',
    type: GyeFeedType.questCompleted,
    actorUid: 'preview-min',
    actorNickname: 'Min',
    payload: {'questId': 'weekly-promise-scene'},
  ),
];

const _pathUnits = <CourseUnit>[
  CourseUnit(
    id: 'a1_01',
    level: 'a1',
    order: 1,
    title: CurriculumText(ko: '첫째', de: 'Erste Mission', en: 'First mission'),
    canDo: CurriculumText(
      ko: '인사',
      de: 'freundlich beginnen',
      en: 'start kindly',
    ),
  ),
  CourseUnit(
    id: 'a1_02',
    level: 'a1',
    order: 2,
    title: CurriculumText(ko: '인사', de: 'Begrüßen & Hangul', en: 'Greeting'),
    canDo: CurriculumText(ko: '인사', de: 'freundlich beginnen', en: 'greet'),
  ),
  CourseUnit(
    id: 'a1_03',
    level: 'a1',
    order: 3,
    title: CurriculumText(ko: '소개', de: 'Name, Herkunft, Thema', en: 'Intro'),
    canDo: CurriculumText(
      ko: '소개',
      de: 'mich kurz vorstellen',
      en: 'introduce myself',
    ),
  ),
  CourseUnit(
    id: 'a1_04',
    level: 'a1',
    order: 4,
    title: CurriculumText(ko: '주문', de: 'Bestellen und bitten', en: 'Ordering'),
    canDo: CurriculumText(
      ko: '주문',
      de: 'höflich bestellen',
      en: 'order politely',
    ),
  ),
];
