import '../../models/book_page.dart';
import '../../models/liked_content.dart';
import '../../services/bookshelf_service.dart';
import '../../services/custom_pack_service.dart';
import '../../services/liked_content_service.dart';
import '../../services/scenario_loader.dart';
import '../../services/smalltalk_loader.dart';
import '../../services/storage_service.dart';
import 'study_library_models.dart';
import 'study_library_repository.dart';
import 'typed_study_bookmark_store.dart';

StudyLibraryRepository createProductionStudyLibraryRepository({
  TypedStudyBookmarkStore? bookmarkStore,
}) => StudyLibraryRepository(
  likedReader: const ProductionStudyLibraryLikedReader(),
  customPackReader: const ProductionStudyLibraryCustomPackReader(),
  bookshelfReader: const ProductionStudyLibraryBookshelfReader(),
  srsReader: const ProductionStudyLibrarySrsReader(),
  bookmarkReader: ProductionStudyLibraryBookmarkReader(
    bookmarkStore ?? TypedStudyBookmarkStore.production(),
  ),
);

final class ProductionStudyLibraryLikedReader
    implements StudyLibraryLikedReader {
  const ProductionStudyLibraryLikedReader();

  @override
  Future<List<StudyLibrarySourceRecord>> readLiked() async {
    final likedItems = LikedContentService.all();
    final smalltalkById = <String, String>{};
    if (likedItems.any((item) => item.kind == LikedContentService.smalltalk)) {
      await SmalltalkLoader.load();
      for (final phrase in SmalltalkLoader.phrases) {
        smalltalkById[phrase.id] = phrase.ko;
      }
    }
    final listeningById = <String, String>{};
    if (likedItems.any((item) => item.kind == LikedContentService.listening)) {
      for (final scenario in await ScenarioLoader.load()) {
        for (var index = 0; index < scenario.dialog.length; index++) {
          listeningById['${scenario.id}:$index'] = scenario.dialog[index].ko;
        }
      }
    }
    return <StudyLibrarySourceRecord>[
      for (final liked in likedItems)
        _likedRecord(
          liked,
          smalltalkById: smalltalkById,
          listeningById: listeningById,
        ),
    ];
  }

  static StudyLibrarySourceRecord _likedRecord(
    LikedContent liked, {
    required Map<String, String> smalltalkById,
    required Map<String, String> listeningById,
  }) {
    final type = switch (liked.kind) {
      LikedContentService.vocab => StudyLibraryItemType.word,
      LikedContentService.grammar => StudyLibraryItemType.grammar,
      LikedContentService.hangul => StudyLibraryItemType.hangul,
      LikedContentService.listening ||
      LikedContentService.smalltalk => StudyLibraryItemType.sentence,
      _ => StudyLibraryItemType.expression,
    };
    final id = switch (liked.kind) {
      LikedContentService.vocab ||
      LikedContentService.grammar ||
      LikedContentService.hangul ||
      LikedContentService.listening ||
      LikedContentService.smalltalk => liked.id,
      _ => '${liked.kind}:${liked.id}',
    };
    final primaryText = switch (liked.kind) {
      // These callers persist the learner-facing Korean text itself as id.
      LikedContentService.vocab ||
      LikedContentService.grammar ||
      LikedContentService.hangul => liked.id,
      LikedContentService.smalltalk => smalltalkById[liked.id],
      LikedContentService.listening => listeningById[liked.id],
      _ => null,
    };
    return StudyLibrarySourceRecord(
      key: StudyItemKey(type: type, id: id),
      primaryText: primaryText,
      sources: <StudyLibrarySource>[
        StudyLibrarySource(
          origin: StudyLibraryOrigin.liked,
          sourceId: liked.key,
        ),
      ],
    );
  }
}

final class ProductionStudyLibraryCustomPackReader
    implements StudyLibraryCustomPackReader {
  const ProductionStudyLibraryCustomPackReader();

  @override
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems() async {
    final records = <StudyLibrarySourceRecord>[];
    for (final pack in CustomPackService.getAll()) {
      for (var index = 0; index < pack.words.length; index++) {
        final word = pack.words[index];
        final sourceId = '${pack.id}:word:$index';
        records.add(
          StudyLibrarySourceRecord(
            // Legacy CustomPack storage has no trustworthy item-type field.
            // Even grammar-looking text remains a word/legacyFlattened row.
            key: StudyItemKey(type: StudyLibraryItemType.word, id: word.korean),
            primaryText: word.korean,
            secondaryText: word.translationFor(word.translationLanguage),
            sources: <StudyLibrarySource>[
              StudyLibrarySource(
                origin: StudyLibraryOrigin.customPack,
                sourceId: sourceId,
              ),
              StudyLibrarySource(
                origin: StudyLibraryOrigin.legacyFlattened,
                sourceId: sourceId,
              ),
              if (pack.id == CustomPackService.quickPackId)
                StudyLibrarySource(
                  origin: StudyLibraryOrigin.wordbookMirror,
                  sourceId: sourceId,
                ),
            ],
          ),
        );
      }
    }
    return records;
  }
}

