import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/learner_level.dart';
import '../models/silben_puzzle.dart';
import '../services/analytics_service.dart';
import '../services/learner_level_selection.dart';
import '../services/silben_puzzle_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// **Silben-Kreuz** — 음절 크로스워드. Wordle식 6줄 보드를 대체한다
/// (Jin 2026-08-11: "줄끼리 연결이 안 보인다" → 단어들이 공유 음절에서
/// 실제로 교차하는 격자 + 음절 타일 배치로 개편).
///
/// - 칸 탭 → 아래 풀에서 음절 탭 → 배치
/// - 정답 칸은 **즉시 녹색 잠김**(교차 단어가 "물리는" 게 보임), 오답은 흔들림
/// - 힌트 = 독일어 뜻 + 독일어 예문 + 정답이 ◯로 가려진 한국어 예문
/// - 진행: 레벨별 20퍼즐, `Storage.recordGameBest('skz_<level>')` 에 저장
class SilbenKreuzScreen extends StatefulWidget {
  const SilbenKreuzScreen({super.key, this.puzzleLoader});

  /// Optional deterministic seam. Production keeps [SilbenPuzzleLoader.load].
  final Future<Map<String, List<SilbenPuzzle>>> Function()? puzzleLoader;

  @override
  State<SilbenKreuzScreen> createState() => _SilbenKreuzScreenState();
}

