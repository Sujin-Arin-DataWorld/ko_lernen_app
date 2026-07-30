import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

import 'account/cloud_write_session.dart';
import 'account/media_cleanup_gate.dart';
import 'media_mutation_lock.dart';
import 'storage_service.dart';

enum ManagedMediaKind { book, word }

class ManagedMediaRef {
  const ManagedMediaRef._(this.kind, this.fileName);

  final ManagedMediaKind kind;
  final String fileName;

  String get encoded => '${kind.name}:$fileName';

  static final RegExp _fileNamePattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9_-]{0,119}\.(?:jpe?g|png|webp|heic)$',
    caseSensitive: false,
  );

  static ManagedMediaRef parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid managed media reference.', value);
    }
    return parsed;
  }

  static ManagedMediaRef? tryParse(Object? value) {
    if (value is! String || value.isEmpty || value.contains('://')) {
      return null;
    }
    final separator = value.indexOf(':');
    if (separator <= 0 || separator != value.lastIndexOf(':')) {
      return null;
    }
    final kindName = value.substring(0, separator);
    final fileName = value.substring(separator + 1);
    final kind = switch (kindName) {
      'book' => ManagedMediaKind.book,
      'word' => ManagedMediaKind.word,
      _ => null,
    };
    if (kind == null ||
        fileName.contains('/') ||
        fileName.contains(r'\') ||
        fileName == '.' ||
        fileName == '..' ||
        !_fileNamePattern.hasMatch(fileName)) {
      return null;
    }
    return ManagedMediaRef._(kind, fileName);
  }

  @override
  bool operator ==(Object other) =>
      other is ManagedMediaRef && other.encoded == encoded;

  @override
  int get hashCode => encoded.hashCode;

  @override
  String toString() => encoded;
}

class PendingMediaLease {
  const PendingMediaLease._({required this.kind, required this.fileName});

  final ManagedMediaKind kind;
  final String fileName;

  String get encoded => 'pending:${kind.name}:$fileName';

  static PendingMediaLease? tryParse(Object? value) {
    if (value is! String) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 3 || parts.first != 'pending') {
      return null;
    }
    final kind = switch (parts[1]) {
      'book' => ManagedMediaKind.book,
      'word' => ManagedMediaKind.word,
      _ => null,
    };
    if (kind == null ||
        !RegExp(
          '^p_${kind.name}_[A-Za-z0-9_-]+\\.(?:jpe?g|png|webp|heic)\$',
          caseSensitive: false,
        ).hasMatch(parts[2])) {
      return null;
    }
    return PendingMediaLease._(kind: kind, fileName: parts[2]);
  }
}

enum RecoveredBookPhase { picked, cropped }

class RecoveredBookDraft {
  const RecoveredBookDraft({
    required this.workflowId,
    required this.lease,
    required this.phase,
  });

  final String workflowId;
  final PendingMediaLease lease;
  final RecoveredBookPhase phase;

  String get encoded => jsonEncode({
    'workflowId': workflowId,
    'lease': lease.encoded,
    'phase': phase.name,
  });

  static RecoveredBookDraft? tryParse(Object? source) {
    try {
      final decoded = source is String ? jsonDecode(source) : source;
      if (decoded is! Map ||
          decoded['workflowId'] is! String ||
          (decoded['workflowId'] as String).isEmpty) {
        return null;
      }
      final lease = PendingMediaLease.tryParse(decoded['lease']);
      if (lease == null || lease.kind != ManagedMediaKind.book) {
        return null;
      }
      final phase = switch (decoded['phase']) {
        null => RecoveredBookPhase.picked,
        'picked' => RecoveredBookPhase.picked,
        'cropped' => RecoveredBookPhase.cropped,
        _ => null,
      };
      return phase == null
          ? null
          : RecoveredBookDraft(
              workflowId: decoded['workflowId'] as String,
              lease: lease,
              phase: phase,
            );
    } on Object {
      return null;
    }
  }
}

class ManagedMediaPromotion {
  const ManagedMediaPromotion._({required this.lease, required this.reference});

  final PendingMediaLease lease;
  final ManagedMediaRef reference;
}

class ManagedMediaReferenceSnapshot {
  const ManagedMediaReferenceSnapshot.valid(this.references)
    : isComplete = true;

  const ManagedMediaReferenceSnapshot.invalid()
    : isComplete = false,
      references = const {};

  final bool isComplete;
  final Map<String, int> references;

  bool contains(ManagedMediaRef reference) =>
      (references[reference.encoded] ?? 0) > 0;

