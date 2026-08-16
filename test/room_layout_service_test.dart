import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/models/room_layout.dart';
import 'package:ko_lernen_app/services/room_layout_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    RoomLayoutService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'adapts v2 in memory without writing until the first real edit',
    () async {
      final legacy = jsonEncode({
        'sarangbang': {'floor_center': 'decoration_soban'},
        'anbang': {'wall_back': 'decoration_pyeonaek'},
      });
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_room_placements_v2': legacy});
      await Storage.init();

      final snapshot = RoomLayoutService.load();

      expect(snapshot.source, RoomLayoutLoadSource.migratedV2);
      expect(snapshot.layouts[PersonalRoomSurface.sarangbang], hasLength(1));
      expect(
        snapshot.layouts[PersonalRoomSurface.sarangbang]!.single.instanceId,
        'decor:decoration_soban',
      );
      expect(Storage.roomLayoutsV3Raw, isNull);
    },
  );

  test(
    'first edit writes v3 and leaves v2 plus legacy rollback data intact',
    () async {
      final legacy = jsonEncode({'floor_center': 'decoration_soban'});
      final v2 = jsonEncode({
        'sarangbang': {'floor_center': 'decoration_soban'},
      });
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_owned_decor': <String>['decoration_soban', 'decoration_pyeonaek'],
        'kl_room_placement': legacy,
        'kl_room_placements_v2': v2,
      });
      await Storage.init();

      final mutation = await RoomLayoutService.addItem(
        PersonalRoomSurface.sarangbang,
        RoomAssetKind.decoration,
        'decoration_pyeonaek',
      );

      expect(mutation.result, RoomLayoutWriteResult.added);
      final document = jsonDecode(Storage.roomLayoutsV3Raw!) as Map;
      expect(document['version'], 3);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('kl_room_placement'), legacy);
      expect(preferences.getString('kl_room_placements_v2'), v2);
    },
  );

  test(
    'moves unique decor between rooms but gives stickers unique copies',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_owned_decor': <String>['decoration_soban'],
      });
      await Storage.init();

      await RoomLayoutService.addItem(
        PersonalRoomSurface.sarangbang,
        RoomAssetKind.decoration,
        'decoration_soban',
      );
      final moved = await RoomLayoutService.addItem(
        PersonalRoomSurface.anbang,
        RoomAssetKind.decoration,
        'decoration_soban',
      );
      final firstSticker = await RoomLayoutService.addItem(
        PersonalRoomSurface.anbang,
        RoomAssetKind.sticker,
        '16',
      );
      final secondSticker = await RoomLayoutService.addItem(
        PersonalRoomSurface.anbang,
        RoomAssetKind.sticker,
        '16',
      );

      expect(moved.layouts[PersonalRoomSurface.sarangbang], isNull);
      expect(
        moved.layouts[PersonalRoomSurface.anbang]!.single.instanceId,
        'decor:decoration_soban',
      );
      expect(firstSticker.selectedId, isNot(secondSticker.selectedId));
      expect(secondSticker.selectedId, startsWith('sticker:16:'));
    },
  );

  test('persists a transformed item and z-order across reloads', () async {
    final first = await RoomLayoutService.addItem(
      PersonalRoomSurface.sarangbang,
      RoomAssetKind.sticker,
      '16',
    );
    await RoomLayoutService.addItem(
      PersonalRoomSurface.sarangbang,
      RoomAssetKind.sticker,
      '17',
    );
    final firstItem =
        RoomLayoutService.load().layouts[PersonalRoomSurface.sarangbang]!.first;
    await RoomLayoutService.updateItem(
      PersonalRoomSurface.sarangbang,
      firstItem.copyWith(x: .73, y: .21, width: .31, rotation: .42),
    );
    await RoomLayoutService.reorderItem(
      PersonalRoomSurface.sarangbang,
      first.selectedId!,
      1,
    );

    final reloaded = RoomLayoutService.load();
    final item = reloaded.layouts[PersonalRoomSurface.sarangbang]!.last;
    expect(reloaded.source, RoomLayoutLoadSource.v3);
    expect(item.instanceId, first.selectedId);
    expect(item.x, .73);
    expect(item.y, .21);
    expect(item.width, .31);
    expect(item.rotation, .42);
  });

  test('valid v3 is authoritative and never live-merges v2', () async {
    final item = const RoomLayoutItem(
      instanceId: 'sticker:20:1',
      kind: RoomAssetKind.sticker,
      assetId: '20',
      x: .25,
      y: .35,
      width: .2,
    );
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_room_layouts_v3': jsonEncode({
        'version': 3,
        'surfaces': {
          'sarangbang': [item.toJson(z: 0)],
        },
      }),
      'kl_room_placements_v2': jsonEncode({
        'sarangbang': {'floor_center': 'decoration_soban'},
      }),
    });
    await Storage.init();

    final snapshot = RoomLayoutService.load();

    expect(snapshot.source, RoomLayoutLoadSource.v3);
    expect(snapshot.layouts[PersonalRoomSurface.sarangbang], [item]);
  });

  test('corrupt v3 recovers v2 in memory without overwriting either', () async {
    final v2 = jsonEncode({
      'sarangbang': {'floor_center': 'decoration_soban'},
    });
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_room_layouts_v3': '{broken',
      'kl_room_placements_v2': v2,
    });
    await Storage.init();

    final snapshot = RoomLayoutService.load();

    expect(snapshot.source, RoomLayoutLoadSource.recoveredCorruptV3);
    expect(snapshot.layouts[PersonalRoomSurface.sarangbang], hasLength(1));
    expect(Storage.roomLayoutsV3Raw, '{broken');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_room_placements_v2'), v2);
  });

  test('caps one sticker artwork at four room copies', () async {
    for (var i = 0; i < 4; i++) {
      expect(
        (await RoomLayoutService.addItem(
          PersonalRoomSurface.sarangbang,
          RoomAssetKind.sticker,
          '19',
        )).result,
        RoomLayoutWriteResult.added,
      );
    }

    final fifth = await RoomLayoutService.addItem(
      PersonalRoomSurface.sarangbang,
      RoomAssetKind.sticker,
      '19',
    );

    expect(fifth.result, RoomLayoutWriteResult.limitReached);
    expect(fifth.layouts[PersonalRoomSurface.sarangbang], hasLength(4));
  });

  test(
    'requires earned stamp ownership without changing the stamp book',
    () async {
      final blocked = await RoomLayoutService.addItem(
        PersonalRoomSurface.sarangbang,
        RoomAssetKind.stamp,
        'lotus',
      );
      expect(blocked.result, RoomLayoutWriteResult.notOwned);

      await Storage.addEarnedStamp('lotus');
      final added = await RoomLayoutService.addItem(
        PersonalRoomSurface.sarangbang,
        RoomAssetKind.stamp,
        'lotus',
      );

      expect(added.result, RoomLayoutWriteResult.added);
      expect(Storage.earnedStamps, contains('lotus'));
    },
  );

  test('sanitizes damaged coordinates, identities and duplicate singles', () {
    final clean = RoomLayoutService.sanitize({
      PersonalRoomSurface.sarangbang: [
        const RoomLayoutItem(
          instanceId: 'decor:decoration_soban',
          kind: RoomAssetKind.decoration,
          assetId: 'decoration_soban',
          x: -4,
          y: 8,
          width: 9,
          rotation: 50,
        ),
        const RoomLayoutItem(
          instanceId: 'wrong-id',
          kind: RoomAssetKind.decoration,
          assetId: 'decoration_soban',
          x: .5,
          y: .5,
          width: .2,
        ),
      ],
      PersonalRoomSurface.anbang: [
        const RoomLayoutItem(
          instanceId: 'decor:decoration_soban',
          kind: RoomAssetKind.decoration,
          assetId: 'decoration_soban',
          x: .4,
          y: .4,
          width: .2,
        ),
      ],
    });

    final item = clean[PersonalRoomSurface.sarangbang]!.single;
    expect(item.x, 0);
    expect(item.y, 1);
    expect(item.width, RoomLayoutService.maxWidth);
    expect(item.rotation, inInclusiveRange(-3.142, 3.142));
    expect(clean[PersonalRoomSurface.anbang], isNull);
  });

  test('does not overwrite a layout written by a newer app version', () async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_room_layouts_v3': jsonEncode({'version': 4, 'surfaces': {}}),
    });
    await Storage.init();

    final mutation = await RoomLayoutService.addItem(
      PersonalRoomSurface.sarangbang,
      RoomAssetKind.sticker,
      '20',
    );

    expect(mutation.result, RoomLayoutWriteResult.futureVersion);
    expect(jsonDecode(Storage.roomLayoutsV3Raw!)['version'], 4);
  });

  test('strict v3 writer rejects uninitialized storage', () async {
    Storage.resetForTesting();

    await expectLater(Storage.setRoomLayoutsV3Raw('{}'), throwsStateError);
  });
}
