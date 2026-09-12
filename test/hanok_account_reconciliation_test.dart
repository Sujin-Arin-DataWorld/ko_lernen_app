import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_state.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('remote IlDu V3 is decoded as reserved typed state', () {
    final state = _state('roof.remote', 2, 'device-b');
    final decoded = AccountReconciliationSnapshot.decodeCloudDocument({
      'ildu_world_state_json': jsonEncode(state.toJson()),
      'ordinary': 1,
    });

    expect(decoded.isPresent, isTrue);
    expect(decoded.value!.ilduWorldState!.toJson(), state.toJson());
    expect(decoded.value!.fields, {'ordinary': 1});
    expect(decoded.value!.toCloudDocument(), {
      'ordinary': 1,
      'srs_json': '{}',
      'custom_packs_json': '{}',
      'ildu_world_state_json': jsonEncode(state.toJson()),
    });
  });

  test('legacy-only remote state is converted but never written as V1', () {
    final decoded = AccountReconciliationSnapshot.decodeCloudDocument({
      'hanok_state_json': _legacyStateJson('roof.legacy'),
      'ordinary': 1,
    });

    expect(decoded.isPresent, isTrue);
    expect(
      decoded
          .value!
          .ilduWorldState!
          .activeDesignSelections['roofForm']!
          .grantId,
      'roof.legacy',
    );
    expect(decoded.value!.fields, {'ordinary': 1});
    expect(decoded.value!.toCloudDocument(), contains('ildu_world_state_json'));
    expect(
      decoded.value!.toCloudDocument(),
      isNot(contains('hanok_state_json')),
    );
  });

  test('V3 takes precedence without decoding malformed legacy state', () {
    final state = _state('roof.v3', 4, 'device-v3');
    final decoded = AccountReconciliationSnapshot.decodeCloudDocument({
      'ildu_world_state_json': jsonEncode(state.toJson()),
      'hanok_state_json': '{broken',
    });

    expect(decoded.isPresent, isTrue);
    expect(decoded.value!.ilduWorldState!.toJson(), state.toJson());
  });

  test('account merge uses deterministic IlDu per-slot LWW', () {
    final local = _snapshot(_state('roof.local', 3, 'device-a'));
    final remote = _snapshot(_state('roof.remote', 3, 'device-z'));

    final result = AccountReconciliationMerger.merge(
      local: local,
      remote: remote,
      catalog: const {},
    );

    expect(result.conflicts, isEmpty);
    expect(
      result
          .merged!
          .ilduWorldState!
          .activeDesignSelections['roofForm']!
          .grantId,
      'roof.remote',
    );
  });

  test('malformed V3 invalidates the typed account snapshot', () {
    expect(
      AccountReconciliationSnapshot.decodeCloudDocument({
        'ildu_world_state_json': '{broken',
      }).state,
      CloudReadState.invalid,
    );
  });

  test('malformed legacy fallback invalidates the typed account snapshot', () {
    expect(
      AccountReconciliationSnapshot.decodeCloudDocument({
        'hanok_state_json': '{broken',
      }).state,
      CloudReadState.invalid,
    );
  });

  test(
    'local account capture keeps IlDu state and generation atomic',
    () async {
      await _initializeStorage();
      final state = _state('roof.local', 1, 'device-a');
      await const IlDuWorldStateService().save(state);

      final snapshot = await LocalAccountReconciliationStore.load();

      expect(snapshot.ilduWorldState!.toJson(), state.toJson());
      expect(
        snapshot.localIlDuWorldGeneration,
        jsonEncode(snapshot.ilduWorldState!.toJson()),
      );
    },
  );

  test('IlDu CAS conflict becomes a reconciliation retry conflict', () async {
    await _initializeStorage();
    final original = _state('roof.original', 1, 'device-a');
    final concurrent = _state('roof.concurrent', 2, 'device-b');
    await const IlDuWorldStateService().save(original);
    final snapshot = await LocalAccountReconciliationStore.load();
    await const IlDuWorldStateService().save(
      concurrent,
      expectedGeneration: snapshot.localIlDuWorldGeneration,
    );
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final session = sessions.transition(CloudWriteMode.reconciling);

    await expectLater(
      LocalAccountReconciliationStore.write(
        snapshot,
        session: session,
        sessions: sessions,
      ),
      throwsA(isA<LocalReconciliationGenerationConflict>()),
    );
    expect(const IlDuWorldStateService().load()!.toJson(), concurrent.toJson());
  });
}

Future<void> _initializeStorage() async {
  SharedPreferences.setMockInitialValues({});
  Storage.resetForTesting();
  Storage.resetPackProgressForTesting();
  await Storage.init();
  await Storage.setCustomPacksRawJsonStrict('{}');
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

AccountReconciliationSnapshot _snapshot(IlDuWorldState state) =>
    AccountReconciliationSnapshot(
      fields: const {},
      srsCards: const {},
      customPacks: const {},
      packProgress: const {},
      ilduWorldState: state,
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
