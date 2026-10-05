import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/cultural_glossary.dart';
import '../../models/smalltalk_context_case.dart';
import '../../services/cultural_glossary_repository.dart';
import '../../services/scenario_culture_link_repository.dart';
import 'button.dart';
import 'card.dart';
import 'cultural_help.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'motion.dart';
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
    this.learnerLevel,
    this.entriesLoader = loadScenarioCultureEntries,
    this.previewCompanionPreference,
  });

  final String scenarioId;
  final String? learnerLevel;
  final ScenarioCultureEntriesLoader entriesLoader;

  /// Storage-free presentation seam for tests and galleries. Production leaves
  /// this null so the card reacts to [MascotPreference.preference].
  final CompanionPreference? previewCompanionPreference;

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
                  _ScenarioCultureHeader(
                    previewPreference: widget.previewCompanionPreference,
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
                  if (widget.learnerLevel != null) ...[
                    Divider(
                      height: Spacing.lg,
                      color: surfaces.border.withValues(alpha: .6),
                    ),
                    _ScenarioPragmaticTransfer(
                      learnerLevel: widget.learnerLevel!,
                    ),
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

class _ScenarioCultureHeader extends StatelessWidget {
  const _ScenarioCultureHeader({required this.previewPreference});

  final CompanionPreference? previewPreference;

  @override
  Widget build(BuildContext context) {
    return CompanionBuilder(
      previewPreference: previewPreference,
      noneBuilder: (context) => _buildHeader(
        context,
        leading: const Icon(
          Icons.auto_stories_outlined,
          color: SoriColors.accent,
          size: 24,
        ),
        body: AppL10n.of(context).scenarioCultureInSceneBody,
      ),
      builder: (context, kind) {
        final isMagpie = kind == MascotKind.magpie;
        final t = AppL10n.of(context);
        final mascot = ExcludeSemantics(
          child: Mascot(
            kind: kind,
            emotion: isMagpie ? MascotEmotion.surprised : MascotEmotion.neutral,
            size: 52,
            animate: isMagpie,
          ),
        );
        return _buildHeader(
          context,
          leading: SoriEntrance(
            key: ValueKey('scenario-culture-companion-${kind.name}'),
            duration: isMagpie ? SoriMotion.medium : SoriMotion.slow,
            slideY: isMagpie ? 10 : 4,
            startScale: isMagpie ? .92 : .98,
            child: mascot,
          ),
          body: isMagpie
              ? t.scenarioCultureMagpieReaction
              : t.scenarioCultureTigerReaction,
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Widget leading,
    required String body,
  }) {
    final t = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
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
              Text(body, style: SoriTextTheme.of(context).bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScenarioPragmaticTransfer extends StatelessWidget {
  const _ScenarioPragmaticTransfer({required this.learnerLevel});

  final String learnerLevel;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/illustrations/tactile/hahoe_scholar.png',
              width: 32,
              height: 48,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.scenarioCultureTransferTitle,
                    style: SoriTextTheme.of(context).h3,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    t.scenarioCultureTransferBody,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SoriButton.outlined(
          key: const ValueKey('scenario_culture_pragmatic_transfer'),
          label: t.scenarioCultureTransferAction,
          fullWidth: true,
          onTap: () => Navigator.of(context).pushNamed(
            '/smalltalk/context',
            arguments: SmalltalkContextRequest(
              level: learnerLevel.toLowerCase(),
            ),
          ),
        ),
      ],
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
