import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../../services/storage_service.dart';
import 'study_library_models.dart';

/// A bookmark whose content shape is persisted explicitly.
///
/// Unlike legacy CustomPack rows, this record never guesses the type from its
/// text. Grammar, sentences, expressions, and Hangul therefore survive a
/// storage round trip without being flattened into words.
final class TypedStudyBookmark {
  factory TypedStudyBookmark({
    required StudyItemKey key,
    required String primaryText,
    String? secondaryText,
    String sourceUnitId = '',
  }) {
    final primary = primaryText.trim();
    if (primary.isEmpty) {
      throw ArgumentError.value(
        primaryText,
        'primaryText',
        'A typed bookmark must have display text.',
      );
    }
    final secondary = secondaryText?.trim();
    return TypedStudyBookmark._(
      key: key,
      primaryText: primary,
      secondaryText: secondary == null || secondary.isEmpty ? null : secondary,
      sourceUnitId: sourceUnitId.trim(),
    );
  }

  const TypedStudyBookmark._({
    required this.key,
    required this.primaryText,
    required this.secondaryText,
    required this.sourceUnitId,
  });

  final StudyItemKey key;
  final String primaryText;
  final String? secondaryText;
  final String sourceUnitId;

  Map<String, Object> toJson() => <String, Object>{
    'type': key.type.name,
    'id': key.id,
    'primaryText': primaryText,
    if (secondaryText case final value?) 'secondaryText': value,
    if (sourceUnitId.isNotEmpty) 'sourceUnitId': sourceUnitId,
  };

  static TypedStudyBookmark fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Typed bookmark must be an object.');
    }
    final json = value.map((key, value) => MapEntry(key.toString(), value));
    final rawType = json['type'];
    final rawId = json['id'];
    final rawPrimary = json['primaryText'];
    final rawSecondary = json['secondaryText'];
    final rawSourceUnitId = json['sourceUnitId'];
    if (rawType is! String ||
        rawId is! String ||
        rawPrimary is! String ||
        (rawSecondary != null && rawSecondary is! String) ||
        (rawSourceUnitId != null && rawSourceUnitId is! String)) {
      throw const FormatException('Typed bookmark fields are invalid.');
    }
    final type = StudyLibraryItemType.values
        .where((candidate) => candidate.name == rawType)
        .firstOrNull;
    if (type == null) {
      throw const FormatException('Typed bookmark type is unsupported.');
    }
    try {
      return TypedStudyBookmark(
        key: StudyItemKey(type: type, id: rawId),
        primaryText: rawPrimary,
        secondaryText: rawSecondary as String?,
        sourceUnitId: rawSourceUnitId as String? ?? '',
      );
    } on ArgumentError catch (error) {
      throw FormatException('Typed bookmark content is invalid.', error);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TypedStudyBookmark &&
      other.key == key &&
      other.primaryText == primaryText &&
      other.secondaryText == secondaryText &&
      other.sourceUnitId == sourceUnitId;

  @override
  int get hashCode =>
      Object.hash(key, primaryText, secondaryText, sourceUnitId);
}

final class TypedStudyBookmarkReadResult {
  TypedStudyBookmarkReadResult({
    required this.health,
    required Iterable<TypedStudyBookmark> bookmarks,
    Iterable<StudyLibraryLegacyMirrorSuppression> legacyMirrorSuppressions =
        const <StudyLibraryLegacyMirrorSuppression>[],
    this.sourceVersion,
  }) : bookmarks = UnmodifiableListView<TypedStudyBookmark>(bookmarks.toList()),
       legacyMirrorSuppressions =
           UnmodifiableListView<StudyLibraryLegacyMirrorSuppression>(
             legacyMirrorSuppressions.toList()..sort(),
           );

  final StudyLibraryBookmarkHealth health;
  final List<TypedStudyBookmark> bookmarks;
  final List<StudyLibraryLegacyMirrorSuppression> legacyMirrorSuppressions;
  final int? sourceVersion;

  /// The caller may offer recovery UX, but must not overwrite the raw blob.
  bool get needsQuarantine => health != StudyLibraryBookmarkHealth.healthy;
}

