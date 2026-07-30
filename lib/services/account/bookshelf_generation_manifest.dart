import 'dart:convert';

import 'package:crypto/crypto.dart';

const int _bookshelfSchemaVersion = 1;
const int _maxBookshelfRecords = 400;
const int _maxBookshelfRecordBytes = 256 * 1024;
const int _maxBookshelfGenerationBytes = 4 * 1024 * 1024;
const int _maxBookshelfStringBytes = 128 * 1024;
const int _maxBookshelfCollectionLength = 512;
const int _maxBookshelfNestingDepth = 16;

enum BookshelfSnapshotSource { activeGeneration, legacy }

enum BookshelfGenerationWriteStatus { activated, revisionConflict }

class BookshelfGenerationWriteResult {
  const BookshelfGenerationWriteResult(this.status, {this.revision});

  final BookshelfGenerationWriteStatus status;
  final int? revision;
}

class BookshelfRemoteSnapshot {
  const BookshelfRemoteSnapshot({
    required this.source,
    required this.entries,
    required this.tombstoneIds,
    required this.revision,
  });

  final BookshelfSnapshotSource source;
  final Map<String, Map<String, dynamic>> entries;
  final Set<String> tombstoneIds;
  final int? revision;
}

class BookshelfGenerationManifest {
  BookshelfGenerationManifest({
    required this.generationId,
    required this.revision,
    required Set<String> recordIds,
  }) : recordIds = Set.unmodifiable(recordIds) {
    _requireIdentifier(generationId, 'generationId');
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    _requireRecordIds(recordIds);
  }

  final String generationId;
  final int revision;
  final Set<String> recordIds;

  factory BookshelfGenerationManifest.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != _bookshelfSchemaVersion ||
        json['completed'] != true) {
      throw const FormatException('Invalid bookshelf manifest.');
    }
    final generationId = json['generation_id'];
    final revision = json['revision'];
    final rawIds = json['record_ids'];
    if (generationId is! String || revision is! int || rawIds is! List) {
      throw const FormatException('Invalid bookshelf manifest.');
    }
    final ids = <String>{};
    for (final value in rawIds) {
      if (value is! String || !ids.add(value)) {
        throw const FormatException('Invalid bookshelf manifest records.');
      }
    }
    try {
      return BookshelfGenerationManifest(
        generationId: generationId,
        revision: revision,
        recordIds: ids,
      );
    } on ArgumentError {
      throw const FormatException('Invalid bookshelf manifest.');
    }
  }

  Map<String, dynamic> toJson() {
    final ids = recordIds.toList()..sort();
    return {
      'schema_version': _bookshelfSchemaVersion,
      'generation_id': generationId,
      'revision': revision,
      'record_ids': ids,
      'completed': true,
    };
  }

  bool hasSameContent(BookshelfGenerationManifest other) =>
      generationId == other.generationId &&
      revision == other.revision &&
      recordIds.length == other.recordIds.length &&
      recordIds.containsAll(other.recordIds);
}

class BookshelfGenerationRecord {
  BookshelfGenerationRecord._({
    required this.id,
    required this.revision,
    required this.deleted,
    required Map<String, dynamic> portable,
  }) : portable = Map.unmodifiable(portable) {
    _requireIdentifier(id, 'id');
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    final canonical = _validatePortable(portable);
    encodedBytes = utf8.encode(jsonEncode(canonical)).length;
    if (encodedBytes > _maxBookshelfRecordBytes) {
      throw const FormatException('Bookshelf record is too large.');
    }
    canonicalHash = _hashCanonicalRecord(
      deleted: deleted,
      canonicalPortable: canonical,
    );
  }

  factory BookshelfGenerationRecord.live({
    required String id,
    required int revision,
    required Map<String, dynamic> portable,
  }) => BookshelfGenerationRecord._(
    id: id,
    revision: revision,
    deleted: false,
    portable: portable,
  );

  factory BookshelfGenerationRecord.tombstone({
    required String id,
    required int revision,
  }) => BookshelfGenerationRecord._(
    id: id,
    revision: revision,
    deleted: true,
    portable: const {},
  );

  final String id;
  final int revision;
  final bool deleted;
  final Map<String, dynamic> portable;
  late final int encodedBytes;
  late final String canonicalHash;

