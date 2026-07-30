import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill_journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'shared preferences receipt uses compare-and-clear by exact token',
    () async {
      const store = SharedPreferencesFirstDurableLinkBackfillJournalStore();
      final pending = FirstDurableLinkBackfillJournal.pending(
        uid: 'source',
        token: 'token-a',
      );
      final booksDone = FirstDurableLinkBackfillJournal(
        uid: 'source',
        token: 'token-a',
        bookshelfPending: false,
        packProgressPending: true,
      );
      final replacement = FirstDurableLinkBackfillJournal.pending(
        uid: 'source',
        token: 'token-b',
      );

      expect(await store.createIfAbsent(pending), isTrue);
      expect(await store.createIfAbsent(replacement), isFalse);
      expect(await store.read(), pending);
      expect(
        await store.replaceIfCurrent(expected: pending, next: booksDone),
        isTrue,
      );
      expect(await store.clearIfCurrent(pending), isFalse);
      expect(await store.clearIfCurrent(booksDone), isTrue);
      expect(await store.read(), isNull);
    },
  );

  test('receipt rejects malformed durable data', () {
    expect(
      () => FirstDurableLinkBackfillJournal.fromJson(const <String, Object>{
        'version': 1,
        'uid': 'source',
        'token': 'token-a',
        'bookshelfPending': 'not-a-bool',
        'packProgressPending': true,
      }),
      throwsFormatException,
    );
  });
}
