import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../motion/transitions.dart';
import '../services/tts_service.dart';
import '../services/word_relation_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
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

    return Scaffold(
      appBar: SoriAppBar(
        title: t.wordWebTitle,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
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
                          SoriTransitions.page<void>(
                            (_) => WordWebQuizScreen(
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
        Spacing.sm,
        Spacing.lg,
        Spacing.xs,
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
                // §W-A2 재조사(실측): 200%·320dp 에서 두 칩이 한 줄에 안
                // 들어가 Wrap 이 세로로 접혀(2줄×48dp) 헤더 Row 가 61px
                // 넘쳤다 — 세로로 접히는 대신 가로 스크롤로 항상 한 줄을
                // 유지한다(칩 폭이 아무리 커져도 헤더 높이가 고정된다).
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SoriChip(
                        key: const ValueKey('word-web-filter-learned'),
                        label: t.wordWebLearnedFilter,
                        selected: _scope == WordWebScope.learned,
                        icon: _scope == WordWebScope.learned
                            ? Icons.check_rounded
                            : null,
                        accent: SoriColors.accent,
                        variant: SoriChipVariant.outlined,
                        maxLines: null,
                        minInteractiveHeight: 48,
                        onTap: () => _setScope(WordWebScope.learned),
                      ),
                      const SizedBox(width: Spacing.md),
                      SoriChip(
                        key: const ValueKey('word-web-filter-level'),
                        label: t.wordWebLevelFilter,
                        selected: _scope == WordWebScope.all,
                        icon: _scope == WordWebScope.all
                            ? Icons.check_rounded
                            : null,
                        accent: SoriColors.accent,
                        variant: SoriChipVariant.outlined,
                        maxLines: null,
                        minInteractiveHeight: 48,
                        onTap: () => _setScope(WordWebScope.all),
                      ),
                    ],
                  ),
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
        asset: 'assets/illustrations/mascot/magpie_encourage.png',
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
        onSecondary: () => _setScope(WordWebScope.all),
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
          SoriTransitions.page<void>(
            (_) => WordWebStudyScreen(cluster: cluster),
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
                  style: SoriTextTheme.of(context).cardSubtitle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '${t.ttsListen}: ${cluster.sourceKo}',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary,
            ),
            onPressed: () => TtsService.speak(cluster.sourceKo),
          ),
        ],
      ),
    );
  }
}
