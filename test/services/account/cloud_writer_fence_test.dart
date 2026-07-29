import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/gye_service.dart';

void main() {
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

  test('an original snapshot stays stale after the UID becomes ready again', () {
    final sessions = CloudWriteSessionController();
    final original = sessions.acquire('uid-a');
    final fence = CloudWriteFence(sessions);
    sessions.acquire('uid-b');
    sessions.acquire('uid-a');

    expect(
      fence.verify(original, uid: 'uid-a'),
      CloudWriteResult.stale,
    );
  });

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
