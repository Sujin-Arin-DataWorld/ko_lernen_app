import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/culture_discovery_service.dart';
import 'card.dart';
import 'tokens.dart';

typedef CultureStoriesEntryLoader = Future<CultureDiscoverySnapshot> Function();

/// Full-width Hanok entry for the derived culture-story collection.
///
/// It intentionally sits outside the four compact first-action shortcuts so
/// the existing 390px phone row keeps its tested layout.
class CultureStoriesEntryCard extends StatefulWidget {
  const CultureStoriesEntryCard({
    super.key,
    required this.onOpen,
    this.loadSnapshot,
  });

  final VoidCallback onOpen;
  final CultureStoriesEntryLoader? loadSnapshot;

  @override
  State<CultureStoriesEntryCard> createState() =>
      _CultureStoriesEntryCardState();
}

class _CultureStoriesEntryCardState extends State<CultureStoriesEntryCard> {
  late Future<CultureDiscoverySnapshot> _future;

  Future<CultureDiscoverySnapshot> _load() =>
      (widget.loadSnapshot ?? CultureDiscoveryService().load)();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CultureStoriesEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadSnapshot != widget.loadSnapshot) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    return FutureBuilder<CultureDiscoverySnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final count = data == null
            ? null
            : '${data.discoveredCount} / ${data.availableTermCount}';
        return Semantics(
          button: true,
          label: count == null
              ? t.cultureStoriesTitle
              : '${t.cultureStoriesTitle}, $count',
          onTap: widget.onOpen,
          child: ExcludeSemantics(
            child: SoriCard(
              key: const ValueKey('hanok-culture-stories-entry'),
              variant: SoriCardVariant.base,
              accent: SoriColors.accent,
              tinted: true,
              onTap: widget.onOpen,
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    size: 36,
                    color: SoriColors.accent,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.cultureStoriesTitle,
                          style: SoriTextTheme.of(context).cardTitle,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          t.cultureStoriesHanokBody,
                          style: SoriTextTheme.of(
                            context,
                          ).bodySmall.copyWith(color: surfaces.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: Spacing.sm),
                    Text(
                      count,
                      key: const ValueKey('hanok-culture-stories-count'),
                      style: SoriTextTheme.of(context).caption.copyWith(
                        color: surfaces.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const SizedBox(width: Spacing.xs),
                  Icon(Icons.chevron_right_rounded, color: surfaces.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
