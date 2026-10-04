import '../models/practice_history.dart';
import '../models/silben_practice.dart';
import '../services/practice_history_store.dart';
import '../widgets/practice_dokkaebi_help.dart';
import '../widgets/practice_dokkaebi_art.dart';
import '../widgets/practice_guide.dart';
import '../widgets/practice_motion.dart';
import '../widgets/practice_layout.dart';
import '../widgets/practice_magic.dart';
import '../services/haptic_service.dart';
import '../widgets/sori/game_reward.dart';
import '../services/learning_journey.dart';
import '../models/sori_stage_progression.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/learner_level.dart';
import '../models/silben_puzzle.dart';
import '../services/analytics_service.dart';
import '../services/learner_level_selection.dart';
import '../services/silben_puzzle_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_result_recovery.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';

/// **Silben-Kreuz** — 음절 크로스워드. Wordle식 6줄 보드를 대체한다
/// (Jin 2026-08-11: "줄끼리 연결이 안 보인다" → 단어들이 공유 음절에서
/// 실제로 교차하는 격자 + 음절 타일 배치로 개편).
///
/// - 칸 탭 → 아래 풀에서 음절 탭 → 배치
/// - 정답 칸은 **즉시 녹색 잠김**(교차 단어가 "물리는" 게 보임), 오답은 흔들림
/// - 힌트 = 선택한 UI 언어의 뜻·예문 + 정답이 ◯로 가려진 한국어 예문
/// - 진행: 레벨별 20퍼즐, `Storage.recordGameBest('skz_<level>')` 에 저장
class SilbenKreuzScreen extends StatefulWidget {
  const SilbenKreuzScreen({super.key, this.puzzleLoader, this.review});
  final SilbenReviewRequest? review;

  /// Optional deterministic seam. Production keeps [SilbenPuzzleLoader.load].
  final Future<Map<String, List<SilbenPuzzle>>> Function()? puzzleLoader;

  @override
  State<SilbenKreuzScreen> createState() => _SilbenKreuzScreenState();
}

