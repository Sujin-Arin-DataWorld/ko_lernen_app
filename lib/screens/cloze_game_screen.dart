import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';
import '../models/feedback_completion.dart';
import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import '../models/vocab.dart';
import '../services/analytics_service.dart';
import '../services/cloze_loader.dart';
import '../services/course_activity_reporter.dart';
import '../services/curriculum_catalog.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/cloze_prompt.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// **Lückentext (Cloze)** — das fehlende Wort im echten Satz wählen.
///
/// Kontext-Abruf schlägt isolierte Karteikarten (Forschung), füllt aktiv die
/// anspruchsvolle B1-C2-Inhalte und ist für Erwachsene zufriedenstellender
/// als reines
/// Wiedererkennen. Sätze + Übersetzungen stammen aus geprüften Vokabel-
/// Beispielen (assets/data/cloze.json).
class ClozeGameScreen extends StatefulWidget {
  /// Optional test fixture; production loads the curated cloze asset.
  final List<ClozeItem>? items;

  /// When opened from a course mission, only graph-linked items are drawn.
  /// Library entry keeps the existing all-level behavior.
  final String? courseUnitId;
  final CoursePracticeContext? courseContext;

  const ClozeGameScreen({
    super.key,
    this.items,
    this.courseUnitId,
    this.courseContext,
  });

  @override
  State<ClozeGameScreen> createState() => _ClozeGameScreenState();
}

class _ClozeGameScreenState extends State<ClozeGameScreen> {
  static const _roundSize = 10;
  static const _levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
  static const _allLevels = '';

  List<ClozeItem> _all = const [];
  Map<String, Vocab> _vocabByKo = const {};
  bool _loading = true;
  String? _level; // null = alle
  int _roundId = 0;

  List<ClozeItem> _round = const [];
  int _idx = 0;
  int _score = 0;
  String? _picked;

