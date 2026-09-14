import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform()..values['kl_xp'] = 100;
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  Future<void> claim({
    String attempt = 'attempt',
    String scene = 'scene',
    int xp = 24,
  }) => Storage.claimScenarioCompletionReward(
    attemptId: attempt,
    scenarioId: scene,
    earnedXp: xp,
  );

  test(
    'duplicate concurrent completion claims pay once and real replay pays again',
    () async {
      await Future.wait([claim(), claim()]);
      expect(Storage.xp, 124);
      expect(Storage.xpToday, 24);
      await claim(attempt: 'replay');
      expect(Storage.xp, 148);
      expect(Storage.xpToday, 48);
      expect(platform.writes[Storage.listeningRewardLedgerPreferenceKey], 2);
    },
  );

  test(
    'claim survives a storage restart and remains compatible with other XP',
    () async {
      await claim();
      Storage.resetForTesting();
      await Storage.init();
      await claim();
      await Future.wait([
        Storage.addXp(7),
        Storage.claimListeningCompletionReward(
          scenarioId: 'listening',
          earnedXp: 40,
        ),
      ]);
      expect(Storage.xp, 171);
      expect(Storage.xpToday, 71);
      await claim();
      expect(Storage.xp, 171);
    },
  );

  test(
    'same attempt cannot be reused for a different scene or amount',
    () async {
      await claim();
      await expectLater(claim(scene: 'other'), throwsArgumentError);
      await expectLater(claim(xp: 25), throwsArgumentError);
      expect(Storage.xp, 124);
    },
  );

  test(
    'zero-star reward does not create a payout or corrupt the ledger',
    () async {
      await claim(xp: 0);
      expect(Storage.xp, 100);
      expect(
        platform.values,
        isNot(contains(Storage.listeningRewardLedgerPreferenceKey)),
      );
    },
  );

  test('a rejected claim stays unpublished and can be retried', () async {
    platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
    await expectLater(claim(), throwsA(isA<PreferenceWriteException>()));
    expect(Storage.xp, 100);
    expect(Storage.xpToday, 0);
    platform.rejectKey = null;
    await claim();
    expect(Storage.xp, 124);
    expect(Storage.xpToday, 24);
  });

  for (final committed in [false, true]) {
    test(
      'unknown native reply recovers without duplicate reward; committed=$committed',
      () async {
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          claim(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.xp, 100);
        expect(Storage.xpToday, 0);
        await expectLater(
          claim(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(platform.writes[Storage.listeningRewardLedgerPreferenceKey], 1);
        platform
          ..unavailable = false
          ..rejectKey = null;
        await claim();
        expect(Storage.xp, 124);
        expect(Storage.xpToday, 24);
        expect(
          platform.writes[Storage.listeningRewardLedgerPreferenceKey],
          committed ? 1 : 2,
        );
      },
    );
  }

  test(
    'native commit with lost acknowledgement is confirmed by reload',
    () async {
      platform
        ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
        ..throwReply = true
        ..commitBeforeFailure = true;
      await claim();
      expect(Storage.xp, 124);
      await claim();
      expect(platform.writes[Storage.listeningRewardLedgerPreferenceKey], 1);
    },
  );

  test(
    'old ledger without scenario claims is read without re-awarding old XP',
    () async {
      platform.values[Storage.listeningRewardLedgerPreferenceKey] = jsonEncode({
        'version': 1,
        'totalXp': 140,
        'listeningClaims': {
          'old': {'xp': 40, 'earnedOn': '2020-01-01'},
        },
      });
      await (await SharedPreferences.getInstance()).reload();
      await claim();
      expect(Storage.xp, 164);
      expect(Storage.xpToday, 24);
      expect(Storage.completedScenarios, contains('old'));
    },
  );

  test(
    'malformed scenario claim ledger is preserved and fails closed',
    () async {
      final raw = jsonEncode({
        'version': 1,
        'totalXp': 100,
        'listeningClaims': {},
        'scenarioClaims': null,
      });
      platform.values[Storage.listeningRewardLedgerPreferenceKey] = raw;
      await (await SharedPreferences.getInstance()).reload();
      await expectLater(claim(), throwsA(isA<PreferenceWriteException>()));
      expect(platform.values[Storage.listeningRewardLedgerPreferenceKey], raw);
      expect(
        platform.writes[Storage.listeningRewardLedgerPreferenceKey],
        isNull,
      );
    },
  );

  for (final strict in [false, true]) {
    test(
      'reset removes a delayed successful native commit; strict=$strict',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;
        final first = claim();
        await entered.future;
        final reset = strict ? Storage.resetAllStrict() : Storage.resetAll();
        await Future<void>.delayed(Duration.zero);
        release.complete();
        await first;
        await reset;
        expect(
          platform.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
        await (await SharedPreferences.getInstance()).reload();
        expect(Storage.xp, 0);
      },
    );

    test(
      'reset drains an admitted reward and rejects new claims; strict=$strict',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true;
        final first = claim();
        await entered.future;
        final reset = strict ? Storage.resetAllStrict() : Storage.resetAll();
        await Future<void>.delayed(Duration.zero);
        await expectLater(
          claim(attempt: 'late'),
          throwsA(isA<StaleLocalDataLifetimeException>()),
        );
        release.complete();
        await first;
        await reset;
        expect(Storage.xp, 0);
        expect(
          platform.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
        platform.rejectKey = null;
        await claim(attempt: 'fresh');
        expect(Storage.xp, 24);
      },
    );
  }

  test('listening cannot trust an unknown completion list', () async {
    platform
      ..rejectKey = 'kl_completed_scenarios'
      ..throwReply = true
      ..failReloadAfterWrite = true;
    await expectLater(
      Storage.addCompletedScenario('listening'),
      throwsA(isA<PreferenceOutcomeUnknownException>()),
    );
    await expectLater(
      Storage.claimListeningCompletionReward(
        scenarioId: 'listening',
        earnedXp: 40,
      ),
      throwsA(isA<PreferenceOutcomeUnknownException>()),
    );
    platform
      ..unavailable = false
      ..rejectKey = null;
    expect(
      await Storage.claimListeningCompletionReward(
        scenarioId: 'listening',
        earnedXp: 40,
      ),
      ListeningRewardClaimResult.awarded,
    );
    expect(Storage.xp, 140);
  });
}