class _SilbenKreuzScreenState extends State<SilbenKreuzScreen>
    with
        ScreenCoachMixin<SilbenKreuzScreen>,
        GameResultRecovery<SilbenKreuzScreen> {
  static final _levels = LearnerLevel.values
      .map((level) => level.display)
      .toList(growable: false);
  static const _xpPerPuzzle = 30;

  Map<String, List<SilbenPuzzle>> _byLevel = {};
  bool _loading = true;
  bool _loadFailed = false;
  int _loadGeneration = 0;

  String _level = 'A1';
  int _index = 0;
  SilbenPuzzle? _puzzle;
  Map<(int, int), String> _solution = {};
  Map<(int, int), List<SilbenWord>> _memberships = const {};
  final Set<(int, int)> _locked = {};
  final Set<String> _spoken = {};
  // 1.7 잔여(2.9) — 단서 카드 좌상단 인디케이터의 text 를 위해 가장 최근에
  // 완성된 단어를 기억한다. `_spoken`은 완성 여부만 알 뿐 순서를 노출하지
  // 않으므로 별도 필드가 필요하다.
  SilbenWord? _lastCompletedWord;
  List<bool> _tileUsed = [];
  (int, int)? _selected;
  // 사용자가 지금 풀고 있는 단어. 한 칸을 맞힌 뒤 커서를 **이 단어 안에서**
  // 다음 빈 칸으로 옮기려고 둔다.
  //
  // 없던 시절엔 맞힐 때마다 _firstEmpty() 로 갔다. 그건 격자 전체에서 행→열
  // 순 첫 빈 칸이라, 화요일(세로)을 풀던 중에도 커서가 맨 윗줄로 튀었다
  // ("나는 화요일하려는데 칸이 무조건 오른쪽 상단으로 고정돼" — Jin,
  // 2026-08-12 실기기). 십자말 격자가 성글어서 그 첫 칸이 우측 상단처럼 보인다.
  SilbenWord? _activeWord;
  bool _solved = false;
  bool _finishing = false;
  LearningAttempt? _learningAttempt;
  bool _rewardPersisted = false;
  int _presentation = 0;
  final _practiceSession = PracticeHistoryStore.session();
  SilbenHelpState _helpState = SilbenHelpState();
  final _helpAnchor = GlobalKey();
  int _hintGesture = 0, _hintPulse = 0;
  String? _hintWordKey;
  bool _hintPlay = false;
  PracticeAttempt? _historyAttempt;
  bool _practiceFailed = false;
  DateTime? _viewedAt;
  bool _viewedSaved = false;
  bool _viewedFailed = false;
  int _wrongTick = 0;
  (int, int)? _wrongCell;
  Timer? _wrongFeedbackTimer;

  // ── 첫 방문 코치마크 (chosung_quiz_screen 과 동일 패턴) ──
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _cluesKey = GlobalKey();
  final GlobalKey _poolKey = GlobalKey();

  @override
  String get coachId => 'silben_kreuz';

  @override
  bool get coachReady => _puzzle != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _gridKey,
        title: t.coachSilbenStep1Title,
        body: t.coachSilbenStep1Body,
        icon: Icons.grid_4x4_rounded,
      ),
      SpotlightStep(
        targetKey: _cluesKey,
        title: t.coachSilbenStep2Title,
        body: t.coachSilbenStep2Body,
        icon: Icons.menu_book_rounded,
      ),
      SpotlightStep(
        targetKey: _poolKey,
        title: t.coachSilbenStep3Title,
        body: t.coachSilbenStep3Body,
        icon: Icons.touch_app_rounded,
      ),
    ];
  }

  static String _progressKey(String level) => 'skz_${level.toLowerCase()}';

  List<SilbenPuzzle> get _puzzles => _byLevel[_level] ?? const [];

  int _solvedCount(String level) => Storage.gameBest(
    _progressKey(level),
  ).clamp(0, (_byLevel[level] ?? const []).length);

  @override
  void initState() {
    super.initState();
    _level =
        widget.review?.level.toUpperCase() ??
        learnerLevelDisplayForStoredCode(Storage.userLevelCode);
    _load();
  }

  Future<void> _load() async {
    if (!gameResultAcceptsInput ||
        _finishing ||
        (_loading && _loadGeneration > 0)) {
      return;
    }
    final generation = ++_loadGeneration;
    if (!_loading) {
      setState(() {
        _loading = true;
        _loadFailed = false;
        _puzzle = null;
      });
    }
    late final Map<String, List<SilbenPuzzle>> data;
    try {
      data = await (widget.puzzleLoader ?? SilbenPuzzleLoader.load)();
    } catch (_) {
      if (!gameResultAcceptsInput || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
        _puzzle = null;
      });
      return;
    }
    if (!gameResultAcceptsInput || generation != _loadGeneration) {
      return;
    }
    setState(() {
      _byLevel = data;
      _loading = false;
      _loadFailed = false;
    });
    if (widget.review case final review?) {
      if (review.revision != 1 ||
          !(_byLevel[review.level.toUpperCase()]?.any(
                (p) => p.id == review.puzzleId,
              ) ??
              false)) {
        setState(() {
          _loadFailed = true;
          _puzzle = null;
        });
        return;
      }
    }
    final resolvedLevel = (_byLevel[_level]?.isNotEmpty ?? false)
        ? _level
        : _levels.reversed.firstWhere(
            (candidate) => _byLevel[candidate]?.isNotEmpty ?? false,
            orElse: () => 'A1',
          );
    _openLevel(resolvedLevel);
    if (_puzzle != null) {
      unawaited(Analytics.gameStarted(gameType: 'silben_kreuz', level: _level));
    }
  }

  Future<void> _retryLoad(int generation) async {
    if (!gameResultAcceptsInput ||
        _finishing ||
        generation != _loadGeneration ||
        _loading ||
        !_loadFailed) {
      return;
    }
    if (widget.puzzleLoader == null) {
      SilbenPuzzleLoader.reset();
    }
    await _load();
  }

  void _openLevel(String level) {
    if (!gameResultAcceptsInput || _finishing) return;
    final list = _byLevel[level] ?? const [];
    if (list.isEmpty) {
      return;
    }
    setState(() {
      _level = level;
      _index = widget.review == null
          ? math.min(_solvedCount(level), list.length - 1)
          : list.indexWhere((p) => p.id == widget.review!.puzzleId);
    });
    _openPuzzle();
  }

  Future<void> _showLevelFilter(AppL10n t) async {
    if (widget.review != null) {
      return;
    }
    final presentation = _presentation;
    if (!gameResultAcceptsInput || _finishing) return;
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level,
      levels: _levels,
      allLabel: t.filterAll,
      countFor: (level) => (_byLevel[level] ?? const []).length,
    );
    if (!gameResultAcceptsInput ||
        _finishing ||
        presentation != _presentation ||
        next == null) {
      return;
    }
    _openLevel(next);
  }

  Widget _levelChrome(AppL10n t) {
    final total = (_byLevel[_level] ?? const []).length;
    return SoriChromeRow(
      onFilterTap: () => _showLevelFilter(t),
      filterSemanticLabel: t.filterLevel,
      meta: Text(
        '$_level · ${_solvedCount(_level)}/$total',
        style: SoriTextTheme.of(context).meta,
      ),
      trailing: const TtsSpeedAction(),
    );
  }

  void _openPuzzle() {
    resetGameResult();
    _presentation++;
    _finishing = false;
    _learningAttempt = null;
    _rewardPersisted = false;
    _helpState = SilbenHelpState();
    _hintPulse = 0;
    _hintPlay = false;
    _hintWordKey = null;
    _historyAttempt = null;
    _practiceFailed = false;
    _viewedAt = DateTime.now().toUtc();
    _viewedSaved = false;
    _viewedFailed = false;
    final p = _puzzles[_index];
    setState(() {
      _puzzle = p;
      _solution = p.solution;
      _memberships = p.memberships;
      _locked.clear();
      _spoken.clear();
      _lastCompletedWord = null;
      _tileUsed = List.filled(p.pool.length, false);
      _solved = false;
      _selected = null;
      _activeWord = null;
    });
    setState(() {
      _selected = _firstEmpty();
      _activeWord = _selected == null ? null : _wordThrough(_selected!);
    });
    unawaited(_saveViewed(_presentation).catchError((Object _) {}));
  }

  Future<void> _saveViewed(int presentation) async {
    if (!mounted ||
        presentation != _presentation ||
        !_practiceSession.isCurrent) {
      return;
    }
    if (_viewedSaved) {
      return;
    }
    final source = silbenPracticeSource(_puzzle!, _level);
    final viewedAt = _viewedAt!;
    try {
      await PracticeHistoryStore.recordViewed(
        source,
        at: viewedAt,
        session: _practiceSession,
      );
      if (mounted &&
          presentation == _presentation &&
          _practiceSession.isCurrent) {
        setState(() {
          _viewedSaved = true;
          _viewedFailed = false;
        });
      }
    } catch (_) {
      if (mounted &&
          presentation == _presentation &&
          _practiceSession.isCurrent) {
        setState(() => _viewedFailed = true);
      }
      rethrow;
    }
  }

  List<(int, int)> get _cellOrder {
    final cells = _solution.keys.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return cells;
  }

  (int, int)? _firstEmpty() {
    for (final c in _cellOrder) {
      if (!_locked.contains(c)) {
        return c;
      }
    }
    return null;
  }

  /// [cell] 을 지나는 단어 중 아직 빈 칸이 남은 것. 교차점에서 방향이 제멋대로
  /// 바뀌지 않도록, 현재 단어가 그 칸을 포함하면 현재 단어를 유지한다.
  SilbenWord? _wordThrough((int, int) cell) {
    final current = _activeWord;
    final memberships = _memberships[cell] ?? const <SilbenWord>[];
    if (current != null && memberships.contains(current)) {
      return current;
    }
    for (final w in memberships) {
      if (w.cells.any((c) => !_locked.contains(c))) {
        return w;
      }
    }
    return null;
  }

  /// 현재 단어에서 아직 안 채운 첫 칸. 단어가 끝났으면 null.
  (int, int)? _nextInActiveWord() {
    for (final c in _activeWord?.cells ?? const <(int, int)>[]) {
      if (!_locked.contains(c)) {
        return c;
      }
    }
    return null;
  }

  void _onCellTap((int, int) cell, int presentation) {
    if (!gameResultAcceptsInput ||
        _finishing ||
        presentation != _presentation) {
      return;
    }
    if (_solved || _locked.contains(cell)) {
      return;
    }
    HapticService.selectionClick();
    setState(() {
      _selected = cell;
      _activeWord = _wordThrough(cell);
    });
  }

  void _onClueTap(SilbenWord w, int presentation) {
    if (!gameResultAcceptsInput ||
        _finishing ||
        presentation != _presentation) {
      return;
    }
    for (final c in w.cells) {
      if (!_locked.contains(c)) {
        HapticService.selectionClick();
        setState(() {
          _selected = c;
          _activeWord = w;
        });
        return;
      }
    }
  }

  /// 완성된 단어를 발음할 때 쓰는 텍스트 — exampleKo 가 있으면 답+예문,
  /// 없으면 답만. 완성 시 자동 발화(_onTileTap)와 단서 카드 좌상단
  /// 인디케이터(_clues)가 같은 규칙을 공유해야 인디케이터 탭=정지가
  /// 실제로 그 발화를 멈춘다(같은 텍스트 → 같은 SoriSpeech in-flight 키).
  String _speechFor(SilbenWord w) =>
      w.exampleKo.isEmpty ? w.answer : '${w.answer}. ${w.exampleKoSpoken}';

  void _onTileTap(int i, int presentation) {
    if (!gameResultAcceptsInput ||
        _finishing ||
        presentation != _presentation) {
      return;
    }
    if (_solved || _tileUsed[i]) {
      return;
    }
    final sel = _selected ?? _firstEmpty();
    if (sel == null) {
      return;
    }
    final p = _puzzle!;
    if (p.pool[i] == _solution[sel]) {
      _wrongFeedbackTimer?.cancel();
      setState(() {
        _wrongCell = null;
        _locked.add(sel);
        _tileUsed[i] = true;
        // 풀던 단어 안에서 다음 빈 칸으로. 그 단어를 다 채웠을 때만 격자 전체의
        // 첫 빈 칸으로 넘어간다 — 이게 없으면 커서가 매번 맨 윗줄로 튄다.
        _selected = _nextInActiveWord() ?? _firstEmpty();
        _activeWord = _selected == null ? null : _wordThrough(_selected!);
      });
      HapticService.lightImpact();
      // 방금 잠긴 칸으로 완성된 단어 → 발음 + 정답음 (교차가 "물리는" 순간).
      for (final w in p.words) {
        if (_spoken.contains(w.answer)) {
          continue;
        }
        if (w.cells.every(_locked.contains)) {
          _spoken.add(w.answer);
          _lastCompletedWord = w;
          SoundService.correct();
          SoriSpeech.speak(_speechFor(w));
        }
      }
      if (_locked.length == _solution.length) {
        _onSolved();
      }
    } else {
      HapticService.mediumImpact();
      _wrongFeedbackTimer?.cancel();
      setState(() {
        _selected = sel;
        _wrongCell = sel;
        _wrongTick++;
      });
      _wrongFeedbackTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _wrongCell == sel) {
          setState(() => _wrongCell = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _wrongFeedbackTimer?.cancel();
    SoriSpeech.stop();
    super.dispose();
  }

  Future<void> _onSolved() async {
    if (!gameResultAcceptsInput ||
        _finishing ||
        _solved ||
        !_practiceSession.isCurrent) {
      return;
    }
    _finishing = true;
    final presentation = _presentation;
    final at = DateTime.now().toUtc();
    _historyAttempt ??= PracticeAttempt(
      id: 'silben:${at.microsecondsSinceEpoch}',
      at: at,
      variant: widget.review == null ? 'game' : 'replay',
      completed: true,
      hints: Map.unmodifiable(_helpState.levels),
    );
    try {
      await _saveViewed(presentation);
      if (!mounted ||
          presentation != _presentation ||
          !_practiceSession.isCurrent) {
        return;
      }
      await PracticeHistoryStore.recordAttempt(
        silbenPracticeSource(_puzzle!, _level),
        _historyAttempt!,
        session: _practiceSession,
      );
      if (!mounted ||
          presentation != _presentation ||
          !_practiceSession.isCurrent) {
        return;
      }
      setState(() => _practiceFailed = false);
    } catch (_) {
      if (mounted && presentation == _presentation) {
        setState(() {
          _practiceFailed = true;
          _finishing = false;
        });
      }
      return;
    }
    if (widget.review == null) {
      final outcome = await saveGameResult(
        gameId: _progressKey(_level),
        xp: _xpPerPuzzle,
        score: _index + 1,
      );
      if (!mounted ||
          outcome == null ||
          presentation != _presentation ||
          !_practiceSession.isCurrent) {
        return;
      }
      _learningAttempt = outcome.attempt;
      _rewardPersisted = true;
    }
    if (!mounted || !gameResultAcceptsInput) {
      return;
    }
    setState(() {
      _solved = true;
      _finishing = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (gameResultAcceptsInput && _solved) {
        SoriCelebration.burst(context);
      }
    });
  }

  void _requestHint(int presentation) {
    final word = _activeWord;
    final p = _puzzle;
    final cell = _selected;
    if (!gameResultAcceptsInput ||
        _finishing ||
        _solved ||
        presentation != _presentation ||
        word == null ||
        p == null ||
        cell == null ||
        !_practiceSession.isCurrent) {
      return;
    }
    final next = (_helpState.levelFor(word) + 1).clamp(1, 3);
    setState(() {
      _helpState.use(p, word, next, cell: cell);
      _hintPulse = 0;
      _hintPlay = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final anchor = _helpAnchor.currentContext;
      if (!mounted ||
          anchor == null ||
          _solved ||
          _finishing ||
          presentation != _presentation ||
          word != _activeWord ||
          !_practiceSession.isCurrent) {
        return;
      }
      await Scrollable.ensureVisible(
        anchor,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: Storage.reducedMotion
            ? Duration.zero
            : SoriMotion.respect(context, SoriMotion.medium),
      );
      if (!mounted ||
          _solved ||
          _finishing ||
          presentation != _presentation ||
          word != _activeWord ||
          !_practiceSession.isCurrent) {
        return;
      }
      setState(() {
        _hintGesture++;
        _hintWordKey = silbenWordOccurrence(word);
        _hintPlay = true;
      });
    });
  }

  Widget _helpPanel(AppL10n t) {
    final word = _activeWord;
    if (word == null) {
      return const SizedBox.shrink();
    }
    final level = _helpState.levelFor(word);
    final presentation = _presentation;
    final crossings = _helpState.crossingCells(_puzzle!, word);
    final reveal = _helpState.revealedCell;
    final occurrence = silbenWordOccurrence(word);
    final pulse = _hintWordKey == occurrence ? _hintPulse : 0;
    final example = word.exampleFor(_hintLanguage);
    return PracticeDokkaebiHelp(
      key: ValueKey('dokkaebi-help-$presentation-$occurrence'),
      compact: level == 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (level == 1) ...[
            PracticeHintEmphasis(
              pulse: pulse,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.practiceHintWordPath(
                        word.cells.length,
                        word.row + 1,
                        word.col + 1,
                      ),
                      key: const ValueKey('dokkaebi-word-path'),
                      style: SoriTextTheme.of(context).meta,
                    ),
                    // Unmasked inflected examples can disclose the answer. Show
                    // those after completion, rather than as a light hint.
                    if (word.exampleKo.contains('◯')) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        word.exampleKo,
                        key: const ValueKey('dokkaebi-sentence-clue'),
                        style: SoriTextTheme.of(context).h3,
                      ),
                    ],
                    if (example.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(example, style: SoriTextTheme.of(context).bodySmall),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (level == 2) ...[
            if (crossings.isEmpty)
              Text(
                t.practiceHintNoCrossing,
                style: SoriTextTheme.of(context).bodySmall,
              ),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final cell in crossings)
                  PracticeHintEmphasis(
                    pulse: pulse,
                    child: IntrinsicWidth(
                      child: PracticeRaisedAction(
                        child: SoriButton.outlined(
                          key: ValueKey('dokkaebi-cross-${cell.$1}-${cell.$2}'),
                          label: t.silbenCellPosition(cell.$1 + 1, cell.$2 + 1),
                          onTap: _locked.contains(cell)
                              ? null
                              : () => _onCellTap(cell, presentation),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (level == 3 &&
              reveal != null &&
              word.cells.contains(reveal) &&
              !_locked.contains(reveal)) ...[
            PracticeHintEmphasis(
              pulse: pulse,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${t.silbenCellPosition(reveal.$1 + 1, reveal.$2 + 1)}: ${_solution[reveal]}',
                  key: const ValueKey('dokkaebi-revealed'),
                  style: SoriTextTheme.of(context).h2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.practiceHintPlace,
              style: SoriTextTheme.of(context).bodySmall,
            ),
            const SizedBox(height: Spacing.md),
          ],
          PracticeRaisedAction(
            child: SoriButton.outlined(
              key: const ValueKey('dokkaebi-hint'),
              label: level == 0
                  ? t.practiceHintMeaning
                  : level == 1
                  ? t.practiceHintCrossing
                  : t.practiceHintReveal,
              fullWidth: true,
              onTap:
                  _finishing || _selected == null || _locked.contains(_selected)
                  ? null
                  : () => _requestHint(presentation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _puzzleBoard(SilbenPuzzle p, SoriSurfaces s, AppL10n t) {
    final word = _activeWord;
    final occurrence = word == null ? null : silbenWordOccurrence(word);
    final gesture = _hintGesture;
    final presentation = _presentation;
    return KeyedSubtree(
      key: _helpAnchor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final minGrid = p.cols * 48.0 + (p.cols - 1) * Spacing.xs;
          final sideBySide = width - minGrid - 32 >= 104;
          final stageSize = sideBySide
              ? (width - minGrid - 32).clamp(104.0, 176.0)
              : 144.0;
          final gridWidth = sideBySide ? width - stageSize - 32 : width - 32;
          final metrics = _gridMetrics(p, gridWidth);
          final gridHeight = metrics.cell * p.rows + metrics.gap * (p.rows - 1);
          final panelHeight = gridHeight + 32;
          final panelLeft = sideBySide ? stageSize * .838 - 24 : 0.0;
          final panelTop = sideBySide
              ? math.max(0.0, stageSize * .921 - panelHeight)
              : stageSize * .921;
          final contactY = sideBySide ? panelTop + panelHeight : panelTop;
          final stageTop = contactY - stageSize * .921;
          // The clip stays intact. Its contact point meets the card ledge;
          // its full opaque video rectangle never covers an interactive cell.
          final stage = PracticeDokkaebiStage(
            key: ValueKey('dokkaebi-board-$presentation-$occurrence'),
            size: stageSize,
            requestId: gesture,
            play: !_solved && _hintPlay && _hintWordKey == occurrence,
            helping: word != null && _helpState.levelFor(word) > 0,
            onRequested: () {
              if (mounted && gesture == _hintGesture && _hintPlay) {
                setState(() => _hintPlay = false);
              }
            },
            onImpact: () {
              if (mounted &&
                  !_solved &&
                  !_finishing &&
                  _practiceSession.isCurrent &&
                  presentation == _presentation &&
                  word == _activeWord &&
                  gesture == _hintGesture) {
                setState(() => _hintPulse = gesture);
              }
            },
          );
          return PracticeMagicFrame(
            pulse: _hintPulse,
            child: SoriCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: math.max(
                      panelTop + panelHeight,
                      stageTop + stageSize,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: panelLeft,
                          right: 0,
                          top: panelTop,
                          child: SoriCard(
                            padding: EdgeInsets.fromLTRB(
                              sideBySide ? stageSize - panelLeft + 16 : 16,
                              16,
                              16,
                              16,
                            ),
                            child: KeyedSubtree(
                              key: _gridKey,
                              child: _grid(p, s),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: stageTop,
                          child: IgnorePointer(child: stage),
                        ),
                        Positioned(
                          left: panelLeft + 16,
                          right: 16,
                          top: contactY,
                          child: IgnorePointer(
                            child: SizedBox(
                              key: const ValueKey('dokkaebi-board-ledge'),
                              height: 3,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: s.border,
                                  borderRadius: BorderRadius.circular(
                                    SoriRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_solved) _helpPanel(t),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ({double cell, double gap}) _gridMetrics(SilbenPuzzle p, double width) {
    const maxGap = 10.0;
    const minCell = 48.0;
    final maxCell = width >= SoriAdaptiveWidth.crosswordLargeCells
        ? 96.0
        : 52.0;
    double cellFor(double gap) =>
        math.min(maxCell, (width - (p.cols - 1) * gap) / p.cols);
    var gap = maxGap;
    var cell = cellFor(gap);
    if (cell < minCell) {
      final cellNoGap = math.min(maxCell, width / p.cols);
      if (cellNoGap >= minCell && p.cols > 1) {
        gap = ((width - minCell * p.cols) / (p.cols - 1)).clamp(0.0, maxGap);
        cell = cellFor(gap);
      } else {
        gap = 0;
        cell = cellNoGap;
      }
    }
    return (cell: cell, gap: gap);
  }

  /// 다음 퍼즐 → 없으면 미완료 레벨로 → 전부 끝이면 null.
  VoidCallback? get _nextAction {
    if (widget.review != null) {
      return null;
    }
    final presentation = _presentation;
    if (_index + 1 < _puzzles.length) {
      return () {
        if (!gameResultAcceptsInput ||
            !_solved ||
            presentation != _presentation) {
          return;
        }
        setState(() => _index++);
        _openPuzzle();
      };
    }
    for (final l in _levels) {
      final list = _byLevel[l] ?? const [];
      if (list.isNotEmpty && _solvedCount(l) < list.length) {
        return () {
          if (!gameResultAcceptsInput ||
              !_solved ||
              presentation != _presentation) {
            return;
          }
          _finishing = false;
          _openLevel(l);
        };
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final generation = _loadGeneration;
    final recovery = gameResultRecoveryFrame(t.screenWordleTitle);
    if (recovery != null) return recovery;
    final s = SoriSurfaces.of(context);
    if (_practiceFailed) {
      return SoriStudyFrame(
        title: t.screenWordleTitle,
        onLeave: retireGameResult,
        child: AppError(message: t.practiceSaveFailed, onRetry: _onSolved),
      );
    }
    if (_viewedFailed) {
      final presentation = _presentation;
      return SoriStudyFrame(
        title: t.screenWordleTitle,
        onLeave: retireGameResult,
        child: AppError(
          message: t.practiceSaveFailed,
          onRetry: () {
            unawaited(_saveViewed(presentation).catchError((Object _) {}));
          },
        ),
      );
    }

    if (_loading) {
      return SoriStudyFrame(
        onLeave: retireGameResult,
        title: t.screenWordleTitle,
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
        onLeave: retireGameResult,
        title: t.screenWordleTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: t.loadErrorTryAgain,
          onRetry: () => _retryLoad(generation),
          messageLiveRegion: true,
        ),
      );
    }

    final p = _puzzle;
    return SoriStudyFrame(
      onLeave: retireGameResult,
      title: t.screenWordleTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_solved && (_locked.isNotEmpty || _wrongTick > 0),
      ),
      adaptTitleAtNormalScale: true,
      actions: const [PracticeDokkaebiFireAction()],
      padding: EdgeInsets.zero,
      child: p == null
          ? SoriEmptyState(
              icon: Icons.grid_off_rounded,
              title: t.screenWordleTitle,
              body: t.silbenEmptyBody,
            )
          // W10 T-V3(2026-09-05, Jin D-4): 판+풀+힌트가 560dp 안팎이라
          // 태블릿 세로 화면에서 위쪽에 뭉쳤다. `_grid()` 안에 격자 셀
          // 크기를 재는 `LayoutBuilder` 가 있어 `SoriAdaptiveStudyBody`
          // (fillViewport)의 IntrinsicHeight 측정과 함께 못 쓴다
          // ("LayoutBuilder does not support returning intrinsic
          // dimensions") — `SoriMinHeightScroll(intrinsic: false)` 로
          // IntrinsicHeight 없이 채운다(W10 PR-D, 손레시피 공용화).
          : SoriMinHeightScroll(
              minHeight: 0,
              fillViewport: true,
              intrinsic: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _levelChrome(t),
                    const SizedBox(height: Spacing.md),
                    // 섹션 간격 md→lg: 격자·타일풀·힌트가 "다닥다닥"
                    // 붙어 무엇을 하는 화면인지 안 읽혔다(2026-08-12
                    // Jin 실기기).
                    if (!_solved) ...[
                      KeyedSubtree(key: _cluesKey, child: _clues(p, s)),
                      const SizedBox(height: Spacing.lg),
                    ],
                    _puzzleBoard(p, s, t),
                    const SizedBox(height: Spacing.lg),
                    if (!_solved) ...[
                      KeyedSubtree(key: _poolKey, child: _tilePool(p, s)),
                    ],
                    if (_solved)
                      PracticeMotionSurface(enter: true, child: _solvedCard(t)),
                    const SizedBox(height: Spacing.xl),
                    if (_solved)
                      KeyedSubtree(key: _cluesKey, child: _clues(p, s)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _grid(SilbenPuzzle p, SoriSurfaces s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _gridMetrics(p, constraints.maxWidth);
        final gap = metrics.gap;
        final cell = metrics.cell;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < p.rows; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < p.cols; c++)
                        Padding(
                          padding: EdgeInsets.only(left: c == 0 ? 0 : gap),
                          child: _cellBox((r, c), cell, s),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cellBox((int, int) cell, double size, SoriSurfaces s) {
    final presentation = _presentation;
    final syllable = _solution[cell];
    if (syllable == null) {
      return SizedBox(width: size, height: size);
    }
    final memberships = _memberships[cell] ?? const <SilbenWord>[];
    final locked = _locked.contains(cell);
    final selected = _selected == cell;
    final wrong = _wrongCell == cell;
    final inActiveWord =
        _activeWord != null && memberships.contains(_activeWord);
    final helpCrossing =
        _activeWord != null &&
        _helpState.levelFor(_activeWord!) >= 2 &&
        _helpState.crossingCells(_puzzle!, _activeWord!).contains(cell);
    final reduceMotion = SoriMotion.reduceMotion(context);
    final directions = <String>[];
    for (final word in memberships) {
      if (!directions.contains(word.dir)) {
        directions.add(word.dir);
      }
    }

    Widget box = Stack(
      children: [
        AnimatedContainer(
          key: ValueKey('silben-cell-surface-${cell.$1}-${cell.$2}'),
          duration: SoriMotion.respect(context, SoriMotion.fast),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: locked
                ? SoriColors.success.withValues(alpha: 0.16)
                : selected
                ? SoriColors.info.withValues(alpha: 0.10)
                : inActiveWord
                ? SoriColors.info.withValues(alpha: 0.06)
                : s.surfaceAlt,
            borderRadius: BorderRadius.circular(SoriRadius.sm),
            border: Border.all(
              color: locked
                  ? SoriColors.success
                  : selected
                  ? SoriColors.info
                  : s.border,
              width: locked
                  ? 1.8
                  : selected
                  ? 2
                  : 1,
            ),
          ),
          child: locked
              ? Text(
                  syllable,
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.w700,
                    color: SoriColors.success,
                  ),
                )
              : wrong
              ? const Icon(
                  Icons.close_rounded,
                  color: SoriColors.danger,
                  size: 24,
                )
              : null,
        ),
        if (helpCrossing && !locked)
          Positioned(
            right: 4,
            bottom: 4,
            child: Icon(
              Icons.add_rounded,
              key: ValueKey('silben-help-cross-${cell.$1}-${cell.$2}'),
              size: 16,
              color: SoriColors.info,
            ),
          ),
        if (memberships.length > 1)
          Positioned.fill(
            child: SilbenCrossingWedges(
              key: ValueKey('silben-crossing-wedges-${cell.$1}-${cell.$2}'),
              directions: directions,
            ),
          ),
      ],
    );

    final hintLevel = _activeWord == null
        ? 0
        : _helpState.levelFor(_activeWord!);
    final currentPulse =
        _activeWord != null &&
        _hintWordKey == silbenWordOccurrence(_activeWord!) &&
        !locked &&
        (hintLevel == 1 && inActiveWord ||
            hintLevel == 2 && helpCrossing ||
            hintLevel == 3 && _helpState.revealedCell == cell);
    box = PracticeHintEmphasis(
      pulse: currentPulse ? _hintPulse : 0,
      child: box,
    );

    if (selected && wrong && !reduceMotion) {
      // 오답 흔들림 — _wrongTick 이 바뀔 때마다 좌우 스냅.
      box = TweenAnimationBuilder<double>(
        key: ValueKey(_wrongTick),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        builder: (_, v, child) => Transform.translate(
          offset: Offset(math.sin(v * math.pi * 4) * 4 * (1 - v), 0),
          child: child,
        ),
        child: box,
      );
    }
    final t = AppL10n.of(context);
    final membershipLabel = memberships
        .map((word) {
          final direction = word.isHorizontal
              ? t.silbenDirectionHorizontal
              : t.silbenDirectionVertical;
          return '$direction: ${word.meaningFor(_hintLanguage)}';
        })
        .join('; ');
    final semanticsParts = <String>[
      t.silbenCellPosition(cell.$1 + 1, cell.$2 + 1),
      t.silbenCellMembership(membershipLabel),
      if (inActiveWord)
        t.silbenCellActiveWord(_activeWord!.meaningFor(_hintLanguage)),
      if (helpCrossing) t.practiceHintCrossing,
      if (_helpState.revealedCell == cell) t.wordleAnswerLabel(syllable),
      if (locked) t.wordleAnswerLabel(syllable),
      if (wrong)
        t.silbenCellWrong
      else if (locked)
        t.silbenCellCorrect
      else
        t.silbenCellOpen,
    ];
    return Semantics(
      key: ValueKey('silben-cell-${cell.$1}-${cell.$2}'),
      button: true,
      enabled: !locked,
      selected: selected,
      label: '${semanticsParts.join('. ')}.',
      onTap: locked ? null : () => _onCellTap(cell, presentation),
      excludeSemantics: true,
      child: SoriPressable(
        pressScale: 1,
        haptic: null,
        onTap: locked ? null : () => _onCellTap(cell, presentation),
        child: box,
      ),
    );
  }

  Widget _tilePool(SilbenPuzzle p, SoriSurfaces s) {
    final presentation = _presentation;
    return Wrap(
      alignment: WrapAlignment.center,
      // 8→12: 음절 타일이 다닥다닥 붙어 낱개 선택지로 안 보였다.
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < p.pool.length; i++)
          AnimatedOpacity(
            duration: SoriMotion.respect(context, SoriMotion.fast),
            opacity: _tileUsed[i] ? 0.18 : 1,
            child: Semantics(
              button: true,
              enabled: !_tileUsed[i],
              label: p.pool[i],
              onTap: _tileUsed[i] ? null : () => _onTileTap(i, presentation),
              excludeSemantics: true,
              child: PracticeMotionSurface(
                interactive: false,
                child: SoriPressable(
                  pressScale: .99,
                  surfaceDepth: _tileUsed[i] ? 0 : 3,
                  surfaceRadius: SoriRadius.sm,
                  surfaceEdgeColor: s.border,
                  tactileTilt: true,
                  haptic: null,
                  onTap: _tileUsed[i]
                      ? null
                      : () => _onTileTap(i, presentation),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.surface,
                      borderRadius: BorderRadius.circular(SoriRadius.sm),
                      border: Border.all(color: s.border),
                    ),
                    child: Text(
                      p.pool[i],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: s.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _clues(SilbenPuzzle p, SoriSurfaces s) {
    final words =
        [for (var i = 0; i < p.words.length; i++) (index: i, word: p.words[i])]
          ..sort(
            (a, b) => a.word.row != b.word.row
                ? a.word.row - b.word.row
                : a.word.col - b.word.col,
          );
    if (!_solved) {
      return LayoutBuilder(
        key: const ValueKey('silben-compact-clues'),
        builder: (context, constraints) => Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            if (_lastCompletedWord case final completed?)
              SoriSpeechIndicator(
                key: const Key('silben-clue-speak'),
                text: _speechFor(completed),
              ),
            for (final entry in words)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: IntrinsicWidth(
                  child: _clueRow(entry.word, entry.index, s),
                ),
              ),
          ],
        ),
      );
    }
    final card = SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < words.length; i++) ...[
            if (i > 0) Divider(height: Spacing.lg, color: s.border),
            _clueRow(words[i].word, words[i].index, s),
          ],
        ],
      ),
    );
    // 1.7 잔여(2.9) — 완성된 단어가 1개 이상일 때만 좌상단 듣기 아이콘을
    // 얹는다. 미완성 상태(0개)엔 재생할 음성이 아직 없으므로 인디케이터
    // 자체를 넣지 않는다.
    final lastCompleted = _lastCompletedWord;
    if (_spoken.isEmpty || lastCompleted == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: Spacing.sm,
          left: Spacing.sm,
          child: SoriSpeechIndicator(
            key: const Key('silben-clue-speak'),
            text: _speechFor(lastCompleted),
          ),
        ),
      ],
    );
  }

  Widget _clueRow(SilbenWord w, int declaredIndex, SoriSurfaces s) {
    final presentation = _presentation;
    final done = _spoken.contains(w.answer);
    final active = _activeWord == w;
    final meaning = w.meaningFor(_hintLanguage);
    final localizedExample = w.exampleFor(_hintLanguage);
    final label = done && _solved
        ? '${w.answer} · $meaning. $localizedExample ${w.exampleKo}'
        : done
        ? '${w.answer} · $meaning'
        : meaning;
    void onTap() => _onClueTap(w, presentation);
    return Semantics(
      key: ValueKey('silben-clue-$declaredIndex'),
      button: true,
      enabled: !done,
      selected: active,
      label: label,
      onTap: done ? null : onTap,
      excludeSemantics: true,
      child: PracticeMotionSurface(
        interactive: false,
        child: SoriPressable(
          pressScale: .99,
          surfaceDepth: done ? 0 : 3,
          surfaceRadius: SoriRadius.md,
          surfaceEdgeColor: s.border,
          tactileTilt: true,
          haptic: null,
          onTap: done ? null : onTap,
          child: AnimatedContainer(
            key: ValueKey('silben-clue-surface-$declaredIndex'),
            duration: SoriMotion.respect(context, SoriMotion.fast),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: active
                  ? SoriColors.info.withValues(alpha: .10)
                  : SoriCard.resolvedBackground(context),
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(
                color: active ? SoriColors.info : s.border,
                width: active ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: s.border, offset: const Offset(0, Spacing.xs)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  done
                      ? Icons.check_circle_outline_rounded
                      : w.isHorizontal
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: done
                      ? SoriColors.success
                      : active
                      ? SoriColors.info
                      : SoriColors.accent,
                ),
                const SizedBox(width: Spacing.sm),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? '${w.answer} · $meaning' : meaning,
                        style: SoriTextTheme.of(context).label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: done ? SoriColors.success : s.text,
                        ),
                      ),
                      if (done && _solved) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          localizedExample,
                          style: SoriTextTheme.of(context).caption,
                        ),
                        Text(
                          w.exampleKo,
                          style: SoriTextTheme.of(context).caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _hintLanguage => Localizations.localeOf(context).languageCode;

  Widget _solvedCard(AppL10n t) {
    if (widget.review != null) {
      return SoriCard(
        child: Column(
          children: [
            PracticeGuide(
              dokkaebi: true,
              dokkaebiPose: PracticeDokkaebiPose.celebrate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.practiceReplaySaved,
                    style: SoriTextTheme.of(context).h2,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    _helpState.levels.isEmpty
                        ? t.practiceIndependent
                        : t.practiceAssisted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            PracticeRaisedAction(
              child: SoriButton.outlined(
                label: t.practiceHistoryOpen,
                onTap: () => Navigator.of(context).pushNamed('/hanok/practice'),
              ),
            ),
          ],
        ),
      );
    }
    final next = _nextAction;
    return Semantics(
      container: true,
      liveRegion: true,
      label: t.wordleResultWin,
      child: SoriCard(
        accent: SoriColors.success,
        tinted: true,
        child: Column(
          children: [
            PracticeGuide(
              dokkaebi: true,
              dokkaebiPose: PracticeDokkaebiPose.celebrate,
              child: LearningRewardPresentation(
                attempt: _learningAttempt,
                kind: SoriRewardKind.xp,
                amount: _xpPerPuzzle,
                presentationComplete: _rewardPersisted,
                child: Text(
                  _rewardPersisted
                      ? '${t.wordleResultWin} +$_xpPerPuzzle XP'
                      : t.wordleResultWin,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SoriColors.success,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            if (next != null)
              PracticeRaisedAction(
                primary: true,
                child: SoriButton.filled(
                  label: t.btnNext,
                  accent: SoriColors.success,
                  onTap: next,
                  fullWidth: true,
                ),
              )
            else
              const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(height: Spacing.md),
            PracticeRaisedAction(
              child: SoriButton.outlined(
                label: t.practiceToSarangbang,
                fullWidth: true,
                onTap: () => Navigator.of(context).pushNamed('/sarangbang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-color crossing cue: horizontal and vertical memberships use wedges
/// with different geometry at opposite corners of the cell.
class SilbenCrossingWedges extends StatelessWidget {
  SilbenCrossingWedges({super.key, required Iterable<String> directions})
    : directions = List<String>.unmodifiable(directions);

  final List<String> directions;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _SilbenCrossingWedgePainter(
        horizontal: directions.contains('h'),
        vertical: directions.contains('v'),
      ),
    ),
  );
}

class _SilbenCrossingWedgePainter extends CustomPainter {
  const _SilbenCrossingWedgePainter({
    required this.horizontal,
    required this.vertical,
  });

  final bool horizontal;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoriColors.info.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    if (horizontal) {
      final horizontalWidth = math.min(18.0, size.width * 0.38);
      final horizontalDepth = math.min(8.0, size.height * 0.18);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(horizontalWidth, 0)
          ..lineTo(0, horizontalDepth)
          ..close(),
        paint,
      );
    }
    if (vertical) {
      final verticalHeight = math.min(18.0, size.height * 0.38);
      final verticalDepth = math.min(8.0, size.width * 0.18);
      canvas.drawPath(
        Path()
          ..moveTo(size.width, size.height)
          ..lineTo(size.width, size.height - verticalHeight)
          ..lineTo(size.width - verticalDepth, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SilbenCrossingWedgePainter oldDelegate) =>
      horizontal != oldDelegate.horizontal || vertical != oldDelegate.vertical;
}
