import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/discover_catalog.dart';
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
  DiscoverPurpose? _selectedPurpose;

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
    final allFeatures = discoverCatalog(t);
    final visibleFeatures = allFeatures
        .where((feature) {
          final matchesPurpose =
              _selectedPurpose == null || feature.purpose == _selectedPurpose;
          final query = _query.trim().toLowerCase();
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
    final showBookPriority = _query.trim().isEmpty && _selectedPurpose == null;

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
              Text(t.discoverEyebrow, style: tt.label),
              const SizedBox(height: Spacing.xs),
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
                      selected: _selectedPurpose == null,
                      onSelected: () => setState(() => _selectedPurpose = null),
                    ),
                    for (final purpose in DiscoverPurpose.values)
                      _CategoryChip(
                        label: purpose.label(t),
                        selected: _selectedPurpose == purpose,
                        onSelected: () =>
                            setState(() => _selectedPurpose = purpose),
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
                _selectedPurpose?.label(t) ?? t.discoverAllTools,
              ),
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

extension on DiscoverPurpose {
  String label(AppL10n t) => switch (this) {
    DiscoverPurpose.learn => t.discoverCategoryLearn,
    DiscoverPurpose.practice => t.discoverCategoryPractice,
    DiscoverPurpose.words => t.discoverCategoryWords,
    DiscoverPurpose.progress => t.discoverCategoryProgress,
  };
}
