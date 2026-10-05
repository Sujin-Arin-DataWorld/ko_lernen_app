import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/cultural_glossary.dart';
import '../services/culture_discovery_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/sori/tokens.dart';

typedef CultureStoriesLoader = Future<CultureDiscoverySnapshot> Function();

/// Hanok collection of culture encountered through completed scenarios.
///
/// Discovery is projected from existing scenario completion evidence; opening
/// this screen never writes progress or creates a second collection ledger.
class CultureStoriesScreen extends StatefulWidget {
  const CultureStoriesScreen({super.key, this.loadSnapshot});

  /// Test seam. Production derives from [CultureDiscoveryService].
  final CultureStoriesLoader? loadSnapshot;

  @override
  State<CultureStoriesScreen> createState() => _CultureStoriesScreenState();
}

class _CultureStoriesScreenState extends State<CultureStoriesScreen> {
  late Future<CultureDiscoverySnapshot> _future;

  Future<CultureDiscoverySnapshot> _load() =>
      (widget.loadSnapshot ?? CultureDiscoveryService().load)();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.cultureStoriesTitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, padding) => FutureBuilder<CultureDiscoverySnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: padding,
              children: [
                SoriEmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: t.cultureStoriesTitle,
                  body: t.loadErrorTryAgain,
                  ctaLabel: t.btnRetry,
                  onCta: _retry,
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return ListView(
              padding: padding,
              children: const [
                SizedBox(height: Spacing.xxl),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: padding,
            children: [
              Text(t.cultureStoriesBody, style: SoriTextTheme.of(context).body),
              const SizedBox(height: Spacing.sm),
              Text(
                '${data.discoveredCount} / ${data.availableTermCount}',
                key: const ValueKey('culture-stories-count'),
                style: SoriTextTheme.of(context).caption.copyWith(
                  color: SoriSurfaces.of(context).textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              if (data.storyArcs.isNotEmpty) ...[
                for (var index = 0; index < data.storyArcs.length; index++) ...[
                  if (index > 0) const SizedBox(height: Spacing.md),
                  _CultureStoryArcCard(projection: data.storyArcs[index]),
                ],
                const SizedBox(height: Spacing.lg),
              ],
              if (data.isEmpty)
                SoriEmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: t.cultureStoriesEmptyTitle,
                  body: t.cultureStoriesEmptyBody,
                )
              else
                for (var index = 0; index < data.entries.length; index++) ...[
                  if (index > 0) const SizedBox(height: Spacing.md),
                  _CultureStoryCard(entry: data.entries[index]),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CultureStoryArcCard extends StatelessWidget {
  const _CultureStoryArcCard({required this.projection});

  final CultureStoryArcProjection projection;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final arc = projection.arc;
    final surfaces = SoriSurfaces.of(context);

    return SoriCard(
      key: Key('culture_story_arc_${arc.arcId}'),
      variant: SoriCardVariant.hanji,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.route_outlined,
                color: SoriColors.accent,
                size: 28,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  arc.title.forLanguage(languageCode),
                  style: SoriTextTheme.of(context).h3,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${projection.completedStepCount} / ${projection.stepCount}',
                key: Key('culture_story_arc_count_${arc.arcId}'),
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(color: surfaces.textMuted),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            arc.summary.forLanguage(languageCode),
            style: SoriTextTheme.of(context).body,
          ),
        ],
      ),
    );
  }
}

class _CultureStoryCard extends StatelessWidget {
  const _CultureStoryCard({required this.entry});

  final CulturalGlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localized = entry.localized(languageCode);
    final surfaces = SoriSurfaces.of(context);

    return SoriCard(
      key: Key('culture_story_${entry.termId}'),
      variant: SoriCardVariant.base,
      onTap: () => showCulturalTermSheet(context, entry),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: SoriColors.accent,
            size: 28,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(entry.korean, style: SoriTextTheme.of(context).h3),
                    Text(
                      entry.romanization,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: surfaces.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(localized.meaning, style: SoriTextTheme.of(context).body),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Icon(Icons.chevron_right_rounded, color: surfaces.textMuted),
        ],
      ),
    );
  }
}
