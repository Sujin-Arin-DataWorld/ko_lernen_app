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
  const SoriStageHanokScreen({super.key, this.loadSnapshot});

  /// Test seam — 프로덕션은 기존 진행 스냅샷 서비스를 읽는다.
  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;

  @override
  State<SoriStageHanokScreen> createState() => _SoriStageHanokScreenState();
}

class _SoriStageHanokScreenState extends State<SoriStageHanokScreen> {
  late Future<SoriStageProgressionSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
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
              Expanded(child: HanokWorldScreen(embedded: true)),
              // §P5-2: 고스트 텍스트 버튼 3개 → 일러스트 숏컷 타일 3개.
              // 카운트는 진행 스냅샷(퀘스트·보자기)과 Storage(도장)에서 —
              // 로드 전에는 타일+라벨만 (폴백 우선 배포).
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FutureBuilder<SoriStageProgressionSnapshot>(
                    future: _future,
                    builder: (context, snap) =>
                        _ShortcutTiles(snapshot: snap.data),
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
  const _ShortcutTiles({required this.snapshot});

  final SoriStageProgressionSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    // Quests — ⚠️ 14 는 상수가 아니다: quests_screen `_QuestSummary` 의 계산
    // (done = completed 수, total = active∪completed 수)을 재사용한다.
    // 카탈로그엔 시즌 포함 정의가 있어 시즌 윈도우 안에선 total 이 커진다.
    String? questsCount;
    if (snapshot != null) {
      final quests = snapshot!.quests;
      final done = quests.where((q) => q.completed).length;
      final total = quests.where((q) => q.active || q.completed).length;
      questsCount = '$done / $total';
    }

    // Dojang — 획득 도장 ∩ DancheongMotif 14종 (dojangcheop_screen 선례).
    const motifs = DancheongMotif.values;
    final earned = Storage.earnedStamps.toSet();
    final got = motifs.where((m) => earned.contains(m.name)).length;
    final dojangCount = '$got / ${motifs.length}';

    // Bojagi — Today 의 pendingBojagiCount 와 동일 소스.
    final bojagiCount = snapshot == null
        ? null
        : '${snapshot!.pendingBojagiCount}';

    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            label: t.soriStageQuests,
            count: questsCount,
            thumb: const SoriRewardThumb(
              // 대표 마당 장식 1장 — 실재 화이트리스트 슬러그.
              slug: 'decoration_maehwa',
              earned: true,
              size: 40,
            ),
            route: '/quests',
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
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
            route: '/dojangcheop',
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _ShortcutTile(
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
            route: '/bojagi',
          ),
        ),
      ],
    );
  }
}

/// 숏컷 타일 — 썸네일 → 라벨 → 카운트 세로 구성, 전체가 탭타깃.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.count,
    required this.thumb,
    required this.route,
  });

  final String label;
  final String? count;
  final Widget thumb;
  final String route;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return Semantics(
      button: true,
      label: count == null ? label : '$label, $count',
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 40, child: Center(child: thumb)),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: tt.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count != null)
              Text(count!, style: tt.caption.copyWith(color: s.textMuted)),
          ],
        ),
      ),
    );
  }
}
