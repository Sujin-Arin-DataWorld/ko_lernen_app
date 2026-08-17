import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/services/hanok_state_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test(
    'HanokState v1 round-trips presentation state without grant authority',
    () {
      final state = HanokState(
        manifestVersion: 'hanok_v1_core_2026_v1',
        cutoverVersion: 2,
        seenRevealIds: const {'known', 'future_unknown_reveal'},
        activeLoadout: {
          'roofMaterial': HanokLoadoutSelection(
            grantId: 'hanok_roof_tile',
            clock: const HanokLwwClock(counter: 4, actorId: 'device_a'),
          ),
          'futureSlot': HanokLoadoutSelection(
            grantId: 'future_unknown_grant',
            clock: const HanokLwwClock(counter: 1, actorId: 'device_z'),
          ),
        },
        careState: HanokCareState(
          lastEligibleActivityAt: DateTime.utc(2026, 8, 16, 8),
          vacationMode: false,
          displayEnabled: true,
          notificationsEnabled: false,
          settingsClock: const HanokLwwClock(counter: 2, actorId: 'device_a'),
        ),
      );

      final decoded = HanokState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.toJson(), state.toJson());
      expect(decoded.seenRevealIds, contains('future_unknown_reveal'));
      expect(decoded.activeLoadout, contains('futureSlot'));
      expect(decoded.toJson(), isNot(contains('earnedGrantIds')));
    },
  );

  test(
    'merge is union plus deterministic per-slot LWW and latest care UTC',
    () {
      final local = HanokState(
        manifestVersion: 'hanok_v1_core_2026_v1',
        cutoverVersion: 2,
        seenRevealIds: const {'local', 'future_local'},
        activeLoadout: {
          'roofForm': HanokLoadoutSelection(
            grantId: 'local_roof',
            clock: const HanokLwwClock(counter: 3, actorId: 'device_a'),
          ),
          'door': HanokLoadoutSelection(
            grantId: 'local_door',
            clock: const HanokLwwClock(counter: 5, actorId: 'device_a'),
          ),
        },
        careState: HanokCareState(
          lastEligibleActivityAt: DateTime.utc(2026, 8, 10),
          vacationMode: false,
          displayEnabled: true,
          notificationsEnabled: false,
          settingsClock: const HanokLwwClock(counter: 1, actorId: 'device_a'),
        ),
      );
      final remote = HanokState(
        manifestVersion: 'hanok_v1_core_2026_v1',
        cutoverVersion: 2,
        seenRevealIds: const {'remote', 'future_remote'},
        activeLoadout: {
          'roofForm': HanokLoadoutSelection(
            grantId: 'remote_roof',
            clock: const HanokLwwClock(counter: 3, actorId: 'device_z'),
          ),
          'door': HanokLoadoutSelection(
            grantId: 'older_door',
            clock: const HanokLwwClock(counter: 4, actorId: 'device_z'),
          ),
        },
        careState: HanokCareState(
          lastEligibleActivityAt: DateTime.utc(2026, 8, 15),
          vacationMode: true,
          displayEnabled: false,
          notificationsEnabled: true,
          settingsClock: const HanokLwwClock(counter: 2, actorId: 'device_b'),
        ),
      );

      final merged = HanokState.merge(local, remote);
      expect(merged.seenRevealIds, {
        'local',
        'remote',
        'future_local',
        'future_remote',
      });
      expect(merged.activeLoadout['roofForm']!.grantId, 'remote_roof');
      expect(merged.activeLoadout['door']!.grantId, 'local_door');
      expect(
        merged.careState.lastEligibleActivityAt,
        DateTime.utc(2026, 8, 15),
      );
      expect(merged.careState.vacationMode, isTrue);
      expect(merged.careState.displayEnabled, isFalse);
    },
  );

  test('same-clock conflicts converge regardless of merge order', () {
    HanokState state(String grantId, bool vacationMode) => HanokState(
      manifestVersion: 'hanok_v1_core_2026_v1',
      cutoverVersion: 2,
      activeLoadout: {
        'door': HanokLoadoutSelection(
          grantId: grantId,
          clock: const HanokLwwClock(counter: 3, actorId: 'device_a'),
        ),
      },
      careState: HanokCareState(
        lastEligibleActivityAt: DateTime.utc(2026, 8, 16),
        vacationMode: vacationMode,
        displayEnabled: true,
        notificationsEnabled: false,
        settingsClock: const HanokLwwClock(counter: 4, actorId: 'device_a'),
      ),
    );

    final left = state('door_a', false);
    final right = state('door_z', true);
    expect(
      HanokState.merge(left, right).toJson(),
      HanokState.merge(right, left).toJson(),
    );
    expect(
      HanokState.merge(left, right).activeLoadout['door']!.grantId,
      'door_z',
    );
    expect(HanokState.merge(left, right).careState.vacationMode, isTrue);
  });

  test('merge is associative for reveal, loadout, and care state', () {
    HanokState state(int counter, String actor, String grant, int day) =>
        HanokState(
          manifestVersion: 'hanok_v1_core_2026_v1',
          cutoverVersion: 2,
          seenRevealIds: {'reveal_$actor'},
          activeLoadout: {
            'door': HanokLoadoutSelection(
              grantId: grant,
              clock: HanokLwwClock(counter: counter, actorId: actor),
            ),
          },
          careState: HanokCareState(
            lastEligibleActivityAt: DateTime.utc(2026, 8, day),
            vacationMode: actor == 'device_c',
            displayEnabled: true,
            notificationsEnabled: false,
            settingsClock: HanokLwwClock(counter: counter, actorId: actor),
            notifiedTierIds: {'tier_$actor'},
          ),
        );

    final a = state(1, 'device_a', 'door_a', 10);
    final b = state(2, 'device_b', 'door_b', 11);
    final c = state(2, 'device_c', 'door_c', 12);
    expect(
      HanokState.merge(HanokState.merge(a, b), c).toJson(),
      HanokState.merge(a, HanokState.merge(b, c)).toJson(),
    );
  });

  test('a newer care activity starts a fresh notification cycle', () {
    final previous = HanokCareState(
      lastEligibleActivityAt: DateTime.utc(2026, 8, 1),
      vacationMode: false,
      displayEnabled: true,
      notificationsEnabled: true,
      settingsClock: const HanokLwwClock(counter: 1, actorId: 'device_a'),
      notifiedTierIds: const {'livedIn', 'patina'},
    );
    final renewed = previous.copyWith(
      lastEligibleActivityAt: DateTime.utc(2026, 8, 16),
    );
    expect(renewed.notifiedTierIds, isEmpty);

    final merged = HanokCareState.merge(previous, renewed);
    expect(merged.lastEligibleActivityAt, DateTime.utc(2026, 8, 16));
    expect(merged.notifiedTierIds, isEmpty);
  });

  test('future schemas and non-UTC state fail closed', () {
    expect(
      () => HanokState.fromJson({
        'schemaVersion': 2,
        'manifestVersion': 'future',
        'cutoverVersion': 2,
        'seenRevealIds': <String>[],
        'activeLoadout': <String, Object>{},
        'careState': <String, Object>{},
      }),
      throwsFormatException,
    );
    expect(
      () => HanokCareState.fromJson({
        'lastEligibleActivityAt': '2026-08-16T08:00:00+02:00',
        'vacationMode': false,
        'displayEnabled': true,
        'notificationsEnabled': false,
        'settingsClock': {'counter': 0, 'actorId': 'device_a'},
      }),
      throwsFormatException,
    );
  });

  test(
    'same-schema unknown fields fail closed at every persisted boundary',
    () {
      final canonical =
          HanokState.fresh(manifestVersion: 'hanok_v1_core_2026_v1')
              .copyWith(
                activeLoadout: {
                  'door': HanokLoadoutSelection(
                    grantId: 'hanok_door_plain',
                    clock: const HanokLwwClock(counter: 1, actorId: 'device_a'),
                  ),
                },
              )
              .toJson();

      expect(
        () => HanokState.fromJson({...canonical, 'earnedGrantIds': <String>[]}),
        throwsFormatException,
      );

      final loadoutUnknown = _jsonCopy(canonical);
      ((loadoutUnknown['activeLoadout'] as Map<String, dynamic>)['door']
              as Map<String, dynamic>)['futureAuthority'] =
          true;
      expect(() => HanokState.fromJson(loadoutUnknown), throwsFormatException);

      final clockUnknown = _jsonCopy(canonical);
      ((((clockUnknown['activeLoadout'] as Map<String, dynamic>)['door']
                  as Map<String, dynamic>)['clock'])
              as Map<String, dynamic>)['serverWins'] =
          true;
      expect(() => HanokState.fromJson(clockUnknown), throwsFormatException);

      final careUnknown = _jsonCopy(canonical);
      (careUnknown['careState'] as Map<String, dynamic>)['streak'] = 99;
      expect(() => HanokState.fromJson(careUnknown), throwsFormatException);
    },
  );

  test('storage service persists and merges valid cloud state', () async {
    final service = HanokStateService();
    final initial = HanokState.fresh(
      manifestVersion: 'hanok_v1_core_2026_v1',
    ).copyWith(seenRevealIds: const {'local'});
    await service.save(initial);

    final cloud = initial.copyWith(seenRevealIds: const {'remote'});
    final merged = await service.mergeCloudSnapshotJson(
      jsonEncode(cloud.toJson()),
      expectedGeneration: Storage.hanokStateRawJson,
    );
    expect(merged.seenRevealIds, {'local', 'remote'});
    expect(service.load()!.seenRevealIds, {'local', 'remote'});
  });

  test(
    'cloud capture returns one queue-consistent state and generation',
    () async {
      final service = HanokStateService();
      final first = HanokState.fresh(
        manifestVersion: 'hanok_v1_core_2026_v1',
      ).copyWith(seenRevealIds: const {'first'});
      final second = first.copyWith(seenRevealIds: const {'second'});
      await service.save(first);
      final firstGeneration = Storage.hanokStateRawJson;

      final write = service.save(second, expectedGeneration: firstGeneration);
      final capture = service.captureForCloudReconciliation();
      await write;
      final captured = await capture;

      expect(captured.generation, Storage.hanokStateRawJson);
      expect(jsonEncode(captured.state!.toJson()), captured.generation);
      expect(captured.state!.seenRevealIds, {'second'});
    },
  );

  test(
    'absent-state generation fence rejects a concurrent first write',
    () async {
      final service = HanokStateService();
      final intended = HanokState.fresh(
        manifestVersion: 'hanok_v1_core_2026_v1',
      );
      final concurrent = intended.copyWith(seenRevealIds: const {'concurrent'});
      var injected = false;

      await expectLater(
        service.save(
          intended,
          expectedGeneration: '',
          beforeWrite: () {
            if (injected) {
              return;
            }
            injected = true;
            Storage.setHanokStateRawJsonStrict(jsonEncode(concurrent.toJson()));
          },
        ),
        throwsA(isA<HanokStateGenerationConflict>()),
      );
      expect(service.load()!.seenRevealIds, {'concurrent'});
    },
  );

  test(
    'process-wide queue prevents two absent-generation writes from winning',
    () async {
      final firstService = HanokStateService();
      final secondService = HanokStateService();
      final firstState = HanokState.fresh(
        manifestVersion: 'hanok_v1_core_2026_v1',
      ).copyWith(seenRevealIds: const {'first'});
      final secondState = firstState.copyWith(seenRevealIds: const {'second'});

      final firstWrite = firstService.save(firstState, expectedGeneration: '');
      final secondWrite = secondService.save(
        secondState,
        expectedGeneration: '',
      );
      await firstWrite;
      await expectLater(
        secondWrite,
        throwsA(isA<HanokStateGenerationConflict>()),
      );
      expect(firstService.load()!.seenRevealIds, {'first'});
    },
  );

  test('oversized state is rejected before durable storage changes', () async {
    final service = HanokStateService();
    final baseline = HanokState.fresh(manifestVersion: 'hanok_v1_core_2026_v1');
    await service.save(baseline);
    final before = Storage.hanokStateRawJson;
    final oversized = baseline.copyWith(
      seenRevealIds: {
        for (var index = 0; index < 2200; index++)
          'future_${index.toString().padLeft(4, '0')}_${'x' * 140}',
      },
    );

    await expectLater(
      service.save(oversized, expectedGeneration: before),
      throwsFormatException,
    );
    expect(Storage.hanokStateRawJson, before);
  });

  test(
    'oversized cloud union fails closed and preserves the valid local state',
    () async {
      final service = HanokStateService();
      final baseline = HanokState.fresh(
        manifestVersion: 'hanok_v1_core_2026_v1',
      );
      Set<String> revealIds(String prefix) => {
        for (var index = 0; index < 900; index++)
          '${prefix}_${index.toString().padLeft(4, '0')}_${'x' * 140}',
      };

      final local = baseline.copyWith(seenRevealIds: revealIds('local'));
      final remote = baseline.copyWith(seenRevealIds: revealIds('remote'));
      final remoteJson = jsonEncode(remote.toJson());
      await service.save(local);
      final before = Storage.hanokStateRawJson;

      expect(utf8.encode(before).length, lessThan(256 * 1024));
      expect(utf8.encode(remoteJson).length, lessThan(256 * 1024));

      await expectLater(
        service.mergeCloudSnapshotJson(remoteJson, expectedGeneration: before),
        throwsFormatException,
      );
      expect(Storage.hanokStateRawJson, before);
      expect(service.load()!.seenRevealIds, local.seenRevealIds);
    },
  );
}

Map<String, dynamic> _jsonCopy(Map<String, dynamic> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
