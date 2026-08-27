import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';

void main() {
  group('StudyLibraryRepository', () {
    test(
      'merges multiple origins and uses deterministic presentation priority',
      () async {
        final key = StudyItemKey(type: StudyLibraryItemType.word, id: ' 사과 ');
        final repository = StudyLibraryRepository(
          likedReader: _LikedReader(<StudyLibrarySourceRecord>[
            _record(key, StudyLibraryOrigin.liked, 'vocab|사과'),
          ]),
          customPackReader: _CustomPackReader(<StudyLibrarySourceRecord>[
            StudyLibrarySourceRecord(
              key: key,
              primaryText: 'Custom 사과',
              secondaryText: 'custom apple',
              sources: <StudyLibrarySource>[
                _source(StudyLibraryOrigin.legacyFlattened, 'pack:0'),
                _source(StudyLibraryOrigin.customPack, 'pack:0'),
              ],
            ),
          ]),
          bookshelfReader: _BookshelfReader(<StudyLibrarySourceRecord>[
            _record(
              key,
              StudyLibraryOrigin.bookshelf,
              'page:0',
              primary: 'Bookshelf 사과',
              secondary: 'bookshelf apple',
            ),
          ]),
          srsReader: _SrsReader(<StudyLibrarySrsRecord>[
            StudyLibrarySrsRecord(key: key, reviewCount: 3, isDue: true),
          ]),
          bookmarkReader: _BookmarkReader(
            records: <StudyLibrarySourceRecord>[
              _record(
                key,
                StudyLibraryOrigin.typedBookmark,
                'unit-1',
                primary: '사과',
                secondary: 'saved apple',
              ),
            ],
          ),
        );

        final snapshot = await repository.load();

        expect(snapshot.entries, hasLength(1));
        final entry = snapshot.entries.single;
        expect(entry.key.id, '사과');
        expect(entry.primaryText, '사과');
        expect(entry.secondaryText, 'saved apple');
        expect(entry.isLiked, isTrue);
        expect(entry.isSaved, isTrue);
        expect(entry.isDue, isTrue);
        expect(entry.reviewCount, 3);
        expect(
          entry.origins,
          containsAll(<StudyLibraryOrigin>{
            StudyLibraryOrigin.liked,
            StudyLibraryOrigin.typedBookmark,
            StudyLibraryOrigin.customPack,
            StudyLibraryOrigin.bookshelf,
            StudyLibraryOrigin.srs,
            StudyLibraryOrigin.legacyFlattened,
          }),
        );
      },
    );

    test('preserves an unresolved like instead of dropping it', () async {
      final key = StudyItemKey(
        type: StudyLibraryItemType.expression,
        id: 'future-kind:item-42',
      );
      final snapshot = await _repository(
        liked: <StudyLibrarySourceRecord>[
          _record(key, StudyLibraryOrigin.liked, 'future-kind|item-42'),
        ],
      ).load();

      final entry = snapshot.entries.single;
      expect(entry.key, key);
      expect(entry.primaryText, key.id);
      expect(entry.isResolved, isFalse);
      expect(entry.isLiked, isTrue);
      expect(entry.isSaved, isFalse);
      expect(entry.isDue, isFalse);
    });

    test('propagates typed-bookmark quarantine health', () async {
      final repository = StudyLibraryRepository(
        likedReader: _LikedReader(const <StudyLibrarySourceRecord>[]),
        customPackReader: _CustomPackReader(const <StudyLibrarySourceRecord>[]),
        bookshelfReader: _BookshelfReader(const <StudyLibrarySourceRecord>[]),
        srsReader: _SrsReader(const <StudyLibrarySrsRecord>[]),
        bookmarkReader: _BookmarkReader(
          health: StudyLibraryBookmarkHealth.corrupt,
        ),
      );

      final snapshot = await repository.load();

      expect(snapshot.entries, isEmpty);
      expect(snapshot.bookmarkHealth, StudyLibraryBookmarkHealth.corrupt);
    });

    test('never promotes a heart-only word into the due queue', () async {
      final key = StudyItemKey(type: StudyLibraryItemType.word, id: '학교');
      final snapshot = await _repository(
        liked: <StudyLibrarySourceRecord>[
          _record(key, StudyLibraryOrigin.liked, 'vocab|학교'),
        ],
        srs: <StudyLibrarySrsRecord>[
          StudyLibrarySrsRecord(key: key, reviewCount: 9, isDue: true),
        ],
      ).load();

      final entry = snapshot.entries.single;
      expect(entry.isLiked, isTrue);
      expect(entry.isSaved, isFalse);
      expect(entry.reviewCount, 9);
      expect(entry.isDue, isFalse);
      expect(snapshot.due, isEmpty);
    });

    test('due contains only saved reviewable words', () async {
      final word = StudyItemKey(type: StudyLibraryItemType.word, id: '책');
      final grammar = StudyItemKey(
        type: StudyLibraryItemType.grammar,
        id: 'g-progressive',
      );
      final srsOnly = StudyItemKey(
        type: StudyLibraryItemType.word,
        id: 'orphan',
      );
      final snapshot = await _repository(
        bookmarks: <StudyLibrarySourceRecord>[
          _record(
            word,
            StudyLibraryOrigin.typedBookmark,
            'word-unit',
            primary: '책',
          ),
          _record(
            grammar,
            StudyLibraryOrigin.typedBookmark,
            'grammar-unit',
            primary: '-고 있다',
          ),
        ],
        srs: <StudyLibrarySrsRecord>[
          StudyLibrarySrsRecord(key: word, reviewCount: 1, isDue: true),
          StudyLibrarySrsRecord(key: grammar, reviewCount: 2, isDue: true),
          StudyLibrarySrsRecord(key: srsOnly, reviewCount: 4, isDue: true),
        ],
      ).load();

      expect(
        snapshot.entries.map((entry) => entry.key),
        isNot(contains(srsOnly)),
      );
      expect(snapshot.due.map((entry) => entry.key), <StudyItemKey>[word]);
      expect(
        snapshot.entries.singleWhere((entry) => entry.key == grammar).isDue,
        isFalse,
      );
    });

    test(
      'typed non-word bookmark suppresses its legacy CustomPack word mirror',
      () async {
        final grammar = StudyItemKey(
          type: StudyLibraryItemType.grammar,
          id: 'g-progressive',
        );
        final mirroredWord = StudyItemKey(
          type: StudyLibraryItemType.word,
          id: '-고 있다',
        );
        final realWord = StudyItemKey(
          type: StudyLibraryItemType.word,
          id: '사과',
        );
        final snapshot = await _repository(
          custom: <StudyLibrarySourceRecord>[
            StudyLibrarySourceRecord(
              key: mirroredWord,
              primaryText: '  -고   있다 ',
              secondaryText: 'progressive',
              sources: <StudyLibrarySource>[
                _source(StudyLibraryOrigin.customPack, 'quick:grammar'),
                _source(StudyLibraryOrigin.legacyFlattened, 'quick:grammar'),
                _source(StudyLibraryOrigin.wordbookMirror, 'quick:grammar'),
              ],
            ),
            StudyLibrarySourceRecord(
              key: realWord,
              primaryText: '사과',
              secondaryText: 'apple',
              sources: <StudyLibrarySource>[
                _source(StudyLibraryOrigin.customPack, 'quick:word'),
                _source(StudyLibraryOrigin.legacyFlattened, 'quick:word'),
                _source(StudyLibraryOrigin.wordbookMirror, 'quick:word'),
              ],
            ),
          ],
          bookmarks: <StudyLibrarySourceRecord>[
            _record(
              grammar,
              StudyLibraryOrigin.typedBookmark,
              'grammar-card',
              primary: '-고 있다',
              secondary: 'progressive',
            ),
          ],
          srs: <StudyLibrarySrsRecord>[
            StudyLibrarySrsRecord(
              key: mirroredWord,
              reviewCount: 4,
              isDue: true,
            ),
          ],
        ).load();

        expect(snapshot.entries.map((entry) => entry.key), <StudyItemKey>[
          realWord,
          grammar,
        ]);
        expect(
          snapshot.entries.where((entry) => entry.key == mirroredWord),
          isEmpty,
        );
        expect(
          snapshot.entries.singleWhere((entry) => entry.key == grammar).isSaved,
          isTrue,
        );
        expect(snapshot.due, isEmpty);
      },
    );

    test(
      'removed typed bookmark suppression hides only its quick wordbook mirror',
      () async {
        final mirroredWord = StudyItemKey(
          type: StudyLibraryItemType.word,
          id: '날씨 좋네요.',
        );
        final snapshot = await _repository(
          custom: <StudyLibrarySourceRecord>[
            StudyLibrarySourceRecord(
              key: mirroredWord,
              primaryText: '날씨 좋네요.',
              sources: <StudyLibrarySource>[
                _source(StudyLibraryOrigin.customPack, 'quick:0'),
                _source(StudyLibraryOrigin.legacyFlattened, 'quick:0'),
                _source(StudyLibraryOrigin.wordbookMirror, 'quick:0'),
              ],
            ),
            StudyLibrarySourceRecord(
              key: mirroredWord,
              primaryText: '날씨 좋네요.',
              sources: <StudyLibrarySource>[
                _source(StudyLibraryOrigin.customPack, 'personal:0'),
                _source(StudyLibraryOrigin.legacyFlattened, 'personal:0'),
              ],
            ),
          ],
          suppressions: <StudyLibraryLegacyMirrorSuppression>[
            StudyLibraryLegacyMirrorSuppression(
              type: StudyLibraryItemType.sentence,
              primaryText: ' 날씨  좋네요. ',
            ),
          ],
        ).load();

        final word = snapshot.entries.single;
        expect(word.key, mirroredWord);
        expect(
          word.sources.map((source) => source.sourceId),
          contains('personal:0'),
        );
        expect(
          word.sources.map((source) => source.sourceId),
          isNot(contains('quick:0')),
        );
      },
    );

    test('ordering and source merge are stable across reader order', () async {
      final wordA = StudyItemKey(type: StudyLibraryItemType.word, id: '가방');
      final wordB = StudyItemKey(type: StudyLibraryItemType.word, id: '나무');
      final sentence = StudyItemKey(
        type: StudyLibraryItemType.sentence,
        id: '학교에 가요.',
      );
      final records = <StudyLibrarySourceRecord>[
        _record(
          sentence,
          StudyLibraryOrigin.bookshelf,
          'page:s',
          primary: sentence.id,
        ),
        _record(
          wordB,
          StudyLibraryOrigin.bookshelf,
          'page:b',
          primary: wordB.id,
        ),
        _record(
          wordA,
          StudyLibraryOrigin.bookshelf,
          'page:a',
          primary: wordA.id,
        ),
      ];
      final first = await _repository(bookshelf: records).load();
      final second = await _repository(
        bookshelf: records.reversed.toList(),
      ).load();

      expect(
        first.entries.map((entry) => entry.key.encoded),
        second.entries.map((entry) => entry.key.encoded),
      );
      expect(first.entries.map((entry) => entry.key), <StudyItemKey>[
        wordA,
        wordB,
        sentence,
      ]);
      expect(
        () => first.entries.add(first.entries.first),
        throwsUnsupportedError,
      );
      expect(() => first.entries.first.sources.clear(), throwsUnsupportedError);
    });

    test(
      'loads each injected source once and never mutates reader lists',
      () async {
        final key = StudyItemKey(type: StudyLibraryItemType.word, id: '물');
        final likedItems = <StudyLibrarySourceRecord>[
          _record(key, StudyLibraryOrigin.liked, 'vocab|물'),
        ];
        final customItems = <StudyLibrarySourceRecord>[
          _record(key, StudyLibraryOrigin.customPack, 'pack:0', primary: '물'),
        ];
        final liked = _LikedReader(likedItems);
        final custom = _CustomPackReader(customItems);
        final bookshelf = _BookshelfReader(const <StudyLibrarySourceRecord>[]);
        final srs = _SrsReader(const <StudyLibrarySrsRecord>[]);
        final bookmarks = _BookmarkReader();

        await StudyLibraryRepository(
          likedReader: liked,
          customPackReader: custom,
          bookshelfReader: bookshelf,
          srsReader: srs,
          bookmarkReader: bookmarks,
        ).load();

        expect(liked.readCount, 1);
        expect(custom.readCount, 1);
        expect(bookshelf.readCount, 1);
        expect(srs.readCount, 1);
        expect(bookmarks.readCount, 1);
        expect(likedItems, hasLength(1));
        expect(customItems, hasLength(1));
        expect(likedItems.single.sources.single.sourceId, 'vocab|물');
        expect(customItems.single.sources.single.sourceId, 'pack:0');
      },
    );
  });
}

