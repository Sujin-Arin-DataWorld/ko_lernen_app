import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/learner_level.dart';
import '../models/word_relation.dart';
import '../services/learner_level_selection.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/word_relation_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import 'word_web_quiz_screen.dart';
import 'word_web_study_screen.dart';

/// Study synonyms, antonyms, related words, and expressions for learned vocab.
///
/// Default scope is words already marked seen. When that set is empty, the
/// empty state can open a cumulative level browse so the seed stays reachable.
class WordWebScreen extends StatefulWidget {
  const WordWebScreen({
    super.key,
    this.clusterLoader,
    this.seenLoader,
    this.levelLoader,
  });

  final Future<List<WordRelationCluster>> Function()? clusterLoader;
  final Set<String> Function()? seenLoader;
  final LearnerLevel Function()? levelLoader;

  @override
  State<WordWebScreen> createState() => _WordWebScreenState();
}

class _WordWebScreenState extends State<WordWebScreen>
    with ScreenCoachMixin<WordWebScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  WordWebScope _scope = WordWebScope.learned;
  List<WordRelationCluster> _all = const [];
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
    if (!mounted) {
      return;
    }
    setState(() {
      _all = all;
      _loadFailed = failed;
      _loading = false;
    });
    scheduleCoach();
  }

  Set<String> get _seen =>
      widget.seenLoader?.call() ?? WordRelationService.learnedKorean();

  LearnerLevel get _level =>
      widget.levelLoader?.call() ??
      learnerLevelForStoredCode(Storage.userLevelCode);

  List<WordRelationCluster> _filter() {
    return WordRelationService.filterForLearner(
      clusters: _all,
      seenKorean: _seen,
      level: _level,
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

    return Scaffold(
      appBar: SoriAppBar(
        title: t.wordWebTitle,
        actions: const [TtsSpeedAction()],
      ),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: _loading
              ? const AppLoading()
              : _loadFailed
              ? _loadError(t)
              : Column(
                  children: [
                    _header(t),
                    Expanded(
                      child: _visible.isEmpty
                          ? _empty(t)
                          : ListView.separated(
                              key: _listKey,
                              padding: soriClampPadding(
                                MediaQuery.sizeOf(context).width,
                                base: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                              ),
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: Spacing.xs),
                              itemBuilder: (_, i) =>
                                  _clusterCard(t, _visible[i]),
                            ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _visible.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoriButton(
                      key: const ValueKey('word-web-quiz'),
                      label: t.wordWebQuizCta,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.accent,
                      fullWidth: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => WordWebQuizScreen(
                              clusters: _visible,
                              distractorClusters: _all,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _header(AppL10n t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Row(
        children: [
          const Mascot.tiger(
            emotion: MascotEmotion.thinking,
            size: 72,
            animate: false,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.wordWebSubtitle(_visible.length),
                  style: SoriTextTheme.of(context).bodySmall,
                ),
                const SizedBox(height: Spacing.xs),
                Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.xs,
                  children: [
                    _scopeLink(
                      key: const ValueKey('word-web-filter-learned'),
                      label: t.wordWebLearnedFilter,
                      selected: _scope == WordWebScope.learned,
                      onTap: () => _setScope(WordWebScope.learned),
                    ),
                    _scopeLink(
                      key: const ValueKey('word-web-filter-level'),
                      label: t.wordWebLevelFilter,
                      selected: _scope == WordWebScope.level,
                      onTap: () => _setScope(WordWebScope.level),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppL10n t) {
    return Center(
      child: SoriEmptyState(
        asset: 'assets/illustrations/empty/studyroom_waiting.png',
        icon: Icons.hub_outlined,
        title: t.wordWebEmptyTitle,
        body: t.wordWebEmptyBody,
        ctaLabel: t.wordWebOpenVocabCta,
        onCta: () async {
          await Navigator.of(context).pushNamed('/vocab');
          if (mounted) {
            setState(() {});
            scheduleCoach();
          }
        },
        secondaryLabel: t.wordWebBrowseLevelCta,
        onSecondary: () => _setScope(WordWebScope.level),
      ),
    );
  }

  Widget _loadError(AppL10n t) {
    return Center(
      child: SoriEmptyState(
        asset: 'assets/illustrations/error/lost_magpie.png',
        icon: Icons.hub_outlined,
        title: t.wordWebLoadErrorTitle,
        body: t.wordWebLoadErrorBody,
        ctaLabel: t.btnRetry,
        onCta: _load,
      ),
    );
  }

  Widget _clusterCard(AppL10n t, WordRelationCluster cluster) {
    final gloss = cluster.sourceGloss(
      Localizations.localeOf(context).languageCode,
    );
    return SoriCard(
      key: ValueKey(cluster.id),
      accent: SoriColors.accent,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WordWebStudyScreen(cluster: cluster),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cluster.sourceKo, style: SoriTextTheme.of(context).h3),
                if (gloss.isNotEmpty)
                  Text(gloss, style: SoriTextTheme.of(context).cardSubtitle),
                Text(
                  t.wordWebClusterCount(
                    cluster.synonyms.length,
                    cluster.antonyms.length,
                    cluster.related.length,
                    cluster.expressions.length,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SoriTextTheme.of(context).cardSubtitle,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => TtsService.speak(cluster.sourceKo),
          ),
        ],
      ),
    );
  }

  Widget _scopeLink({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final tt = SoriTextTheme.of(context);
    final color = selected
        ? SoriColors.accent
        : SoriSurfaces.of(context).textMuted;
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Text(
        label,
        style: (selected ? tt.label : tt.bodySmall).copyWith(
          color: color,
          decoration: selected ? TextDecoration.underline : TextDecoration.none,
          decorationColor: color,
        ),
      ),
    );
  }
}
