import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/ildu_world_state_service.dart';
import 'package:ko_lernen_app/services/legacy_hanok_v1_importer.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';

import 'support/privacy_preferences_platform.dart';
import 'support/reward_preferences_platform.dart';

String _legacyState() => jsonEncode({
  'schemaVersion': 1,
  'manifestVersion': 'hanok-grants-v1',
  'cutoverVersion': 2,
  'seenRevealIds': <String>[],
  'activeLoadout': <String, Object>{},
  'careState': {
    'vacationMode': false,
    'displayEnabled': true,
    'notificationsEnabled': false,
    'settingsClock': {'counter': 1, 'actorId': 'device-a'},
    'notifiedTierIds': <String>[],
  },
});

class _CleanupReadHold extends PrivacyPreferencesPlatform {
  final cleanupReadEntered = Completer<void>();
  final releaseCleanupRead = Completer<void>();

  @override
  Future<bool> remove(String key) async {
    final result = await super.remove(key);
    if (key == 'flutter.${DataMigrationService.journalPreferenceKey}') {
      readEntered = cleanupReadEntered;
      releaseRead = releaseCleanupRead;
    }
    return result;
  }
}

class _FailureReadHold extends PrivacyPreferencesPlatform {
  final failureReadEntered = Completer<void>();
  final releaseFailureRead = Completer<void>();
  bool failedWrite = false;
  int recoveryReads = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final result = await super.setValue(valueType, key, value);
    if (key == 'flutter.${IlDuWorldStateService.preferenceKey}' && !result) {
      failedWrite = true;
    }
    return result;
  }

  @override
  Future<Map<String, Object>> getAll() {
    // Restore reads its evidence, verifies the restored keys, then the runner
    // reconciles its failure. Hold that last native snapshot before it returns.
    if (failedWrite && ++recoveryReads == 3) {
      readEntered = failureReadEntered;
      releaseRead = releaseFailureRead;
    }
    return super.getAll();
  }
}

class _ResetRemovalHold extends RewardPreferencesPlatform {
  _ResetRemovalHold({this.removalKey = 'kl_xp', this.failRemoval = false});
  final String removalKey;
  final bool failRemoval;
  final removalEntered = Completer<void>();
  final releaseRemoval = Completer<void>();
  @override
  Future<bool> remove(String key) async {
    if (key == 'flutter.$removalKey') {
      removalEntered.complete();
      await releaseRemoval.future;
      if (failRemoval) {
        throw StateError('Native reset removal rejected');
      }
    }
    return super.remove(key);
  }
}

Map<String, Object> _seed() => {
  DataMigrationService.versionPreferenceKey: 1,
  LegacyHanokV1Importer.legacyStateKey: _legacyState(),
  for (final key in PrivacyChoiceStorage.keys.values) key: true,
  PrivacyChoiceStorage.ageKey: 1990,
  'kl_custom_packs_v1': '[]',
  'kl_xp': 1,
};

Future<void> _boot(SharedPreferencesStorePlatform native) async {
  Storage.resetForTesting();
  DataMigrationService.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesStorePlatform.instance = native;
  await Storage.init();
}

Future<void> _acceptIndependentChoices() async {
  for (final purpose in PrivacyPurpose.values) {
    await PrivacyChoiceStorage.set(purpose, false);
  }
  await Storage.setBirthYear(DateTime.now().year - 10);
  await Storage.setCustomPacksRawJsonStrict('[{"id":"accepted"}]');
  await Storage.setXp(25);
}

