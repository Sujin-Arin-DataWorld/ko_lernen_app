import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../widgets/sori/nuancen_c.dart';
import '../widgets/sori/tokens.dart';

/// All authored relationships remain read-only; listening never marks a word learned.
class WordWebStudyScreen extends StatelessWidget {
  const WordWebStudyScreen({super.key, required this.cluster});
  final WordRelationCluster cluster;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return NuancenFrame(
      title: t.wordWebTitle,
      actions: const [NuancenSpeedAction()],
      padding: const EdgeInsets.fromLTRB(16, 16, 16, NuancenC.actionClearance),
      child: ListView(
        children: [
          NuancenPanel(
            minHeight: 110,
            padding: const EdgeInsets.fromLTRB(26, 14, 20, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cluster.sourceKo,
                        style: NuancenC.korean.copyWith(
                          fontSize: 30,
                          height: 1.25,
                        ),
                      ),
                    ),
                    NuancenSpeaker(cluster.sourceKo),
                  ],
                ),
                if (cluster.sourceGloss(lang).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cluster.sourceGloss(lang),
                    style: NuancenC.body.copyWith(height: 1.25),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final item in cluster.synonyms)
            _RelationLane(
              title: t.wordWebSynonymSection,
              color: NuancenC.coral,
              child: _NeighborBlock(item: item, lang: lang),
            ),
          for (final item in cluster.antonyms)
            _RelationLane(
              title: t.wordWebAntonymSection,
              color: NuancenC.indigo,
              child: _NeighborBlock(item: item, lang: lang),
            ),
          for (final item in cluster.related)
            _RelationLane(
              title: t.wordWebRelatedSection,
              color: NuancenC.coral,
              child: _NeighborBlock(item: item, lang: lang),
            ),
          for (final item in cluster.expressions)
            _RelationLane(
              title: t.wordWebExpressionSection,
              color: NuancenC.indigo,
              child: _ExpressionBlock(item: item, lang: lang),
            ),
        ],
      ),
    );
  }
}

class _RelationLane extends StatelessWidget {
  const _RelationLane({
    required this.title,
    required this.color,
    required this.child,
  });
  final String title;
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => NuancenLinkedPanel(
    knot: true,
    inset: 20,
    relationColor: color,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NuancenPanel(
        padding: const EdgeInsets.fromLTRB(26, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color.withValues(alpha: .24)),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xs),
                child: Text(
                  title,
                  style: NuancenC.body.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    ),
  );
}

class _NeighborBlock extends StatelessWidget {
  const _NeighborBlock({required this.item, required this.lang});
  final WordNeighbor item;
  final String lang;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              item.ko,
              style: NuancenC.korean.copyWith(fontSize: 30, height: 1.25),
            ),
          ),
          NuancenSpeaker(item.ko),
        ],
      ),
      Text(item.gloss(lang), style: NuancenC.body.copyWith(height: 1.25)),
      if (item.nuance(lang).isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          item.nuance(lang),
          style: NuancenC.body.copyWith(fontSize: 14, height: 1.25),
        ),
      ],
    ],
  );
}

class _ExpressionBlock extends StatelessWidget {
  const _ExpressionBlock({required this.item, required this.lang});
  final WordExpression item;
  final String lang;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              item.ko,
              style: NuancenC.korean.copyWith(fontSize: 30, height: 1.25),
            ),
          ),
          NuancenSpeaker(item.ko),
        ],
      ),
      Text(item.gloss(lang), style: NuancenC.body.copyWith(height: 1.25)),
      if (item.exampleKo.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          AppL10n.of(context).wordWebExampleLabel,
          style: NuancenC.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.exampleKo,
                style: NuancenC.korean.copyWith(fontSize: 20),
              ),
            ),
            NuancenSpeaker(item.exampleKo),
          ],
        ),
        if (item.example(lang).isNotEmpty)
          Text(item.example(lang), style: NuancenC.body),
      ],
    ],
  );
}
