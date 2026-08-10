import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/tokens.dart';

/// A scan-first feature directory for learners who do not yet know which
/// Hangul Sori activity solves their current learning need.
///
/// This is intentionally a destination, rather than a permanent list of every
/// activity in the primary navigation. The tab stays short and stable while
/// this screen makes the full product surface searchable and scannable.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _DiscoverCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final allFeatures = _features(t);
    final visibleFeatures = allFeatures
        .where((feature) {
          final matchesCategory =
              _selectedCategory == null ||
              feature.category == _selectedCategory;
          final query = _query.trim().toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              feature.title.toLowerCase().contains(query) ||
              feature.subtitle.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
    final showBookPriority = _query.trim().isEmpty && _selectedCategory == null;

    return Scaffold(
      appBar: AppBar(title: Text(t.navDiscover)),
      body: SafeArea(
        child: SoriContentClamp(
          base: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xxxl,
          ),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              Text(t.discoverTitle, style: tt.h1),
              const SizedBox(height: Spacing.xs),
              Text(t.discoverSubtitle, style: tt.bodySmall),
              const SizedBox(height: Spacing.lg),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.discoverSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: surfaces.surface,
                  border: const OutlineInputBorder(
                    borderRadius: SoriRadius.brMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: t.discoverCategoryAll,
                      selected: _selectedCategory == null,
                      onSelected: () =>
                          setState(() => _selectedCategory = null),
                    ),
                    for (final category in _DiscoverCategory.values)
                      _CategoryChip(
                        label: category.label(t),
                        selected: _selectedCategory == category,
                        onSelected: () =>
                            setState(() => _selectedCategory = category),
                      ),
                  ],
                ),
              ),
              if (showBookPriority) ...[
                const SizedBox(height: Spacing.lg),
                SoriSectionHeader(t.discoverStartHere),
                FeaturedModuleCard(
                  icon: Icons.document_scanner_outlined,
                  title: t.homeBookCardTitle,
                  subtitle: t.homeBookCardDesc,
                  accent: SoriColors.primary,
                  ribbonType: 'new',
                  onTap: () => Navigator.pushNamed(context, '/book'),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              SoriSectionHeader(
                _selectedCategory?.label(t) ?? t.discoverAllTools,
              ),
              if (visibleFeatures.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                  child: Center(
                    child: Text(t.discoverNoResults, style: tt.bodySmall),
                  ),
                )
              else
                _FeatureGrid(
                  features: showBookPriority
                      ? visibleFeatures
                            .where((feature) => feature.route != '/book')
                            .toList(growable: false)
                      : visibleFeatures,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DiscoverFeature> _features(AppL10n t) => [
    _DiscoverFeature(
      category: _DiscoverCategory.learn,
      icon: Icons.document_scanner_outlined,
      title: t.homeBookCardTitle,
      subtitle: t.homeBookCardDesc,
      accent: SoriColors.primary,
      route: '/book',
      ribbonType: 'new',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.learn,
      icon: Icons.text_fields_rounded,
      title: t.moduleHangulTitle,
      subtitle: t.moduleHangulDesc,
      accent: SoriColors.primary,
      route: '/hangul',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.learn,
      icon: Icons.edit_note_rounded,
      title: t.moduleGrammarTitle,
      subtitle: t.moduleGrammarDesc,
      accent: SoriColors.primary,
      route: '/grammar',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.learn,
      icon: Icons.forum_rounded,
      title: t.moduleScenariosTitle,
      subtitle: t.moduleScenariosDesc,
      accent: SoriColors.primary,
      route: '/scenarios',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.learn,
      icon: Icons.style_outlined,
      title: t.moduleVocabTitle,
      subtitle: t.moduleVocabDesc,
      accent: SoriColors.primary,
      route: '/vocab',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.refresh_rounded,
      title: t.reviewTitle,
      subtitle: t.reviewEmptyTitle,
      accent: SoriColors.tiger,
      route: '/review',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.local_fire_department_rounded,
      title: t.dailyTitle,
      subtitle: t.dailyDesc,
      accent: SoriColors.goldOnLight,
      route: '/daily',
      ribbonType: 'new',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.sort_by_alpha_rounded,
      title: t.gameChosungTitle,
      subtitle: t.gameChosungDesc,
      accent: SoriColors.goldOnLight,
      route: '/chosung',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.grid_4x4_rounded,
      title: t.gameWordleTitle,
      subtitle: t.gameWordleDesc,
      accent: SoriColors.goldOnLight,
      route: '/wordle',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.short_text_rounded,
      title: t.clozeTitle,
      subtitle: t.clozeDesc,
      accent: SoriColors.goldOnLight,
      route: '/cloze',
      ribbonType: 'new',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.bolt_rounded,
      title: t.speedMatchTitle,
      subtitle: t.speedMatchDesc,
      accent: SoriColors.goldOnLight,
      route: '/speed_match',
      ribbonType: 'new',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.reorder_rounded,
      title: t.satzArcadeTitle,
      subtitle: t.satzArcadeDesc,
      accent: SoriColors.goldOnLight,
      route: '/satz_arcade',
      ribbonType: 'new',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.link_rounded,
      title: t.gameKkeunmariTitle,
      subtitle: t.gameKkeunmariDesc,
      accent: SoriColors.goldOnLight,
      route: '/kkeunmari',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.headphones_rounded,
      title: t.moduleListenTitle,
      subtitle: t.listeningSubtitle,
      accent: SoriColors.goldOnLight,
      route: '/listening',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.practice,
      icon: Icons.chat_bubble_outline_rounded,
      title: t.homeSmalltalkCardTitle,
      subtitle: t.homeSmalltalkCardDesc,
      accent: SoriColors.goldOnLight,
      route: '/smalltalk',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.words,
      icon: Icons.collections_bookmark_outlined,
      title: t.homeBookshelfCardTitle,
      subtitle: t.homeBookshelfCardDesc,
      accent: SoriColors.accent,
      route: '/bookshelf',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.words,
      icon: Icons.search_rounded,
      title: t.wbSearchTitle,
      subtitle: t.wbSearchCta,
      accent: SoriColors.accent,
      route: '/wordbook/search',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.words,
      icon: Icons.bolt_rounded,
      title: t.hardWordsTitle,
      subtitle: t.hardWordsEmptyTitle,
      accent: SoriColors.accent,
      route: '/hard_words',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.route_outlined,
      title: t.pathTitle,
      subtitle: t.homePathCardSub,
      accent: SoriColors.primary,
      route: '/path',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.bar_chart_rounded,
      title: t.moduleStatsTitle,
      subtitle: t.moduleStatsDesc,
      accent: SoriColors.primary,
      route: '/stats',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.workspace_premium_outlined,
      title: t.homeQuestsCardTitle,
      subtitle: t.homeQuestsCardDesc,
      accent: SoriColors.goldOnLight,
      route: '/quests',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.collections_outlined,
      title: t.dojangTitle,
      subtitle: t.dojangEmptyBody,
      accent: SoriColors.goldOnLight,
      route: '/dojangcheop',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.home_work_outlined,
      title: t.hanokWorldTitle,
      subtitle: t.hanokWorldIntro,
      accent: SoriColors.primary,
      route: '/hanok',
    ),
    _DiscoverFeature(
      category: _DiscoverCategory.progress,
      icon: Icons.chair_outlined,
      title: t.sarangbangTitle,
      subtitle: t.sarangbangHubDesc,
      accent: SoriColors.goldOnLight,
      route: '/sarangbang',
    ),
  ];
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<_DiscoverFeature> features;

  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = soriGridColumns(
          constraints.maxWidth,
          target: 156,
          min: 1,
          max: 3,
          outerPadding: 0,
        );
        final itemWidth =
            (constraints.maxWidth - Spacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.md,
          children: [
            for (final feature in features)
              SizedBox(
                width: itemWidth,
                child: ModuleCard(
                  icon: feature.icon,
                  title: feature.title,
                  subtitle: feature.subtitle,
                  accent: feature.accent,
                  ribbonType: feature.ribbonType,
                  onTap: () => Navigator.pushNamed(context, feature.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _DiscoverCategory { learn, practice, words, progress }

extension on _DiscoverCategory {
  String label(AppL10n t) => switch (this) {
    _DiscoverCategory.learn => t.discoverCategoryLearn,
    _DiscoverCategory.practice => t.discoverCategoryPractice,
    _DiscoverCategory.words => t.discoverCategoryWords,
    _DiscoverCategory.progress => t.discoverCategoryProgress,
  };
}

class _DiscoverFeature {
  final _DiscoverCategory category;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String route;
  final String? ribbonType;

  const _DiscoverFeature({
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.route,
    this.ribbonType,
  });
}
