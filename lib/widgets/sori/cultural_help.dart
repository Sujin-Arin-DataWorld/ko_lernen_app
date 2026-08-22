import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'sheet.dart';
import 'tokens.dart';

typedef CulturalGlossaryWidgetBuilder =
    Widget Function(BuildContext context, CulturalGlossary? glossary);

class CulturalGlossaryBuilder extends StatelessWidget {
  const CulturalGlossaryBuilder({super.key, required this.builder});

  final CulturalGlossaryWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CulturalGlossary?>(
      future: CulturalGlossaryRepository.load(),
      builder: (context, snapshot) => builder(context, snapshot.data),
    );
  }
}

/// A visually small question mark with a full 48dp accessible target.
///
/// The control remains absent until a valid catalog entry is available. This
/// keeps optional cultural help from affecting the surrounding product flow
/// when the bundled data is missing or malformed.
class CulturalHelpButton extends StatelessWidget {
  const CulturalHelpButton({
    super.key,
    required this.termId,
    this.foregroundColor,
    this.focusNode,
  });

  final String termId;
  final Color? foregroundColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return CulturalGlossaryBuilder(
      builder: (context, glossary) {
        final entry = glossary?.entry(termId);
        if (entry == null) {
          return const SizedBox.shrink();
        }
        return _ResolvedCulturalHelpButton(
          entry: entry,
          foregroundColor: foregroundColor,
          focusNode: focusNode,
        );
      },
    );
  }
}

class CulturalDecorationHelpButton extends StatelessWidget {
  const CulturalDecorationHelpButton({
    super.key,
    required this.decorationSlug,
    this.foregroundColor,
  });

  final String decorationSlug;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return CulturalGlossaryBuilder(
      builder: (context, glossary) {
        final termId = glossary?.termIdForDecoration(decorationSlug);
        final entry = termId == null ? null : glossary?.entry(termId);
        if (entry == null) {
          return const SizedBox.shrink();
        }
        return _ResolvedCulturalHelpButton(
          entry: entry,
          foregroundColor: foregroundColor,
          focusNode: null,
        );
      },
    );
  }
}

class _ResolvedCulturalHelpButton extends StatelessWidget {
  const _ResolvedCulturalHelpButton({
    required this.entry,
    required this.foregroundColor,
    required this.focusNode,
  });

  final CulturalGlossaryEntry entry;
  final Color? foregroundColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final label = t.culturalHelpSemantics(entry.korean);
    final color = foregroundColor ?? SoriSurfaces.of(context).textMuted;
    void openStory() => showCulturalTermSheet(context, entry);
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: openStory,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: IconButton(
          key: Key('cultural_help_${entry.termId}'),
          tooltip: label,
          focusNode: focusNode,
          onPressed: openStory,
          icon: Text(
            '?',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class CulturalTermContent extends StatelessWidget {
  const CulturalTermContent({
    super.key,
    required this.termId,
    this.includeTitle = true,
  });

  final String termId;
  final bool includeTitle;

  @override
  Widget build(BuildContext context) {
    return CulturalGlossaryBuilder(
      builder: (context, glossary) {
        final entry = glossary?.entry(termId);
        if (entry == null) {
          return const SizedBox.shrink();
        }
        return CulturalTermEntryContent(
          entry: entry,
          includeTitle: includeTitle,
        );
      },
    );
  }
}

class CulturalTermEntryContent extends StatelessWidget {
  const CulturalTermEntryContent({
    super.key,
    required this.entry,
    this.includeTitle = true,
  });

  final CulturalGlossaryEntry entry;
  final bool includeTitle;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final copy = entry.localized(languageCode);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (includeTitle) ...[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            children: [
              Text(
                entry.korean,
                style: textTheme.headlineSmall?.copyWith(
                  color: surfaces.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.romanization,
                style: textTheme.titleMedium?.copyWith(
                  color: surfaces.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
        ],
        Text(
          t.culturalMeaningLabel,
          style: textTheme.labelLarge?.copyWith(
            color: SoriColors.primaryOnLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          copy.meaning,
          style: textTheme.bodyLarge?.copyWith(
            color: surfaces.text,
            height: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          t.culturalStoryLabel,
          style: textTheme.labelLarge?.copyWith(
            color: SoriColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          copy.story,
          style: textTheme.bodyLarge?.copyWith(
            color: surfaces.text,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

Future<void> showCulturalTermSheet(
  BuildContext context,
  CulturalGlossaryEntry entry,
) {
  final t = AppL10n.of(context);
  return showSoriSheet<void>(
    context: context,
    maxTextScaleFactor: 2,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Semantics(
            button: true,
            label: t.culturalClose,
            onTap: () => Navigator.of(sheetContext).pop(),
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 48,
              child: IconButton(
                key: const Key('cultural_help_close'),
                tooltip: t.culturalClose,
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ),
        CulturalTermEntryContent(entry: entry),
        const SizedBox(height: Spacing.lg),
      ],
    ),
  );
}

Future<void> showCulturalTermSheetForId(
  BuildContext context,
  String termId,
) async {
  final glossary = await CulturalGlossaryRepository.load();
  if (!context.mounted) {
    return;
  }
  final entry = glossary?.entry(termId);
  if (entry != null) {
    await showCulturalTermSheet(context, entry);
  }
}

Future<void> showCulturalDecorationSheet(
  BuildContext context,
  String decorationSlug,
) async {
  final glossary = await CulturalGlossaryRepository.load();
  if (!context.mounted) {
    return;
  }
  final termId = glossary?.termIdForDecoration(decorationSlug);
  final entry = termId == null ? null : glossary?.entry(termId);
  if (entry != null) {
    await showCulturalTermSheet(context, entry);
  }
}

final ValueNotifier<int> _culturalObjectHintRevision = ValueNotifier(0);

Future<void> markCulturalObjectHintSeen() async {
  await Storage.setCulturalObjectHintSeen();
  _culturalObjectHintRevision.value++;
}

/// Local-only, one-time guidance for read-only scenes with inspectable decor.
class CulturalObjectHint extends StatefulWidget {
  const CulturalObjectHint({super.key, required this.enabled});

  final bool enabled;

  @override
  State<CulturalObjectHint> createState() => _CulturalObjectHintState();
}

class _CulturalObjectHintState extends State<CulturalObjectHint> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = widget.enabled && !Storage.culturalObjectHintSeen;
    _culturalObjectHintRevision.addListener(_hideAfterExternalOpen);
  }

  @override
  void dispose() {
    _culturalObjectHintRevision.removeListener(_hideAfterExternalOpen);
    super.dispose();
  }

  void _hideAfterExternalOpen() {
    if (mounted && _visible) {
      setState(() => _visible = false);
    }
  }

  @override
  void didUpdateWidget(covariant CulturalObjectHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled &&
        widget.enabled &&
        !Storage.culturalObjectHintSeen) {
      _visible = true;
    }
    if (!widget.enabled) {
      _visible = false;
    }
  }

  Future<void> _dismiss() async {
    if (_visible) {
      setState(() => _visible = false);
    }
    await markCulturalObjectHintSeen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Material(
      key: const Key('cultural_object_hint'),
      color: surfaces.surface.withValues(alpha: .96),
      elevation: 2,
      borderRadius: SoriRadius.brPill,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: Spacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                t.culturalObjectHint,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: surfaces.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                tooltip: t.culturalObjectHintDismiss,
                onPressed: _dismiss,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
