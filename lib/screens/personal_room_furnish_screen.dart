import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/personal_room_catalog.dart';
import '../data/sticker_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/sticker_localizations.dart';
import '../models/personal_hanok.dart';
import '../models/personal_room.dart';
import '../models/room_layout.dart';
import '../services/analytics_service.dart';
import '../services/decoration_reward_service.dart';
import '../services/hanok_stage_service.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/room_layout_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/free_room_layer.dart';
import '../widgets/sori/personal_room_scene.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sticker_image.dart';
import '../widgets/sori/tokens.dart';

/// A collectible interior in the private Hanok estate.
///
/// It only reads the already-earned Hanok projection to gate entry. Learning
/// progress, reward ownership, and all community/Gye state remain outside this
/// screen and its local placement service.
class PersonalRoomFurnishScreen extends StatefulWidget {
  final PersonalRoomSurface surface;
  final Future<LevelRatios> Function()? loadRatios;
  final Future<PersonalHanokProjection> Function(LevelRatios ratios)?
  loadProjection;
  final bool enforceUnlock;
  final Future<RoomLayoutMutation> Function(
    PersonalRoomSurface surface,
    RoomAssetKind kind,
    String assetId,
  )?
  addLayoutItem;
  final Future<RoomLayoutMutation> Function(
    PersonalRoomSurface surface,
    RoomLayoutItem item,
  )?
  updateLayoutItem;

  const PersonalRoomFurnishScreen({
    super.key,
    required this.surface,
    this.loadRatios,
    this.loadProjection,
    this.enforceUnlock = true,
    this.addLayoutItem,
    this.updateLayoutItem,
  });

  @override
  State<PersonalRoomFurnishScreen> createState() =>
      _PersonalRoomFurnishScreenState();
}

class _PersonalRoomFurnishScreenState extends State<PersonalRoomFurnishScreen> {
  PersonalHanokProjection? _projection;
  RoomLayouts _layouts = const {};
  bool _layoutWritable = true;
  String? _selectedId;
  RoomAssetKind _inventoryKind = RoomAssetKind.decoration;
  int _stateRevision = 0;

  PersonalRoomDefinition get _room => personalRoomFor(widget.surface);

  @override
  void initState() {
    super.initState();
    Analytics.hanokBuildStarted(roomType: widget.surface.name);
    _load();
  }

