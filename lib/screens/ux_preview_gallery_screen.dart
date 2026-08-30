import 'package:flutter/material.dart';

import '../models/ux_preview_catalog.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';

typedef UxPreviewPanelBuilder = Widget Function(UxPreviewPanel panel);
typedef UxPreviewPanelTitleBuilder = String Function(UxPreviewPanel panel);
typedef UxPreviewSectionLabelBuilder =
    String Function(UxPreviewSection section);

/// Debug-only directory for the UX rebuild fixture states.
///
/// [buildPanel] must return the production screen wired to a mutation-free
/// preview seam. The gallery owns only discovery and navigation; it never
/// reads or fabricates learner progress itself.
class UxPreviewGalleryScreen extends StatelessWidget {
  const UxPreviewGalleryScreen({
    super.key,
    required this.buildPanel,
    this.panels = uxPreviewPanels,
    this.appBarTitle = 'UX 01-07',
    this.leading,
    this.automaticallyImplyLeading = true,
    this.eyebrow,
    this.headline,
    this.description,
    this.panelTitleBuilder,
    this.sectionLabelBuilder,
    this.panelKeyPrefix = 'ux-preview-panel',
    this.showPanelIds = true,
  });

  final UxPreviewPanelBuilder buildPanel;
  final List<UxPreviewPanel> panels;
  final String appBarTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final String? eyebrow;
  final String? headline;
  final String? description;
  final UxPreviewPanelTitleBuilder? panelTitleBuilder;
  final UxPreviewSectionLabelBuilder? sectionLabelBuilder;
  final String panelKeyPrefix;
  final bool showPanelIds;

  void _open(BuildContext context, UxPreviewPanel panel) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/ux_gallery/${panel.id}'),
        builder: (_) => buildPanel(panel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final children = <Widget>[];
    UxPreviewSection? previousSection;

    if (headline != null) {
      children
        ..add(
          SoriPageHeader(eyebrow: eyebrow, title: headline!, body: description),
        )
        ..add(const SizedBox(height: Spacing.xl));
    }

    for (final panel in panels) {
      if (previousSection != panel.section) {
        if (previousSection != null) {
          children.add(const SizedBox(height: Spacing.lg));
        }
        children
          ..add(
            Text(
              sectionLabelBuilder?.call(panel.section) ??
                  _sectionLabel(panel.section),
              style: text.label,
            ),
          )
          ..add(const SizedBox(height: Spacing.sm));
      }
      previousSection = panel.section;
      children.add(
        Builder(
          builder: (context) {
            void onTap() => _open(context, panel);
            final panelTitle = panelTitleBuilder?.call(panel) ?? panel.title;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Semantics(
                key: ValueKey('$panelKeyPrefix-${panel.id}'),
                label: showPanelIds ? '${panel.id} $panelTitle' : panelTitle,
                button: true,
                onTap: onTap,
                child: ExcludeSemantics(
                  child: SoriCard(
                    variant: SoriCardVariant.compact,
                    onTap: onTap,
                    child: Row(
                      children: [
                        if (showPanelIds)
                          SizedBox(
                            width: 48,
                            child: Text(panel.id, style: text.cardTitle),
                          ),
                        Expanded(child: Text(panelTitle, style: text.body)),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return SoriStandardFrame(
      appBarTitle: appBarTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      builder: (context, padding) =>
          ListView(padding: padding, children: children),
    );
  }

  static String _sectionLabel(UxPreviewSection section) => switch (section) {
    UxPreviewSection.onboarding => '01 · Onboarding',
    UxPreviewSection.daily => '02 · Heute',
    UxPreviewSection.hanok => '03 · Hanok',
    UxPreviewSection.explore => '04 · Üben & Entdecken',
    UxPreviewSection.gye => '05 · 계',
    UxPreviewSection.account => '06 · Ich & Offline',
    UxPreviewSection.soriStage => '07 · Sori Stage',
  };
}