  static ManagedMediaReferenceSnapshot fromJson({
    required String bookshelfJson,
    required String customPacksJson,
  }) {
    final counts = <String, int>{};
    try {
      final bookshelf = _strictTopLevelMap(bookshelfJson);
      final packs = _strictTopLevelMap(customPacksJson);
      for (final value in bookshelf.values) {
        final page = _strictEntry(value);
        _collectNullableRef(
          page,
          'localThumbnailPath',
          ManagedMediaKind.book,
          counts,
        );
        _collectWords(page, counts);
      }
      for (final value in packs.values) {
        final pack = _strictEntry(value);
        _collectWords(pack, counts);
      }
      return ManagedMediaReferenceSnapshot.valid(
        Map<String, int>.unmodifiable(counts),
      );
    } on Object {
      return const ManagedMediaReferenceSnapshot.invalid();
    }
  }

  static Map<String, dynamic> _strictTopLevelMap(String source) {
    if (source.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Expected media reference map.');
    }
    final result = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw const FormatException('Expected string media owner id.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static Map<String, dynamic> _strictEntry(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected media owner entry.');
    }
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('Expected string media field.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static void _collectWords(
    Map<String, dynamic> owner,
    Map<String, int> counts,
  ) {
    if (!owner.containsKey('words')) {
      return;
    }
    final words = owner['words'];
    if (words is! List) {
      throw const FormatException('Expected words list.');
    }
    for (final value in words) {
      final word = _strictEntry(value);
      _collectNullableRef(word, 'imagePath', ManagedMediaKind.word, counts);
    }
  }

  static void _collectNullableRef(
    Map<String, dynamic> owner,
    String key,
    ManagedMediaKind expectedKind,
    Map<String, int> counts,
  ) {
    if (!owner.containsKey(key)) {
      return;
    }
    final value = owner[key];
    if (value == null || value == '') {
      return;
    }
    final reference = ManagedMediaRef.tryParse(value);
    if (reference == null || reference.kind != expectedKind) {
      throw const FormatException('Invalid local media reference.');
    }
    counts.update(reference.encoded, (count) => count + 1, ifAbsent: () => 1);
  }
}

class ManagedMediaStore {
  ManagedMediaStore({
    required this.documentsDirectory,
    required this.temporaryDirectory,
    this.sessions,
    this.readJournal,
    DateTime Function()? now,
    String Function()? nonce,
  }) : _now = now ?? DateTime.now,
       _nonce = nonce ?? _randomNonce;

  final Directory documentsDirectory;
  final Directory temporaryDirectory;
  final CloudWriteSessionController? sessions;
  final AccountTransitionJournalReader? readJournal;
  final DateTime Function() _now;
  final String Function() _nonce;
  int _sequence = 0;

  Directory get root => Directory(
    '${documentsDirectory.path}${Platform.pathSeparator}'
    'hangul_sori_media',
  );

  Directory get _pendingDirectory =>
      Directory('${root.path}${Platform.pathSeparator}pending');

  Directory _kindDirectory(ManagedMediaKind kind) =>
      Directory('${root.path}${Platform.pathSeparator}${kind.name}');

  static String _randomNonce() {
    final random = math.Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_'
        '${random.nextInt(1 << 31).toRadixString(36)}';
  }

  String _nextToken() => '${_nonce()}_${_sequence++}';

  Future<PendingMediaLease> stage(
    File source,
    ManagedMediaKind kind, {
    bool deleteTrustedTemporarySource = false,
  }) async {
    if (!await source.exists()) {
      throw FileSystemException('Media source does not exist.', source.path);
    }
    final extension = _allowedExtension(source.path);
    if (extension == null) {
      throw FormatException('Unsupported media extension.', source.path);
    }
    if (!await _ensureManagedDirectory(_pendingDirectory)) {
      throw StateError('Pending media directory escaped the managed root.');
    }
    final lease = PendingMediaLease._(
      kind: kind,
      fileName: 'p_${kind.name}_${_nextToken()}.$extension',
    );
    final destination = pendingFile(lease);
    try {
      await source.copy(destination.path);
    } on Object {
      if (await _isManagedContained(destination, _pendingDirectory)) {
        try {
          await destination.delete();
        } on Object {
          // Reconciliation retries cleanup if the partial copy is locked.
        }
      }
      rethrow;
    }
    if (deleteTrustedTemporarySource &&
        await _isContainedExisting(source, temporaryDirectory)) {
      try {
        await source.delete();
      } on Object {
        // The managed copy is complete and owns the data. Cache cleanup is
        // best effort and must not hide the returned lease from its caller.
      }
    }
    return lease;
  }

  Future<PendingMediaLease?> stageTrustedTemporary(
    File source,
    ManagedMediaKind kind, {
    bool deleteSource = true,
  }) async {
    late final File canonicalSource;
    try {
      if (!await _isContainedExisting(source, temporaryDirectory)) {
        return null;
      }
      canonicalSource = File(await source.resolveSymbolicLinks());
      if (!await _isContainedExisting(canonicalSource, temporaryDirectory)) {
        return null;
      }
    } on FileSystemException {
      return null;
    }
    return stage(
      canonicalSource,
      kind,
      deleteTrustedTemporarySource: deleteSource,
    );
  }

