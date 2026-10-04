import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import 'activity_illustration.dart';
import 'button.dart';
import 'localized_copy.dart';
import 'pressable.dart';
import 'tokens.dart';
import 'window_class.dart';

/// Image-first shortcut. Full descriptions and details remain in the catalog.
class SoriCatalogShortcut extends StatelessWidget {
  const SoriCatalogShortcut({
    super.key,
    required this.entry,
    required this.onTap,
  });
  final ActivityCatalogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = localCopy(context, entry.title);
    final type = SoriTextTheme.of(context);
    return Semantics(
      button: true,
      label: AppL10n.of(context).soriStageOpenActivity(title),
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          pressScale: .99,
          surfaceDepth: 2,
          surfaceEdgeColor: SoriColors.lightBorder,
          child: Material(
            color: SoriColors.lightSurfaceRaised,
            borderRadius: SoriRadius.brLg,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      activityIllustrationAsset(entry.id),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          AppL10n.of(context).catalogImageUnavailable,
                          style: type.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: type.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SoriColors.lightText,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: SoriColors.primary,
                        ),
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
}

/// Natural-height cards with whole artwork and an independent details action.
class SoriCatalogCard extends StatelessWidget {
  const SoriCatalogCard({
    super.key,
    required this.entry,
    required this.onStart,
    required this.onDetails,
    this.featured = false,
    this.status,
    this.recent = false,
  });
  final ActivityCatalogEntry entry;
  final VoidCallback onStart;
  final VoidCallback onDetails;
  final bool featured;
  final String? status;
  final bool recent;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final title = localCopy(context, entry.title);
    final games = entry.tab == SoriStageTab.games;
    final color = featured
        ? (games
              ? SoriActivityColors.actionGold
              : SoriActivityColors.hanokStage)
        : SoriColors.lightSurfaceRaised;
    final ink = featured ? SoriColors.onFill(color) : s.text;
    final secondary = type.bodySmall.copyWith(
      fontSize: 14,
      height: 1.4,
      color: ink,
    );
    Widget art(double width) => ClipRRect(
      borderRadius: SoriRadius.brMd,
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset(
            activityIllustrationAsset(entry.id),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                t.catalogImageUnavailable,
                textAlign: TextAlign.center,
                style: secondary,
              ),
            ),
          ),
        ),
      ),
    );
    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (featured ? type.h2 : type.body).copyWith(
            fontSize: featured ? 26 : 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(localCopy(context, entry.description), style: secondary),
        const SizedBox(height: Spacing.sm),
        Text(t.soriStageMinutes(entry.minutes), style: secondary),
      ],
    );
    final content = LayoutBuilder(
      builder: (context, bounds) {
        final large = MediaQuery.textScalerOf(context).scale(16) >= 24;
        if (featured) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              information,
              const SizedBox(height: Spacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Transform.rotate(
                  angle: SoriMotion.reduceMotion(context) ? 0 : -.035,
                  child: art(bounds.maxWidth.clamp(0, 190)),
                ),
              ),
            ],
          );
        }
        if (bounds.maxWidth < SoriAdaptiveWidth.catalogCardArtRow || large) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              art(112),
              const SizedBox(height: Spacing.sm),
              information,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            art(96),
            const SizedBox(width: Spacing.md),
            Expanded(child: information),
          ],
        );
      },
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: featured
              ? BorderRadius.circular(SoriRadius.xl)
              : SoriRadius.brLg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(featured ? Spacing.xl : Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: t.soriStageOpenActivity(title),
                child: SoriPressable(
                  key: ValueKey('catalog-start-${entry.id}'),
                  onTap: onStart,
                  onLongPress: onDetails,
                  pressScale: .99,
                  child: content,
                ),
              ),
              if (recent || status != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  [
                    if (recent) t.catalogRecentlyOpened,
                    if (status != null) status!,
                  ].join(' · '),
                  style: secondary,
                ),
              ],
              if (featured) ...[
                const SizedBox(height: Spacing.md),
                SoriButton(
                  label: t.catalogStartSession,
                  illustrationAsset:
                      SoriArtwork.action(entry.id) ??
                      (games ? activityIllustrationAsset(entry.id) : null),
                  trailingIcon: Icons.arrow_forward_rounded,
                  accent: games
                      ? SoriColors.primary
                      : SoriActivityColors.actionGold,
                  onTap: onStart,
                  fullWidth: true,
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: ValueKey('catalog-details-${entry.id}'),
                  onPressed: onDetails,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Semantics(
                    label: t.soriStageActivityDetails(title),
                    excludeSemantics: true,
                    child: Text(
                      featured ? t.catalogHowItWorks : t.catalogDetails,
                      style: secondary.copyWith(fontWeight: FontWeight.w600),
                    ),
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