final class ProductionStudyLibraryBookshelfReader
    implements StudyLibraryBookshelfReader {
  const ProductionStudyLibraryBookshelfReader();

  @override
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems() async {
    final records = <StudyLibrarySourceRecord>[];
    for (final page in BookshelfService.getAllLocal()) {
      _addWords(records, page);
      _addGrammar(records, page);
      _addSentences(records, page);
      _addExpressions(records, page);
    }
    return records;
  }

  static void _addWords(List<StudyLibrarySourceRecord> records, BookPage page) {
    for (var index = 0; index < page.words.length; index++) {
      final word = page.words[index];
      records.add(
        StudyLibrarySourceRecord(
          key: StudyItemKey(type: StudyLibraryItemType.word, id: word.korean),
          primaryText: word.korean,
          secondaryText: word.translationFor(page.analysisLanguage),
          sources: <StudyLibrarySource>[
            StudyLibrarySource(
              origin: StudyLibraryOrigin.bookshelf,
              sourceId: '${page.id}:word:$index',
            ),
          ],
        ),
      );
    }
  }

  static void _addGrammar(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
  ) {
    for (var index = 0; index < page.grammar.length; index++) {
      final grammar = page.grammar[index];
      final id = grammar.patternId.trim().isNotEmpty
          ? grammar.patternId
          : grammar.matchedText;
      records.add(
        StudyLibrarySourceRecord(
          key: StudyItemKey(type: StudyLibraryItemType.grammar, id: id),
          primaryText: grammar.matchedText.trim().isNotEmpty
              ? grammar.matchedText
              : grammar.nameDe,
          secondaryText: grammar.explanationDe,
          sources: <StudyLibrarySource>[
            StudyLibrarySource(
              origin: StudyLibraryOrigin.bookshelf,
              sourceId: '${page.id}:grammar:$index',
            ),
          ],
        ),
      );
    }
  }

  static void _addSentences(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
  ) {
    for (var index = 0; index < page.sentences.length; index++) {
      final sentence = page.sentences[index];
      records.add(
        StudyLibrarySourceRecord(
          key: StudyItemKey(
            type: StudyLibraryItemType.sentence,
            id: sentence.korean,
          ),
          primaryText: sentence.korean,
          secondaryText: sentence.translationDe,
          sources: <StudyLibrarySource>[
            StudyLibrarySource(
              origin: StudyLibraryOrigin.bookshelf,
              sourceId: '${page.id}:sentence:$index',
            ),
          ],
        ),
      );
    }
  }

  static void _addExpressions(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
  ) {
    for (var index = 0; index < page.expressions.length; index++) {
      final expression = page.expressions[index];
      final translation = page.analysisLanguage == 'en'
          ? expression.translationEn
          : expression.translationDe;
      records.add(
        StudyLibrarySourceRecord(
          key: StudyItemKey(
            type: StudyLibraryItemType.expression,
            id: expression.korean,
          ),
          primaryText: expression.korean,
          secondaryText: translation,
          sources: <StudyLibrarySource>[
            StudyLibrarySource(
              origin: StudyLibraryOrigin.bookshelf,
              sourceId: '${page.id}:expression:$index',
            ),
          ],
        ),
      );
    }
  }
}

final class ProductionStudyLibrarySrsReader implements StudyLibrarySrsReader {
  const ProductionStudyLibrarySrsReader({this.now});

  final DateTime Function()? now;

  @override
  Future<List<StudyLibrarySrsRecord>> readSrsRecords() async {
    final today = _dateOnly((now ?? DateTime.now)());
    final ids = Storage.srsReviewedIds.toList()..sort();
    final records = <StudyLibrarySrsRecord>[];
    for (final id in ids) {
      final card = Storage.srsCard(id);
      if (card == null || card.reviewCount <= 0) continue;
      records.add(
        StudyLibrarySrsRecord(
          key: StudyItemKey(type: StudyLibraryItemType.word, id: id),
          reviewCount: card.reviewCount,
          isDue:
              card.nextReviewIso.isEmpty ||
              card.nextReviewIso.compareTo(today) <= 0,
        ),
      );
    }
    return records;
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

final class ProductionStudyLibraryBookmarkReader
    implements StudyLibraryBookmarkReader {
  const ProductionStudyLibraryBookmarkReader(this.store);

  final TypedStudyBookmarkStore store;

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async {
    final result = store.read();
    return StudyLibraryBookmarkSourceSnapshot(
      health: result.health,
      legacyMirrorSuppressions: result.legacyMirrorSuppressions,
      records: <StudyLibrarySourceRecord>[
        for (final bookmark in result.bookmarks)
          StudyLibrarySourceRecord(
            key: bookmark.key,
            primaryText: bookmark.primaryText,
            secondaryText: bookmark.secondaryText,
            sources: <StudyLibrarySource>[
              StudyLibrarySource(
                origin: StudyLibraryOrigin.typedBookmark,
                sourceId: bookmark.sourceUnitId.isEmpty
                    ? bookmark.key.encoded
                    : bookmark.sourceUnitId,
              ),
            ],
          ),
      ],
    );
  }
}
