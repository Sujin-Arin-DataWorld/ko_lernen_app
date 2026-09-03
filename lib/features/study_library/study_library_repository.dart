import 'study_library_models.dart';

/// One normalized contribution from an existing source repository.
final class StudyLibrarySourceRecord {
  factory StudyLibrarySourceRecord({
    required StudyItemKey key,
    required Iterable<StudyLibrarySource> sources,
    String? primaryText,
    String? secondaryText,
  }) {
    final immutableSources = List<StudyLibrarySource>.of(sources);
    if (immutableSources.isEmpty) {
      throw ArgumentError.value(
        sources,
        'sources',
        'A study-library record needs at least one source.',
      );
    }
    final primary = primaryText?.trim();
    final secondary = secondaryText?.trim();
    return StudyLibrarySourceRecord._(
      key: key,
      sources: List<StudyLibrarySource>.unmodifiable(immutableSources),
      primaryText: primary == null || primary.isEmpty ? null : primary,
      secondaryText: secondary == null || secondary.isEmpty ? null : secondary,
    );
  }

  const StudyLibrarySourceRecord._({
    required this.key,
    required this.sources,
    required this.primaryText,
    required this.secondaryText,
  });

  final StudyItemKey key;
  final List<StudyLibrarySource> sources;
  final String? primaryText;
  final String? secondaryText;
}

final class StudyLibrarySrsRecord {
  StudyLibrarySrsRecord({
    required this.key,
    required this.reviewCount,
    required this.isDue,
  }) {
    if (reviewCount < 0) {
      throw ArgumentError.value(
        reviewCount,
        'reviewCount',
        'Review count must not be negative.',
      );
    }
  }

  final StudyItemKey key;
  final int reviewCount;
  final bool isDue;
}

final class StudyLibraryBookmarkSourceSnapshot {
  const StudyLibraryBookmarkSourceSnapshot({
    required this.records,
    required this.health,
    this.legacyMirrorSuppressions =
        const <StudyLibraryLegacyMirrorSuppression>[],
  });

  final List<StudyLibrarySourceRecord> records;
  final StudyLibraryBookmarkHealth health;
  final List<StudyLibraryLegacyMirrorSuppression> legacyMirrorSuppressions;
}

abstract interface class StudyLibraryLikedReader {
  Future<List<StudyLibrarySourceRecord>> readLiked();
}

abstract interface class StudyLibraryCustomPackReader {
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems();
}

abstract interface class StudyLibraryBookshelfReader {
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems();
}

abstract interface class StudyLibrarySrsReader {
  Future<List<StudyLibrarySrsRecord>> readSrsRecords();
}

abstract interface class StudyLibraryBookmarkReader {
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks();
}

final class EmptyStudyLibraryBookmarkReader
    implements StudyLibraryBookmarkReader {
  const EmptyStudyLibraryBookmarkReader();

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async =>
      const StudyLibraryBookmarkSourceSnapshot(
        records: <StudyLibrarySourceRecord>[],
        health: StudyLibraryBookmarkHealth.healthy,
      );
}

/// Read-only composition over existing, independently owned repositories.
///
/// This class exposes no source writer. Loading a snapshot cannot migrate,
/// flatten, delete, or otherwise rewrite likes, CustomPacks, bookshelf pages,
/// typed bookmarks, or SRS state.
final class StudyLibraryRepository {
  factory StudyLibraryRepository({
    required StudyLibraryLikedReader likedReader,
    required StudyLibraryCustomPackReader customPackReader,
    required StudyLibraryBookshelfReader bookshelfReader,
    required StudyLibrarySrsReader srsReader,
    StudyLibraryBookmarkReader bookmarkReader =
        const EmptyStudyLibraryBookmarkReader(),
  }) => StudyLibraryRepository._(
    likedReader,
    customPackReader,
    bookshelfReader,
    srsReader,
    bookmarkReader,
  );

  const StudyLibraryRepository._(
    this._likedReader,
    this._customPackReader,
    this._bookshelfReader,
    this._srsReader,
    this._bookmarkReader,
  );

  final StudyLibraryLikedReader _likedReader;
  final StudyLibraryCustomPackReader _customPackReader;
  final StudyLibraryBookshelfReader _bookshelfReader;
  final StudyLibrarySrsReader _srsReader;
  final StudyLibraryBookmarkReader _bookmarkReader;

