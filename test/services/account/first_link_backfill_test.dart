import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill_journal.dart';

void main() {
  group('FirstDurableLinkBackfill', () {
    test(
      'persists a failed first bookshelf upload and retries it after restart',
      () async {
        final store = _MemoryJournalStore();
        final sessions = CloudWriteSessionController();
        final initialSession = sessions.acquire('source');
        var liveUid = 'source';
        final events = <String>[];
        var bookshelfAttempts = 0;
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => liveUid,
          uploadBookshelf: (session, {required operationId}) async {
            events.add('bookshelf:$operationId:${session.uid}');
            bookshelfAttempts += 1;
            return bookshelfAttempts == 1
                ? CloudWriteResult.blocked
                : CloudWriteResult.completed;
          },
          uploadPackProgress: (session, {required operationId}) async {
            events.add('packs:$operationId:${session.uid}');
            return CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.begin(session: initialSession, uid: 'source'),
          CloudWriteResult.blocked,
        );
        expect(
          store.value,
          FirstDurableLinkBackfillJournal.pending(
            uid: 'source',
            token: 'receipt-token',
          ),
        );
        expect(events, <String>['bookshelf:first-link:receipt-token:source']);

        // A process restart never reuses the old session epoch. It obtains a
        // fresh ready snapshot for the same durable account instead.
        sessions.acquire('source');

        expect(
          await backfill.resume(expectedUid: 'source'),
          CloudWriteResult.completed,
        );
        expect(events, <String>[
          'bookshelf:first-link:receipt-token:source',
          'bookshelf:first-link:receipt-token:source',
          'packs:first-link:receipt-token:source',
        ]);
        expect(await store.read(), isNull);
        expect(liveUid, 'source');
      },
    );

    test(
      'records the bookshelf receipt before retrying only failed packs',
      () async {
        final store = _MemoryJournalStore();
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        var packAttempts = 0;
        final events = <String>[];
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => 'source',
          uploadBookshelf: (source, {required operationId}) async {
            events.add('bookshelf:$operationId');
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (source, {required operationId}) async {
            events.add('packs:$operationId');
            packAttempts += 1;
            return packAttempts == 1
                ? CloudWriteResult.blocked
                : CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.begin(session: session, uid: 'source'),
          CloudWriteResult.blocked,
        );
        expect(
          await store.read(),
          FirstDurableLinkBackfillJournal(
            uid: 'source',
            token: 'receipt-token',
            bookshelfPending: false,
            packProgressPending: true,
          ),
        );

        final freshSession = sessions.acquire('source');
        expect(
          await backfill.begin(session: freshSession, uid: 'source'),
          CloudWriteResult.completed,
        );
        expect(events, <String>[
          'bookshelf:first-link:receipt-token',
          'packs:first-link:receipt-token',
          'packs:first-link:receipt-token',
        ]);
        expect(await store.read(), isNull);
      },
    );

    test('foreign receipt stays inert and never redirects an upload', () async {
      final foreign = FirstDurableLinkBackfillJournal.pending(
        uid: 'other-durable-user',
        token: 'foreign-token',
      );
      final store = _MemoryJournalStore(value: foreign);
      final sessions = CloudWriteSessionController()..acquire('source');
      final events = <String>[];
      final backfill = _backfill(
        sessions: sessions,
        store: store,
        currentUid: () => 'source',
        uploadBookshelf: (source, {required operationId}) async {
          events.add('bookshelf:${source.uid}');
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (source, {required operationId}) async {
          events.add('packs:${source.uid}');
          return CloudWriteResult.completed;
        },
      );

      expect(
        await backfill.resume(expectedUid: 'source'),
        CloudWriteResult.blocked,
      );
      expect(events, isEmpty);
      expect(await store.read(), foreign);
    });

    test(
      'blocked account transition keeps the receipt without uploading',
      () async {
        final pending = FirstDurableLinkBackfillJournal.pending(
          uid: 'source',
          token: 'blocked-token',
        );
        final store = _MemoryJournalStore(value: pending);
        final sessions = CloudWriteSessionController()..acquire('source');
        final events = <String>[];
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => 'source',
          hasBlockingAccountJournal: () async => true,
          uploadBookshelf: (source, {required operationId}) async {
            events.add('bookshelf');
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (source, {required operationId}) async {
            events.add('packs');
            return CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.resume(expectedUid: 'source'),
          CloudWriteResult.blocked,
        );
        expect(events, isEmpty);
        expect(await store.read(), pending);
      },
    );

    test('stale session keeps an existing receipt without uploading', () async {
      final pending = FirstDurableLinkBackfillJournal.pending(
        uid: 'source',
        token: 'stale-token',
      );
      final store = _MemoryJournalStore(value: pending);
      final sessions = CloudWriteSessionController();
      final staleSession = sessions.acquire('source');
      sessions.acquire('source');
      final events = <String>[];
      final backfill = _backfill(
        sessions: sessions,
        store: store,
        currentUid: () => 'source',
        uploadBookshelf: (source, {required operationId}) async {
          events.add('bookshelf');
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (source, {required operationId}) async {
          events.add('packs');
          return CloudWriteResult.completed;
        },
      );

      expect(
        await backfill.begin(session: staleSession, uid: 'source'),
        CloudWriteResult.stale,
      );
      expect(events, isEmpty);
      expect(await store.read(), pending);
    });

    test('a transition appearing after bookshelf blocks pack upload', () async {
      final store = _MemoryJournalStore();
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      var blockingJournalExists = false;
      final events = <String>[];
      final backfill = _backfill(
        sessions: sessions,
        store: store,
        currentUid: () => 'source',
        hasBlockingAccountJournal: () async => blockingJournalExists,
        uploadBookshelf: (source, {required operationId}) async {
          events.add('bookshelf');
          blockingJournalExists = true;
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (source, {required operationId}) async {
          events.add('packs');
          return CloudWriteResult.completed;
        },
      );

      expect(
        await backfill.begin(session: session, uid: 'source'),
        CloudWriteResult.blocked,
      );
      expect(events, <String>['bookshelf']);
      expect(
        await store.read(),
        FirstDurableLinkBackfillJournal.pending(
          uid: 'source',
          token: 'receipt-token',
        ),
      );
    });

    test(
      'a stale source after upload keeps the pending receipt and skips packs',
      () async {
        final store = _MemoryJournalStore();
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        var liveUid = 'source';
        final events = <String>[];
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => liveUid,
          uploadBookshelf: (source, {required operationId}) async {
            events.add('bookshelf');
            liveUid = 'replacement';
            sessions.acquire(liveUid);
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (source, {required operationId}) async {
            events.add('packs');
            return CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.begin(session: session, uid: 'source'),
          CloudWriteResult.stale,
        );
        expect(events, <String>['bookshelf']);
        expect(
          await store.read(),
          FirstDurableLinkBackfillJournal.pending(
            uid: 'source',
            token: 'receipt-token',
          ),
        );
      },
    );

    test(
      'receipt failure after remote bookshelf success retries with the same operation ID',
      () async {
        final store = _MemoryJournalStore()..rejectNextReplacement = true;
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        final operationIds = <String>[];
        var packs = 0;
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => 'source',
          uploadBookshelf: (source, {required operationId}) async {
            operationIds.add(operationId);
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (source, {required operationId}) async {
            packs += 1;
            return CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.begin(session: session, uid: 'source'),
          CloudWriteResult.blocked,
        );
        expect(
          await store.read(),
          FirstDurableLinkBackfillJournal.pending(
            uid: 'source',
            token: 'receipt-token',
          ),
        );
        expect(packs, 0);

        sessions.acquire('source');
        expect(
          await backfill.resume(expectedUid: 'source'),
          CloudWriteResult.completed,
        );
        expect(operationIds, <String>[
          'first-link:receipt-token',
          'first-link:receipt-token',
        ]);
        expect(packs, 1);
        expect(await store.read(), isNull);
      },
    );

    test(
      'journal persistence failure blocks before any remote upload',
      () async {
        final store = _MemoryJournalStore()..throwOnCreate = true;
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        final events = <String>[];
        final backfill = _backfill(
          sessions: sessions,
          store: store,
          currentUid: () => 'source',
          uploadBookshelf: (source, {required operationId}) async {
            events.add('bookshelf');
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (source, {required operationId}) async {
            events.add('packs');
            return CloudWriteResult.completed;
          },
        );

        expect(
          await backfill.begin(session: session, uid: 'source'),
          CloudWriteResult.blocked,
        );
        expect(events, isEmpty);
        expect(await store.read(), isNull);
      },
    );

    test('activation and startup resume share one in-flight upload', () async {
      final store = _MemoryJournalStore();
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      final bookshelfGate = Completer<CloudWriteResult>();
      var bookshelfCalls = 0;
      var packCalls = 0;
      final backfill = _backfill(
        sessions: sessions,
        store: store,
        currentUid: () => 'source',
        uploadBookshelf: (source, {required operationId}) {
          bookshelfCalls += 1;
          return bookshelfGate.future;
        },
        uploadPackProgress: (source, {required operationId}) async {
          packCalls += 1;
          return CloudWriteResult.completed;
        },
      );

      final activation = backfill.begin(session: session, uid: 'source');
      await Future<void>.delayed(Duration.zero);
      final resume = backfill.resume(expectedUid: 'source');
      await Future<void>.delayed(Duration.zero);

      expect(bookshelfCalls, 1);
      bookshelfGate.complete(CloudWriteResult.completed);
      expect(await activation, CloudWriteResult.completed);
      expect(await resume, CloudWriteResult.completed);
      expect(bookshelfCalls, 1);
      expect(packCalls, 1);
      expect(await store.read(), isNull);
    });
  });
}

FirstDurableLinkBackfill _backfill({
  required CloudWriteSessionController sessions,
  required FirstDurableLinkBackfillJournalStore store,
  required String? Function() currentUid,
  Future<bool> Function()? hasBlockingAccountJournal,
  required FirstDurableLinkUploader uploadBookshelf,
  required FirstDurableLinkUploader uploadPackProgress,
}) {
  return FirstDurableLinkBackfill(
    sessions: sessions,
    currentUid: currentUid,
    hasBlockingAccountJournal: hasBlockingAccountJournal ?? () async => false,
    journalStore: store,
    createToken: () => 'receipt-token',
    uploadBookshelf: uploadBookshelf,
    uploadPackProgress: uploadPackProgress,
  );
}

class _MemoryJournalStore implements FirstDurableLinkBackfillJournalStore {
  _MemoryJournalStore({this.value});

  FirstDurableLinkBackfillJournal? value;
  bool throwOnCreate = false;
  bool rejectNextReplacement = false;

  @override
  Future<bool> clearIfCurrent(FirstDurableLinkBackfillJournal expected) async {
    if (value != expected) return false;
    value = null;
    return true;
  }

  @override
  Future<bool> createIfAbsent(FirstDurableLinkBackfillJournal journal) async {
    if (throwOnCreate) {
      throw StateError('preference write failed');
    }
    if (value != null) return false;
    value = journal;
    return true;
  }

  @override
  Future<FirstDurableLinkBackfillJournal?> read() async => value;

  @override
  Future<bool> replaceIfCurrent({
    required FirstDurableLinkBackfillJournal expected,
    required FirstDurableLinkBackfillJournal next,
  }) async {
    if (value != expected) return false;
    if (rejectNextReplacement) {
      rejectNextReplacement = false;
      return false;
    }
    value = next;
    return true;
  }
}
