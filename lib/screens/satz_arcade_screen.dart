import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_practice_context.dart';
import '../models/feedback_completion.dart';
import '../models/curriculum.dart';
import '../services/course_activity_reporter.dart';
import '../services/curriculum_catalog.dart';
import '../services/satz_loader.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
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

class _SatzArcadeScreenState extends State<SatzArcadeScreen> {
  static const _roundSize = 8;
  static const _levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

  List<SatzSentence> _all = const [];
  bool _loading = true;
  String? _level;
  int _roundId = 0;

  List<SatzSentence> _round = const [];
  int _idx = 0;
  int _passed = 0;
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
    if (!mounted) return;
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
      _level = catalog == null && widget.items == null ? start : null;
      _missionContext = missionContext;
      _loading = false;
    });
    _newRound();
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
      _outcome = null;
      _feedbackCompletion.reset();
    });
  }

  void _setLevel(String? level) {
    _level = level;
    _newRound();
  }

  void _onComplete(QuestResult result) {
    final rid = _roundId;
    // Produktiver Abruf → Haupt-SRS. Key = Headword (vocabKo), NICHT der ganze
    // Satz → sonst Geisterkarten, die in der Wiederholung nie auftauchen.
    if (_idx < _round.length) {
      final item = _round[_idx];
      final ko = item.vocabKo;
      if (ko.isNotEmpty) {
        Storage.srsReview(ko, gotIt: result.passed);
      }
      // ignore: discarded_futures
      CourseActivityReporter.recordContentAttempt(
        CurriculumContentKind.satz,
        item.id,
        result.passed,
        courseContext: _missionContext?.initialContentId == item.id
            ? _missionContext
            : null,
        errorReason: result.passed ? null : MasteryErrorReason.wordOrder,
      );
    }
    if (result.passed) _passed++;
    Future.delayed(const Duration(milliseconds: 300), () {
      // Bei Level-Wechsel/Neustart während der Verzögerung nicht die neue
      // Runde verschieben (Round-Token-Guard).
      if (!mounted || _roundId != rid) return;
      setState(() => _idx++);
      if (_idx >= _round.length) _finish();
    });
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.satzArcade(
        contentLabel: AppL10n.of(context).satzArcadeTitle,
        level: _level,
        passed: _passed,
        total: _round.length,
      ),
    );
    final pct = _round.isEmpty ? 0 : ((_passed / _round.length) * 100).round();
    final outcome = await recordGameResult(
      gameId: 'satz_arcade',
      xp: _passed * 5,
      score: pct,
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.satzArcadeTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_round.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.satzArcadeTitle)),
        body: SafeArea(
          child: Column(
            children: [
              if (widget.items == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: _levelBar(t),
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
        ),
      );
    }
    if (_idx >= _round.length) {
      // _buildDone liest _outcome defensiv (?.) → kein RangeError im kurzen
      // Fenster, bevor recordGameResult auflöst (Muster wie cloze_game_screen).
      return _buildDone(t);
    }

    final item = _round[_idx];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.satzArcadeTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.items == null) _levelBar(t),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SoriChip(
                      label: '${_idx + 1} / ${_round.length}',
                      accent: SoriColors.info,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Expanded(
                    child: SatzBauenQuest(
                      key: ValueKey('satz_${_roundId}_$_idx'),
                      data: item.toQuestData(),
                      onComplete: _onComplete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelBar(AppL10n t) {
    if (widget.courseContext != null || widget.courseUnitId != null) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          _levelChip(t.clozeLevelAll, _level == null, () => _setLevel(null)),
          for (final lv in _levels) ...[
            const SizedBox(width: Spacing.sm),
            _levelChip(lv.toUpperCase(), _level == lv, () => _setLevel(lv)),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(String label, bool selected, VoidCallback onTap) {
    return SoriChip(
      label: label,
      accent: SoriColors.primary,
      selected: selected,
      variant: selected ? SoriChipVariant.filled : SoriChipVariant.soft,
      onTap: onTap,
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_passed / _round.length) * 100).round();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.satzArcadeTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
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
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: _newRound,
              ),
              SoriButton(
                label: t.btnClose,
                variant: SoriButtonVariant.ghost,
                fullWidth: true,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
