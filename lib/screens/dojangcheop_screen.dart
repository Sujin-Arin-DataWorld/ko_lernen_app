import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/pack_progress_service.dart';
import '../services/stamp_entitlement_reconciler.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sori_term.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/window_class.dart';

/// 도장첩 — 팩 클리어로 획득한 단청·생활문화 도장 컬렉션.
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
    _reconcileEntitlements();
  }

  Future<void> _reconcileEntitlements() async {
    final result = await StampEntitlementReconciler.reconcile(
      progress: PackProgressService.getAll(),
    );
    if (!mounted) {
      return;
    }
    if (result.addedCount > 0) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          soriToast(
            context,
            AppL10n.of(context).dojangReconciled(result.addedCount),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final earned = Storage.earnedStamps.toSet();
    const motifs = DancheongMotif.values;
    final got = motifs.where((m) => earned.contains(m.name)).length;
    final dancheong = motifs
        .where((motif) => motif.spec.series == StampSeries.dancheong)
        .toList(growable: false);
    final livingCulture = motifs
        .where((motif) => motif.spec.series == StampSeries.livingCulture)
        .toList(growable: false);

    return SoriStandardFrame(
      appBarTitle: t.dojangTitle,
      maxWidth: SoriMaxWidth.hub,
      actions: const [CulturalHelpButton(termId: 'dojangcheop')],
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, padding) => ListView(
        padding: padding,
        children: [
          SoriPageHeader(
            title: t.dojangTitle,
            body: t.dojangProgress(got, motifs.length),
            titleStyle: SoriTextTheme.of(context).cultureTitle,
          ),
          if (got == 0) ...[
            const SizedBox(height: Spacing.lg),
            Semantics(
              container: true,
              explicitChildNodes: true,
              child: SoriEmptyState(
                asset: 'assets/illustrations/mascot/magpie_encourage.png',
                icon: Icons.workspace_premium_outlined,
                title: t.dojangEmptyTitle,
                body: t.dojangEmptyBody,
                ctaLabel: t.dojangEmptyCta,
                onCta: () => Navigator.of(context).pushNamed('/vocab'),
              ),
            ),
          ],
          if (got > 0) ...[
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
                  Semantics(
                    container: true,
                    child: Text(
                      t.dojangDecorHintBody,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: s.textMuted),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  SoriButton.outlined(
                    label: t.dojangDecorHintCta,
                    fullWidth: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/sarangbang/furnish'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          KeyedSubtree(
            key: _gridKey,
            child: Column(
              children: [
                _StampSeriesSection(
                  title: t.dojangSeriesDancheongTitle,
                  body: t.dojangSeriesDancheongBody,
                  motifs: dancheong,
                  earned: earned,
                ),
                const SizedBox(height: Spacing.lg),
                _StampSeriesSection(
                  title: t.dojangSeriesLivingCultureTitle,
                  body: t.dojangSeriesLivingCultureBody,
                  motifs: livingCulture,
                  earned: earned,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// If [title] contains the literal word "Dancheong" (both DE "Dancheong-…"
/// and EN "Dancheong …" series titles do), wrap just that word in a tappable
/// [SoriTerm.span] pointing at the `dancheong` glossary entry (§W-C C3).
/// Falls back to a plain heading when the word is absent, so a future
/// translation change degrades gracefully instead of breaking.
Widget _seriesTitle(BuildContext context, String title) {
  final style = SoriTextTheme.of(context).h3;
  const needle = 'Dancheong';
  final index = title.indexOf(needle);
  if (index < 0) {
    return Text(title, style: style);
  }
  final before = title.substring(0, index);
  final after = title.substring(index + needle.length);
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        if (before.isNotEmpty) TextSpan(text: before),
        SoriTerm.span(
          termId: 'dancheong',
          text: needle,
          style: style,
          surface: 'dojangcheop_series_title',
        ),
        if (after.isNotEmpty) TextSpan(text: after),
      ],
    ),
  );
}

class _StampSeriesSection extends StatelessWidget {
  const _StampSeriesSection({
    required this.title,
    required this.body,
    required this.motifs,
    required this.earned,
  });

  final String title;
  final String body;
  final List<DancheongMotif> motifs;
  final Set<String> earned;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final got = motifs.where((motif) => earned.contains(motif.name)).length;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seriesTitle(context, title),
          const SizedBox(height: Spacing.xs),
          Text(
            body,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: surfaces.textMuted),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            t.dojangProgress(got, motifs.length),
            style: SoriTextTheme.of(
              context,
            ).meta.copyWith(color: SoriColors.contentCta),
          ),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = soriGridColumns(
                constraints.maxWidth,
                target: 118,
                min: 3,
                max: 6,
                outerPadding: 0,
              );
              final cellWidth =
                  (constraints.maxWidth - Spacing.md * (columns - 1)) / columns;
              final stampSize = cellWidth.clamp(64.0, 96.0).toDouble();
              final nameStyle = SoriTextTheme.of(context).meta;
              final textScaler = MediaQuery.textScalerOf(context);
              final textDirection = Directionality.of(context);
              final locale = Localizations.localeOf(context);
              final maxNameHeight = motifs.fold<double>(0, (height, motif) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: dancheongMotifName(t, motif),
                    style: nameStyle,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: textDirection,
                  textScaler: textScaler,
                  locale: locale,
                )..layout(maxWidth: cellWidth);
                return painter.height > height ? painter.height : height;
              });
              final naturalCellHeight =
                  stampSize + Spacing.xs + maxNameHeight + 1;
              final legacyCellHeight = cellWidth / 0.78;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: motifs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: naturalCellHeight > legacyCellHeight
                      ? naturalCellHeight
                      : legacyCellHeight,
                  mainAxisSpacing: Spacing.md,
                  crossAxisSpacing: Spacing.md,
                ),
                itemBuilder: (context, index) {
                  final motif = motifs[index];
                  return _StampCell(
                    motif: motif,
                    earned: earned.contains(motif.name),
                  );
                },
              );
            },
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
          container: true,
          image: true,
          label: earned ? t.dojangStampEarned(name) : t.dojangStampLocked(name),
          excludeSemantics: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
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
              const SizedBox(height: Spacing.xs),
              Text(
                name,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).meta.copyWith(
                  color: earned
                      ? SoriSurfaces.of(context).text
                      : SoriSurfaces.of(context).textDim,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