  Future<void> deleteTrustedTemporary(File source) async {
    try {
      if (!await _isContainedExisting(source, temporaryDirectory)) {
        return;
      }
      final canonicalSource = File(await source.resolveSymbolicLinks());
      if (await _isContainedExisting(canonicalSource, temporaryDirectory)) {
        await canonicalSource.delete();
      }
    } on Object {
      // Application cache cleanup is best effort after durable ownership.
    }
  }

  Future<PendingMediaLease?> findRecoveredCrop(String workflowId) async {
    if (workflowId.isEmpty) {
      return null;
    }
    final token = sha256.convert(utf8.encode(workflowId)).toString();
    for (final extension in const ['jpg', 'jpeg', 'png', 'webp', 'heic']) {
      final lease = PendingMediaLease._(
        kind: ManagedMediaKind.book,
        fileName: 'p_book_recovery_$token.$extension',
      );
      final file = pendingFile(lease);
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
              FileSystemEntityType.file &&
          await _isManagedContained(file, _pendingDirectory)) {
        return lease;
      }
    }
    return null;
  }

  Future<PendingMediaLease?> stageRecoveredCrop(
    File source,
    String workflowId,
  ) async {
    if (workflowId.isEmpty) {
      throw const FormatException('Missing crop recovery workflow.');
    }
    final existing = await findRecoveredCrop(workflowId);
    if (existing != null) {
      return existing;
    }
    late final File canonicalSource;
    try {
      if (await FileSystemEntity.type(source.path, followLinks: false) !=
              FileSystemEntityType.file ||
          !await _isContainedExisting(source, temporaryDirectory)) {
        return null;
      }
      canonicalSource = File(await source.resolveSymbolicLinks());
      if (await FileSystemEntity.type(
                canonicalSource.path,
                followLinks: false,
              ) !=
              FileSystemEntityType.file ||
          !await _isContainedExisting(canonicalSource, temporaryDirectory)) {
        return null;
      }
    } on FileSystemException {
      return null;
    }
    final extension = _allowedExtension(canonicalSource.path);
    if (extension == null) {
      throw FormatException(
        'Unsupported media extension.',
        canonicalSource.path,
      );
    }
    if (!await _ensureManagedDirectory(_pendingDirectory)) {
      throw StateError('Pending media directory escaped the managed root.');
    }
    final token = sha256.convert(utf8.encode(workflowId)).toString();
    final lease = PendingMediaLease._(
      kind: ManagedMediaKind.book,
      fileName: 'p_book_recovery_$token.$extension',
    );
    final destination = pendingFile(lease);
    final partial = File('${destination.path}.part');
    final destinationType = await FileSystemEntity.type(
      destination.path,
      followLinks: false,
    );
    if (destinationType != FileSystemEntityType.notFound) {
      if (destinationType == FileSystemEntityType.file &&
          await _isManagedContained(destination, _pendingDirectory)) {
        return lease;
      }
      throw StateError('Crop recovery journal path is unsafe.');
    }
    final partialType = await FileSystemEntity.type(
      partial.path,
      followLinks: false,
    );
    if (partialType != FileSystemEntityType.notFound) {
      if (partialType != FileSystemEntityType.file ||
          !await _isManagedContained(partial, _pendingDirectory)) {
        throw StateError('Crop recovery partial path is unsafe.');
      }
      await partial.delete();
    }
    try {
      await canonicalSource.copy(partial.path);
      if (!await _isManagedContained(partial, _pendingDirectory)) {
        throw StateError('Crop recovery partial escaped the managed root.');
      }
      await partial.rename(destination.path);
      if (await FileSystemEntity.type(destination.path, followLinks: false) !=
              FileSystemEntityType.file ||
          !await _isManagedContained(destination, _pendingDirectory)) {
        throw StateError('Crop recovery journal escaped the managed root.');
      }
      return lease;
    } on Object {
      if (await _isManagedContained(partial, _pendingDirectory)) {
        try {
          await partial.delete();
        } on Object {
          // Reconciliation retries cleanup if the partial journal is locked.
        }
      }
      rethrow;
    }
  }

  Future<PendingMediaLease?> findRecoveredPicker(
    String workflowId,
    ManagedMediaKind kind,
  ) async {
    if (workflowId.isEmpty) {
      return null;
    }
    final token = sha256
        .convert(utf8.encode('${kind.name}:$workflowId'))
        .toString();
    for (final extension in const ['jpg', 'jpeg', 'png', 'webp', 'heic']) {
      final lease = PendingMediaLease._(
        kind: kind,
        fileName: 'p_${kind.name}_picker_$token.$extension',
      );
      final file = pendingFile(lease);
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
              FileSystemEntityType.file &&
          await _isManagedContained(file, _pendingDirectory)) {
        return lease;
      }
    }
    return null;
  }

  Future<PendingMediaLease?> stageRecoveredPicker(
    File source,
    String workflowId,
    ManagedMediaKind kind,
  ) async {
    if (workflowId.isEmpty) {
      throw const FormatException('Missing picker recovery workflow.');
    }
    final existing = await findRecoveredPicker(workflowId, kind);
    if (existing != null) {
      return existing;
    }
    late final File canonicalSource;
    try {
      if (await FileSystemEntity.type(source.path, followLinks: false) !=
              FileSystemEntityType.file ||
          !await _isContainedExisting(source, temporaryDirectory)) {
        return null;
      }
      canonicalSource = File(await source.resolveSymbolicLinks());
      if (await FileSystemEntity.type(
                canonicalSource.path,
                followLinks: false,
              ) !=
              FileSystemEntityType.file ||
          !await _isContainedExisting(canonicalSource, temporaryDirectory)) {
        return null;
      }
    } on FileSystemException {
      return null;
    }
    final extension = _allowedExtension(canonicalSource.path);
    if (extension == null) {
      throw FormatException(
        'Unsupported media extension.',
        canonicalSource.path,
      );
    }
    if (!await _ensureManagedDirectory(_pendingDirectory)) {
      throw StateError('Pending media directory escaped the managed root.');
    }
    final token = sha256
        .convert(utf8.encode('${kind.name}:$workflowId'))
        .toString();
    final lease = PendingMediaLease._(
      kind: kind,
      fileName: 'p_${kind.name}_picker_$token.$extension',
    );
    final destination = pendingFile(lease);
    final partial = File('${destination.path}.part');
    final destinationType = await FileSystemEntity.type(
      destination.path,
      followLinks: false,
    );
    if (destinationType != FileSystemEntityType.notFound) {
      if (destinationType == FileSystemEntityType.file &&
          await _isManagedContained(destination, _pendingDirectory)) {
        return lease;
      }
      throw StateError('Picker recovery journal path is unsafe.');
    }
    final partialType = await FileSystemEntity.type(
      partial.path,
      followLinks: false,
    );
    if (partialType != FileSystemEntityType.notFound) {
      if (partialType != FileSystemEntityType.file ||
          !await _isManagedContained(partial, _pendingDirectory)) {
        throw StateError('Picker recovery partial path is unsafe.');
      }
      await partial.delete();
    }
    try {
      await canonicalSource.copy(partial.path);
      if (!await _isManagedContained(partial, _pendingDirectory)) {
        throw StateError('Picker recovery partial escaped the managed root.');
      }
      await partial.rename(destination.path);
      if (await FileSystemEntity.type(destination.path, followLinks: false) !=
              FileSystemEntityType.file ||
          !await _isManagedContained(destination, _pendingDirectory)) {
        throw StateError('Picker recovery journal escaped the managed root.');
      }
      return lease;
    } on Object {
      if (await _isManagedContained(partial, _pendingDirectory)) {
        try {
          await partial.delete();
        } on Object {
          // Reconciliation retries cleanup if the partial journal is locked.
        }
      }
      rethrow;
    }
  }

  File pendingFile(PendingMediaLease lease) => File(
    '${_pendingDirectory.path}${Platform.pathSeparator}${lease.fileName}',
  );

  Future<File?> resolvePending(PendingMediaLease lease) async {
    final file = pendingFile(lease);
    return await _isManagedContained(file, _pendingDirectory) ? file : null;
  }

  Future<ManagedMediaPromotion> promote(PendingMediaLease lease) async {
    final source = pendingFile(lease);
    if (!await _isManagedContained(source, _pendingDirectory)) {
      throw StateError('Pending media lease is missing or unsafe.');
    }
    final extension = _allowedExtension(lease.fileName)!;
    final reference = ManagedMediaRef._(
      lease.kind,
      'm_${_nextToken()}.$extension',
    );
    final directory = _kindDirectory(lease.kind);
    if (!await _ensureManagedDirectory(directory)) {
      throw StateError('Committed media directory escaped the managed root.');
    }
    final destination = File(pathForTesting(reference));
    try {
      await source.copy(destination.path);
      return ManagedMediaPromotion._(lease: lease, reference: reference);
    } on Object {
      if (await _isManagedContained(destination, directory)) {
        await destination.delete();
      }
      rethrow;
    }
  }

  Future<void> finalize(ManagedMediaPromotion promotion) async {
    final resolved = await resolve(promotion.reference);
    if (resolved == null) {
      throw StateError('Promoted media disappeared before finalization.');
    }
    await discard(promotion.lease);
  }

  Future<void> finalizeAfterPersistence(ManagedMediaPromotion promotion) async {
    try {
      await finalize(promotion);
    } on Object {
      // The strict model write is already the source of truth. Startup
      // reconciliation cleans a leftover pending file, while a missing
      // committed file safely degrades to the UI image fallback.
    }
  }

  Future<void> rollback(ManagedMediaPromotion promotion) async {
    await deleteCommitted(promotion.reference);
  }

  Future<void> discard(PendingMediaLease lease) async {
    final file = pendingFile(lease);
    if (await _isManagedContained(file, _pendingDirectory)) {
      await file.delete();
    }
  }

  String pathForTesting(ManagedMediaRef reference) =>
      '${_kindDirectory(reference.kind).path}${Platform.pathSeparator}'
      '${reference.fileName}';

  Future<File?> resolve(ManagedMediaRef reference) async {
    final file = File(pathForTesting(reference));
    return await _isManagedContained(file, _kindDirectory(reference.kind))
        ? file
        : null;
  }

  Future<void> deleteCommitted(ManagedMediaRef reference) async {
    final file = await resolve(reference);
    if (file != null) {
      await file.delete();
    }
  }

  Future<void> deleteIfUnreferenced(
    ManagedMediaRef reference,
    ManagedMediaReferenceSnapshot snapshot,
  ) async {
    await _runGarbageCollection((session) async {
      if (snapshot.isComplete && !snapshot.contains(reference)) {
        await _deleteCommittedForGarbageCollection(reference, session);
      }
    });
  }

  Future<List<File>> listCommitted(ManagedMediaKind kind) async {
    final directory = _kindDirectory(kind);
    if (!await directory.exists() ||
        !await _isSafeManagedDirectory(directory)) {
      return const [];
    }
    final files = <File>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final reference = ManagedMediaRef.tryParse(
        '${kind.name}:${_basename(entity.path)}',
      );
      if (reference != null && await resolve(reference) != null) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<void> reconcile({
    required ManagedMediaReferenceSnapshot snapshot,
    Duration pendingTtl = const Duration(days: 2),
  }) async {
    await _runGarbageCollection(
      (session) => _reconcileUnfenced(
        snapshot: snapshot,
        pendingTtl: pendingTtl,
        session: session,
      ),
    );
  }

  Future<void> _reconcileUnfenced({
    required ManagedMediaReferenceSnapshot snapshot,
    required Duration pendingTtl,
    required CloudWriteSession? session,
  }) async {
    if (await root.exists() && !await _isSafeManagedDirectory(root)) {
      return;
    }
    if (await _pendingDirectory.exists() &&
        await _isSafeManagedDirectory(_pendingDirectory)) {
      final cutoff = _now().subtract(pendingTtl);
      await for (final entity in _pendingDirectory.list(followLinks: false)) {
        if (entity is! File ||
            !await _isManagedContained(entity, _pendingDirectory)) {
          continue;
        }
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          if (_garbageCollectionSessionIsCurrent(session)) {
            await entity.delete();
          }
        }
      }
    }
    if (!snapshot.isComplete) {
      return;
    }
    for (final kind in ManagedMediaKind.values) {
      for (final file in await listCommitted(kind)) {
        final reference = ManagedMediaRef.parse(
          '${kind.name}:${_basename(file.path)}',
        );
        if (!snapshot.contains(reference)) {
          await _deleteCommittedForGarbageCollection(reference, session);
        }
      }
    }
  }

  Future<void> _runGarbageCollection(
    Future<void> Function(CloudWriteSession? session) action,
  ) async {
    final controller = sessions;
    if (controller == null) {
      await action(null);
      return;
    }
    final current = controller.current;
    await MediaCleanupGate(controller).run(
      uid: current?.uid,
      session: current,
      readJournal:
          readJournal ??
          const SharedPreferencesAccountTransitionJournalReader().call,
      prepare: () async {},
      delete: () => action(current),
    );
  }

  Future<void> _deleteCommittedForGarbageCollection(
    ManagedMediaRef reference,
    CloudWriteSession? session,
  ) async {
    final file = await resolve(reference);
    if (file != null && _garbageCollectionSessionIsCurrent(session)) {
      await file.delete();
    }
  }

  bool _garbageCollectionSessionIsCurrent(CloudWriteSession? session) {
    final controller = sessions;
    if (session == null) {
      return controller == null;
    }
    try {
      controller!.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }

  Future<ManagedMediaRef?> migrateTrustedLegacy(
    String storedValue,
    ManagedMediaKind kind,
  ) async {
    final alreadyManaged = ManagedMediaRef.tryParse(storedValue);
    if (alreadyManaged != null) {
      return alreadyManaged.kind == kind ? alreadyManaged : null;
    }
    final normalized = storedValue.replaceAll(r'\', '/');
    final basename = normalized.split('/').last;
    if (!ManagedMediaRef._fileNamePattern.hasMatch(basename)) {
      return null;
    }
    final legacyDirectoryName = kind == ManagedMediaKind.word
        ? 'wordbook_images'
        : 'book_images';
    final mentionsLegacyDirectory = normalized
        .split('/')
        .contains(legacyDirectoryName);
    File? trustedSource;
    if (mentionsLegacyDirectory) {
      final normalizedDocuments = documentsDirectory.path.replaceAll(r'\', '/');
      final isCurrentLegacyPath = normalized.startsWith(
        '$normalizedDocuments/$legacyDirectoryName/',
      );
      final isStaleIosContainerPath = RegExp(
        '^/(?:private/)?var/mobile/Containers/Data/Application/'
        '[A-Za-z0-9-]+/Documents/$legacyDirectoryName/',
      ).hasMatch(normalized);
      if (!isCurrentLegacyPath && !isStaleIosContainerPath) {
        return null;
      }
      final legacyDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}'
        '$legacyDirectoryName',
      );
      final candidate = File(
        '${legacyDirectory.path}${Platform.pathSeparator}$basename',
      );
      final legacyIsInsideDocuments =
          await legacyDirectory.exists() &&
          await documentsDirectory.exists() &&
          await FileSystemEntity.type(
                legacyDirectory.path,
                followLinks: false,
              ) !=
              FileSystemEntityType.link &&
          _samePath(
            await legacyDirectory.resolveSymbolicLinks(),
            '${await documentsDirectory.resolveSymbolicLinks()}'
            '${Platform.pathSeparator}$legacyDirectoryName',
          );
      if (legacyIsInsideDocuments &&
          await _isContainedExisting(candidate, legacyDirectory)) {
        trustedSource = candidate;
      }
    } else if (kind == ManagedMediaKind.book) {
      final candidate = File(storedValue);
      if (await _isContainedExisting(candidate, temporaryDirectory)) {
        trustedSource = candidate;
      }
    }
    if (trustedSource == null) {
      return null;
    }
    PendingMediaLease? lease;
    ManagedMediaPromotion? promotion;
    try {
      lease = await stage(trustedSource, kind);
      promotion = await promote(lease);
      await finalize(promotion);
      return promotion.reference;
    } on Object {
      if (promotion != null) {
        try {
          await rollback(promotion);
        } on Object {
          // Startup reconciliation retries committed-file cleanup.
        }
      }
      if (lease != null) {
        try {
          await discard(lease);
        } on Object {
          // Pending TTL reconciliation retries cleanup.
        }
      }
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await deleteAllStrict();
    } on Object {
      // Ordinary reset is intentionally best effort.
    }
  }

  Future<void> deleteAllStrict() async {
    if (await root.exists()) {
      if (!await _isSafeManagedDirectory(root)) {
        throw StateError('Managed media root escaped application documents.');
      }
      await root.delete(recursive: true);
    }
  }

  static String? _allowedExtension(String path) {
    final basename = _basename(path);
    final dot = basename.lastIndexOf('.');
    if (dot <= 0 || dot == basename.length - 1) {
      return null;
    }
    final extension = basename.substring(dot + 1).toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)
        ? extension
        : null;
  }

  static String _basename(String path) =>
      path.replaceAll(r'\', '/').split('/').last;

  static Future<bool> _isContainedExisting(
    FileSystemEntity entity,
    Directory expectedRoot,
  ) async {
    try {
      if (!await entity.exists() && entity is! Link) {
        return false;
      }
      if (!await expectedRoot.exists()) {
        return false;
      }
      final rootPath = await expectedRoot.resolveSymbolicLinks();
      final entityPath = await entity.resolveSymbolicLinks();
      return _isWithin(entityPath, rootPath);
    } on FileSystemException {
      return false;
    }
  }

  Future<bool> _isSafeManagedDirectory(Directory directory) async {
    try {
      if (!await documentsDirectory.exists() ||
          !await root.exists() ||
          !await directory.exists()) {
        return false;
      }
      if (await FileSystemEntity.type(root.path, followLinks: false) ==
              FileSystemEntityType.link ||
          await FileSystemEntity.type(directory.path, followLinks: false) ==
              FileSystemEntityType.link) {
        return false;
      }
      final documentsPath = await documentsDirectory.resolveSymbolicLinks();
      final rootPath = await root.resolveSymbolicLinks();
      final directoryPath = await directory.resolveSymbolicLinks();
      final expectedRootPath =
          '$documentsPath${Platform.pathSeparator}hangul_sori_media';
      if (!_samePath(rootPath, expectedRootPath) ||
          _samePath(rootPath, documentsPath)) {
        return false;
      }
      if (_samePath(directory.path, root.path)) {
        return _samePath(directoryPath, rootPath);
      }
      final childName = _basename(directory.path);
      if (!const {'pending', 'book', 'word'}.contains(childName)) {
        return false;
      }
      final expectedDirectoryPath =
          '$rootPath${Platform.pathSeparator}$childName';
      return _samePath(directoryPath, expectedDirectoryPath) &&
          !_samePath(directoryPath, rootPath);
    } on FileSystemException {
      return false;
    }
  }

  Future<bool> _ensureManagedDirectory(Directory directory) async {
    try {
      if (!await documentsDirectory.exists()) {
        return false;
      }
      if (await root.exists()) {
        if (!await _isSafeManagedDirectory(root)) {
          return false;
        }
      } else {
        await root.create();
        if (!await _isSafeManagedDirectory(root)) {
          return false;
        }
      }
      if (directory.path == root.path) {
        return true;
      }
      if (await directory.exists()) {
        return _isSafeManagedDirectory(directory);
      }
      await directory.create();
      return _isSafeManagedDirectory(directory);
    } on FileSystemException {
      return false;
    }
  }

  Future<bool> _isManagedContained(
    FileSystemEntity entity,
    Directory expectedDirectory,
  ) async {
    if (!await _isSafeManagedDirectory(expectedDirectory)) {
      return false;
    }
    try {
      if (!await entity.exists() && entity is! Link) {
        return false;
      }
      final entityPath = await entity.resolveSymbolicLinks();
      final expectedPath = await expectedDirectory.resolveSymbolicLinks();
      final rootPath = await root.resolveSymbolicLinks();
      final documentsPath = await documentsDirectory.resolveSymbolicLinks();
      return _isWithin(entityPath, expectedPath) &&
          _isWithin(entityPath, rootPath) &&
          _isWithin(entityPath, documentsPath);
    } on FileSystemException {
      return false;
    }
  }

  static bool _isWithin(String path, String rootPath) {
    final root = _normalizePath(rootPath);
    final child = _normalizePath(path);
    return child == root || child.startsWith('$root/');
  }

  static bool _samePath(String first, String second) =>
      _normalizePath(first) == _normalizePath(second);

  static String _normalizePath(String value) {
    var normalized = value.replaceAll(r'\', '/');
    if (Platform.isWindows) {
      normalized = normalized.toLowerCase();
    }
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }
}

class BookImageService {
  static ManagedMediaStore? _store;

  static Future<ManagedMediaStore> get store async {
    final existing = _store;
    if (existing != null) {
      return existing;
    }
    final created = ManagedMediaStore(
      documentsDirectory: await getApplicationDocumentsDirectory(),
      temporaryDirectory: await getTemporaryDirectory(),
      sessions: cloudWriteSessionController,
    );
    _store = created;
    return created;
  }

  @visibleForTesting
  static void setStoreForTesting(ManagedMediaStore? store) {
    _store = store;
  }

  static Future<PendingMediaLease> stageCrop(String path) async {
    final mediaStore = await store;
    final lease = await mediaStore.stageTrustedTemporary(
      File(path),
      ManagedMediaKind.book,
    );
    if (lease == null) {
      throw StateError('Crop output escaped the application cache.');
    }
    return lease;
  }

  static Future<void> discardEncoded(String? encoded) async {
    final lease = PendingMediaLease.tryParse(encoded);
    if (lease != null) {
      await (await store).discard(lease);
    }
  }

  static Future<File?> resolve(String? encoded) async {
    final reference = ManagedMediaRef.tryParse(encoded);
    return reference == null ? null : (await store).resolve(reference);
  }

  static Future<void> deleteAll() async => (await store).deleteAll();

  static Future<void> deleteAllStrict() async =>
      (await store).deleteAllStrict();

  static Future<void> initialize({
    Future<void> Function(String value)? writeBookshelf,
    Future<void> Function(String value)? writeCustomPacks,
  }) async {
    final persistBookshelf =
        writeBookshelf ?? Storage.setBookshelfRawJsonStrict;
    final persistCustomPacks =
        writeCustomPacks ?? Storage.setCustomPacksRawJsonStrict;
    await MediaMutationLock.run(() async {
      final mediaStore = await store;
      final originalBookshelf = Storage.bookshelfRawJson;
      final originalPacks = Storage.customPacksRawJson;
      if (!_isStructurallyValid(originalBookshelf) ||
          !_isStructurallyValid(originalPacks)) {
        await mediaStore.reconcile(
          snapshot: const ManagedMediaReferenceSnapshot.invalid(),
        );
        return;
      }
      final existingFiles = <String>{};
      for (final kind in ManagedMediaKind.values) {
        existingFiles.addAll(
          (await mediaStore.listCommitted(kind)).map((file) => file.path),
        );
      }
      try {
        final migratedBookshelf = await _migrateCollection(
          originalBookshelf,
          mediaStore,
          isBookshelf: true,
        );
        final migratedPacks = await _migrateCollection(
          originalPacks,
          mediaStore,
          isBookshelf: false,
        );
        if (migratedBookshelf == null || migratedPacks == null) {
          throw StateError('Validated media collection changed shape.');
        }
        if (migratedBookshelf.json != originalBookshelf) {
          await persistBookshelf(migratedBookshelf.json);
        }
        if (migratedPacks.json != originalPacks) {
          await persistCustomPacks(migratedPacks.json);
        }
        final snapshot =
            migratedBookshelf.isComplete && migratedPacks.isComplete
            ? ManagedMediaReferenceSnapshot.fromJson(
                bookshelfJson: migratedBookshelf.json,
                customPacksJson: migratedPacks.json,
              )
            : const ManagedMediaReferenceSnapshot.invalid();
        await mediaStore.reconcile(snapshot: snapshot);
      } on PreferenceOutcomeUnknownException {
        // A migrated or original preference value may be durable. Preserve all
        // old and newly migrated media and avoid compensating preference writes
        // until a later startup can refresh the platform store.
        rethrow;
      } on Object {
        var restored = true;
        try {
          await persistBookshelf(originalBookshelf);
          await persistCustomPacks(originalPacks);
        } on Object {
          restored = false;
        }
        if (restored) {
          for (final kind in ManagedMediaKind.values) {
            for (final file in await mediaStore.listCommitted(kind)) {
              if (!existingFiles.contains(file.path)) {
                final reference = ManagedMediaRef.parse(
                  '${kind.name}:${ManagedMediaStore._basename(file.path)}',
                );
                await mediaStore.deleteCommitted(reference);
              }
            }
          }
        }
        rethrow;
      }
    });
  }

  static bool _isStructurallyValid(String source) {
    if (source.trim().isEmpty) {
      return true;
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return false;
      }
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! Map) {
          return false;
        }
        for (final field in (entry.value as Map).entries) {
          if (field.key is! String) {
            return false;
          }
        }
        final words = (entry.value as Map)['words'];
        if (words != null) {
          if (words is! List) {
            return false;
          }
          for (final word in words) {
            if (word is! Map || word.keys.any((key) => key is! String)) {
              return false;
            }
          }
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  static Future<_MigratedCollection?> _migrateCollection(
    String source,
    ManagedMediaStore mediaStore, {
    required bool isBookshelf,
  }) async {
    if (source.trim().isEmpty) {
      return _MigratedCollection(json: source, isComplete: true);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return null;
      }
      final result = <String, dynamic>{};
      var isComplete = true;
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! Map) {
          return null;
        }
        final owner = <String, dynamic>{};
        for (final field in (entry.value as Map).entries) {
          if (field.key is! String) {
            return null;
          }
          owner[field.key as String] = field.value;
        }
        if (isBookshelf && owner.containsKey('localThumbnailPath')) {
          final migrated = await _migrateValue(
            owner['localThumbnailPath'],
            ManagedMediaKind.book,
            mediaStore,
          );
          owner['localThumbnailPath'] = migrated.value;
          isComplete = isComplete && migrated.isComplete;
        }
        if (owner.containsKey('words')) {
          final words = owner['words'];
          if (words is! List) {
            return null;
          }
          final migratedWords = await Future.wait(
            words.map((value) async {
              if (value is! Map) {
                throw const FormatException('Malformed local word.');
              }
              final word = <String, dynamic>{};
              for (final field in value.entries) {
                if (field.key is! String) {
                  throw const FormatException('Malformed local word field.');
                }
                word[field.key as String] = field.value;
              }
              if (word.containsKey('imagePath')) {
                final migrated = await _migrateValue(
                  word['imagePath'],
                  ManagedMediaKind.word,
                  mediaStore,
                );
                if (migrated.value == null) {
                  word.remove('imagePath');
                } else {
                  word['imagePath'] = migrated.value;
                }
                return (word: word, isComplete: migrated.isComplete);
              }
              return (word: word, isComplete: true);
            }),
          );
          owner['words'] = migratedWords
              .map((migrated) => migrated.word)
              .toList();
          isComplete =
              isComplete &&
              migratedWords.every((migrated) => migrated.isComplete);
        }
        result[entry.key as String] = owner;
      }
      return _MigratedCollection(
        json: jsonEncode(result),
        isComplete: isComplete,
      );
    } on FormatException {
      rethrow;
    }
  }

  static Future<_MigratedValue> _migrateValue(
    Object? value,
    ManagedMediaKind kind,
    ManagedMediaStore mediaStore,
  ) async {
    if (value == null || value == '') {
      return const _MigratedValue(value: null, isComplete: true);
    }
    final managed = ManagedMediaRef.tryParse(value);
    if (managed != null) {
      return managed.kind == kind
          ? _MigratedValue(value: managed.encoded, isComplete: true)
          : const _MigratedValue(value: null, isComplete: false);
    }
    if (value is! String) {
      return const _MigratedValue(value: null, isComplete: false);
    }
    final migrated = await mediaStore.migrateTrustedLegacy(value, kind);
    return migrated == null
        ? const _MigratedValue(value: null, isComplete: false)
        : _MigratedValue(value: migrated.encoded, isComplete: true);
  }

  static void configureForTesting(ManagedMediaStore? value) {
    _store = value;
  }
}

class _MigratedCollection {
  const _MigratedCollection({required this.json, required this.isComplete});

  final String json;
  final bool isComplete;
}

class _MigratedValue {
  const _MigratedValue({required this.value, required this.isComplete});

  final String? value;
  final bool isComplete;
}
