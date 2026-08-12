import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/course_mastery.dart';
import '../models/course_mission_brief.dart';
import '../models/curriculum.dart';
import '../models/gye.dart';
import '../models/hanok_build_narrative.dart';
import '../models/hanok_stage.dart';
import '../models/personal_hanok.dart';
import '../models/personal_room.dart';
import '../models/scenario.dart';
import '../models/scenario_can_do_result.dart';
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
import 'character_selection_screen.dart';
import 'consent_screen.dart';
import 'course_mission_screen.dart';
import 'discover_screen.dart';
import 'first_voice_success_screen.dart';
import 'gye_screen.dart';
import 'gye_tab_screen.dart';
import 'hanok_world_screen.dart';
import 'home_screen.dart';
import 'learning_path_screen.dart';
import 'onboarding_start_screen.dart';
import 'practice_hub_screen.dart';
import 'profile_screen.dart';
import 'sarangbang_screen.dart';
import 'scenario_player_screen.dart';
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
      startNewLearner: (_) async {},
      openFirstScene: (_, __) async {},
      openPlacement: () async {},
    ),
    '01C' => FirstVoiceSuccessScreen(
      canDo: _greetingUnit.canDo.de,
      phrase: '안녕하세요.',
      finishOverride: (_) async {},
      chooseCompanionOverride: _ignoreAsync,
    ),
    '01D' => CharacterSelectionScreen.preview(onPreviewComplete: (_) {}),
    '02A' => _todayCourseHome(),
    '02B' => CourseMissionScreen.preview(
      brief: _missionBrief(),
      openLink: (_) async {},
    ),
    '02C' => ScenarioPlayerScreen.preview(
      fixture: const ScenarioPlayerPreviewFixture.action(
        scenario: _listeningScenario,
        stage: ScenarioStage.quest,
        missionTitle: 'Weniger scharf bestellen',
      ),
    ),
    '02D' => ScenarioPlayerScreen.preview(
      fixture: const ScenarioPlayerPreviewFixture.result(
        scenario: _greetingScenario,
        result: _verifiedResult,
        onReturn: _ignore,
        onRepeat: _ignore,
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
    '06B' => HomeScreen(
      previewMode: true,
      loadTodaySnapshot: _offlineToday,
      onOpenSavedReview: _ignoreAsync,
      ensureTodayPackAccess: (_) async => true,
      openTodayRoute: (_, __) async {},
    ),
    '06C' => _reviewFirstHome(),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('UX Gallery')),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${routeName ?? 'Diese Aktion'} ist in der Vorschau schreibgeschützt.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

Widget _todayCourseHome() {
  final projection = PersonalHanokProjection.from(
    const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
  );
  return HomeScreen.preview(
    now: () => DateTime(2026, 8, 12),
    dailyCharacter: '한',
    previewFixture: HomePreviewFixture(
      today: const TodayLearningSnapshot(
        pick: CoursePick(
          unit: _greetingUnit,
          missionNumber: 1,
          totalMissions: 36,
          fraction: 0,
          started: false,
        ),
        scenario: _greetingScenario,
        destination: TodayLearningDestination(route: '/course/mission'),
      ),
      hanok: projection,
      narrative: HanokBuildNarrative(
        projection: projection,
        nextUnit: _greetingUnit,
      ),
      onOpenToday: (_) {},
      onOpenHanok: _ignore,
    ),
  );
}

Widget _reviewFirstHome() {
  final projection = PersonalHanokProjection.from(
    const LevelRatios(a1: .5, a2: 0, b1: 0, b2: 0),
  );
  return HomeScreen.preview(
    now: () => DateTime(2026, 8, 12),
    previewFixture: HomePreviewFixture(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanok: projection,
      narrative: HanokBuildNarrative.empty(projection),
      onOpenToday: (_) {},
      onOpenHanok: _ignore,
    ),
  );
}

CourseMissionBrief _missionBrief() => CourseMissionBrief.from(
  unit: _greetingUnit,
  links: _greetingMissionLinks,
  scenarios: const [_greetingScenario],
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
    feedUpdates: Stream.value(const <GyeFeedEvent>[]),
    loadTodaySnapshot: () async => const TodayLearningSnapshot(
      pick: ReviewPick(dueCount: 12),
      destination: TodayLearningDestination(route: '/review'),
      dueCount: 12,
    ),
    resolvePromiseNavigation: (_, __) async =>
        const GyePromiseNavigationResolution(
          kind: GyePromiseNavigationKind.todayFallback,
          destination: TodayLearningDestination(route: '/review'),
        ),
    ensureTodayPackAccess: (_) async => true,
    openTodayRoute: (_, __) async {},
    onOpenMembers: _ignore,
    enableCoach: false,
  );
}

Future<List<GyeMeta>> _emptyGyes() async => const [];

Future<TodayLearningSnapshot> _offlineToday() async =>
    const TodayLearningSnapshot(
      pick: ReviewPick(dueCount: 12),
      destination: TodayLearningDestination(route: '/review'),
      dueCount: 12,
      availability: TodayLearningAvailability.unavailable,
      unavailableReason: TodayLearningUnavailableReason.offline,
    );

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

const _greetingScenario = Scenario(
  id: 'preview_greeting',
  level: LearnerLevel.a1,
  emoji: '👋',
  register: Register.polite,
  title: LocalizedText(
    ko: '첫 인사',
    de: 'Die erste Begrüßung',
    en: 'The first greeting',
  ),
  intro: LocalizedText(
    ko: '',
    de: 'Begrüße die Person höflich.',
    en: 'Greet the person politely.',
  ),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(speaker: 'user', ko: '안녕하세요.', de: 'Guten Tag.', en: 'Hello.'),
  ],
  quests: [],
);

const _listeningScenario = Scenario(
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

final _greetingLink = ContentLink(
  id: 'preview-greeting-link',
  contentKind: CurriculumContentKind.scenario,
  contentId: _greetingScenario.id,
  courseUnitId: _greetingUnit.id,
  conceptIds: const ['greeting'],
  role: ContentLinkRole.assess,
);

final _greetingMissionLinks = <ContentLink>[
  ContentLink(
    id: 'preview-greeting-vocab',
    contentKind: CurriculumContentKind.vocab,
    contentId: 'preview_greeting_word',
    courseUnitId: _greetingUnit.id,
    conceptIds: const ['greeting'],
    role: ContentLinkRole.introduce,
  ),
  ContentLink(
    id: 'preview-greeting-cloze',
    contentKind: CurriculumContentKind.cloze,
    contentId: 'preview_greeting_build',
    courseUnitId: _greetingUnit.id,
    conceptIds: const ['greeting'],
    role: ContentLinkRole.practice,
  ),
  _greetingLink,
];

const _verifiedResult = ScenarioCanDoResult(
  status: ScenarioCanDoStatus.verified,
  score: 1,
  courseUnit: _greetingUnit,
  structureStageBefore: HanokStage.foundation,
  structureStageAfter: HanokStage.pillars,
);

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
