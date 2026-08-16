import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/hanok_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('remote Hanok is decoded as reserved typed state', () {
    final state = _state('remote', 'roof_remote', 2, 'device_b');
    final decoded = AccountReconciliationSnapshot.decodeCloudDocument({
      'hanok_state_json': jsonEncode(state.toJson()),
      'ordinary': 1,
    });

    expect(decoded.isPresent, isTrue);
    expect(decoded.value!.hanokState!.toJson(), state.toJson());
    expect(decoded.value!.fields, {'ordinary': 1});
    expect(decoded.value!.toCloudDocument(), {
      'ordinary': 1,
      'srs_json': '{}',
      'custom_packs_json': '{}',
      'hanok_state_json': jsonEncode(state.toJson()),
    });
  });

  test('account merge uses Hanok union and per-slot LWW, not raw conflict', () {
    final local = _snapshot(_state('local', 'roof_local', 3, 'device_a'));
    final remote = _snapshot(_state('remote', 'roof_remote', 3, 'device_z'));

    final result = AccountReconciliationMerger.merge(
      local: local,
      remote: remote,
      catalog: const {},
    );

    expect(result.conflicts, isEmpty);
    expect(result.merged!.hanokState!.seenRevealIds, {'local', 'remote'});
    expect(
      result.merged!.hanokState!.activeLoadout['roofForm']!.grantId,
      'roof_remote',
    );
  });

  test('malformed remote Hanok invalidates the typed account snapshot', () {
    expect(
      AccountReconciliationSnapshot.decodeCloudDocument({
        'hanok_state_json': '{broken',
      }).state,
      CloudReadState.invalid,
    );
  });

  test(
    'local account capture keeps Hanok state and generation atomic',
    () async {
      SharedPreferences.setMockInitialValues({});
      Storage.resetForTesting();
      Storage.resetPackProgressForTesting();
      await Storage.init();
      await Storage.setCustomPacksRawJsonStrict('{}');
      final state = _state('local', 'roof_local', 1, 'device_a');
      await const HanokStateService().save(state);

      final snapshot = await LocalAccountReconciliationStore.load();

      expect(snapshot.hanokState!.toJson(), state.toJson());
      expect(
        snapshot.localHanokGeneration,
        jsonEncode(snapshot.hanokState!.toJson()),
      );
    },
  );

  test('Hanok CAS conflict becomes a reconciliation retry conflict', () async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    await Storage.init();
    await Storage.setCustomPacksRawJsonStrict('{}');
    final original = _state('original', 'roof_original', 1, 'device_a');
    final concurrent = _state('concurrent', 'roof_concurrent', 2, 'device_b');
    await const HanokStateService().save(original);
    final snapshot = await LocalAccountReconciliationStore.load();
    await const HanokStateService().save(
      concurrent,
      expectedGeneration: snapshot.localHanokGeneration,
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
    expect(const HanokStateService().load()!.toJson(), concurrent.toJson());
  });
}

HanokState _state(
  String revealId,
  String grantId,
  int counter,
  String actorId,
) => HanokState.fresh(manifestVersion: 'hanok_v1_core_2026_v1').copyWith(
  seenRevealIds: {revealId},
  activeLoadout: {
    'roofForm': HanokLoadoutSelection(
      grantId: grantId,
      clock: HanokLwwClock(counter: counter, actorId: actorId),
    ),
  },
);

AccountReconciliationSnapshot _snapshot(HanokState state) =>
    AccountReconciliationSnapshot(
      fields: const {},
      srsCards: const {},
      customPacks: const {},
      packProgress: const {},
      hanokState: state,
    );
