import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/book_page.dart';
import '../../models/grammar.dart';
import '../../models/vocab.dart';
import '../../models/smalltalk.dart';
import '../../models/liked_content.dart';
import '../../services/bookshelf_service.dart';
import '../../services/custom_pack_service.dart';
import '../../services/data_loader.dart';
import '../../services/saved_word_localization.dart';
import '../../services/liked_content_service.dart';
import '../../services/scenario_loader.dart';
import '../../services/smalltalk_loader.dart';
import '../../services/storage_service.dart';
import 'study_library_models.dart';
import 'study_library_repository.dart';
import 'typed_study_bookmark_store.dart';

StudyLibraryRepository createProductionStudyLibraryRepository({
  required String languageCode,
  TypedStudyBookmarkStore? bookmarkStore,
}) => StudyLibraryRepository(
  likedReader: const ProductionStudyLibraryLikedReader(),
  customPackReader: ProductionStudyLibraryCustomPackReader(
    languageCode: languageCode,
  ),
  bookshelfReader: ProductionStudyLibraryBookshelfReader(
    languageCode: languageCode,
  ),
  srsReader: const ProductionStudyLibrarySrsReader(),
  bookmarkReader: ProductionStudyLibraryBookmarkReader(
    bookmarkStore ?? TypedStudyBookmarkStore.production(),
    languageCode: languageCode,
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
  const ProductionStudyLibraryCustomPackReader({required this.languageCode});
  final String languageCode;

  @override
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems() async {
    final translations = await _LibraryTranslations.load();
    final records = <StudyLibrarySourceRecord>[];
    for (final pack in CustomPackService.getAll()) {
      for (var index = 0; index < pack.words.length; index++) {
        final word = localizeSavedWord(pack.words[index], translations.vocab);
        final sourceId = '${pack.id}:word:$index';
        records.add(
          StudyLibrarySourceRecord(
            // Legacy CustomPack storage has no trustworthy item-type field.
            // Even grammar-looking text remains a word/legacyFlattened row.
            key: StudyItemKey(type: StudyLibraryItemType.word, id: word.korean),
            primaryText: word.korean,
            secondaryText: word.translationFor(languageCode),
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
  const ProductionStudyLibraryBookshelfReader({required this.languageCode});
  final String languageCode;

  @override
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems() async {
    final translations = await _LibraryTranslations.load();
    final records = <StudyLibrarySourceRecord>[];
    for (final page in BookshelfService.getAllLocal()) {
      _addWords(records, page, translations);
      _addGrammar(records, page, translations);
      _addSentences(records, page, translations);
      _addExpressions(records, page);
    }
    return records;
  }

  void _addWords(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
    _LibraryTranslations translations,
  ) {
    for (var index = 0; index < page.words.length; index++) {
      final word = localizeSavedWord(page.words[index], translations.vocab);
      records.add(
        StudyLibrarySourceRecord(
          key: StudyItemKey(type: StudyLibraryItemType.word, id: word.korean),
          primaryText: word.korean,
          secondaryText: word.translationFor(languageCode),
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

  void _addGrammar(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
    _LibraryTranslations translations,
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
              : (page.analysisLanguage == languageCode ? grammar.nameDe : null),
          secondaryText: page.analysisLanguage == languageCode
              ? grammar.explanationDe
              : translations.secondary(
                  StudyItemKey(type: StudyLibraryItemType.grammar, id: id),
                  grammar.matchedText,
                  languageCode,
                ),
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

  void _addSentences(
    List<StudyLibrarySourceRecord> records,
    BookPage page,
    _LibraryTranslations translations,
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
          secondaryText: sentence.translationLanguage == languageCode
              ? sentence.translationDe
              : translations.secondary(
                  StudyItemKey(
                    type: StudyLibraryItemType.sentence,
                    id: sentence.korean,
                  ),
                  sentence.korean,
                  languageCode,
                ),
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

  void _addExpressions(List<StudyLibrarySourceRecord> records, BookPage page) {
    for (var index = 0; index < page.expressions.length; index++) {
      final expression = page.expressions[index];
      final translation = languageCode == 'en'
          ? (expression.translationEn.isNotEmpty
                ? expression.translationEn
                : (expression.translationLanguage == 'en'
                      ? expression.translationDe
                      : ''))
          : (expression.translationLanguage == 'en' &&
                    (expression.translationEn.isEmpty ||
                        expression.translationDe == expression.translationEn)
                ? ''
                : expression.translationDe);
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
  const ProductionStudyLibraryBookmarkReader(
    this.store, {
    required this.languageCode,
  });

  final TypedStudyBookmarkStore store;
  final String languageCode;

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async {
    final result = store.read();
    final translations = await _LibraryTranslations.load();
    return StudyLibraryBookmarkSourceSnapshot(
      health: result.health,
      legacyMirrorSuppressions: result.legacyMirrorSuppressions,
      records: <StudyLibrarySourceRecord>[
        for (final bookmark in result.bookmarks)
          StudyLibrarySourceRecord(
            key: bookmark.key,
            primaryText: bookmark.primaryText,
            secondaryText: bookmark.secondaryLanguage == languageCode
                ? bookmark.secondaryText
                : translations.secondary(
                    bookmark.key,
                    bookmark.primaryText,
                    languageCode,
                    savedMeaning: bookmark.secondaryText,
                    sourceContentId: bookmark.sourceUnitId,
                  ),
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

/// Resolves only authored translations from local content with a matching key
/// or source text. Legacy user prose is retained in storage, never translated
/// or relabeled by guessing its language.
final class _LibraryTranslations {
  _LibraryTranslations(this.vocab, this.grammar, this.patterns, this.smalltalk);

  final List<Vocab> vocab;
  final List<Grammar> grammar;
  final Map<String, Map<String, dynamic>> patterns;
  final List<SmalltalkPhrase> smalltalk;

  static Future<_LibraryTranslations> load() async {
    final values = await Future.wait<Object>([
      DataLoader.loadVocab(),
      DataLoader.loadGrammar(),
      _loadPatterns(),
      SmalltalkLoader.load().then((_) => SmalltalkLoader.phrases),
    ]);
    return _LibraryTranslations(
      values[0] as List<Vocab>,
      values[1] as List<Grammar>,
      values[2] as Map<String, Map<String, dynamic>>,
      values[3] as List<SmalltalkPhrase>,
    );
  }

  static Future<Map<String, Map<String, dynamic>>> _loadPatterns() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/grammar_patterns.json',
      );
      return {
        for (final row
            in (jsonDecode(raw) as List).whereType<Map<String, dynamic>>())
          row['id'] as String: row,
      };
    } on Object {
      return {};
    }
  }

  String? secondary(
    StudyItemKey key,
    String primary,
    String languageCode, {
    String? savedMeaning,
    String? sourceContentId,
  }) {
    String? available(String value) => value.trim().isEmpty ? null : value;
    final english = languageCode == 'en';
    switch (key.type) {
      case StudyLibraryItemType.word:
        final byId = vocab.where((word) => word.id == key.id).firstOrNull;
        if (byId != null) {
          return available(english ? byId.english : byId.german);
        }
        final matches = vocab.where(
          (word) => word.korean == primary || word.korean == key.id,
        );
        final byMeaning = matches
            .where(
              (word) =>
                  savedMeaning != null &&
                  (word.german.trim() == savedMeaning.trim() ||
                      word.english.trim() == savedMeaning.trim()),
            )
            .firstOrNull;
        // Korean alone is not enough to replace a custom meaning or choose
        // between homonyms. An unspecialized bookmark can use a unique row.
        final match =
            byMeaning ??
            (savedMeaning == null && matches.length == 1
                ? matches.single
                : null);
        return match == null
            ? null
            : available(english ? match.english : match.german);
      case StudyLibraryItemType.grammar:
        final match =
            grammar.where((item) => item.id == key.id).firstOrNull ??
            grammar.where((item) => item.id == sourceContentId).firstOrNull ??
            grammar
                .where(
                  (item) => item.pattern == key.id || item.pattern == primary,
                )
                .firstOrNull;
        if (match != null) {
          return available(english ? match.explanationEn : match.explanationDe);
        }
        return available(
          patterns[key.id]?['explanation_$languageCode'] as String? ?? '',
        );
      case StudyLibraryItemType.sentence:
      case StudyLibraryItemType.expression:
        final phrase =
            smalltalk.where((item) => item.id == key.id).firstOrNull ??
            smalltalk
                .where((item) => item.ko == primary || item.ko == key.id)
                .firstOrNull;
        if (phrase != null) {
          return available(english ? phrase.en : phrase.de);
        }
        String normalized(String value) =>
            value.trim().replaceAll(RegExp(r'\s+'), ' ');
        final example = vocab
            .where(
              (word) => normalized(word.exampleKorean) == normalized(primary),
            )
            .firstOrNull;
        return example == null
            ? null
            : available(
                english ? example.exampleEnglish : example.exampleGerman,
              );
      case StudyLibraryItemType.hangul:
        return null;
    }
  }
}
