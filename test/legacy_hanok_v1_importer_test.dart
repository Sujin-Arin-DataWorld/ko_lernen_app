import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_state.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/legacy_hanok_v1_importer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  test('does nothing when no V1 state exists', () async {
    expect(await LegacyHanokV1Importer.migratePreferences(prefs), isFalse);
    expect(prefs.containsKey(IlDuWorldStateService.preferenceKey), isFalse);
    expect(prefs.containsKey(LegacyHanokV1Importer.markerKey), isFalse);
  });

  test(
    'moves only design and care preferences, then removes V1 keys',
    () async {
      await _seedLegacy(prefs);

      expect(await LegacyHanokV1Importer.migratePreferences(prefs), isTrue);

      final raw = prefs.getString(IlDuWorldStateService.preferenceKey)!;
      final state = const IlDuWorldStateService().decode(raw);
      expect(state.sourceManifestVersion, 'hanok-grants-v1');
      expect(state.activeDesignSelections['roofForm']!.grantId, 'roof.giwa');
      expect(state.toJson().toString(), isNot(contains('seenRevealIds')));
      for (final key in LegacyHanokV1Importer.legacyKeys) {
        expect(prefs.containsKey(key), isFalse, reason: key);
      }
      expect(prefs.getBool(LegacyHanokV1Importer.markerKey), isTrue);
    },
  );

  test(
    'merges existing V3 state with legacy selections deterministically',
    () async {
      await _seedLegacy(prefs);
      final existing = IlDuWorldState(
        sourceManifestVersion: 'hanok-grants-v1',
        activeDesignSelections: {
          'roofForm': IlDuDesignSelection(
            grantId: 'roof.newer',
            clock: const IlDuLwwClock(counter: 3, actorId: 'device-b'),
          ),
        },
        carePreferences: IlDuCarePreferences.fresh(),
      );
      await prefs.setString(
        IlDuWorldStateService.preferenceKey,
        jsonEncode(existing.toJson()),
      );

      await LegacyHanokV1Importer.migratePreferences(prefs);

      final state = const IlDuWorldStateService().decode(
        prefs.getString(IlDuWorldStateService.preferenceKey)!,
      );
      expect(state.activeDesignSelections['roofForm']!.grantId, 'roof.newer');
    },
  );

  test('a repeated call leaves the V3 bytes unchanged', () async {
    await _seedLegacy(prefs);
    await LegacyHanokV1Importer.migratePreferences(prefs);
    final before = prefs.getString(IlDuWorldStateService.preferenceKey);

    expect(await LegacyHanokV1Importer.migratePreferences(prefs), isFalse);
    expect(prefs.getString(IlDuWorldStateService.preferenceKey), before);
  });

  test('malformed and oversized V1 state remove nothing', () async {
    for (final raw in <String>[
      '{broken',
      jsonEncode({'payload': 'x' * IlDuWorldStateService.maximumEncodedBytes}),
    ]) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LegacyHanokV1Importer.legacyStateKey: raw,
        'kl_hanok_cutover_v2': '2',
        'kl_hanok_stages_seen_v1': <String>['old'],
        'kl_personal_hanok_milestones_seen_v1': <String>['old'],
      });
      prefs = await SharedPreferences.getInstance();

      await expectLater(
        LegacyHanokV1Importer.migratePreferences(prefs),
        throwsFormatException,
      );
      for (final key in LegacyHanokV1Importer.legacyKeys) {
        expect(prefs.containsKey(key), isTrue, reason: key);
      }
      expect(prefs.containsKey(IlDuWorldStateService.preferenceKey), isFalse);
    }
  });

  test('a rejected V3 write leaves every V1 key present', () async {
    await _seedLegacy(prefs);

    await expectLater(
      LegacyHanokV1Importer.migratePreferences(
        prefs,
        writeV3: (_) async => false,
      ),
      throwsStateError,
    );

    for (final key in LegacyHanokV1Importer.legacyKeys) {
      expect(prefs.containsKey(key), isTrue, reason: key);
    }
    expect(prefs.containsKey(LegacyHanokV1Importer.markerKey), isFalse);
  });
}

Future<void> _seedLegacy(SharedPreferences prefs) async {
  await prefs.setString(
    LegacyHanokV1Importer.legacyStateKey,
    jsonEncode({
      'schemaVersion': 1,
      'manifestVersion': 'hanok-grants-v1',
      'cutoverVersion': 2,
      'seenRevealIds': ['retired.asset'],
      'activeLoadout': {
        'roofForm': {
          'grantId': 'roof.giwa',
          'clock': {'counter': 2, 'actorId': 'device-a'},
        },
      },
      'careState': {
        'vacationMode': false,
        'displayEnabled': true,
        'notificationsEnabled': false,
        'settingsClock': {'counter': 1, 'actorId': 'device-a'},
        'notifiedTierIds': <String>[],
      },
    }),
  );
  await prefs.setString('kl_hanok_cutover_v2', '2');
  await prefs.setStringList('kl_hanok_stages_seen_v1', ['old']);
  await prefs.setStringList('kl_personal_hanok_milestones_seen_v1', ['old']);
}