class _SilbenKreuzScreenState extends State<SilbenKreuzScreen>
    with ScreenCoachMixin<SilbenKreuzScreen> {
  static final _levels = LearnerLevel.values
      .map((level) => level.display)
      .toList(growable: false);
  static const _xpPerPuzzle = 30;

  Map<String, List<SilbenPuzzle>> _byLevel = {};
  bool _loading = true;
  bool _loadFailed = false;

  String _level = 'A1';
  int _index = 0;
  SilbenPuzzle? _puzzle;
  Map<(int, int), String> _solution = {};
  Map<(int, int), List<SilbenWord>> _memberships = const {};
  final Set<(int, int)> _locked = {};
  final Set<String> _spoken = {};
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
    _level = learnerLevelDisplayForStoredCode(Storage.userLevelCode);
    _load();
  }

  Future<void> _load() async {
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
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
        _puzzle = null;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _byLevel = data;
      _loading = false;
      _loadFailed = false;
    });
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

  Future<void> _retryLoad() async {
    if (widget.puzzleLoader == null) {
      SilbenPuzzleLoader.reset();
    }
    await _load();
  }

  void _openLevel(String level) {
    final list = _byLevel[level] ?? const [];
    if (list.isEmpty) {
      return;
    }
    setState(() {
      _level = level;
      _index = math.min(_solvedCount(level), list.length - 1);
    });
    _openPuzzle();
  }

  Future<void> _showLevelFilter(AppL10n t) async {
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level,
      levels: _levels,
      allLabel: t.filterAll,
      countFor: (level) => (_byLevel[level] ?? const []).length,
    );
    if (!mounted || next == null) return;
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
    );
  }

  void _openPuzzle() {
    final p = _puzzles[_index];
    setState(() {
      _puzzle = p;
      _solution = p.solution;
      _memberships = p.memberships;
      _locked.clear();
      _spoken.clear();
      _tileUsed = List.filled(p.pool.length, false);
      _solved = false;
      _selected = null;
      _activeWord = null;
    });
    setState(() {
      _selected = _firstEmpty();
      _activeWord = _selected == null ? null : _wordThrough(_selected!);
    });
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

  void _onCellTap((int, int) cell) {
    if (_solved || _locked.contains(cell)) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selected = cell;
      _activeWord = _wordThrough(cell);
    });
  }

  void _onClueTap(SilbenWord w) {
    for (final c in w.cells) {
      if (!_locked.contains(c)) {
        HapticFeedback.selectionClick();
        setState(() {
          _selected = c;
          _activeWord = w;
        });
        return;
      }
    }
  }

  void _onTileTap(int i) {
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
      HapticFeedback.lightImpact();
      // 방금 잠긴 칸으로 완성된 단어 → 발음 + 정답음 (교차가 "물리는" 순간).
      for (final w in p.words) {
        if (_spoken.contains(w.answer)) {
          continue;
        }
        if (w.cells.every(_locked.contains)) {
          _spoken.add(w.answer);
          SoundService.correct();
          TtsService.speak(
            w.exampleKo.isEmpty
                ? w.answer
                : '${w.answer}. ${w.exampleKoSpoken}',
          );
        }
      }
      if (_locked.length == _solution.length) {
        _onSolved();
      }
    } else {
      HapticFeedback.mediumImpact();
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
    super.dispose();
  }

  void _onSolved() {
    setState(() => _solved = true);
    final done = _solvedCount(_level);
    if (_index + 1 > done) {
      // ignore: discarded_futures
      Storage.recordGameBest(_progressKey(_level), _index + 1);
    }
    // ignore: discarded_futures
    Storage.addXp(_xpPerPuzzle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SoriCelebration.burst(context);
      }
    });
  }

  /// 다음 퍼즐 → 없으면 미완료 레벨로 → 전부 끝이면 null.
  VoidCallback? get _nextAction {
    if (_index + 1 < _puzzles.length) {
      return () {
        setState(() => _index++);
        _openPuzzle();
      };
    }
    for (final l in _levels) {
      final list = _byLevel[l] ?? const [];
      if (list.isNotEmpty && _solvedCount(l) < list.length) {
        return () => _openLevel(l);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    if (_loading) {
      return SoriStudyFrame(
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
        title: t.screenWordleTitle,
        padding: EdgeInsets.zero,
        child: AppError(
          message: t.loadErrorTryAgain,
          onRetry: _retryLoad,
          messageLiveRegion: true,
        ),
      );
    }

    final p = _puzzle;
    return SoriStudyFrame(
      title: t.screenWordleTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_solved && (_locked.isNotEmpty || _wrongTick > 0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      child: p == null
          ? SoriEmptyState(
              icon: Icons.grid_off_rounded,
              title: t.screenWordleTitle,
              body: t.silbenEmptyBody,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _levelChrome(t),
                  const SizedBox(height: Spacing.md),
                  // 섹션 간격 md→lg: 격자·타일풀·힌트가 "다닥다닥" 붙어
                  // 무엇을 하는 화면인지 안 읽혔다(2026-08-12 Jin 실기기).
                  KeyedSubtree(key: _gridKey, child: _grid(p, s)),
                  const SizedBox(height: Spacing.lg),
                  if (!_solved)
                    KeyedSubtree(key: _poolKey, child: _tilePool(p, s)),
                  if (_solved) _solvedCard(t),
                  const SizedBox(height: Spacing.lg),
                  KeyedSubtree(key: _cluesKey, child: _clues(p, s)),
                ],
              ),
            ),
    );
  }

  Widget _grid(SilbenPuzzle p, SoriSurfaces s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // gap 6→10: 셀이 붙어 보여 교차 구조가 안 읽혔다(2026-08-12 Jin).
        const gap = 10.0;
        final cell = math.min(
          52.0,
          (constraints.maxWidth - (p.cols - 1) * gap) / p.cols,
        );
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
            borderRadius: BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w800,
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
        if (memberships.length > 1)
          Positioned.fill(
            child: SilbenCrossingWedges(
              key: ValueKey('silben-crossing-wedges-${cell.$1}-${cell.$2}'),
              directions: directions,
            ),
          ),
      ],
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
          return '$direction: ${word.german}';
        })
        .join('; ');
    final semanticsParts = <String>[
      t.silbenCellPosition(cell.$1 + 1, cell.$2 + 1),
      t.silbenCellMembership(membershipLabel),
      if (inActiveWord) t.silbenCellActiveWord(_activeWord!.german),
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
      onTap: locked ? null : () => _onCellTap(cell),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => _onCellTap(cell),
        child: box,
      ),
    );
  }

  Widget _tilePool(SilbenPuzzle p, SoriSurfaces s) {
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
              onTap: _tileUsed[i] ? null : () => _onTileTap(i),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tileUsed[i] ? null : () => _onTileTap(i),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: s.border),
                  ),
                  child: Text(
                    p.pool[i],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: s.text,
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
    return SoriCard(
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
  }

  Widget _clueRow(SilbenWord w, int declaredIndex, SoriSurfaces s) {
    final done = _spoken.contains(w.answer);
    final active = _activeWord == w;
    final label = done
        ? '${w.answer} · ${w.german}. ${w.exampleDe} ${w.exampleKo}'
        : '${w.german}. ${w.exampleDe} ${w.exampleKo}';
    void onTap() => _onClueTap(w);
    return Semantics(
      key: ValueKey('silben-clue-$declaredIndex'),
      button: true,
      selected: active,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          key: ValueKey('silben-clue-surface-$declaredIndex'),
          duration: SoriMotion.respect(context, SoriMotion.fast),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: active
                ? SoriColors.info.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? SoriColors.info : Colors.transparent,
              width: active ? 1.5 : 0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                w.isHorizontal
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: done
                    ? SoriColors.success
                    : active
                    ? SoriColors.info
                    : SoriColors.accent,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? '${w.answer} · ${w.german}' : w.german,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: done
                            ? SoriColors.success
                            : active
                            ? SoriColors.info
                            : s.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.exampleDe,
                      style: TextStyle(fontSize: 12.5, color: s.textMuted),
                    ),
                    Text(
                      w.exampleKo,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: s.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _solvedCard(AppL10n t) {
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
            Text(
              '${t.wordleResultWin} +$_xpPerPuzzle XP',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SoriColors.success,
              ),
            ),
            const SizedBox(height: Spacing.md),
            if (next != null)
              SoriButton.filled(
                label: t.btnNext,
                icon: Icons.arrow_forward,
                accent: SoriColors.success,
                onTap: next,
                fullWidth: true,
              )
            else
              const Text('🎉', style: TextStyle(fontSize: 28)),
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
