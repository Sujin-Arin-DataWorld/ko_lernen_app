import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../services/tts_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// Read-only study page for one word-web cluster.
class WordWebStudyScreen extends StatelessWidget {
  const WordWebStudyScreen({super.key, required this.cluster});

  final WordRelationCluster cluster;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cluster.sourceKo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [TtsSpeedAction()],
      ),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: SoriContentClamp(
            base: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xl,
            ),
            builder: (context, padding) => ListView(
              padding: padding,
              children: [
                SoriCard(
                  variant: SoriCardVariant.hero,
                  accent: SoriColors.accent,
                  tinted: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cluster.sourceKo,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: SoriColors.primary,
                        ),
                        onPressed: () => TtsService.speak(cluster.sourceKo),
                      ),
                    ],
                  ),
                ),
                if (cluster.synonyms.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebSynonymSection),
                  ...cluster.synonyms.map(
                    (item) => _NeighborBlock(
                      item: item,
                      lang: lang,
                      muted: s.textMuted,
                    ),
                  ),
                ],
                if (cluster.antonyms.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebAntonymSection),
                  ...cluster.antonyms.map(
                    (item) => _NeighborBlock(
                      item: item,
                      lang: lang,
                      muted: s.textMuted,
                    ),
                  ),
                ],
                if (cluster.related.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebRelatedSection),
                  ...cluster.related.map(
                    (item) => _NeighborBlock(
                      item: item,
                      lang: lang,
                      muted: s.textMuted,
                    ),
                  ),
                ],
                if (cluster.expressions.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebExpressionSection),
                  ...cluster.expressions.map(
                    (item) => _ExpressionBlock(
                      item: item,
                      lang: lang,
                      muted: s.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeighborBlock extends StatelessWidget {
  const _NeighborBlock({
    required this.item,
    required this.lang,
    required this.muted,
  });

  final WordNeighbor item;
  final String lang;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final nuance = item.nuance(lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoriCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.ko,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: SoriColors.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => TtsService.speak(item.ko),
                ),
              ],
            ),
            Text(
              item.gloss(lang),
              style: TextStyle(color: muted, height: 1.35),
            ),
            if (nuance.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(nuance, style: TextStyle(height: 1.4, color: muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpressionBlock extends StatelessWidget {
  const _ExpressionBlock({
    required this.item,
    required this.lang,
    required this.muted,
  });

  final WordExpression item;
  final String lang;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final example = item.example(lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoriCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.ko,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: SoriColors.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => TtsService.speak(item.ko),
                ),
              ],
            ),
            Text(
              item.gloss(lang),
              style: TextStyle(color: muted, height: 1.35),
            ),
            if (item.exampleKo.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                t.wordWebExampleLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Spacing.xs),
              GestureDetector(
                onTap: () => TtsService.speak(item.exampleKo),
                child: Text(
                  item.exampleKo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (example.isNotEmpty)
                Text(example, style: TextStyle(color: muted, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
