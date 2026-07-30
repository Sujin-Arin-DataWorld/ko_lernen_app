import 'dart:convert';

import 'package:crypto/crypto.dart';

const int _bookshelfSchemaVersion = 1;
const int _maxBookshelfRecords = 400;
const int _maxBookshelfRecordBytes = 256 * 1024;
const int _maxBookshelfGenerationBytes = 4 * 1024 * 1024;
const int _maxBookshelfStringBytes = 128 * 1024;
const int _maxBookshelfCollectionLength = 512;
const int _maxBookshelfNestingDepth = 16;
const int _maxBookshelfNodes = 4096;

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
    this.operationId,
    this.contentHash,
  }) : recordIds = Set.unmodifiable(recordIds) {
    _requireIdentifier(generationId, 'generationId');
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    _requireRecordIds(recordIds);
    if ((operationId == null) != (contentHash == null)) {
      throw ArgumentError(
        'Bookshelf manifest operation ID and content hash must be paired.',
      );
    }
    final selectedOperationId = operationId;
    final selectedContentHash = contentHash;
    if (selectedOperationId != null) {
      _requireIdentifier(selectedOperationId, 'operationId');
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(selectedContentHash!)) {
        throw ArgumentError.value(
          selectedContentHash,
          'contentHash',
          'must be a SHA-256 hash',
        );
      }
    }
  }

  final String generationId;
  final int revision;
  final Set<String> recordIds;
  final String? operationId;
  final String? contentHash;

  factory BookshelfGenerationManifest.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != _bookshelfSchemaVersion ||
        json['completed'] != true) {
      throw const FormatException('Invalid bookshelf manifest.');
    }
    final generationId = json['generation_id'];
    final revision = json['revision'];
    final rawIds = json['record_ids'];
    final operationId = json['operation_id'];
    final contentHash = json['content_hash'];
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
        operationId: operationId as String?,
        contentHash: contentHash as String?,
      );
    } on Object {
      throw const FormatException('Invalid bookshelf manifest.');
    }
  }

  Map<String, dynamic> toJson() {
    final ids = recordIds.toList()..sort();
    final json = <String, dynamic>{
      'schema_version': _bookshelfSchemaVersion,
      'generation_id': generationId,
      'revision': revision,
      'record_ids': ids,
      'completed': true,
    };
    final selectedOperationId = operationId;
    final selectedContentHash = contentHash;
    if (selectedOperationId != null && selectedContentHash != null) {
      json['operation_id'] = selectedOperationId;
      json['content_hash'] = selectedContentHash;
    }
    return json;
  }

  bool hasSameContent(BookshelfGenerationManifest other) =>
      generationId == other.generationId &&
      revision == other.revision &&
      operationId == other.operationId &&
      contentHash == other.contentHash &&
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
    String uid, {
    bool allowParentOnlyLegacy = false,
  }) async {
    _requireIdentifier(uid, 'uid');
    final manifest = await repository.readActiveManifest(uid);
    if (manifest == null) {
      final merged = await _readLegacy(
        repository,
        uid,
        allowParentOnlyLegacy: allowParentOnlyLegacy,
      );
      return BookshelfRemoteSnapshot(
        source: BookshelfSnapshotSource.legacy,
        entries: Map.unmodifiable(merged),
        tombstoneIds: const {},
        revision: null,
      );
    }

    final visible = <String, Map<String, dynamic>>{};
    final tombstones = <String>{};
    final records = <String, BookshelfGenerationRecord>{};
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
      records[id] = record;
      if (!record.deleted) {
        visible[id] = Map<String, dynamic>.from(record.portable);
      } else {
        tombstones.add(id);
      }
    }
    final expectedContentHash = manifest.contentHash;
    if (expectedContentHash != null &&
        _hashGenerationContent(records) != expectedContentHash) {
      throw const FormatException(
        'Active bookshelf generation content hash does not match.',
      );
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
    String? operationId,
    required Map<String, Map<String, dynamic>> entries,
    Set<String> deletedIds = const {},
    Set<String> revivedIds = const {},
    bool allowParentOnlyLegacy = false,
    required void Function() beforeWrite,
  }) async {
    _requireIdentifier(uid, 'uid');
    _requireIdentifier(generationId, 'generationId');
    _requireRecordIds(entries.keys.toSet());
    _requireRecordIds(deletedIds);
    _requireRecordIds(revivedIds);
    if (deletedIds.any(revivedIds.contains) ||
        !entries.keys.toSet().containsAll(revivedIds)) {
      throw const FormatException('Invalid bookshelf revival intent.');
    }
    if (operationId != null) {
      _requireIdentifier(operationId, 'operationId');
    }

    final active = await repository.readActiveManifest(uid);
    if (operationId != null && active?.operationId == operationId) {
      if (active?.contentHash == null) {
        throw const FormatException(
          'Completed bookshelf operation has no content hash.',
        );
      }
      await read(repository, uid);
      return BookshelfGenerationWriteResult(
        BookshelfGenerationWriteStatus.activated,
        revision: active!.revision,
      );
    }
    final expectedRevision = active?.revision ?? 0;
    final nextRevision = expectedRevision + 1;
    final activeEntries = <String, Map<String, dynamic>>{};
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
        if (record.deleted) {
          activeTombstones.add(id);
        } else {
          activeEntries[id] = record.portable;
        }
      }
    }
    final selectedEntries = active == null
        ? {
            ...await _readLegacy(
              repository,
              uid,
              allowParentOnlyLegacy: allowParentOnlyLegacy,
            ),
            ...entries,
          }
        : {...activeEntries, ...entries};
    final recordIds = <String>{
      ...?active?.recordIds,
      ...selectedEntries.keys,
      ...deletedIds,
    };
    _requireRecordIds(recordIds);

    final records = <String, BookshelfGenerationRecord>{};
    var generationBytes = 0;
    final sortedIds = recordIds.toList()..sort();
    for (final id in sortedIds) {
      final portable = selectedEntries[id];
      final record =
          portable == null ||
              deletedIds.contains(id) ||
              (activeTombstones.contains(id) && !revivedIds.contains(id))
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
      operationId: operationId,
      contentHash: operationId == null ? null : _hashGenerationContent(records),
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
    String uid, {
    required bool allowParentOnlyLegacy,
  }) async {
    final parent = await repository.readLegacyParent(uid);
    final entries = await repository.readLegacyEntries(uid);
    // The per-document collection was the newer legacy writer. Once it has
    // records, its survivor set is authoritative; stale parent-only records
    // must not be resurrected.
    if (entries.isEmpty && parent.isNotEmpty && !allowParentOnlyLegacy) {
      throw const FormatException(
        'Parent-only legacy bookshelf source is ambiguous.',
      );
    }
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
  _validatePortableStructure(portable, depth: 0, budget: _PortableBudget());
  final canonical = _canonicalizeValidated(portable);
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

void _validatePortableStructure(
  Object? value, {
  required int depth,
  required _PortableBudget budget,
}) {
  if (depth > _maxBookshelfNestingDepth) {
    throw const FormatException('Bookshelf entry is nested too deeply.');
  }
  budget.addNode();
  if (value is Map) {
    if (value.length > _maxBookshelfCollectionLength) {
      throw const FormatException('Bookshelf collection is too large.');
    }
    budget.addBytes(2);
    for (final key in value.keys) {
      if (key is! String ||
          utf8.encode(key).length > _maxBookshelfStringBytes) {
        throw const FormatException('Invalid bookshelf map key.');
      }
      budget.addBytes(utf8.encode(key).length + 4);
      _validatePortableStructure(value[key], depth: depth + 1, budget: budget);
    }
    return;
  }
  if (value is List) {
    if (value.length > _maxBookshelfCollectionLength) {
      throw const FormatException('Bookshelf collection is too large.');
    }
    budget.addBytes(2 + value.length);
    for (final item in value) {
      _validatePortableStructure(item, depth: depth + 1, budget: budget);
    }
    return;
  }
  if (value is String) {
    final bytes = utf8.encode(value).length;
    if (bytes > _maxBookshelfStringBytes) {
      throw const FormatException('Bookshelf string is too large.');
    }
    budget.addBytes(bytes + 2);
    return;
  }
  if (value is num && !value.isFinite) {
    throw const FormatException('Invalid bookshelf number.');
  }
  if (value == null || value is bool || value is num) {
    budget.addBytes(value.toString().length);
    return;
  }
  throw const FormatException('Invalid portable bookshelf value.');
}

Object? _canonicalizeValidated(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => (left.key as String).compareTo(right.key as String),
      );
    return <String, dynamic>{
      for (final entry in entries)
        entry.key as String: _canonicalizeValidated(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalizeValidated).toList();
  }
  return value;
}

String _hashGenerationContent(Map<String, BookshelfGenerationRecord> records) {
  final ids = records.keys.toList()..sort();
  return sha256
      .convert(
        utf8.encode(
          jsonEncode([
            for (final id in ids)
              {
                'id': id,
                'deleted': records[id]!.deleted,
                'canonical_hash': records[id]!.canonicalHash,
              },
          ]),
        ),
      )
      .toString();
}

class _PortableBudget {
  int nodes = 0;
  int bytes = 0;

  void addNode() {
    nodes += 1;
    if (nodes > _maxBookshelfNodes) {
      throw const FormatException('Bookshelf entry has too many nodes.');
    }
  }

  void addBytes(int count) {
    bytes += count;
    if (bytes > _maxBookshelfRecordBytes) {
      throw const FormatException('Bookshelf record is too large.');
    }
  }
}
