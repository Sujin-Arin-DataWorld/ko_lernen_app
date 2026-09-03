import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

const _version = DataMigrationService.versionPreferenceKey;
const _backup = DataMigrationService.backupPreferenceKey;
const _journal = DataMigrationService.journalPreferenceKey;
const _secret = 'synthetic.person@example.test token=synthetic-secret-123';

// Hand-authored on-disk fixtures, independent of the migration serializer.
const _originalBackup =
    '{"kl_schema_version":{"t":"i","v":1},'
    '"kl_keep":{"t":"s","v":"original"}}';
const _started = '{"from":1,"to":2,"phase":"started"}';
const _done = '{"from":1,"to":2,"phase":"step_done","step":2}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late _NativeStore native;
  final originalPlatform = SharedPreferencesStorePlatform.instance;

  Future<void> boot([Map<String, Object>? values]) async {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = _NativeStore(values ?? {_version: 1, 'kl_keep': 'original'});
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    prefs = await SharedPreferences.getInstance();
    native.operations.clear();
  }

  Future<DataMigrationResult> run({Map<int, DataMigrationStep>? steps}) =>
      DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: steps ?? {2: (p) async => p.setString('kl_keep', 'changed')},
      );

  void expectLocked(DataMigrationResult result) {
    expect(result.status, DataMigrationStatus.failed);
    expect(result.writesAllowed, isFalse);
    expect(Storage.learningWritesLockReason, isNotNull);
  }

  tearDown(() {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  group('untrusted metadata is read before any mutation', () {
    for (final marker in <Object>[
      '1',
      true,
      <String>['1'],
      0,
      -1,
      1.5,
    ]) {
      test(
        'invalid ${marker.runtimeType} marker is preserved and locked',
        () async {
          await boot({_version: marker, 'kl_keep': 'original'});
          final before = Map<String, Object>.of(native.values);
          final result = await run();

          expectLocked(result);
          expect(result.fromVersion, isNull);
          expect(result.failureCode, DataMigrationFailureCode.invalidMetadata);
          expect(result.failurePhase, DataMigrationPhase.read);
          expect(native.values, before);
          expect(native.operations, isEmpty);
        },
      );
    }

    test(
      'initial reload failure returns a locked result without mutation',
      () async {
        await boot();
        native.failRead = true;
        final result = await run();
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.readFailed);
        expect(result.failurePhase, DataMigrationPhase.read);
        expect(result.fromVersion, isNull);
        expect(native.operations, isEmpty);
      },
    );

    test('reload detects future native marker behind an old cache', () async {
      await boot();
      native.values[_version] = 99;
      final result = await run();
      expect(result.status, DataMigrationStatus.futureVersion);
      expect(result.fromVersion, 99);
      expect(native.values[_version], 99);
      expect(native.operations, isEmpty);
    });

    test(
      'future marker preserves even malformed old recovery artifacts',
      () async {
        await boot({_version: 99, _backup: 'invalid', _journal: false});
        final before = Map<String, Object>.of(native.values);
        final result = await run();
        expect(result.status, DataMigrationStatus.futureVersion);
        expect(native.values, before);
        expect(native.operations, isEmpty);
      },
    );
  });

  group('backup and journal preparation is checked', () {
    for (final key in [_backup, _journal]) {
      for (final fault in [
        _Fault.reject,
        _Fault.throwBefore,
        _Fault.throwAfter,
      ]) {
        test('$key $fault prevents every step', () async {
          await boot();
          native.failNext('set', key, fault);
          var stepsRun = 0;
          final result = await run(steps: {2: (p) async => stepsRun++});
          expectLocked(result);
          expect(
            result.failureCode,
            fault == _Fault.reject
                ? DataMigrationFailureCode.writeRejected
                : DataMigrationFailureCode.writeFailed,
          );
          expect(result.failurePhase, DataMigrationPhase.prepare);
          expect(stepsRun, 0);
          expect(native.values[_version], 1);
          expect(native.values['kl_keep'], 'original');
          expect(
            native.operations.where((op) => op.startsWith('remove:')),
            isEmpty,
          );
        });
      }
    }

    test(
      'a rejected progress journal write rolls back successful step data',
      () async {
        await boot();
        final result = await run(
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              native.failNext('set', _journal, _Fault.reject);
            },
          },
        );
        expectLocked(result);
        expect(native.values['kl_keep'], 'original');
        expect(native.values[_version], 1);
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
      },
    );
  });

  group('recovery validates the complete original before mutation', () {
    final invalidBackups = <String, Object>{
      'late invalid typed value':
          '{"kl_schema_version":{"t":"i","v":1},'
          '"kl_keep":{"t":"s","v":"original"},"kl_bad":{"t":"i","v":"bad"}}',
      'non kl key':
          '{"kl_schema_version":{"t":"i","v":1},"foreign":{"t":"s","v":"x"}}',
      'recursive journal':
          '{"kl_schema_version":{"t":"i","v":1},"kl_migration_journal_v1":{"t":"s","v":"x"}}',
      'wrong original version': '{"kl_schema_version":{"t":"i","v":3}}',
      'invalid list element':
          '{"kl_schema_version":{"t":"i","v":1},"kl_list":{"t":"sl","v":["x",1]}}',
      'unknown type':
          '{"kl_schema_version":{"t":"i","v":1},"kl_keep":{"t":"object","v":{}}}',
      'empty backup': '',
      'non string backup': true,
    };
    for (final fixture in invalidBackups.entries) {
      test('${fixture.key} leaves all bytes and extras untouched', () async {
        await boot({
          _version: 1,
          'kl_keep': 'changed',
          'kl_new': 'retain until validated',
          _backup: fixture.value,
          _journal: _started,
        });
        final before = Map<String, Object>.of(native.values);
        expectLocked(await run());
        expect(native.values, before);
        expect(native.operations, isEmpty);
      });
    }

    for (final journal in <Object>[
      false,
      '{}',
      '{"from":1,"to":2,"phase":"other"}',
      '{"from":1,"to":2,"phase":"step_done","step":3}',
      '{"from":2,"to":1,"phase":"started"}',
    ]) {
      test('invalid journal $journal never restores or deletes', () async {
        await boot({_version: 1, _journal: journal, _backup: _originalBackup});
        final before = Map<String, Object>.of(native.values);
        expectLocked(await run());
        expect(native.values, before);
        expect(native.operations, isEmpty);
      });
    }

    test('incomplete transaction without its backup fails closed', () async {
      await boot({_version: 1, _journal: _started, 'kl_keep': 'changed'});
      final before = Map<String, Object>.of(native.values);
      expectLocked(await run());
      expect(native.values, before);
      expect(native.operations, isEmpty);
    });

    test('uncertain orphan backup is not overwritten or deleted', () async {
      await boot({_version: 1, _backup: _originalBackup, 'kl_keep': 'changed'});
      final before = Map<String, Object>.of(native.values);
      expectLocked(await run());
      expect(native.values, before);
      expect(native.operations, isEmpty);
    });

    test(
      'interrupted step restores original before the first retry step',
      () async {
        await boot({
          _version: 1,
          _backup: _originalBackup,
          _journal: _done,
          'kl_keep': 'changed',
          'kl_new': 'remove after original restored',
        });
        final result = await run(
          steps: {
            2: (p) async {
              expect(p.getString('kl_keep'), 'original');
              expect(p.containsKey('kl_new'), isFalse);
              await p.setString('kl_keep', 'complete');
            },
          },
        );
        expect(result.status, DataMigrationStatus.migrated);
        expect(native.values['kl_keep'], 'complete');
        expect(
          native.operations.indexOf('set:kl_keep'),
          lessThan(native.operations.indexOf('remove:kl_new')),
        );
      },
    );

    test(
      'partial restore retains evidence and retry repairs before steps',
      () async {
        await boot();
        final first = await run(
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              await p.setString('kl_new', 'temporary');
              native.failNext('set', 'kl_keep', _Fault.reject);
              throw StateError(_secret);
            },
          },
        );
        expectLocked(first);
        expect(first.failureCode, DataMigrationFailureCode.recoveryFailed);
        expect(first.failurePhase, DataMigrationPhase.restore);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values['kl_new'], 'temporary');
        final originalBackup = native.values[_backup];
        final originalJournal = native.values[_journal];
        expect(originalBackup, isNotNull);
        expect(originalJournal, isNotNull);
        expect(prefs.getString(_backup), originalBackup);
        native.operations.clear();

        final second = await run(
          steps: {
            2: (p) async {
              expect(p.getString('kl_keep'), 'original');
              expect(p.containsKey('kl_new'), isFalse);
              expect(p.getString(_backup), originalBackup);
            },
          },
        );
        expect(second.status, DataMigrationStatus.migrated);
        expect(native.values['kl_keep'], 'original');
        expect(native.values.containsKey('kl_new'), isFalse);
      },
    );
  });

  group('the native version marker is the commit point', () {
    for (final fault in [_Fault.reject, _Fault.throwBefore]) {
      test('$fault final marker rolls back despite optimistic cache', () async {
        await boot();
        native.failNext('set', _version, fault);
        expectLocked(await run());
        expect(native.values[_version], 1);
        expect(prefs.getInt(_version), 1);
        expect(native.values['kl_keep'], 'original');
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
      });
    }

    test(
      'post-persistence marker error is committed and never rolled back',
      () async {
        await boot();
        native.failNext('set', _version, _Fault.throwAfter);
        final result = await run();
        expect(result.status, DataMigrationStatus.migrated);
        expect(result.writesAllowed, isTrue);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'changed');
        expect(
          native.operations.where((op) => op == 'set:kl_keep'),
          hasLength(1),
        );
        expect(native.values.containsKey(_backup), isFalse);
        expect(native.values.containsKey(_journal), isFalse);
      },
    );

    test(
      'unreadable commit outcome retains data and all recovery evidence',
      () async {
        await boot();
        native.afterSet = (key) {
          if (key == _version) {
            native.failRead = true;
          }
        };
        final result = await run();
        expectLocked(result);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
        expect(
          native.operations.where((op) => op.startsWith('remove:')),
          isEmpty,
        );
      },
    );

    test(
      'unexpected native marker after commit is not speculatively restored',
      () async {
        await boot();
        native.afterSet = (key) {
          if (key == _version) {
            native.values[_version] = 7;
          }
        };
        expectLocked(await run());
        expect(native.values[_version], 7);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
      },
    );

    test(
      'a double equal to target is not an authoritative committed marker',
      () async {
        await boot();
        native.afterSet = (key) {
          if (key == _version) {
            native.values[_version] = 2.0;
          }
        };
        final result = await run();
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.outcomeUnknown);
        expect(result.failurePhase, DataMigrationPhase.commit);
        expect(native.values[_version], isA<double>());
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
        expect(
          native.operations.where((op) => op.startsWith('remove:')),
          isEmpty,
        );
      },
    );

    test(
      'persisted marker with false return is committed after reload',
      () async {
        await boot();
        native.failNext('set', _version, _Fault.persistReject);
        final result = await run();
        expect(result.status, DataMigrationStatus.migrated);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values.containsKey(_backup), isFalse);
      },
    );

    test(
      'corruption during steps prevents commit and all recovery writes',
      () async {
        await boot();
        final result = await run(
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              await p.setString('kl_new', 'keep');
              native.values[_backup] = '{"kl_keep":{"t":"i","v":"bad"}}';
              native.operations.clear();
            },
          },
        );
        expectLocked(result);
        expect(native.values[_version], 1);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values['kl_new'], 'keep');
        expect(native.values[_backup], '{"kl_keep":{"t":"i","v":"bad"}}');
        expect(native.operations.where((op) => op == 'set:$_version'), isEmpty);
        expect(
          native.operations.where((op) => op.startsWith('remove:')),
          isEmpty,
        );
      },
    );

    test(
      'late corruption after commit is preserved without rollback or cleanup',
      () async {
        await boot();
        native.afterSet = (key) {
          if (key == _version) {
            native.values[_backup] = 'corrupt';
          }
        };
        final result = await run();
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.invalidBackup);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values[_backup], 'corrupt');
        expect(native.values[_journal], isNotNull);
        expect(
          native.operations.where((op) => op.startsWith('remove:')),
          isEmpty,
        );
      },
    );
  });

  group('committed cleanup cannot roll back learning data', () {
    test(
      'older committed cleanup failure cannot unlock a newer schema runtime',
      () async {
        await boot({
          _version: 2,
          _journal: _done,
          _backup: _originalBackup,
          'kl_keep': 'committed',
        });
        native.failNext('remove', _backup, _Fault.reject);
        var stepsRun = 0;
        final first = await DataMigrationService.run(
          preferences: prefs,
          targetVersion: 3,
          steps: {3: (p) async => stepsRun++},
        );
        expectLocked(first);
        expect(first.fromVersion, 2);
        expect(first.toVersion, 3);
        expect(first.failureCode, DataMigrationFailureCode.writeRejected);
        expect(first.failurePhase, DataMigrationPhase.cleanup);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'committed');
        expect(native.values[_backup], _originalBackup);
        expect(native.values[_journal], _done);
        expect(stepsRun, 0);

        final second = await DataMigrationService.run(
          preferences: prefs,
          targetVersion: 3,
          steps: {
            3: (p) async {
              expect(p.getString('kl_keep'), 'committed');
              await p.setString('kl_keep', 'next');
              stepsRun++;
            },
          },
        );
        expect(second.status, DataMigrationStatus.migrated);
        expect(stepsRun, 1);
        expect(native.values[_version], 3);
        expect(native.values['kl_keep'], 'next');
      },
    );

    test(
      'cleanup reload failure preserves commitment and can finish next run',
      () async {
        await boot();
        native.afterRemove = (key) {
          if (key == _backup) {
            native.failRead = true;
          }
        };
        final first = await run();
        expect(first.status, DataMigrationStatus.migrated);
        expect(first.cleanupPending, isTrue);
        expect(first.failureCode, DataMigrationFailureCode.readFailed);
        expect(first.failurePhase, DataMigrationPhase.cleanup);
        expect(first.writesAllowed, isTrue);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values.containsKey(_backup), isFalse);
        expect(native.values[_journal], isNotNull);
        native.failRead = false;
        final second = await run(
          steps: {2: (p) async => fail('must not rerun steps')},
        );
        expect(second.status, DataMigrationStatus.upToDate);
        expect(second.cleanupPending, isFalse);
        expect(native.values.containsKey(_journal), isFalse);
      },
    );

    for (final key in [_backup, _journal]) {
      for (final fault in [
        _Fault.reject,
        _Fault.throwBefore,
        _Fault.throwAfter,
      ]) {
        test(
          '$key $fault keeps committed state and retries only cleanup',
          () async {
            await boot();
            native.failNext('remove', key, fault);
            final first = await run();
            expect(first.status, DataMigrationStatus.migrated);
            expect(first.cleanupPending, isTrue);
            expect(first.failurePhase, DataMigrationPhase.cleanup);
            expect(first.writesAllowed, isTrue);
            expect(Storage.learningWritesLockReason, isNull);
            expect(native.values[_version], 2);
            expect(native.values['kl_keep'], 'changed');
            expect(
              native.operations.indexOf('remove:$_backup'),
              lessThan(
                !native.operations.contains('remove:$_journal')
                    ? native.operations.length
                    : native.operations.indexOf('remove:$_journal'),
              ),
            );
            native.operations.clear();
            var stepsRun = 0;
            final second = await run(steps: {2: (p) async => stepsRun++});
            expect(second.writesAllowed, isTrue);
            expect(second.cleanupPending, isFalse);
            expect(stepsRun, 0);
            expect(native.values[_version], 2);
            expect(native.values['kl_keep'], 'changed');
            expect(native.values.containsKey(_backup), isFalse);
            expect(native.values.containsKey(_journal), isFalse);
            expect(
              native.operations.where((op) => op.startsWith('set:kl_')),
              isEmpty,
            );
          },
        );
      }
    }

    test(
      'corrupt backup alongside committed marker is preserved for diagnosis',
      () async {
        await boot({_version: 2, _journal: _done, _backup: 'corrupt'});
        final before = Map<String, Object>.of(native.values);
        expectLocked(await run());
        expect(native.values, before);
        expect(native.operations, isEmpty);
      },
    );
  });

  group('one synchronous owner', () {
    test(
      'learning writes lock before the first await and overlapping run is rejected',
      () async {
        await boot();
        final entered = Completer<void>();
        final release = Completer<void>();
        final first = run(
          steps: {
            2: (p) async {
              entered.complete();
              await release.future;
            },
          },
        );
        final immediateLock = Storage.learningWritesLockReason;
        await entered.future;
        final ownerJournal = native.values[_journal];
        final ownerResult = DataMigrationService.lastResult;
        final second = await run(steps: {}).timeout(const Duration(seconds: 2));
        final lockAfterRejected = Storage.learningWritesLockReason;
        final journalAfterRejected = native.values[_journal];
        final lastAfterRejected = DataMigrationService.lastResult;
        release.complete();
        expect((await first).status, DataMigrationStatus.migrated);

        expect(immediateLock, isNotNull);
        expect(second.status, DataMigrationStatus.failed);
        expect(second.failureCode, DataMigrationFailureCode.alreadyRunning);
        expect(second.failurePhase, DataMigrationPhase.acquire);
        expect(lockAfterRejected, immediateLock);
        expect(journalAfterRejected, ownerJournal);
        expect(lastAfterRejected, same(ownerResult));
      },
    );

    test(
      'awaiting a reentrant run rejects without deadlock or overwriting owner',
      () async {
        await boot();
        DataMigrationResult? nested;
        final outer = await run(
          steps: {
            2: (p) async {
              nested = await run(steps: {}).timeout(const Duration(seconds: 2));
              expect(Storage.learningWritesLockReason, isNotNull);
              expect(p.getString(_journal), isNotNull);
              await p.setString('kl_keep', 'outer');
            },
          },
        );
        expect(nested!.status, DataMigrationStatus.failed);
        expect(outer.status, DataMigrationStatus.migrated);
        expect(native.values['kl_keep'], 'outer');
        expect(DataMigrationService.lastResult, same(outer));
      },
    );
  });

  group('first stamp and exact restoration', () {
    test(
      'native Object lists of strings can be captured and migrated',
      () async {
        await boot({
          _version: 1,
          'kl_list': <Object?>['one', 'two'],
        });
        var stepsRun = 0;
        final result = await run(
          steps: {
            2: (p) async {
              expect(jsonDecode(p.getString(_backup)!)['kl_list'], {
                't': 'sl',
                'v': ['one', 'two'],
              });
              await p.setStringList('kl_list', ['complete']);
              stepsRun++;
            },
          },
        );
        expect(result.status, DataMigrationStatus.migrated);
        expect(stepsRun, 1);
        expect(native.values[_version], 2);
        expect(native.values['kl_list'], ['complete']);
        expect(native.values.containsKey(_backup), isFalse);
        expect(native.values.containsKey(_journal), isFalse);
      },
    );

    test(
      'rollback verifies string lists decoded as Object lists on every reload',
      () async {
        await boot({
          _version: 1,
          'kl_list': <Object?>['one', 'two'],
        });
        final result = await run(
          steps: {
            2: (p) async {
              await p.setStringList('kl_list', ['changed']);
              await p.setString('kl_new', 'temporary');
              throw StateError(_secret);
            },
          },
        );
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.stepFailed);
        expect(result.failurePhase, DataMigrationPhase.steps);
        expect(native.values[_version], 1);
        expect(native.values['kl_list'], ['one', 'two']);
        expect(native.values.containsKey('kl_new'), isFalse);
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
        expect(prefs.get('kl_list'), ['one', 'two']);
      },
    );

    test(
      'interrupted recovery accepts native Object string lists before retry steps',
      () async {
        await boot({
          _version: 1,
          _journal: _started,
          _backup:
              '{"kl_schema_version":{"t":"i","v":1},'
              '"kl_list":{"t":"sl","v":["one","two"]}}',
          'kl_list': <Object?>['changed'],
        });
        var stepsRun = 0;
        final result = await run(
          steps: {
            2: (p) async {
              expect(p.get('kl_list'), ['one', 'two']);
              stepsRun++;
            },
          },
        );
        expect(result.status, DataMigrationStatus.migrated);
        expect(stepsRun, 1);
        expect(native.values['kl_list'], ['one', 'two']);
        expect(native.values[_version], 2);
      },
    );

    for (final invalidElement in <Object?>[2, null]) {
      test(
        'native Object list containing $invalidElement fails before snapshot writes',
        () async {
          await boot({
            _version: 1,
            'kl_list': <Object?>['one', invalidElement],
            'kl_keep': 'original',
          });
          final before = Map<String, Object>.of(native.values);
          var stepsRun = 0;
          final result = await run(steps: {2: (p) async => stepsRun++});
          expectLocked(result);
          expect(result.failureCode, DataMigrationFailureCode.invalidBackup);
          expect(result.failurePhase, DataMigrationPhase.prepare);
          expect(stepsRun, 0);
          expect(native.operations, isEmpty);
          expect(native.values, before);
        },
      );
    }

    test(
      'validated recovery determines unstamped baseline after marker deletion',
      () async {
        await boot({
          _journal: _started,
          _backup:
              '{"kl_xp":{"t":"i","v":12},"kl_keep":{"t":"s","v":"original"}}',
          'kl_keep': 'changed',
        });
        var stepsRun = 0;
        final result = await run(
          steps: {
            2: (p) async {
              expect(p.getInt('kl_xp'), 12);
              expect(p.getString('kl_keep'), 'original');
              await p.setString('kl_keep', 'complete');
              stepsRun++;
            },
          },
        );
        expect(result.status, DataMigrationStatus.migrated);
        expect(result.fromVersion, 1);
        expect(stepsRun, 1);
        expect(native.values[_version], 2);
        expect(native.values['kl_keep'], 'complete');
      },
    );

    for (final fault in [
      _Fault.reject,
      _Fault.throwBefore,
      _Fault.throwAfter,
    ]) {
      test(
        'restore removal $fault retains original evidence for safe retry',
        () async {
          await boot();
          final first = await run(
            steps: {
              2: (p) async {
                await p.setString('kl_keep', 'changed');
                await p.setString('kl_new', 'temporary');
                native.failNext('remove', 'kl_new', fault);
                throw StateError(_secret);
              },
            },
          );
          expectLocked(first);
          expect(first.failureCode, DataMigrationFailureCode.recoveryFailed);
          expect(native.values['kl_keep'], 'original');
          final savedBackup = native.values[_backup];
          final savedJournal = native.values[_journal];
          expect(savedBackup, isNotNull);
          expect(savedJournal, isNotNull);
          expect(prefs.getString(_backup), savedBackup);
          expect(prefs.getString(_journal), savedJournal);
          final second = await run(
            steps: {
              2: (p) async {
                expect(p.getString('kl_keep'), 'original');
                expect(p.containsKey('kl_new'), isFalse);
                expect(p.getString(_backup), savedBackup);
              },
            },
          );
          expect(second.status, DataMigrationStatus.migrated);
          expect(native.values.containsKey('kl_new'), isFalse);
        },
      );
    }

    test(
      'second step failure restores native original and keeps progress journal',
      () async {
        await boot();
        final result = await DataMigrationService.run(
          preferences: prefs,
          targetVersion: 3,
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              await p.setString('kl_new', 'temporary');
            },
            3: (p) async => throw StateError(_secret),
          },
        );
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.stepFailed);
        expect(result.failurePhase, DataMigrationPhase.steps);
        expect(native.values[_version], 1);
        expect(native.values['kl_keep'], 'original');
        expect(native.values.containsKey('kl_new'), isFalse);
        expect(jsonDecode(native.values[_journal]! as String), {
          'from': 1,
          'to': 3,
          'phase': 'step_done',
          'step': 2,
        });
      },
    );

    test(
      'corrupt native backup after thrown step causes no restore writes',
      () async {
        await boot();
        final result = await run(
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              await p.setString('kl_new', 'temporary');
              native.values[_backup] = 'late corrupt original';
              native.operations.clear();
              throw StateError(_secret);
            },
          },
        );
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.invalidBackup);
        expect(result.failurePhase, DataMigrationPhase.restore);
        expect(native.operations, isEmpty);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values['kl_new'], 'temporary');
        expect(native.values[_backup], 'late corrupt original');
      },
    );

    for (final fault in [_Fault.reject, _Fault.throwBefore]) {
      test(
        'fresh $fault stamp leaves marker absent and writes locked',
        () async {
          await boot({});
          native.failNext('set', _version, fault);
          final result = await run();
          expectLocked(result);
          expect(native.values, isEmpty);
          expect(prefs.containsKey(_version), isFalse);
        },
      );
    }

    test('fresh post-persistence error can confirm the first stamp', () async {
      await boot({});
      native.failNext('set', _version, _Fault.throwAfter);
      final result = await run();
      expect(result.status, DataMigrationStatus.fresh);
      expect(native.values, {_version: 2});
    });

    test(
      'restoration preserves missing baseline marker and every supported type',
      () async {
        final initial = <String, Object>{
          'kl_xp': 12,
          'kl_keep': 'original',
          'kl_flag': true,
          'kl_double': 1.25,
          'kl_list': <String>['one', 'two'],
          'foreign': 'outside snapshot',
        };
        await boot(initial);
        final result = await run(
          steps: {
            2: (p) async {
              await p.setInt('kl_xp', 99);
              await p.setStringList('kl_list', ['changed']);
              await p.remove('kl_keep');
              await p.setBool('kl_flag', false);
              await p.setDouble('kl_double', 2.75);
              await p.setString('kl_new', 'temporary');
              throw StateError(_secret);
            },
          },
        );
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.stepFailed);
        final restoredData = Map<String, Object>.of(native.values)
          ..removeWhere((key, _) => key == _backup || key == _journal);
        expect(restoredData, initial);
        expect(prefs.containsKey(_version), isFalse);
        expect(prefs.getStringList('kl_list'), ['one', 'two']);
        expect(prefs.getDouble('kl_double'), 1.25);
      },
    );

    test(
      'a silently rejected restore is detected by exact native verification',
      () async {
        await boot();
        final result = await run(
          steps: {
            2: (p) async {
              await p.setString('kl_keep', 'changed');
              native.failNext(
                'set',
                'kl_keep',
                _Fault.acknowledgeWithoutPersist,
              );
              throw StateError(_secret);
            },
          },
        );
        expectLocked(result);
        expect(result.failureCode, DataMigrationFailureCode.recoveryFailed);
        expect(native.values['kl_keep'], 'changed');
        expect(native.values[_backup], isNotNull);
        expect(native.values[_journal], isNotNull);
      },
    );

    test('partial restore invalidates previously loaded pack cache', () async {
      const originalPack = '{"fixture":{"stage":"learn"}}';
      const changedPack = '{"fixture":{"stage":"boss"}}';
      await boot({_version: 1, 'kl_pack_progress_v1': originalPack});
      expect(Storage.packProgressJson('fixture')?['stage'], 'learn');
      final result = await run(
        steps: {
          2: (p) async {
            await p.setString('kl_pack_progress_v1', changedPack);
            native.failNext('set', 'kl_pack_progress_v1', _Fault.throwBefore);
            throw StateError(_secret);
          },
        },
      );
      expectLocked(result);
      expect(Storage.packProgressJson('fixture')?['stage'], 'boss');
      expect(
        jsonDecode(
          native.values[_backup]! as String,
        )['kl_pack_progress_v1']['v'],
        originalPack,
      );
    });
  });

  test(
    'step exceptions never expose injected email or token in diagnostics',
    () async {
      await boot();
      final messages = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        messages.add(message ?? '');
      };
      addTearDown(() => debugPrint = previousDebugPrint);
      final result = await run(
        steps: {2: (p) async => throw StateError(_secret)},
      );
      expectLocked(result);
      final exposed = [
        ...messages,
        result.toString(),
        result.diagnosticValue,
        Storage.learningWritesLockReason ?? '',
      ].join('\n');
      expect(exposed, isNot(contains('synthetic.person')));
      expect(exposed, isNot(contains('synthetic-secret')));
    },
  );
}

