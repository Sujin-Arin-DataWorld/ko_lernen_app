import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/discover_catalog.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// A scan-first feature directory for learners who do not yet know which
/// Hangul Sori activity solves their current learning need.
///
/// This is intentionally a destination, rather than a permanent list of every
/// activity in the primary navigation. The tab stays short and stable while
/// this screen makes the full product surface searchable and scannable.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.initialPurpose = DiscoverPurpose.forMe,
    this.initialQuery = '',
  });

  /// Fixture entry point for the UX gallery. Discover has no persistence, and
  /// this constructor makes its visible state explicit for deterministic
  /// previews while reusing the production widget tree.
  const DiscoverScreen.preview({
    super.key,
    this.initialPurpose = DiscoverPurpose.forMe,
    this.initialQuery = '',
  });

  final DiscoverPurpose initialPurpose;
  final String initialQuery;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _query;
  late DiscoverPurpose _selectedPurpose;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _selectedPurpose = widget.initialPurpose;
    _searchController.text = _query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final allFeatures = discoverCatalog(t);
    final query = _query.trim().toLowerCase();
    final visibleFeatures = allFeatures
        .where((feature) {
          // A typed query searches the complete directory. Category filters
          // remain a browsing aid rather than hiding a valid exact result.
          final matchesPurpose =
              query.isNotEmpty || feature.purpose == _selectedPurpose;
          final matchesQuery =
              query.isEmpty ||
              feature.title.toLowerCase().contains(query) ||
              feature.subtitle.toLowerCase().contains(query) ||
              feature.searchTerms.any(
                (term) => term.toLowerCase().contains(query),
              );
          return matchesPurpose && matchesQuery;
        })
        .toList(growable: false);
    final showPriorities =
        query.isEmpty && _selectedPurpose == DiscoverPurpose.forMe;

    return SoriStandardPage(
      appBarTitle: t.navDiscover,
      eyebrow: t.discoverEyebrow,
      headline: t.discoverTitle,
      description: t.discoverSubtitle,
      maxWidth: SoriMaxWidth.hub,
      children: [
        SoriTextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
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
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            for (final purpose in DiscoverPurpose.values)
              _CategoryChip(
                label: purpose.label(t),
                selected: _selectedPurpose == purpose,
                onSelected: () => setState(() => _selectedPurpose = purpose),
              ),
          ],
        ),
        if (showPriorities) ...[
          const SizedBox(height: Spacing.md),
          const _DiscoverPriorityRoutes(),
        ],
        const SizedBox(height: Spacing.lg),
        SoriSectionHeader(_selectedPurpose.label(t)),
        if (visibleFeatures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: SoriColors.primary,
                ),
                const SizedBox(height: Spacing.sm),
                Text(t.discoverNoResults, style: tt.bodySmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  t.discoverNoResultsHint,
                  textAlign: TextAlign.center,
                  style: tt.caption,
                ),
              ],
            ),
          )
        else
          _FeatureGrid(
            features: showPriorities
                ? visibleFeatures
                      .where(
                        (feature) => !const {
                          '/book',
                          '/vocab_notebook',
                          '/listening',
                          '/wordbook/search',
                        }.contains(feature.route),
                      )
                      .toList(growable: false)
                : visibleFeatures,
          ),
      ],
    );
  }
}

class _DiscoverPriorityRoutes extends StatelessWidget {
  const _DiscoverPriorityRoutes();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      children: [
        _DiscoverPriorityRoute(
          key: const ValueKey('discover-priority-book'),
          icon: Icons.document_scanner_outlined,
          title: t.discoverPriorityBookTitle,
          subtitle: t.discoverPriorityBookBody,
          accent: SoriColors.primary,
          onTap: () => Navigator.pushNamed(context, '/book'),
        ),
        const SizedBox(height: Spacing.sm),
        _DiscoverPriorityRoute(
          key: const ValueKey('discover-priority-notebook'),
          icon: Icons.photo_album_outlined,
          title: t.vocabNotebookTitle,
          subtitle: t.vocabNotebookDesc,
          accent: SoriColors.accent,
          onTap: () => Navigator.pushNamed(context, '/vocab_notebook'),
        ),
        const SizedBox(height: Spacing.sm),
        _DiscoverPriorityRoute(
          key: const ValueKey('discover-priority-pronunciation'),
          icon: Icons.headphones_rounded,
          title: t.discoverPriorityPronunciationTitle,
          subtitle: t.discoverPriorityPronunciationBody,
          accent: SoriColors.goldOnLight,
          onTap: () => Navigator.pushNamed(context, '/listening'),
        ),
        const SizedBox(height: Spacing.sm),
        _DiscoverPriorityRoute(
          key: const ValueKey('discover-priority-words'),
          icon: Icons.search_rounded,
          title: t.discoverPriorityWordsTitle,
          subtitle: t.discoverPriorityWordsBody,
          accent: SoriColors.accent,
          onTap: () => Navigator.pushNamed(context, '/wordbook/search'),
        ),
      ],
    );
  }
}

class _DiscoverPriorityRoute extends StatelessWidget {
  const _DiscoverPriorityRoute({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoriCard(
    variant: SoriCardVariant.compact,
    accent: accent,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: SoriRadius.brSm,
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SoriTextTheme.of(context).cardTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: SoriTextTheme.of(context).caption),
            ],
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Icon(Icons.chevron_right_rounded, color: accent),
      ],
    ),
  );
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
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: SoriRadius.brPill,
            onTap: onSelected,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? SoriColors.primary : surfaces.surface,
                borderRadius: SoriRadius.brPill,
                border: Border.all(
                  color: selected ? SoriColors.primary : surfaces.border,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: text.caption.copyWith(
                  color: selected ? Colors.white : surfaces.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<DiscoverCatalogEntry> features;

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
        // 설명 말줄임을 없앤 뒤로는 카드마다 줄 수가 달라진다. Wrap 은 한 행의
        // 높이를 맞춰 주지 않아 카드가 들쭉날쭉해지므로, 행 단위로 끊어
        // IntrinsicHeight + stretch 로 **그 행 안에서만** 높이를 맞춘다.
        // (전체를 한 높이로 맞추지는 않는다 — 설명이 긴 카드 때문에 짧은 카드가
        //  통째로 커지면 화면이 낭비된다.)
        final rows = <Widget>[];
        for (var start = 0; start < features.length; start += columns) {
          final end = start + columns > features.length
              ? features.length
              : start + columns;
          final slice = features.sublist(start, end);
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: Spacing.md),
                    SizedBox(
                      width: itemWidth,
                      // 마지막 행이 덜 찼을 때 빈 자리 — 남은 카드가 가로로
                      // 늘어나지 않게 자리만 차지한다.
                      child: column < slice.length
                          ? ModuleCard(
                              icon: slice[column].icon,
                              title: slice[column].title,
                              subtitle: slice[column].subtitle,
                              accent: slice[column].accent,
                              ribbonType: slice[column].ribbonType,
                              onTap: () => Navigator.pushNamed(
                                context,
                                slice[column].route,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: Spacing.md),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

extension on DiscoverPurpose {
  String label(AppL10n t) => switch (this) {
    DiscoverPurpose.forMe => t.discoverCategoryForMe,
    DiscoverPurpose.language => t.discoverCategoryLanguage,
    DiscoverPurpose.words => t.discoverCategoryWords,
    DiscoverPurpose.leisure => t.discoverCategoryLeisure,
  };
}