  Future<void> _load() async {
    final loadRatios = widget.loadRatios ?? HanokStageService.levelRatios;
    PersonalHanokProjection projection;
    try {
      final ratios = await loadRatios();
      final loadProjection =
          widget.loadProjection ??
          HanokStructureProjectionService.loadForRatios;
      projection = await loadProjection(ratios);
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
        _reloadLayouts();
        unawaited(DecorationRewardService.maybeLogRewardUnused());
      } else {
        _layouts = const {};
      }
    });
  }

  void _reloadLayouts() {
    final snapshot = RoomLayoutService.load();
    _layouts = snapshot.layouts;
    _layoutWritable = snapshot.writable;
    _stateRevision++;
    if (_selectedItem == null) {
      _selectedId = null;
    }
  }

  bool get _isUnlocked =>
      !widget.enforceUnlock ||
      (_projection?.isUnlocked(_room.requires) ?? false);

  RoomLayoutItem? get _selectedItem {
    final selectedId = _selectedId;
    if (selectedId == null) {
      return null;
    }
    for (final item in _layouts[widget.surface] ?? const <RoomLayoutItem>[]) {
      if (item.instanceId == selectedId) {
        return item;
      }
    }
    return null;
  }

  void _selectItem(String instanceId) {
    if (!_layoutWritable) {
      return;
    }
    setState(() => _selectedId = instanceId);
  }

  void _updateDraft(RoomLayoutItem updated) {
    if (!_layoutWritable) {
      return;
    }
    final layouts = copyRoomLayouts(_layouts);
    final items = layouts[widget.surface];
    final index =
        items?.indexWhere((item) => item.instanceId == updated.instanceId) ??
        -1;
    if (items == null || index < 0) {
      return;
    }
    items[index] = updated;
    _stateRevision++;
    setState(() {
      _layouts = layouts;
      _selectedId = updated.instanceId;
    });
  }

  Future<void> _saveTransform(RoomLayoutItem item) async {
    await _applyMutation(() => _updateLayoutItem(item));
  }

  Future<void> _addItem(RoomAssetKind kind, String assetId) async {
    await _applyMutation(
      () => _addLayoutItem(kind, assetId),
      selectReturned: true,
    );
  }

  Future<RoomLayoutMutation> _addLayoutItem(
    RoomAssetKind kind,
    String assetId,
  ) {
    final add = widget.addLayoutItem ?? RoomLayoutService.addItem;
    return add(widget.surface, kind, assetId);
  }

  Future<void> _changeSelected(
    RoomLayoutItem Function(RoomLayoutItem current) change,
  ) async {
    final current = _selectedItem;
    if (current == null) {
      return;
    }
    final updated = change(current);
    _updateDraft(updated);
    await _applyMutation(() => _updateLayoutItem(updated));
  }

  Future<RoomLayoutMutation> _updateLayoutItem(RoomLayoutItem item) {
    final update = widget.updateLayoutItem ?? RoomLayoutService.updateItem;
    return update(widget.surface, item);
  }

  Future<void> _reorderSelected(int delta) async {
    final current = _selectedItem;
    if (current == null) {
      return;
    }
    await _applyMutation(
      () => RoomLayoutService.reorderItem(
        widget.surface,
        current.instanceId,
        delta,
      ),
    );
  }

  Future<void> _removeSelected() async {
    final current = _selectedItem;
    if (current == null) {
      return;
    }
    await _applyMutation(
      () => RoomLayoutService.removeItem(widget.surface, current.instanceId),
    );
  }

  Future<void> _applyMutation(
    Future<RoomLayoutMutation> Function() operation, {
    bool selectReturned = false,
  }) async {
    if (!_layoutWritable) {
      _showMessage(AppL10n.of(context).personalRoomFutureLayout);
      return;
    }
    final requestRevision = ++_stateRevision;
    RoomLayoutMutation mutation;
    try {
      mutation = await operation();
    } on Object {
      if (mounted && requestRevision == _stateRevision) {
        setState(_reloadLayouts);
        _showMessage(AppL10n.of(context).personalRoomSaveFailed);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (requestRevision != _stateRevision) {
      return;
    }
    setState(() {
      _layouts = mutation.layouts;
      if (mutation.result == RoomLayoutWriteResult.removed) {
        _selectedId = null;
      } else if (selectReturned && mutation.selectedId != null) {
        _selectedId = mutation.selectedId;
      }
    });
    if (mutation.result == RoomLayoutWriteResult.limitReached) {
      _showMessage(AppL10n.of(context).personalRoomStickerLimit);
    } else if (mutation.result == RoomLayoutWriteResult.futureVersion) {
      _showMessage(AppL10n.of(context).personalRoomFutureLayout);
    } else if (mutation.result == RoomLayoutWriteResult.notOwned ||
        mutation.result == RoomLayoutWriteResult.unknownAsset ||
        mutation.result == RoomLayoutWriteResult.missingItem) {
      _showMessage(AppL10n.of(context).personalRoomSaveFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStudy() async {
    await Navigator.of(context).pushNamed(_room.studyRoute);
    if (mounted) {
      setState(_reloadLayouts);
    }
  }

  Future<void> _openBojagi() async {
    await Navigator.of(context).pushNamed('/bojagi');
    if (mounted) {
      setState(_reloadLayouts);
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(_roomTitle(t, widget.surface), style: text.h3),
            ),
            if (widget.surface == PersonalRoomSurface.sarangbang)
              const CulturalHelpButton(termId: 'sarangbang'),
          ],
        ),
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
                            const SizedBox(height: Spacing.md),
                            Text(
                              t.personalRoomEditorHint,
                              style: text.bodySmall.copyWith(
                                color: s.textMuted,
                              ),
                            ),
                            if (furnishedDecorSlugs(
                              Storage.ownedDecor,
                              openedVenues: {widget.surface},
                            ).isEmpty) ...[
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
                        layouts: _layouts,
                        interactive: _layoutWritable,
                        selectedId: _selectedId,
                        onSelectItem: _selectItem,
                        onTransformItem: _updateDraft,
                        onTransformEnd: _saveTransform,
                      ),
                      if (!_layoutWritable) ...[
                        const SizedBox(height: Spacing.md),
                        Text(
                          t.personalRoomFutureLayout,
                          style: text.bodySmall.copyWith(
                            color: SoriColors.warning,
                          ),
                        ),
                      ],
                      if (_selectedItem case final selected?) ...[
                        const SizedBox(height: Spacing.md),
                        _RoomItemToolbar(
                          label: t.personalRoomSelectedItem(
                            roomLayoutItemName(context, selected),
                          ),
                          enabled: _layoutWritable,
                          onMoveLeft: () => _changeSelected(
                            (item) => item.copyWith(x: item.x - .025),
                          ),
                          onMoveRight: () => _changeSelected(
                            (item) => item.copyWith(x: item.x + .025),
                          ),
                          onMoveUp: () => _changeSelected(
                            (item) => item.copyWith(y: item.y - .025),
                          ),
                          onMoveDown: () => _changeSelected(
                            (item) => item.copyWith(y: item.y + .025),
                          ),
                          onSmaller: () => _changeSelected(
                            (item) => item.copyWith(width: item.width * .9),
                          ),
                          onLarger: () => _changeSelected(
                            (item) => item.copyWith(width: item.width * 1.1),
                          ),
                          onRotateLeft: () => _changeSelected(
                            (item) => item.copyWith(
                              rotation: item.rotation - math.pi / 12,
                            ),
                          ),
                          onRotateRight: () => _changeSelected(
                            (item) => item.copyWith(
                              rotation: item.rotation + math.pi / 12,
                            ),
                          ),
                          onBackward: () => _reorderSelected(-1),
                          onForward: () => _reorderSelected(1),
                          onRemove: _removeSelected,
                        ),
                      ],
                      const SizedBox(height: Spacing.lg),
                      _RoomInventory(
                        surface: widget.surface,
                        kind: _inventoryKind,
                        layouts: _layouts,
                        onKindChanged: (kind) =>
                            setState(() => _inventoryKind = kind),
                        onAdd: _layoutWritable ? _addItem : null,
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

class _RoomItemToolbar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onSmaller;
  final VoidCallback onLarger;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onBackward;
  final VoidCallback onForward;
  final VoidCallback onRemove;

  const _RoomItemToolbar({
    required this.label,
    required this.enabled,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSmaller,
    required this.onLarger,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onBackward,
    required this.onForward,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      key: const ValueKey('room-item-toolbar'),
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.label),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              _tool(
                icon: Icons.arrow_left_rounded,
                tooltip: t.personalRoomMoveLeft,
                onPressed: onMoveLeft,
              ),
              _tool(
                icon: Icons.arrow_right_rounded,
                tooltip: t.personalRoomMoveRight,
                onPressed: onMoveRight,
              ),
              _tool(
                icon: Icons.arrow_upward_rounded,
                tooltip: t.personalRoomMoveUp,
                onPressed: onMoveUp,
              ),
              _tool(
                icon: Icons.arrow_downward_rounded,
                tooltip: t.personalRoomMoveDown,
                onPressed: onMoveDown,
              ),
              _tool(
                icon: Icons.zoom_out_map_rounded,
                tooltip: t.personalRoomMakeSmaller,
                onPressed: onSmaller,
              ),
              _tool(
                icon: Icons.zoom_in_map_rounded,
                tooltip: t.personalRoomMakeLarger,
                onPressed: onLarger,
              ),
              _tool(
                icon: Icons.rotate_left_rounded,
                tooltip: t.personalRoomRotateLeft,
                onPressed: onRotateLeft,
              ),
              _tool(
                icon: Icons.rotate_right_rounded,
                tooltip: t.personalRoomRotateRight,
                onPressed: onRotateRight,
              ),
              _tool(
                icon: Icons.flip_to_back_rounded,
                tooltip: t.personalRoomSendBackward,
                onPressed: onBackward,
              ),
              _tool(
                icon: Icons.flip_to_front_rounded,
                tooltip: t.personalRoomBringForward,
                onPressed: onForward,
              ),
              _tool(
                icon: Icons.inventory_2_outlined,
                tooltip: t.personalRoomRemoveItem,
                onPressed: onRemove,
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tool({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool danger = false,
  }) => IconButton(
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    style: IconButton.styleFrom(
      foregroundColor: danger ? SoriColors.danger : SoriColors.primary,
    ),
    onPressed: enabled ? onPressed : null,
    icon: Icon(icon),
  );
}

class _RoomInventory extends StatelessWidget {
  final PersonalRoomSurface surface;
  final RoomAssetKind kind;
  final RoomLayouts layouts;
  final ValueChanged<RoomAssetKind> onKindChanged;
  final void Function(RoomAssetKind kind, String assetId)? onAdd;

  const _RoomInventory({
    required this.surface,
    required this.kind,
    required this.layouts,
    required this.onKindChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final entries = _entries(context);
    return SoriCard(
      key: const ValueKey('room-inventory'),
      variant: SoriCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.personalRoomInventoryTitle, style: text.h3),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              _kindChip(
                context,
                RoomAssetKind.decoration,
                Icons.chair_outlined,
                t.personalRoomInventoryDecorations,
              ),
              _kindChip(
                context,
                RoomAssetKind.sticker,
                Icons.emoji_emotions_outlined,
                t.personalRoomInventoryStickers,
              ),
              _kindChip(
                context,
                RoomAssetKind.stamp,
                Icons.workspace_premium_outlined,
                t.personalRoomInventoryStamps,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (entries.isEmpty)
            Text(
              kind == RoomAssetKind.decoration
                  ? t.personalRoomNoDecorations
                  : t.personalRoomNoStamps,
              style: text.bodySmall,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => CulturalGlossaryBuilder(
                builder: (context, glossary) {
                  final helpSlugs = <String>{};
                  final seenTerms = <String>{};
                  if (kind == RoomAssetKind.decoration) {
                    for (final entry in entries) {
                      final termId = glossary?.termIdForDecoration(
                        entry.assetId,
                      );
                      if (termId != null && seenTerms.add(termId)) {
                        helpSlugs.add(entry.assetId);
                      }
                    }
                  }
                  return GridView.builder(
                    key: ValueKey('room-inventory-${kind.name}'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: soriGridColumns(
                        constraints.maxWidth,
                        target: 112,
                        min: 2,
                        max: 5,
                      ),
                      mainAxisExtent: 126,
                      mainAxisSpacing: Spacing.sm,
                      crossAxisSpacing: Spacing.sm,
                    ),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _RoomInventoryTile(
                        entry: entry,
                        showCulturalHelp: helpSlugs.contains(entry.assetId),
                        onTap: onAdd == null
                            ? null
                            : () => onAdd!(entry.kind, entry.assetId),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _kindChip(
    BuildContext context,
    RoomAssetKind value,
    IconData icon,
    String label,
  ) => ChoiceChip(
    key: ValueKey('room-inventory-tab-${value.name}'),
    selected: kind == value,
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onSelected: (_) => onKindChanged(value),
  );

  List<_RoomInventoryEntry> _entries(BuildContext context) {
    final t = AppL10n.of(context);
    final used = <String>{
      for (final item in layouts.values.expand((items) => items))
        if (item.kind != RoomAssetKind.sticker)
          '${item.kind.name}:${item.assetId}',
    };
    if (kind == RoomAssetKind.decoration) {
      final slugs =
          furnishedDecorSlugs(
            Storage.ownedDecor,
            openedVenues: {surface},
          ).toList()
            ..sort((a, b) => decorName(t, a).compareTo(decorName(t, b)));
      return [
        for (final slug in slugs)
          _RoomInventoryEntry(
            kind: kind,
            assetId: slug,
            label: decorName(t, slug),
            inUse: used.contains('${kind.name}:$slug'),
          ),
      ];
    }
    if (kind == RoomAssetKind.sticker) {
      return [
        for (final sticker in kStickers)
          _RoomInventoryEntry(
            kind: kind,
            assetId: '${sticker.code}',
            label: stickerName(t, sticker),
            sticker: sticker,
          ),
      ];
    }
    final motifs = <DancheongMotif>[];
    for (final slug in Storage.earnedStamps.toSet()) {
      for (final motif in DancheongMotif.values) {
        if (motif.name == slug) {
          motifs.add(motif);
        }
      }
    }
    motifs.sort(
      (a, b) => dancheongMotifName(t, a).compareTo(dancheongMotifName(t, b)),
    );
    return [
      for (final motif in motifs)
        _RoomInventoryEntry(
          kind: kind,
          assetId: motif.name,
          label: dancheongMotifName(t, motif),
          motif: motif,
          inUse: used.contains('${kind.name}:${motif.name}'),
        ),
    ];
  }
}

class _RoomInventoryEntry {
  final RoomAssetKind kind;
  final String assetId;
  final String label;
  final StickerSpec? sticker;
  final DancheongMotif? motif;
  final bool inUse;

  const _RoomInventoryEntry({
    required this.kind,
    required this.assetId,
    required this.label,
    this.sticker,
    this.motif,
    this.inUse = false,
  });
}

class _RoomInventoryTile extends StatelessWidget {
  final _RoomInventoryEntry entry;
  final VoidCallback? onTap;
  final bool showCulturalHelp;

  const _RoomInventoryTile({
    required this.entry,
    required this.onTap,
    required this.showCulturalHelp,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            key: ValueKey(
              'room-inventory-item-${entry.kind.name}-${entry.assetId}',
            ),
            button: true,
            enabled: onTap != null,
            label: t.personalRoomAddItem(entry.label),
            value: entry.inUse ? t.personalRoomItemInUse : null,
            onTap: onTap,
            excludeSemantics: true,
            child: Material(
              color: s.surfaceAlt.withValues(alpha: .5),
              borderRadius: SoriRadius.brSm,
              child: InkWell(
                borderRadius: SoriRadius.brSm,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.sm),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(child: Center(child: _preview())),
                          const SizedBox(height: Spacing.xs),
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: showCulturalHelp ? 40 : 0,
                            ),
                            child: Text(
                              entry.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: SoriTextTheme.of(context).caption,
                            ),
                          ),
                        ],
                      ),
                      if (entry.inUse)
                        const PositionedDirectional(
                          end: 0,
                          top: 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: SoriColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showCulturalHelp)
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: CulturalDecorationHelpButton(decorationSlug: entry.assetId),
          ),
      ],
    );
  }

  Widget _preview() {
    if (entry.kind == RoomAssetKind.decoration) {
      return SoriDecorationImage(slug: entry.assetId, size: 64);
    }
    if (entry.kind == RoomAssetKind.sticker) {
      return StickerImage(spec: entry.sticker!, size: 64, semantic: '');
    }
    return DancheongStamp(
      motif: entry.motif!,
      size: 64,
      stamped: true,
      animate: false,
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
