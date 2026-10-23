import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/lernpfad_catalog.dart';
import 'package:ko_lernen_app/services/lernpfad_lease.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/models/lernpfad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LernpfadCatalog catalog;
  late CourseProgressService progress;
  late CloudWriteSessionController accounts;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    progress = CourseProgressService(
      () => throw StateError('No v5 mutation allowed'),
    );
    accounts = CloudWriteSessionController()..acquire('learner-a');
    catalog = LernpfadCatalog.parse(
      jsonDecode(File('assets/data/lernpfad_v2.json').readAsStringSync()),
      jsonDecode(
        File('assets/data/lernpfad_foundation.json').readAsStringSync(),
      ),
      PhaseTaskCatalog.parse(
        jsonDecode(File('assets/data/phase_tasks.json').readAsStringSync()),
      ),
    );
  });
  test(
    'selection survives restart and leaves original mastery bytes untouched',
    () async {
      final lease = LernpfadLease(sessions: accounts);
      final before = Storage.courseMasterySnapshotRawJson;
      await progress.mutateLernpfad(
        catalog,
        lease,
        (s) => s.selectBand('B2.2', catalog),
      );
      final restarted = CourseProgressService(
        () => throw StateError('No v5 mutation'),
      );
      expect(
        (await restarted.readLernpfad(catalog, lease)).selectedBandId,
        'B2.2',
      );
      expect(Storage.courseMasterySnapshotRawJson, before);
    },
  );
  test(
    'different account cannot see or mutate the previous account state',
    () async {
      final old = LernpfadLease(sessions: accounts);
      await progress.mutateLernpfad(
        catalog,
        old,
        (s) => s.selectBand('C2.2', catalog),
      );
      accounts.acquire('learner-b');
      expect(
        (await progress.readLernpfad(
          catalog,
          LernpfadLease(sessions: accounts),
        )).selectedBandId,
        'F0.1',
      );
      await expectLater(
        progress.mutateLernpfad(catalog, old, (s) => s),
        throwsStateError,
      );
      accounts.acquire('learner-a');
      await expectLater(progress.readLernpfad(catalog, old), throwsStateError);
    },
  );
  test(
    'reset removes extension and a stale lesson cannot resurrect it',
    () async {
      final lease = LernpfadLease(sessions: accounts);
      await progress.mutateLernpfad(
        catalog,
        lease,
        (s) => s.selectBand('A2.1', catalog),
      );
      LocalDataLifetime.invalidate();
      await Storage.resetAll();
      await expectLater(
        progress.mutateLernpfad(catalog, lease, (s) => s),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      final fresh = await progress.readLernpfad(
        catalog,
        LernpfadLease(sessions: accounts),
      );
      expect(fresh.selectedBandId, 'F0.1');
    },
  );
  test(
    'a future extension is retained and cannot be overwritten by selection',
    () async {
      final lease = LernpfadLease(sessions: accounts);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Storage.lernpfadKey(lease.owner), '{"version":99}');
      await expectLater(
        progress.mutateLernpfad(
          catalog,
          lease,
          (s) => s.selectBand('A1.1', catalog),
        ),
        throwsFormatException,
      );
      expect(
        prefs.getString(Storage.lernpfadKey(lease.owner)),
        '{"version":99}',
      );
    },
  );

  test(
    'a rejected native write cannot publish an optimistic selection',
    () async {
      final store = FailingPathStore();
      final lease = LernpfadLease(sessions: accounts);
      store.reject = true;
      await expectLater(
        Storage.mutateLernpfad(
          lease.owner,
          (_) => LernpfadState.empty().selectBand('C2.2', catalog).encode(),
          assertCurrentWrite: lease.assertCurrent,
          preferences: store,
        ),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(store.durable, isEmpty);
      store.reject = false;
      String? seen;
      await Storage.mutateLernpfad(
        lease.owner,
        (before) {
          seen = before;
          return before;
        },
        assertCurrentWrite: lease.assertCurrent,
        preferences: store,
      );
      expect(seen, '');
    },
  );

  test(
    'an uncertain write is reread before deriving the next action',
    () async {
      final store = FailingPathStore()..unknown = true;
      final lease = LernpfadLease(sessions: accounts);
      final encoded = LernpfadState.empty()
          .selectBand('C2.2', catalog)
          .encode();
      await expectLater(
        Storage.mutateLernpfad(
          lease.owner,
          (_) => encoded,
          assertCurrentWrite: lease.assertCurrent,
          preferences: store,
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      store.unknown = false;
      String? seen;
      await Storage.mutateLernpfad(
        lease.owner,
        (before) {
          seen = before;
          return before;
        },
        assertCurrentWrite: lease.assertCurrent,
        preferences: store,
      );
      expect(seen, encoded);
    },
  );

  test(
    'two lesson routes cannot erase help or overwrite a newer cursor',
    () async {
      final lease = LernpfadLease(sessions: accounts);
      final lesson = catalog.lessons.values.first;
      final start = FoundationRun.start(lesson, 'route-a', DateTime.now());
      await progress.saveFoundationRun(catalog, lease, start, expected: null);
      final helped = start.withHelp();
      await progress.saveFoundationRun(catalog, lease, helped, expected: start);
      await expectLater(
        progress.saveFoundationRun(
          catalog,
          lease,
          start.advance(lesson),
          expected: start,
        ),
        throwsStateError,
      );
      final stored = await progress.readLernpfad(catalog, lease);
      expect(stored.active!.helped, isTrue);
      expect(stored.active!.step, 0);
      final other = FoundationRun.start(lesson, 'route-b', DateTime.now());
      await expectLater(
        progress.saveFoundationRun(catalog, lease, other, expected: null),
        throwsStateError,
      );
      await progress.saveFoundationRun(catalog, lease, helped, expected: start);
      expect(
        (await progress.readLernpfad(catalog, lease)).active!.helped,
        isTrue,
      );
    },
  );
}

class FailingPathStore implements PreferenceStringStore {
  final durable = <String, String>{}, cache = <String, String>{};
  bool reject = false, unknown = false;
  @override
  bool containsKey(String key) => cache.containsKey(key);
  @override
  String? getString(String key) => cache[key];
  @override
  Future<void> reload() async {
    if (unknown) {
      throw StateError('Cannot confirm native write');
    }
    cache
      ..clear()
      ..addAll(durable);
  }

  @override
  Future<bool> remove(String key) async {
    if (unknown) {
      throw StateError('Native store unavailable');
    }
    cache.remove(key);
    durable.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    cache[key] = value;
    if (reject) {
      return false;
    }
    durable[key] = value;
    if (unknown) {
      throw StateError('Acknowledgement lost');
    }
    return true;
  }
}