Future<void> _expectIndependentChoices(
  Map<String, Object> native, {
  bool allowUnconfirmedAge = false,
}) async {
  await PrivacyChoiceStorage.refresh();
  final prefs = await SharedPreferences.getInstance();
  for (final purpose in PrivacyPurpose.values) {
    expect(native[PrivacyChoiceStorage.keys[purpose]], false);
    expect(PrivacyChoiceStorage.admitted(purpose), false);
    expect(PrivacyChoiceStorage.choice(purpose).confirmed, false);
  }
  expect(native[PrivacyChoiceStorage.ageKey], DateTime.now().year - 10);
  expect(
    PrivacyChoiceStorage.birthYear,
    allowUnconfirmedAge
        ? anyOf(0, DateTime.now().year - 10)
        : DateTime.now().year - 10,
  );
  expect(native['kl_custom_packs_v1'], '[{"id":"accepted"}]');
  expect(prefs.getString('kl_custom_packs_v1'), '[{"id":"accepted"}]');
  expect(Storage.customPacksRawJson, '[{"id":"accepted"}]');
  expect(
    prefs.getString(Storage.listeningRewardLedgerPreferenceKey),
    native[Storage.listeningRewardLedgerPreferenceKey],
  );
  expect(Storage.xp, 25);
}

