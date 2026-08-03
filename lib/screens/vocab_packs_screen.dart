import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/curriculum.dart';
import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import '../services/pack_progress_service.dart';
import '../services/premium_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/pack_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// **Vocab Packs Screen** — Phase 2 의 새 vocab 진입 화면.
///
/// 사용자 레벨의 모든 팩을 2-Spalten Grid 로 보여준다. 잠금 상태는
/// `PackProgressService.effectiveStatus()` 로 계산. 첫 팩만 처음에 열려있고,
/// 이전 팩 클리어 시 다음 팩 unlock.
///
/// 상단에는 진행 요약 ("A1: 3 / 24 클리어 — 기둥 세우는 중") +
/// HanokHeader 이미지.
class VocabPacksScreen extends StatefulWidget {
  const VocabPacksScreen({super.key, this.courseUnitId});

  /// Restricts the library to packs that contain graph-linked practice for a
  /// mission. A null value remains the unrestricted browse library.
  final String? courseUnitId;

  @override
  State<VocabPacksScreen> createState() => _VocabPacksScreenState();
}

class _VocabPacksScreenState extends State<VocabPacksScreen> {
  bool _loading = true;
  String _level = 'A1';
  List<({VocabPack pack, PackProgress progress})> _packs = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Library browsing is intentionally independent from diagnosis/placement
    // and the sequential course mission.
    final code = Storage.browseLevelCode ?? Storage.placementLevelCode;
    _level = _normalizeLevel(code);
    _load();
  }

  String _normalizeLevel(String? code) {
    final c = (code ?? '').toUpperCase();
    if (c == 'A1' || c == 'A2' || c == 'B1' || c == 'B2') return c;
    return 'A1';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final packs = await PackProgressService.loadLevelView(_level);
      final catalog = widget.courseUnitId == null
          ? null
          : await CurriculumCatalog.load();
      if (!mounted) return;
      final contentIds = catalog == null
          ? const <String>{}
          : catalog
                .linksForCourseUnit(widget.courseUnitId!)
                .where(
                  (link) => link.contentKind == CurriculumContentKind.vocab,
                )
                .map((link) => link.contentId)
                .toSet();
      final scoped = catalog == null
          ? packs
          : packs
                .where(
                  (entry) => entry.pack.words.any(
                    (word) => contentIds.contains(word.id),
                  ),
                )
                .toList();
      setState(() {
        _packs = scoped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  Future<void> _switchLevel(String level) async {
    if (widget.courseUnitId != null) return;
    if (level == _level) return;
    HapticFeedback.selectionClick();
    await Storage.setBrowseLevelCode(level.toLowerCase());
    if (!mounted) return;
    setState(() => _level = level);
    await _load();
  }

  void _onPackTap(VocabPack pack) {
    // Premium-Gate: A1 ist kostenlos, A2/B1/B2 erfordern ein Abo.
    // Freie Nutzer dürfen alle Level durchstöbern (Verkaufsfläche); erst das
    // Lernen eines A2/B1/B2-Packs öffnet die Paywall.
    if (_level != 'A1' && !PremiumService.isPremium) {
      PremiumService.gate(context).then((ok) {
        if (ok && mounted) _openPack(pack);
      });
      return;
    }
    _openPack(pack);
  }

  void _openPack(VocabPack pack) {
    Navigator.of(context).pushNamed('/vocab/pack', arguments: pack.id).then((
      _,
    ) {
      // 복귀 시 진행도 새로고침 — 보스 클리어 후 다음 팩 unlock 반영.
      if (mounted) _load();
    });
  }

  void _onLockedTap(VocabPack pack) {
    final prev = PackProgressService.previousPackInLevel(
      pack.id,
      _packs.map((e) => e.pack).toList(),
    );
    final t = AppL10n.of(context);
    final msg = prev == null
        ? t.vocabPackLockedNoPrev
        : t.vocabPackLockedHint(VocabPackService.displayLabel(prev.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _clearedCount =>
      _packs.where((e) => e.progress.status == PackStatus.cleared).length;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t.vocabPacksTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: const AppLoading(),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabPacksTitle)),
        body: AppError(message: _loadError!, onRetry: _load),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.vocabPacksTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: t.dojangTitle,
            onPressed: () => Navigator.of(context).pushNamed('/dojangcheop'),
          ),
          if (widget.courseUnitId == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              tooltip: t.vocabPacksLevelMenu,
              onSelected: _switchLevel,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'A1', child: Text('A1')),
                PopupMenuItem(value: 'A2', child: Text('A2')),
                PopupMenuItem(value: 'B1', child: Text('B1')),
                PopupMenuItem(value: 'B2', child: Text('B2')),
              ],
            ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: soriClampPadding(
              MediaQuery.sizeOf(context).width,
              maxWidth: SoriBreakpoints.grid,
              base: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            ),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: HanokHeader(
                    asset: 'assets/illustrations/hanok/study_classroom.png',
                    fallbackIcon: Icons.collections_bookmark_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LevelProgressHeader(
                    level: _level,
                    cleared: _clearedCount,
                    total: _packs.length,
                  ),
                ),
                if (_packs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SoriEmptyState(
                      asset: 'assets/illustrations/mascot/magpie_wave.png',
                      icon: Icons.menu_book_outlined,
                      title: t.vocabPacksEmptyTitle,
                      body: t.vocabPacksEmptyBody,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: Spacing.md, bottom: 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: Spacing.md,
                            crossAxisSpacing: Spacing.md,
                            childAspectRatio: 0.92,
                          ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final e = _packs[i];
                        return PackCard(
                          packId: e.pack.id,
                          title: VocabPackService.displayLabel(e.pack.id),
                          progress: e.progress,
                          onTap: () => _onPackTap(e.pack),
                          onLockedTap: () => _onLockedTap(e.pack),
                        );
                      }, childCount: _packs.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelProgressHeader extends StatelessWidget {
  final String level;
  final int cleared;
  final int total;
  const _LevelProgressHeader({
    required this.level,
    required this.cleared,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final pct = total == 0 ? 0.0 : (cleared / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, Spacing.md, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(level, style: SoriTextTheme.of(context).h2),
              const SizedBox(width: Spacing.sm),
              Text(
                t.vocabPacksProgressLabel(cleared, total),
                style: SoriTextTheme.of(context).bodySmall,
              ),
              const Spacer(),
              _StageLabel(level: level, pct: pct),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: s.text.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(SoriColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stage-Label — "터 잡는 중", "기둥 세우는 중", "기와 올리는 중", "종갓집" …
/// Phase 3 의 한옥 시각화와 연결되는 텍스트 단서.
class _StageLabel extends StatelessWidget {
  final String level;
  final double pct;
  const _StageLabel({required this.level, required this.pct});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final label = _stageText(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SoriRadius.pill),
        border: Border.all(
          color: SoriColors.primary.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: SoriTextTheme.of(
          context,
        ).cardSubtitle.copyWith(color: s.text, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _stageText(AppL10n t) {
    // Mapping mit Plan §5.1 abgeglichen (Hanok-Stages):
    //   A1 0-25%   → terrain
    //   A1 25-50%  → foundation
    //   A1 50-75%  → pillars
    //   A1 75-100% → beams
    //   A1 100%    → thatch
    //   A2 → tile transition
    //   B1 → gate + windows
    //   B2 → side building → jongga
    final level = this.level;
    if (level == 'A1') {
      if (pct < 0.25) return t.hanokStageEmpty;
      if (pct < 0.50) return t.hanokStageFoundation;
      if (pct < 0.75) return t.hanokStagePillars;
      if (pct < 1.00) return t.hanokStageBeams;
      return t.hanokStageThatch;
    }
    if (level == 'A2') {
      if (pct < 0.50) return t.hanokStageTilePartial;
      if (pct < 1.00) return t.hanokStageTileComplete;
      return t.hanokStageDancheong;
    }
    if (level == 'B1') {
      if (pct < 0.50) return t.hanokStageGate;
      return t.hanokStageWindows;
    }
    // B2
    if (pct < 0.50) return t.hanokStageSideBuilding;
    return t.hanokStageJongga;
  }
}
