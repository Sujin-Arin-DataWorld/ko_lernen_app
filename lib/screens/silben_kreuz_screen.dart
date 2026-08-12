import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/silben_puzzle.dart';
import '../services/silben_puzzle_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// **Silben-Kreuz** — 음절 크로스워드. Wordle식 6줄 보드를 대체한다
/// (Jin 2026-08-11: "줄끼리 연결이 안 보인다" → 단어들이 공유 음절에서
/// 실제로 교차하는 격자 + 음절 타일 배치로 개편).
///
/// - 칸 탭 → 아래 풀에서 음절 탭 → 배치
/// - 정답 칸은 **즉시 녹색 잠김**(교차 단어가 "물리는" 게 보임), 오답은 흔들림
/// - 힌트 = 독일어 뜻 + 독일어 예문 + 정답이 ◯로 가려진 한국어 예문
/// - 진행: 레벨별 20퍼즐, `Storage.recordGameBest('skz_<level>')` 에 저장
class SilbenKreuzScreen extends StatefulWidget {
  const SilbenKreuzScreen({super.key});

  @override
  State<SilbenKreuzScreen> createState() => _SilbenKreuzScreenState();
}

class _SilbenKreuzScreenState extends State<SilbenKreuzScreen>
    with ScreenCoachMixin<SilbenKreuzScreen> {
  static const _levels = ['A1', 'A2', 'B1', 'B2'];
  static const _xpPerPuzzle = 30;

  Map<String, List<SilbenPuzzle>> _byLevel = {};
  bool _loading = true;

  String _level = 'A1';
  int _index = 0;
  SilbenPuzzle? _puzzle;
  Map<(int, int), String> _solution = {};
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
    _load();
  }

  Future<void> _load() async {
    final data = await SilbenPuzzleLoader.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _byLevel = data;
      _loading = false;
    });
    _openLevel(_level);
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

  void _openPuzzle() {
    final p = _puzzles[_index];
    setState(() {
      _puzzle = p;
      _solution = p.solution;
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
    if (current != null && current.cells.contains(cell)) {
      return current;
    }
    for (final w in _puzzle?.words ?? const <SilbenWord>[]) {
      if (w.cells.contains(cell) && w.cells.any((c) => !_locked.contains(c))) {
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
      setState(() {
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
          TtsService.speak(w.answer);
        }
      }
      if (_locked.length == _solution.length) {
        _onSolved();
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _selected = sel;
        _wrongTick++;
      });
    }
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
      return const Scaffold(body: AppLoading());
    }

    final p = _puzzle;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenWordleTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: p == null
              ? const AppLoading()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _levelPicker(s),
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
        ),
      ),
    );
  }

  Widget _levelPicker(SoriSurfaces s) {
    return Row(
      children: [
        for (final l in _levels)
          if ((_byLevel[l] ?? const []).isNotEmpty)
            Expanded(
              child: GestureDetector(
                onTap: () => _openLevel(l),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: l == _level
                        ? SoriColors.accent.withValues(alpha: 0.16)
                        : s.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: l == _level ? SoriColors.accent : s.border,
                      width: l == _level ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: l == _level ? SoriColors.accent : s.text,
                        ),
                      ),
                      Text(
                        '${_solvedCount(l)}/${(_byLevel[l] ?? const []).length}',
                        style: TextStyle(fontSize: 11, color: s.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
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
    final locked = _locked.contains(cell);
    final selected = _selected == cell;

    Widget box = AnimatedContainer(
      duration: SoriMotion.fast,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: locked
            ? SoriColors.success.withValues(alpha: 0.16)
            : selected
            ? SoriColors.accent.withValues(alpha: 0.10)
            : s.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: locked
              ? SoriColors.success
              : selected
              ? SoriColors.accent
              : s.border,
          width: locked || selected ? 1.8 : 1,
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
          : null,
    );

    if (selected && !locked) {
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
    return GestureDetector(onTap: () => _onCellTap(cell), child: box);
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
            duration: SoriMotion.fast,
            opacity: _tileUsed[i] ? 0.18 : 1,
            child: GestureDetector(
              onTap: () => _onTileTap(i),
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
      ],
    );
  }

  Widget _clues(SilbenPuzzle p, SoriSurfaces s) {
    final words = [...p.words]
      ..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);
    return SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < words.length; i++) ...[
            if (i > 0) Divider(height: Spacing.lg, color: s.border),
            _clueRow(words[i], s),
          ],
        ],
      ),
    );
  }

  Widget _clueRow(SilbenWord w, SoriSurfaces s) {
    final done = _spoken.contains(w.answer);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onClueTap(w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            w.isHorizontal
                ? Icons.arrow_forward_rounded
                : Icons.arrow_downward_rounded,
            size: 16,
            color: done ? SoriColors.success : SoriColors.accent,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '${w.answer} — ${w.german}' : w.german,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: done ? SoriColors.success : s.text,
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
    );
  }

  Widget _solvedCard(AppL10n t) {
    final next = _nextAction;
    return SoriCard(
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
    );
  }
}
