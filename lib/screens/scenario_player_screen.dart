import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/course_practice_context.dart';
import '../models/course_mastery.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/hanok_competence.dart';
import '../models/personal_hanok.dart';
import '../models/scenario.dart';
import '../models/scenario_can_do_result.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_mission_navigation.dart';
import '../services/curriculum_catalog.dart';
import '../services/data_loader.dart';
import '../services/hanok_stage_service.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/scenario_loader.dart';
import '../services/scene_asset_resolver.dart';
import '../services/scenario_writing_check_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/can_do_result_card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/home_action.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/motion.dart' show SoriEntrance;
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/scenario_write_after_roleplay_card.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/wordbook_add.dart';
import 'quest_engines/hoerverstehen_quest.dart';
import 'quest_engines/luecken_quest.dart';
import 'quest_engines/batchim_drop_quest.dart';
import 'quest_engines/diktat_quest.dart';
import 'quest_engines/particle_pop_quest.dart';
import 'quest_engines/quest_models.dart';
import 'quest_engines/satz_bauen_quest.dart';
import 'quest_engines/uebersetzen_quest.dart';

/// Reihenfolge der Lern-Stages eines Szenarios.
/// Top-level + public → die Index-Mathematik ist rein testbar.
enum ScenarioStage { intro, vocab, dialog, grammar, rollenspiel, quest, result }

/// Reuse the scene's authored meaning without treating a comprehension answer
/// (which may describe an intention) as a literal translation of the audio.
String scenarioListeningTranscriptTranslation(
  Scenario scenario,
  QuestSpec quest,
  String language,
) {
  final audio = (quest.data['audioKo'] as String? ?? '').trim();
  if (audio.isEmpty) {
    return '';
  }
  for (final line in scenario.dialog) {
    if (line.ko.trim() == audio) {
      return line.pick(language);
    }
  }
  for (final word in scenario.vocab) {
    if (word.korean.trim() == audio) {
      return word.note?.pick(language) ?? '';
    }
  }
  // The default question asks for the sentence's meaning. Custom questions
  // may instead ask about intent; their answers are not audio translations.
  if (quest.data['question'] == null) {
    final options = quest.data['options'];
    final correct = (quest.data['correctIndex'] as num?)?.toInt() ?? 0;
    if (options is List && correct >= 0 && correct < options.length) {
      final option = options[correct];
      if (option is Map && option[language] is String) {
        return option[language] as String;
      }
    }
  }
  return '';
}

const _scenarioIntroHorizontalFocalPoints = <double>[
  -0.24,
  -0.12,
  0,
  0.12,
  0.24,
];
const _scenarioIntroVerticalFocalPoints = <double>[-0.12, 0, 0.12];

/// Stable unsigned 32-bit FNV-1a over UTF-8 bytes.
///
/// The 16-bit split keeps every intermediate below JavaScript's exact integer
/// limit, so VM and web builds select the same intro crop.
int scenarioIntroFnv1a32(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    final low = hash & 0xffff;
    final high = (hash >> 16) & 0xffff;
    const primeLow = 0x0193;
    const primeHigh = 0x0100;
    final lowProduct = low * primeLow;
    final middle = (high * primeLow + low * primeHigh) & 0xffff;
    hash = (lowProduct + (middle << 16)) & 0xffffffff;
  }
  return hash;
}

String scenarioIntroSeedFor(Scenario scenario) {
  final courseUnitId = scenario.courseUnitId.trim();
  return courseUnitId.isNotEmpty ? courseUnitId : scenario.id.trim();
}

Alignment scenarioIntroAlignmentFor(Scenario scenario) {
  final hash = scenarioIntroFnv1a32(scenarioIntroSeedFor(scenario));
  return Alignment(
    _scenarioIntroHorizontalFocalPoints[hash %
        _scenarioIntroHorizontalFocalPoints.length],
    _scenarioIntroVerticalFocalPoints[(hash >> 8) %
        _scenarioIntroVerticalFocalPoints.length],
  );
}

typedef ScenarioIntroAudioPrefetcher =
    Future<void> Function(ScenarioIntroAudioPrefetchRequest request);

/// The one cache-compatible audio request allowed during the intro dwell.
///
/// Voice resolution deliberately mirrors dialog playback. Canonical character
/// profiles stay authoritative; legacy scenes retain user=female and npc=male.
@immutable
class ScenarioIntroAudioPrefetchRequest {
  const ScenarioIntroAudioPrefetchRequest({
    required this.text,
    required this.voice,
  });

  final String text;
  final String voice;

  TtsCacheKey get cacheKey => TtsCacheKey.forRequest(voice: voice, text: text);
}

ScenarioIntroAudioPrefetchRequest? scenarioIntroAudioPrefetchFor(
  Scenario scenario,
) {
  if (scenario.dialog.isEmpty) {
    return null;
  }
  final first = scenario.dialog.first;
  final text = first.ko;
  if (text.trim().isEmpty) {
    return null;
  }
  final voice = TtsVoicePolicy.resolve(
    text: text,
    voice: scenario.voiceForSpeaker(first.speaker),
  );
  return ScenarioIntroAudioPrefetchRequest(text: text, voice: voice);
}

Future<void> _prefetchScenarioIntroAudio(
  ScenarioIntroAudioPrefetchRequest request,
) => SoriSpeech.prefetch(request.text, voice: request.voice);

/// Baut den Stage-Plan. `quest` erscheint [questCount]-mal. Rein (keine State),
/// damit Stage-Zählung/Quest-Index-Mapping per Unit-Test abgesichert sind.
List<ScenarioStage> buildScenarioStagePlan({
  required bool hasRollenspiel,
  required bool hasGrammar,
  required int questCount,
}) {
  return [
    ScenarioStage.intro,
    ScenarioStage.vocab,
    ScenarioStage.dialog,
    if (hasGrammar) ScenarioStage.grammar,
    if (hasRollenspiel) ScenarioStage.rollenspiel,
    for (var i = 0; i < questCount; i++) ScenarioStage.quest,
    ScenarioStage.result,
  ];
}

/// Resolves the first visible stage without letting a route invent progress.
/// Onboarding may skip explanation pages, but it still enters the existing
/// quest widget and remains browse-only until a typed course mission opens it.
int scenarioInitialStageIndex(
  List<ScenarioStage> plan, {
  required bool startAtFirstTask,
}) {
  if (!startAtFirstTask) return 0;
  final firstTask = plan.indexOf(ScenarioStage.quest);
  return firstTask < 0 ? 0 : firstTask;
}

/// Preserves the scenario result contract: persist once, then navigate.
Future<void> runScenarioResultAction({
  required Future<void> Function() persistResult,
  required Future<void> Function() navigate,
}) async {
  await persistResult();
  await navigate();
}

/// Records only failed, directly assessed quest targets as negative SRS
/// evidence. Reaching a scenario result page is not evidence that every word
/// displayed in [Scenario.vocab] was independently answered correctly.
Future<void> recordScenarioFailedQuestSrs({
  required Scenario scenario,
  required Iterable<int> failedQuestIndices,
}) async {
  final missedKeys = <String>{};
  for (final index in failedQuestIndices) {
    if (index >= 0 && index < scenario.quests.length) {
      missedKeys.addAll(scenario.quests[index].targetVocabKeys());
    }
  }
  for (final missed in missedKeys) {
    await Storage.srsReview(missed, gotIt: false, recordToStudyLog: false);
  }
}

/// One screen instance is one learning attempt. Historical mastery and a
/// second correct answer in the same attempt cannot reopen first-success UX.
class FirstCorrectAttemptGate {
  bool _reported = false;

  bool accept({required bool correct}) {
    if (!correct || _reported) {
      return false;
    }
    _reported = true;
    return true;
  }
}

/// Keeps delayed scenario loading from starting SDK tracking after exit, and
/// admits the tracking side effects at most once for one screen instance.
class ScenarioLoadLifecycleGate {
  bool _exitRequested = false;
  bool _lessonTrackingStarted = false;

  bool get canContinue => !_exitRequested;

  bool requestExit() {
    if (_exitRequested) {
      return false;
    }
    _exitRequested = true;
    return true;
  }

  void startLessonTracking(VoidCallback startTracking) {
    if (_exitRequested || _lessonTrackingStarted) {
      return;
    }
    _lessonTrackingStarted = true;
    startTracking();
  }
}

enum ScenarioFirstSuccessKind { listening, completion }

class ScenarioFirstSuccess {
  const ScenarioFirstSuccess({required this.phrase, required this.kind});

  final String phrase;
  final ScenarioFirstSuccessKind kind;
}

typedef ScenarioFirstCorrectCallback =
    void Function(ScenarioFirstSuccess success);

enum ScenarioPlayerMode { standard, onboardingFirstScene }

class ScenarioCompletionSummary {
  const ScenarioCompletionSummary({
    required this.firstSuccess,
    required this.passed,
    required this.total,
  });

  final ScenarioFirstSuccess? firstSuccess;
  final int passed;
  final int total;
}

/// Cinematic scene poster height shared by quest and roleplay frames.
double scenarioPosterHeight({
  required double viewportHeight,
  required double textScale,
}) {
  if (textScale >= 2.0) {
    return 72;
  }
  if (viewportHeight < 650 || textScale >= 1.6) {
    return 96;
  }
  return (viewportHeight * 0.24).clamp(120.0, 240.0);
}

