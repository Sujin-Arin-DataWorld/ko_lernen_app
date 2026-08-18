import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/course_practice_context.dart';
import '../models/course_mastery.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../models/hanok_competence.dart';
import '../models/personal_hanok.dart';
import '../models/scenario.dart';
import '../models/scenario_can_do_result.dart';
import '../services/course_activity_reporter.dart';
import '../services/curriculum_catalog.dart';
import '../services/hanok_stage_service.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/scenario_loader.dart';
import '../services/scene_asset_resolver.dart';
import '../services/scenario_writing_check_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/can_do_result_card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/hanok_header.dart' show SoriPosterLoop;
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/motion.dart' show SoriEntrance;
import '../widgets/sori/tiger_video.dart' show TigerStageVideo;
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/scenario_write_after_roleplay_card.dart';
import '../widgets/sori/spotlight_coach.dart';
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
    await Storage.srsReview(missed, gotIt: false);
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
  final CoursePracticeContext? courseContext;
  final Future<Scenario?> Function(String scenarioId)? scenarioLoader;
  final ScenarioResultPersister? resultPersister;
  final ScenarioCompletionCallback? onCompleted;
  final VoidCallback? onExit;
  final ScenarioPlayerMode mode;
  final ScenarioPlayerPreviewFixture? previewFixture;

  const ScenarioPlayerScreen({
    super.key,
    required this.scenarioId,
    this.courseContext,
    this.scenarioLoader,
    this.resultPersister,
    this.onCompleted,
    this.onExit,
    this.mode = ScenarioPlayerMode.standard,
  }) : previewFixture = null;

  ScenarioPlayerScreen.preview({
    super.key,
    required ScenarioPlayerPreviewFixture fixture,
    this.onExit,
  }) : scenarioId = fixture.scenario.id,
       courseContext = null,
       scenarioLoader = null,
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
  List<ScenarioStage> _plan = const [];
  int _stage = 0;
  QuestAbandonTracker? _abandonTracker;
  int _firstTryPassedCount = 0;
  int _passedCount = 0;
  bool _questReady = true; // false → Quest läuft noch, Next-Button deaktiviert
  int _roleplayTurnIndex = 0;
  late final PageController _pageCtrl;
  // Quest-Indizes, die der Nutzer NICHT bestanden hat. Wird in _persistResult
  // konsumiert, um deren Ziel-Vokabeln SRS-mäßig herabzustufen (error-aware
  // review).
  final Set<int> _failedQuestIndices = <int>{};
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  final FirstCorrectAttemptGate _firstCorrectGate = FirstCorrectAttemptGate();
  ScenarioFirstSuccess? _firstSuccess;
  bool _completionDelivered = false;
  bool _resultSaving = false;
  bool _resultPersisted = false;
  bool _exitRequested = false;
  ScenarioCanDoResult? _canDoResult;

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
      return;
    }
    _pageCtrl = PageController();
    _loadScenario();
    scheduleCoach();
  }

  @override
  void dispose() {
    _abandonTracker?.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScenario() async {
    final providedLoader = widget.scenarioLoader;
    final s = providedLoader != null
        ? await providedLoader(widget.scenarioId)
        : await _loadScenarioFromCatalog(widget.scenarioId);
    if (s != null) {
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
    }
    if (s == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final courseContext = widget.courseContext;
    final catalog = courseContext?.isFor(CurriculumContentKind.scenario) == true
        ? await CurriculumCatalog.load()
        : null;
    if (!mounted) return;
    // Premium-Gate (M4): A1-Szenarien frei, A2/B1/B2 erfordern ein Abo.
    // Deckt alle Einstiege ab (Home-CTA, Skill-Path, Szenarien-Liste).
    if (s.level != LearnerLevel.a1 && !PremiumService.isPremium) {
      if (!mounted) return;
      final ok = await PremiumService.gate(context);
      if (!ok) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    if (!mounted) return;
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
      hasGrammar: s.grammarBlock != null,
      questCount: s.quests.length,
    );
    final initialStage = scenarioInitialStageIndex(
      plan,
      startAtFirstTask: widget.mode == ScenarioPlayerMode.onboardingFirstScene,
    );
    setState(() {
      _scenario = s;
      _missionStep = missionStep;
      _missionTitle = missionTitle;
      _plan = plan;
      _stage = initialStage;
      _questReady = initialStage == 0;
    });
    if (initialStage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(initialStage);
        }
      });
    }
  }

  Future<Scenario?> _loadScenarioFromCatalog(String scenarioId) async {
    await ScenarioLoader.load();
    return ScenarioLoader.byId(scenarioId);
  }

  // ─── Backdrop-Map ──────────────────────────────────────────────────────────

  /// Resolved scene poster / ambient loop for the current scenario. Prefers a
  /// dedicated per-scenario asset (`scenes/{id}.png` · `loops/scene_{id}.mp4`)
  /// and falls back to the category backdrop via SceneAssetResolver.
  String? get _backdropPoster =>
      _scenario == null ? null : SceneAssetResolver.posterAsset(_scenario!);
  String? get _backdropLoop =>
      _scenario == null ? null : SceneAssetResolver.loopAsset(_scenario!);

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
      courseContext: widget.courseContext,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).courseCheckpointSaveError)),
      );
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
            loopAsset: _backdropLoop,
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
          SoriCard(
            variant: SoriCardVariant.base,
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              s.intro.pick(lang),
              style: TextStyle(
                color: ss.textMuted,
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
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
          _StageTitle(t.scenarioVocabTitle, vocabAccent),
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
                            style: const TextStyle(
                              color: vocabAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            TtsService.speak(v.korean);
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
                    if (v.aliases.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: v.aliases
                            .map((a) => _MiniChip(a, vocabAccent))
                            .toList(),
                      ),
                    ],
                    if (v.variants.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: v.variants
                            .map((vt) => _MiniChip(vt, ss.textDim))
                            .toList(),
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

  /// Speaker별 bubble accent 컬러
  Color _speakerAccent(String speaker) {
    switch (speaker) {
      case 'user':
        return SoriColors.primary;
      case 'narrator':
        return SoriColors.warning;
      case 'partner':
        return SoriColors.hangul;
      case 'officer':
        return SoriColors.danger;
      default:
        return SoriColors.success; // minsu, jieun, etc.
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
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.xs,
                            ),
                            child: Text(
                              line.ko,
                              style: SoriTextTheme.of(
                                context,
                              ).bodySmall.copyWith(fontStyle: FontStyle.italic),
                            ),
                          )
                        : SoriCard(
                            variant: SoriCardVariant.compact,
                            accent: bubbleAccent,
                            tinted: isUser,
                            // 스피커 아이콘뿐 아니라 **버블 전체**를 탭하면 재생.
                            // SoriCard.onTap 이 SoriPressable+버튼 시맨틱으로 감싼다.
                            onTap: () {
                              HapticFeedback.selectionClick();
                              TtsService.speak(
                                line.ko,
                                voice: line.speaker == 'user'
                                    ? 'female'
                                    : 'male',
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        line.ko,
                                        style: TextStyle(
                                          color: ss.text,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
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
    final block = _scenario!.grammarBlock!;
    final ss = SoriSurfaces.of(context);
    const grammarAccent = SoriColors.warning;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioGrammarTitle, grammarAccent),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            variant: SoriCardVariant.base,
            accent: grammarAccent,
            tinted: true,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title.pick(lang),
                  style: SoriTextTheme.of(
                    context,
                  ).h2.copyWith(color: grammarAccent),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  block.explanation.pick(lang),
                  style: SoriTextTheme.of(
                    context,
                  ).body.copyWith(color: ss.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
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
                'Quest type "${spec.type.name}" noch nicht implementiert.',
                style: TextStyle(color: ss.textMuted),
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
    final posterHeight = scenarioPosterHeight(
      viewportHeight: media.size.height,
      textScale: textScale,
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
                child: SizedBox(
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
          Expanded(child: questWidget),
        ],
      ),
    );
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
                    color: SoriColors.warning,
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
      const scaffold = Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
      return _withExitScope(scaffold);
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _requestExit,
        ),
        centerTitle: _usesSegmentHeader,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _scenario!.title.pick(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (_usesSegmentHeader)
              Text(
                t.scenarioQuestProgress(_segmentCurrent + 1, _segmentTotal),
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).caption.copyWith(
                  color: SoriColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_usesSegmentHeader ? 18 : 6),
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

  Widget _withExitScope(Widget child) {
    final onExit = widget.onExit;
    if (onExit == null) {
      return child;
    }
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _requestExit();
        }
      },
      child: child,
    );
  }

  void _requestExit() {
    final onExit = widget.onExit;
    if (onExit == null) {
      Navigator.pop(context);
      return;
    }
    if (_exitRequested) {
      return;
    }
    _exitRequested = true;
    onExit();
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
  final String? loopAsset;
  final String emoji;
  final String? sidekick;

  const _ScenarioIntroArt({
    required this.posterAsset,
    required this.loopAsset,
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

    // 정지 백드롭 포스터 — 영상 게이트 통과 시 위로 앰비언트 루프가 페이드인.
    final poster = Image.asset(
      posterAsset!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: SoriColors.primary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: mascot,
      ),
    );
    // 챕터 헤더 앰비언트 루프 (배치 계획 §2-6): scenes/{key}.png 포스터 위에
    // loops/scene_{key}.mp4 무음 루프. 영상 미존재·실패 시 포스터 유지.
    final live =
        TigerStageVideo.videoReady && !SoriMotion.reduceMotion(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (live && loopAsset != null)
              SoriPosterLoop(videoAsset: loopAsset!, poster: poster)
            else
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

  const _MiniChip(this.label, this.color);

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
        style: SoriTextTheme.of(
          context,
        ).caption.copyWith(color: color, fontWeight: FontWeight.w600),
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
      return _StageScroll(
        fill: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoriEntrance(child: const _RollenspielDoneCard()),
            const SizedBox(height: Spacing.lg),
            ScenarioWriteAfterRoleplayCard(
              evidence: ScenarioWritingEvidence.fromScenario(
                scenario: widget.scenario,
                language: widget.lang,
              ),
            ),
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
                        color: SoriColors.tiger,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          t.scenarioRoleplayTitle,
                          style: SoriTextTheme.of(context).label.copyWith(
                            color: SoriColors.tiger,
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
                Icons.task_alt_rounded,
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
