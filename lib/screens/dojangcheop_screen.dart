import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// 도장첩 — 팩 클리어로 획득한 단청 도장 컬렉션 (14 motif).
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
    Analytics.featureUsed('dojangcheop');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final earned = Storage.earnedStamps.toSet();
    const motifs = DancheongMotif.values;
    final got = motifs.where((m) => earned.contains(m.name)).length;

    return SoriStandardFrame(
      appBarTitle: t.dojangTitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, padding) => got == 0
          ? Center(
              child: Padding(
                padding: padding,
                child: SoriEmptyState(
                  asset: 'assets/illustrations/mascot/magpie_encourage.png',
                  icon: Icons.workspace_premium_outlined,
                  title: t.dojangEmptyTitle,
                  body: t.dojangEmptyBody,
                ),
              ),
            )
          : ListView(
              padding: padding,
              children: [
                SoriPageHeader(
                  title: t.dojangTitle,
                  body: t.dojangProgress(got, motifs.length),
                  titleStyle: SoriTextTheme.of(context).cultureTitle,
                ),
                const SizedBox(height: Spacing.lg),
                // 도장은 이 컬렉션에 남으면서 개인 방에도 한 번 배치할 수
                // 있다. 획득 상태와 방 배치는 서로 다른 투영이다.
                SoriCard(
                  variant: SoriCardVariant.base,
                  accent: SoriColors.info,
                  tinted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.dojangDecorHintBody,
                        style: SoriTextTheme.of(
                          context,
                        ).bodySmall.copyWith(color: s.textMuted),
                      ),
                      const SizedBox(height: Spacing.md),
                      SoriButton.outlined(
                        label: t.dojangDecorHintCta,
                        fullWidth: true,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed('/sarangbang/furnish'),
                      ),
                    ],
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
                      outerPadding: 0,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Spacing.lg,
                    crossAxisSpacing: Spacing.lg,
                    children: [
                      for (final m in motifs)
                        _StampCell(motif: m, earned: earned.contains(m.name)),
                    ],
                  ),
                ),
              ],
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
    final t = AppL10n.of(context);
    final name = dancheongMotifName(t, motif);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(64.0, 96.0).toDouble();
        return Semantics(
          image: true,
          label: earned ? t.dojangStampEarned(name) : t.dojangStampLocked(name),
          excludeSemantics: true,
          child: Center(
            child: earned
                ? DancheongStamp(motif: motif, size: size, stamped: true)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.20,
                        child: DancheongStamp(motif: motif, size: size),
                      ),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: size * 0.27,
                        color: SoriSurfaces.of(context).textDim,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
