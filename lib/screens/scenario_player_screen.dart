import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/course_practice_context.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../models/scenario.dart';
import '../models/scenario_can_do_result.dart';
import '../services/course_activity_reporter.dart';
import '../services/curriculum_catalog.dart';
import '../services/premium_service.dart';
import '../services/scenario_loader.dart';
import '../services/scene_asset_resolver.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/can_do_result_card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chip.dart';
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

/// Preserves the scenario result contract: persist once, then navigate.
Future<void> runScenarioResultAction({
  required Future<void> Function() persistResult,
  required Future<void> Function() navigate,
}) async {
  await persistResult();
  await navigate();
}

typedef ScenarioResultPersister =
    Future<ScenarioCanDoResult?> Function(
      Scenario scenario,
      int stars,
      int earnedXp,
    );

class ScenarioPlayerScreen extends StatefulWidget {
  final String scenarioId;
  final CoursePracticeContext? courseContext;
  final Future<Scenario?> Function(String scenarioId)? scenarioLoader;
  final ScenarioResultPersister? resultPersister;

  const ScenarioPlayerScreen({
    super.key,
    required this.scenarioId,
    this.courseContext,
    this.scenarioLoader,
    this.resultPersister,
  });

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
  int _firstTryPassedCount = 0;
  int _passedCount = 0;
  bool _questReady = true; // false → Quest läuft noch, Next-Button deaktiviert
  // 시나리오 대화 재생 속도 배수 (요청 단위에만 적용 — 전역 Storage.ttsRate 보존).
  double _dialogRate = 1.0;
  final PageController _pageCtrl = PageController();
  // Quest-Indizes, die der Nutzer NICHT bestanden hat. Wird in _persistResult
  // konsumiert, um deren Ziel-Vokabeln SRS-mäßig herabzustufen (error-aware
  // review).
  final Set<int> _failedQuestIndices = <int>{};
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  bool _resultSaving = false;
  bool _resultPersisted = false;
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
    _loadScenario();
    scheduleCoach();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScenario() async {
    final providedLoader = widget.scenarioLoader;
    final s = providedLoader != null
        ? await providedLoader(widget.scenarioId)
        : await _loadScenarioFromCatalog(widget.scenarioId);
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
    setState(() {
      _scenario = s;
      _missionStep = missionStep;
      _missionTitle = missionTitle;
      _plan = buildScenarioStagePlan(
        hasRollenspiel: s.dialog.any((l) => l.speaker == 'user'),
        hasGrammar: s.grammarBlock != null,
        questCount: s.quests.length,
      );
    });
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
        final lang = Localizations.localeOf(context).languageCode;
        _feedbackCompletion.complete(
          () => FeedbackCompletion.scenario(
            scenarioId: sc.id,
            contentLabel: sc.title.pick(lang),
            level: sc.level.display,
            passed: _passedCount,
            firstTryPassed: _firstTryPassedCount,
            total: sc.quests.length,
          ),
        );
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

    // 결과 스테이지 진입 + 별 1개 이상 → 축하 연출 (단청 별·다이아 burst)
    if (_isResultStage) {
      final s = _scenario;
      if (s != null &&
          _starsFor(_passedCount, _firstTryPassedCount, s.quests.length) >= 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SoriCelebration.burst(context);
        });
      }
    }
  }

  void _onQuestComplete(QuestResult result) {
    final scenario = _scenario;
    if (scenario != null &&
        _currentQuestIndex >= 0 &&
        _currentQuestIndex < scenario.quests.length) {
      final quest = scenario.quests[_currentQuestIndex];
      // Only audited pilot quest metadata writes concept evidence. Untagged
      // legacy quests still feed the scenario checkpoint at completion, which
      // avoids pretending that a single particle mistake affected every form
      // used elsewhere in the dialogue.
      if (quest.hasExplicitId && quest.conceptIds.isNotEmpty) {
        for (final conceptId in quest.conceptIds) {
          // ignore: discarded_futures
          CourseActivityReporter.recordContentAttempt(
            CurriculumContentKind.scenario,
            scenario.id,
            result.passed,
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
    if (result.passed) _celebrateCorrect();
    setState(() => _questReady = true);
  }

  /// 정답 순간 — 화면 중앙에 엽전·복주머니 코인 burst. post-frame + 화면 State의
  /// 안정적 context로 호출한다(이벤트 콜백에서 동기 호출 시 InheritedWidget 의존성
  /// 오염 → _dependents.isEmpty. _next()의 검증된 안전 패턴과 동일).
  void _celebrateCorrect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SoriCelebration.coins(context);
    });
  }

  // ─── Stern-Berechnung ──────────────────────────────────────────────────────

  int _starsFor(int passed, int firstTryPassed, int total) {
    if (total == 0) return 0;
    if (passed == total && firstTryPassed == total) return 3;
    if (passed == total) return 2;
    if (passed >= (total * 0.6).ceil()) return 1;
    return 0;
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
    );

    // Erster Abschluss → Badge
    if (!Storage.earnedBadges.contains('cafe_starter')) {
      await Storage.earnBadge('cafe_starter');
    }

    // Error-aware SRS: Ziel-Vokabeln gescheiterter Quests werden als
    // "nicht gewusst" gewertet (1-Tages-Intervall), alle anderen als
    // "gewusst". Wörter aus gescheiterten Quests, die nicht in der
    // Szenario-Vokabelliste stehen, werden ebenfalls heruntergestuft.
    final missedKeys = <String>{};
    for (final idx in _failedQuestIndices) {
      if (idx >= 0 && idx < s.quests.length) {
        missedKeys.addAll(s.quests[idx].targetVocabKeys());
      }
    }
    final scenarioKeys = s.vocab.map((v) => v.korean).toSet();
    for (final v in s.vocab) {
      await Storage.srsReview(v.korean, gotIt: !missedKeys.contains(v.korean));
    }
    for (final missed in missedKeys.difference(scenarioKeys)) {
      await Storage.srsReview(missed, gotIt: false);
    }

    if (courseUpdate == null) return null;
    final catalog = await CurriculumCatalog.load();
    return ScenarioCanDoResult.fromSnapshot(
      snapshot: courseUpdate.snapshot,
      scenarioId: s.id,
      courseUnits: catalog.courseUnits,
    );
  }

  Future<void> _complete(int stars, int earnedXp) async {
    if (_resultSaving) return;
    if (_resultPersisted) {
      Navigator.pop(context);
      return;
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _resultSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).courseCheckpointSaveError)),
      );
    }
  }

  Future<void> _openNext(int stars, int earnedXp, String nextId) async {
    if (_resultSaving) return;
    if (_resultPersisted) {
      Navigator.of(
        context,
      ).pushReplacementNamed('/scenario', arguments: nextId);
      return;
    }
    await runScenarioResultAction(
      persistResult: () async {
        await _persistResult(stars, earnedXp);
      },
      navigate: () async {
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/scenario', arguments: nextId);
        }
      },
    );
  }

  /// Nächstes empfohlenes Szenario im aktuellen Level.
  /// Priorität: 1) nicht abgeschlossen, 2) abgeschlossen aber < 3 Sterne.
  /// Aktuelles Szenario wird übersprungen.
  Scenario? _nextRecommended() {
    final cur = _scenario;
    if (cur == null) return null;
    final completed = Storage.completedScenarios.toSet();
    final stars = Storage.scenarioStars;
    final sameLevel = ScenarioLoader.byLevel(
      cur.level,
    ).where((s) => s.id != cur.id).toList();
    for (final s in sameLevel) {
      if (!completed.contains(s.id)) return s;
    }
    for (final s in sameLevel) {
      if ((stars[s.id] ?? 0) < 3) return s;
    }
    return null;
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
          // 재생 속도 조절 — 좁은 화면 대비 Wrap(오버플로 방지). 요청 단위 배수만 적용.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: Spacing.xs,
            children: [
              Icon(Icons.speed_rounded, size: 16, color: ss.textMuted),
              const SizedBox(width: Spacing.xs),
              Text(
                t.listeningSpeedLabel,
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: Spacing.md),
              ...[0.75, 1.0, 1.25].map((r) {
                final selected = (_dialogRate - r).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(right: Spacing.xs),
                  child: SoriChip(
                    label: '${r}x',
                    accent: SoriColors.info,
                    selected: selected,
                    variant: SoriChipVariant.soft,
                    onTap: () => setState(() => _dialogRate = r),
                    fontSize: 12,
                  ),
                );
              }),
            ],
          ),
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
                                rateMultiplier: _dialogRate,
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

    switch (spec.type) {
      case QuestType.hoerverstehen:
        questWidget = HoerverstehenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.uebersetzen:
        questWidget = UebersetzenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.luecken:
        questWidget = LueckenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.particlePop:
        questWidget = ParticlePopQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.batchimDrop:
        questWidget = BatchimDropQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.satzBauen:
        questWidget = SatzBauenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.diktat:
        questWidget = DiktatQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
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

    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(
            '${t.scenarioQuestsTitle} ${_currentQuestIndex + 1}/${_scenario!.quests.length}',
            SoriColors.primary,
          ),
          const SizedBox(height: Spacing.xl),
          questWidget,
        ],
      ),
    );
  }

  Widget _buildResult(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final stars = _starsFor(
      _passedCount,
      _firstTryPassedCount,
      sc.quests.length,
    );
    final xpFull = sc.xpReward;
    final earnedXp = stars == 3
        ? xpFull
        : stars == 2
        ? (xpFull * 2 ~/ 3)
        : stars == 1
        ? (xpFull ~/ 3)
        : 0;

    // Mascot emotion based on stars
    final mascotEmotion = stars == 3
        ? MascotEmotion.celebrate
        : stars >= 1
        ? MascotEmotion.smile
        : MascotEmotion.worry;
    // Mascot kind: 'kkachi'/'magpie' → magpie (좋은 소식 분위기), else tiger 기본
    final mascotKind = (sc.sidekick == 'kkachi' || sc.sidekick == 'magpie')
        ? MascotKind.magpie
        : MascotKind.tiger;

    // Once persistence has completed, replace the game-result presentation
    // with the calm return surface from mockup 02D. The saved vocabulary,
    // grammar and course checkpoint are all derived from the real scenario;
    // visiting this screen does not create additional learning evidence.
    if (_resultPersisted) {
      return _buildSavedResult(t, sc, lang);
    }

    return _StageScroll(
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),

          // Celebrating mascot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: SoriMotion.celebrate,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Mascot(
              kind: mascotKind,
              emotion: mascotEmotion,
              size: 120,
              animate: false,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Sterne (SoriStars + AnimatedScale)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: filled ? 1.0 : 0.8),
                  duration: Duration(milliseconds: 400 + i * 150),
                  curve: SoriMotion.celebrate,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: filled ? SoriColors.warning : ss.textDim,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.scenarioStarsLabel(stars),
            style: SoriTextTheme.of(context).bodySmall,
          ),
          const SizedBox(height: Spacing.lg),

          // XP Badge (SoriBadge.xp)
          SoriCard(
            variant: SoriCardVariant.base,
            accent: SoriColors.primary,
            tinted: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SoriBadge.xp(earnedXp, size: 28),
                const SizedBox(width: Spacing.sm),
                Text(
                  t.scenarioXpEarned(earnedXp),
                  style: SoriTextTheme.of(context).h3.copyWith(
                    color: SoriColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Recap — was du in diesem Szenario gelernt hast
          SoriCard(
            variant: SoriCardVariant.base,
            accent: SoriColors.primary,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.scenarioRecapTitle,
                  style: SoriTextTheme.of(context).label.copyWith(
                    color: SoriColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _RecapLine(
                  icon: Icons.menu_book_rounded,
                  text: t.scenarioRecapWordsLine(sc.vocab.length),
                ),
                const SizedBox(height: Spacing.xs),
                _RecapLine(
                  icon: Icons.check_circle_outline_rounded,
                  text: t.scenarioRecapAccuracyLine(
                    _firstTryPassedCount,
                    sc.quests.length,
                  ),
                ),
                if (sc.grammarBlock != null) ...[
                  const SizedBox(height: Spacing.xs),
                  _RecapLine(
                    icon: Icons.translate_rounded,
                    text: t.scenarioRecapGrammarLine(
                      sc.grammarBlock!.title.pick(lang),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Cultural Note
          if (sc.culturalNote != null) ...[
            SoriCard(
              variant: SoriCardVariant.base,
              accent: SoriColors.warning,
              tinted: true,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: SoriColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        t.scenarioCulturalNote,
                        style: SoriTextTheme.of(context).label.copyWith(
                          color: SoriColors.warning,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    sc.culturalNote!.title.pick(lang),
                    style: SoriTextTheme.of(context).h3,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    sc.culturalNote!.body.pick(lang),
                    style: SoriTextTheme.of(
                      context,
                    ).bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],

          if (_canDoResult case final result?) ...[
            CanDoResultCard(result: result),
            const SizedBox(height: Spacing.xl),
          ],

          if (_feedbackCompletion.current != null &&
              feedbackScope != null &&
              feedbackScope.featureGate.isEnabled) ...[
            ContentFeedbackCard(
              feedbackContext: _feedbackCompletion.current!.context,
              featureGate: feedbackScope.featureGate,
              submitFeedback: feedbackScope.submitFeedback,
              mascotKind: mascotKind,
              completedMissionIds: feedbackScope.completedMissionIds,
            ),
            const SizedBox(height: Spacing.xl),
          ],

          // Next recommended — nächstes Szenario im gleichen Level
          if (!_resultPersisted)
            Builder(
              builder: (_) {
                final next = _nextRecommended();
                if (next == null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.lg),
                    child: Text(
                      t.scenarioNextRecommendedAllDone(sc.level.display),
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).bodySmall,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: SoriCard(
                    variant: SoriCardVariant.base,
                    accent: SoriColors.accent,
                    tinted: true,
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.scenarioNextRecommendedTitle,
                          style: SoriTextTheme.of(context).label.copyWith(
                            color: SoriColors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child:
                                  Mascot.forSpeaker(
                                    next.sidekick ?? '',
                                    size: 36,
                                    emotion: MascotEmotion.smile,
                                  ) ??
                                  Mascot.tiger(
                                    emotion: MascotEmotion.smile,
                                    size: 36,
                                  ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                next.title.pick(lang),
                                style: SoriTextTheme.of(
                                  context,
                                ).body.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            SoriButton.outlined(
                              label: t.scenarioNextRecommendedCta,
                              onTap: () => _openNext(stars, earnedXp, next.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Complete-Button
          SoriButton.filled(
            label: _resultPersisted
                ? t.scenarioResultReturnBtn
                : t.scenarioCompleteBtn,
            accent: SoriColors.success,
            fullWidth: true,
            onTap: _resultSaving ? null : () => _complete(stars, earnedXp),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedResult(AppL10n t, Scenario scenario, String lang) {
    final phrase = scenario.dialog.isNotEmpty
        ? scenario.dialog.first.ko
        : scenario.vocab.isNotEmpty
        ? scenario.vocab.first.korean
        : null;
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
            )
          else
            SoriCard(
              variant: SoriCardVariant.base,
              child: Text(
                t.scenarioSavedEmpty,
                style: SoriTextTheme.of(context).bodySmall,
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
          const SizedBox(height: Spacing.xl),
          SoriButton.filled(
            label: t.scenarioSavedReturnHanok,
            fullWidth: true,
            onTap: () => Navigator.of(context).pushReplacementNamed('/hanok'),
          ),
          const SizedBox(height: Spacing.xs),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushReplacementNamed('/scenario', arguments: scenario.id),
            child: Text(t.scenarioSavedRepeat),
          ),
        ],
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
      onCorrect: _celebrateCorrect,
      onDone: () {
        if (mounted) setState(() => _questReady = true);
      },
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(AppL10n t) {
    if (_isResultStage) return const SizedBox.shrink();

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _scenario!.title.pick(lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SoriProgressBar(
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
            if (_backdropPoster != null)
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

class _RecapLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecapLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ss = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SoriColors.primary),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: SoriTextTheme.of(context).bodySmall.copyWith(color: ss.text),
          ),
        ),
      ],
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

  const _RollenspielStage({
    required this.scenario,
    required this.lang,
    required this.onDone,
    this.onCorrect,
  });

  @override
  State<_RollenspielStage> createState() => _RollenspielStageState();
}

class _RollenspielStageState extends State<_RollenspielStage> {
  late final List<_Turn> _turns;
  late final List<String> _pool; // Distraktor-Quelle (echte Dialog-Wörter)
  int _idx = 0;
  bool _done = false;

  /// 온보딩에서 사용자가 고른 캐릭터. 축하 클립을 여기에 맞춘다.
  late final MascotKind? _kind;
  late final String? _clip;
  bool _burstFired = false;

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

    _kind = MascotPreference.selectedKind;
    // celebrate는 두 캐릭터 모두 클립이 있어 사실상 non-null이지만,
    // game_reward.dart 패턴대로 null 분기는 유지한다.
    _clip = _kind == null
        ? null
        : CharacterClips.feedbackFor(_kind, MascotEmotion.celebrate);

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
    if (result.passed) widget.onCorrect?.call();
    if (_idx + 1 >= _turns.length) {
      setState(() => _done = true);
      widget.onDone();
      // 직접 해낸 경우에만 축하 — 턴이 없는 시나리오는 조용히 넘어간다.
      if (!_burstFired) {
        _burstFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // reduce-motion·Overlay 부재 시 no-op (celebration.dart:20-22).
          if (mounted) SoriCelebration.burst(context);
        });
      }
    } else {
      setState(() => _idx++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    // ── 완료: 스테이지 전체를 차지하는 중앙 정렬 축하 패널 ──────────────────
    if (_done || _turns.isEmpty) {
      return _StageScroll(
        fill: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoriEntrance(
              child: _RollenspielDoneCard(kind: _kind, clip: _clip),
            ),
          ],
        ),
      );
    }

    final turn = _turns[_idx];
    final ctx = turn.context;

    // ── 진행 중: 기존 위 정렬 유지 (회귀 0) ────────────────────────────────
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageTitle(t.scenarioRoleplayTitle, SoriColors.tiger),
          const SizedBox(height: Spacing.xs),
          Text(
            t.scenarioRoleplayHint,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            '${t.scenarioRoleplayTurn} ${_idx + 1}/${_turns.length}',
            style: SoriTextTheme.of(
              context,
            ).caption.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: Spacing.sm),
          if (ctx != null) ...[
            SoriCard(
              variant: SoriCardVariant.compact,
              accent: SoriColors.success,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctx.ko,
                    style: TextStyle(
                      color: s.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (ctx.pick(widget.lang).isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      ctx.pick(widget.lang),
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: s.textDim),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          SatzBauenQuest(
            key: ValueKey('roleplay_${turn.user.ko}_$_idx'),
            data: _dataFor(turn.user),
            onComplete: _onTurnComplete,
          ),
        ],
      ),
    );
  }
}

/// Rollenspiel 완료 패널 — 캐릭터 클립 히어로 + 축하 문구.
///
/// 온보딩에서 고른 캐릭터의 축하 영상을 재생한다. 명시적 none이면 중립
/// 완료 아이콘만 남긴다.
/// 이름 있는 위젯이라 위젯 테스트에서 턴을 주행하지 않고 바로 pump 할 수 있다.
class _RollenspielDoneCard extends StatelessWidget {
  final MascotKind? kind;
  final String? clip;

  const _RollenspielDoneCard({required this.kind, this.clip});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);

    // ⚠️ 단일 진실원천 — well 배경과 blendColor가 **같은 상수**여야 한다.
    // 영상은 알파가 없고 배경이 정확히 (255,255,255)이라, multiply
    // (out = src·dst/255, src=255 → out = dst) 로 배경이 well 색에 정확히
    // 수렴해 사라진다. 이 클립을 well 밖(한지 텍스처·backdrop 위)으로 옮기면
    // 불투명한 평면 패치가 그대로 보인다.
    final wellColor = s.surface;

    // 960² 소스의 56~66%가 흰 여백이라 기존 정적 Mascot(48)보다 크게 잡아야
    // 캐릭터가 히어로로 읽힌다. 폭·높이 양쪽 클램프 → 어떤 뷰포트에서도 안전.
    final screen = MediaQuery.sizeOf(context);
    final cardInner =
        math.min(screen.width, SoriBreakpoints.content) -
        (Spacing.lg * 2) - // _StageScroll 좌우
        (Spacing.lg * 2) - // 카드 좌우
        2; // hairline
    final clipSize = math
        .min(cardInner - (Spacing.sm * 2) - 2, screen.height * 0.26)
        .clamp(132.0, 200.0);

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
              // ── 한지 창(well) — 캐릭터 뒤 **평면 substrate** 보장 전용 ──
              // 2026-08-06: 테두리(Border.all) 제거. never-cage 규칙은
              // "캐릭터 mp4는 ClipOval/박스/**프레임** 금지"라, clip 이 없어도
              // 눈에 보이는 테두리 링은 액자다. 색 채움만 남기는 건 규칙이
              // 허용하는 범위 — multiply 가 요구하는 평면 배경색을 주는 게
              // 이 Container 의 유일한 목적이기 때문이다.
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: wellColor,
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                ),
                // ClipRRect 없음 — 영상 테두리 링이 100% 흰색이라 모서리가
                // wellColor로 수렴한다.
                child: kind == null
                    ? Icon(
                        key: const ValueKey('roleplay_done_none'),
                        Icons.task_alt_rounded,
                        size: clipSize * 0.68,
                        color: SoriColors.success,
                      )
                    : clip == null
                    ? Mascot(
                        kind: kind!,
                        emotion: MascotEmotion.celebrate,
                        size: clipSize * 0.85,
                        animate: true,
                      )
                    : CharacterClipPlayer(
                        key: ValueKey('roleplay_done_${kind!.name}'),
                        asset: clip!,
                        size: clipSize,
                        // ⚠️ loop 금지 — PageView가 "Weiter" 후에도 페이지를
                        // 살려둬서 960² 디코더가 세션 내내 돌게 된다.
                        loop: false,
                        blendColor: wellColor,
                        fallbackKind: kind!,
                        fallbackEmotion: MascotEmotion.celebrate,
                        // onCompleted 미전달 → Timer 자체가 생성되지 않는다.
                        // "Weiter"는 이미 onDone()에서 열렸다.
                      ),
              ),
              const SizedBox(height: Spacing.lg),
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
