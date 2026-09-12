import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_state.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test('round trips design selections and care preferences', () {
    final state = IlDuWorldState(
      sourceManifestVersion: 'hanok-grants-v1',
      activeDesignSelections: {
        'roofForm': IlDuDesignSelection(
          grantId: 'roof.giwa',
          clock: const IlDuLwwClock(counter: 2, actorId: 'device-a'),
        ),
      },
      carePreferences: IlDuCarePreferences.fresh(),
    );
    expect(IlDuWorldState.fromJson(state.toJson()).toJson(), state.toJson());
  });

  test('merge keeps the selection with the greater LWW clock', () {
    final merged = IlDuWorldState.merge(_state(1, 'old'), _state(2, 'new'));
    expect(merged.activeDesignSelections['roofForm']!.grantId, 'new');
  });

  test('rejects unknown top-level keys', () {
    final json = _state(1, 'roof.giwa').toJson()..['unknown'] = true;
    expect(() => IlDuWorldState.fromJson(json), throwsFormatException);
  });

  test('rejects non-UTC activity timestamps', () {
    final json = _state(1, 'roof.giwa').toJson();
    (json['carePreferences']
            as Map<String, dynamic>)['lastEligibleActivityAt'] =
        '2026-09-11T12:00:00+02:00';
    expect(() => IlDuWorldState.fromJson(json), throwsFormatException);
  });

  test('rejects duplicate care tier IDs', () {
    final json = _state(1, 'roof.giwa').toJson();
    (json['carePreferences'] as Map<String, dynamic>)['notifiedTierIds'] = [
      'tier.one',
      'tier.one',
    ];
    expect(() => IlDuWorldState.fromJson(json), throwsFormatException);
  });

  test('rejects counters outside the JavaScript-safe range', () {
    final json = _state(1, 'roof.giwa').toJson();
    final selections = json['activeDesignSelections'] as Map<String, dynamic>;
    final selection = selections['roofForm'] as Map<String, dynamic>;
    (selection['clock'] as Map<String, dynamic>)['counter'] =
        IlDuLwwClock.maxCounter + 1;
    expect(() => IlDuWorldState.fromJson(json), throwsFormatException);
  });

  test('rejects invalid stable IDs', () {
    expect(
      () => IlDuDesignSelection(
        grantId: 'roof with spaces',
        clock: const IlDuLwwClock(counter: 1, actorId: 'device-a'),
      ),
      throwsFormatException,
    );
  });

  test('decode rejects non-map roots and oversized payloads', () {
    const service = IlDuWorldStateService();
    expect(() => service.decode('[]'), throwsFormatException);
    final oversized = jsonEncode({
      'payload': 'x' * IlDuWorldStateService.maximumEncodedBytes,
    });
    expect(() => service.decode(oversized), throwsFormatException);
  });

  test('save preserves the captured generation fence', () async {
    const service = IlDuWorldStateService();
    final initial = _state(1, 'roof.giwa');
    await service.save(initial);
    final capture = await service.captureForCloudReconciliation();
    await service.save(_state(2, 'roof.other'));

    expect(
      () => service.save(initial, expectedGeneration: capture.generation),
      throwsA(isA<IlDuWorldStateGenerationConflict>()),
    );
  });
}

IlDuWorldState _state(int counter, String grantId) => IlDuWorldState(
  sourceManifestVersion: 'hanok-grants-v1',
  activeDesignSelections: {
    'roofForm': IlDuDesignSelection(
      grantId: grantId,
      clock: IlDuLwwClock(counter: counter, actorId: 'device-a'),
    ),
  },
  carePreferences: IlDuCarePreferences.fresh(),
);