enum TypedStudyBookmarkMutationResult {
  inserted,
  updated,
  unchanged,
  removed,
  absent,
  blockedCorrupt,
  blockedFutureVersion,
}

typedef TypedStudyBookmarkRawReader = String Function();
typedef TypedStudyBookmarkRawWriter = Future<void> Function(String raw);

/// Versioned, type-preserving bookmark storage with fail-closed recovery.
final class TypedStudyBookmarkStore {
  factory TypedStudyBookmarkStore({
    required TypedStudyBookmarkRawReader readRaw,
    required TypedStudyBookmarkRawWriter writeRaw,
  }) => TypedStudyBookmarkStore._(readRaw, writeRaw);

  TypedStudyBookmarkStore._(this._readRaw, this._writeRaw);

  factory TypedStudyBookmarkStore.production() => _production;

  /// One process-wide mutation queue protects production callers that save
  /// from different learning screens at nearly the same time. Separate store
  /// instances would each read the same old blob and let the last write win.
  static TypedStudyBookmarkStore _production = _newProductionStore();

  static TypedStudyBookmarkStore _newProductionStore() =>
      TypedStudyBookmarkStore(
        readRaw: () => Storage.typedStudyBookmarksRawJson,
        writeRaw: Storage.setTypedStudyBookmarksRawJson,
      );

  /// Rebinds the process queue after a test replaces SharedPreferences.
  /// Production code must never call this.
  static void resetProductionForTesting() {
    _production = _newProductionStore();
  }

  static const int schemaVersion = 1;

  final TypedStudyBookmarkRawReader _readRaw;
  final TypedStudyBookmarkRawWriter _writeRaw;
  Future<void> _mutationTail = Future<void>.value();

  TypedStudyBookmarkReadResult read() => decode(_readRaw());

  static TypedStudyBookmarkReadResult decode(String raw) {
    if (raw.trim().isEmpty) {
      return TypedStudyBookmarkReadResult(
        health: StudyLibraryBookmarkHealth.healthy,
        bookmarks: const <TypedStudyBookmark>[],
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Bookmark payload must be an object.');
      }
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      final version = json['version'];
      if (version is! int) {
        throw const FormatException('Bookmark version is invalid.');
      }
      if (version > schemaVersion) {
        return TypedStudyBookmarkReadResult(
          health: StudyLibraryBookmarkHealth.futureVersion,
          bookmarks: const <TypedStudyBookmark>[],
          sourceVersion: version,
        );
      }
      if (version != schemaVersion || json['items'] is! List) {
        throw const FormatException('Bookmark schema is unsupported.');
      }
      final byKey = <StudyItemKey, TypedStudyBookmark>{};
      for (final rawBookmark in json['items'] as List) {
        final bookmark = TypedStudyBookmark.fromJson(rawBookmark);
        if (byKey.containsKey(bookmark.key)) {
          throw const FormatException('Bookmark keys must be unique.');
        }
        byKey[bookmark.key] = bookmark;
      }
      final rawSuppressions = json['hiddenLegacyMirrors'];
      if (rawSuppressions != null && rawSuppressions is! List) {
        throw const FormatException('Mirror suppressions must be a list.');
      }
      final suppressions = <StudyLibraryLegacyMirrorSuppression>{};
      for (final rawSuppression in (rawSuppressions as List? ?? const [])) {
        final suppression = _decodeSuppression(rawSuppression);
        if (!suppressions.add(suppression)) {
          throw const FormatException('Mirror suppressions must be unique.');
        }
        if (byKey.values.any(
          (bookmark) =>
              bookmark.key.type == suppression.type &&
              StudyItemKey.normalizeId(bookmark.primaryText) ==
                  suppression.primaryText,
        )) {
          throw const FormatException(
            'An active bookmark cannot also suppress its mirror.',
          );
        }
      }
      final bookmarks = byKey.values.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return TypedStudyBookmarkReadResult(
        health: StudyLibraryBookmarkHealth.healthy,
        bookmarks: bookmarks,
        legacyMirrorSuppressions: suppressions,
        sourceVersion: version,
      );
    } on Object {
      return TypedStudyBookmarkReadResult(
        health: StudyLibraryBookmarkHealth.corrupt,
        bookmarks: const <TypedStudyBookmark>[],
      );
    }
  }

