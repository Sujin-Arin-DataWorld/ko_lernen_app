import '../widgets/sori/game_result_recovery.dart';
import '../widgets/sori/study_evidence_recovery.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_practice_context.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../services/analytics_service.dart';
import '../services/course_activity_reporter.dart';
import '../services/curriculum_catalog.dart';
import '../services/satz_loader.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import 'quest_engines/quest_models.dart';
import 'quest_engines/satz_bauen_quest.dart';

/// **Satz-Bauen Arcade (문장 짓기)** — Wort-Kacheln zu einem Satz ordnen.
///
/// Produktiver Abruf + SOV-Wortstellung = stärkste Lernwirkung (Forschung).
/// Nutzt die bestehende [SatzBauenQuest]-Engine, befüllt aus geprüften
/// Beispielsätzen (assets/data/satz_sentences.json). Selbst-Wettbewerb.
class SatzArcadeScreen extends StatefulWidget {
  /// Optional test fixture; production loads the curated sentence set.
  final List<SatzSentence>? items;

  /// A mission passes its ID so sentence practice cannot accidentally draw a
  /// future-level library item and turn it into course evidence.
  final String? courseUnitId;
  final CoursePracticeContext? courseContext;

  const SatzArcadeScreen({
    super.key,
    this.items,
    this.courseUnitId,
    this.courseContext,
  });

  @override
  State<SatzArcadeScreen> createState() => _SatzArcadeScreenState();
}

