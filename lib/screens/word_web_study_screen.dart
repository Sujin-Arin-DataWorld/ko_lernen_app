import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../services/tts_service.dart';
import '../widgets/sori/app_bar.dart';
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

    return Scaffold(
      appBar: SoriAppBar(
        title: cluster.sourceKo,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cluster.sourceKo,
                              style: SoriTextTheme.of(context).display,
                            ),
                            if (cluster.sourceGloss(lang).isNotEmpty)
                              Text(
                                cluster.sourceGloss(lang),
                                style: SoriTextTheme.of(context).bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '${t.ttsListen}: ${cluster.sourceKo}',
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
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
                    (item) => _NeighborBlock(item: item, lang: lang),
                  ),
                ],
                if (cluster.antonyms.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebAntonymSection),
                  ...cluster.antonyms.map(
                    (item) => _NeighborBlock(item: item, lang: lang),
                  ),
                ],
                if (cluster.related.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebRelatedSection),
                  ...cluster.related.map(
                    (item) => _NeighborBlock(item: item, lang: lang),
                  ),
                ],
                if (cluster.expressions.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  SoriSectionHeader(t.wordWebExpressionSection),
                  ...cluster.expressions.map(
                    (item) => _ExpressionBlock(item: item, lang: lang),
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
  const _NeighborBlock({required this.item, required this.lang});

  final WordNeighbor item;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
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
                  child: Text(item.ko, style: SoriTextTheme.of(context).h3),
                ),
                IconButton(
                  tooltip: '${t.ttsListen}: ${item.ko}',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: SoriColors.primary,
                  ),
                  onPressed: () => TtsService.speak(item.ko),
                ),
              ],
            ),
            Text(item.gloss(lang), style: SoriTextTheme.of(context).bodySmall),
            if (nuance.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(nuance, style: SoriTextTheme.of(context).bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpressionBlock extends StatelessWidget {
  const _ExpressionBlock({required this.item, required this.lang});

  final WordExpression item;
  final String lang;

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
                  child: Text(item.ko, style: SoriTextTheme.of(context).h3),
                ),
                IconButton(
                  tooltip: '${t.ttsListen}: ${item.ko}',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: SoriColors.primary,
                  ),
                  onPressed: () => TtsService.speak(item.ko),
                ),
              ],
            ),
            Text(item.gloss(lang), style: SoriTextTheme.of(context).bodySmall),
            if (item.exampleKo.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                t.wordWebExampleLabel,
                style: SoriTextTheme.of(context).label,
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.exampleKo,
                      style: SoriTextTheme.of(context).body,
                    ),
                  ),
                  IconButton(
                    tooltip: '${t.ttsListen}: ${item.exampleKo}',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: SoriColors.primary,
                    ),
                    onPressed: () => TtsService.speak(item.exampleKo),
                  ),
                ],
              ),
              if (example.isNotEmpty)
                Text(example, style: SoriTextTheme.of(context).bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