  Future<StudyLibrarySnapshot> load() async {
    // Start all independent reads before awaiting any one of them.
    final likedFuture = _likedReader.readLiked();
    final customPackFuture = _customPackReader.readCustomPackItems();
    final bookshelfFuture = _bookshelfReader.readBookshelfItems();
    final srsFuture = _srsReader.readSrsRecords();
    final bookmarkFuture = _bookmarkReader.readBookmarks();

    final liked = await likedFuture;
    final customPack = await customPackFuture;
    final bookshelf = await bookshelfFuture;
    final srs = await srsFuture;
    final bookmarks = await bookmarkFuture;

    // CustomPack is still the compatibility writer used by games, but it has
    // no item-type field. Once the type-preserving bookmark store contains an
    // authoritative non-word record, an exact learner-facing text match is
    // the same save mirrored through that legacy word-only shape. Keep the
    // CustomPack row in its owner (games still consume it), but do not expose
    // the flattened duplicate as a fake word in this read model.
    //
    // This deliberately requires both legacyFlattened provenance and a live
    // typed bookmark. Unrelated real words and corrupt/quarantined bookmark
    // payloads are never hidden.
    final typedNonWordTexts = <String>{
      for (final record in bookmarks.records)
        if (record.key.type != StudyLibraryItemType.word &&
            record.primaryText != null)
          StudyItemKey.normalizeId(record.primaryText!),
      for (final suppression in bookmarks.legacyMirrorSuppressions)
        suppression.primaryText,
    };
    final visibleCustomPack = customPack.where((record) {
      if (record.key.type != StudyLibraryItemType.word ||
          !record.sources.any(
            (source) => source.origin == StudyLibraryOrigin.wordbookMirror,
          ) ||
          !record.sources.any(
            (source) => source.origin == StudyLibraryOrigin.legacyFlattened,
          )) {
        return true;
      }
      final learnerText = record.primaryText ?? record.key.id;
      return !typedNonWordTexts.contains(StudyItemKey.normalizeId(learnerText));
    });

    final merged = <StudyItemKey, _EntryAccumulator>{};
    for (final record in <StudyLibrarySourceRecord>[
      ...liked,
      ...visibleCustomPack,
      ...bookshelf,
      ...bookmarks.records,
    ]) {
      (merged[record.key] ??= _EntryAccumulator(record.key)).add(record);
    }

    final srsByKey = <StudyItemKey, _SrsAccumulator>{};
    for (final record in srs) {
      // SRS is annotation, not ownership. An SRS-only card must not silently
      // become a saved library item.
      if (!merged.containsKey(record.key)) continue;
      (srsByKey[record.key] ??= _SrsAccumulator()).add(record);
    }

    final entries = <StudyLibraryEntry>[];
    for (final accumulator in merged.values) {
      final srsState = srsByKey[accumulator.key];
      entries.add(accumulator.build(srsState));
    }
    entries.sort((a, b) => a.key.compareTo(b.key));

    return StudyLibrarySnapshot(
      entries: entries,
      bookmarkHealth: bookmarks.health,
    );
  }
}

final class _EntryAccumulator {
  _EntryAccumulator(this.key);

  final StudyItemKey key;
  final Set<StudyLibrarySource> _sources = <StudyLibrarySource>{};
  final List<StudyLibrarySourceRecord> _presentations =
      <StudyLibrarySourceRecord>[];

  void add(StudyLibrarySourceRecord record) {
    _sources.addAll(record.sources);
    if (record.primaryText != null) {
      _presentations.add(record);
    }
  }

  StudyLibraryEntry build(_SrsAccumulator? srs) {
    final presentations = List<StudyLibrarySourceRecord>.of(_presentations)
      ..sort(_comparePresentation);
    final selected = presentations.firstOrNull;
    final origins = _sources.map((source) => source.origin).toSet();
    final isLiked = origins.contains(StudyLibraryOrigin.liked);
    final isSaved =
        origins.contains(StudyLibraryOrigin.typedBookmark) ||
        origins.contains(StudyLibraryOrigin.customPack) ||
        origins.contains(StudyLibraryOrigin.bookshelf);
    final reviewCount = srs?.reviewCount ?? 0;
    final isDue =
        isSaved &&
        key.type == StudyLibraryItemType.word &&
        reviewCount > 0 &&
        (srs?.isDue ?? false);
    final sources = <StudyLibrarySource>{..._sources};
    if (srs != null && reviewCount > 0) {
      sources.add(
        StudyLibrarySource(origin: StudyLibraryOrigin.srs, sourceId: key.id),
      );
    }
    return StudyLibraryEntry(
      key: key,
      primaryText: selected?.primaryText ?? key.id,
      secondaryText: presentations
          .map((record) => record.secondaryText)
          .whereType<String>()
          .firstOrNull,
      sources: sources,
      isResolved: selected != null,
      isLiked: isLiked,
      isSaved: isSaved,
      isDue: isDue,
      reviewCount: reviewCount,
    );
  }

  static int _comparePresentation(
    StudyLibrarySourceRecord first,
    StudyLibrarySourceRecord second,
  ) {
    final firstPriority = _presentationPriority(first);
    final secondPriority = _presentationPriority(second);
    final priorityOrder = firstPriority.compareTo(secondPriority);
    if (priorityOrder != 0) return priorityOrder;
    final primaryOrder = (first.primaryText ?? '').compareTo(
      second.primaryText ?? '',
    );
    if (primaryOrder != 0) return primaryOrder;
    final secondaryOrder = (first.secondaryText ?? '').compareTo(
      second.secondaryText ?? '',
    );
    if (secondaryOrder != 0) return secondaryOrder;
    final firstSource = List<StudyLibrarySource>.of(first.sources)..sort();
    final secondSource = List<StudyLibrarySource>.of(second.sources)..sort();
    return firstSource.first.compareTo(secondSource.first);
  }

  static int _presentationPriority(StudyLibrarySourceRecord record) {
    final origins = record.sources.map((source) => source.origin).toSet();
    if (origins.contains(StudyLibraryOrigin.typedBookmark)) return 0;
    if (origins.contains(StudyLibraryOrigin.bookshelf)) return 1;
    if (origins.contains(StudyLibraryOrigin.customPack)) return 2;
    if (origins.contains(StudyLibraryOrigin.liked)) return 3;
    return 4;
  }
}

final class _SrsAccumulator {
  int reviewCount = 0;
  bool isDue = false;

  void add(StudyLibrarySrsRecord record) {
    if (record.reviewCount > reviewCount) {
      reviewCount = record.reviewCount;
    }
    isDue = isDue || record.isDue;
  }
}
