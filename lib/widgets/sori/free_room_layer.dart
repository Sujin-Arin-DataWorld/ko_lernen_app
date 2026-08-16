import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/sticker_localizations.dart';
import '../../models/room_layout.dart';
import 'dancheong_stamp.dart';
import 'placed_decoration.dart';
import 'sticker_image.dart';
import 'tokens.dart';

typedef RoomItemTransformCallback = void Function(RoomLayoutItem item);

/// Marker-free, continuous room canvas.
///
/// Items use one-finger translation and two-finger scale/rotation. The parent
/// owns the draft and persists only at gesture end, keeping pointer updates
/// smooth and SharedPreferences writes bounded.
class FreeRoomLayer extends StatefulWidget {
  final RoomLayout items;
  final bool interactive;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final RoomItemTransformCallback? onTransform;
  final RoomItemTransformCallback? onTransformEnd;
  final ValueChanged<String>? onInspectDecoration;
  final Set<String> inspectableDecorationSlugs;

  const FreeRoomLayer({
    super.key,
    required this.items,
    required this.interactive,
    this.selectedId,
    this.onSelect,
    this.onTransform,
    this.onTransformEnd,
    this.onInspectDecoration,
    this.inspectableDecorationSlugs = const {},
  }) : assert(!interactive || onSelect != null);

  @override
  State<FreeRoomLayer> createState() => _FreeRoomLayerState();
}

class _FreeRoomLayerState extends State<FreeRoomLayer> {
  final Map<String, _RoomGestureSession> _gestureSessions = {};

  _RoomGestureSession _gestureSession(String instanceId) =>
      _gestureSessions.putIfAbsent(instanceId, _RoomGestureSession.new);

  void _trackPointerDown(String instanceId, int pointer) {
    _gestureSession(instanceId).pointers.add(pointer);
  }

