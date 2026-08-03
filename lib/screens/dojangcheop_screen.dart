import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// 도장첩 — 팩 클리어로 획득한 단청 도장 컬렉션 (8 motif).
///
/// 획득 = 풀컬러 도장(PNG). 미획득 = 흐릿 + 자물쇠. 0개면 빈 상태.
/// 획득 영속: `Storage.earnedStamps`(`DancheongMotif.name` slug).
class DojangcheopScreen extends StatefulWidget {
  const DojangcheopScreen({super.key});

  @override
  State<DojangcheopScreen> createState() => _DojangcheopScreenState();
}

class _DojangcheopScreenState extends State<DojangcheopScreen>
    with ScreenCoachMixin<DojangcheopScreen> {
  // ── 코치마크 타겟 ──
  final GlobalKey _gridKey = GlobalKey();

  @override
  String get coachId => 'dojang';

  @override
  bool get coachReady => Storage.earnedStamps.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _gridKey,
        title: t.coachDojangTitle,
        body: t.coachDojangBody,
        icon: Icons.workspace_premium_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    scheduleCoach();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final earned = Storage.earnedStamps.toSet();
    const motifs = DancheongMotif.values;
    final got = motifs.where((m) => earned.contains(m.name)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.dojangTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: got == 0
              ? Center(
                  child: SoriEmptyState(
                    asset: 'assets/illustrations/mascot/magpie_encourage.png',
                    icon: Icons.workspace_premium_outlined,
                    title: t.dojangEmptyTitle,
                    body: t.dojangEmptyBody,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    padding: soriClampPadding(
                      constraints.maxWidth,
                      base: const EdgeInsets.all(Spacing.lg),
                    ),
                    children: [
                      SoriSectionHeader(t.dojangTitle),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        t.dojangProgress(got, motifs.length),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: s.textMuted,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      LayoutBuilder(
                        builder: (context, c) => GridView.count(
                          key: _gridKey,
                          crossAxisCount: soriGridColumns(
                            c.maxWidth,
                            target: 110,
                            min: 3,
                            max: 6,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: Spacing.lg,
                          crossAxisSpacing: Spacing.lg,
                          children: [
                            for (final m in motifs)
                              _StampCell(
                                motif: m,
                                earned: earned.contains(m.name),
                              ),
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
}

class _StampCell extends StatelessWidget {
  final DancheongMotif motif;
  final bool earned;
  const _StampCell({required this.motif, required this.earned});

  @override
  Widget build(BuildContext context) {
    if (earned) {
      return Center(
        child: DancheongStamp(motif: motif, size: 96, stamped: true),
      );
    }
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.20, child: DancheongStamp(motif: motif, size: 96)),
          Icon(
            Icons.lock_outline_rounded,
            size: 26,
            color: SoriSurfaces.of(context).textDim,
          ),
        ],
      ),
    );
  }
}
