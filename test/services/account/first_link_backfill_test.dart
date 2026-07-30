import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill.dart';

void main() {
  group('FirstDurableLinkBackfill', () {
    test(
      'same-UID durable link uploads local bookshelf before packs',
      () async {
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        var liveUid = 'source';
        final events = <String>[];
        final backfill = FirstDurableLinkBackfill(
          sessions: sessions,
          currentUid: () => liveUid,
          hasReplacementJournal: () async => false,
          uploadBookshelf: (expected) async {
            events.add('bookshelf:${expected.uid}');
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (expected) async {
            events.add('packs:${expected.uid}');
            return CloudWriteResult.completed;
          },
        );

        final result = await backfill.run(session: session, uid: 'source');

        expect(result, CloudWriteResult.completed);
        expect(events, ['bookshelf:source', 'packs:source']);
        expect(liveUid, 'source');
      },
    );

    test('replacement journal blocks every first-link uploader', () async {
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      final events = <String>[];
      final backfill = FirstDurableLinkBackfill(
        sessions: sessions,
        currentUid: () => 'source',
        hasReplacementJournal: () async => true,
        uploadBookshelf: (expected) async {
          events.add('bookshelf:${expected.uid}');
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (expected) async {
          events.add('packs:${expected.uid}');
          return CloudWriteResult.completed;
        },
      );

      final result = await backfill.run(session: session, uid: 'source');

      expect(result, CloudWriteResult.blocked);
      expect(events, isEmpty);
    });

    test(
      'a replacement appearing after bookshelf never uploads pack progress',
      () async {
        final sessions = CloudWriteSessionController();
        final session = sessions.acquire('source');
        var replacementJournalExists = false;
        final events = <String>[];
        final backfill = FirstDurableLinkBackfill(
          sessions: sessions,
          currentUid: () => 'source',
          hasReplacementJournal: () async => replacementJournalExists,
          uploadBookshelf: (expected) async {
            events.add('bookshelf:${expected.uid}');
            replacementJournalExists = true;
            return CloudWriteResult.completed;
          },
          uploadPackProgress: (expected) async {
            events.add('packs:${expected.uid}');
            return CloudWriteResult.completed;
          },
        );

        final result = await backfill.run(session: session, uid: 'source');

        expect(result, CloudWriteResult.blocked);
        expect(events, ['bookshelf:source']);
      },
    );

    test('a stale source session never starts a first-link upload', () async {
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('source');
      var liveUid = 'source';
      final events = <String>[];
      final backfill = FirstDurableLinkBackfill(
        sessions: sessions,
        currentUid: () => liveUid,
        hasReplacementJournal: () async {
          liveUid = 'replacement';
          sessions.acquire(liveUid);
          return false;
        },
        uploadBookshelf: (expected) async {
          events.add('bookshelf:${expected.uid}');
          return CloudWriteResult.completed;
        },
        uploadPackProgress: (expected) async {
          events.add('packs:${expected.uid}');
          return CloudWriteResult.completed;
        },
      );

      final result = await backfill.run(session: session, uid: 'source');

      expect(result, CloudWriteResult.stale);
      expect(events, isEmpty);
    });
  });
}
