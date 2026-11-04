import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../widgets/sori/nuancen_c.dart';

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
      child: ListView(
        children: [
          NuancenPanel(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cluster.sourceKo,
                        style: NuancenC.korean.copyWith(fontSize: 36),
                      ),
                      if (cluster.sourceGloss(lang).isNotEmpty)
                        Text(cluster.sourceGloss(lang), style: NuancenC.body),
                    ],
                  ),
                ),
                NuancenSpeaker(cluster.sourceKo),
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
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NuancenPanel(
        padding: const EdgeInsets.fromLTRB(24, 18, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: .17),
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  title,
                  style: NuancenC.body.copyWith(fontWeight: FontWeight.w700),
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
          Expanded(child: Text(item.ko, style: NuancenC.korean)),
          NuancenSpeaker(item.ko),
        ],
      ),
      Text(item.gloss(lang), style: NuancenC.body),
      if (item.nuance(lang).isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(item.nuance(lang), style: NuancenC.body),
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
          Expanded(child: Text(item.ko, style: NuancenC.korean)),
          NuancenSpeaker(item.ko),
        ],
      ),
      Text(item.gloss(lang), style: NuancenC.body),
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
