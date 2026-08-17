import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/hanok_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('backup includes only schema-valid Hanok state', () async {
    final state = HanokState.fresh(
      manifestVersion: 'hanok_v1_core_2026_v1',
    ).copyWith(seenRevealIds: const {'local'});
    await const HanokStateService().save(state);

    final payload = await CloudSync.buildBackupPayload();
    expect(jsonDecode(payload['hanok_state_json'] as String), state.toJson());

    await Storage.setHanokStateRawJsonStrict('{broken');
    expect(
      await CloudSync.buildBackupPayload(),
      isNot(contains('hanok_state_json')),
    );
  });

  test('restore unions reveals and uses deterministic slot LWW', () async {
    final local = HanokState.fresh(manifestVersion: 'hanok_v1_core_2026_v1')
        .copyWith(
          seenRevealIds: const {'local'},
          activeLoadout: {
            'door': HanokLoadoutSelection(
              grantId: 'local_door',
              clock: const HanokLwwClock(counter: 2, actorId: 'device_a'),
            ),
          },
        );
    final remote = local.copyWith(
      seenRevealIds: const {'remote'},
      activeLoadout: {
        'door': HanokLoadoutSelection(
          grantId: 'remote_door',
          clock: const HanokLwwClock(counter: 2, actorId: 'device_z'),
        ),
      },
    );
    await const HanokStateService().save(local);

    await CloudSync.applyRestorePayload({
      'hanok_state_json': jsonEncode(remote.toJson()),
    });

    final merged = const HanokStateService().load()!;
    expect(merged.seenRevealIds, {'local', 'remote'});
    expect(merged.activeLoadout['door']!.grantId, 'remote_door');
  });

  test('invalid remote Hanok state fails without overwriting local', () async {
    final local = HanokState.fresh(manifestVersion: 'hanok_v1_core_2026_v1');
    await const HanokStateService().save(local);
    final before = Storage.hanokStateRawJson;

    await expectLater(
      CloudSync.applyRestorePayload({'hanok_state_json': '{broken'}),
      throwsFormatException,
    );
    expect(Storage.hanokStateRawJson, before);
  });
}
