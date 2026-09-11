import '../widgets/sori/game_result_recovery.dart';
import '../widgets/sori/study_evidence_recovery.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/vocab.dart';
import '../services/analytics_service.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sori_icon.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/game_layout.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// **Speed-Match** — gegen die Uhr Koreanisch ↔ Bedeutung paaren.
///
/// Arcade-Tempo (Drops-Stil) für Flüssigkeit + Spaß; Erkennen ist hier bewusst
/// die Mechanik (Aufwärm-/Geschwindigkeitsschicht), Abruf liefern die anderen
/// Spiele. Selbst-Wettbewerb (persönliche Bestleistung) — keine Rangliste.
class SpeedMatchScreen extends StatefulWidget {
  /// Optional test fixture; production loads the curated vocabulary set.
  final List<Vocab>? items;

  /// Optional deterministic seam. Production keeps [DataLoader.loadVocab].
  final Future<List<Vocab>> Function()? vocabLoader;

  const SpeedMatchScreen({super.key, this.items, this.vocabLoader});

  @override
  State<SpeedMatchScreen> createState() => _SpeedMatchScreenState();
}

class _SpeedMatchScreenState extends State<SpeedMatchScreen>
    with
        WidgetsBindingObserver,
        GameResultRecovery<SpeedMatchScreen>,
        StudyEvidenceRecovery<SpeedMatchScreen> {
  static const _seconds = 60;
  static const _regularSlots = 5;
  static const _levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
  static const _allLevels = '';

  final Random _rng = Random();
  List<Vocab> _all = const [];
  bool _loading = true;
  bool _loadFailed = false;
  String? _level;

  final List<Vocab> _pool = []; // verbleibender Vorrat (gemischt)
  final List<Vocab> _active = []; // aktuell sichtbare Vokabeln
  List<Vocab> _rightOrder = const []; // Bedeutungsspalte (gemischt)
  String? _selLeftKo;
  String? _wrongRightKo;
  // Wörter mit mindestens einem Fehlversuch in der laufenden Runde behalten
  // ihren negativen SRS-Nachweis, auch wenn der Spieler sie danach korrekt
  // zuordnet und damit Punkte erhält.
  final Set<String> _missedKorean = {};

  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _remaining = _seconds;
  Timer? _timer;
  bool _running = false;
  bool _lifecyclePaused = false;
  int _slotCount = _regularSlots;
  int? _pendingSlotCount;
  int _loadGeneration = 0;
  int _roundGeneration = 0;
  int _presentation = 0;
  GameOutcome? _outcome;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  bool get _acceptsInput => studyEvidenceAcceptsInput && gameResultAcceptsInput;

  void _retireStudy() {
    _loadGeneration++;
    _roundGeneration++;
    _presentation++;
    _pendingSlotCount = null;
    _timer?.cancel();
    _timer = null;
    retireStudyEvidence();
    retireGameResult();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecyclePaused = false;
        if (_acceptsInput && _running && _remaining > 0 && _timer == null) {
          _runTimer();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _lifecyclePaused = true;
        _timer?.cancel();
        _timer = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scaler = MediaQuery.textScalerOf(context);
    final nextSlotCount = soriSpeedMatchSlotCount(
      viewportHeight: MediaQuery.sizeOf(context).height,
      textScaleFactor: scaler.scale(16) / 16,
    );
    if (_slotCount == nextSlotCount) {
      _pendingSlotCount = null;
      return;
    }
    if (!_acceptsInput) {
      if (!_loading && _running && studyEvidenceIsCurrent) {
        _pendingSlotCount = nextSlotCount;
      }
      return;
    }
    if (!_loading && !_running) {
      return;
    }
    if (_loading) {
      _slotCount = nextSlotCount;
      return;
    }

    _applySlotCount(nextSlotCount);
  }

  void _applySlotCount(int nextSlotCount) {
    _pendingSlotCount = null;
    _slotCount = nextSlotCount;
    while (_active.length > _slotCount) {
      _pool.add(_active.removeLast());
    }
    while (_active.length < _slotCount && _pool.isNotEmpty) {
      _active.add(_pool.removeLast());
    }
    _presentation++;
    _selLeftKo = null;
    _wrongRightKo = null;
    _reshuffleRight();
  }

  void _applyPendingSlotCount() {
    final pending = _pendingSlotCount;
    if (pending != null && pending != _slotCount) {
      _applySlotCount(pending);
    } else {
      _pendingSlotCount = null;
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (!_loading) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    late final List<Vocab> all;
    try {
      all = widget.items != null
          ? await Future<List<Vocab>>.value(widget.items!)
          : await (widget.vocabLoader ?? DataLoader.loadVocab)();
    } catch (_) {
      if (!_acceptsInput || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    if (!mounted || !_acceptsInput || generation != _loadGeneration) {
      return;
    }
    final defaultLoadFailed =
        widget.items == null &&
        widget.vocabLoader == null &&
        DataLoader.vocabError != null;
    if (defaultLoadFailed) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    // Nach koreanischem Wort dedupen → kein Homograph-Doppel (removeWhere würde
    // sonst beide Kacheln entfernen). Erstes Vorkommen gewinnt.
    final seen = <String>{};
    final usable = <Vocab>[];
    for (final v in all) {
      final ko = v.korean.trim();
      if (ko.isEmpty || v.translationFor(lang).trim().isEmpty) continue;
      if (seen.add(ko)) usable.add(v);
    }
    final preferredLevel = SoriLevelFilterBar.resolveStartLevel();
    final start = usable.any((v) => v.level.toLowerCase() == preferredLevel)
        ? preferredLevel
        : null;
    setState(() {
      _all = usable;
      _level = widget.items == null ? start : null;
      _loading = false;
      _loadFailed = false;
    });
    _startRound();
    if (_running) {
      unawaited(Analytics.gameStarted(gameType: 'speed_match', level: _level));
    }
  }

  Future<void> _retryLoad(int loadGeneration) async {
    if (!_acceptsInput ||
        loadGeneration != _loadGeneration ||
        _loading ||
        !_loadFailed) {
      return;
    }
    if (widget.items == null && widget.vocabLoader == null) {
      DataLoader.resetVocab();
    }
    await _load();
  }

  List<Vocab> _filtered() {
    if (_level == null) return _all;
    return _all.where((v) => v.level.toLowerCase() == _level).toList();
  }

  void _startRound({int? expectedGeneration}) {
    if (!_acceptsInput ||
        (expectedGeneration != null &&
            expectedGeneration != _roundGeneration)) {
      return;
    }
    _timer?.cancel();
    _roundGeneration++;
    _presentation++;
    _pendingSlotCount = null;
    final pool = List<Vocab>.of(_filtered())..shuffle(_rng);
    _pool
      ..clear()
      ..addAll(pool);
    _active.clear();
    for (var i = 0; i < _slotCount && _pool.isNotEmpty; i++) {
      _active.add(_pool.removeLast());
    }
    _missedKorean.clear();
    setState(() {
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _remaining = _seconds;
      _selLeftKo = null;
      _wrongRightKo = null;
      _outcome = null;
      _feedbackCompletion.reset();
      resetGameResult();
      _running = _active.length >= 2;
      _reshuffleRight();
    });
    if (_running && !_lifecyclePaused) _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!identical(timer, _timer)) {
        timer.cancel();
        return;
      }
      if (!_acceptsInput || !_running) {
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        unawaited(_end(_roundGeneration));
      }
    });
  }

  void _reshuffleRight() {
    _rightOrder = [..._active]..shuffle(_rng);
  }

  void _setLevel(String? level) {
    if (!_acceptsInput) {
      return;
    }
    _level = level;
    _startRound();
  }

  int _levelCount(String level) => level == _allLevels
      ? _all.length
      : _all.where((item) => item.level.toLowerCase() == level).length;

  Future<void> _showLevelFilter(
    AppL10n t,
    int generation,
    int presentation,
  ) async {
    if (!_acceptsInput ||
        !_running ||
        generation != _roundGeneration ||
        presentation != _presentation) {
      return;
    }
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level ?? _allLevels,
      levels: const [_allLevels, ..._levels],
      allLabel: t.clozeLevelAll,
      countFor: _levelCount,
    );
    if (!_acceptsInput ||
        !_running ||
        generation != _roundGeneration ||
        presentation != _presentation ||
        next == null) {
      return;
    }
    _setLevel(next == _allLevels ? null : next);
  }

  Widget _levelChrome(AppL10n t, int generation, int presentation) {
    final selected = _level ?? _allLevels;
    final label = _level == null ? t.clozeLevelAll : _level!.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriChromeRow(
        onFilterTap: () => _showLevelFilter(t, generation, presentation),
        filterSemanticLabel: t.clozeLevelLabel,
        meta: Text(
          '$label · ${_levelCount(selected)}',
          style: SoriTextTheme.of(context).meta,
        ),
      ),
    );
  }

  void _tapLeft(String ko, int presentation) {
    if (!_acceptsInput ||
        !_running ||
        presentation != _presentation ||
        !_active.any((word) => word.korean == ko)) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _presentation++;
      _selLeftKo = ko;
      _wrongRightKo = null;
    });
  }

  Future<void> _tapRight(Vocab right, int presentation) async {
    if (!_acceptsInput ||
        !_running ||
        presentation != _presentation ||
        _selLeftKo == null) {
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    final selectedKorean = _selLeftKo!;
    final correct = selectedKorean == right.korean;
    final generation = _roundGeneration;
    final judgment = ++_presentation;
    final firstMiss = !_missedKorean.contains(selectedKorean);
    if (firstMiss) {
      final attempt = SrsReviewAttempt(id: selectedKorean, gotIt: correct);
      if (!await saveStudyEvidence(attempt.save)) {
        return;
      }
    }
    if (!_isCurrentMatch(
      generation: generation,
      presentation: judgment,
      selectedKorean: selectedKorean,
      right: right,
    )) {
      return;
    }
    _resumeTimerAfterEvidence();
    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
      _combo++;
      if (_combo > _bestCombo) {
        _bestCombo = _combo;
      }
      if (_combo >= 3) {
        SoundService.combo();
      } else {
        SoundService.correct();
      }
      _active.removeWhere((v) => v.korean == right.korean);
      if (_pool.isNotEmpty) {
        _active.add(_pool.removeLast());
      }
      setState(() {
        _selLeftKo = null;
        _wrongRightKo = null;
        _reshuffleRight();
        _applyPendingSlotCount();
      });
      if (_active.length < 2) {
        unawaited(_end(generation)); // Vorrat erschöpft → früh beenden
      }
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _combo = 0;
      if (firstMiss && _missedKorean.add(selectedKorean)) {
        // SRS card + daily log were already confirmed above. This diagnostic
        // is emitted once per word/round and cannot run ahead of that evidence.
        unawaited(Storage.incrementWrongCount(selectedKorean));
      }
      setState(() {
        _applyPendingSlotCount();
        _wrongRightKo = right.translationFor(lang);
      });
      final feedbackPresentation = _presentation;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_acceptsInput &&
            generation == _roundGeneration &&
            feedbackPresentation == _presentation) {
          setState(() => _wrongRightKo = null);
        }
      });
    }
  }

  bool _isCurrentMatch({
    required int generation,
    required int presentation,
    required String selectedKorean,
    required Vocab right,
  }) =>
      _acceptsInput &&
      _running &&
      generation == _roundGeneration &&
      presentation == _presentation &&
      _selLeftKo == selectedKorean &&
      _active.any((word) => word.korean == selectedKorean) &&
      _rightOrder.any((word) => identical(word, right));

  void _resumeTimerAfterEvidence() {
    if (_acceptsInput &&
        _running &&
        !_lifecyclePaused &&
        _remaining > 0 &&
        _timer == null) {
      _runTimer();
    }
  }

  Future<void> _end(int generation) async {
    if (!_acceptsInput || !_running || generation != _roundGeneration) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _running = false;

    HapticFeedback.heavyImpact();
    final outcome = await saveGameResult(
      gameId: 'speed_match',
      xp: _score * 3,
      score: _score, // höher = besser
    );
    if (!mounted ||
        !studyEvidenceIsCurrent ||
        generation != _roundGeneration ||
        outcome == null) {
      return;
    }
    _feedbackCompletion.complete(
      () => FeedbackCompletion.speedMatch(
        contentLabel: AppL10n.of(context).speedMatchTitle,
        level: _level,
        score: _score,
      ),
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = AppL10n.of(context).speedMatchTitle;
    final recovery =
        studyEvidenceRecoveryFrame(title) ?? gameResultRecoveryFrame(title);
    if (recovery != null) {
      return recovery;
    }
    final t = AppL10n.of(context);
    final loadGeneration = _loadGeneration;
    final roundGeneration = _roundGeneration;
    final presentation = _presentation;
    if (_loading) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.speedMatchTitle,
        padding: EdgeInsets.zero,
        child: Semantics(
          liveRegion: true,
          label: t.gameLoading,
          excludeSemantics: true,
          child: AppLoading(message: t.gameLoading),
        ),
      );
    }
    if (_loadFailed) {
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.speedMatchTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: t.loadErrorTryAgain,
          onRetry: () => _retryLoad(loadGeneration),
          messageLiveRegion: true,
        ),
      );
    }
    if (!_running && _outcome == null && _active.length < 2) {
      final canUseAllLevels =
          widget.items == null && _level != null && _all.length >= 2;
      return SoriStudyFrame(
        onLeave: _retireStudy,
        title: t.speedMatchTitle,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.bolt_rounded,
            title: t.speedMatchTitle,
            body: t.speedMatchEmptyBody,
            ctaLabel: canUseAllLevels ? t.speedMatchAllLevels : null,
            onCta: canUseAllLevels
                ? () {
                    if (_acceptsInput &&
                        loadGeneration == _loadGeneration &&
                        roundGeneration == _roundGeneration &&
                        presentation == _presentation &&
                        !_running &&
                        _outcome == null &&
                        _active.length < 2) {
                      _setLevel(null);
                    }
                  }
                : null,
          ),
        ),
      );
    }
    if (!_running && _outcome != null) {
      return _buildDone(t, roundGeneration);
    }

    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    final lowTime = _remaining <= 10;
    final compact = _slotCount < _regularSlots;

    return SoriStudyFrame(
      onLeave: _retireStudy,
      title: t.speedMatchTitle,
      homeEscape: SoriHomeEscape(confirmWhen: _running),
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: compact ? Spacing.sm : Spacing.lg,
      ),
      child: SoriAdaptiveStudyBody(
        minHeight: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.items == null)
              _levelChrome(t, roundGeneration, presentation),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                Semantics(
                  liveRegion: lowTime,
                  label: t.kkeunmariTimerSeconds(
                    _remaining < 0 ? 0 : _remaining,
                  ),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: lowTime ? SoriColors.danger : s.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.kkeunmariTimerSeconds(
                          _remaining < 0 ? 0 : _remaining,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: lowTime ? SoriColors.danger : s.text,
                          // 카운트다운 자릿수 폭 고정(흔들림 방지).
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_combo >= 2)
                  SoriChip(
                    label: compact ? '×$_combo' : t.comboPop(_combo),
                    semanticLabel: t.comboPop(_combo),
                    icon: SoriGlyph.streak,
                    accent: SoriColors.tiger,
                    variant: SoriChipVariant.filled,
                    fontSize: compact ? 11 : 12,
                  ),
                SoriChip(
                  label: t.speedMatchScore(_score),
                  accent: SoriColors.success,
                ),
              ],
            ),
            SizedBox(height: compact ? Spacing.xs : Spacing.sm),
            Text(
              t.speedMatchInstruction,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.2,
                color: s.textMuted,
              ),
            ),
            SizedBox(height: compact ? Spacing.sm : Spacing.md),
            // 보드는 정상 화면의 남는 높이를 균등하게 사용한다. 번역이 길거나
            // 글자가 커져 타일이 최소 높이보다 커지면 보드 자체가 스크롤되어
            // 어떤 단어도 ellipsis로 사라지지 않는다.
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileHeight = soriFairTileHeight(
                    available: c.maxHeight,
                    count: _active.length,
                    minimum: 44,
                  );
                  final expandForText = _boardNeedsScroll(
                    context,
                    boardWidth: c.maxWidth,
                    tileHeight: tileHeight,
                    lang: lang,
                  );
                  final board = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (final v in _active)
                              _MatchTile(
                                key: ValueKey('speed-match-left-${v.korean}'),
                                label: v.korean,
                                height: tileHeight,
                                expandForText: expandForText,
                                selected: _selLeftKo == v.korean,
                                accent: SoriColors.primary,
                                onTap: () => _tapLeft(v.korean, presentation),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          children: [
                            for (final v in _rightOrder)
                              _MatchTile(
                                key: ValueKey('speed-match-right-${v.korean}'),
                                label: v.translationFor(lang),
                                height: tileHeight,
                                expandForText: expandForText,
                                wrong: _wrongRightKo == v.translationFor(lang),
                                accent: SoriColors.accent,
                                onTap: () =>
                                    unawaited(_tapRight(v, presentation)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                  if (expandForText) {
                    return SingleChildScrollView(child: board);
                  }
                  return board;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _boardNeedsScroll(
    BuildContext context, {
    required double boardWidth,
    required double tileHeight,
    required String lang,
  }) {
    const minimumFontSize = 12.0;
    const maxLines = 3;
    final textWidth = ((boardWidth - Spacing.md) / 2 - Spacing.sm * 2).clamp(
      1.0,
      double.infinity,
    );
    final textHeight = (tileHeight - Spacing.sm * 2).clamp(
      1.0,
      double.infinity,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    final style = DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        fontWeight: FontWeight.w700,
        height: 1.1,
        fontSize: minimumFontSize,
      ),
    );
    final labels = <String>[
      for (final vocab in _active) vocab.korean,
      for (final vocab in _rightOrder) vocab.translationFor(lang),
    ];

    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        maxLines: maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      )..layout(maxWidth: textWidth);
      if (painter.didExceedMaxLines || painter.height > textHeight) {
        return true;
      }
    }
    return false;
  }

  Widget _buildDone(AppL10n t, int generation) {
    return SoriStudyFrame(
      onLeave: _retireStudy,
      automaticallyImplyLeading: false,
      title: t.speedMatchTitle,
      padding: EdgeInsets.zero,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: t.quizResultTitle,
        child: SoriCenterClamp(
          child: GameOverCard(
            headline: t.quizResultTitle,
            scoreLabel: t.speedMatchScore(_score),
            feedbackContext: _feedbackCompletion.current?.context,
            xpGained: _score * 3,
            isNewBest: _outcome?.isNewBest ?? false,
            newBestLabel: t.gameNewBest,
            bestLabel: t.speedMatchBest(Storage.gameBest('speed_match')),
            mascotKind: MascotKind.magpie,
            mascotEmotion: MascotEmotion.celebrate,
            celebrate: _score > 0,
            actions: [
              SoriButton(
                label: t.quizAgain,
                icon: Icons.refresh_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.tiger,
                fullWidth: true,
                onTap: () {
                  if (_acceptsInput &&
                      generation == _roundGeneration &&
                      !_running &&
                      _outcome != null) {
                    _startRound(expectedGeneration: generation);
                  }
                },
              ),
              SoriButton(
                label: t.btnClose,
                variant: SoriButtonVariant.ghost,
                fullWidth: true,
                onTap: () {
                  if (_acceptsInput &&
                      generation == _roundGeneration &&
                      !_running &&
                      _outcome != null) {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool wrong;
  final bool expandForText;
  final Color accent;
  final VoidCallback onTap;

  /// Normal row height. Long labels grow instead of being clipped.
  final double height;

  const _MatchTile({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
    this.height = 52,
    this.selected = false,
    this.wrong = false,
    this.expandForText = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    Color border = s.border;
    Color bg = s.surface;
    if (wrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withValues(alpha: 0.12);
    } else if (selected) {
      border = accent;
      bg = accent.withValues(alpha: 0.12);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      value: wrong ? t.statsWrong : null,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(SoriRadius.md),
          child: InkWell(
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(SoriRadius.md),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: expandForText ? null : height,
              constraints: expandForText
                  ? BoxConstraints(minHeight: height)
                  : null,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1.5),
                borderRadius: BorderRadius.circular(SoriRadius.md),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wrong || selected ? 20 : 0,
                    ),
                    child: _MatchTileLabel(
                      label: label,
                      tileHeight: height,
                      expandForText: expandForText,
                    ),
                  ),
                  if (wrong || selected)
                    Positioned(
                      right: 0,
                      child: Icon(
                        wrong
                            ? Icons.close_rounded
                            : Icons.radio_button_checked_rounded,
                        color: wrong ? SoriColors.danger : accent,
                        size: 18,
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
}

class _MatchTileLabel extends StatelessWidget {
  static const _minimumFontSize = 12.0;
  static const _maxLines = 3;

  final String label;
  final double tileHeight;
  final bool expandForText;

  const _MatchTileLabel({
    required this.label,
    required this.tileHeight,
    required this.expandForText,
  });

  @override
  Widget build(BuildContext context) {
    if (expandForText) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          height: 1.1,
          fontSize: soriTileFontSize(tileHeight: tileHeight),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        final style = DefaultTextStyle.of(context).style.merge(
          TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.1,
            fontSize: soriTileFontSize(tileHeight: tileHeight),
          ),
        );
        final fontSize = _fitFontSize(
          constraints: constraints,
          style: style,
          textScaler: textScaler,
          textDirection: textDirection,
          locale: locale,
        );
        return Text(
          label,
          locale: locale,
          maxLines: _maxLines,
          softWrap: true,
          textAlign: TextAlign.center,
          textDirection: textDirection,
          textScaler: textScaler,
          style: style.copyWith(fontSize: fontSize),
        );
      },
    );
  }

  double _fitFontSize({
    required BoxConstraints constraints,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required Locale? locale,
  }) {
    final maximum = style.fontSize ?? _minimumFontSize;
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      return maximum;
    }

    bool fits(double fontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: style.copyWith(fontSize: fontSize),
        ),
        maxLines: _maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      )..layout(maxWidth: constraints.maxWidth);
      return !painter.didExceedMaxLines &&
          painter.height <= constraints.maxHeight;
    }

    if (fits(maximum)) {
      return maximum;
    }
    if (!fits(_minimumFontSize)) {
      return _minimumFontSize;
    }

    var low = _minimumFontSize;
    var high = maximum;
    for (var i = 0; i < 8; i++) {
      final middle = (low + high) / 2;
      if (fits(middle)) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return low;
  }
}