  Future<TypedStudyBookmarkMutationResult> upsert(
    TypedStudyBookmark bookmark,
  ) => _enqueue(() async {
    final current = read();
    final blocked = _blockedResult(current.health);
    if (blocked != null) return blocked;

    final byKey = <StudyItemKey, TypedStudyBookmark>{
      for (final item in current.bookmarks) item.key: item,
    };
    final suppressions = current.legacyMirrorSuppressions.toSet();
    if (bookmark.key.type != StudyLibraryItemType.word) {
      suppressions.remove(
        StudyLibraryLegacyMirrorSuppression(
          type: bookmark.key.type,
          primaryText: bookmark.primaryText,
        ),
      );
    }
    final existing = byKey[bookmark.key];
    if (existing == bookmark &&
        suppressions.length == current.legacyMirrorSuppressions.length) {
      return TypedStudyBookmarkMutationResult.unchanged;
    }
    byKey[bookmark.key] = bookmark;
    await _writeRaw(_encode(byKey.values, suppressions));
    return existing == null
        ? TypedStudyBookmarkMutationResult.inserted
        : TypedStudyBookmarkMutationResult.updated;
  });

  Future<TypedStudyBookmarkMutationResult> remove(StudyItemKey key) =>
      _enqueue(() async {
        final current = read();
        final blocked = _blockedResult(current.health);
        if (blocked != null) return blocked;

        final byKey = <StudyItemKey, TypedStudyBookmark>{
          for (final item in current.bookmarks) item.key: item,
        };
        final removed = byKey.remove(key);
        if (removed == null) {
          return TypedStudyBookmarkMutationResult.absent;
        }
        final suppressions = current.legacyMirrorSuppressions.toSet();
        if (key.type != StudyLibraryItemType.word) {
          suppressions.add(
            StudyLibraryLegacyMirrorSuppression(
              type: key.type,
              primaryText: removed.primaryText,
            ),
          );
        }
        await _writeRaw(_encode(byKey.values, suppressions));
        return TypedStudyBookmarkMutationResult.removed;
      });

  static TypedStudyBookmarkMutationResult? _blockedResult(
    StudyLibraryBookmarkHealth health,
  ) => switch (health) {
    StudyLibraryBookmarkHealth.healthy => null,
    StudyLibraryBookmarkHealth.corrupt =>
      TypedStudyBookmarkMutationResult.blockedCorrupt,
    StudyLibraryBookmarkHealth.futureVersion =>
      TypedStudyBookmarkMutationResult.blockedFutureVersion,
  };

  static StudyLibraryLegacyMirrorSuppression _decodeSuppression(Object? value) {
    if (value is! Map) {
      throw const FormatException('Mirror suppression must be an object.');
    }
    final json = value.map((key, value) => MapEntry(key.toString(), value));
    final rawType = json['type'];
    final rawPrimaryText = json['primaryText'];
    if (rawType is! String || rawPrimaryText is! String) {
      throw const FormatException('Mirror suppression fields are invalid.');
    }
    final type = StudyLibraryItemType.values
        .where((candidate) => candidate.name == rawType)
        .firstOrNull;
    if (type == null) {
      throw const FormatException('Mirror suppression type is unsupported.');
    }
    try {
      return StudyLibraryLegacyMirrorSuppression(
        type: type,
        primaryText: rawPrimaryText,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Mirror suppression content is invalid.', error);
    }
  }

  static String _encode(
    Iterable<TypedStudyBookmark> bookmarks,
    Iterable<StudyLibraryLegacyMirrorSuppression> suppressions,
  ) {
    final ordered = bookmarks.toList()..sort((a, b) => a.key.compareTo(b.key));
    final orderedSuppressions = suppressions.toList()..sort();
    return jsonEncode(<String, Object>{
      'version': schemaVersion,
      'items': ordered.map((bookmark) => bookmark.toJson()).toList(),
      if (orderedSuppressions.isNotEmpty)
        'hiddenLegacyMirrors': <Object>[
          for (final suppression in orderedSuppressions)
            <String, Object>{
              'type': suppression.type.name,
              'primaryText': suppression.primaryText,
            },
        ],
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then<void>((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
