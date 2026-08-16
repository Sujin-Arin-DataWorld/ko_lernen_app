import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/screen_background.dart';
import '../../widgets/sori/tokens.dart';
import '../bojagi_screen.dart' show kBojagiClosed;
import '../hanok_world_screen.dart';
import 'sori_stage_common.dart';

class SoriStageHanokScreen extends StatefulWidget {
  const SoriStageHanokScreen({
    super.key,
    this.loadSnapshot,
    this.active = true,
    this.worldForTesting,
  });

  /// Test seam; production uses the shared Stage progression snapshot.
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  /// The shell keeps every tab alive. Refresh progression whenever this tab
  /// becomes visible so work completed in Today/Learn is reflected here.
  final bool active;

  /// Keeps shortcut tests independent from the production world's async
  /// unlock-reveal layer. Production callers always render [HanokWorldScreen].
  @visibleForTesting
  final Widget? worldForTesting;

  @override
  State<SoriStageHanokScreen> createState() => _SoriStageHanokScreenState();
}

class _SoriStageHanokScreenState extends State<SoriStageHanokScreen> {
  Future<SoriStageProgressionSnapshot>? _future;

  Future<SoriStageProgressionSnapshot> _load() =>
      (widget.loadSnapshot ?? SoriStageProgressionService.load)();

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _future = _load();
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageHanokScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active || oldWidget.loadSnapshot != widget.loadSnapshot)) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openShortcut(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      // Quest completion, stamp awards, and Bojagi claims can all change the
      // three captions. Refresh only after returning so no stale count is
      // presented by this long-lived tab in the shell's IndexedStack.
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SoriScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              SoriContentClamp(
                maxWidth: 960,
                base: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                builder: (context, padding) => Padding(
                  padding: padding,
                  child: SoriStageRootHeader(
                    eyebrow: t.soriStageNavHanok,
                    title: t.soriStageHanokTitle,
                    body: t.soriStageHanokBody,
                  ),
                ),
              ),
              Expanded(
                child:
                    widget.worldForTesting ??
                    const HanokWorldScreen(embedded: true),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FutureBuilder<SoriStageProgressionSnapshot>(
                    future: _future,
                    builder: (context, snapshot) {
                      final ready =
                          snapshot.connectionState == ConnectionState.done &&
                          !snapshot.hasError;
                      return _ShortcutTiles(
                        snapshot: ready ? snapshot.data : null,
                        onOpen: _openShortcut,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTiles extends StatelessWidget {
  const _ShortcutTiles({required this.snapshot, required this.onOpen});

  final SoriStageProgressionSnapshot? snapshot;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    String? questsCount;
    if (snapshot != null) {
      final quests = snapshot!.quests;
      final done = quests.where((quest) => quest.completed).length;
      final total = quests
          .where((quest) => quest.active || quest.completed)
          .length;
      questsCount = '$done / $total';
    }

    const motifs = DancheongMotif.values;
    final earned = Storage.earnedStamps.toSet();
    final got = motifs.where((motif) => earned.contains(motif.name)).length;
    final dojangCount = '$got / ${motifs.length}';

    final bojagiCount = snapshot == null
        ? null
        : '${snapshot!.pendingBojagiCount}';

    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            id: 'quests',
            label: t.soriStageQuests,
            count: questsCount,
            thumb: const SoriRewardThumb(
              // 대표 마당 장식 1장 — 실재 화이트리스트 슬러그.
              slug: 'decoration_maehwa',
              earned: true,
              size: 40,
              semantic: '',
            ),
            onTap: () => onOpen('/quests'),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            id: 'dojang',
            label: t.soriStageDojang,
            count: dojangCount,
            thumb: Image.asset(
              'assets/illustrations/stamps/stamp_lotus.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.approval_rounded,
                size: 32,
                color: SoriColors.accent,
              ),
            ),
            onTap: () => onOpen('/dojangcheop'),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
            id: 'bojagi',
            label: t.soriStageBojagi,
            count: bojagiCount,
            thumb: Image.asset(
              kBojagiClosed,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.redeem_rounded,
                size: 32,
                color: SoriColors.goldOnLight,
              ),
            ),
            onTap: () => onOpen('/bojagi'),
          ),
        ),
      ],
    );
  }
}

/// 숏컷 타일 — 썸네일 → 라벨 → 카운트 세로 구성, 전체가 탭타깃.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.id,
    required this.label,
    required this.count,
    required this.thumb,
    required this.onTap,
  });

  final String id;
  final String label;
  final String? count;
  final Widget thumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return KeyedSubtree(
      key: ValueKey('hanok-shortcut-$id'),
      child: Semantics(
        // A count change replaces the semantic annotation as well as its
        // visible Text. This avoids an old cached label surviving a
        // FutureBuilder refresh in accessibility mode.
        key: ValueKey('hanok-shortcut-semantics-$id-${count ?? 'loading'}'),
        button: true,
        label: count == null ? label : '$label, $count',
        onTap: onTap,
        child: ExcludeSemantics(
          child: SoriCard(
            variant: SoriCardVariant.compact,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 40, child: Center(child: thumb)),
                const SizedBox(height: Spacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: tt.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (count != null)
                  Text(
                    count!,
                    key: ValueKey('hanok-shortcut-count-$id'),
                    style: tt.caption.copyWith(color: s.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
