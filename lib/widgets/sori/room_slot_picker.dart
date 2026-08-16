import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'placed_decoration.dart';
import 'tokens.dart';

/// Explicit result for clearing a slot. A dismissed sheet returns null, so it
/// must never be overloaded as the clear instruction.
const String kSlotPickClear = ' clear';

/// Shared picker for every private Hanok room surface.
///
/// It returns a decoration slug, [kSlotPickClear], or null when dismissed.
/// Keeping the explicit sentinel prevents a swipe-dismiss from silently
/// clearing furniture in any room.
class SlotPickerSheet extends StatelessWidget {
  final List<String> candidates;
  final String? current;

  const SlotPickerSheet({super.key, required this.candidates, this.current});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(t.sarangbangPickTitle, style: text.h3),
        ),
        const SizedBox(height: Spacing.md),
        for (final slug in candidates)
          _PickRow(
            slug: slug,
            label: decorName(t, slug),
            selected: slug == current,
            onTap: () => Navigator.of(context).pop(slug),
          ),
        if (current != null)
          _PickRow(
            label: t.sarangbangClear,
            selected: false,
            onTap: () => Navigator.of(context).pop(kSlotPickClear),
          ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  final String? slug;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickRow({
    this.slug,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final thumb = slug;

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
                width: 52,
                height: 52,
                child: thumb == null
                    ? Icon(
                        Icons.remove_circle_outline,
                        size: 26,
                        color: s.textMuted,
                      )
                    : FittedBox(
                        fit: BoxFit.contain,
                        child: SoriDecorationImage(slug: thumb, size: 46),
                      ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.cardTitle.copyWith(
                    color: thumb == null ? s.textMuted : s.text,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: SoriColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
