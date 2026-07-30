import 'dart:convert';

import 'package:crypto/crypto.dart';

const int _bookshelfSchemaVersion = 1;
const int _maxBookshelfRecords = 400;

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
    _validatePortable(portable);
    canonicalHash = _hashRecord(deleted: deleted, portable: portable);
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
    late BookshelfGenerationRecord result;
    try {
      result = BookshelfGenerationRecord._(
        id: id,
        revision: revision,
        deleted: deleted,
        portable: portable.map((key, value) => MapEntry(key.toString(), value)),
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
      final parent = await repository.readLegacyParent(uid);
      final entries = await repository.readLegacyEntries(uid);
      final merged = {...parent, ...entries};
      _requireRecordIds(merged.keys.toSet());
      return BookshelfRemoteSnapshot(
        source: BookshelfSnapshotSource.legacy,
        entries: Map.unmodifiable(merged),
        tombstoneIds: const {},
        revision: null,
      );
    }

    final visible = <String, Map<String, dynamic>>{};
    final tombstones = <String>{};
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
    final expectedRevision = active?.revision ?? 0;
    final nextRevision = expectedRevision + 1;
    final recordIds = <String>{...?active?.recordIds, ...entries.keys};
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

    final sortedIds = recordIds.toList()..sort();
    for (final id in sortedIds) {
      final portable = entries[id];
      final record = portable == null || activeTombstones.contains(id)
          ? BookshelfGenerationRecord.tombstone(id: id, revision: nextRevision)
          : BookshelfGenerationRecord.live(
              id: id,
              revision: nextRevision,
              portable: portable,
            );
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

void _validatePortable(Map<String, dynamic> portable) {
  try {
    jsonEncode(_canonicalize(portable));
  } on Object {
    throw const FormatException('Invalid portable bookshelf entry.');
  }
}

String _hashRecord({
  required bool deleted,
  required Map<String, dynamic> portable,
}) => sha256
    .convert(
      utf8.encode(
        jsonEncode({'deleted': deleted, 'portable': _canonicalize(portable)}),
      ),
    )
    .toString();

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalize).toList();
  }
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  throw const FormatException('Invalid portable bookshelf value.');
}
