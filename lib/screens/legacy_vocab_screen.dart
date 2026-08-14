import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vocab.dart';
import '../models/feedback_completion.dart';
import '../services/data_loader.dart';
import '../services/review_deck_service.dart';
import '../services/tts_service.dart';
import '../services/culture_notes_service.dart';
import '../widgets/sori/culture_note_card.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/swipe_card.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../l10n/generated/app_localizations.dart';

class LegacyVocabScreen extends StatefulWidget {
  final Future<List<Vocab>> Function()? vocabLoader;

  const LegacyVocabScreen({super.key, this.vocabLoader});

  @override
  State<LegacyVocabScreen> createState() => _LegacyVocabScreenState();
}

class _LegacyVocabScreenState extends State<LegacyVocabScreen>
    with ScreenCoachMixin<LegacyVocabScreen> {
  List<Vocab> _all = [];
  List<Vocab> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  // FlipCard re-key용 서빙 카운터 — 카드 전환 시 뒷면(뜻) 선노출 방지
  // (계약: flip_card.dart doc-comment).
  int _serve = 0;
  int _correct = 0;
  int _wrong = 0;
  int _skipped = 0;

  String _level = 'Alle';
  String _topic = 'Alle';
  bool _koFirst = true;

  /// 'due' = Tagesziel (neu + Wiederholung, capped), 'favorites' = ⭐ markierte, 'all' = alle.
  ///
  /// Phase 1 SRS-UX-Patch (stately-rising-jongga):
  ///   - früher: 'due' = alle SRS-fälligen Karten → "522 due" Schock
  ///   - jetzt:  'due' = max 10 neue + max 15 Wiederholung → Tagesziel
  String _mode = 'due';
  Set<String> _dueIds = {};
  // Stat für die Header-Anzeige — wie viele neue / wie viele Wdh. heute.
  int _todayNewCount = 0;
  int _todayReviewCount = 0;
  Set<String> _favorites = {};
  final LegacyDueFeedbackSession _dueFeedback = LegacyDueFeedbackSession();

  bool _loading = true;
  bool _loadFailed = false;

  // ── 코치마크 타겟 ──
  final GlobalKey _flashCardKey = GlobalKey();

  @override
  String get coachId => 'legacyVocab';

  @override
  bool get coachReady => !_loading && _current != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _flashCardKey,
        title: t.coachLegacyVocabTitle,
        body: t.coachLegacyVocabBody,
        icon: Icons.style_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Persistente Werte beim Start laden
    _correct = Storage.vokCorrect;
    _wrong = Storage.vokWrong;
    _skipped = Storage.vokSkipped;
    _idx = Storage.vokLastIdx;
    _load();
    scheduleCoach();
    // K-Culture 노트 로드 후 카드 반영.
    CultureNotesService.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _load() {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _dueFeedback.reset();
    });
    final providedLoader = widget.vocabLoader;
    final loader = providedLoader ?? DataLoader.loadVocab;
    loader().then((raw) {
      if (!mounted) return;
      // 레벨 오름차순 안정 정렬 — `todayNewIds` 는 입력 순서대로 신규를 뽑아,
      // 원본 CSV 순서(레벨 뒤섞임)면 A2 학습자에게 B1/B2 신규가 나간다.
      // ReviewDeckService.allReviewable() 과 같은 규칙.
      final v = ReviewDeckService.sortByLevelStable(raw);
      // Phase 1 SRS-UX-Patch: nicht ALLE due (= Schock), sondern Tagesziel
      // (10 neu + 15 Wdh., respektiert CSV/pack_order).
      final newIds = Storage.todayNewIds(v.map((e) => e.korean));
      final reviewIds = Storage.todayReviewIds(v.map((e) => e.korean));
      final goal = {...newIds, ...reviewIds};
      setState(() {
        _all = v;
        _dueIds = goal;
        _todayNewCount = newIds.length;
        _todayReviewCount = reviewIds.length;
        _favorites = Storage.vokFavorites.toSet();
        // Erstanwendung: Tagesziel ist nicht leer → 'due' Modus (jetzt
        // gemeint als "heute lernen"). Sonst 'all'.
        _mode = goal.isNotEmpty ? 'due' : 'all';
        _loading = false;
        _loadFailed = v.isEmpty && DataLoader.lastError != null;
        _filtered = _filterList();
        if (_idx >= _filtered.length) _idx = 0;
      });
    });
  }

  List<Vocab> _filterList() {
    return _all.where((v) {
      if (_level != 'Alle' && v.level != _level) return false;
      if (_topic != 'Alle' && v.topic != _topic) return false;
      if (_mode == 'due' && !_dueIds.contains(v.korean)) return false;
      if (_mode == 'favorites' && !_favorites.contains(v.korean)) return false;
      return true;
    }).toList();
  }

  void _toggleFavorite(String korean) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_favorites.contains(korean)) {
        _favorites.remove(korean);
      } else {
        _favorites.add(korean);
      }
      // Im favorites-Modus: re-filter (Karte wurde evtl. entfernt)
      if (_mode == 'favorites') {
        _filtered = _filterList();
        if (_idx >= _filtered.length && _filtered.isNotEmpty) _idx = 0;
      }
    });
    // ignore: discarded_futures
    Storage.toggleVokFavorite(korean);
  }

  void _applyFilters() {
    setState(() {
      _filtered = _filterList();
      _idx = 0;
      _flipped = false;
      _serve++;
    });
  }

  void _setMode(String m) {
    if (_mode == m) return;
    HapticFeedback.selectionClick();
    _dueFeedback.reset();
    setState(() {
      _mode = m;
      _filtered = _filterList();
      _idx = 0;
      _flipped = false;
      _serve++;
    });
  }

  Vocab? get _current =>
      _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

  void _persistIdx() => Storage.setVokLastIdx(_idx);

  void _next() {
    setState(() {
      _flipped = false;
      _serve++;
      _idx = (_idx + 1) % _filtered.length;
    });
    _persistIdx();
  }

  // §C-1-2: prev 복원. 판정 덱 유지 + prev 버튼(하단 행).
  // 판정 없이 이전 카드로 되돌아간다 (SRS 영향 0).
  void _prev() {
    if (_filtered.isEmpty) return;
    setState(() {
      _flipped = false;
      _serve++;
      _idx = (_idx - 1 + _filtered.length) % _filtered.length;
    });
    _persistIdx();
  }

  void _random() {
    setState(() {
      _flipped = false;
      _serve++;
      _idx = math.Random().nextInt(_filtered.length);
    });
    _persistIdx();
  }

  void _gewusst() {
    HapticFeedback.lightImpact();
    final cur = _current;
    setState(() {
      _correct++;
      if (_mode == 'due' && cur != null && _dueIds.contains(cur.korean)) {
        _dueFeedback.record(known: true);
      }
      if (cur != null) _dueIds.remove(cur.korean);
    });
    Storage.setVokCorrect(_correct);
    if (cur != null) {
      Storage.addVokSeen(cur.korean);
      // SRS: nächste Wiederholung in die Zukunft schieben.
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: true);
    }
    _advanceAfterReview();
  }

  void _nichtGewusst() {
    HapticFeedback.mediumImpact();
    final cur = _current;
    setState(() {
      _wrong++;
      if (_mode == 'due' && cur != null && _dueIds.contains(cur.korean)) {
        _dueFeedback.record(known: false);
      }
      // Falsch → morgen wieder fällig, also heute nicht mehr in der due-Liste.
      if (cur != null) _dueIds.remove(cur.korean);
    });
    Storage.setVokWrong(_wrong);
    if (cur != null) {
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: false);
      // ignore: discarded_futures
      Storage.incrementWrongCount(cur.korean);
    }
    _advanceAfterReview();
  }

  /// Nach SRS-Update: im 'due' Modus die Karte aus _filtered entfernen,
  /// damit sie nicht direkt wieder erscheint.
  void _advanceAfterReview() {
    if (_mode == 'due') {
      setState(() {
        if (_filtered.isNotEmpty) {
          _filtered = _filterList();
          if (_idx >= _filtered.length) _idx = 0;
          _flipped = false;
          _serve++;
        }
        _dueFeedback.completeIfEligible(
          isDueMode: true,
          dueIsEmpty: _dueIds.isEmpty,
          contentLabel: AppL10n.of(context).vocabDueEmptyTitle,
          level: null,
        );
      });
      _persistIdx();
    } else {
      _next();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    setState(() => _skipped++);
    Storage.setVokSkipped(_skipped);
    _next();
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
  }

  List<String> get _levels {
    final s = _all.map((v) => v.level).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  List<String> get _topics {
    final s = _all.map((v) => v.topic).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(body: AppLoading(message: t.loadingVocab));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenVocabTitle)),
        body: AppError(
          message: DataLoader.lastError ?? 'Unbekannter Fehler',
          onRetry: () {
            DataLoader.reset();
            _load();
          },
        ),
      );
    }

    final v = _current;
    if (v == null) {
      // Im 'due' Modus: heute alles erledigt → eigene Empty-State.
      if (_mode == 'due') {
        return _buildDueResult(t);
      }
      // Im 'favorites' Modus: noch keine Sternchen → Hinweis-State.
      if (_mode == 'favorites') {
        return Scaffold(
          appBar: AppBar(title: Text(t.screenVocabTitle)),
          body: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_wave.png',
            icon: Icons.star_outline_rounded,
            title: t.vocabEmptyFavorites,
            ctaLabel: t.vocabModeAll,
            onCta: () => _setMode('all'),
            accent: SoriColors.warning,
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(t.screenVocabTitle)),
        body: SoriEmptyState(
          asset: 'assets/illustrations/mascot/magpie_wave.png',
          icon: Icons.tune_rounded,
          title: t.emptyVocab,
          ctaLabel: t.filterOpenBtn,
          onCta: _showFilterSheet,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenVocabTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
          const TtsSpeedAction(),
        ],
      ),
      body: SafeArea(
        child: SoriStudyClamp(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              children: [
                // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
                const HanokHeader(
                  asset: 'assets/illustrations/hanok/study_classroom.png',
                  fallbackIcon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: Spacing.md),

                // Mode chips (Tagesziel / Favorites / Alle)
                //
                // Phase 1 SRS-UX-Patch (stately-rising-jongga):
                //   Früher: "🔥 522 fällig" (Schock-UX bei Erstanwendung).
                //   Jetzt:  "🔥 Heute (N+M)" — N neue + M Wdh., gecapped.
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    SoriChip(
                      label: t.vocabTodayBadge(
                        _todayNewCount,
                        _todayReviewCount,
                      ),
                      accent: SoriColors.info,
                      selected: _mode == 'due',
                      variant: SoriChipVariant.filled,
                      onTap: () => _setMode('due'),
                      minInteractiveHeight: 44,
                    ),
                    SoriChip(
                      label: t.vocabFavoritesBadge(_favorites.length),
                      accent: SoriColors.warning,
                      selected: _mode == 'favorites',
                      variant: SoriChipVariant.filled,
                      onTap: () => _setMode('favorites'),
                      minInteractiveHeight: 44,
                    ),
                    SoriChip(
                      label: t.vocabModeAll,
                      accent: SoriColors.info,
                      selected: _mode == 'all',
                      variant: SoriChipVariant.filled,
                      onTap: () => _setMode('all'),
                      minInteractiveHeight: 44,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),

                // Stat chips
                Row(
                  children: [
                    SoriChip(
                      label: '${_idx + 1}/${_filtered.length}',
                      accent: SoriColors.info,
                    ),
                    const SizedBox(width: Spacing.xs + 2),
                    SoriChip(label: '✅ $_correct', accent: SoriColors.success),
                    const SizedBox(width: Spacing.xs + 2),
                    SoriChip(label: '❌ $_wrong', accent: SoriColors.danger),
                    const SizedBox(width: Spacing.xs + 2),
                    SoriChip(label: '⏭ $_skipped', accent: SoriColors.warning),
                  ],
                ),
                const SizedBox(height: 10),

                // Card with swipe judgment + favorite star overlay
                // 2026-08-14: 데이팅앱식 판정 스와이프 — 오른쪽=Gewusst,
                // 왼쪽=Nicht gewusst. 하단 버튼은 접근성 정본으로 유지.
                Expanded(
                  child: Center(
                    child: FractionallySizedBox(
                      heightFactor: 0.82,
                      child: Stack(
                        children: [
                          SoriSwipeCard(
                            // §C-1-1: 플립 전 스와이프 금지 — 답을 보지 않은
                            // 카드에 SRS 오답이 기록되는 데이터 버그 방지.
                            // 버튼 행도 if (_flipped) 게이트 — 동일 계약.
                            enabled: _flipped,
                            onSwipeRight: _gewusst,
                            onSwipeLeft: _nichtGewusst,
                            rightBadge: SoriSwipeBadge(
                              label: t.btnGewusst,
                              icon: Icons.check_rounded,
                              color: SoriColors.success,
                            ),
                            leftBadge: SoriSwipeBadge(
                              label: t.btnNichtGewusst,
                              icon: Icons.close_rounded,
                              color: SoriColors.danger,
                            ),
                            // §C-1-3: 별을 child 내부 Stack으로 — 퇴장
                            // 애니메이션에서 별이 제자리에 남지 않도록.
                            child: Stack(
                              children: [
                                SoriStudyScale(
                                  child: KeyedSubtree(
                                    key: _flashCardKey,
                                    child: FlipCard(
                                      key: ValueKey('legacy-$_serve'),
                                      flipped: _flipped,
                                      onTap: _onFlip,
                                      front: _Front(v: v, koFirst: _koFirst),
                                      back: _Back(v: v, koFirst: _koFirst),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: SoriPressable(
                                    onTap: () => _toggleFavorite(v.korean),
                                    haptic: SoriHaptic.light,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: SoriSurfaces.of(
                                          context,
                                        ).bg.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _favorites.contains(v.korean)
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: _favorites.contains(v.korean)
                                            ? SoriColors.warning
                                            : SoriSurfaces.of(context).textDim,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Answer buttons (only when flipped)
                if (_flipped) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SoriButton.filled(
                          label: t.btnGewusst,
                          icon: Icons.check,
                          accent: SoriColors.success,
                          fullWidth: true,
                          onTap: _gewusst,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: SoriButton.filled(
                          label: t.btnNichtGewusst,
                          icon: Icons.close,
                          fullWidth: true,
                          destructive: true,
                          onTap: _nichtGewusst,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                ],

                // Bottom row — §C-1-2: prev 버튼 복원 (판정 덱 + prev 공존)
                Row(
                  children: [
                    // Prev: 이전 카드 (판정 없음)
                    Semantics(
                      label: t.legacyVocabPrevious,
                      button: true,
                      child: SoriPressable(
                        onTap: _prev,
                        haptic: SoriHaptic.selection,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(SoriRadius.md),
                            border: Border.all(
                              color: SoriSurfaces.of(context).border,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.navigate_before_rounded,
                            size: 22,
                            color: SoriSurfaces.of(context).text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs + 2),
                    Expanded(
                      child: SoriPressable(
                        onTap: () => TtsService.speak(v.korean),
                        onLongPress: () => TtsService.speakSlow(v.korean),
                        haptic: SoriHaptic.selection,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(SoriRadius.md),
                            border: Border.all(
                              color: SoriSurfaces.of(context).border,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up,
                                size: 17,
                                color: SoriSurfaces.of(context).text,
                              ),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                t.btnHoeren,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  color: SoriSurfaces.of(context).text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs + 2),
                    Expanded(
                      child: SoriButton.outlined(
                        label: t.btnSkip,
                        icon: Icons.skip_next,
                        fullWidth: true,
                        onTap: _skip,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs + 2),
                    Expanded(
                      child: SoriButton.outlined(
                        label: t.btnRandom,
                        icon: Icons.shuffle,
                        fullWidth: true,
                        onTap: _random,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Center(
                  child: Text(
                    t.vocabSlowHint,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 10.5,
                      color: SoriSurfaces.of(context).textDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueResult(AppL10n t) {
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final completion = _dueFeedback.current;
    return Scaffold(
      appBar: AppBar(title: Text(t.screenVocabTitle)),
      body: SafeArea(
        child: SoriCenterClamp(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoriEmptyState(
                  asset: 'assets/illustrations/empty/celebrate_complete.png',
                  icon: Icons.celebration_outlined,
                  title: t.vocabDueEmptyTitle,
                  body: t.vocabDueEmptyBody,
                ),
                if (completion != null &&
                    feedbackScope != null &&
                    feedbackScope.featureGate.isEnabled) ...[
                  ContentFeedbackCard(
                    feedbackContext: completion.context,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                    completedMissionIds: feedbackScope.completedMissionIds,
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                SoriButton.filled(
                  label: t.vocabDueEmptyAction,
                  fullWidth: true,
                  onTap: () => _setMode('all'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showSoriSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppL10n.of(ctx).filterTitle,
                style: SoriTextTheme.of(ctx).h3,
              ),
              const SizedBox(height: 12),
              _dropdown(AppL10n.of(ctx).filterLevel, _level, _levels, (v) {
                setLocal(() => _level = v!);
                _level = v!;
              }),
              const SizedBox(height: 10),
              _dropdown(AppL10n.of(ctx).filterTheme, _topic, _topics, (v) {
                setLocal(() => _topic = v!);
                _topic = v!;
              }),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppL10n.of(ctx).filterDirKoDe),
                value: _koFirst,
                onChanged: (b) {
                  setLocal(() => _koFirst = b);
                  _koFirst = b;
                },
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.filled(
                label: AppL10n.of(ctx).btnApply,
                fullWidth: true,
                onTap: () {
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        border: Border.all(color: s.surfaceAlt),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: s.surface,
        hint: Text(label, style: TextStyle(color: s.textMuted)),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Front extends StatelessWidget {
  final Vocab v;
  final bool koFirst;
  const _Front({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final mastery = Storage.vocabMastery(v.korean);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 카드 안쪽 높이를 폰트·간격의 기준으로 삼아 텍스트가 카드에 비례해
          // 커지게(기기 무관 균일 충전율) 한다. FlipCard 가 세로 스크롤로 감싸
          // maxHeight 를 무한으로 풀 수 있으므로, 유한한 minHeight(= 카드 실제
          // 높이)를 폴백으로 쓴다. 둘 다 없으면 360.
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (constraints.minHeight.isFinite && constraints.minHeight > 0
                    ? constraints.minHeight
                    : 360.0);
          // 헤드라인 = koFirst 순서상 먼저 보이는 값. 한국어 단어는 한 줄이라
          // FittedBox 로 폭에 맞춰 줄이고, 번역은 여러 단어일 수 있어 줄바꿈 허용.
          final Widget headline = koFirst
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    v.korean,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.19, 38, 92),
                      fontWeight: FontWeight.w800,
                      color: SoriColors.info,
                      height: 1.15,
                    ),
                  ),
                )
              : Text(
                  v.translationFor(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: soriFillSize(h, 0.12, 28, 48),
                    fontWeight: FontWeight.w800,
                    color: SoriColors.info,
                    height: 1.15,
                  ),
                );
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SoriChip(
                        label: v.level,
                        accent: SoriColors.info,
                        variant: SoriChipVariant.filled,
                      ),
                      const SizedBox(width: 8),
                      _MasteryChip(
                        state: mastery,
                        label: _masteryLabel(t, mastery),
                      ),
                    ],
                  ),
                  // 단어 + 발음(로마자) + 품사를 한 묶음으로 → spaceEvenly 가
                  // 흩뜨리지 않고 하나의 중앙 초점 블록으로 다룬다.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      headline,
                      if (koFirst) ...[
                        SizedBox(height: soriFillSize(h, 0.02, 6, 16)),
                        Text(
                          '[${v.romanization}]',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: soriFillSize(h, 0.05, 15, 30),
                            color: SoriColors.info.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      SizedBox(height: soriFillSize(h, 0.02, 8, 16)),
                      Text(
                        v.posFor(lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: soriFillSize(h, 0.05, 12, 26),
                          color: s.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '👆 ${t.hintTapToFlip}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.038, 13, 22),
                      color: s.textDim,
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
}

String _masteryLabel(AppL10n t, MasteryState m) {
  switch (m) {
    case MasteryState.fresh:
      return t.vocabMasteryFresh;
    case MasteryState.learning:
      return t.vocabMasteryLearning;
    case MasteryState.reviewDue:
      return t.vocabMasteryReviewDue;
    case MasteryState.strong:
      return t.vocabMasteryStrong;
  }
}

class _MasteryChip extends StatelessWidget {
  final MasteryState state;
  final String label;
  const _MasteryChip({required this.state, required this.label});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      MasteryState.fresh => (
        SoriSurfaces.of(context).textMuted,
        Icons.fiber_new_rounded,
      ),
      MasteryState.learning => (SoriColors.info, Icons.school_outlined),
      MasteryState.reviewDue => (SoriColors.warning, Icons.refresh_rounded),
      MasteryState.strong => (
        SoriColors.success,
        Icons.workspace_premium_rounded,
      ),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final Vocab v;
  final bool koFirst;
  const _Back({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 카드 안쪽 높이 기준(위 _Front 와 동일 근거) — FlipCard 세로 스크롤이
          // maxHeight 를 무한으로 풀 수 있어 유한한 minHeight 폴백을 둔다.
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (constraints.minHeight.isFinite && constraints.minHeight > 0
                    ? constraints.minHeight
                    : 360.0);
          // 헤드라인 = koFirst 순서상 먼저 보이는 값. 한국어 단어는 FittedBox 로
          // 한 줄에 맞추고, 번역은 줄바꿈 허용.
          final Widget headline = koFirst
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    v.translationFor(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.12, 28, 48),
                      fontWeight: FontWeight.w800,
                      color: SoriColors.success,
                      height: 1.2,
                    ),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    v.korean,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.19, 36, 92),
                      fontWeight: FontWeight.w800,
                      color: SoriColors.success,
                      height: 1.2,
                    ),
                  ),
                );
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SoriChip(
                    label: v.level,
                    accent: SoriColors.success,
                    variant: SoriChipVariant.filled,
                  ),
                  // 뜻 + 품사·주제를 한 묶음으로.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      headline,
                      SizedBox(height: soriFillSize(h, 0.02, 8, 16)),
                      Text(
                        '${v.posFor(lang)} · ${v.topic}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: soriFillSize(h, 0.05, 12, 26),
                          color: s.textMuted,
                        ),
                      ),
                    ],
                  ),
                  // 예문(한국어 + 듣기 + 번역)을 한 묶음으로 → spaceEvenly 가
                  // 흩뜨리지 않는다.
                  if (v.exampleKorean.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  v.exampleKorean,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: soriFillSize(h, 0.075, 16, 40),
                                    fontWeight: FontWeight.w700,
                                    color: SoriColors.info.withValues(
                                      alpha: 0.9,
                                    ),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SoriPressable(
                                onTap: () => TtsService.speak(v.exampleKorean),
                                onLongPress: () =>
                                    TtsService.speakSlow(v.exampleKorean),
                                haptic: SoriHaptic.selection,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: SoriColors.info.withValues(
                                      alpha: 0.18,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    color: SoriColors.info,
                                    size: soriFillSize(h, 0.075, 24, 48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: soriFillSize(h, 0.02, 4, 14)),
                          Text(
                            v.exampleFor(lang),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: soriFillSize(h, 0.05, 13.5, 28),
                              color: s.text,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: CultureNoteCard(korean: v.korean),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