class _QuestSegmentProgress extends StatelessWidget {
  const _QuestSegmentProgress({
    required this.current,
    required this.total,
    required this.semanticsLabel,
  });

  final int current;
  final int total;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < total; index++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  height: index == current ? 8 : 6,
                  decoration: BoxDecoration(
                    color: index < current
                        ? SoriColors.primary
                        : index == current
                        ? SoriColors.primary.withAlpha(82)
                        : surfaces.surfaceAlt,
                    borderRadius: BorderRadius.circular(SoriRadius.sm),
                    border: index == current
                        ? Border.all(color: SoriColors.primary, width: 1.5)
                        : null,
                  ),
                ),
              ),
              if (index < total - 1) const SizedBox(width: Spacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

typedef ScenarioCompletionCallback =
    FutureOr<void> Function(ScenarioCompletionSummary summary);

/// Describes only the Korean expression that the completed quest actually
/// checked. Invalid or incomplete legacy quest data fails closed.
ScenarioFirstSuccess? scenarioFirstSuccessForQuest(QuestSpec quest) {
  final data = quest.data;
  String? phrase;
  var kind = ScenarioFirstSuccessKind.completion;

  switch (quest.type) {
    case QuestType.hoerverstehen:
      phrase = _questString(data['audioKo']);
      kind = ScenarioFirstSuccessKind.listening;
    case QuestType.luecken:
      final sentence = _questString(data['sentence']);
      final answer = _correctQuestOption(data);
      if (sentence != null && answer != null) {
        phrase = sentence.contains('___')
            ? sentence.replaceFirst('___', answer)
            : sentence;
      }
    case QuestType.uebersetzen:
      final answer = _correctQuestValue(data);
      if (answer is Map) {
        phrase = _questString(answer['ko']);
      } else {
        phrase = _questString(answer);
      }
    case QuestType.particlePop:
      final prefix = _questComponent(data['prefix']);
      final answer = _correctQuestOption(data);
      final suffix = _questComponent(data['suffix']);
      if (prefix != null && answer != null && suffix != null) {
        phrase = '$prefix$answer$suffix';
      }
    case QuestType.batchimDrop:
      phrase =
          _questString(data['audioKo']) ?? _questString(data['targetWord']);
      kind = ScenarioFirstSuccessKind.listening;
    case QuestType.satzBauen:
    case QuestType.diktat:
      phrase = _questString(data['targetKo']) ?? _questString(data['audioKo']);
    case QuestType.schreiben:
      phrase = _questString(data['targetKo']);
  }

  if (phrase == null) {
    return null;
  }
  return ScenarioFirstSuccess(phrase: phrase, kind: kind);
}

Object? _correctQuestValue(Map<String, dynamic> data) {
  final options = data['options'];
  final index = (data['correctIndex'] as num?)?.toInt();
  if (options is! List ||
      index == null ||
      index < 0 ||
      index >= options.length) {
    return null;
  }
  return options[index];
}

String? _correctQuestOption(Map<String, dynamic> data) =>
    _questString(_correctQuestValue(data));

String? _questString(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _questComponent(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value;
}

typedef ScenarioResultPersister =
    Future<ScenarioCanDoResult?> Function(
      Scenario scenario,
      int stars,
      int earnedXp,
    );

typedef ScenarioGrammarLoader = Future<List<Grammar>> Function();

/// Resolves explicit scenario references without allowing corpus order or a
/// missing row to rewrite the authored teaching sequence.
List<Grammar> resolveScenarioGrammarIds(
  Iterable<String> grammarIds,
  Iterable<Grammar> grammar,
) {
  final byId = <String, Grammar>{};
  for (final entry in grammar) {
    final id = entry.id.trim();
    if (id.isNotEmpty) {
      byId.putIfAbsent(id, () => entry);
    }
  }
  return List<Grammar>.unmodifiable([
    for (final rawId in grammarIds)
      if (byId[rawId.trim()] case final entry?) entry,
  ]);
}

/// The optional post-roleplay exercise repeats one authored learner turn,
/// never an assistant line or a synthesized vocabulary fallback.
String? scenarioWritingPromptKo(Scenario scenario) {
  for (final line in scenario.dialog.reversed) {
    final korean = line.ko.trim();
    if (line.speaker == 'user' && korean.isNotEmpty) {
      return korean;
    }
  }
  return null;
}

/// Deterministic, storage-free state for rendering the production player in a
/// gallery or widget test. Production loaders, entitlement gates, evidence,
/// rewards, and progress persistence are bypassed.
class ScenarioPlayerPreviewFixture {
  const ScenarioPlayerPreviewFixture.action({
    required this.scenario,
    this.stage = ScenarioStage.dialog,
    this.questIndex = 0,
    this.missionStep,
    this.missionTitle,
    this.onReturn,
    this.onRepeat,
  }) : result = null;

  const ScenarioPlayerPreviewFixture.result({
    required this.scenario,
    required this.result,
    this.missionStep,
    this.missionTitle,
    this.onReturn,
    this.onRepeat,
  }) : stage = ScenarioStage.result,
       questIndex = 0;

  final Scenario scenario;
  final ScenarioStage stage;
  final int questIndex;
  final ScenarioCanDoResult? result;
  final CourseMissionStep? missionStep;
  final String? missionTitle;
  final VoidCallback? onReturn;
  final VoidCallback? onRepeat;
}

class ScenarioPlayerScreen extends StatefulWidget {
  final String scenarioId;

  /// §W2-Task7: 알고 있으면 `ScenarioLoader.findById` 가 이 레벨 샤드부터
  /// 찾도록 힌트를 준다 — 없으면 전체 순회(정확성은 동일, 최적화만 없음).
  final LearnerLevel? levelHint;
  final CoursePracticeContext? courseContext;
  final Future<Scenario?> Function(String scenarioId)? scenarioLoader;
  final ScenarioGrammarLoader? grammarLoader;
  final ScenarioResultPersister? resultPersister;
  final ScenarioCompletionCallback? onCompleted;
  final VoidCallback? onExit;
  final ScenarioPlayerMode mode;
  final ScenarioPlayerPreviewFixture? previewFixture;
  final ScenarioIntroAudioPrefetcher? introAudioPrefetcher;

  const ScenarioPlayerScreen({
    super.key,
    required this.scenarioId,
    this.levelHint,
    this.courseContext,
    this.scenarioLoader,
    this.grammarLoader,
    this.resultPersister,
    this.onCompleted,
    this.onExit,
    this.mode = ScenarioPlayerMode.standard,
    this.introAudioPrefetcher,
  }) : previewFixture = null;

  ScenarioPlayerScreen.preview({
    super.key,
    required ScenarioPlayerPreviewFixture fixture,
    this.onExit,
    this.introAudioPrefetcher,
  }) : scenarioId = fixture.scenario.id,
       levelHint = null,
       courseContext = null,
       scenarioLoader = null,
       grammarLoader = null,
       resultPersister = null,
       onCompleted = null,
       mode = ScenarioPlayerMode.standard,
       previewFixture = fixture;

  @override
  State<ScenarioPlayerScreen> createState() => _ScenarioPlayerScreenState();
}

class _ScenarioPlayerScreenState extends State<ScenarioPlayerScreen>
    with ScreenCoachMixin<ScenarioPlayerScreen> {
  Scenario? _scenario;
  CourseMissionStep? _missionStep;
  String? _missionTitle;
  CoursePracticeContext? _effectiveCourseContext;
  List<Grammar> _resolvedGrammar = const <Grammar>[];
  List<ScenarioStage> _plan = const [];
  int _stage = 0;
  QuestAbandonTracker? _abandonTracker;
  int _firstTryPassedCount = 0;
  int _passedCount = 0;
  bool _questReady = true; // false → Quest läuft noch, Next-Button deaktiviert
  int _roleplayTurnIndex = 0;
  late final PageController _pageCtrl;
  // 대사 스테이지 진입 시 대표 문장(첫 대사) 1회 자동재생 + 전환 시 정지
  // (지시서 4.5). ContentSpeechController 배선은 review_session_screen.dart
  // 선례를 그대로 따른다.
  final _speech = ContentSpeechController();
  // Quest-Indizes, die der Nutzer NICHT bestanden hat. Wird in _persistResult
  // konsumiert, um deren Ziel-Vokabeln SRS-mäßig herabzustufen (error-aware
  // review).
  final Set<int> _failedQuestIndices = <int>{};
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  final FirstCorrectAttemptGate _firstCorrectGate = FirstCorrectAttemptGate();
  final ScenarioLoadLifecycleGate _loadLifecycle = ScenarioLoadLifecycleGate();
  ScenarioFirstSuccess? _firstSuccess;
  bool _completionDelivered = false;
  bool _resultSaving = false;
  bool _resultPersisted = false;
  ScenarioCanDoResult? _canDoResult;
  Object? _loadFailure;
  bool _introAudioPrefetchStarted = false;

  // Wie viel Höhe das Szenen-Poster an den Quest-Inhalt abgibt.
  //
  // Das Poster nimmt sonst bis zu 24 % der Höhe ein; Hörverstehen mit vier
  // Antworten passte dann nicht mehr über die Falz — die letzten Optionen
  // wurden am Scroll-Rand hart angeschnitten (Jin 2026-08-23, Screenshot
  // "Einreise am Flughafen"). Statt das Poster überall statisch zu
  // verkleinern, gibt es genau den gemessenen Überlauf ab (bis hinunter zur
  // Kleinformat-Höhe [_questPosterMinHeight]). Monoton pro Szenario-Besuch,
  // damit Poster-Höhe und Scroll-Viewport nicht gegeneinander oszillieren.
  double _questPosterConcession = 0;

  /// Untergrenze beim Abgeben: die Höhe, die kleine Geräte (< 650 dp) ohnehin
  /// schon als reguläres Poster bekommen.
  static const double _questPosterMinHeight = 96;

  // ── 코치마크 타겟 ──
  final GlobalKey _stageAreaKey = GlobalKey();
  final GlobalKey _nextBtnKey = GlobalKey();

  @override
  String get coachId => 'scenario';

  /// 시나리오 로드됨 + 프리미엄 게이트 화면 아님(= 실제 콘텐츠 화면).
  @override
  bool get coachReady => _scenario != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    // 프리미엄 게이트를 통과한 시나리오만 코치 표시.
    if (_scenario == null) {
      return [];
    }
    return [
      SpotlightStep(
        targetKey: _stageAreaKey,
        title: t.coachScenarioStep1Title,
        body: t.coachScenarioStep1Body,
        icon: Icons.school_outlined,
      ),
      SpotlightStep(
        targetKey: _nextBtnKey,
        title: t.coachScenarioStep2Title,
        body: t.coachScenarioStep2Body,
        icon: Icons.arrow_forward_rounded,
      ),
    ];
  }

  // ─── Initialisierung ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.mode == ScenarioPlayerMode.onboardingFirstScene) {
      Analytics.tutorialStep(stepNumber: 2, stepName: 'first_scene');
    }
    final preview = widget.previewFixture;
    if (preview != null) {
      final scenario = preview.scenario;
      _scenario = scenario;
      _missionStep = preview.missionStep;
      _missionTitle = preview.missionTitle;
      _plan = buildScenarioStagePlan(
        hasRollenspiel: scenario.dialog.any((line) => line.speaker == 'user'),
        hasGrammar: scenario.grammarBlock != null,
        questCount: scenario.quests.length,
      );
      final requestedIndex = preview.stage == ScenarioStage.result
          ? _plan.length - 1
          : preview.stage == ScenarioStage.quest
          ? _plan.indexOf(ScenarioStage.quest) +
                preview.questIndex
                    .clamp(0, math.max(0, scenario.quests.length - 1))
                    .toInt()
          : _plan.indexOf(preview.stage);
      _stage = requestedIndex < 0 ? 0 : requestedIndex;
      _questReady =
          preview.stage != ScenarioStage.quest &&
          preview.stage != ScenarioStage.rollenspiel;
      _resultPersisted = preview.stage == ScenarioStage.result;
      _canDoResult = preview.result;
      _pageCtrl = PageController(initialPage: _stage);
      _startIntroAudioPrefetch(scenario);
      if (_plan[_stage] == ScenarioStage.dialog) {
        _autoPlayDialogEntry(scenario);
      }
      return;
    }
    _pageCtrl = PageController();
    _loadScenario();
    scheduleCoach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) _speech.subscribe(route);
  }

  @override
  void deactivate() {
    _speech.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    _speech.dispose();
    _abandonTracker?.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  /// 대사 스테이지의 대표 문장(첫 대사) 1회 자동재생 — 순차 전체 읽기가
  /// 아니라 진입 시 한 번만(지시서 4.5, §9-1 룰링).
  void _autoPlayDialogEntry(Scenario scenario) {
    if (scenario.dialog.isEmpty) return;
    final first = scenario.dialog.first;
    _speech.playOnEnter(
      first.ko,
      voice: scenario.voiceForSpeaker(first.speaker),
    );
  }

  Future<void> _loadScenario() async {
    try {
      await _loadScenarioOrExit();
    } catch (error) {
      debugPrint('Scenario load failed for ${widget.scenarioId}: $error');
      if (mounted && _loadLifecycle.canContinue) {
        setState(() => _loadFailure = error);
      }
    }
  }

  Future<void> _loadScenarioOrExit() async {
    final providedLoader = widget.scenarioLoader;
    final s = providedLoader != null
        ? await providedLoader(widget.scenarioId)
        : await _loadScenarioFromCatalog(widget.scenarioId);
    if (!mounted || !_loadLifecycle.canContinue) {
      return;
    }
    if (s != null) {
      _loadLifecycle.startLessonTracking(() {
        Analytics.lessonStarted(
          lessonType: 'scenario',
          lessonId: s.id,
          level: s.level.display,
        );
        _abandonTracker = QuestAbandonTracker(
          questType: 'scenario',
          questId: s.id,
          lastStepReached: () => 'stage_$_stage',
        );
      });
    }
    if (s == null) {
      _popAfterLoadExit();
      return;
    }
    final resolvedGrammar = await _resolveGrammar(s);
    if (!mounted || !_loadLifecycle.canContinue) {
      return;
    }
    final courseContext =
        widget.courseContext ??
        await activeScenarioCheckpointContext(widget.scenarioId);
    final catalog = courseContext?.isFor(CurriculumContentKind.scenario) == true
        ? await CurriculumCatalog.load()
        : null;
    if (!mounted || !_loadLifecycle.canContinue) {
      return;
    }
    // Premium-Gate (M4): A1-Szenarien frei, A2/B1/B2 erfordern ein Abo.
    // Deckt alle Einstiege ab (Home-CTA, Skill-Path, Szenarien-Liste).
    if (s.level != LearnerLevel.a1 && !PremiumService.hasContentAccess) {
      final ok = await PremiumService.gate(context);
      if (!mounted || !_loadLifecycle.canContinue) {
        return;
      }
      if (!ok) {
        _popAfterLoadExit();
        return;
      }
    }
    if (!mounted || !_loadLifecycle.canContinue) {
      return;
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    final candidateStep = catalog == null || courseContext == null
        ? null
        : CourseMissionStepPlan.fromLinks(
            catalog.linksForCourseUnit(courseContext.courseUnitId),
          ).stepForContentLinkId(courseContext.contentLinkId);
    final missionStep =
        candidateStep?.link.contentKind == CurriculumContentKind.scenario &&
            candidateStep?.link.contentId == s.id &&
            candidateStep?.link.courseUnitId == courseContext?.courseUnitId
        ? candidateStep
        : null;
    final missionTitle = catalog == null || missionStep == null
        ? null
        : catalog
              .courseUnitFor(missionStep.link.courseUnitId)
              ?.title
              .pick(languageCode);
    final plan = buildScenarioStagePlan(
      hasRollenspiel: s.dialog.any((line) => line.speaker == 'user'),
      hasGrammar: resolvedGrammar.isNotEmpty || s.grammarBlock != null,
      questCount: s.quests.length,
    );
    final initialStage = scenarioInitialStageIndex(
      plan,
      startAtFirstTask: widget.mode == ScenarioPlayerMode.onboardingFirstScene,
    );
    setState(() {
      _scenario = s;
      _resolvedGrammar = resolvedGrammar;
      _missionStep = missionStep;
      _missionTitle = missionTitle;
      _effectiveCourseContext = courseContext;
      _plan = plan;
      _stage = initialStage;
      _questReady = initialStage == 0;
    });
    if (initialStage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadLifecycle.canContinue && _pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(initialStage);
        }
      });
    }
    _startIntroAudioPrefetch(s);
  }

  void _startIntroAudioPrefetch(Scenario scenario) {
    if (_introAudioPrefetchStarted ||
        _stage < 0 ||
        _stage >= _plan.length ||
        _plan[_stage] != ScenarioStage.intro) {
      return;
    }
    final request = scenarioIntroAudioPrefetchFor(scenario);
    if (request == null) {
      return;
    }
    final prefetcher =
        widget.introAudioPrefetcher ??
        (widget.previewFixture == null ? _prefetchScenarioIntroAudio : null);
    if (prefetcher == null) {
      return;
    }
    _introAudioPrefetchStarted = true;
    unawaited(
      Future<void>.sync(() => prefetcher(request)).catchError((Object _) {}),
    );
  }

  Future<List<Grammar>> _resolveGrammar(Scenario scenario) async {
    if (scenario.grammarIds.isEmpty) {
      return const <Grammar>[];
    }
    try {
      final corpus = await (widget.grammarLoader ?? DataLoader.loadGrammar)();
      return resolveScenarioGrammarIds(scenario.grammarIds, corpus);
    } catch (error) {
      debugPrint('Scenario grammar load failed for ${scenario.id}: $error');
      return const <Grammar>[];
    }
  }

  Future<void> _retryLoadScenario() async {
    if (!mounted) {
      return;
    }
    setState(() => _loadFailure = null);
    await _loadScenario();
  }

  Future<Scenario?> _loadScenarioFromCatalog(String scenarioId) =>
      ScenarioLoader.findById(scenarioId, preferredLevel: widget.levelHint);

  // ─── Backdrop-Map ──────────────────────────────────────────────────────────

  /// Resolved static scene poster for the current scenario. Prefers a
  /// dedicated per-scenario asset and falls back to the category backdrop.
  String? get _backdropPoster =>
      _scenario == null ? null : SceneAssetResolver.posterAsset(_scenario!);

  // ─── Stage-Berechnung (plan-basiert, siehe buildScenarioStagePlan) ─────────

  int get _totalStages => _scenario == null ? 1 : _plan.length;

  /// Index des ersten Quest-Stages (oder -1, falls keine Quests).
  int get _questStartStage => _plan.indexOf(ScenarioStage.quest);

  /// Ist die aktuelle Stage die Ergebnis-Stage?
  bool get _isResultStage {
    if (_scenario == null || _stage < 0 || _stage >= _plan.length) return false;
    return _plan[_stage] == ScenarioStage.result;
  }

  /// Quest-Index (0-basiert) der aktuellen Stage
  int get _currentQuestIndex => _stage - _questStartStage;

  /// 지금 단계가 퀘스트인가. 퀘스트는 자기 CTA 를 직접 그리므로 시나리오의
  /// Weiter 를 겹쳐 띄우면 안 된다(§ `_buildNextButton` 주석).
  bool get _isQuestStage =>
      _scenario != null &&
      _stage >= 0 &&
      _stage < _plan.length &&
      _plan[_stage] == ScenarioStage.quest;

  bool get _isRoleplayStage =>
      _scenario != null &&
      _stage >= 0 &&
      _stage < _plan.length &&
      _plan[_stage] == ScenarioStage.rollenspiel;

  bool get _usesSegmentHeader => _isQuestStage || _isRoleplayStage;

  int get _segmentCurrent =>
      _isRoleplayStage ? _roleplayTurnIndex : _currentQuestIndex;

  int get _segmentTotal {
    if (_isRoleplayStage) {
      final turns =
          _scenario?.dialog.where((line) => line.speaker == 'user').length ?? 0;
      return turns == 0 ? 1 : turns;
    }
    return _scenario?.quests.length ?? 0;
  }

  double get _progress => _totalStages <= 1 ? 0 : _stage / (_totalStages - 1);

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _next() {
    if (!_questReady) return;
    final nextStage = _stage + 1;
    if (nextStage >= _totalStages) return;

    // Quest und Rollenspiel müssen erst abgeschlossen werden → Next sperren.
    final nextKind = _plan[nextStage];
    final nextNeedsCompletion =
        nextKind == ScenarioStage.quest ||
        nextKind == ScenarioStage.rollenspiel;
    if (nextKind == ScenarioStage.result) {
      final sc = _scenario;
      if (sc != null) {
        _ensureFeedbackCompletion(sc);
      }
    }
    if (nextKind == ScenarioStage.dialog) {
      final sc = _scenario;
      if (sc != null) {
        _autoPlayDialogEntry(sc);
      }
    }
    setState(() {
      _stage = nextStage;
      _questReady = !nextNeedsCompletion;
    });
    _pageCtrl.animateToPage(
      nextStage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    // A result is a calm persisted outcome, not a second reward ceremony.
    // Save on entry so the learner never has to press a misleading "complete"
    // button before seeing the can-do and structural evidence.
    if (nextKind == ScenarioStage.result) {
      final scenario = _scenario;
      if (scenario != null) {
        final score = _resultScore(scenario);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _complete(score.stars, score.earnedXp);
          }
        });
      }
    }
  }

  void _onQuestComplete(QuestResult result) {
    final scenario = _scenario;
    QuestSpec? completedQuest;
    if (scenario != null &&
        _currentQuestIndex >= 0 &&
        _currentQuestIndex < scenario.quests.length) {
      final quest = scenario.quests[_currentQuestIndex];
      completedQuest = quest;
      // Only audited pilot quest metadata writes concept evidence. Untagged
      // legacy quests still feed the scenario checkpoint at completion, which
      // avoids pretending that a single particle mistake affected every form
      // used elsewhere in the dialogue.
      if (widget.mode == ScenarioPlayerMode.standard &&
          widget.previewFixture == null &&
          quest.hasExplicitId &&
          quest.conceptIds.isNotEmpty) {
        for (final conceptId in quest.conceptIds) {
          // ignore: discarded_futures
          CourseActivityReporter.recordContentAttempt(
            CurriculumContentKind.scenario,
            scenario.id,
            result.passed,
            courseContext: widget.courseContext,
            conceptId: conceptId,
            errorReason: result.passed
                ? null
                : masteryErrorForQuestType(quest.type),
          );
        }
      }
    }
    if (result.passed) _passedCount++;
    if (result.firstTry && result.passed) _firstTryPassedCount++;
    if (!result.passed) _failedQuestIndices.add(_currentQuestIndex);
    if (result.passed &&
        completedQuest != null &&
        _firstCorrectGate.accept(correct: true)) {
      _firstSuccess = scenarioFirstSuccessForQuest(completedQuest);
    }
    setState(() => _questReady = true);
  }

  void _onCorrectAnswer({ScenarioFirstSuccess? firstSuccess}) {
    if (firstSuccess != null && _firstCorrectGate.accept(correct: true)) {
      _firstSuccess = firstSuccess;
    }
  }

  // ─── Stern-Berechnung ──────────────────────────────────────────────────────

  int _starsFor(int passed, int firstTryPassed, int total) {
    if (total == 0) return 0;
    if (passed == total && firstTryPassed == total) return 3;
    if (passed == total) return 2;
    if (passed >= (total * 0.6).ceil()) return 1;
    return 0;
  }

  ({int stars, int earnedXp}) _resultScore(Scenario scenario) {
    final stars = _starsFor(
      _passedCount,
      _firstTryPassedCount,
      scenario.quests.length,
    );
    final xpFull = scenario.xpReward;
    final earnedXp = stars == 3
        ? xpFull
        : stars == 2
        ? (xpFull * 2 ~/ 3)
        : stars == 1
        ? (xpFull ~/ 3)
        : 0;
    return (stars: stars, earnedXp: earnedXp);
  }

  // ─── Complete (Ergebnis speichern) ─────────────────────────────────────────

  Future<ScenarioCanDoResult?> _persistResult(int stars, int earnedXp) async {
    final s = _scenario;
    if (s == null) return null;
    final providedResultPersister = widget.resultPersister;
    if (providedResultPersister != null) {
      return providedResultPersister(s, stars, earnedXp);
    }

    HapticFeedback.heavyImpact();

    await Future.wait([
      Storage.addXp(earnedXp),
      Storage.setScenarioStars(s.id, stars),
      Storage.addCompletedScenario(s.id),
    ]);

    // Scenario completion is a checkpoint alongside, not a replacement for,
    // the concept-level evidence collected by vocabulary and game activities.
    // A replayed future scenario is retained by the engine as browse history
    // and never unlocks the current mission retroactively.
    final courseUpdate = await CourseActivityReporter.recordScenarioCheckpoint(
      s.id,
      passed: _passedCount,
      total: s.quests.length,
      courseContext: _effectiveCourseContext,
    );

    // Erster Abschluss → Badge
    if (!Storage.earnedBadges.contains('cafe_starter')) {
      await Storage.earnBadge('cafe_starter');
    }

    await recordScenarioFailedQuestSrs(
      scenario: s,
      failedQuestIndices: _failedQuestIndices,
    );

    if (courseUpdate == null) return null;
    final catalog = await CurriculumCatalog.load();
    final ratios = await HanokStageService.levelRatios();
    final beforeSnapshot =
        courseUpdate.previousSnapshot ?? courseUpdate.snapshot;

    PersonalHanokProjection project(CourseMasterySnapshot snapshot) =>
        PersonalHanokProjection.from(
          ratios,
          competence: HanokCompetenceProjection.fromSnapshot(
            snapshot: snapshot,
            courseUnits: catalog.courseUnits,
          ),
        );

    return ScenarioCanDoResult.fromSnapshot(
      snapshot: courseUpdate.snapshot,
      scenarioId: s.id,
      courseUnits: catalog.courseUnits,
      contentLinks: catalog.contentLinks,
      structureStageBefore: project(beforeSnapshot).structureStage,
      structureStageAfter: project(courseUpdate.snapshot).structureStage,
    );
  }

  Future<void> _complete(int stars, int earnedXp) async {
    final preview = widget.previewFixture;
    if (preview != null) {
      if (!_resultPersisted && mounted) {
        setState(() {
          _resultPersisted = true;
          _canDoResult = preview.result;
        });
      }
      return;
    }
    if (_resultSaving) return;
    if (_resultPersisted) {
      return;
    }

    final done = _scenario;
    if (done != null) {
      Analytics.lessonCompleted(
        lessonType: 'scenario',
        lessonId: done.id,
        level: done.level.display,
      );
      _abandonTracker?.markCompleted();
    }
    setState(() => _resultSaving = true);
    try {
      final canDoResult = await _persistResult(stars, earnedXp);
      if (!mounted) return;
      setState(() {
        _resultSaving = false;
        _resultPersisted = true;
        _canDoResult = canDoResult;
      });
      if (widget.mode == ScenarioPlayerMode.standard) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SoriCelebration.burst(context);
        });
      }
      final onCompleted = widget.onCompleted;
      if (!_completionDelivered && onCompleted != null) {
        _completionDelivered = true;
        await onCompleted(
          ScenarioCompletionSummary(
            firstSuccess: _firstSuccess,
            passed: _passedCount,
            total: done?.quests.length ?? 0,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultSaving = false);
      soriToast(context, AppL10n.of(context).courseCheckpointSaveError);
    }
  }

  // ─── Sprecher-Icon ─────────────────────────────────────────────────────────

  IconData _speakerIcon(String speaker) {
    switch (speaker) {
      case 'minsu':
        return Icons.badge_outlined;
      case 'jieun':
        return Icons.school_outlined;
      case 'user':
        return Icons.person_rounded;
      case 'narrator':
        return Icons.menu_book_outlined;
      case 'partner':
        return Icons.favorite_outline_rounded;
      case 'officer':
        return Icons.local_police_outlined;
      default:
        return Icons.record_voice_over_outlined;
    }
  }

  /// minsu/jieun이면 [Mascot] 위젯, 그 외엔 시맨틱 아이콘 반환.
  Widget _speakerAvatar(
    String speaker, {
    double size = 40,
    MascotEmotion emotion = MascotEmotion.smile,
  }) {
    final mascot = Mascot.forSpeaker(speaker, emotion: emotion, size: size);
    if (mascot != null) return mascot;
    return Icon(
      _speakerIcon(speaker),
      color: _speakerAccent(speaker),
      size: size * 0.6,
    );
  }

  // ─── Stage-Widgets ─────────────────────────────────────────────────────────

  Widget _buildIntro(AppL10n t, String lang) {
    final s = _scenario!;
    final ss = SoriSurfaces.of(context);
    return _StageScroll(
      child: Column(
        children: [
          _ScenarioIntroArt(
            posterAsset: _backdropPoster,
            alignment: scenarioIntroAlignmentFor(s),
            emoji: s.emoji,
            sidekick: s.sidekick,
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            t.scenarioIntroTitle,
            style: SoriTextTheme.of(
              context,
            ).caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            s.title.pick(lang),
            style: SoriTextTheme.of(context).display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            s.intro.pick(lang),
            style: SoriTextTheme.of(
              context,
            ).gloss.copyWith(color: ss.textMuted, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          SoriBadge.level(s.level.display, size: 28),
        ],
      ),
    );
  }

  Widget _buildVocab(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    const vocabAccent = SoriColors.info;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioVocabTitle, ss.textMuted),
          const SizedBox(height: Spacing.lg),
          ...sc.vocab.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: SoriCard(
                variant: SoriCardVariant.base,
                accent: vocabAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.korean,
                            style: SoriTextTheme.of(
                              context,
                            ).koDisplay.copyWith(color: vocabAccent),
                          ),
                        ),
                        IconButton(
                          tooltip: t.ttsListen,
                          constraints: const BoxConstraints.tightFor(
                            width: Spacing.xxxl,
                            height: Spacing.xxxl,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            SoriSpeech.speak(v.korean);
                          },
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: vocabAccent,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: vocabAccent.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        // 시나리오 단어를 내 단어장에 담기.
                        AddToWordbookButton(
                          korean: v.korean,
                          translationDe: v.note?.de ?? '',
                          translationEn: v.note?.en ?? '',
                          compact: true,
                        ),
                      ],
                    ),
                    if (v.aliases.isNotEmpty || v.variants.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: [
                          for (final alias in v.aliases)
                            _MiniChip(
                              alias,
                              vocabAccent,
                              foregroundColor: ss.textMuted,
                            ),
                          for (final variant in v.variants)
                            _MiniChip(variant, ss.textMuted),
                        ],
                      ),
                    ],
                    if (v.note != null) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        v.note!.pick(lang),
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Speaker별 bubble accent 컬러.
  ///
  /// 2026-08-19: 5색 → 2색. 화자를 구분하는 건 **이름**이지 색이 아닌데,
  /// 한 대화에 머스터드·석간주·빨강·초록이 동시에 뜨면 화면이 시끄럽고
  /// 정작 "내 차례"가 안 보인다 (Jin: "색상이 너무 많달까").
  /// 나 = 녹청, 나머지 = 잉크.
  Color _speakerAccent(String speaker) {
    switch (speaker) {
      case 'user':
        return SoriColors.primary;
      default:
        return SoriColors.lightTextMuted;
    }
  }

  Widget _buildDialog(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioDialogTitle, SoriColors.success),
          const SizedBox(height: Spacing.sm),
          // 재생 속도 조절 — 전역 배수 컨트롤 (모든 화면과 공유·영속).
          const TtsSpeedControl(mode: TtsSpeedControlMode.row),
          const SizedBox(height: Spacing.lg),
          ...sc.dialog.map((line) {
            final isUser = line.speaker == 'user';
            final isNarrator = line.speaker == 'narrator';
            final bubbleAccent = _speakerAccent(line.speaker);

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    _speakerAvatar(line.speaker, size: 40),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Flexible(
                    child: isNarrator
                        ? SoriSpeakable(
                            text: line.ko,
                            voice: 'male',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.xs,
                              ),
                              child: Text(
                                line.ko,
                                style: SoriTextTheme.of(context).bodySmall
                                    .copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          )
                        : SoriCard(
                            variant: SoriCardVariant.compact,
                            accent: bubbleAccent,
                            tinted: isUser,
                            semanticLabel: '${t.ttsListen}: ${line.ko}',
                            // 스피커 아이콘뿐 아니라 **버블 전체**를 탭하면 재생.
                            // SoriCard.onTap 이 SoriPressable+버튼 시맨틱으로 감싼다.
                            onTap: () {
                              HapticFeedback.selectionClick();
                              SoriSpeech.speak(
                                line.ko,
                                voice: sc.voiceForSpeaker(line.speaker),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sc.speakerDisplayName(
                                    line.speaker,
                                    languageCode: lang,
                                    fallbackYou: t.listeningSpeakerYou,
                                    fallbackNarrator: t.listeningNarrator,
                                    playerSelfSuffix:
                                        t.scenarioPlayerSelfSuffix,
                                  ),
                                  style: SoriTextTheme.of(context).meta
                                      .copyWith(
                                        color: bubbleAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: Spacing.xs),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        line.ko,
                                        style: SoriTextTheme.of(
                                          context,
                                        ).h3.copyWith(color: ss.text),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    // 버블 전체가 탭 대상이므로 아이콘은 시각적
                                    // 힌트만 담당(별도 GestureDetector 불필요).
                                    Icon(
                                      Icons.volume_up_rounded,
                                      color: bubbleAccent.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                if (line.pick(lang).isNotEmpty) ...[
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    line.pick(lang),
                                    style: SoriTextTheme.of(
                                      context,
                                    ).bodySmall.copyWith(color: ss.textDim),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: Spacing.sm),
                    _speakerAvatar(line.speaker, size: 40),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrammar(AppL10n t, String lang) {
    const grammarAccent = SoriColors.primary;
    final resolved = _resolvedGrammar;
    final inline = _scenario!.grammarBlock;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioGrammarTitle, grammarAccent),
          const SizedBox(height: Spacing.lg),
          if (resolved.length == 1)
            _ScenarioGrammarExpandedCard(
              grammar: resolved.single,
              language: lang,
            )
          else if (resolved.length > 1)
            for (var index = 0; index < resolved.length; index++) ...[
              _ScenarioGrammarSummaryCard(
                grammar: resolved[index],
                language: lang,
              ),
              if (index + 1 < resolved.length)
                const SizedBox(height: Spacing.md),
            ]
          else if (inline != null)
            _ScenarioInlineGrammarCard(block: inline, language: lang),
        ],
      ),
    );
  }

  Widget _buildQuest(QuestSpec spec, AppL10n t) {
    Widget questWidget;
    final allowDontKnow =
        widget.mode == ScenarioPlayerMode.onboardingFirstScene &&
        widget.courseContext == null;

    switch (spec.type) {
      case QuestType.hoerverstehen:
        questWidget = HoerverstehenQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          transcriptTranslation: scenarioListeningTranscriptTranslation(
            _scenario!,
            spec,
            Localizations.localeOf(context).languageCode,
          ),
          audioEnabled: widget.previewFixture == null,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.uebersetzen:
        questWidget = UebersetzenQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          audioEnabled: widget.previewFixture == null,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.luecken:
        questWidget = LueckenQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          audioEnabled: widget.previewFixture == null,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.particlePop:
        questWidget = ParticlePopQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          audioEnabled: widget.previewFixture == null,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.batchimDrop:
        questWidget = BatchimDropQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.satzBauen:
        questWidget = SatzBauenQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowDontKnow: allowDontKnow,
        );
      case QuestType.diktat:
        questWidget = DiktatQuest(
          key: ValueKey('quest-$_currentQuestIndex'),
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
          onContinue: _next,
          isLast: _currentQuestIndex == _scenario!.quests.length - 1,
          allowWordBankFallback: allowDontKnow,
          allowDontKnow: allowDontKnow,
        );
      default:
        questWidget = Center(
          child: Builder(
            builder: (ctx) {
              final ss = SoriSurfaces.of(ctx);
              return Text(
                AppL10n.of(context).questTypeUnsupported(spec.type.name),
                style: SoriTextTheme.of(
                  ctx,
                ).bodySmall.copyWith(color: ss.textMuted),
                textAlign: TextAlign.center,
              );
            },
          ),
        );
    }

    // Quests bekommen **eine feste Höhe statt eines Scroll-Rahmens**.
    //
    // Nur so kann die Engine ihre eigene Aktion (`Überprüfen`, `Weiter`) unten
    // am Rand halten und nur den Aufgabenteil scrollen lassen. Vorher lag hier
    // ein `_StageScroll`; dessen unendliche Höhe hat `QuestLayout` in den
    // gestapelten Zweig gezwungen und in `SatzBauenQuest` das schon vorhandene
    // `pinBottom` stillgelegt (`c.maxHeight.isFinite` war false).
    //
    // Die `PageView` gibt jeder Seite eine feste Höhe, also ist die Höhe hier
    // begrenzt. Zu langer Inhalt scrollt innerhalb von `QuestLayout`.
    final pad = soriClampPadding(
      MediaQuery.sizeOf(context).width,
      base: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
    );
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final basePosterHeight = scenarioPosterHeight(
      viewportHeight: media.size.height,
      textScale: textScale,
    );
    // Poster gibt gemessenen Quest-Überlauf ab (siehe _questPosterConcession).
    final posterFloor = math.min(_questPosterMinHeight, basePosterHeight);
    final posterHeight = (basePosterHeight - _questPosterConcession).clamp(
      posterFloor,
      basePosterHeight,
    );
    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_backdropPoster case final poster?) ...[
            Semantics(
              image: true,
              label: _scenario!.title.pick(
                Localizations.localeOf(context).languageCode,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(SoriRadius.lg),
                ),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: posterHeight,
                  child: Image.asset(
                    poster,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          Text(
            _questTypeLabel(spec.type, t),
            style: SoriTextTheme.of(context).label.copyWith(
              color: SoriColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: _absorbQuestOverflowIntoPoster,
              child: questWidget,
            ),
          ),
        ],
      ),
    );
  }

  /// Misst den vertikalen Überlauf der Quest-Scrollbereiche und lässt das
  /// Poster genau diesen Betrag abgeben. Nur wachsend (nie zurück), sonst
  /// würden Poster-Höhe und Scroll-Viewport sich gegenseitig aufschaukeln.
  bool _absorbQuestOverflowIntoPoster(ScrollMetricsNotification notification) {
    // Nur die äußeren Scrollbereiche von QuestLayout (Inhalt + Aktionskarte);
    // tiefere/horizontale Scroller (Wortbank u. Ä.) sagen nichts über die Falz.
    if (notification.depth != 0) {
      return false;
    }
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical || !metrics.hasContentDimensions) {
      return false;
    }
    final overflow = metrics.maxScrollExtent;
    if (overflow <= 1 || !mounted) {
      return false;
    }
    final media = MediaQuery.of(context);
    final base = scenarioPosterHeight(
      viewportHeight: media.size.height,
      textScale: media.textScaler.scale(1),
    );
    final maxConcession = base - math.min(_questPosterMinHeight, base);
    final next = math.min(_questPosterConcession + overflow, maxConcession);
    if (next > _questPosterConcession + 0.5) {
      setState(() => _questPosterConcession = next);
    }
    return false;
  }

  String _questTypeLabel(QuestType type, AppL10n t) => switch (type) {
    QuestType.hoerverstehen => t.questTypeListening,
    QuestType.uebersetzen => t.questTypeTranslation,
    QuestType.luecken => t.questTypeCloze,
    QuestType.particlePop => t.questTypeParticle,
    QuestType.batchimDrop => t.questTypeBatchim,
    QuestType.satzBauen => t.questTypeSentence,
    QuestType.diktat => t.questTypeDictation,
    QuestType.schreiben => t.questTypeWriting,
  };

  Widget _buildResult(AppL10n t, String lang) {
    final scenario = _scenario!;
    final score = _resultScore(scenario);

    if (_resultPersisted) {
      return _buildSavedResult(t, scenario, lang);
    }

    return _StageScroll(
      fill: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            t.scenarioSavedEyebrow,
            style: SoriTextTheme.of(
              context,
            ).label.copyWith(color: SoriColors.primary),
          ),
          const SizedBox(height: Spacing.sm),
          Text(t.scenarioResultSaving, style: SoriTextTheme.of(context).h1),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            variant: SoriCardVariant.base,
            accent: SoriColors.primary,
            tinted: true,
            child: Row(
              children: [
                if (_resultSaving)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.sync_problem_outlined,
                    color: SoriColors.primary,
                  ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    t.scenarioResultSaving,
                    style: SoriTextTheme.of(context).body,
                  ),
                ),
              ],
            ),
          ),
          if (!_resultSaving) ...[
            const SizedBox(height: Spacing.md),
            SoriButton.outlined(
              label: t.scenarioResultSaveRetry,
              fullWidth: true,
              onTap: () => _complete(score.stars, score.earnedXp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedResult(AppL10n t, Scenario scenario, String lang) {
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final feedbackCompletion = _ensureFeedbackCompletion(scenario);
    String? phrase;
    for (final line in scenario.dialog) {
      if (line.speaker.trim().toLowerCase() == 'user' &&
          line.ko.trim().isNotEmpty) {
        phrase = line.ko;
        break;
      }
    }
    phrase ??= scenario.vocab.isNotEmpty ? scenario.vocab.first.korean : null;
    final grammar = scenario.grammarBlock?.title.pick(lang);

    return _StageScroll(
      fill: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          Text(
            t.scenarioSavedEyebrow,
            style: SoriTextTheme.of(
              context,
            ).label.copyWith(color: SoriColors.primary),
          ),
          const SizedBox(height: Spacing.sm),
          Text(t.scenarioSavedTitle, style: SoriTextTheme.of(context).h1),
          const SizedBox(height: Spacing.lg),
          if (_canDoResult case final result?) ...[
            CanDoResultCard(result: result),
            const SizedBox(height: Spacing.md),
            ScenarioStructureResultCard(result: result),
            const SizedBox(height: Spacing.md),
          ],
          if (feedbackScope != null && feedbackScope.featureGate.isEnabled) ...[
            ContentFeedbackCard(
              feedbackContext: feedbackCompletion.context,
              featureGate: feedbackScope.featureGate,
              submitFeedback: feedbackScope.submitFeedback,
              mascotKind: MascotPreference.selectedKind,
              completedMissionIds: feedbackScope.completedMissionIds,
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (phrase != null)
            SoriCard(
              variant: SoriCardVariant.base,
              accent: SoriColors.primary,
              tinted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.scenarioSavedPhrase,
                    style: SoriTextTheme.of(context).label,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(phrase, style: SoriTextTheme.of(context).h2),
                ],
              ),
            ),
          if (grammar != null && grammar.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            SoriCard(
              variant: SoriCardVariant.compact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.scenarioSavedStructure,
                    style: SoriTextTheme.of(context).label,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(grammar, style: SoriTextTheme.of(context).body),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          Text(
            t.scenarioSavedEmpty,
            style: SoriTextTheme.of(context).bodySmall,
          ),
          const SizedBox(height: Spacing.xl),
          SoriButton.filled(
            label: t.scenarioSavedReturnHanok,
            fullWidth: true,
            onTap: widget.previewFixture == null
                ? () => Navigator.of(context).pushReplacementNamed('/hanok')
                : widget.previewFixture!.onReturn,
          ),
          const SizedBox(height: Spacing.xs),
          TextButton(
            onPressed: widget.previewFixture == null
                ? () => Navigator.of(
                    context,
                  ).pushReplacementNamed('/scenario', arguments: scenario.id)
                : widget.previewFixture!.onRepeat,
            child: Text(t.scenarioSavedRepeat),
          ),
        ],
      ),
    );
  }

  FeedbackCompletion _ensureFeedbackCompletion(Scenario scenario) {
    final lang = Localizations.localeOf(context).languageCode;
    return _feedbackCompletion.complete(
      () => FeedbackCompletion.scenario(
        scenarioId: scenario.id,
        contentLabel: scenario.title.pick(lang),
        level: scenario.level.display,
        passed: _passedCount,
        firstTryPassed: _firstTryPassedCount,
        total: scenario.quests.length,
      ),
    );
  }

  // ─── Stage-Dispatcher ──────────────────────────────────────────────────────

  Widget _buildStage(int index, AppL10n t, String lang) {
    if (index < 0 || index >= _plan.length) return const SizedBox.shrink();
    switch (_plan[index]) {
      case ScenarioStage.intro:
        return _buildIntro(t, lang);
      case ScenarioStage.vocab:
        return _buildVocab(t, lang);
      case ScenarioStage.dialog:
        return _buildDialog(t, lang);
      case ScenarioStage.grammar:
        return _buildGrammar(t, lang);
      case ScenarioStage.rollenspiel:
        return _buildRollenspiel(t, lang);
      case ScenarioStage.quest:
        final quests = _scenario!.quests;
        final questIdx = index - _questStartStage;
        if (questIdx >= 0 && questIdx < quests.length) {
          return _buildQuest(quests[questIdx], t);
        }
        return const SizedBox.shrink();
      case ScenarioStage.result:
        return _buildResult(t, lang);
    }
  }

  // ─── Rollenspiel-Stage (inline produktive Antworten) ───────────────────────

  Widget _buildRollenspiel(AppL10n t, String lang) {
    // 헤더(_StageTitle·hint)와 스크롤은 _RollenspielStage가 소유한다 —
    // 완료 상태에선 "Jetzt bist du dran"이 더 이상 참이 아니라 헤더째 사라지고,
    // 축하 패널이 스테이지 전체를 중앙 정렬로 차지해야 하기 때문.
    return _RollenspielStage(
      scenario: _scenario!,
      lang: lang,
      onCorrect: _onCorrectAnswer,
      onTurnChanged: (index) {
        if (mounted && _roleplayTurnIndex != index) {
          setState(() => _roleplayTurnIndex = index);
        }
      },
      onDone: () {
        if (mounted) setState(() => _questReady = true);
      },
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(AppL10n t) {
    if (_isResultStage) return const SizedBox.shrink();
    // 퀘스트 단계에서는 퀘스트가 자기 CTA(Überprüfen 등)를 직접 그린다.
    // 완료 전까지 시나리오의 Weiter 는 **숨긴다** — 비활성으로 남겨두면 한
    // 화면에 CTA 가 두 개가 되고 아래쪽은 눌리지 않는 죽은 버튼으로 보인다
    // (Jin 2026-08-13 실기기, Rollenspiel).
    //
    // 예전 조건은 `_currentQuestOwnsPrimaryAction` 이었는데 그건
    // hoerverstehen + confirmSelection 한 조합만 참이라, Satz-bauen 등
    // 나머지 퀘스트는 전부 이중 CTA 였다.
    //
    // `_questReady == false` 는 "이 퀘스트는 완료돼야 넘어간다"는 뜻이고
    // (`_questReady = !nextNeedsCompletion`), 그런 퀘스트는 자기 완료 수단을
    // 반드시 갖는다. 완료되면 `_questReady` 가 true 가 되어 Weiter 가 다시
    // 나타나므로 사용자가 갇히지 않는다.
    if (_isQuestStage || (_isRoleplayStage && !_questReady)) {
      return const SizedBox.shrink();
    }

    final isIntro = _stage == 0;
    final enabled = _questReady;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        Spacing.xxl,
      ),
      child: SoriButton.filled(
        key: _nextBtnKey,
        label: isIntro ? t.scenarioStartBtn : t.scenarioNextBtn,
        accent: SoriColors.contentCta,
        fullWidth: true,
        onTap: enabled ? _next : null,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    if (_scenario == null) {
      final state = SoriStudyFrame(
        title: t.scenariosListTitle,
        leading: _buildCloseButton(),
        automaticallyImplyLeading: false,
        padding: EdgeInsets.zero,
        child: _loadFailure == null
            ? const AppLoading()
            : AppError(
                message: t.scenariosLoadFailedTitle,
                onRetry: _retryLoadScenario,
              ),
      );
      return _withExitScope(state);
    }

    final scaffold = Scaffold(
      appBar: SoriAppBar(
        title: _scenario!.title.pick(lang),
        eyebrow: _usesSegmentHeader
            ? t.scenarioQuestProgress(_segmentCurrent + 1, _segmentTotal)
            : null,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
        adaptTitleAtNormalScale: true,
        leading: _buildCloseButton(),
        automaticallyImplyLeading: false,
        actions: [
          SoriHomeAction(
            escape: SoriHomeEscape(confirmWhen: _stage > 0 && !_isResultStage),
            onLeave: () {
              _loadLifecycle.requestExit();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.xs,
            ),
            child: _usesSegmentHeader
                ? _QuestSegmentProgress(
                    current: _segmentCurrent,
                    total: _segmentTotal,
                    semanticsLabel: t.scenarioQuestProgress(
                      _segmentCurrent + 1,
                      _segmentTotal,
                    ),
                  )
                : SoriProgressBar(
                    value: _progress,
                    thickness: 6,
                    animated: true,
                  ),
          ),
        ),
      ),
      body: SoriScreenBackground(
        child: Stack(
          children: [
            if (_backdropPoster != null && !_isQuestStage && !_isRoleplayStage)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      _backdropPoster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  if (_missionStep case final step?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        Spacing.sm,
                        Spacing.lg,
                        Spacing.sm,
                      ),
                      child: MissionContextBar(
                        missionTitle:
                            _missionTitle ?? t.courseMissionTitleShort,
                        step: step,
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      key: _stageAreaKey,
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _totalStages,
                      itemBuilder: (_, index) => _buildStage(index, t, lang),
                    ),
                  ),
                  _buildBottomBar(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return _withExitScope(scaffold);
  }

  Widget _buildCloseButton() => IconButton(
    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
    icon: const Icon(Icons.close_rounded),
    onPressed: _requestExit,
  );

  Widget _withExitScope(Widget child) {
    final onExit = widget.onExit;
    return PopScope<void>(
      canPop: onExit == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _loadLifecycle.requestExit();
          return;
        }
        _requestExit();
      },
      child: child,
    );
  }

  void _requestExit() {
    if (!_loadLifecycle.requestExit()) {
      return;
    }
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
      return;
    }
    Navigator.pop(context);
  }

  void _popAfterLoadExit() {
    if (!_loadLifecycle.requestExit()) {
      return;
    }
    Navigator.pop(context);
  }
}

// ─── Hilfs-Widgets ─────────────────────────────────────────────────────────

class _StageScroll extends StatelessWidget {
  final Widget child;

  /// 콘텐츠가 viewport보다 짧을 때 세로를 채워 중앙 정렬할지.
  ///
  /// **기본 false** — 나머지 6개 호출부는 위젯 트리가 그대로라 회귀 0.
  /// `minHeight`만 주고 `maxHeight`는 건드리지 않으므로 오버플로가 구조적으로
  /// 불가능하다. 긴 콘텐츠는 지금처럼 위 정렬 + 스크롤로 degrade 된다.
  ///
  /// ⚠️ 이 분기 아래에는 `Expanded`/`Flexible`/`Spacer`를 넣으면 안 된다 —
  /// `maxHeight`가 infinity로 남아 flex child가 assert 한다.
  final bool fill;

  const _StageScroll({required this.child, this.fill = false});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = soriClampPadding(
      width,
      base: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xl,
      ),
    );
    if (!fill) {
      return SingleChildScrollView(padding: pad, child: child);
    }
    // PageView가 각 페이지에 tight 높이를 주므로 c.maxHeight는 유한하다.
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: pad,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0.0, c.maxHeight - pad.vertical),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScenarioIntroArt extends StatelessWidget {
  final String? posterAsset;
  final Alignment alignment;
  final String emoji;
  final String? sidekick;

  const _ScenarioIntroArt({
    required this.posterAsset,
    required this.alignment,
    required this.emoji,
    required this.sidekick,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final mascot =
        Mascot.forSpeaker(
          sidekick ?? '',
          size: 72,
          emotion: MascotEmotion.smile,
          animate: false,
        ) ??
        Mascot.tiger(emotion: MascotEmotion.smile, size: 72, animate: false);

    // Backdrop만 표시 (호랑이 없이 — 배경 자체가 시각적 focal point)
    if (posterAsset == null) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: SoriColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SoriRadius.lg),
          border: Border.all(color: SoriColors.primary.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: mascot,
      );
    }

    // 정적 포스터만 사용한다. 정렬은 scenario/course-unit seed로 결정되며
    // 작은 안전 범위 안에서만 움직여 인트로 텍스트 영역을 침범하지 않는다.
    final poster = Image.asset(
      posterAsset!,
      key: const ValueKey('scenario-intro-art-image'),
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => Container(
        color: SoriColors.primary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: mascot,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            poster,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, s.bg.withValues(alpha: 0.5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioGrammarExpandedCard extends StatelessWidget {
  const _ScenarioGrammarExpandedCard({
    required this.grammar,
    required this.language,
  });

  final Grammar grammar;
  final String language;

  @override
  Widget build(BuildContext context) => SoriCard(
    key: ValueKey<String>('scenario-grammar-expanded-${grammar.id}'),
    variant: SoriCardVariant.hero,
    accent: SoriColors.primary,
    tinted: true,
    width: double.infinity,
    child: _ScenarioGrammarDetails(
      grammar: grammar,
      language: language,
      expanded: true,
    ),
  );
}

class _ScenarioGrammarSummaryCard extends StatelessWidget {
  const _ScenarioGrammarSummaryCard({
    required this.grammar,
    required this.language,
  });

  final Grammar grammar;
  final String language;

  void _openDetails(BuildContext context) {
    unawaited(
      showSoriSheet<void>(
        context: context,
        builder: (_) =>
            _ScenarioGrammarDetailSheet(grammar: grammar, language: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = grammar.typeFor(language).trim();
    final semanticLabel = [
      grammar.pattern,
      if (type.isNotEmpty) type,
      AppL10n.of(context).hintTapForExplanation,
    ].join('. ');
    return SoriCard(
      key: ValueKey<String>('scenario-grammar-summary-${grammar.id}'),
      variant: SoriCardVariant.base,
      accent: SoriColors.primary,
      tinted: true,
      width: double.infinity,
      semanticLabel: semanticLabel,
      onTap: () => _openDetails(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grammar.pattern,
                  style: SoriTextTheme.of(
                    context,
                  ).h3.copyWith(color: SoriColors.primary),
                ),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    type,
                    style: SoriTextTheme.of(context).bodySmall.copyWith(
                      color: SoriSurfaces.of(context).textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          const Icon(Icons.chevron_right_rounded, color: SoriColors.primary),
        ],
      ),
    );
  }
}

class _ScenarioGrammarDetailSheet extends StatelessWidget {
  const _ScenarioGrammarDetailSheet({
    required this.grammar,
    required this.language,
  });

  final Grammar grammar;
  final String language;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey<String>('scenario-grammar-detail-${grammar.id}'),
    container: true,
    child: _ScenarioGrammarDetails(
      grammar: grammar,
      language: language,
      expanded: false,
    ),
  );
}

class _ScenarioGrammarDetails extends StatelessWidget {
  const _ScenarioGrammarDetails({
    required this.grammar,
    required this.language,
    required this.expanded,
  });

  final Grammar grammar;
  final String language;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final type = grammar.typeFor(language).trim();
    final explanation = grammar.explanationFor(language).trim();
    final koreanExample = grammar.exampleKorean.trim();
    final localizedExample = grammar.exampleFor(language).trim();
    final note = grammar.noteFor(language).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          grammar.pattern,
          style: tt.h2.copyWith(
            color: SoriColors.primary,
            fontSize: expanded ? 30 : null,
          ),
        ),
        if (type.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(type, style: tt.label.copyWith(color: surfaces.textMuted)),
        ],
        if (explanation.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text(explanation, style: tt.body.copyWith(height: 1.55)),
        ],
        if (koreanExample.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text(koreanExample, style: tt.h3.copyWith(color: SoriColors.primary)),
        ],
        if (localizedExample.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            localizedExample,
            style: tt.bodySmall.copyWith(
              color: surfaces.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Text(note, style: tt.bodySmall.copyWith(color: surfaces.textMuted)),
        ],
      ],
    );
  }
}

class _ScenarioInlineGrammarCard extends StatelessWidget {
  const _ScenarioInlineGrammarCard({
    required this.block,
    required this.language,
  });

  final GrammarBlock block;
  final String language;

  @override
  Widget build(BuildContext context) => SoriCard(
    key: const ValueKey<String>('scenario-grammar-inline'),
    variant: SoriCardVariant.base,
    accent: SoriColors.primary,
    tinted: true,
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.title.pick(language),
          style: SoriTextTheme.of(
            context,
          ).h2.copyWith(color: SoriColors.primary),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          block.explanation.pick(language),
          style: SoriTextTheme.of(context).body.copyWith(
            color: SoriSurfaces.of(context).textMuted,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class _StageTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _StageTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SoriTextTheme.of(
        context,
      ).label.copyWith(color: color, letterSpacing: 1.2),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? foregroundColor;

  const _MiniChip(this.label, this.color, {this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SoriRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: SoriTextTheme.of(context).caption.copyWith(
          color: foregroundColor ?? color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Eine Gesprächsrunde: vorhergehende NPC-Zeile (Stichwort) + die vom
/// Lernenden zu bauende Antwort.
class _Turn {
  final DialogLine? context;
  final DialogLine user;
  const _Turn(this.context, this.user);
}

/// Inline-Rollenspiel: der Lernende baut nacheinander **seine eigenen
/// Antworten** (speaker:'user') aus Wort-Kacheln — der gelesene Dialog wird
/// zum Gespräch, das man selbst spricht. Wiederverwendet [SatzBauenQuest].
class _RollenspielStage extends StatefulWidget {
  final Scenario scenario;
  final String lang;
  final VoidCallback onDone;

  /// 각 턴 정답 시 호출 — 지속 까치 코인 burst 트리거.
  final VoidCallback? onCorrect;
  final ValueChanged<int>? onTurnChanged;

  const _RollenspielStage({
    required this.scenario,
    required this.lang,
    required this.onDone,
    this.onCorrect,
    this.onTurnChanged,
  });

  @override
  State<_RollenspielStage> createState() => _RollenspielStageState();
}

class _RollenspielStageState extends State<_RollenspielStage> {
  late final List<_Turn> _turns;
  late final List<String> _pool; // Distraktor-Quelle (echte Dialog-Wörter)
  int _idx = 0;
  bool _done = false;
  QuestResult? _pendingResult;

  @override
  void initState() {
    super.initState();
    final dialog = widget.scenario.dialog;
    final turns = <_Turn>[];
    for (var i = 0; i < dialog.length; i++) {
      if (dialog[i].speaker == 'user') {
        final prev = i > 0 ? dialog[i - 1] : null;
        // Narrator/eigene Vorzeile nicht als Stichwort zeigen.
        final ctx = (prev != null && prev.speaker != 'user') ? prev : null;
        turns.add(_Turn(ctx, dialog[i]));
      }
    }
    _turns = turns;

    final pool = <String>{};
    for (final l in dialog) {
      for (final tk in SatzBauenQuest.tokenize(l.ko)) {
        if (tk.length >= 2) pool.add(tk);
      }
    }
    _pool = pool.toList()..sort();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTurnChanged?.call(_idx);
    });

    if (_turns.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _done = true);
          widget.onDone();
        }
      });
    }
  }

  Map<String, dynamic> _dataFor(DialogLine line) {
    final targetTokens = SatzBauenQuest.tokenize(line.ko).toSet();
    final candidates = _pool.where((w) => !targetTokens.contains(w)).toList();
    candidates.shuffle(math.Random(line.ko.hashCode));
    return {
      'targetKo': line.ko,
      'promptDe': line.de,
      'promptEn': line.en,
      'distractors': candidates.take(2).toList(),
      'audioKo': line.ko,
    };
  }

  void _onTurnComplete(QuestResult result) {
    setState(() => _pendingResult = result);
  }

  void _continueTurn() {
    final result = _pendingResult;
    if (result == null) return;
    if (result.passed) widget.onCorrect?.call();
    if (_idx + 1 >= _turns.length) {
      setState(() => _done = true);
      widget.onDone();
    } else {
      setState(() {
        _idx++;
        _pendingResult = null;
      });
      widget.onTurnChanged?.call(_idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    // ── 완료: 스테이지 전체를 차지하는 중앙 정렬 축하 패널 ──────────────────
    if (_done || _turns.isEmpty) {
      final promptKo = scenarioWritingPromptKo(widget.scenario);
      return _StageScroll(
        fill: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoriEntrance(child: const _RollenspielDoneCard()),
            if (promptKo != null) ...[
              const SizedBox(height: Spacing.lg),
              ScenarioWriteAfterRoleplayCard(
                promptKo: promptKo,
                evidence: ScenarioWritingEvidence.fromScenario(
                  scenario: widget.scenario,
                  language: widget.lang,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final turn = _turns[_idx];
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final posterHeight = scenarioPosterHeight(
      viewportHeight: media.size.height,
      textScale: textScale,
    );
    final poster = SceneAssetResolver.posterAsset(widget.scenario);
    final reservedForBuilder = textScale >= 2.0
        ? 280.0
        : textScale >= 1.6
        ? 320.0
        : 360.0;
    final topMaxHeight = math.max(
      posterHeight + 64,
      math.min(posterHeight + 80, media.size.height - reservedForBuilder),
    );
    final padding = soriClampPadding(
      media.size.width,
      base: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.sm,
      ),
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: topMaxHeight),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (poster != null) ...[
                    Semantics(
                      image: true,
                      label: widget.scenario.title.pick(widget.lang),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(SoriRadius.lg),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: posterHeight,
                          child: Image.asset(
                            poster,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.theater_comedy_outlined,
                        color: SoriColors.contentCta,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          t.scenarioRoleplayTitle,
                          style: SoriTextTheme.of(context).label.copyWith(
                            color: SoriColors.contentCta,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const TtsSpeedControl(),
                    ],
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: SatzBauenQuest(
              key: ValueKey('roleplay_${turn.user.ko}_$_idx'),
              data: _dataFor(turn.user),
              onComplete: _onTurnComplete,
              onContinue: _continueTurn,
              isLast: _idx + 1 >= _turns.length,
              showMascot: false,
              compact: true,
              showSpeedControl: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet roleplay-complete panel. Celebration clips belong on the final
/// scenario result only.
class _RollenspielDoneCard extends StatelessWidget {
  const _RollenspielDoneCard();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);

    return SoriCard(
      variant: SoriCardVariant.base,
      accent: SoriColors.success,
      tinted: true,
      width: double.infinity,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: '${t.scenarioRoleplayDoneTitle} ${t.scenarioRoleplayDoneBody}',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                key: ValueKey('roleplay_done_none'),
                Icons.check_circle_rounded,
                size: 56,
                color: SoriColors.success,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.scenarioRoleplayDoneTitle,
                textAlign: TextAlign.center,
                style: tt.h2.copyWith(color: SoriColors.success),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                t.scenarioRoleplayDoneBody,
                textAlign: TextAlign.center,
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
