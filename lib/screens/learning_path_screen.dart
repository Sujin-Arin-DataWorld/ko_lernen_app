import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import '../services/hanok_stage_service.dart';
import '../services/pack_progress_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';

/// **Lernpfad (학습 경로)** — Duolingo식 진척 시각화.
///
/// "내가 어디 있고, 다음 한 걸음이 무엇인지"를 한 화면에 보여준다:
///   1. 상단: 한옥 12단계 (현재 단계 이미지 + 전체 클리어 진행률)
///   2. 본문: 레벨(A1~B2)별 단어팩 노드 — 완료(체크)/현재("Jetzt")/잠금(자물쇠).
///
/// 데이터: [HanokStageService.currentStage] + [PackProgressService.loadLevelView]
/// (둘 다 기존 서비스 — 새 저장소 없음). 노드 탭 → `/vocab/pack`.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LevelGroup {
  final String level;
  final List<({VocabPack pack, PackProgress progress})> packs;
  const _LevelGroup(this.level, this.packs);
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  bool _loading = true;
  HanokStage _stage = HanokStage.empty;
  final List<_LevelGroup> _groups = [];
  int _clearedTotal = 0;
  int _packTotal = 0;
  String? _nowPackId; // 첫 미완 + 잠금해제 팩 = "지금 할 것"

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stage = await HanokStageService.currentStage();
    final groups = <_LevelGroup>[];
    int cleared = 0;
    int total = 0;
    String? now;
    for (final lv in _levels) {
      final view = await PackProgressService.loadLevelView(lv);
      groups.add(_LevelGroup(lv, view));
      for (final e in view) {
        total++;
        if (e.progress.status == PackStatus.cleared) {
          cleared++;
        }
        if (now == null &&
            e.progress.status != PackStatus.cleared &&
            e.progress.status != PackStatus.locked) {
          now = e.pack.id;
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _stage = stage;
      _groups
        ..clear()
        ..addAll(groups);
      _clearedTotal = cleared;
      _packTotal = total;
      _nowPackId = now;
      _loading = false;
    });
  }

  Future<void> _openPack(VocabPack pack, PackStatus status) async {
    final t = AppL10n.of(context);
    if (status == PackStatus.locked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.pathLockedHint)));
      return;
    }
    await Navigator.pushNamed(context, '/vocab/pack', arguments: pack.id);
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(t.pathTitle),
        backgroundColor: s.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: soriClampPadding(
                  MediaQuery.sizeOf(context).width,
                  base: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                ),
                children: [
                  _HanokHeader(
                    stage: _stage,
                    cleared: _clearedTotal,
                    total: _packTotal,
                  ),
                  const SizedBox(height: Spacing.xl),
                  for (final g in _groups) ..._levelSection(t, g),
                ],
              ),
            ),
    );
  }

  List<Widget> _levelSection(AppL10n t, _LevelGroup g) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cleared = g.packs
        .where((e) => e.progress.status == PackStatus.cleared)
        .length;
    return [
      Padding(
        padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
        child: Row(
          children: [
            Text(
              g.level,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: s.text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.pathLevelPacks(cleared, g.packs.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.textMuted,
              ),
            ),
          ],
        ),
      ),
      for (final e in g.packs)
        _PathNode(
          label: VocabPackService.displayLabel(e.pack.id, lang: lang),
          status: e.progress.status,
          fraction: e.progress.progressFraction,
          isNow: e.pack.id == _nowPackId,
          onTap: () => _openPack(e.pack, e.progress.status),
        ),
      const SizedBox(height: Spacing.lg),
    ];
  }
}

// ─── 한옥 단계 헤더 ──────────────────────────────────────────────────────────

class _HanokHeader extends StatelessWidget {
  const _HanokHeader({
    required this.stage,
    required this.cleared,
    required this.total,
  });

  final HanokStage stage;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final frac = total == 0 ? 0.0 : cleared / total;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: SoriRadius.brLg,
        border: Border.all(color: s.border),
        boxShadow: SoriElevation.low,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_light.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SoriColors.primarySoft,
                      SoriColors.lightSurfaceAlt,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.temple_buddhist_outlined,
                  size: 56,
                  color: SoriColors.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.pathHanokStage(stage.ordinal + 1),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.pathHanokSub,
                  style: TextStyle(
                    fontSize: 13,
                    color: s.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SoriProgressBar(value: frac, animated: true),
                const SizedBox(height: 6),
                Text(
                  t.pathLevelPacks(cleared, total),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 팩 노드 ─────────────────────────────────────────────────────────────────

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.label,
    required this.status,
    required this.fraction,
    required this.isNow,
    required this.onTap,
  });

  final String label;
  final PackStatus status;
  final double fraction;
  final bool isNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final cleared = status == PackStatus.cleared;
    final locked = status == PackStatus.locked;

    final Color ringColor = cleared
        ? SoriColors.primary
        : isNow
        ? SoriColors.tiger
        : locked
        ? s.border
        : SoriColors.gold;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriPressable(
        onTap: onTap,
        haptic: locked ? SoriHaptic.light : SoriHaptic.selection,
        child: Opacity(
          opacity: locked ? 0.62 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: isNow
                  ? SoriColors.tiger.withValues(alpha: 0.08)
                  : s.surface,
              borderRadius: SoriRadius.brMd,
              border: Border.all(
                color: isNow ? SoriColors.tiger : s.border,
                width: isNow ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                _node(ringColor, cleared, locked),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: s.text,
                              ),
                            ),
                          ),
                          if (isNow) ...[
                            const SizedBox(width: Spacing.sm),
                            _nowBadge(t),
                          ],
                        ],
                      ),
                      if (!locked && !cleared && fraction > 0) ...[
                        const SizedBox(height: 6),
                        SoriProgressBar(value: fraction, thickness: 5),
                      ],
                    ],
                  ),
                ),
                Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right,
                  size: 20,
                  color: s.textDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _node(Color ring, bool cleared, bool locked) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cleared ? SoriColors.primary : Colors.transparent,
        border: Border.all(color: ring, width: 2.4),
      ),
      alignment: Alignment.center,
      child: Icon(
        cleared
            ? Icons.check
            : locked
            ? Icons.lock_outline
            : Icons.play_arrow_rounded,
        size: 20,
        color: cleared ? Colors.white : ring,
      ),
    );
  }

  Widget _nowBadge(AppL10n t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SoriColors.tiger,
        borderRadius: SoriRadius.brPill,
      ),
      child: Text(
        t.pathNodeNow,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
