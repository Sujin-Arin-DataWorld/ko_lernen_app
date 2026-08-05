import 'package:flutter/material.dart';

import '../../models/gye_dedication.dart';
import '../../l10n/generated/app_localizations.dart';
import 'placed_decoration.dart';
import 'tokens.dart';

/// A dismissed sheet returns null. This explicit sentinel is the only way a
/// caller can request withdrawal from the shared exhibition.
const String kGyeDedicationWithdraw = ' __withdraw_gye_exhibit';

class GyeDedicationPickerSheet extends StatelessWidget {
  final List<String> candidates;
  final GyeDedication? current;

  GyeDedicationPickerSheet({
    super.key,
    required Iterable<String> candidates,
    this.current,
  }) : candidates = List<String>.unmodifiable(candidates);

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final german = Localizations.localeOf(context).languageCode != 'en';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(t.gyeDedicationTitle, style: text.h3),
        ),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeDedicationPickerBody, style: text.bodySmall),
        const SizedBox(height: Spacing.md),
        if (candidates.isEmpty && current?.isActive != true)
          Text(t.gyeDedicationEmpty, style: text.bodySmall),
        for (final slug in candidates)
          _GyeDedicationPickRow(
            slug: slug,
            label: decorName(slug, german: german),
            selected: slug == current?.decorationSlug,
            onTap: () => Navigator.of(context).pop(slug),
          ),
        if (current?.isActive == true)
          _GyeDedicationPickRow(
            label: t.gyeDedicationWithdraw,
            selected: false,
            isWithdraw: true,
            onTap: () => Navigator.of(context).pop(kGyeDedicationWithdraw),
          ),
      ],
    );
  }
}

class _GyeDedicationPickRow extends StatelessWidget {
  final String? slug;
  final String label;
  final bool selected;
  final bool isWithdraw;
  final VoidCallback onTap;

  const _GyeDedicationPickRow({
    this.slug,
    required this.label,
    required this.selected,
    this.isWithdraw = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: SoriRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: slug == null
                    ? Icon(Icons.remove_circle_outline, color: s.textMuted)
                    : FittedBox(
                        fit: BoxFit.contain,
                        child: SoriDecorationImage(slug: slug!, size: 44),
                      ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.cardTitle.copyWith(
                    color: isWithdraw ? s.textMuted : s.text,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: SoriColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
