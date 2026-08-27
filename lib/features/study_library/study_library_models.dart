import 'dart:collection';

/// Content shapes supported by the unified study-library contract.
///
/// This enum is deliberately narrower than the app's activity catalog. It
/// describes the shape of a saved learning item, not the screen that created
/// it.
enum StudyLibraryItemType { word, grammar, sentence, expression, hangul }

/// Independent source repositories that may contribute one library entry.
enum StudyLibraryOrigin {
  liked,
  typedBookmark,
  customPack,
  bookshelf,
  srs,

  /// A row in the quick wordbook that mirrors a typed non-word bookmark.
  ///
  /// The row remains available to legacy vocabulary games. The Study Library
  /// may hide it when the typed store proves that it is only a compatibility
  /// representation rather than a learner-facing word.
  wordbookMirror,

  /// Compatibility marker for pre-typed CustomPack rows.
  ///
  /// It is never interpreted as grammar or a sentence. The row remains a
  /// [StudyLibraryItemType.word] until a future explicit migration proves a
  /// more specific type.
  legacyFlattened,
}

/// Durable evidence that a removed typed bookmark still has a word-only
/// compatibility mirror.
///
/// Suppressions never delete or retype the CustomPack row. They only keep that
/// row out of the type-preserving Study Library read model, so vocabulary games
/// can continue to consume the legacy pack without presenting grammar or a
/// sentence as a word.
final class StudyLibraryLegacyMirrorSuppression
    implements Comparable<StudyLibraryLegacyMirrorSuppression> {
  factory StudyLibraryLegacyMirrorSuppression({
    required StudyLibraryItemType type,
    required String primaryText,
  }) {
    if (type == StudyLibraryItemType.word) {
      throw ArgumentError.value(
        type,
        'type',
        'Word bookmarks do not need a non-word mirror suppression.',
      );
    }
    final normalizedText = StudyItemKey.normalizeId(primaryText);
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(
        primaryText,
        'primaryText',
        'A mirror suppression needs learner-facing text.',
      );
    }
    return StudyLibraryLegacyMirrorSuppression._(
      type: type,
      primaryText: normalizedText,
    );
  }

  const StudyLibraryLegacyMirrorSuppression._({
    required this.type,
    required this.primaryText,
  });

  final StudyLibraryItemType type;
  final String primaryText;

  String get encoded => '${type.name}|$primaryText';

  @override
  int compareTo(StudyLibraryLegacyMirrorSuppression other) {
    final typeOrder = type.index.compareTo(other.type.index);
    return typeOrder != 0
        ? typeOrder
        : primaryText.compareTo(other.primaryText);
  }

  @override
  bool operator ==(Object other) =>
      other is StudyLibraryLegacyMirrorSuppression &&
      other.type == type &&
      other.primaryText == primaryText;

  @override
  int get hashCode => Object.hash(type, primaryText);
}

/// Stable identity used to merge the same item from independent stores.
final class StudyItemKey implements Comparable<StudyItemKey> {
  factory StudyItemKey({
    required StudyLibraryItemType type,
    required String id,
  }) {
    final normalizedId = normalizeId(id);
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Study item ID must not be empty.');
    }
    return StudyItemKey._(type: type, id: normalizedId);
  }

  const StudyItemKey._({required this.type, required this.id});

  final StudyLibraryItemType type;
  final String id;

  static String normalizeId(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String get encoded => '${type.name}|$id';

  @override
  int compareTo(StudyItemKey other) {
    final typeOrder = type.index.compareTo(other.type.index);
    return typeOrder != 0 ? typeOrder : id.compareTo(other.id);
  }

  @override
  bool operator ==(Object other) =>
      other is StudyItemKey && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => encoded;
}

/// One exact provenance edge retained after multi-store merging.
final class StudyLibrarySource implements Comparable<StudyLibrarySource> {
  factory StudyLibrarySource({
    required StudyLibraryOrigin origin,
    required String sourceId,
  }) {
    final normalizedId = sourceId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Study-library source ID must not be empty.',
      );
    }
    return StudyLibrarySource._(origin: origin, sourceId: normalizedId);
  }

  const StudyLibrarySource._({required this.origin, required this.sourceId});

  final StudyLibraryOrigin origin;
  final String sourceId;

  @override
  int compareTo(StudyLibrarySource other) {
    final originOrder = origin.index.compareTo(other.origin.index);
    return originOrder != 0 ? originOrder : sourceId.compareTo(other.sourceId);
  }

  @override
  bool operator ==(Object other) =>
      other is StudyLibrarySource &&
      other.origin == origin &&
      other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(origin, sourceId);
}

/// Canonical, read-only item exposed to future library consumers.
final class StudyLibraryEntry {
  StudyLibraryEntry({
    required this.key,
    required this.primaryText,
    required this.secondaryText,
    required Iterable<StudyLibrarySource> sources,
    required this.isResolved,
    required this.isLiked,
    required this.isSaved,
    required this.isDue,
    required this.reviewCount,
  }) : sources = UnmodifiableListView<StudyLibrarySource>(
         List<StudyLibrarySource>.of(sources)..sort(),
       );

  final StudyItemKey key;
  final String primaryText;
  final String? secondaryText;
  final List<StudyLibrarySource> sources;

  /// False for a liked item whose source content is no longer resolvable.
  /// Such an item remains visible and removable instead of disappearing.
  final bool isResolved;
  final bool isLiked;
  final bool isSaved;

  /// True only for saved, reviewable words with a due SRS record.
  final bool isDue;
  final int reviewCount;

  Set<StudyLibraryOrigin> get origins => Set<StudyLibraryOrigin>.unmodifiable(
    sources.map((source) => source.origin),
  );

  bool get isReviewable => key.type == StudyLibraryItemType.word;
}

enum StudyLibraryBookmarkHealth { healthy, corrupt, futureVersion }

/// Deterministic aggregate used by a later UI without mutating source stores.
final class StudyLibrarySnapshot {
  StudyLibrarySnapshot({
    required Iterable<StudyLibraryEntry> entries,
    required this.bookmarkHealth,
  }) : entries = UnmodifiableListView<StudyLibraryEntry>(
         List<StudyLibraryEntry>.of(entries)
           ..sort((first, second) => first.key.compareTo(second.key)),
       ) {
    liked = UnmodifiableListView<StudyLibraryEntry>(
      this.entries.where((entry) => entry.isLiked).toList(),
    );
    saved = UnmodifiableListView<StudyLibraryEntry>(
      this.entries.where((entry) => entry.isSaved).toList(),
    );
    due = UnmodifiableListView<StudyLibraryEntry>(
      this.entries.where((entry) => entry.isDue).toList(),
    );
  }

  final List<StudyLibraryEntry> entries;
  late final List<StudyLibraryEntry> liked;
  late final List<StudyLibraryEntry> saved;
  late final List<StudyLibraryEntry> due;
  final StudyLibraryBookmarkHealth bookmarkHealth;
}