  factory BookshelfGenerationRecord.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != _bookshelfSchemaVersion) {
      throw const FormatException('Invalid bookshelf generation record.');
    }
    final id = json['id'];
    final revision = json['revision'];
    final deleted = json['deleted'];
    final portable = json['portable'];
    final hash = json['canonical_hash'];
    if (id is! String ||
        revision is! int ||
        deleted is! bool ||
        portable is! Map ||
        hash is! String) {
      throw const FormatException('Invalid bookshelf generation record.');
    }
    final typedPortable = <String, dynamic>{};
    for (final entry in portable.entries) {
      if (entry.key is! String) {
        throw const FormatException('Invalid bookshelf generation record.');
      }
      typedPortable[entry.key as String] = entry.value;
    }
    late BookshelfGenerationRecord result;
    try {
      result = BookshelfGenerationRecord._(
        id: id,
        revision: revision,
        deleted: deleted,
        portable: typedPortable,
      );
    } on Object {
      throw const FormatException('Invalid bookshelf generation record.');
    }
    if (result.canonicalHash != hash ||
        (result.deleted && result.portable.isNotEmpty)) {
      throw const FormatException('Invalid bookshelf generation record hash.');
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'schema_version': _bookshelfSchemaVersion,
    'id': id,
    'revision': revision,
    'deleted': deleted,
    'portable': portable,
    'canonical_hash': canonicalHash,
  };
}

abstract interface class BookshelfGenerationRepository {
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid);

  Future<Map<String, dynamic>?> readGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
  });

  Future<Map<String, Map<String, dynamic>>> readLegacyParent(String uid);

  Future<Map<String, Map<String, dynamic>>> readLegacyEntries(String uid);

  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  });

  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  });
}

class BookshelfGenerationSync {
  const BookshelfGenerationSync._();

  static Future<BookshelfRemoteSnapshot> read(
    BookshelfGenerationRepository repository,
    String uid,
  ) async {
    _requireIdentifier(uid, 'uid');
    final manifest = await repository.readActiveManifest(uid);
    if (manifest == null) {
      final merged = await _readLegacy(repository, uid);
      return BookshelfRemoteSnapshot(
        source: BookshelfSnapshotSource.legacy,
        entries: Map.unmodifiable(merged),
        tombstoneIds: const {},
        revision: null,
      );
    }

    final visible = <String, Map<String, dynamic>>{};
    final tombstones = <String>{};
    var generationBytes = 0;
    final ids = manifest.recordIds.toList()..sort();
    for (final id in ids) {
      final raw = await repository.readGenerationRecord(
        uid: uid,
        generationId: manifest.generationId,
        recordId: id,
      );
      if (raw == null) {
        throw const FormatException(
          'Active bookshelf generation is incomplete.',
        );
      }
      final record = BookshelfGenerationRecord.fromJson(raw);
      generationBytes += record.encodedBytes;
      if (generationBytes > _maxBookshelfGenerationBytes) {
        throw const FormatException('Bookshelf generation is too large.');
      }
      if (record.id != id || record.revision != manifest.revision) {
        throw const FormatException('Invalid active bookshelf record.');
      }
      if (!record.deleted) {
        visible[id] = Map<String, dynamic>.from(record.portable);
      } else {
        tombstones.add(id);
      }
    }
    return BookshelfRemoteSnapshot(
      source: BookshelfSnapshotSource.activeGeneration,
      entries: Map.unmodifiable(visible),
      tombstoneIds: Set.unmodifiable(tombstones),
      revision: manifest.revision,
    );
  }

  static Future<BookshelfGenerationWriteResult> stageAndActivate({
    required BookshelfGenerationRepository repository,
    required String uid,
    required String generationId,
    required Map<String, Map<String, dynamic>> entries,
    required void Function() beforeWrite,
  }) async {
    _requireIdentifier(uid, 'uid');
    _requireIdentifier(generationId, 'generationId');
    _requireRecordIds(entries.keys.toSet());

    final active = await repository.readActiveManifest(uid);
    final selectedEntries = active == null
        ? {...await _readLegacy(repository, uid), ...entries}
        : entries;
    final expectedRevision = active?.revision ?? 0;
    final nextRevision = expectedRevision + 1;
    final recordIds = <String>{...?active?.recordIds, ...selectedEntries.keys};
    _requireRecordIds(recordIds);
    final activeTombstones = <String>{};
    if (active != null) {
      for (final id in active.recordIds) {
        final raw = await repository.readGenerationRecord(
          uid: uid,
          generationId: active.generationId,
          recordId: id,
        );
        if (raw == null) {
          throw const FormatException(
            'Active bookshelf generation is incomplete.',
          );
        }
        final record = BookshelfGenerationRecord.fromJson(raw);
        if (record.id != id || record.revision != active.revision) {
          throw const FormatException('Invalid active bookshelf record.');
        }
        if (record.deleted) activeTombstones.add(id);
      }
    }

    final records = <String, BookshelfGenerationRecord>{};
    var generationBytes = 0;
    final sortedIds = recordIds.toList()..sort();
    for (final id in sortedIds) {
      final portable = selectedEntries[id];
      final record = portable == null || activeTombstones.contains(id)
          ? BookshelfGenerationRecord.tombstone(id: id, revision: nextRevision)
          : BookshelfGenerationRecord.live(
              id: id,
              revision: nextRevision,
              portable: portable,
            );
      generationBytes += record.encodedBytes;
      if (generationBytes > _maxBookshelfGenerationBytes) {
        throw const FormatException('Bookshelf generation is too large.');
      }
      records[id] = record;
    }
    for (final id in sortedIds) {
      final record = records[id]!;
      beforeWrite();
      await repository.writeGenerationRecord(
        uid: uid,
        generationId: generationId,
        recordId: id,
        data: record.toJson(),
      );
    }

    final manifest = BookshelfGenerationManifest(
      generationId: generationId,
      revision: nextRevision,
      recordIds: recordIds,
    );
    beforeWrite();
    final activated = await repository.activateManifest(
      uid: uid,
      manifest: manifest,
      expectedRevision: expectedRevision,
    );
    return BookshelfGenerationWriteResult(
      activated
          ? BookshelfGenerationWriteStatus.activated
          : BookshelfGenerationWriteStatus.revisionConflict,
      revision: activated ? nextRevision : null,
    );
  }