enum _Fault {
  reject,
  throwBefore,
  throwAfter,
  persistReject,
  acknowledgeWithoutPersist,
}

// A native boundary double: real SharedPreferences retains its own optimistic
// cache. Rejected/throwing writes must not accidentally look durable to the SUT.
class _NativeStore extends SharedPreferencesStorePlatform {
  _NativeStore(Map<String, Object> initial) : values = Map.of(initial);

  final Map<String, Object> values;
  final List<String> operations = [];
  final Map<String, List<_Fault>> faults = {};
  bool failRead = false;
  void Function(String key)? afterSet;
  void Function(String key)? afterRemove;

  void failNext(String operation, String key, _Fault fault) {
    faults.putIfAbsent('$operation:$key', () => []).add(fault);
  }

  Future<bool> _mutate(
    String operation,
    String prefixedKey,
    void Function(String) write,
  ) async {
    final key = prefixedKey.substring('flutter.'.length);
    final label = '$operation:$key';
    operations.add(label);
    final queue = faults[label];
    final fault = queue == null || queue.isEmpty ? null : queue.removeAt(0);
    if (fault == _Fault.reject) {
      return false;
    }
    if (fault == _Fault.acknowledgeWithoutPersist) {
      return true;
    }
    if (fault == _Fault.throwBefore) {
      throw StateError(_secret);
    }
    write(key);
    if (operation == 'set') {
      afterSet?.call(key);
    } else {
      afterRemove?.call(key);
    }
    if (fault == _Fault.throwAfter) {
      throw StateError(_secret);
    }
    if (fault == _Fault.persistReject) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _mutate('set', key, (key) {
        values[key] = value is List<String> ? List<String>.of(value) : value;
      });

  @override
  Future<bool> remove(String key) => _mutate('remove', key, values.remove);

  @override
  Future<Map<String, Object>> getAll() async {
    if (failRead) {
      throw StateError(_secret);
    }
    return values.map(
      (key, value) => MapEntry(
        'flutter.$key',
        // StandardMessageCodec/Pigeon can decode native string arrays with
        // this generic type on every read, even after setStringList succeeded.
        value is List ? List<Object?>.of(value) : value,
      ),
    );
  }

  @override
  Future<bool> clear() async {
    throw UnsupportedError('Migration must never clear preferences');
  }
}