StudyLibraryRepository _repository({
  List<StudyLibrarySourceRecord> liked = const <StudyLibrarySourceRecord>[],
  List<StudyLibrarySourceRecord> custom = const <StudyLibrarySourceRecord>[],
  List<StudyLibrarySourceRecord> bookshelf = const <StudyLibrarySourceRecord>[],
  List<StudyLibrarySourceRecord> bookmarks = const <StudyLibrarySourceRecord>[],
  List<StudyLibraryLegacyMirrorSuppression> suppressions =
      const <StudyLibraryLegacyMirrorSuppression>[],
  List<StudyLibrarySrsRecord> srs = const <StudyLibrarySrsRecord>[],
}) => StudyLibraryRepository(
  likedReader: _LikedReader(liked),
  customPackReader: _CustomPackReader(custom),
  bookshelfReader: _BookshelfReader(bookshelf),
  srsReader: _SrsReader(srs),
  bookmarkReader: _BookmarkReader(
    records: bookmarks,
    legacyMirrorSuppressions: suppressions,
  ),
);

StudyLibrarySourceRecord _record(
  StudyItemKey key,
  StudyLibraryOrigin origin,
  String sourceId, {
  String? primary,
  String? secondary,
}) => StudyLibrarySourceRecord(
  key: key,
  primaryText: primary,
  secondaryText: secondary,
  sources: <StudyLibrarySource>[_source(origin, sourceId)],
);

