import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/room_layer.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// Explicit result for clearing a slot. A dismissed sheet returns null, so it
/// must never be overloaded as the clear instruction.
const String kSlotPickClear = ' clear';

/// P1's collectible room-placement surface.
///
/// This stays separate from [SarangbangStudyScreen]: the study room opens the
/// existing recommendation, while furnishing only reads/writes through
/// [RoomPlacementService].
class SarangbangFurnishScreen extends StatefulWidget {
  const SarangbangFurnishScreen({super.key});

  @override
  State<SarangbangFurnishScreen> createState() =>
      _SarangbangFurnishScreenState();
}

class _SarangbangFurnishScreenState extends State<SarangbangFurnishScreen> {
  static const String _background =
      'assets/illustrations/hanok/sarangbang_empty.png';

  late RoomPlacement _placement;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _placement = RoomPlacementService.sanitize(Storage.roomPlacement);
  }

  Future<void> _onTapSlot(SlotDef slot) async {
    final current = _placement[slot.id];
    final candidates = RoomPlacementService.candidatesForSlot(
      slot,
      owned: Storage.ownedDecor,
      placement: _placement,
    );
    if (candidates.isEmpty && current == null) {
      return;
    }

    final picked = await showSoriSheet<String>(
      context: context,
      builder: (_) => SlotPickerSheet(candidates: candidates, current: current),
    );
    if (!mounted || picked == null) {
      return;
    }

    await RoomPlacementService.placeInSlot(
      slot.id,
      picked == kSlotPickClear ? null : picked,
    );
    if (!mounted) {
      return;
    }
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final owned = Storage.ownedDecor.toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.sarangbangTitle, style: text.h3),
        actions: [
          IconButton(
            tooltip: t.bojagiTitle,
            icon: const Icon(Icons.card_giftcard_rounded),
            onPressed: () async {
              await Navigator.of(context).pushNamed('/bojagi');
              if (mounted) {
                setState(_reload);
              }
            },
          ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: owned.isEmpty && _placement.isEmpty
              ? Center(
                  child: SoriEmptyState(
                    asset:
                        'assets/illustrations/reward/reward_bojagi_closed.png',
                    icon: Icons.card_giftcard_rounded,
                    title: t.sarangbangEmptyTitle,
                    body: t.sarangbangEmptyBody,
                  ),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _background,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => ColoredBox(
                            color: SoriSurfaces.of(ctx).surfaceAlt,
                          ),
                        ),
                        RoomLayer(
                          slots: kSarangbangSlots,
                          placement: _placement,
                          owned: owned,
                          onTapSlot: _onTapSlot,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Sheet that returns either a decoration slug, [kSlotPickClear], or null
/// when it was dismissed without a change.
class SlotPickerSheet extends StatelessWidget {
  final List<String> candidates;
  final String? current;

  const SlotPickerSheet({super.key, required this.candidates, this.current});

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
          child: Text(t.sarangbangPickTitle, style: text.h3),
        ),
        const SizedBox(height: Spacing.md),
        for (final slug in candidates)
          _PickRow(
            slug: slug,
            label: decorName(slug, german: german),
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