  void _trackPointerDone(String instanceId, int pointer) {
    final session = _gestureSessions[instanceId];
    if (session == null) {
      return;
    }
    session.pointers.remove(pointer);
    if (session.pointers.isNotEmpty) {
      return;
    }

    // The raw pointer route receives the same up/cancel event as the scale
    // recognizer. Flush in a microtask so its final onEnd segment cleanup has
    // completed regardless of hit-test callback ordering.
    scheduleMicrotask(() {
      final current = _gestureSessions[instanceId];
      if (!mounted || current != session || session.pointers.isNotEmpty) {
        return;
      }
      _gestureSessions.remove(instanceId);
      final finalItem = session.draft;
      if (finalItem != null) {
        widget.onTransformEnd?.call(finalItem);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            for (final item in widget.items)
              _positionedItem(context, item, canvas),
          ],
        );
      },
    );
  }

  Widget _positionedItem(
    BuildContext context,
    RoomLayoutItem item,
    Size canvas,
  ) {
    final visualSize = (item.width * canvas.width).clamp(16.0, canvas.width);
    final targetSize = math.max(48.0, visualSize);
    final horizontalInset = canvas.width > 0
        ? math.min(.5, targetSize / (canvas.width * 2))
        : .5;
    final verticalInset = canvas.height > 0
        ? math.min(.5, targetSize / (canvas.height * 2))
        : .5;
    final displayX = item.x
        .clamp(horizontalInset, 1 - horizontalInset)
        .toDouble();
    final displayY = item.y.clamp(verticalInset, 1 - verticalInset).toDouble();
    final left = displayX * canvas.width - targetSize / 2;
    final top = displayY * canvas.height - targetSize / 2;
    final selected = widget.selectedId == item.instanceId;
    final label = roomLayoutItemName(context, item);

    Widget child = Container(
      width: targetSize,
      height: targetSize,
      alignment: Alignment.center,
      decoration: selected
          ? BoxDecoration(
              borderRadius: SoriRadius.brSm,
              border: Border.all(color: SoriColors.primary, width: 2.5),
              color: SoriColors.primarySoft.withValues(alpha: .16),
            )
          : null,
      child: Transform.rotate(
        angle: item.rotation,
        child: _RoomItemVisual(item: item, size: visualSize),
      ),
    );

    if (widget.interactive) {
      child = Semantics(
        key: ValueKey('room-item-${item.instanceId}'),
        button: true,
        selected: selected,
        label: label,
        hint: selected ? null : _selectHint(context),
        onTap: () => widget.onSelect!(item.instanceId),
        excludeSemantics: true,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) =>
              _trackPointerDown(item.instanceId, event.pointer),
          onPointerUp: (event) =>
              _trackPointerDone(item.instanceId, event.pointer),
          onPointerCancel: (event) =>
              _trackPointerDone(item.instanceId, event.pointer),
          onPointerPanZoomStart: (event) =>
              _trackPointerDown(item.instanceId, event.pointer),
          onPointerPanZoomEnd: (event) =>
              _trackPointerDone(item.instanceId, event.pointer),
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            gestures: <Type, GestureRecognizerFactory>{
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(debugOwner: this),
                    (recognizer) {
                      recognizer.onTap = () =>
                          widget.onSelect!(item.instanceId);
                    },
                  ),
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                    () => ScaleGestureRecognizer(debugOwner: this),
                    (recognizer) {
                      recognizer
                        // A room item lives inside a vertical ListView. Accept
                        // its free transform before the parent's 18dp vertical
                        // drag threshold so short up/down moves edit the room
                        // instead of scrolling the page.
                        ..gestureSettings = const DeviceGestureSettings(
                          touchSlop: 6,
                        )
                        ..onStart = (details) {
                          // ScaleGestureRecognizer ends and restarts its
                          // callback segment whenever the pointer set changes.
                          // Carry the live draft into every next segment.
                          final session = _gestureSession(item.instanceId);
                          final start = session.draft ?? item;
                          session.start = start;
                          session.draft = start;
                          session.focalStart = details.focalPoint;
                          widget.onSelect!(item.instanceId);
                        }
                        ..onUpdate = (details) {
                          final session = _gestureSessions[item.instanceId];
                          final start = session?.start;
                          final focalStart = session?.focalStart;
                          if (start == null || focalStart == null) {
                            return;
                          }
                          final delta = details.focalPoint - focalStart;
                          final updated = start.copyWith(
                            x: (start.x + delta.dx / canvas.width)
                                .clamp(horizontalInset, 1 - horizontalInset)
                                .toDouble(),
                            y: (start.y + delta.dy / canvas.height)
                                .clamp(verticalInset, 1 - verticalInset)
                                .toDouble(),
                            width: (start.width * details.scale).clamp(
                              .08,
                              .72,
                            ),
                            rotation: start.rotation + details.rotation,
                          );
                          session!.draft = updated;
                          widget.onTransform?.call(updated);
                        }
                        // ScaleGestureRecognizer emits onEnd for each pointer
                        // configuration, not just the final lift. Raw pointer
                        // tracking above owns the one true save boundary.
                        ..onEnd = (_) {
                          final session = _gestureSessions[item.instanceId];
                          session?.start = null;
                          session?.focalStart = null;
                        };
                    },
                  ),
            },
            child: child,
          ),
        ),
      );
    } else if (item.kind == RoomAssetKind.decoration &&
        widget.onInspectDecoration != null &&
        widget.inspectableDecorationSlugs.contains(item.assetId)) {
      final helpLabel = AppL10n.of(context).culturalHelpSemantics(label);
      child = Semantics(
        key: ValueKey('inspect-room-item-${item.instanceId}'),
        button: true,
        label: helpLabel,
        onTap: () => widget.onInspectDecoration!(item.assetId),
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => widget.onInspectDecoration!(item.assetId),
            customBorder: const RoundedRectangleBorder(
              borderRadius: SoriRadius.brSm,
            ),
            child: child,
          ),
        ),
      );
    } else {
      child = Semantics(
        image: true,
        label: label,
        excludeSemantics: true,
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: targetSize,
      height: targetSize,
      child: child,
    );
  }

  String _selectHint(BuildContext context) =>
      AppL10n.of(context).personalRoomSelectItemHint;
}

class _RoomGestureSession {
  final Set<int> pointers = {};
  RoomLayoutItem? start;
  RoomLayoutItem? draft;
  Offset? focalStart;
}

class _RoomItemVisual extends StatelessWidget {
  final RoomLayoutItem item;
  final double size;

  const _RoomItemVisual({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    if (item.kind == RoomAssetKind.decoration) {
      return SoriDecorationImage(slug: item.assetId, size: size);
    }
    if (item.kind == RoomAssetKind.sticker) {
      final spec = stickerByCode(int.tryParse(item.assetId) ?? -1);
      return spec == null
          ? SizedBox.square(dimension: size)
          : StickerImage(spec: spec, size: size, semantic: '');
    }
    final motif = _motifByName(item.assetId);
    return motif == null
        ? SizedBox.square(dimension: size)
        : DancheongStamp(
            motif: motif,
            size: size,
            stamped: true,
            animate: false,
          );
  }
}

String roomLayoutItemName(BuildContext context, RoomLayoutItem item) {
  final t = AppL10n.of(context);
  if (item.kind == RoomAssetKind.decoration) {
    return decorName(t, item.assetId);
  }
  if (item.kind == RoomAssetKind.sticker) {
    final sticker = stickerByCode(int.tryParse(item.assetId) ?? -1);
    return sticker == null
        ? t.personalRoomStickerFallback
        : stickerName(t, sticker);
  }
  final motif = _motifByName(item.assetId);
  return motif == null
      ? t.personalRoomStampFallback
      : dancheongMotifName(t, motif);
}

DancheongMotif? _motifByName(String name) {
  for (final motif in DancheongMotif.values) {
    if (motif.name == name) {
      return motif;
    }
  }
  return null;
}
