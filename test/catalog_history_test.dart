import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/catalog_history_lease.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late _Store native;
  setUp(() async {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = _Store();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
  });
  tearDown(() {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferencesStorePlatform.instance = original;
  });

  test(
    'legacy migration validates the catalog tab and is idempotent',
    () async {
      await Storage.setLastActivityId('chosung');
      await Storage.initializeCatalogHistory();
      await Storage.initializeCatalogHistory();
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), 'chosung');
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      expect(Storage.lastActivityId, isNull);
      expect(native.historyWrites, 1);
    },
  );

  test('unknown and removed IDs never migrate', () async {
    await Storage.setLastActivityId('removed_activity');
    await Storage.initializeCatalogHistory();
    expect(Storage.recentCatalogActivityId(SoriStageTab.games), isNull);
    expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
    expect(native.historyWrites, 0);
  });

  test(
    'newer tab launch wins over legacy and shared routes keep separate IDs',
    () async {
      await Storage.setLastActivityId('grammar');
      await Storage.recordCatalogActivity('my_words');
      await Storage.recordCatalogActivity('custom_practice');
      await Storage.initializeCatalogHistory();
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), 'my_words');
      expect(
        Storage.recentCatalogActivityId(SoriStageTab.games),
        'custom_practice',
      );
    },
  );

  test(
    'a launch arriving during migration wins after the delayed platform write',
    () async {
      await Storage.setLastActivityId('grammar');
      final gate = native.delayNextHistory();
      final migration = Storage.initializeCatalogHistory();
      await native.submitted.future;
      final launch = Storage.recordCatalogActivity('listening');
      gate.complete();
      await Future.wait([migration, launch]);
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), 'listening');
      expect(
        jsonDecode(
          native.values[Storage.recentLearnActivityPreferenceKey]! as String,
        )['id'],
        'listening',
      );
    },
  );

  for (final strict in [false, true]) {
    for (final migration in [false, true]) {
      test(
        '${strict ? 'strict' : 'ordinary'} reset drains ${migration ? 'migration' : 'launch'} setters before deletion',
        () async {
          await Storage.setLastActivityId('grammar');
          final gate = native.delayNextHistory();
          final write = migration
              ? Storage.initializeCatalogHistory()
              : Storage.recordCatalogActivity('chosung');
          await native.submitted.future;
          var finished = false;
          final reset = (strict ? Storage.resetAllStrict() : Storage.resetAll())
              .then((_) => finished = true);
          await Future<void>.delayed(Duration.zero);
          expect(finished, isFalse);
          // New work while reset is admitted must not re-create history either.
          await Storage.recordCatalogActivity('listening');
          gate.complete();
          await Future.wait([write, reset]);
          expect(
            native.values.keys.where((key) => key.startsWith('kl_recent_')),
            isEmpty,
          );
          expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
          expect(Storage.recentCatalogActivityId(SoriStageTab.games), isNull);
          expect(Storage.lastActivityId, isNull);
        },
      );
    }
  }

  test(
    'preparation from an old local lifetime cannot record after reset',
    () async {
      final lease = CatalogHistoryLease.capture();
      await Storage.resetAll();
      await Storage.recordCatalogActivity('chosung', lease: lease);
      expect(native.historyWrites, 0);
    },
  );

  test(
    'old account callbacks and already-submitted setters stay invisible to the next account',
    () async {
      cloudWriteSessionController.acquire('first');
      final lease = CatalogHistoryLease.capture();
      final gate = native.delayNextHistory();
      final pending = Storage.recordCatalogActivity('chosung', lease: lease);
      await native.submitted.future;
      cloudWriteSessionController.acquire('second');
      await Storage.recordCatalogActivity('grammar', lease: lease);
      gate.complete();
      await pending;
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), isNull);
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      await Storage.recordCatalogActivity('cloze');
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), 'cloze');
      cloudWriteSessionController.transition(CloudWriteMode.quiesced);
      await Storage.recordCatalogActivity('grammar');
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), isNull);
    },
  );

  test(
    'test reset drains old queue without importing it into new preferences',
    () async {
      final gate = native.delayNextHistory();
      final old = Storage.recordCatalogActivity('chosung');
      await native.submitted.future;
      final queued = Storage.recordCatalogActivity('grammar');
      final oldLease = CatalogHistoryLease.capture();
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final initialized = Storage.init();
      gate.complete();
      await Future.wait([old, queued, initialized]);
      await Storage.recordCatalogActivity('grammar', lease: oldLease);
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), isNull);
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), isNull);
      await Storage.recordCatalogActivity('listening');
      expect(Storage.recentCatalogActivityId(SoriStageTab.learn), 'listening');
    },
  );

  test(
    'storage failure is non-blocking and a later launch still writes',
    () async {
      native.fail = true;
      await Storage.recordCatalogActivity('chosung');
      native.fail = false;
      await Storage.recordCatalogActivity('cloze');
      expect(Storage.recentCatalogActivityId(SoriStageTab.games), 'cloze');
    },
  );
}

class _Store extends SharedPreferencesStorePlatform {
  final values = <String, Object>{};
  int historyWrites = 0;
  bool fail = false;
  Completer<void>? _delay;
  Completer<void> submitted = Completer<void>();
  Completer<void> delayNextHistory() {
    submitted = Completer<void>();
    return _delay = Completer<void>();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final normalized = key.replaceFirst('flutter.', '');
    if (normalized.startsWith('kl_recent_')) {
      historyWrites++;
      if (fail) {
        throw StateError('preference write failed');
      }
      final wait = _delay;
      _delay = null;
      if (wait != null) {
        submitted.complete();
        await wait.future;
      }
    }
    values[normalized] = value;
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async =>
      values.map((key, value) => MapEntry('flutter.$key', value));
  @override
  Future<bool> remove(String key) async {
    values.remove(key.replaceFirst('flutter.', ''));
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}
