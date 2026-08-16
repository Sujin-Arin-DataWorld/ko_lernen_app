import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/room_layout.dart';
import 'package:ko_lernen_app/widgets/sori/free_room_layer.dart';

void main() {
  const item = RoomLayoutItem(
    instanceId: 'sticker:16:1',
    kind: RoomAssetKind.sticker,
    assetId: '16',
    x: .5,
    y: .5,
    width: .08,
  );

  testWidgets('has no slot marker and keeps a 48dp selectable target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(items: const [item], interactive: true, onSelect: (_) {}),
      ),
    );

    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('room-item-sticker:16:1'))),
      const Size(48, 48),
    );
  });

  testWidgets('semantic tap selects a room item', (tester) async {
    final semantics = tester.ensureSemantics();
    String? selected;
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          onSelect: (value) => selected = value,
        ),
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const ValueKey('room-item-sticker:16:1')),
    );
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);

    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => candidate.id == node.id),
    );
    await tester.pump();

    expect(selected, item.instanceId);
    semantics.dispose();
  });

  testWidgets('freely drags an item and reports one persistence boundary', (
    tester,
  ) async {
    RoomLayoutItem? changed;
    RoomLayoutItem? ended;
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: (value) => changed = value,
          onTransformEnd: (value) => ended = value,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('room-item-sticker:16:1')),
      const Offset(60, -40),
    );
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.x, greaterThan(.6));
    expect(changed!.y, lessThan(.45));
    expect(ended, changed);
  });

  testWidgets('two pointers freely scale and rotate an item', (tester) async {
    RoomLayoutItem? changed;
    RoomLayoutItem? ended;
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: (value) => changed = value,
          onTransformEnd: (value) => ended = value,
        ),
      ),
    );
    final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
    final center = tester.getCenter(target);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);

    await first.down(center - const Offset(12, 0));
    await second.down(center + const Offset(12, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(0, 30));
    await second.moveTo(center + const Offset(0, 30));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.width, greaterThan(item.width));
    expect(changed!.rotation.abs(), greaterThan(.25));
    expect(ended, changed);
  });

  testWidgets('keeps the drag draft when a second pointer joins the gesture', (
    tester,
  ) async {
    final changed = <RoomLayoutItem>[];
    final ended = <RoomLayoutItem>[];
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: changed.add,
          onTransformEnd: ended.add,
        ),
      ),
    );
    final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
    final center = tester.getCenter(target);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);

    await first.down(center);
    await first.moveBy(const Offset(24, 0));
    await tester.pump();
    await first.moveBy(const Offset(48, 0));
    await tester.pump();
    expect(changed.last.x, greaterThan(.6));

    await second.down(center + const Offset(12, 0));
    expect(ended, isEmpty);
    await first.moveTo(center + const Offset(42, -45));
    await second.moveTo(center + const Offset(42, 45));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(changed.last.x, greaterThan(.6));
    expect(changed.last.width, greaterThan(item.width));
    expect(changed.last.rotation.abs(), greaterThan(.25));
    expect(ended, hasLength(1));
    expect(ended.last, changed.last);
  });

  testWidgets('saves once when a second pointer taps without moving', (
    tester,
  ) async {
    final changed = <RoomLayoutItem>[];
    final ended = <RoomLayoutItem>[];
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: changed.add,
          onTransformEnd: ended.add,
        ),
      ),
    );
    final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
    final center = tester.getCenter(target);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);

    await first.down(center);
    await first.moveBy(const Offset(24, 0));
    await tester.pump();
    await first.moveBy(const Offset(48, 0));
    await tester.pump();
    expect(changed.last.x, greaterThan(.6));

    await second.down(center + const Offset(12, 0));
    await second.up();
    await first.up();
    await tester.pump();

    expect(ended, hasLength(1));
    expect(ended.single, changed.last);
  });

  testWidgets(
    'continues after one pointer lifts across parent rebuilds and saves once',
    (tester) async {
      final changed = <RoomLayoutItem>[];
      final ended = <RoomLayoutItem>[];
      await tester.pumpWidget(
        _host(_RebuildingLayer(initial: item, changed: changed, ended: ended)),
      );
      final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
      final center = tester.getCenter(target);
      final first = await tester.createGesture(pointer: 1);
      final second = await tester.createGesture(pointer: 2);

      await first.down(center - const Offset(12, 0));
      await second.down(center + const Offset(12, 0));
      await tester.pump();
      await first.moveTo(center - const Offset(0, 30));
      await second.moveTo(center + const Offset(0, 30));
      await tester.pump();
      final beforeSinglePointer = changed.last;
      expect(beforeSinglePointer.width, greaterThan(item.width));
      expect(beforeSinglePointer.rotation.abs(), greaterThan(.25));

      await first.up();
      await tester.pump();
      expect(ended, isEmpty);
      await second.moveBy(const Offset(20, 0));
      await tester.pump();
      await second.moveBy(const Offset(30, 0));
      await tester.pump();
      await second.up();
      await tester.pump();

      expect(ended, hasLength(1));
      expect(ended.single.x, greaterThan(beforeSinglePointer.x));
      expect(ended.single.width, closeTo(beforeSinglePointer.width, .001));
      expect(
        ended.single.rotation,
        closeTo(beforeSinglePointer.rotation, .001),
      );
    },
  );

  testWidgets('pointer cancellation saves the latest visible draft once', (
    tester,
  ) async {
    final changed = <RoomLayoutItem>[];
    final ended = <RoomLayoutItem>[];
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: changed.add,
          onTransformEnd: ended.add,
        ),
      ),
    );
    final target = find.byKey(const ValueKey('room-item-sticker:16:1'));
    final gesture = await tester.startGesture(tester.getCenter(target));

    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(changed.last.x, greaterThan(.6));
    expect(ended, hasLength(1));
    expect(ended.single, changed.last);
  });

  testWidgets('trackpad pan zoom persists its final transform', (tester) async {
    final changed = <RoomLayoutItem>[];
    final ended = <RoomLayoutItem>[];
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item],
          interactive: true,
          selectedId: item.instanceId,
          onSelect: (_) {},
          onTransform: changed.add,
          onTransformEnd: ended.add,
        ),
      ),
    );
    final center = tester.getCenter(
      find.byKey(const ValueKey('room-item-sticker:16:1')),
    );
    final pointer = TestPointer(7, PointerDeviceKind.trackpad);

    await tester.sendEventToBinding(pointer.panZoomStart(center));
    await tester.sendEventToBinding(
      pointer.panZoomUpdate(center, pan: const Offset(24, 0)),
    );
    await tester.pump();
    await tester.sendEventToBinding(
      pointer.panZoomUpdate(
        center,
        pan: const Offset(60, 12),
        scale: 1.5,
        rotation: .4,
      ),
    );
    await tester.pump();
    await tester.sendEventToBinding(pointer.panZoomEnd());
    await tester.pump();

    expect(changed.last.x, greaterThan(item.x));
    expect(changed.last.width, greaterThan(item.width));
    expect(changed.last.rotation, greaterThan(.25));
    expect(ended, hasLength(1));
    expect(ended.single, changed.last);
  });

  testWidgets('two different room items keep independent gesture drafts', (
    tester,
  ) async {
    const secondItem = RoomLayoutItem(
      instanceId: 'sticker:19:2',
      kind: RoomAssetKind.sticker,
      assetId: '19',
      x: .8,
      y: .7,
      width: .08,
    );
    final changed = <RoomLayoutItem>[];
    final ended = <RoomLayoutItem>[];
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [item, secondItem],
          interactive: true,
          onSelect: (_) {},
          onTransform: changed.add,
          onTransformEnd: ended.add,
        ),
      ),
    );
    final firstGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('room-item-sticker:16:1'))),
      pointer: 1,
    );
    final secondGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('room-item-sticker:19:2'))),
      pointer: 2,
    );

    await firstGesture.moveBy(const Offset(24, 0));
    await secondGesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await firstGesture.moveBy(const Offset(30, 0));
    await secondGesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await firstGesture.up();
    await secondGesture.up();
    await tester.pump();

    final persisted = {for (final value in ended) value.instanceId: value};
    expect(persisted, hasLength(2));
    expect(persisted[item.instanceId]!.x, greaterThan(item.x));
    expect(persisted[secondItem.instanceId]!.x, lessThan(secondItem.x));
    expect(changed.map((value) => value.instanceId).toSet(), {
      item.instanceId,
      secondItem.instanceId,
    });
  });

  testWidgets('keeps the full 48dp target inside the clipped canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FreeRoomLayer(
          items: const [
            RoomLayoutItem(
              instanceId: 'sticker:16:edge',
              kind: RoomAssetKind.sticker,
              assetId: '16',
              x: 0,
              y: 0,
              width: .08,
            ),
          ],
          interactive: true,
          onSelect: (_) {},
        ),
      ),
    );

    final canvas = tester.getRect(find.byType(FreeRoomLayer));
    final target = tester.getRect(
      find.byKey(const ValueKey('room-item-sticker:16:edge')),
    );
    expect(target.left, greaterThanOrEqualTo(canvas.left));
    expect(target.top, greaterThanOrEqualTo(canvas.top));
    expect(target.right, lessThanOrEqualTo(canvas.right));
    expect(target.bottom, lessThanOrEqualTo(canvas.bottom));
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, height: 400, child: child)),
  ),
);

class _RebuildingLayer extends StatefulWidget {
  final RoomLayoutItem initial;
  final List<RoomLayoutItem> changed;
  final List<RoomLayoutItem> ended;

  const _RebuildingLayer({
    required this.initial,
    required this.changed,
    required this.ended,
  });

  @override
  State<_RebuildingLayer> createState() => _RebuildingLayerState();
}

class _RebuildingLayerState extends State<_RebuildingLayer> {
  late RoomLayoutItem current = widget.initial;

  @override
  Widget build(BuildContext context) => FreeRoomLayer(
    items: [current],
    interactive: true,
    selectedId: current.instanceId,
    onSelect: (_) {},
    onTransform: (updated) {
      widget.changed.add(updated);
      setState(() => current = updated);
    },
    onTransformEnd: widget.ended.add,
  );
}