StudyLibrarySource _source(StudyLibraryOrigin origin, String sourceId) =>
    StudyLibrarySource(origin: origin, sourceId: sourceId);

final class _LikedReader implements StudyLibraryLikedReader {
  _LikedReader(this.items);
  final List<StudyLibrarySourceRecord> items;
  int readCount = 0;

  @override
  Future<List<StudyLibrarySourceRecord>> readLiked() async {
    readCount++;
    return items;
  }
}

final class _CustomPackReader implements StudyLibraryCustomPackReader {
  _CustomPackReader(this.items);
  final List<StudyLibrarySourceRecord> items;
  int readCount = 0;

  @override
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems() async {
    readCount++;
    return items;
  }
}

final class _BookshelfReader implements StudyLibraryBookshelfReader {
  _BookshelfReader(this.items);
  final List<StudyLibrarySourceRecord> items;
  int readCount = 0;

  @override
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems() async {
    readCount++;
    return items;
  }
}

final class _SrsReader implements StudyLibrarySrsReader {
  _SrsReader(this.items);
  final List<StudyLibrarySrsRecord> items;
  int readCount = 0;

  @override
  Future<List<StudyLibrarySrsRecord>> readSrsRecords() async {
    readCount++;
    return items;
  }
}

final class _BookmarkReader implements StudyLibraryBookmarkReader {
  _BookmarkReader({
    this.records = const <StudyLibrarySourceRecord>[],
    this.health = StudyLibraryBookmarkHealth.healthy,
    this.legacyMirrorSuppressions =
        const <StudyLibraryLegacyMirrorSuppression>[],
  });

  final List<StudyLibrarySourceRecord> records;
  final StudyLibraryBookmarkHealth health;
  final List<StudyLibraryLegacyMirrorSuppression> legacyMirrorSuppressions;
  int readCount = 0;

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async {
    readCount++;
    return StudyLibraryBookmarkSourceSnapshot(
      records: records,
      health: health,
      legacyMirrorSuppressions: legacyMirrorSuppressions,
    );
  }
}
