import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../motion/transitions.dart';
import '../services/word_relation_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/nuancen_c.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import 'word_web_quiz_screen.dart';
import 'word_web_study_screen.dart';

/// Study synonyms, antonyms, related words, and expressions for learned vocab.
///
/// Default scope is words already marked seen. When that set is empty, the
/// empty state can open the complete A1-C2 catalog so every seed stays reachable.
class WordWebScreen extends StatefulWidget {
  const WordWebScreen({super.key, this.clusterLoader, this.seenLoader});

  final Future<List<WordRelationCluster>> Function()? clusterLoader;
  final Set<String> Function()? seenLoader;

  @override
  State<WordWebScreen> createState() => _WordWebScreenState();
}

class _WordWebScreenState extends State<WordWebScreen>
    with ScreenCoachMixin<WordWebScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  WordWebScope _scope = WordWebScope.learned;
  List<WordRelationCluster> _all = const [];
  Set<String> _seenKorean = const {};
  final GlobalKey _listKey = GlobalKey();

  List<WordRelationCluster> get _visible => _loading ? const [] : _filter();

  @override
  String get coachId => 'wordWeb';

  @override
  bool get coachReady => !_loading && _visible.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _listKey,
        title: t.wordWebCoachTitle,
        body: t.wordWebCoachBody,
        icon: Icons.hub_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _seenKorean =
        widget.seenLoader?.call() ?? WordRelationService.learnedKorean();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    List<WordRelationCluster> all = const [];
    var failed = false;
    try {
      final loader = widget.clusterLoader;
      if (loader != null) {
        all = await loader();
      } else {
        all = await WordRelationService.load();
      }
    } catch (_) {
      failed = true;
      all = const [];
    }
    var seen = widget.seenLoader?.call() ?? WordRelationService.learnedKorean();
    if (widget.seenLoader == null) {
      try {
        seen = await WordRelationService.learnedKoreanWithCourse();
      } catch (_) {
        // Keep the sync pack/SRS set when the course snapshot cannot load.
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _all = all;
      _seenKorean = seen;
      _loadFailed = failed;
      _loading = false;
    });
    scheduleCoach();
  }

  Set<String> get _seen => widget.seenLoader?.call() ?? _seenKorean;

  List<WordRelationCluster> _filter() {
    return WordRelationService.filterForLearner(
      clusters: _all,
      seenKorean: _seen,
      scope: _scope,
    );
  }

  void _setScope(WordWebScope scope) {
    if (_scope == scope) {
      return;
    }
    setState(() {
      _scope = scope;
    });
    scheduleCoach();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final visible = _visible;
    return NuancenFrame(
      title: t.wordWebTitle,
      actions: const [NuancenSpeedAction()],
      bottomAction: visible.isEmpty || _loadFailed
          ? null
          : NuancenAction(
              key: const ValueKey('word-web-quiz'),
              label: t.wordWebQuizCta,
              onTap: () => Navigator.of(context).push(
                SoriTransitions.page<void>(
                  (_) => WordWebQuizScreen(
                    clusters: visible,
                    distractorClusters: _all,
                  ),
                ),
              ),
            ),
      child: _loading
          ? const AppLoading()
          : _loadFailed
          ? _loadError(t)
          : CustomScrollView(
              key: _listKey,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _header(t),
                  ),
                ),
                if (visible.isEmpty)
                  SliverToBoxAdapter(child: _empty(t))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _clusterCard(t, visible[i]),
                      ),
                      childCount: visible.length,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _header(AppL10n t) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Semantics(
            header: true,
            child: Text(
              t.wordWebTitle,
              style: NuancenC.heading.copyWith(fontSize: 32, height: 1.15),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(t.wordWebSubtitle(_visible.length), style: NuancenC.body),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            NuancenScopeChoice(
              key: const ValueKey('word-web-filter-learned'),
              label: t.wordWebLearnedFilter,
              selected: _scope == WordWebScope.learned,
              onTap: () => _setScope(WordWebScope.learned),
            ),
            const SizedBox(width: 8),
            NuancenScopeChoice(
              key: const ValueKey('word-web-filter-level'),
              label: t.wordWebLevelFilter,
              selected: _scope == WordWebScope.all,
              onTap: () => _setScope(WordWebScope.all),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _empty(AppL10n t) => NuancenStateBody(
    title: t.wordWebEmptyTitle,
    body: t.wordWebEmptyBody,
    action: NuancenAction(
      label: t.wordWebOpenVocabCta,
      onTap: () async {
        await Navigator.of(context).pushNamed('/vocab');
        if (mounted) {
          // Re-read real pack, SRS and passing-course evidence on return.
          await _load();
        }
      },
    ),
    secondary: SoriButton.ghost(
      label: t.wordWebBrowseLevelCta,
      textStyle: NuancenC.body,
      onTap: () => _setScope(WordWebScope.all),
    ),
  );

  Widget _loadError(AppL10n t) => NuancenStateBody(
    illustration: const NuancenDisconnectedArt(),
    title: t.wordWebLoadErrorTitle,
    body: t.wordWebLoadErrorBody,
    action: NuancenAction(label: t.btnRetry, onTap: _load),
  );

  Widget _clusterCard(AppL10n t, WordRelationCluster cluster) {
    final gloss = cluster.sourceGloss(
      Localizations.localeOf(context).languageCode,
    );
    return NuancenLinkedPanel(
      knot: true,
      child: NuancenPanel(
        key: ValueKey(cluster.id),
        padding: const EdgeInsets.fromLTRB(24, 16, 20, 20),
        onTap: () => Navigator.of(context).push(
          SoriTransitions.page<void>(
            (_) => WordWebStudyScreen(cluster: cluster),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cluster.sourceKo, style: NuancenC.korean),
                      if (gloss.isNotEmpty) Text(gloss, style: NuancenC.body),
                    ],
                  ),
                ),
                NuancenSpeaker(cluster.sourceKo),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.wordWebClusterCount(
                cluster.synonyms.length,
                cluster.antonyms.length,
                cluster.related.length,
                cluster.expressions.length,
              ),
              style: NuancenC.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