class _SatzArcadeScreenState extends State<SatzArcadeScreen>
    with
        GameResultRecovery<SatzArcadeScreen>,
        StudyEvidenceRecovery<SatzArcadeScreen> {
  static const _roundSize = 8;
  static const _levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
  static const _allLevels = '';

  List<SatzSentence> _all = const [];
  Set<String>? _linkedCourseSentenceIds;
  bool _loading = true;
  String? _level;
  int _roundId = 0;

  List<SatzSentence> _round = const [];
  int _idx = 0;
  int _passed = 0;
  bool _hasSubmittedAnswer = false;
  bool _answerPending = false;
  GameOutcome? _outcome;
  CoursePracticeContext? _missionContext;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = widget.items ?? await SatzLoader.load();
    final all = List<SatzSentence>.of(loaded);
    final courseUnitId =
        widget.courseContext?.courseUnitId ?? widget.courseUnitId;
    final catalog = courseUnitId == null
        ? null
        : await CurriculumCatalog.load();
    if (!gameResultAcceptsInput || !studyEvidenceIsCurrent) {
      return;
    }
    final user = Storage.browseLevelCode ?? Storage.placementLevelCode;
    final start = (user != null && all.any((c) => c.level == user))
        ? user
        : null;
    final courseIds = catalog == null
        ? const <String>{}
        : catalog
              .linksForCourseUnit(courseUnitId!)
              .where((link) => link.contentKind == CurriculumContentKind.satz)
              .map((link) => link.contentId)
              .toSet();
    final scoped = catalog == null
        ? all
        : all.where((item) => courseIds.contains(item.id)).toList();
    final requestedContext = widget.courseContext;
    final missionContext =
        catalog == null ||
            requestedContext == null ||
            !requestedContext.isFor(CurriculumContentKind.satz) ||
            !catalog
                .linksForCourseUnit(courseUnitId!)
                .any(
                  (link) =>
                      link.id == requestedContext.contentLinkId &&
                      link.contentKind == CurriculumContentKind.satz &&
                      link.contentId == requestedContext.initialContentId,
                )
        ? null
        : requestedContext;
    setState(() {
      _all = scoped;
      _linkedCourseSentenceIds = catalog?.contentLinks
          .where((link) => link.contentKind == CurriculumContentKind.satz)
          .map((link) => link.contentId)
          .toSet();
      _level = catalog == null && widget.items == null ? start : null;
      _missionContext = missionContext;
      _loading = false;
    });
    _newRound();
    if (_round.isNotEmpty) {
      // ignore: discarded_futures
      Analytics.gameStarted(gameType: 'satz_arcade', level: _level);
    }
  }

  void _newRound() {
    final pool = SatzLoader.filter(_all, _level)..shuffle();
    final sourceId = _missionContext?.initialContentId;
    if (sourceId != null) {
      final sourceIndex = pool.indexWhere((item) => item.id == sourceId);
      if (sourceIndex > 0) {
        pool.insert(0, pool.removeAt(sourceIndex));
      }
    }
    setState(() {
      _roundId++;
      _round = pool.take(_roundSize).toList();
      _idx = 0;
      _passed = 0;
      _hasSubmittedAnswer = false;
      _answerPending = false;
      _outcome = null;
      _feedbackCompletion.reset();
      resetGameResult();
    });
  }

  void _setLevel(String? level) {
    _level = level;
    _newRound();
  }

  int _levelCount(String level) => level == _allLevels
      ? _all.length
      : _all.where((item) => item.level == level).length;

  Future<void> _showLevelFilter(AppL10n t, int roundId) async {
    if (_roundId != roundId ||
        _answerPending ||
        !gameResultAcceptsInput ||
        !studyEvidenceAcceptsInput) {
      return;
    }
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level ?? _allLevels,
      levels: const [_allLevels, ..._levels],
      allLabel: t.clozeLevelAll,
      countFor: _levelCount,
    );
    if (next == null ||
        _roundId != roundId ||
        _answerPending ||
        !gameResultAcceptsInput ||
        !studyEvidenceAcceptsInput) {
      return;
    }
    _setLevel(next == _allLevels ? null : next);
  }

  Widget _levelChrome(AppL10n t, int roundId) {
    if (widget.courseContext != null || widget.courseUnitId != null) {
      return const SizedBox.shrink();
    }
    final selected = _level ?? _allLevels;
    final label = _level == null ? t.clozeLevelAll : _level!.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriChromeRow(
        onFilterTap: () => _showLevelFilter(t, roundId),
        filterSemanticLabel: t.clozeLevelLabel,
        meta: Text(
          '$label · ${_levelCount(selected)}',
          style: SoriTextTheme.of(context).meta,
        ),
      ),
    );
  }

  Future<void> _onComplete(
    QuestResult result,
    int roundId,
    int index,
    SatzSentence item,
  ) async {
    if (!_isCurrentCard(roundId, index, item) ||
        !gameResultAcceptsInput ||
        !studyEvidenceAcceptsInput ||
        _answerPending) {
      return;
    }
    _answerPending = true;
    // Produktiver Abruf → Haupt-SRS. Key = Headword (vocabKo), NICHT der ganze
    // Satz → sonst Geisterkarten, die in der Wiederholung nie auftauchen.
    final srsAttempt = item.vocabKo.isEmpty
        ? null
        : SrsReviewAttempt(id: item.vocabKo, gotIt: result.passed);
    final courseAttempt = CourseContentAttempt(
      kind: CurriculumContentKind.satz,
      contentId: item.id,
      isCorrect: result.passed,
      isApplicable: _linkedCourseSentenceIds?.contains(item.id),
      courseContext: _missionContext?.initialContentId == item.id
          ? _missionContext
          : null,
      errorReason: result.passed ? null : MasteryErrorReason.wordOrder,
    );
    final saved = await saveStudyEvidence(() async {
      if (srsAttempt != null && !await srsAttempt.save()) {
        return false;
      }
      if (!_isCurrentCard(roundId, index, item) ||
          !studyEvidenceMayFlushAcceptedProgress ||
          !gameResultAcceptsInput) {
        return false;
      }
      final courseResult = await courseAttempt.save();
      return courseResult == CourseContentAttemptResult.persisted ||
          courseResult == CourseContentAttemptResult.notApplicable;
    });
    if (!saved ||
        !_isCurrentCard(roundId, index, item) ||
        !gameResultAcceptsInput) {
      return;
    }
    if (result.passed) _passed++;
    Future.delayed(const Duration(milliseconds: 300), () {
      // Bei Level-Wechsel/Neustart während der Verzögerung nicht die neue
      // Runde verschieben (Round-Token-Guard).
      if (!_isCurrentCard(roundId, index, item) || !gameResultAcceptsInput) {
        return;
      }
      setState(() {
        _idx++;
        _answerPending = false;
      });
      if (_idx >= _round.length) _finish();
    });
  }

  bool _isCurrentCard(int roundId, int index, SatzSentence item) =>
      mounted &&
      _roundId == roundId &&
      _idx == index &&
      index >= 0 &&
      index < _round.length &&
      identical(_round[index], item);

  void _retireStudy() {
    retireStudyEvidence();
    retireGameResult();
  }

  Future<void> _finish() async {
    final pct = _round.isEmpty ? 0 : ((_passed / _round.length) * 100).round();
    final outcome = await saveGameResult(
      gameId: 'satz_arcade',
      xp: _passed * 5,
      score: pct,
    );
    if (!mounted || outcome == null) {
      return;
    }
    _feedbackCompletion.complete(
      () => FeedbackCompletion.satzArcade(
        contentLabel: AppL10n.of(context).satzArcadeTitle,
        level: _level,
        passed: _passed,
        total: _round.length,
      ),
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final evidenceRecovery = studyEvidenceRecoveryFrame(
      AppL10n.of(context).satzArcadeTitle,
    );
    if (evidenceRecovery != null) {
      return evidenceRecovery;
    }
    final recovery = gameResultRecoveryFrame(
      AppL10n.of(context).satzArcadeTitle,
    );
    if (recovery != null) {
      return recovery;
    }
    final t = AppL10n.of(context);
    if (_loading) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.satzArcadeTitle,
        padding: EdgeInsets.zero,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_round.isEmpty) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.satzArcadeTitle,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (widget.items == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: _levelChrome(t, _roundId),
              ),
            Expanded(
              child: Center(
                child: SoriEmptyState(
                  asset: 'assets/illustrations/mascot/magpie_encourage.png',
                  icon: Icons.reorder_rounded,
                  title: t.satzArcadeTitle,
                  body: t.clozeEmptyBody,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_idx >= _round.length) {
      // _buildDone liest _outcome defensiv (?.) → kein RangeError im kurzen
      // Fenster, bevor recordGameResult auflöst (Muster wie cloze_game_screen).
      return _buildDone(t);
    }

    final item = _round[_idx];
    final roundId = _roundId;
    final index = _idx;
    return SoriStudyFrame(
      onLeave: _retireStudy,
      title: t.satzArcadeTitle,
      homeEscape: SoriHomeEscape(confirmWhen: _hasSubmittedAnswer),
      eyebrow:
          '${_idx + 1} / ${_round.length} · ${t.quizScore(_passed, _round.length)}',
      child: SoriAdaptiveStudyBody(
        minHeight: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.items == null) _levelChrome(t, roundId),
            Expanded(
              child: SatzBauenQuest(
                key: ValueKey('satz_${_roundId}_$_idx'),
                data: item.toQuestData(),
                onAttempt: () {
                  if (_isCurrentCard(roundId, index, item) &&
                      gameResultAcceptsInput &&
                      studyEvidenceAcceptsInput &&
                      !_hasSubmittedAnswer) {
                    setState(() => _hasSubmittedAnswer = true);
                  }
                },
                onComplete: (result) =>
                    _onComplete(result, roundId, index, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_passed / _round.length) * 100).round();
    final roundId = _roundId;
    return SoriStudyFrame(
      onLeave: _retireStudy,
      automaticallyImplyLeading: false,
      title: t.satzArcadeTitle,
      padding: EdgeInsets.zero,
      child: SoriCenterClamp(
        child: GameOverCard(
          headline: t.quizResultTitle,
          scoreLabel: t.quizScore(_passed, _round.length),
          feedbackContext: _feedbackCompletion.current?.context,
          xpGained: _outcome?.xpGained ?? (_passed * 5),
          isNewBest: _outcome?.isNewBest ?? false,
          newBestLabel: t.gameNewBest,
          bestLabel: t.gameBestAccuracy(_outcome?.best ?? 0),
          mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
          mascotEmotion: pct >= 50
              ? MascotEmotion.celebrate
              : MascotEmotion.worry,
          celebrate: pct >= 50,
          actions: [
            SoriButton(
              label: t.quizAgain,
              icon: Icons.refresh_rounded,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.contentCta,
              fullWidth: true,
              onTap: () {
                if (_roundId == roundId &&
                    _idx >= _round.length &&
                    gameResultAcceptsInput &&
                    studyEvidenceAcceptsInput) {
                  _newRound();
                }
              },
            ),
            SoriButton(
              label: t.btnClose,
              variant: SoriButtonVariant.ghost,
              fullWidth: true,
              onTap: () {
                if (_roundId == roundId &&
                    _idx >= _round.length &&
                    gameResultAcceptsInput &&
                    studyEvidenceAcceptsInput) {
                  _retireStudy();
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
