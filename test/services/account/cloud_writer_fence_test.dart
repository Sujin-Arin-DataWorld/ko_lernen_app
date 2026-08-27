import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/gye_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stale prepared write cannot reach the irreversible action', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    final prepared = Completer<void>();
    var writes = 0;

    final result = fence.run(
      uid: 'uid-a',
      prepare: () => prepared.future,
      action: () async => writes++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    prepared.complete();

    expect(await result, CloudWriteResult.stale);
    expect(writes, 0);
  });

  test('a late failing action resolves as typed stale', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    final actionStarted = Completer<void>();
    final actionMayFail = Completer<void>();

    final result = fence.run(
      uid: 'uid-a',
      action: () async {
        actionStarted.complete();
        await actionMayFail.future;
        throw StateError('late failure');
      },
    );
    await actionStarted.future;
    sessions.acquire('uid-b');
    actionMayFail.complete();

    expect(await result, CloudWriteResult.stale);
  });

  test(
    'an original snapshot stays stale after the UID becomes ready again',
    () {
      final sessions = CloudWriteSessionController();
      final original = sessions.acquire('uid-a');
      final fence = CloudWriteFence(sessions);
      sessions.acquire('uid-b');
      sessions.acquire('uid-a');

      expect(fence.verify(original, uid: 'uid-a'), CloudWriteResult.stale);
    },
  );

  for (final mode in <CloudWriteMode>[
    CloudWriteMode.quiesced,
    CloudWriteMode.reconciling,
    CloudWriteMode.cleanupPending,
    CloudWriteMode.blocked,
  ]) {
    test('$mode blocks work before preparation starts', () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('uid-a');
      sessions.transition(mode);
      final fence = CloudWriteFence(sessions);
      var preparations = 0;
      var writes = 0;

      final result = await fence.run(
        uid: 'uid-a',
        prepare: () async => preparations++,
        action: () async => writes++,
      );

      expect(result, CloudWriteResult.blocked);
      expect(preparations, 0);
      expect(writes, 0);
    });
  }

  test('a current ready session preserves the existing write path', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    final events = <String>[];

    final result = await fence.run(
      uid: 'uid-a',
      prepare: () async => events.add('prepare'),
      action: () async => events.add('write'),
    );

    expect(result, CloudWriteResult.completed);
    expect(events, <String>['prepare', 'write']);
  });

  test(
    'normal identity replacement is ready before immediate backup',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('anonymous-uid');
      final synchronizer = CloudWriteSessionSynchronizer(sessions);

      expect(
        synchronizer.synchronizeReady('existing-account-uid'),
        CloudWriteResult.completed,
      );
      expect(sessions.current?.uid, 'existing-account-uid');
      expect(sessions.current?.mode, CloudWriteMode.ready);
    },
  );

  test('identity replacement cannot reopen a non-ready transition', () {
    final sessions = CloudWriteSessionController();
    sessions.acquire('source-uid');
    sessions.transition(CloudWriteMode.quiesced);
    final synchronizer = CloudWriteSessionSynchronizer(sessions);

    expect(
      synchronizer.synchronizeReady('target-uid'),
      CloudWriteResult.blocked,
    );
    expect(sessions.current?.uid, 'source-uid');
    expect(sessions.current?.mode, CloudWriteMode.quiesced);
  });

  test('CloudSync concrete seam rejects a session-A prepared backup', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final prepared = Completer<void>();
    var writes = 0;

    final result = CloudSync.backupWithSession(
      sessions: sessions,
      uid: 'uid-a',
      prepare: () => prepared.future,
      write: () async => writes++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    prepared.complete();

    expect(await result, CloudWriteResult.stale);
    expect(writes, 0);
  });

  test(
    'CloudSync concrete seam rejects a backup prepared across local reset',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{'kl_xp': 42});
      Storage.resetForTesting();
      await Storage.init();
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final preparationStarted = Completer<void>();
      final preparationMayFinish = Completer<void>();
      var writes = 0;

      final result = CloudSync.backupWithSession(
        sessions: sessions,
        uid: 'uid-a',
        prepare: () async {
          preparationStarted.complete();
          await preparationMayFinish.future;
        },
        write: () async => writes++,
      );
      await preparationStarted.future;
      await Storage.resetAll();
      preparationMayFinish.complete();

      expect(await result, CloudWriteResult.stale);
      expect(writes, 0);
      expect(Storage.xp, 0);
    },
  );

  test(
    'stale CloudWriteSession stops before course restore persistence',
    () async {
      const local =
          '{"version":2,"placementLevel":"a1",'
          '"currentCourseUnitId":"a1_01_greetings_hangul",'
          '"completedUnitIds":[],"bypassedPrerequisiteUnitIds":[],'
          '"evidence":[],"scenarioCheckpoints":[]}';
      SharedPreferences.setMockInitialValues({
        Storage.courseMasterySnapshotPreferenceKey: local,
      });
      Storage.resetForTesting();
      Storage.resetCourseMasteryForTesting();
      await Storage.init();
      final sessions = CloudWriteSessionController();
      final stale = sessions.acquire('uid-a');
      sessions.acquire('uid-b');
      var sessionChecks = 0;
      var generationReads = 0;
      var courseMerges = 0;

      await expectLater(
        CloudSync.applyRestorePayload(
          const {
            'course_mastery_json':
                '{"version":2,"placementLevel":"a1",'
                '"currentCourseUnitId":"a1_01_greetings_hangul",'
                '"completedUnitIds":[],"bypassedPrerequisiteUnitIds":[],'
                '"evidence":[],"scenarioCheckpoints":[]}',
          },
          beforeWrite: () {
            sessionChecks++;
            sessions.assertCurrent(stale);
          },
          courseGenerationReader: () {
            generationReads++;
            return Storage.courseMasterySnapshotRawJson;
          },
          courseSnapshotMerger:
              (
                raw, {
                required expectedGeneration,
                beforeRead,
                beforeWrite,
              }) async {
                courseMerges++;
                beforeRead?.call();
                beforeWrite?.call();
              },
        ),
        throwsStateError,
      );

      expect(sessionChecks, 1);
      expect(generationReads, 0);
      expect(courseMerges, 0);
      expect(Storage.courseMasterySnapshotRawJson, local);
    },
  );

  test('a stale media collection pass cannot garbage-collect', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    final inventoryReady = Completer<void>();
    var garbageCollections = 0;

    final result = fence.run(
      uid: 'uid-a',
      prepare: () => inventoryReady.future,
      action: () async => garbageCollections++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.transition(CloudWriteMode.quiesced);
    inventoryReady.complete();

    expect(await result, CloudWriteResult.stale);
    expect(garbageCollections, 0);
  });

  test('managed media GC is inert while the session is quiesced', () async {
    final sandbox = await Directory.systemTemp.createTemp('fenced_media_gc_');
    addTearDown(() => sandbox.delete(recursive: true));
    final documents = Directory('${sandbox.path}/documents')..createSync();
    final temporary = Directory('${sandbox.path}/temporary')..createSync();
    final source = File('${temporary.path}/source.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3]);
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final store = ManagedMediaStore(
      documentsDirectory: documents,
      temporaryDirectory: temporary,
      sessions: sessions,
    );
    final lease = await store.stage(source, ManagedMediaKind.book);
    final promotion = await store.promote(lease);
    await store.finalize(promotion);
    final committed = File(store.pathForTesting(promotion.reference));
    sessions.transition(CloudWriteMode.quiesced);

    await store.deleteIfUnreferenced(
      promotion.reference,
      ManagedMediaReferenceSnapshot.fromJson(
        bookshelfJson: '{}',
        customPacksJson: '{}',
      ),
    );

    expect(await committed.exists(), isTrue);
  });

  test('an epoch-bound Gye stream stops yielding after transition', () async {
    final sessions = CloudWriteSessionController();
    sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    final source = StreamController<int>();
    final values = <int>[];
    final done = Completer<void>();

    fence
        .bindStream(uid: 'uid-a', source: source.stream)
        .listen(values.add, onDone: done.complete);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    sessions.transition(CloudWriteMode.quiesced);
    source.add(2);
    await done.future;

    expect(values, <int>[1]);
    await source.close();
  });

  test(
    'an epoch-bound Gye stream cancels without another source event',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('uid-a');
      final source = StreamController<int>();
      final done = Completer<void>();

      CloudWriteFence(sessions)
          .bindStream(uid: 'uid-a', source: source.stream)
          .listen((_) {}, onDone: done.complete);
      await Future<void>.delayed(Duration.zero);
      sessions.transition(CloudWriteMode.quiesced);

      await done.future.timeout(const Duration(milliseconds: 250));
      await source.close();
    },
  );

  test('myGyeIds discards a stale one-shot read', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final loaded = Completer<List<String>>();

    final result = GyeService.myGyeIdsForSession(
      sessions: sessions,
      uid: 'uid-a',
      load: () => loaded.future,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    loaded.complete(<String>['gye-a']);

    expect(await result, isEmpty);
  });

  test(
    'fetchGye discards session-A data after session B becomes current',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final loaded = Completer<GyeMeta?>();

      final result = GyeService.fetchGyeForSession(
        sessions: sessions,
        uid: 'uid-a',
        load: () => loaded.future,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      loaded.complete(_gyeMeta('gye-a'));

      expect(await result, isNull);
    },
  );

  test('myGyeMetas discards the whole stale read chain', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final firstMeta = Completer<GyeMeta?>();
    var metaLoads = 0;

    final result = GyeService.myGyeMetasForSession(
      sessions: sessions,
      uid: 'uid-a',
      loadIds: () async => <String>['gye-a', 'gye-b'],
      loadMeta: (id) {
        metaLoads++;
        return metaLoads == 1
            ? firstMeta.future
            : Future<GyeMeta?>.value(_gyeMeta(id));
      },
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    firstMeta.complete(_gyeMeta('gye-a'));

    expect(await result, isEmpty);
    expect(metaLoads, 1);
  });

  test('Gye rate limits reset for a new session epoch', () {
    final limiter = GyeActionRateLimiter(limit: 2);
    const first = CloudWriteSession(
      uid: 'uid-a',
      epoch: 1,
      mode: CloudWriteMode.ready,
    );
    const second = CloudWriteSession(
      uid: 'uid-b',
      epoch: 2,
      mode: CloudWriteMode.ready,
    );
    final now = DateTime.utc(2026, 7, 29);

    expect(limiter.tryAcquire(first, now), isTrue);
    expect(limiter.tryAcquire(first, now), isTrue);
    expect(limiter.tryAcquire(first, now), isFalse);
    expect(limiter.tryAcquire(second, now), isTrue);
  });
}

GyeMeta _gyeMeta(String id) {
  return GyeMeta(id: id, name: id, code: id, ownerId: 'uid-a');
}