  static Future<Map<String, Map<String, dynamic>>> _readLegacy(
    BookshelfGenerationRepository repository,
    String uid,
  ) async {
    final parent = await repository.readLegacyParent(uid);
    final entries = await repository.readLegacyEntries(uid);
    // The per-document collection was the newer legacy writer. Once it has
    // records, its survivor set is authoritative; stale parent-only records
    // must not be resurrected.
    final selected = entries.isNotEmpty ? entries : parent;
    _requireRecordIds(selected.keys.toSet());
    var totalBytes = 0;
    for (final entry in selected.entries) {
      final record = BookshelfGenerationRecord.live(
        id: entry.key,
        revision: 1,
        portable: entry.value,
      );
      totalBytes += record.encodedBytes;
      if (totalBytes > _maxBookshelfGenerationBytes) {
        throw const FormatException('Bookshelf generation is too large.');
      }
    }
    return Map.unmodifiable(selected);
  }
}

void _requireRecordIds(Set<String> recordIds) {
  if (recordIds.length > _maxBookshelfRecords) {
    throw const FormatException('Bookshelf generation is too large.');
  }
  for (final id in recordIds) {
    _requireIdentifier(id, 'recordId');
  }
}

void _requireIdentifier(String value, String name) {
  if (value.isEmpty ||
      utf8.encode(value).length > 256 ||
      value.contains('/') ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'is not a safe identifier');
  }
}

Map<String, dynamic> _validatePortable(Map<String, dynamic> portable) {
  final canonical = _validateAndCanonicalize(portable, depth: 0);
  if (canonical is! Map<String, dynamic>) {
    throw const FormatException('Invalid portable bookshelf entry.');
  }
  return canonical;
}

String _hashCanonicalRecord({
  required bool deleted,
  required Map<String, dynamic> canonicalPortable,
}) => sha256
    .convert(
      utf8.encode(
        jsonEncode({'deleted': deleted, 'portable': canonicalPortable}),
      ),
    )
    .toString();

Object? _validateAndCanonicalize(Object? value, {required int depth}) {
  if (depth > _maxBookshelfNestingDepth) {
    throw const FormatException('Bookshelf entry is nested too deeply.');
  }
  if (value is Map) {
    if (value.length > _maxBookshelfCollectionLength) {
      throw const FormatException('Bookshelf collection is too large.');
    }
    for (final key in value.keys) {
      if (key is! String ||
          utf8.encode(key).length > _maxBookshelfStringBytes) {
        throw const FormatException('Invalid bookshelf map key.');
      }
    }
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, dynamic>{
      for (final entry in entries)
        entry.key as String: _validateAndCanonicalize(
          entry.value,
          depth: depth + 1,
        ),
    };
  }
  if (value is List) {
    if (value.length > _maxBookshelfCollectionLength) {
      throw const FormatException('Bookshelf collection is too large.');
    }
    return value
        .map((item) => _validateAndCanonicalize(item, depth: depth + 1))
        .toList();
  }
  if (value is String) {
    if (utf8.encode(value).length > _maxBookshelfStringBytes) {
      throw const FormatException('Bookshelf string is too large.');
    }
    return value;
  }
  if (value is num && !value.isFinite) {
    throw const FormatException('Invalid bookshelf number.');
  }
  if (value == null || value is bool || value is num) return value;
  throw const FormatException('Invalid portable bookshelf value.');
}
