import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_state.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('backup emits only schema-valid IlDu V3 state', () async {
    final state = _state('roof.local', 1, 'device-a');
    await const IlDuWorldStateService().save(state);

    final payload = await CloudSync.buildBackupPayload();
    expect(
      jsonDecode(payload['ildu_world_state_json'] as String),
      state.toJson(),
    );
    expect(payload, isNot(contains('hanok_state_json')));

    await Storage.setIlDuWorldStateRawJsonStrict('{broken');
    expect(
      await CloudSync.buildBackupPayload(),
      isNot(contains('ildu_world_state_json')),
    );
  });

  test(
    'restore merges valid IlDu V3 state with deterministic slot LWW',
    () async {
      final local = _state('roof.local', 2, 'device-a');
      final remote = _state('roof.remote', 2, 'device-z');
      await const IlDuWorldStateService().save(local);

      await CloudSync.applyRestorePayload({
        'ildu_world_state_json': jsonEncode(remote.toJson()),
      });

      final merged = const IlDuWorldStateService().load()!;
      expect(merged.activeDesignSelections['roofForm']!.grantId, 'roof.remote');
    },
  );

  test('legacy-only restore imports preferences into local V3 state', () async {
    await CloudSync.applyRestorePayload({
      'hanok_state_json': _legacyStateJson('roof.legacy'),
    });

    final restored = const IlDuWorldStateService().load()!;
    expect(restored.activeDesignSelections['roofForm']!.grantId, 'roof.legacy');
    expect(restored.toJson(), isNot(contains('seenRevealIds')));
  });

  test('V3 wins when both fields exist and legacy is malformed', () async {
    final remote = _state('roof.v3', 3, 'device-v3');

    await CloudSync.applyRestorePayload({
      'ildu_world_state_json': jsonEncode(remote.toJson()),
      'hanok_state_json': '{broken',
    });

    expect(
      const IlDuWorldStateService()
          .load()!
          .activeDesignSelections['roofForm']!
          .grantId,
      'roof.v3',
    );
  });

  test('malformed V3 fails without overwriting local state', () async {
    final local = _state('roof.local', 1, 'device-a');
    await const IlDuWorldStateService().save(local);
    final before = Storage.ilduWorldStateRawJson;

    await expectLater(
      CloudSync.applyRestorePayload({'ildu_world_state_json': '{broken'}),
      throwsFormatException,
    );
    expect(Storage.ilduWorldStateRawJson, before);
  });

  test(
    'malformed legacy fallback fails without overwriting local state',
    () async {
      final local = _state('roof.local', 1, 'device-a');
      await const IlDuWorldStateService().save(local);
      final before = Storage.ilduWorldStateRawJson;

      await expectLater(
        CloudSync.applyRestorePayload({'hanok_state_json': '{broken'}),
        throwsFormatException,
      );
      expect(Storage.ilduWorldStateRawJson, before);
    },
  );
}

IlDuWorldState _state(String grantId, int counter, String actorId) =>
    IlDuWorldState.fresh(sourceManifestVersion: 'ildu-v3-preview').copyWith(
      activeDesignSelections: {
        'roofForm': IlDuDesignSelection(
          grantId: grantId,
          clock: IlDuLwwClock(counter: counter, actorId: actorId),
        ),
      },
    );

String _legacyStateJson(String grantId) => jsonEncode({
  'schemaVersion': 1,
  'manifestVersion': 'hanok-v1-legacy',
  'cutoverVersion': 2,
  'seenRevealIds': ['retired.asset'],
  'activeLoadout': {
    'roofForm': {
      'grantId': grantId,
      'clock': {'counter': 1, 'actorId': 'legacy-device'},
    },
  },
  'careState': {
    'vacationMode': false,
    'displayEnabled': true,
    'notificationsEnabled': false,
    'settingsClock': {'counter': 1, 'actorId': 'legacy-device'},
    'notifiedTierIds': <String>[],
  },
});