String _backup(Map<String, Object> values) => jsonEncode({
  for (final entry in values.entries)
    entry.key: {
      't': entry.value is String
          ? 's'
          : entry.value is bool
          ? 'b'
          : 'i',
      'v': entry.value,
    },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  tearDown(() {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  for (final sessionOnly in [true, false]) {
    test(
      'migration drain preserves privacy fence and releases after ${sessionOnly ? 'session reset' : 'failed deletion'}',
      () async {
        final native = _ResetRemovalHold(
          removalKey: DataMigrationService.versionPreferenceKey,
          failRemoval: !sessionOnly,
        )..values.addAll(_seed());
        await _boot(native);
        final analytics = PrivacyFakeAnalytics();
        final crash = PrivacyFakeCrash();
        PrivacyConsentService.configureForTesting(
          analytics: analytics,
          crash: crash,
        );
        await PrivacyConsentService.applyStored();
        final entered = Completer<void>();
        final release = Completer<void>();
        native
          ..rejectKey = IlDuWorldStateService.preferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..successfulReply = true
          ..commitBeforeFailure = true;
        final migration = DataMigrationService.run();
        Future<void>? reset;
        Object? resetFailure;
        try {
          await entered.future.timeout(const Duration(seconds: 5));
          reset = (sessionOnly ? Storage.resetSession() : Storage.resetAll())
              .catchError((Object error) {
                resetFailure = error;
              });
          expect(PrivacyChoiceStorage.birthYear, 0);
          for (final purpose in PrivacyPurpose.values) {
            expect(PrivacyChoiceStorage.admitted(purpose), false);
          }
          release.complete();
          await migration;
          if (!sessionOnly) {
            await native.removalEntered.future.timeout(
              const Duration(seconds: 5),
            );
            await Future<void>.delayed(const Duration(milliseconds: 20));
            expect(PrivacyChoiceStorage.birthYear, 0);
            expect(PrivacyConsentService.canCollectAnalytics, false);
            expect(PrivacyConsentService.canCollectCrash, false);
            for (final purpose in PrivacyPurpose.values) {
              expect(PrivacyChoiceStorage.admitted(purpose), false);
            }
            native.releaseRemoval.complete();
          }
          await reset;
          expect(resetFailure, sessionOnly ? isNull : isA<StateError>());
          await PrivacyChoiceStorage.refresh();
          await Future<void>.delayed(const Duration(milliseconds: 20));
          // These operations preserved the confirmed native grants. The real
          // reset finalizer may now rebind authority and automatically apply SDKs.
          expect(PrivacyChoiceStorage.birthYear, 1990);
          for (final purpose in PrivacyPurpose.values) {
            expect(native.values[PrivacyChoiceStorage.keys[purpose]], true);
            expect(PrivacyChoiceStorage.admitted(purpose), true);
          }
          expect(PrivacyConsentService.canCollectAnalytics, true);
          expect(PrivacyConsentService.canCollectCrash, true);
        } finally {
          if (!release.isCompleted) {
            release.complete();
          }
          if (!native.releaseRemoval.isCompleted) {
            native.releaseRemoval.complete();
          }
          await migration;
          await reset;
        }
      },
    );
  }

  test(
    'migration cache refresh cannot reopen privacy before reset deletion',
    () async {
      final native = _ResetRemovalHold(
        removalKey: DataMigrationService.versionPreferenceKey,
      )..values.addAll(_seed());
      await _boot(native);
      final analytics = PrivacyFakeAnalytics();
      final crash = PrivacyFakeCrash();
      PrivacyConsentService.configureForTesting(
        analytics: analytics,
        crash: crash,
      );
      await PrivacyConsentService.applyStored();
      expect(PrivacyConsentService.canCollectAnalytics, true);
      expect(PrivacyConsentService.canCollectCrash, true);
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = IlDuWorldStateService.preferenceKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      final migration = DataMigrationService.run();
      Future<void>? reset;
      try {
        await entered.future.timeout(const Duration(seconds: 5));
        final analyticsBefore = analytics.calls.length;
        final crashBefore = crash.calls.length;
        reset = Storage.resetAll();
        expect(PrivacyChoiceStorage.birthYear, 0);
        release.complete();
        await migration;
        await native.removalEntered.future.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // The real reset has not yet deleted even its first key. Observe the
        // real storage listener/SDK application, without manually reapplying it.
        expect(
          {
            for (final purpose in PrivacyPurpose.values)
              purpose.name: PrivacyChoiceStorage.admitted(purpose),
            'age authority': PrivacyChoiceStorage.birthYear,
            'analytics application': PrivacyConsentService.canCollectAnalytics,
            'crash application': PrivacyConsentService.canCollectCrash,
            'analytics enable calls': analytics.calls
                .skip(analyticsBefore)
                .where((v) => v)
                .length,
            'crash enable calls': crash.calls
                .skip(crashBefore)
                .where((v) => v == 'collection:true')
                .length,
          },
          {
            for (final purpose in PrivacyPurpose.values) purpose.name: false,
            'age authority': 0,
            'analytics application': false,
            'crash application': false,
            'analytics enable calls': 0,
            'crash enable calls': 0,
          },
        );
        native.releaseRemoval.complete();
        await reset;
        await PrivacyChoiceStorage.refresh();
        for (final purpose in PrivacyPurpose.values) {
          expect(PrivacyChoiceStorage.admitted(purpose), false);
        }
      } finally {
        if (!release.isCompleted) {
          release.complete();
        }
        if (!native.releaseRemoval.isCompleted) {
          native.releaseRemoval.complete();
        }
        await migration;
        await reset;
      }
    },
  );

  test(
    'failed migration native read preserves concurrent confirmed learner cache',
    () async {
      final native = _FailureReadHold()
        ..values.addAll(_seed())
        ..rejectKey = IlDuWorldStateService.preferenceKey;
      await _boot(native);
      final migration = DataMigrationService.run();
      try {
        await native.failureReadEntered.future.timeout(
          const Duration(seconds: 5),
        );
        await _acceptIndependentChoices();
        native.releaseFailureRead.complete();
        expect((await migration).status, DataMigrationStatus.failed);
        await _expectIndependentChoices(native.values);
        await _boot(native);
        await _expectIndependentChoices(native.values);
      } finally {
        if (!native.releaseFailureRead.isCompleted) {
          native.releaseFailureRead.complete();
        }
        await migration;
      }
    },
  );

  test(
    'new scoped production backup owns only Hanok keys and schema marker',
    () async {
      final native = RewardPreferencesPlatform()..values.addAll(_seed());
      await _boot(native);
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = IlDuWorldStateService.preferenceKey
        ..writeEntered = entered
        ..releaseWrite = release;
      final migration = DataMigrationService.run();
      try {
        await entered.future.timeout(const Duration(seconds: 5));
        final backup =
            jsonDecode(
                  native.values[DataMigrationService.backupPreferenceKey]!
                      as String,
                )
                as Map;
        expect(backup.keys.toSet(), {
          DataMigrationService.versionPreferenceKey,
          LegacyHanokV1Importer.legacyStateKey,
        });
        final journal =
            jsonDecode(
                  native.values[DataMigrationService.journalPreferenceKey]!
                      as String,
                )
                as Map;
        expect(journal['scope'], 'hanok_v1_to_ildu_v3');
      } finally {
        release.complete();
        await migration;
      }
    },
  );

  for (final outcome in ['success', 'reject', 'throw', 'unknown']) {
    test(
      'production $outcome preserves all independent choices and restart',
      () async {
        final native = RewardPreferencesPlatform()..values.addAll(_seed());
        await _boot(native);
        final entered = Completer<void>();
        final release = Completer<void>();
        native
          ..rejectKey = IlDuWorldStateService.preferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..successfulReply = outcome == 'success' || outcome == 'unknown'
          ..commitBeforeFailure = outcome == 'success' || outcome == 'unknown'
          ..throwReply = outcome == 'throw'
          ..failReloadAfterWrite = outcome == 'unknown';
        final migration = DataMigrationService.run();
        try {
          await entered.future.timeout(const Duration(seconds: 5));
          await _acceptIndependentChoices();
          release.complete();
          final result = await migration;
          expect(
            result.status,
            outcome == 'success'
                ? DataMigrationStatus.migrated
                : DataMigrationStatus.failed,
          );
          native.unavailable = false;
          // A failed native read may conservatively keep age authority closed
          // until fresh initialization. It must never restore the old adult age.
          await _expectIndependentChoices(
            native.values,
            allowUnconfirmedAge: outcome == 'unknown',
          );
          await _boot(native);
          await _expectIndependentChoices(native.values);
          native.rejectKey = null;
          final retry = await DataMigrationService.run();
          expect(retry.writesAllowed, true);
          await _expectIndependentChoices(native.values);
          expect(
            native.values.containsKey(LegacyHanokV1Importer.legacyStateKey),
            false,
          );
          expect(
            native.values.containsKey(IlDuWorldStateService.preferenceKey),
            true,
          );
        } finally {
          if (!release.isCompleted) {
            release.complete();
          }
          await migration;
          native.unavailable = false;
        }
      },
    );
  }

  for (final scoped in [false, true]) {
    for (final committed in [false, true]) {
      test(
        'production replays ${scoped ? 'scoped' : 'legacy'} journal committed=$committed without unrelated rollback',
        () async {
          final before = _seed();
          final snapshot = scoped
              ? <String, Object>{
                  DataMigrationService.versionPreferenceKey: 1,
                  LegacyHanokV1Importer.legacyStateKey: _legacyState(),
                }
              : before;
          final native = RewardPreferencesPlatform()..values.addAll(before);
          await _boot(native);
          await _acceptIndependentChoices();
          native.values.addAll({
            DataMigrationService.versionPreferenceKey: committed ? 2 : 1,
            DataMigrationService.backupPreferenceKey: _backup(snapshot),
            DataMigrationService.journalPreferenceKey: jsonEncode({
              'from': 1,
              'to': 2,
              'phase': 'step_done',
              'step': 2,
              if (scoped) 'scope': 'hanok_v1_to_ildu_v3',
            }),
            IlDuWorldStateService.preferenceKey: jsonEncode(
              LegacyHanokV1Importer.decode(_legacyState()).toJson(),
            ),
            LegacyHanokV1Importer.markerKey: true,
          });
          native.values.remove(LegacyHanokV1Importer.legacyStateKey);
          await _boot(native);
          final result = await DataMigrationService.run();
          expect(
            result.status,
            committed
                ? DataMigrationStatus.upToDate
                : DataMigrationStatus.migrated,
          );
          await _expectIndependentChoices(native.values);
          expect(
            native.values.containsKey(
              DataMigrationService.journalPreferenceKey,
            ),
            false,
          );
          expect(
            native.values.containsKey(DataMigrationService.backupPreferenceKey),
            false,
          );
        },
      );
    }
  }

  test(
    'legacy recovery validates unrelated backup entries before narrowing',
    () async {
      final native = RewardPreferencesPlatform()..values.addAll(_seed());
      final snapshot = jsonDecode(_backup(_seed())) as Map<String, dynamic>;
      snapshot['kl_unrelated_invalid'] = {'t': 'b', 'v': 'not-a-bool'};
      native.values.addAll({
        DataMigrationService.backupPreferenceKey: jsonEncode(snapshot),
        DataMigrationService.journalPreferenceKey:
            '{"from":1,"to":2,"phase":"started"}',
      });
      await _boot(native);
      final before = Map<String, Object>.of(native.values);
      final result = await DataMigrationService.run();
      expect(result.failureCode, DataMigrationFailureCode.invalidBackup);
      expect(native.values, before);
    },
  );

  test(
    'an unstamped learner without Hanok state migrates without owning learner data',
    () async {
      final native = RewardPreferencesPlatform()
        ..values.addAll({'kl_xp': 10, 'kl_custom_packs_v1': '[]'});
      await _boot(native);
      final result = await DataMigrationService.run();
      expect(result.status, DataMigrationStatus.migrated);
      expect(native.values['kl_xp'], 10);
      expect(native.values['kl_custom_packs_v1'], '[]');
      expect(
        native.values.containsKey(IlDuWorldStateService.preferenceKey),
        false,
      );
    },
  );

  for (final scope in [null, 'unknown', 'hanok_v1_to_ildu_v3']) {
    test(
      'malformed or mismatched production journal scope $scope fails closed',
      () async {
        final native = RewardPreferencesPlatform()..values.addAll(_seed());
        native.values.addAll({
          DataMigrationService.backupPreferenceKey: _backup(_seed()),
          DataMigrationService.journalPreferenceKey: jsonEncode({
            'from': 1,
            'to': scope == 'hanok_v1_to_ildu_v3' ? 3 : 2,
            'phase': 'started',
            'scope': scope,
          }),
        });
        await _boot(native);
        final before = Map<String, Object>.of(native.values);
        final result = await DataMigrationService.run();
        expect(result.status, DataMigrationStatus.failed);
        expect(result.failureCode, DataMigrationFailureCode.invalidMetadata);
        expect(native.values, before);
      },
    );
  }

  for (final outcome in ['success', 'reject', 'throw']) {
    test(
      'reset drains a held production migration before deleting its state $outcome',
      () async {
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        final native = RewardPreferencesPlatform();
        native.values.addAll({
          DataMigrationService.versionPreferenceKey: 1,
          LegacyHanokV1Importer.legacyStateKey: _legacyState(),
        });
        SharedPreferencesStorePlatform.instance = native;
        await Storage.init();
        final entered = Completer<void>();
        final release = Completer<void>();
        native
          ..rejectKey = IlDuWorldStateService.preferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..successfulReply = outcome == 'success'
          ..commitBeforeFailure = outcome == 'success'
          ..throwReply = outcome == 'throw';
        final migration = DataMigrationService.run();
        Future<void>? reset;
        try {
          await entered.future.timeout(const Duration(seconds: 5));
          var resetFinished = false;
          reset = Storage.resetAll().then((_) => resetFinished = true);
          await Future<void>.delayed(const Duration(milliseconds: 20));
          final prematureReset = resetFinished;
          release.complete();
          await migration;
          await reset;
          expect(
            {
              'reset finished before native settlement': prematureReset,
              'native Hanok state survived deletion': native.values.containsKey(
                IlDuWorldStateService.preferenceKey,
              ),
              'domain Hanok state': Storage.ilduWorldStateRawJson,
            },
            {
              'reset finished before native settlement': false,
              'native Hanok state survived deletion': false,
              'domain Hanok state': '',
            },
          );
        } finally {
          if (!release.isCompleted) {
            release.complete();
          }
          await migration;
          await reset;
        }
      },
    );
  }

  test(
    'a reset rejects new migration admission without changing active state',
    () async {
      final native = _ResetRemovalHold()..values.addAll(_seed());
      await _boot(native);
      final reset = Storage.resetAll();
      try {
        await native.removalEntered.future.timeout(const Duration(seconds: 5));
        final writesBefore = Map<String, int>.of(native.writes);
        final last = DataMigrationService.lastResult;
        final lock = Storage.learningWritesLockReason;
        final blocked = await DataMigrationService.run();
        expect(blocked.failureCode, DataMigrationFailureCode.alreadyRunning);
        expect(DataMigrationService.lastResult, same(last));
        expect(Storage.learningWritesLockReason, lock);
        expect(native.writes, writesBefore);
        native.releaseRemoval.complete();
        await reset;
        expect(
          (await DataMigrationService.run()).status,
          DataMigrationStatus.fresh,
        );
      } finally {
        if (!native.releaseRemoval.isCompleted) {
          native.releaseRemoval.complete();
        }
        await reset;
      }
    },
  );

  test(
    'successful Hanok migration read cannot erase concurrent learner cache',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final native = _CleanupReadHold();
      native.values.addAll({
        DataMigrationService.versionPreferenceKey: 1,
        LegacyHanokV1Importer.legacyStateKey: _legacyState(),
        'kl_custom_packs_v1': '[]',
        'kl_xp': 1,
      });
      SharedPreferencesStorePlatform.instance = native;
      await Storage.init();
      final prefs = await SharedPreferences.getInstance();
      final migration = DataMigrationService.run();
      try {
        await native.cleanupReadEntered.future.timeout(
          const Duration(seconds: 5),
        );
        const acceptedPack = '[{"id":"accepted-during-migration"}]';
        await Storage.setCustomPacksRawJsonStrict(acceptedPack);
        await Storage.setXp(25);
        final acceptedLedger =
            native.values[Storage.listeningRewardLedgerPreferenceKey];
        expect(prefs.getString('kl_custom_packs_v1'), acceptedPack);
        expect(Storage.xp, 25);
        native.releaseCleanupRead.complete();
        expect((await migration).status, DataMigrationStatus.migrated);
        expect(
          {
            'native pack': native.values['kl_custom_packs_v1'],
            'cached pack': prefs.getString('kl_custom_packs_v1'),
            'domain pack': Storage.customPacksRawJson,
            'native XP ledger':
                native.values[Storage.listeningRewardLedgerPreferenceKey],
            'cached XP ledger': prefs.getString(
              Storage.listeningRewardLedgerPreferenceKey,
            ),
            'domain XP': Storage.xp,
          },
          {
            'native pack': acceptedPack,
            'cached pack': acceptedPack,
            'domain pack': acceptedPack,
            'native XP ledger': acceptedLedger,
            'cached XP ledger': acceptedLedger,
            'domain XP': 25,
          },
        );
      } finally {
        if (!native.releaseCleanupRead.isCompleted) {
          native.releaseCleanupRead.complete();
        }
        await migration;
      }
    },
  );

  test(
    'production Hanok rollback preserves a confirmed withdrawal at restart',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final native = PrivacyPreferencesPlatform();
      native.values.addAll({
        DataMigrationService.versionPreferenceKey: 1,
        LegacyHanokV1Importer.legacyStateKey: _legacyState(),
        PrivacyChoiceStorage.keys[PrivacyPurpose.pronunciation]!: true,
        PrivacyChoiceStorage.ageKey: 1990,
      });
      SharedPreferencesStorePlatform.instance = native;
      await Storage.init();
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = IlDuWorldStateService.preferenceKey
        ..entered = entered
        ..release = release;
      // No injected steps or target: exercise the real schema-2 registry.
      final migration = DataMigrationService.run();
      try {
        await entered.future.timeout(const Duration(seconds: 5));
        await Storage.setPronunciationConsent(false);
        expect(Storage.pronunciationConsent, isFalse);
        expect(
          native.values[PrivacyChoiceStorage.keys[PrivacyPurpose
              .pronunciation]],
          false,
        );
        release.complete();
        final result = await migration;
        expect(result.status, DataMigrationStatus.failed);
        final afterRollback = native
            .values[PrivacyChoiceStorage.keys[PrivacyPurpose.pronunciation]];
        // Recreate the shared cache and app authority from the same native bytes.
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = native;
        await Storage.init();
        expect(
          {
            'native after rollback': afterRollback,
            'native after restart':
                native.values[PrivacyChoiceStorage.keys[PrivacyPurpose
                    .pronunciation]],
            'authority after restart': Storage.pronunciationConsent,
          },
          {
            'native after rollback': false,
            'native after restart': false,
            'authority after restart': false,
          },
        );
      } finally {
        if (!release.isCompleted) {
          release.complete();
        }
        await migration;
      }
    },
  );
}
