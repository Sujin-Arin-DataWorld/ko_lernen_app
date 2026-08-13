import 'package:flutter/material.dart';

import '../models/ux_preview_catalog.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

typedef UxPreviewPanelBuilder = Widget Function(UxPreviewPanel panel);

/// Debug-only directory for the twenty UX rebuild fixture states.
///
/// [buildPanel] must return the production screen wired to a mutation-free
/// preview seam. The gallery owns only discovery and navigation; it never
/// reads or fabricates learner progress itself.
class UxPreviewGalleryScreen extends StatelessWidget {
  const UxPreviewGalleryScreen({super.key, required this.buildPanel});

  final UxPreviewPanelBuilder buildPanel;

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

    for (final panel in uxPreviewPanels) {
      if (previousSection != panel.section) {
        if (previousSection != null) {
          children.add(const SizedBox(height: Spacing.lg));
        }
        children
          ..add(Text(_sectionLabel(panel.section), style: text.label))
          ..add(const SizedBox(height: Spacing.sm));
      }
      previousSection = panel.section;
      children.add(
        Builder(
          builder: (context) {
            void onTap() => _open(context, panel);
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Semantics(
                key: ValueKey('ux-preview-panel-${panel.id}'),
                label: '${panel.id} ${panel.title}',
                button: true,
                onTap: onTap,
                child: ExcludeSemantics(
                  child: SoriCard(
                    variant: SoriCardVariant.compact,
                    onTap: onTap,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(panel.id, style: text.cardTitle),
                        ),
                        Expanded(child: Text(panel.title, style: text.body)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('UX 01-06')),
      body: SafeArea(
        child: SoriContentClamp(
          base: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xxxl,
          ),
          builder: (context, padding) =>
              ListView(padding: padding, children: children),
        ),
      ),
    );
  }

  static String _sectionLabel(UxPreviewSection section) => switch (section) {
    UxPreviewSection.onboarding => '01 · Onboarding',
    UxPreviewSection.daily => '02 · Heute',
    UxPreviewSection.hanok => '03 · Hanok',
    UxPreviewSection.explore => '04 · Üben & Entdecken',
    UxPreviewSection.gye => '05 · 계',
    UxPreviewSection.account => '06 · Ich & Offline',
  };
}
