import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';

void main() {
  group('TypedStudyBookmarkStore', () {
    test('preserves language provenance and legacy text without guessing', () {
      final raw = <String, Object>{
        'type': 'word',
        'id': 'legacy',
        'primaryText': '옛말',
        'secondaryText': 'Alte Bedeutung',
      };
      for (final language in ['de', 'en']) {
        final bookmark = TypedStudyBookmark.fromJson({
          ...raw,
          'secondaryLanguage': language,
        });
        expect(bookmark.secondaryLanguage, language);
        expect(TypedStudyBookmark.fromJson(bookmark.toJson()), bookmark);
      }
      final legacy = TypedStudyBookmark.fromJson(raw);
      expect(legacy.secondaryLanguage, isNull);
      expect(
        TypedStudyBookmark.fromJson(legacy.toJson()).secondaryText,
        'Alte Bedeutung',
      );
      expect(
        () => TypedStudyBookmark.fromJson({...raw, 'secondaryLanguage': 7}),
        throwsFormatException,
      );
    });

    test('round-trips every item type without flattening', () async {
      final storage = _MemoryRawStorage();
      final store = storage.store;

      for (final type in StudyLibraryItemType.values.reversed) {
        final result = await store.upsert(
          TypedStudyBookmark(
            key: StudyItemKey(type: type, id: '${type.name}-id'),
            primaryText: '${type.name} primary',
            secondaryText: '${type.name} secondary',
            sourceUnitId: 'unit-${type.name}',
          ),
        );
        expect(result, TypedStudyBookmarkMutationResult.inserted);
      }

      final read = store.read();
      expect(read.health, StudyLibraryBookmarkHealth.healthy);
      expect(
        read.bookmarks.map((bookmark) => bookmark.key.type).toSet(),
        StudyLibraryItemType.values.toSet(),
      );
      expect(
        read.bookmarks.map((bookmark) => bookmark.key.encoded),
        orderedEquals(
          StudyLibraryItemType.values.map(
            (type) => '${type.name}|${type.name}-id',
          ),
        ),
      );

      final payload = jsonDecode(storage.raw) as Map<String, dynamic>;
      expect(payload['version'], TypedStudyBookmarkStore.schemaVersion);
      final items = payload['items'] as List<dynamic>;
      expect(items, hasLength(StudyLibraryItemType.values.length));
      expect(
        items.map((item) => (item as Map<String, dynamic>)['type']),
        orderedEquals(StudyLibraryItemType.values.map((type) => type.name)),
      );
    });

    test(
      'upsert and remove are idempotent and skip redundant writes',
      () async {
        final storage = _MemoryRawStorage();
        final store = storage.store;
        final key = StudyItemKey(
          type: StudyLibraryItemType.grammar,
          id: 'g-progressive',
        );
        final bookmark = TypedStudyBookmark(
          key: key,
          primaryText: '-고 있다',
          secondaryText: 'progressive',
        );

        expect(
          await store.upsert(bookmark),
          TypedStudyBookmarkMutationResult.inserted,
        );
        expect(storage.writeCount, 1);
        expect(
          await store.upsert(bookmark),
          TypedStudyBookmarkMutationResult.unchanged,
        );
        expect(storage.writeCount, 1);

        expect(
          await store.upsert(
            TypedStudyBookmark(
              key: key,
              primaryText: '-고 있어요',
              secondaryText: 'progressive',
            ),
          ),
          TypedStudyBookmarkMutationResult.updated,
        );
        expect(storage.writeCount, 2);
        expect(
          await store.remove(key),
          TypedStudyBookmarkMutationResult.removed,
        );
        expect(storage.writeCount, 3);
        expect(
          await store.remove(key),
          TypedStudyBookmarkMutationResult.absent,
        );
        expect(storage.writeCount, 3);
        expect(store.read().bookmarks, isEmpty);
        expect(
          store.read().legacyMirrorSuppressions,
          <StudyLibraryLegacyMirrorSuppression>[
            StudyLibraryLegacyMirrorSuppression(
              type: StudyLibraryItemType.grammar,
              primaryText: '-고 있어요',
            ),
          ],
        );
      },
    );

    test(
      'non-word removal durably hides its mirror and re-save clears it',
      () async {
        final storage = _MemoryRawStorage();
        final store = storage.store;
        final sentence = TypedStudyBookmark(
          key: StudyItemKey(
            type: StudyLibraryItemType.sentence,
            id: 'weather-line',
          ),
          primaryText: '  날씨   좋네요. ',
          secondaryText: 'Nice weather.',
        );

        await store.upsert(sentence);
        await store.remove(sentence.key);

        final removed = store.read();
        expect(removed.bookmarks, isEmpty);
        expect(removed.legacyMirrorSuppressions, hasLength(1));
        expect(removed.legacyMirrorSuppressions.single.primaryText, '날씨 좋네요.');
        final payload = jsonDecode(storage.raw) as Map<String, dynamic>;
        expect(payload['hiddenLegacyMirrors'], hasLength(1));

        expect(
          await store.upsert(sentence),
          TypedStudyBookmarkMutationResult.inserted,
        );
        expect(store.read().legacyMirrorSuppressions, isEmpty);
      },
    );

    test('word removal never creates a non-word mirror suppression', () async {
      final storage = _MemoryRawStorage();
      final store = storage.store;
      final word = _wordBookmark('학교');

      await store.upsert(word);
      await store.remove(word.key);

      expect(store.read().bookmarks, isEmpty);
      expect(store.read().legacyMirrorSuppressions, isEmpty);
    });

    test('corrupt payload fails closed and signals quarantine', () async {
      final storage = _MemoryRawStorage(raw: '{not-json');
      final original = storage.raw;
      final read = storage.store.read();

      expect(read.health, StudyLibraryBookmarkHealth.corrupt);
      expect(read.needsQuarantine, isTrue);
      expect(read.bookmarks, isEmpty);
      expect(
        await storage.store.upsert(_wordBookmark('물')),
        TypedStudyBookmarkMutationResult.blockedCorrupt,
      );
      expect(
        await storage.store.remove(
          StudyItemKey(type: StudyLibraryItemType.word, id: '물'),
        ),
        TypedStudyBookmarkMutationResult.blockedCorrupt,
      );
      expect(storage.raw, original);
      expect(storage.writeCount, 0);
    });

    test('future schema fails closed without overwriting newer data', () async {
      final storage = _MemoryRawStorage(
        raw: jsonEncode(<String, Object>{
          'version': TypedStudyBookmarkStore.schemaVersion + 1,
          'items': <Object>[],
          'futureField': true,
        }),
      );
      final original = storage.raw;
      final read = storage.store.read();

      expect(read.health, StudyLibraryBookmarkHealth.futureVersion);
      expect(read.sourceVersion, TypedStudyBookmarkStore.schemaVersion + 1);
      expect(read.needsQuarantine, isTrue);
      expect(
        await storage.store.upsert(_wordBookmark('집')),
        TypedStudyBookmarkMutationResult.blockedFutureVersion,
      );
      expect(storage.raw, original);
      expect(storage.writeCount, 0);
    });

    test('unknown types and duplicate keys reject the whole payload', () {
      final unknown = TypedStudyBookmarkStore.decode(
        jsonEncode(<String, Object>{
          'version': 1,
          'items': <Object>[
            <String, Object>{
              'type': 'quiz',
              'id': 'q1',
              'primaryText': 'question',
            },
          ],
        }),
      );
      final duplicate = TypedStudyBookmarkStore.decode(
        jsonEncode(<String, Object>{
          'version': 1,
          'items': <Object>[
            <String, Object>{'type': 'word', 'id': '물', 'primaryText': '물'},
            <String, Object>{'type': 'word', 'id': '물', 'primaryText': 'water'},
          ],
        }),
      );

      expect(unknown.health, StudyLibraryBookmarkHealth.corrupt);
      expect(unknown.bookmarks, isEmpty);
      expect(duplicate.health, StudyLibraryBookmarkHealth.corrupt);
      expect(duplicate.bookmarks, isEmpty);
    });

    test('invalid and duplicate mirror suppressions fail closed', () {
      final wordSuppression = TypedStudyBookmarkStore.decode(
        jsonEncode(<String, Object>{
          'version': 1,
          'items': <Object>[],
          'hiddenLegacyMirrors': <Object>[
            <String, Object>{'type': 'word', 'primaryText': '학교'},
          ],
        }),
      );
      final duplicateSuppression = TypedStudyBookmarkStore.decode(
        jsonEncode(<String, Object>{
          'version': 1,
          'items': <Object>[],
          'hiddenLegacyMirrors': <Object>[
            <String, Object>{'type': 'grammar', 'primaryText': '-고 있다'},
            <String, Object>{'type': 'grammar', 'primaryText': ' -고  있다 '},
          ],
        }),
      );

      expect(wordSuppression.health, StudyLibraryBookmarkHealth.corrupt);
      expect(duplicateSuppression.health, StudyLibraryBookmarkHealth.corrupt);
    });

    test('serializes concurrent mutations without losing bookmarks', () async {
      final storage = _MemoryRawStorage(
        writeDelay: const Duration(milliseconds: 2),
      );
      final store = storage.store;

      await Future.wait(<Future<TypedStudyBookmarkMutationResult>>[
        store.upsert(_wordBookmark('가방')),
        store.upsert(_wordBookmark('나무')),
        store.upsert(_wordBookmark('다리')),
      ]);

      expect(
        store.read().bookmarks.map((bookmark) => bookmark.key.id),
        <String>['가방', '나무', '다리'],
      );
      expect(storage.writeCount, 3);
    });
  });
}

TypedStudyBookmark _wordBookmark(String korean) => TypedStudyBookmark(
  key: StudyItemKey(type: StudyLibraryItemType.word, id: korean),
  primaryText: korean,
);

final class _MemoryRawStorage {
  _MemoryRawStorage({this.raw = '', this.writeDelay = Duration.zero});

  String raw;
  final Duration writeDelay;
  int writeCount = 0;

  late final TypedStudyBookmarkStore store = TypedStudyBookmarkStore(
    readRaw: () => raw,
    writeRaw: (value) async {
      if (writeDelay > Duration.zero) {
        await Future<void>.delayed(writeDelay);
      }
      raw = value;
      writeCount++;
    },
  );
}
