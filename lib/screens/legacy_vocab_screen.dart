import 'dart:async';
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
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/deck_coach.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/scroll_if_needed.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';
import '../l10n/generated/app_localizations.dart';

class LegacyVocabScreen extends StatefulWidget {
  final Future<List<Vocab>> Function()? vocabLoader;
  final CultureNotesLoader? cultureNotesLoader;

  const LegacyVocabScreen({
    super.key,
    this.vocabLoader,
    this.cultureNotesLoader,
  });

  @override
  State<LegacyVocabScreen> createState() => _LegacyVocabScreenState();
}

class _LegacyVocabScreenState extends State<LegacyVocabScreen>
    with ScreenCoachMixin<LegacyVocabScreen> {
  List<Vocab> _all = [];
  List<Vocab> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  // 답을 한 번 공개한 카드는 다시 앞면으로 돌려도 좌/우 판정을 허용한다.
  // 필터·이동·판정으로 다른 카드가 서빙될 때만 초기화한다.
  bool _cardRevealed = false;
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
    unawaited(_loadCultureNotes());
  }

  Future<void> _loadCultureNotes() async {
    try {
      await (widget.cultureNotesLoader ?? CultureNotesService.load)();
    } catch (_) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
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
      final today = ReviewDeckService.todaySelectionForLevel(
        v,
        levelCode: Storage.userLevelCode,
      );
      final goal = today.words.map((word) => word.korean).toSet();
      setState(() {
        _all = v;
        _dueIds = goal;
        _todayNewCount = today.newCount;
        _todayReviewCount = today.reviewCount;
        _favorites = Storage.vokFavorites.toSet();
        // Erstanwendung: Tagesziel ist nicht leer → 'due' Modus (jetzt
        // gemeint als "heute lernen"). Sonst 'all'.
        _mode = goal.isNotEmpty ? 'due' : 'all';
        _loading = false;
        _loadFailed = v.isEmpty && DataLoader.lastError != null;
        _filtered = _filterList();
        if (_idx >= _filtered.length) _idx = 0;
        _flipped = false;
        _cardRevealed = false;
        _serve++;
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
        _flipped = false;
        _cardRevealed = false;
        _serve++;
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
      _cardRevealed = false;
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
      _cardRevealed = false;
      _serve++;
    });
  }

  Vocab? get _current =>
      _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

  // P1-2 (2026-08-14): 덱 공유 균일 헤드라인의 실측 후보 — 현재 필터된 덱의
  // 전 표제어/번역. 단어마다 FittedBox 가 몰래 줄여 글자 크기가 튀는 문제의
  // 근본 수리 (custom_pack_play 선례).
  List<String> get _deckKoreans => [for (final v in _filtered) v.korean];

  List<String> _deckTranslations(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return [for (final v in _filtered) v.translationFor(lang)];
  }

  void _persistIdx() => Storage.setVokLastIdx(_idx);

  void _next() {
    setState(() {
      _flipped = false;
      _cardRevealed = false;
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
      _cardRevealed = false;
      _serve++;
      _idx = (_idx - 1 + _filtered.length) % _filtered.length;
    });
    _persistIdx();
  }

  void _random() {
    setState(() {
      _flipped = false;
      _cardRevealed = false;
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
          _cardRevealed = false;
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

  // §P2-5 플립 게이트 힌트 칩 트리거.
  final ValueNotifier<int> _flipHintTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _flipHintTrigger.dispose();
    super.dispose();
  }

  /// ↑ 저장 (§P2-2) — **추가 전용**. 이미 즐겨찾기면 no-op(스프링백만) —
  /// 토글 그대로 쓰면 재스와이프가 해제되고 favorites 모드에선 리스트가
  /// 즉석 축소된다. 해제는 기존 별 탭 경로만.
  void _favoriteAdd() {
    final cur = _current;
    if (cur == null || _favorites.contains(cur.korean)) {
      return;
    }
    _toggleFavorite(cur.korean);
  }

  Future<void> _likeCurrent() async {
    final cur = _current;
    if (cur == null) {
      return;
    }
    await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: cur.korean,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareCurrent() async {
    final cur = _current;
    if (cur == null) {
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    await shareContentStoryWithRecovery(
      context: context,
      korean: cur.korean,
      gloss: cur.translationFor(lang),
    );
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_flipped) {
        _cardRevealed = true;
      }
      _flipped = !_flipped;
    });
  }

  List<String> get _levels {
    final s = _all.map((v) => v.level).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  int _levelCount(String level) => level == 'Alle'
      ? _all.length
      : _all.where((vocab) => vocab.level == level).length;

  Future<void> _showLevelFilter() async {
    final t = AppL10n.of(context);
    final next = await showSoriLevelFilterSheet(
      context: context,
      selected: _level,
      levels: _levels,
      allLabel: t.filterAll,
      countFor: _levelCount,
    );
    if (!mounted || next == null) return;
    _level = next;
    _applyFilters();
  }

  Widget _levelChrome(AppL10n t) {
    return SoriChromeRow(
      onFilterTap: _showLevelFilter,
      filterSemanticLabel: t.filterLevel,
      meta: Text(
        '${_level == 'Alle' ? t.filterAll : _level} · ${_levelCount(_level)}',
        style: SoriTextTheme.of(context).meta,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.filter_list_rounded),
        tooltip: t.filterTitle,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: _showFilterSheet,
      ),
    );
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
      return SoriStandardFrame(
        appBarTitle: t.screenVocabTitle,
        maxWidth: SoriMaxWidth.focus,
        builder: (context, padding) => AppError(
          message: DataLoader.lastError ?? t.errorUnknown,
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
        return SoriStandardFrame(
          appBarTitle: t.screenVocabTitle,
          maxWidth: SoriMaxWidth.focus,
          builder: (context, padding) => SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_wave.png',
            icon: Icons.star_outline_rounded,
            title: t.vocabEmptyFavorites,
            ctaLabel: t.vocabModeAll,
            onCta: () => _setMode('all'),
            accent: SoriColors.like,
          ),
        );
      }
      return SoriStandardFrame(
        appBarTitle: t.screenVocabTitle,
        maxWidth: SoriMaxWidth.focus,
        builder: (context, padding) => Column(
          children: [
            _levelChrome(t),
            Expanded(
              child: SoriEmptyState(
                asset: 'assets/illustrations/mascot/magpie_wave.png',
                icon: Icons.tune_rounded,
                title: t.emptyVocab,
                ctaLabel: t.filterOpenBtn,
                onCta: _showFilterSheet,
              ),
            ),
          ],
        ),
      );
    }

    // §P2-5: 4방향 덱 코치 — 기존 legacyVocab 코치가 이미 표시된 뒤에만.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowSoriDeckCoach(
          context,
          targetKey: _flashCardKey,
          afterCoachIds: const ['legacyVocab'],
        );
      }
    });

    return SoriStudyFrame(
      title: t.screenVocabTitle,
      actions: const [TtsSpeedAction()],
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: SoriAdaptiveStudyBody(
        minHeight: 680,
        child: Column(
          children: [
            // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
            const HanokHeader(
              asset: 'assets/illustrations/hanok/study_classroom.png',
              fallbackIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: Spacing.md),

            _levelChrome(t),
            const SizedBox(height: Spacing.sm),

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
                  label: t.vocabTodayBadge(_todayNewCount, _todayReviewCount),
                  accent: SoriColors.info,
                  selected: _mode == 'due',
                  variant: SoriChipVariant.filled,
                  onTap: () => _setMode('due'),
                  minInteractiveHeight: 44,
                ),
                SoriChip(
                  label: t.vocabFavoritesBadge(_favorites.length),
                  // 즐겨찾기는 하트·책갈피와 같은 석간주로 읽혀야 한다.
                  accent: SoriColors.like,
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

            // 통계는 접근성 배율에서 다음 줄로 흐르며 내용을 숨기지 않는다.
            Wrap(
              spacing: Spacing.xs + 2,
              runSpacing: Spacing.xs,
              children: [
                SoriChip(
                  label: '${_idx + 1}/${_filtered.length}',
                  accent: SoriColors.info,
                ),
                SoriChip(label: '✅ $_correct', accent: SoriColors.success),
                SoriChip(label: '❌ $_wrong', accent: SoriColors.danger),
                SoriChip(label: '⏭ $_skipped', accent: SoriColors.info),
              ],
            ),
            const SizedBox(height: 10),

            // Card with swipe judgment + favorite star overlay
            // 2026-08-14 §P2: 4방향 덱 — 우=Gewusst, 좌=Nicht gewusst,
            // ↑=즐겨찾기 추가 전용, ↓=스킵(기존 ⏭ 카운터).
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  heightFactor: 0.82,
                  child: SoriContentFeed(
                    judgmentsEnabled: _cardRevealed,
                    onBlockedJudgment: () => _flipHintTrigger.value++,
                    flipHintTrigger: _flipHintTrigger,
                    onNext: _gewusst,
                    onHard: _nichtGewusst,
                    onSkip: _skip,
                    onLike: _likeCurrent,
                    onBookmark: _favoriteAdd,
                    onShare: _shareCurrent,
                    onFlip: _onFlip,
                    liked: LikedContentService.isLiked(
                      kind: LikedContentService.vocab,
                      id: v.korean,
                    ),
                    bookmarked: _favorites.contains(v.korean),
                    underlay: _filtered.length > 1
                        ? _faceSlot(_filtered[(_idx + 1) % _filtered.length])
                        : null,
                    knowLabel: t.btnGewusst,
                    hardLabel: t.btnNichtGewusst,
                    skipLabel: t.btnSkip,
                    bookmarkLabel: t.deckActionSave,
                    child: SizedBox(
                      key: const ValueKey('deck-card-slot'),
                      width: double.infinity,
                      height: double.infinity,
                      child: KeyedSubtree(
                        key: _flashCardKey,
                        child: FlipCard(
                          key: ValueKey('legacy-$_serve'),
                          flipped: _flipped,
                          onTap: _onFlip,
                          front: _Front(
                            v: v,
                            koFirst: _koFirst,
                            deckKoreans: _deckKoreans,
                            deckTranslations: _deckTranslations(context),
                          ),
                          back: _Back(
                            v: v,
                            koFirst: _koFirst,
                            deckKoreans: _deckKoreans,
                            deckTranslations: _deckTranslations(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),

            _buildBottomActions(t, v),
            const SizedBox(height: Spacing.xs),
            Center(
              child: Text(
                t.vocabSlowHint,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(color: SoriSurfaces.of(context).textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(AppL10n t, Vocab v) {
    final previous = Semantics(
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
    );
    final listen = SoriPressable(
      onTap: () => TtsService.speak(v.korean),
      onLongPress: () => TtsService.speakSlow(v.korean),
      haptic: SoriHaptic.selection,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SoriRadius.md),
          border: Border.all(
            color: SoriSurfaces.of(context).border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              size: 17,
              color: SoriSurfaces.of(context).text,
            ),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                t.btnHoeren,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).label,
              ),
            ),
          ],
        ),
      ),
    );
    final random = SoriButton.outlined(
      label: t.btnRandom,
      icon: Icons.shuffle,
      fullWidth: true,
      onTap: _random,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < SoriAdaptiveWidth.shortcutRow ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.6;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: previous),
              const SizedBox(height: Spacing.sm),
              listen,
              const SizedBox(height: Spacing.sm),
              random,
            ],
          );
        }
        return Row(
          children: [
            previous,
            const SizedBox(width: Spacing.xs + 2),
            Expanded(child: listen),
            const SizedBox(width: Spacing.xs + 2),
            Expanded(child: random),
          ],
        );
      },
    );
  }

  /// 덱 스택 underlay 용 앞면 슬롯 — 본 카드와 동일한 지오메트리 경로.
  Widget _faceSlot(Vocab v) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: _Front(
        v: v,
        koFirst: _koFirst,
        deckKoreans: _deckKoreans,
        deckTranslations: _deckTranslations(context),
      ),
    );
  }

  Widget _buildDueResult(AppL10n t) {
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final completion = _dueFeedback.current;
    return SoriStandardFrame(
      appBarTitle: t.screenVocabTitle,
      maxWidth: SoriMaxWidth.focus,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_celebrate.png',
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
              const SizedBox(height: Spacing.md),
              _dropdown(AppL10n.of(ctx).filterTheme, _topic, _topics, (v) {
                setLocal(() => _topic = v!);
                _topic = v!;
              }),
              const SizedBox(height: Spacing.lg),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppL10n.of(ctx).filterDirKoDe),
                  value: _koFirst,
                  onChanged: (b) {
                    setLocal(() => _koFirst = b);
                    _koFirst = b;
                  },
                ),
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
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SoriTextTheme.of(context).label,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Front extends StatelessWidget {
  final Vocab v;
  final bool koFirst;

  /// P1-2: 덱 전체 표제어/번역 — 제시어 크기를 덱에서 가장 넓은 텍스트 기준
  /// 하나로 정해 카드마다 크기가 요동치지 않게 한다 ([soriUniformFitSize]).
  final List<String> deckKoreans;
  final List<String> deckTranslations;
  const _Front({
    required this.v,
    required this.koFirst,
    required this.deckKoreans,
    required this.deckTranslations,
  });

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
          // 덱 공유 균일값(soriUniformFitSize)으로 크기를 고정하고(P1-2 —
          // per-word FittedBox 단독은 단어마다 크기가 튄다), 번역은 여러
          // 단어일 수 있어 줄바꿈 허용. FittedBox 는 안전망으로만 남는다.
          final Widget headline = koFirst
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    v.korean,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriUniformFitSize(
                        context,
                        texts: deckKoreans,
                        maxWidth: constraints.maxWidth,
                        cap: soriFillSize(h, 0.19, 38, 92),
                        min: 30,
                        lineHeight: 1.15,
                      ),
                      fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
                    color: SoriColors.info,
                    height: 1.15,
                  ),
                );
          return SingleChildScrollView(
            physics: kSoriCardFacePhysics,
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
                          fontSize: soriFillSize(h, 0.05, 12.5, 26),
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
      MasteryState.reviewDue => (SoriColors.info, Icons.refresh_rounded),
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
                fontFamily: SoriFonts.sans,
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

  /// P1-2: 덱 전체 표제어/번역 — [_Front] 와 같은 균일 크기 계약.
  final List<String> deckKoreans;
  final List<String> deckTranslations;
  const _Back({
    required this.v,
    required this.koFirst,
    required this.deckKoreans,
    required this.deckTranslations,
  });

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
          // 헤드라인 = koFirst 순서상 먼저 보이는 값. 크기는 덱 공유 균일값
          // (P1-2, soriUniformFitSize) — FittedBox 는 안전망으로만 남는다.
          final Widget headline = koFirst
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    v.translationFor(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: soriUniformFitSize(
                        context,
                        texts: deckTranslations,
                        maxWidth: constraints.maxWidth,
                        cap: soriFillSize(h, 0.12, 28, 48),
                        min: 22,
                        lineHeight: 1.2,
                      ),
                      fontWeight: FontWeight.w700,
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
                      fontSize: soriUniformFitSize(
                        context,
                        texts: deckKoreans,
                        maxWidth: constraints.maxWidth,
                        cap: soriFillSize(h, 0.19, 36, 92),
                        min: 30,
                        lineHeight: 1.2,
                      ),
                      fontWeight: FontWeight.w700,
                      color: SoriColors.success,
                      height: 1.2,
                    ),
                  ),
                );
          return SingleChildScrollView(
            physics: kSoriCardFacePhysics,
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
                          fontSize: soriFillSize(h, 0.05, 12.5, 26),
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
