import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/firestore_progress_service.dart';
import 'package:ko_lernen_app/services/gye_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/shared_pack_service.dart';

void main() {
  test(
    'manual cloud restore cannot apply session-A data after A-to-B',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final loaded = Completer<CloudReadResult<Map<String, dynamic>>>();
      var localWrites = 0;
      var bookshelfRestores = 0;

      final result = CloudSync.restoreWithSession(
        sessions: sessions,
        uid: 'uid-a',
        readAccount: () => loaded.future,
        applyAccount: (data, beforeWrite) async {
          beforeWrite();
          localWrites += 1;
        },
        restoreBookshelf: (expectedSession) async {
          bookshelfRestores += 1;
          return CloudWriteResult.completed;
        },
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      loaded.complete(
        const CloudReadResult.present(<String, dynamic>{
          'progress': <String, dynamic>{'xp': 10},
        }),
      );

      expect(await result, CloudWriteResult.stale);
      expect(localWrites, 0);
      expect(bookshelfRestores, 0);
    },
  );

  test(
    'shared-pack publish cannot write after its session goes stale',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final prepared = Completer<void>();
      var writes = 0;

      final result = SharedPackService.publishWithSession(
        sessions: sessions,
        uid: 'uid-a',
        prepare: () => prepared.future,
        write: () async => writes += 1,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.transition(CloudWriteMode.quiesced);
      prepared.complete();

      expect(await result, CloudWriteResult.stale);
      expect(writes, 0);
    },
  );

  test(
    'Firestore progress does not commit a prepared session-A save',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final prepared = Completer<void>();
      var commits = 0;

      final result = FirestoreProgressService.savePackWithSession(
        _progress(),
        sessions: sessions,
        uid: 'uid-a',
        prepare: () => prepared.future,
        write: () async => commits++,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      prepared.complete();

      expect(await result, CloudWriteResult.stale);
      expect(commits, 0);
    },
  );

  test('pack pull does not overwrite local progress after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final loaded = Completer<Map<String, PackProgress>>();
    var overwrites = 0;

    final result = PackProgressService.pullFromCloudWithSession(
      sessions: sessions,
      uid: 'uid-a',
      loadRemote: () => loaded.future,
      loadLocal: () => const <String, PackProgress>{},
      persistLocal: (_) async => overwrites++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    loaded.complete(<String, PackProgress>{'pack-a': _progress()});

    expect(await result, CloudWriteResult.stale);
    expect(overwrites, 0);
  });

  test(
    'pack push does not commit prepared local progress after A-to-B',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final prepared = Completer<void>();
      var commits = 0;

      final result = PackProgressService.pushToCloudWithSession(
        sessions: sessions,
        uid: 'uid-a',
        loadLocal: () => <String, PackProgress>{'pack-a': _progress()},
        prepareRemote: () => prepared.future,
        writeRemote: (_) async => commits++,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      prepared.complete();

      expect(await result, CloudWriteResult.stale);
      expect(commits, 0);
    },
  );

  test('bookshelf save path does not write after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final prepared = Completer<void>();
    var writes = 0;

    final result = BookshelfService.saveWithSession(
      _page(),
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

  test('bookshelf delete path does not delete after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final prepared = Completer<void>();
    var deletes = 0;

    final result = BookshelfService.deleteWithSession(
      'page-a',
      sessions: sessions,
      uid: 'uid-a',
      prepare: () => prepared.future,
      delete: () async => deletes++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    prepared.complete();

    expect(await result, CloudWriteResult.stale);
    expect(deletes, 0);
  });

  test('bookshelf GC path does not delete media after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final prepared = Completer<void>();
    var deletes = 0;

    final result = BookshelfService.collectGarbageWithSession(
      sessions: sessions,
      uid: 'uid-a',
      readJournal: () async => null,
      prepare: () => prepared.future,
      delete: () async => deletes++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    prepared.complete();

    expect(await result, CloudWriteResult.stale);
    expect(deletes, 0);
  });

  test('custom-pack GC path does not delete media after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final prepared = Completer<void>();
    var deletes = 0;

    final result = CustomPackService.collectGarbageWithSession(
      sessions: sessions,
      uid: 'uid-a',
      readJournal: () async => null,
      prepare: () => prepared.future,
      delete: () async => deletes++,
    );
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');
    prepared.complete();

    expect(await result, CloudWriteResult.stale);
    expect(deletes, 0);
  });

  test(
    'Gye write path returns typed stale and does not commit after A-to-B',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final prepared = Completer<void>();
      var commits = 0;

      final result = GyeService.writeWithSession(
        sessions: sessions,
        uid: 'uid-a',
        prepare: () => prepared.future,
        write: () async => commits++,
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      prepared.complete();

      expect(await result, CloudWriteResult.stale);
      expect(commits, 0);
    },
  );

  test('Gye service stream path closes immediately after A-to-B', () async {
    final sessions = CloudWriteSessionController()..acquire('uid-a');
    final source = StreamController<int>();
    final values = <int>[];
    final done = Completer<void>();

    GyeService.streamWithSession(
      sessions: sessions,
      uid: 'uid-a',
      source: source.stream,
    ).listen(values.add, onDone: done.complete);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    sessions.acquire('uid-b');

    await done.future.timeout(const Duration(milliseconds: 250));
    expect(values, <int>[1]);
    await source.close();
  });
}

PackProgress _progress() {
  return PackProgress.fresh(packId: 'pack-a', level: 'A1', wordsTotal: 10);
}

BookPage _page() {
  return const BookPage(
    id: 'page-a',
    localThumbnailPath: null,
    extractedText: '',
    note: '',
    words: [],
    grammar: [],
    sentences: [],
    capturedAtIso: '2026-07-30T00:00:00Z',
    customPackId: null,
  );
}
