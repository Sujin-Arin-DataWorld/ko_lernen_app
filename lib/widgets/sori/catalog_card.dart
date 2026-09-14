import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import 'activity_illustration.dart';
import 'button.dart';
import 'card.dart';
import 'localized_copy.dart';
import 'tokens.dart';
import 'window_class.dart';

/// Catalog-only natural-height cards. Details is an independent focusable
/// action, outside the route button's semantics and gesture target.
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
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final title = localCopy(context, entry.title);
    final radius = featured ? SoriRadius.brLg : SoriRadius.brMd;
    final secondary = text.bodySmall.copyWith(fontSize: 15, height: 1.35);
    Widget art({double? width}) => SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.asset(
          activityIllustrationAsset(entry.id),
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
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
    final description = Text(
      localCopy(context, entry.description),
      style: secondary.copyWith(color: surfaces.textMuted),
    );
    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: featured
              ? text.h2.copyWith(fontSize: 21, height: 1.35)
              : text.body.copyWith(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
        ),
        const SizedBox(height: Spacing.xs),
        description,
        if (featured) ...[
          const SizedBox(height: Spacing.sm),
          Text(t.soriStageMinutes(entry.minutes), style: secondary),
        ],
      ],
    );
    final detail = TextButton(
      key: ValueKey('catalog-details-${entry.id}'),
      onPressed: onDetails,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
      ),
      child: Semantics(
        label: t.soriStageActivityDetails(title),
        excludeSemantics: true,
        child: Text(
          featured ? t.catalogHowItWorks : t.catalogDetails,
          style: secondary.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? SoriColors.primaryOnDark
                : SoriColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final content = featured
        ? LayoutBuilder(
            builder: (context, constraints) {
              final illustration = ClipRRect(
                borderRadius: SoriRadius.brSm,
                child: art(width: 128),
              );
              if (constraints.maxWidth < SoriAdaptiveWidth.compactMetadataRow ||
                  MediaQuery.textScalerOf(context).scale(16) >= 24) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    illustration,
                    const SizedBox(height: Spacing.md),
                    information,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  illustration,
                  const SizedBox(width: 12),
                  Expanded(child: information),
                ],
              );
            },
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [art(), const SizedBox(height: 8), information],
          );
    final inset = featured ? 16.0 : 10.0;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: SoriCard.resolvedBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: surfaces.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: ValueKey('catalog-start-${entry.id}'),
              onTap: onStart,
              onLongPress: onDetails,
              child: Semantics(
                label: t.soriStageOpenActivity(title),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
                  child: content,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (recent || status != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      [
                        if (recent) t.catalogRecentlyOpened,
                        if (status != null) status!,
                      ].join(' · '),
                      style: secondary.copyWith(color: surfaces.textMuted),
                    ),
                  ],
                  if (featured) ...[
                    const SizedBox(height: 12),
                    SoriButton(label: t.catalogStartSession, onTap: onStart),
                    Align(alignment: Alignment.centerLeft, child: detail),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.soriStageMinutes(entry.minutes),
                            style: secondary.copyWith(
                              color: surfaces.textMuted,
                            ),
                          ),
                        ),
                        Flexible(child: detail),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
