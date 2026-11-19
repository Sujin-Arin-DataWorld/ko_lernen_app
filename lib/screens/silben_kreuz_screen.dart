import '../widgets/sori/intro_tokens.dart';
import '../models/practice_history.dart';
import '../models/silben_practice.dart';
import '../services/practice_history_store.dart';
import '../widgets/practice_dokkaebi_help.dart';
import '../widgets/practice_dokkaebi_art.dart';
import '../widgets/practice_dokkaebi_canvas.dart';
import '../widgets/practice_guide.dart';
import '../widgets/practice_motion.dart';
import '../widgets/practice_layout.dart';
import '../widgets/practice_impact_frame.dart';
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
import '../widgets/sori/approved_games/approved_game_material.dart';
import '../widgets/sori/approved_games/approved_silben_art.dart';
import '../widgets/sori/approved_games/approved_word_chain_view.dart'
    show showWordChainSpeedSheet;
import '../widgets/sori/route_observer.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_result_recovery.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/viewport_pages.dart';
import '../widgets/sori/tokens.dart';

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
        GameResultRecovery<SilbenKreuzScreen>,
        WidgetsBindingObserver,
        RouteAware {
  ModalRoute<dynamic>? _observedRoute;
  bool _foreground = true;
  bool get _visible => _foreground && (_observedRoute?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _observedRoute) {
      soriRouteObserver.unsubscribe(this);
      _observedRoute = route;
      if (route != null) soriRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() => _pauseFeedback();

  @override
  void didPop() => _pauseFeedback();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && (_observedRoute?.isCurrent ?? true)) {
      _pauseFeedback();
    }
  }

  void _pauseFeedback() {
    unawaited(SoriSpeech.stop());
    _wrongFeedbackTimer?.cancel();
    if (_wrongCell != null || _hintPlay) {
      setState(() {
        _wrongCell = null;
        _hintPlay = false;
      });
    }
  }

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
  static const _hintPageKey = ValueKey('silben-hint-page');
  int _hintPageRequest = 0;
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
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
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
    if (!_visible || !gameResultAcceptsInput || _finishing) return;
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level,
      levels: _levels,
      allLabel: t.filterAll,
      countFor: (level) => (_byLevel[level] ?? const []).length,
      solvedFor: _solvedCount,
    );
    if (!_visible ||
        !gameResultAcceptsInput ||
        _finishing ||
        presentation != _presentation ||
        next == null) {
      return;
    }
    _openLevel(next);
  }

  Widget _levelControl(AppL10n t) {
    final total = (_byLevel[_level] ?? const []).length;
    return _headerControl(
      label: '${t.filterLevel}: $_level · ${_solvedCount(_level)}/$total',
      width: 64,
      onTap: widget.review == null ? () => _showLevelFilter(t) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_level, style: silbenType(19)),
          const SilbenChevron(SilbenChevronDirection.down, color: silbenInk),
        ],
      ),
    );
  }

  Widget _speedControl(AppL10n t) => ValueListenableBuilder<double>(
    valueListenable: SoriSpeech.speed,
    builder: (context, speed, _) {
      final formatted = speed
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
      return _headerControl(
        label: '${t.ttsSpeedLabel}: $formatted×',
        width: formatted.length > 2 ? 64 : 48,
        onTap: () {
          if (_visible) showWordChainSpeedSheet(context);
        },
        child: Text('$formatted×', style: silbenType(19)),
      );
    },
  );

  Widget _headerControl({
    required String label,
    required double width,
    required VoidCallback? onTap,
    required Widget child,
  }) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: width, minHeight: 48),
    child: Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: SoriPressable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 13, bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          constraints: BoxConstraints(minWidth: width, minHeight: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xfffff6df), Color(0xffebc18b)],
            ),
            border: Border.all(color: const Color(0xffcaa162)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    ),
  );

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
    if (!_visible ||
        !gameResultAcceptsInput ||
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
    if (!_visible ||
        !gameResultAcceptsInput ||
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
    if (!_visible ||
        !gameResultAcceptsInput ||
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
    WidgetsBinding.instance.removeObserver(this);
    soriRouteObserver.unsubscribe(this);
    _wrongFeedbackTimer?.cancel();
    if (_visible) unawaited(SoriSpeech.stop());
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
      if (_visible && gameResultAcceptsInput && _solved) {
        SoriCelebration.burst(context);
      }
    });
  }

  void _requestHint(int presentation, {bool paged = false}) {
    final word = _activeWord;
    final p = _puzzle;
    final cell = _selected;
    if (!_visible ||
        !gameResultAcceptsInput ||
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
      if (paged) _hintPageRequest++;
    });
    if (paged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final anchor = _helpAnchor.currentContext;
      if (!mounted ||
          !_visible ||
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
          !_visible ||
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

  Widget _helpPanel(AppL10n t, {bool showAction = true}) {
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
      inset: false,
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
          if (showAction) _hintAction(t),
        ],
      ),
    );
  }

  Widget _hintAction(AppL10n t, {bool paged = false}) {
    final word = _activeWord;
    if (word == null) return const SizedBox.shrink();
    final presentation = _presentation;
    final actionLabel = switch (_helpState.levelFor(word)) {
      0 => t.practiceHintMeaning,
      1 => t.practiceHintCrossing,
      _ => t.practiceHintReveal,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = silbenType(paged ? 16 : 22, color: gameCream);
        const padding = EdgeInsets.fromLTRB(12, 5, 12, 9);
        final measure = TextPainter(
          text: TextSpan(text: actionLabel, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth - padding.horizontal - 44);
        final height = math.max(52.0, measure.height + padding.vertical);
        measure.dispose();
        return SizedBox(
          height: height,
          child: ApprovedArtButton(
            key: const ValueKey('dokkaebi-hint'),
            material: 'wordChainAction',
            label: actionLabel,
            onTap:
                _finishing || _selected == null || _locked.contains(_selected)
                ? null
                : () => _requestHint(presentation, paged: paged),
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  const SizedBox(width: 22),
                  Expanded(
                    child: Text(
                      actionLabel,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                  const SilbenChevron(SilbenChevronDirection.right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _puzzleBoard(
    SilbenPuzzle p,
    SoriSurfaces s, {
    required bool dense,
    bool paged = false,
  }) {
    final word = _activeWord;
    final occurrence = word == null ? null : silbenWordOccurrence(word);
    final gesture = _hintGesture;
    final presentation = _presentation;
    return KeyedSubtree(
      key: _helpAnchor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final minGrid = p.cols * 48.0 + (p.cols - 1) * 8;
          final sideBySide = p.cols < 5 && width - minGrid - 32 >= 104;
          final stageSize = sideBySide
              ? (width - minGrid - 32).clamp(104.0, 172.0)
              : math.min(paged ? 94.0 : 144.0, width - 32);
          final stageHeight = stageSize / PracticeDokkaebiCanvas.aspectRatio;
          final panelLeft = sideBySide ? stageSize - 7 : 8.0;
          final panelWidth = width - panelLeft - 14;
          final gridWidth = panelWidth - 24;
          final metrics = _gridMetrics(p, gridWidth, dense: dense);
          final gridHeight = metrics.height * p.rows + 8 * (p.rows - 1);
          final panelHeight = gridHeight + 34;
          final panelTop = sideBySide
              ? 15.0
              : stageHeight * PracticeDokkaebiCanvas.contact.dy;
          final contactY = sideBySide ? panelTop + panelHeight : panelTop;
          final stageTop =
              contactY - stageHeight * PracticeDokkaebiCanvas.contact.dy;
          final arenaHeight = math
              .max(panelTop + panelHeight + 16, stageTop + stageHeight + 4)
              .clamp(sideBySide && !dense ? 279.0 : 0.0, double.infinity);
          final stageLeft = sideBySide ? 0.0 : (width - stageSize) / 2;
          // The clip stays intact. Its contact point meets the card ledge;
          // its full opaque video rectangle never covers an interactive cell.
          final stage = PracticeDokkaebiStage(
            key: ValueKey('dokkaebi-board-$presentation-$occurrence'),
            size: stageSize,
            restingArt: sideBySide && !_solved
                ? OverflowBox(
                    alignment: Alignment.bottomCenter,
                    maxWidth: stageSize + 32,
                    maxHeight: math.min(arenaHeight - 4, panelHeight + 40),
                    child: Transform.translate(
                      offset: const Offset(0, -13),
                      child: const PracticeDokkaebiArt(
                        pose: PracticeDokkaebiPose.ready,
                      ),
                    ),
                  )
                : null,
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
                  _visible &&
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
          return PracticeImpactFrame(
            key: const ValueKey('dokkaebi-arena-fire'),
            pulse: _hintPulse,
            child: SizedBox(
              height: arenaHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: SilbenWood(radius: 20)),
                  Positioned(
                    left: panelLeft,
                    top: panelTop,
                    width: panelWidth,
                    height: panelHeight,
                    child: const SilbenWood(),
                  ),
                  Positioned(
                    left: stageLeft,
                    top: stageTop,
                    child: IgnorePointer(child: stage),
                  ),
                  Positioned(
                    left: sideBySide ? panelLeft - 3 : panelLeft,
                    top: panelTop + 16,
                    width: panelWidth,
                    height: gridHeight,
                    child: KeyedSubtree(
                      key: _gridKey,
                      child: _grid(p, s, metrics),
                    ),
                  ),
                  Positioned(
                    left: stageLeft,
                    width: stageSize,
                    top: contactY,
                    child: const IgnorePointer(
                      child: SizedBox(
                        key: ValueKey('dokkaebi-board-ledge'),
                        height: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ({double width, double height, double gap}) _gridMetrics(
    SilbenPuzzle p,
    double width, {
    required bool dense,
  }) {
    final gap = p.cols > 1
        ? ((width - p.cols * 48) / (p.cols - 1)).clamp(0.0, 7.0)
        : 0.0;
    final cell = ((width - (p.cols - 1) * gap) / p.cols).clamp(48.0, 86.0);
    return (
      width: cell,
      height: dense ? 48.0 : cell.clamp(48.0, 66.0),
      gap: gap,
    );
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
    if (p == null) {
      return SoriStudyFrame(
        onLeave: retireGameResult,
        title: t.screenWordleTitle,
        child: SoriEmptyState(
          icon: Icons.grid_off_rounded,
          title: t.screenWordleTitle,
          body: t.silbenEmptyBody,
        ),
      );
    }
    final locked = StudyBodyInputLock.isLocked(context);
    return SoriStudyFrame(
      onLeave: () {
        _pauseFeedback();
        retireGameResult();
      },
      title: t.screenWordleTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_solved && (_locked.isNotEmpty || _wrongTick > 0),
      ),
      leadingVisual: const SilbenBackFace(),
      surfaceBuilder: (close, _) => ColoredBox(
        color: const Color(0xff044433),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  SilbenHeader(
                    close: close,
                    controls: SoriChromeRow.compact(
                      filterControl: _levelControl(t),
                      trailing: _speedControl(t),
                    ),
                  ),
                  Expanded(
                    child: ExcludeFocus(
                      excluding: locked,
                      child: AbsorbPointer(
                        absorbing: locked,
                        child: _playArea(p, s, t),
                      ),
                    ),
                  ),
                  ApprovedGameNavigation(
                    backgroundArt: 'word_chain_jade_borderless',
                    onSelected: (index) {
                      if (!_visible) return;
                      openApprovedGameTab(context, index);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _playArea(SilbenPuzzle p, SoriSurfaces s, AppL10n t) {
    const corners = BorderRadius.vertical(top: Radius.circular(23));
    return ClipRRect(
      borderRadius: corners,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffac722a), width: 1.7),
          borderRadius: corners,
        ),
        position: DecorationPosition.foreground,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final paged =
                MediaQuery.textScalerOf(context).scale(20) > 20.01 ||
                bounds.maxWidth < 360;
            if (paged) return _pagedPlayArea(p, s, t);
            final dense =
                bounds.maxHeight < 690 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.01;
            return Stack(
              fit: StackFit.expand,
              children: [
                const GameArtwork('paper'),
                SingleChildScrollView(
                  key: const ValueKey('silben-play-scroll'),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_solved) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 8, 25, 3),
                          child: Text(
                            t.silbenPlaceInstruction,
                            style: silbenType(21),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          child: KeyedSubtree(
                            key: _cluesKey,
                            child: _clues(p, s),
                          ),
                        ),
                      ],
                      const SizedBox(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: _puzzleBoard(p, s, dense: dense),
                      ),
                      if (!_solved) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(23, 9, 23, 3),
                          child: Text(t.silbenPoolTitle, style: silbenType(23)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: KeyedSubtree(
                            key: _poolKey,
                            child: _tilePool(p, dense: dense),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _helpPanel(t),
                        ),
                      ] else ...[
                        PracticeMotionSurface(
                          enter: true,
                          child: _solvedCard(t),
                        ),
                        KeyedSubtree(key: _cluesKey, child: _clues(p, s)),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pagedPlayArea(SilbenPuzzle puzzle, SoriSurfaces surfaces, AppL10n t) {
    final word = _activeWord;
    final showHint = !_solved && word != null && _helpState.levelFor(word) > 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        const GameArtwork('paper'),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 16),
          child: Column(
            children: [
              Expanded(
                child: SoriViewportPages(
                  key: ValueKey((_presentation, _solved)),
                  targetSectionKey: showHint ? _hintPageKey : null,
                  targetRevision: _hintPageRequest,
                  sections: [
                    if (_solved) ...[
                      PracticeMotionSurface(enter: true, child: _solvedCard(t)),
                      KeyedSubtree(
                        key: _cluesKey,
                        child: _clues(puzzle, surfaces),
                      ),
                      _puzzleBoard(puzzle, surfaces, dense: true, paged: true),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          t.silbenPlaceInstruction,
                          style: silbenType(16),
                        ),
                      ),
                      _puzzleBoard(puzzle, surfaces, dense: true, paged: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(t.silbenPoolTitle, style: silbenType(17)),
                      ),
                      Padding(
                        key: _poolKey,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: _tilePool(puzzle, dense: true),
                      ),
                      Padding(
                        key: _cluesKey,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _clues(puzzle, surfaces),
                      ),
                      if (showHint)
                        Padding(
                          key: _hintPageKey,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: PracticeMotionSurface(
                            key: ValueKey(_hintPageRequest),
                            enter: true,
                            interactive: false,
                            child: _helpPanel(t, showAction: false),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (!_solved)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _hintAction(t, paged: true),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid(
    SilbenPuzzle p,
    SoriSurfaces s,
    ({double width, double height, double gap}) m,
  ) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < p.rows; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < p.cols; c++) ...[
                if (c > 0) SizedBox(width: m.gap),
                _cellBox((r, c), Size(m.width, m.height), s),
              ],
            ],
          ),
        ],
      ],
    ),
  );

  Widget _cellBox((int, int) cell, Size size, SoriSurfaces s) {
    final presentation = _presentation;
    final syllable = _solution[cell];
    if (syllable == null) {
      return SizedBox.fromSize(
        size: size,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0x683e2111),
            border: Border(top: BorderSide(color: Color(0x83120702), width: 2)),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
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
          width: size.width,
          height: size.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage(silbenTileAsset),
              fit: BoxFit.fill,
              colorFilter: locked
                  ? const ColorFilter.mode(Color(0x4061a575), BlendMode.srcATop)
                  : inActiveWord && !selected
                  ? const ColorFilter.mode(Color(0x22bc7937), BlendMode.srcATop)
                  : null,
            ),
            color: locked
                ? SoriColors.success.withValues(alpha: 0.16)
                : selected
                ? SoriColors.info.withValues(alpha: 0.10)
                : inActiveWord
                ? SoriColors.info.withValues(alpha: 0.06)
                : s.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4a341703),
                offset: Offset(0, 3),
                blurRadius: 3,
              ),
            ],
            border: Border.all(
              color: locked
                  ? SoriColors.success
                  : selected
                  ? const Color(0xff299e78)
                  : Colors.transparent,
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
                    fontFamily: IntroFonts.koreanDisplay,
                    fontSize: size.height * .46,
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
        if (selected && !locked && !wrong)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xff3bcc9c), width: 3),
                ),
              ),
            ),
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
        if (!locked && !wrong)
          for (final (offset, entry)
              in memberships.where((word) => word.cells.first == cell).indexed)
            Positioned(
              left: 5,
              top: 5 + offset * (size.height >= 60 ? 32 : 21),
              child: SilbenNumber(
                _puzzle!.words.indexOf(entry) + 1,
                size: size.height >= 60 ? 24 : 19,
              ),
            ),
        if (memberships.length > 1)
          Positioned.fill(
            child: SilbenCrossingWedges(
              key: ValueKey('silben-crossing-wedges-${cell.$1}-${cell.$2}'),
              directions: directions,
              paintMarkers: !memberships.any(
                (word) => word.cells.first == cell,
              ),
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

  Widget _tilePool(SilbenPuzzle p, {required bool dense}) {
    final presentation = _presentation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = p.pool.length <= 8 ? 4 : 5;
        final gap = ((constraints.maxWidth - columns * 48) / (columns - 1))
            .clamp(0.0, 10.0);
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        final fontSize = width >= 74 ? (dense ? 30.0 : 34.0) : 25.0;
        final height = math.max(
          dense ? 48.0 : 57.0,
          MediaQuery.textScalerOf(context).scale(fontSize) * 1.15 + 6,
        );
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: 8,
          children: [
            for (var i = 0; i < p.pool.length; i++)
              AnimatedOpacity(
                duration: SoriMotion.respect(context, SoriMotion.fast),
                opacity: _tileUsed[i] ? 0.26 : 1,
                child: Semantics(
                  key: ValueKey('silben-pool-$i'),
                  button: true,
                  enabled: !_tileUsed[i],
                  label: p.pool[i],
                  onTap: _tileUsed[i]
                      ? null
                      : () => _onTileTap(i, presentation),
                  excludeSemantics: true,
                  child: SoriPressable(
                    pressScale: .99,
                    surfaceDepth: _tileUsed[i] ? 0 : 1,
                    surfaceRadius: 10,
                    surfaceEdgeColor: const Color(0xffa57a51),
                    tactileTilt: true,
                    haptic: null,
                    onTap: _tileUsed[i]
                        ? null
                        : () => _onTileTap(i, presentation),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: AssetImage(silbenTileAsset),
                            fit: BoxFit.fill,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4a341703),
                              offset: Offset(0, 3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Center(
                            child: ApprovedGameText(
                              p.pool[i],
                              korean: true,
                              size: fontSize,
                              weight: FontWeight.w700,
                              color: const Color(0xff102c24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _clues(SilbenPuzzle p, SoriSurfaces s) {
    final words = p.words;
    if (!_solved) {
      return Column(
        key: const ValueKey('silben-compact-clues'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_lastCompletedWord case final completed?)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SoriSpeechIndicator(
                key: const Key('silben-clue-speak'),
                text: _speechFor(completed),
              ),
            ),
          for (final (index, word) in words.indexed) _clueRow(word, index, s),
        ],
      );
    }
    final card = SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < words.length; i++) ...[
            if (i > 0) Divider(height: Spacing.lg, color: s.border),
            _clueRow(words[i], i, s),
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
      label:
          '${declaredIndex + 1}. ${w.isHorizontal ? AppL10n.of(context).silbenDirectionHorizontal : AppL10n.of(context).silbenDirectionVertical}. $label',
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
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 4),
            child: AnimatedContainer(
              key: ValueKey('silben-clue-surface-$declaredIndex'),
              duration: SoriMotion.respect(context, SoriMotion.fast),
              constraints: const BoxConstraints(minHeight: 41),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: active
                      ? const [Color(0xfffff2cf), Color(0xfff7d9a1)]
                      : const [Color(0xfffff5df), Color(0xfff2dab5)],
                ),
                borderRadius: BorderRadius.circular(SoriRadius.md),
                border: Border.all(
                  color: active
                      ? const Color(0xffac721f)
                      : const Color(0xffcfb58e),
                  width: active ? 1.5 : 1,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x335f3914),
                    offset: Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SilbenNumber(declaredIndex + 1),
                  const SizedBox(width: 14),
                  Icon(
                    done
                        ? Icons.check_circle_outline_rounded
                        : w.isHorizontal
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: done ? SoriColors.success : const Color(0xff4a2c14),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done ? '${w.answer} · $meaning' : meaning,
                          style: silbenType(
                            19,
                            color: done ? SoriColors.success : silbenInk,
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
  SilbenCrossingWedges({
    super.key,
    required Iterable<String> directions,
    this.paintMarkers = true,
  }) : directions = List<String>.unmodifiable(directions);

  final List<String> directions;
  final bool paintMarkers;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _SilbenCrossingWedgePainter(
        horizontal: paintMarkers && directions.contains('h'),
        vertical: paintMarkers && directions.contains('v'),
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