  /// 현재 문제에서 이미 한 번 틀렸는가 — 재시도로 맞혀도 첫 시도 결과가
  /// 점수·SRS·코스 숙달도에 반영되도록 [_pick] 이 읽는다.
  bool _retried = false;
  GameOutcome? _outcome;
  CoursePracticeContext? _missionContext;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = widget.items ?? await ClozeLoader.load();
    final all = List<ClozeItem>.of(loaded);
    // An injected item list is a deterministic test fixture, not a partial
    // production dataset. It must not wait on an unrelated asset load before
    // showing the supplied round.
    final vocab = widget.items == null
        ? await DataLoader.loadVocab()
        : const <Vocab>[];
    final courseUnitId =
        widget.courseContext?.courseUnitId ?? widget.courseUnitId;
    final catalog = courseUnitId == null
        ? null
        : await CurriculumCatalog.load();
    if (!mounted) return;
    // Startlevel = Nutzerlevel, falls es dafür Items gibt; sonst alle.
    final user = Storage.browseLevelCode ?? Storage.placementLevelCode;
    final start = (user != null && all.any((c) => c.level == user))
        ? user
        : null;
    final courseIds = catalog == null
        ? const <String>{}
        : catalog
              .linksForCourseUnit(courseUnitId!)
              .where((link) => link.contentKind == CurriculumContentKind.cloze)
              .map((link) => link.contentId)
              .toSet();
    final scoped = catalog == null
        ? all
        : all.where((item) => courseIds.contains(item.id)).toList();
    final requestedContext = widget.courseContext;
    final missionContext =
        catalog == null ||
            requestedContext == null ||
            !requestedContext.isFor(CurriculumContentKind.cloze) ||
            !catalog
                .linksForCourseUnit(courseUnitId!)
                .any(
                  (link) =>
                      link.id == requestedContext.contentLinkId &&
                      link.contentKind == CurriculumContentKind.cloze &&
                      link.contentId == requestedContext.initialContentId,
                )
        ? null
        : requestedContext;
    setState(() {
      _all = scoped;
      _vocabByKo = {for (final v in vocab) v.korean: v};
      _level = catalog == null && widget.items == null ? start : null;
      _missionContext = missionContext;
      _loading = false;
    });
    _newRound();
    if (_round.isNotEmpty) {
      // ignore: discarded_futures
      Analytics.gameStarted(gameType: 'cloze', level: _level);
    }
  }

  void _newRound() {
    final pool = ClozeLoader.filter(_all, _level)..shuffle();
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
      _score = 0;
      _picked = null;
      _outcome = null;
      _feedbackCompletion.reset();
    });
  }

  void _setLevel(String? level) {
    _level = level;
    _newRound();
  }

  int _levelCount(String level) => level == _allLevels
      ? _all.length
      : _all.where((item) => item.level == level).length;

  Future<void> _showLevelFilter(AppL10n t) async {
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level ?? _allLevels,
      levels: const [_allLevels, ..._levels],
      allLabel: t.clozeLevelAll,
      countFor: _levelCount,
    );
    if (!mounted || next == null) return;
    _setLevel(next == _allLevels ? null : next);
  }

  Widget _levelChrome(AppL10n t) {
    if (widget.courseContext != null || widget.courseUnitId != null) {
      return const SizedBox.shrink();
    }
    final selected = _level ?? _allLevels;
    final label = _level == null ? t.clozeLevelAll : _level!.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriChromeRow(
        onFilterTap: () => _showLevelFilter(t),
        filterSemanticLabel: t.clozeLevelLabel,
        meta: Text(
          '$label · ${_levelCount(selected)}',
          style: SoriTextTheme.of(context).meta,
        ),
      ),
    );
  }

  void _pick(ClozeItem item, String option) {
    if (_picked != null) return;
    final ok = item.accepts(option);
    // 첫 시도 여부를 **기록 전에** 잡는다 — 재시도로 맞혀도 점수·SRS·코스
    // 숙달도는 첫 시도 결과를 따른다. 안 그러면 재시도 허용이 곧 전원 만점이
    // 되어 `n / 10 richtig` 카운터가 의미를 잃는다.
    final firstTry = !_retried;
    setState(() => _picked = option);

    if (firstTry) {
      Storage.srsReview(item.answer, gotIt: ok); // Kontext-Abruf → Haupt-SRS
      // ignore: discarded_futures
      CourseActivityReporter.recordContentAttempt(
        CurriculumContentKind.cloze,
        item.id,
        ok,
        courseContext: _missionContext?.initialContentId == item.id
            ? _missionContext
            : null,
        errorReason: ok ? null : MasteryErrorReason.vocabularyRecall,
      );
      if (ok) _score++;
    }

    if (ok) {
      HapticFeedback.lightImpact();
      SoundService.correct();
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _idx++;
          _picked = null;
          _retried = false;
        });
        if (_idx >= _round.length) _finish();
      });
      return;
    }

    // 오답 — Jin 2026-08-07 지시: 빈칸에 빨갛게 들어갔다가 되돌아오고 계속
    // 고를 수 있다(재시도 허용). 예전에는 오답도 그대로 다음 문제로 넘어가
    // 무엇이 맞는 답이었는지 손으로 확인할 기회가 없었다.
    HapticFeedback.mediumImpact();
    SoundService.wrong();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _picked = null;
        _retried = true;
      });
    });
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.cloze(
        contentLabel: AppL10n.of(context).clozeTitle,
        level: _level,
        correct: _score,
        total: _round.length,
      ),
    );
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    final outcome = await recordGameResult(
      gameId: 'cloze',
      xp: _score * 5,
      score: pct,
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return SoriStudyFrame(
        title: t.clozeTitle,
        padding: EdgeInsets.zero,
        child: const AppLoading(),
      );
    }

    if (_round.isEmpty) {
      return SoriStudyFrame(
        title: t.clozeTitle,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (widget.items == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: _levelChrome(t),
              ),
            Expanded(
              child: Center(
                child: SoriEmptyState(
                  asset: 'assets/illustrations/mascot/magpie_encourage.png',
                  icon: Icons.menu_book_outlined,
                  title: t.clozeTitle,
                  body: t.clozeEmptyBody,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_idx >= _round.length) {
      return _buildDone(t);
    }

    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final item = _round[_idx];
    final options = item.options(_roundId * 100 + _idx);
    final revealed = _picked != null;

    return SoriStudyFrame(
      title: t.clozeTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: _idx > 0 || _picked != null || _retried,
      ),
      eyebrow:
          '${_idx + 1} / ${_round.length} · ${t.quizScore(_score, _round.length)}',
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      child: SoriAdaptiveStudyBody(
        minHeight: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.items == null) _levelChrome(t),
            Text(
              t.clozeInstruction,
              style: SoriTextTheme.of(
                context,
              ).meta.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.md),
            Flexible(
              flex: 3,
              child: SingleChildScrollView(
                child: SoriSpeakable(
                  text: item.fullKo,
                  child: ClozePromptCard(
                    item: item,
                    lang: lang,
                    gloss: _vocabByKo[item.answer]?.translationFor(lang),
                    picked: _picked,
                    pickedWrong: _picked != null && !item.accepts(_picked!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Expanded(
              flex: 4,
              child: ClozeOptionsList(
                options: options,
                acceptedAnswers: item.acceptedAnswers,
                picked: _picked,
                revealed: revealed,
                onPick: (opt) => _pick(item, opt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    return SoriStudyFrame(
      automaticallyImplyLeading: false,
      title: t.clozeTitle,
      padding: EdgeInsets.zero,
      child: SoriCenterClamp(
        child: GameOverCard(
          headline: t.quizResultTitle,
          scoreLabel: t.quizScore(_score, _round.length),
          feedbackContext: _feedbackCompletion.current?.context,
          xpGained: _score * 5,
          isNewBest: _outcome?.isNewBest ?? false,
          newBestLabel: t.gameNewBest,
          bestLabel: t.gameBestAccuracy(Storage.gameBest('cloze')),
          mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
          mascotEmotion: pct >= 50
              ? MascotEmotion.celebrate
              : MascotEmotion.worry,
          celebrate: pct >= 50, // schlechte Runde → kein Konfetti (Tonalität)
          actions: [
            SoriButton(
              label: t.quizAgain,
              icon: Icons.refresh_rounded,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.contentCta,
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
    );
  }
}
