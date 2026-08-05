import 'package:flutter/material.dart';

import '../data/personal_room_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/personal_hanok.dart';
import '../models/personal_room.dart';
import '../services/hanok_stage_service.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/personal_room_scene.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/room_slot_picker.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// A collectible interior in the private Hanok estate.
///
/// It only reads the already-earned Hanok projection to gate entry. Learning
/// progress, reward ownership, and all community/Gye state remain outside this
/// screen and its local placement service.
class PersonalRoomFurnishScreen extends StatefulWidget {
  final PersonalRoomSurface surface;
  final Future<LevelRatios> Function()? loadRatios;
  final bool enforceUnlock;

  const PersonalRoomFurnishScreen({
    super.key,
    required this.surface,
    this.loadRatios,
    this.enforceUnlock = true,
  });

  @override
  State<PersonalRoomFurnishScreen> createState() =>
      _PersonalRoomFurnishScreenState();
}

class _PersonalRoomFurnishScreenState extends State<PersonalRoomFurnishScreen> {
  PersonalHanokProjection? _projection;
  RoomPlacements _placements = const {};

  PersonalRoomDefinition get _room => personalRoomFor(widget.surface);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadRatios = widget.loadRatios ?? HanokStageService.levelRatios;
    PersonalHanokProjection projection;
    try {
      projection = PersonalHanokProjection.from(await loadRatios());
    } catch (_) {
      projection = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _projection = projection;
      // A direct route to a room still under construction must remain a pure
      // progress view. In particular, it must not revive or normalize local
      // placement state before its Hanok milestone is reached.
      if (!widget.enforceUnlock || projection.isUnlocked(_room.requires)) {
        _reloadPlacements();
      } else {
        _placements = const {};
      }
    });
  }

  void _reloadPlacements() {
    _placements = RoomPlacementService.sanitizeAll(Storage.roomPlacements);
  }

  bool get _isUnlocked =>
      !widget.enforceUnlock ||
      (_projection?.isUnlocked(_room.requires) ?? false);

  Future<void> _onTapSlot(SlotDef slot) async {
    final current = _placements[widget.surface]?[slot.id];
    final candidates = RoomPlacementService.candidatesForSurfaceSlot(
      widget.surface,
      slot,
      owned: Storage.ownedDecor,
      placements: _placements,
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

    await RoomPlacementService.placeInSurfaceSlot(
      widget.surface,
      slot.id,
      picked == kSlotPickClear ? null : picked,
    );
    if (!mounted) {
      return;
    }
    setState(_reloadPlacements);
  }

  Future<void> _openStudy() async {
    await Navigator.of(context).pushNamed(_room.studyRoute);
    if (mounted) {
      setState(_reloadPlacements);
    }
  }

  Future<void> _openBojagi() async {
    await Navigator.of(context).pushNamed('/bojagi');
    if (mounted) {
      setState(_reloadPlacements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final projection = _projection;
    return Scaffold(
      appBar: AppBar(
        title: Text(_roomTitle(t, widget.surface), style: text.h3),
        actions: [
          if (widget.surface == PersonalRoomSurface.sarangbang)
            IconButton(
              tooltip: t.bojagiTitle,
              icon: const Icon(Icons.card_giftcard_rounded),
              onPressed: _openBojagi,
            ),
          IconButton(
            tooltip: t.hanokWorldTitle,
            icon: const Icon(Icons.account_balance_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/hanok'),
          ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: projection == null
              ? const AppLoading()
              : !_isUnlocked
              ? SoriEmptyState(
                  icon: Icons.construction_rounded,
                  title: t.personalRoomLockedTitle,
                  body: t.personalRoomLockedBody,
                  ctaLabel: t.personalRoomReturnToMap,
                  onCta: () =>
                      Navigator.of(context).pushReplacementNamed('/hanok'),
                )
              : SoriContentClamp(
                  maxWidth: 720,
                  base: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  builder: (context, padding) => ListView(
                    padding: padding,
                    children: [
                      SoriCard(
                        variant: SoriCardVariant.hanji,
                        accent: SoriColors.primary,
                        tinted: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _roomIntroTitle(t, widget.surface),
                              style: text.h2,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              _roomIntroBody(t, widget.surface),
                              style: text.bodySmall,
                            ),
                            if (Storage.ownedDecor.isEmpty) ...[
                              const SizedBox(height: Spacing.md),
                              Text(
                                t.personalRoomEmptyHint,
                                style: text.bodySmall.copyWith(
                                  color: s.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      PersonalRoomScene(
                        surface: widget.surface,
                        placements: _placements,
                        owned: Storage.ownedDecor.toSet(),
                        interactive: true,
                        onTapSlot: _onTapSlot,
                      ),
                      const SizedBox(height: Spacing.lg),
                      SoriButton.outlined(
                        label: _studyLabel(t, widget.surface),
                        fullWidth: true,
                        maxLines: 2,
                        onTap: _openStudy,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

String _roomTitle(AppL10n t, PersonalRoomSurface surface) => switch (surface) {
  PersonalRoomSurface.sarangbang => t.sarangbangTitle,
  PersonalRoomSurface.anbang => t.personalRoomAnbangTitle,
  PersonalRoomSurface.daecheongmaru => t.personalRoomDaecheongTitle,
};

String _roomIntroTitle(AppL10n t, PersonalRoomSurface surface) =>
    switch (surface) {
      PersonalRoomSurface.sarangbang => t.sarangbangStudyIntroTitle,
      PersonalRoomSurface.anbang => t.personalRoomAnbangTitle,
      PersonalRoomSurface.daecheongmaru => t.personalRoomDaecheongTitle,
    };

String _roomIntroBody(AppL10n t, PersonalRoomSurface surface) =>
    switch (surface) {
      PersonalRoomSurface.sarangbang => t.sarangbangStudyIntroBody,
      PersonalRoomSurface.anbang => t.personalRoomAnbangBody,
      PersonalRoomSurface.daecheongmaru => t.personalRoomDaecheongBody,
    };

String _studyLabel(AppL10n t, PersonalRoomSurface surface) => switch (surface) {
  PersonalRoomSurface.sarangbang => t.hanokWorldOpenSarangbang,
  PersonalRoomSurface.anbang => t.personalRoomAnbangStudy,
  PersonalRoomSurface.daecheongmaru => t.personalRoomDaecheongStudy,
};
