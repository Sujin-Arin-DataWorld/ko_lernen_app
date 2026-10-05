import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/cultural_glossary.dart';
import '../../services/cultural_glossary_repository.dart';
import '../../services/scenario_culture_link_repository.dart';
import 'card.dart';
import 'cultural_help.dart';
import 'tokens.dart';

typedef ScenarioCultureEntriesLoader =
    Future<List<CulturalGlossaryEntry>> Function(String scenarioId);

/// Resolves optional culture entries for one live scenario.
///
/// The link registry and glossary are both presentation-only catalogs. Missing
/// or malformed data returns an empty list so culture UI can never block the
/// saved-result flow.
Future<List<CulturalGlossaryEntry>> loadScenarioCultureEntries(
  String scenarioId,
) async {
  final links = await ScenarioCultureLinkRepository.load();
  final termIds = links?.termIdsForScenario(scenarioId) ?? const <String>[];
  if (termIds.isEmpty) {
    return const <CulturalGlossaryEntry>[];
  }

  final glossary = await CulturalGlossaryRepository.load();
  if (glossary == null) {
    return const <CulturalGlossaryEntry>[];
  }

  return [
    for (final termId in termIds)
      if (glossary.entry(termId) case final entry?) entry,
  ];
}

/// Optional result-stage card showing cultural terms encountered in a scene.
///
/// This widget owns no progress, reward, mastery, or storage state. It is
/// absent until both the scenario link and glossary entries resolve.
class ScenarioCultureCard extends StatefulWidget {
  const ScenarioCultureCard({
    super.key,
    required this.scenarioId,
    this.entriesLoader = loadScenarioCultureEntries,
  });

  final String scenarioId;
  final ScenarioCultureEntriesLoader entriesLoader;

  @override
  State<ScenarioCultureCard> createState() => _ScenarioCultureCardState();
}

class _ScenarioCultureCardState extends State<ScenarioCultureCard> {
  late Future<List<CulturalGlossaryEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.entriesLoader(widget.scenarioId);
  }

  @override
  void didUpdateWidget(covariant ScenarioCultureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scenarioId != widget.scenarioId ||
        oldWidget.entriesLoader != widget.entriesLoader) {
      _entries = widget.entriesLoader(widget.scenarioId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CulturalGlossaryEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null || entries.isEmpty) {
          return const SizedBox.shrink();
        }

        final t = AppL10n.of(context);
        final surfaces = SoriSurfaces.of(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: Semantics(
            container: true,
            label: t.scenarioCultureInSceneTitle,
            child: SoriCard(
              key: Key('scenario_culture_card_${widget.scenarioId}'),
              variant: SoriCardVariant.base,
              accent: SoriColors.accent,
              tinted: true,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_stories_outlined,
                        color: SoriColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.scenarioCultureInSceneTitle,
                              style: SoriTextTheme.of(
                                context,
                              ).h3.copyWith(color: SoriColors.accent),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              t.scenarioCultureInSceneBody,
                              style: SoriTextTheme.of(context).bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: Spacing.lg,
                        color: surfaces.border.withValues(alpha: .6),
                      ),
                    _ScenarioCultureTermRow(entry: entries[index]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScenarioCultureTermRow extends StatelessWidget {
  const _ScenarioCultureTermRow({required this.entry});

  final CulturalGlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final meaning = entry.localized(languageCode).meaning;
    final semanticsLabel = t.culturalHelpSemantics(entry.korean);

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        key: Key('scenario_culture_term_${entry.termId}'),
        borderRadius: SoriRadius.brSm,
        onTap: () => showCulturalTermSheet(context, entry),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            entry.korean,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          Text(
                            entry.romanization,
                            style: SoriTextTheme.of(
                              context,
                            ).bodySmall.copyWith(color: surfaces.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(Icons.chevron_right_rounded, color: surfaces.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
