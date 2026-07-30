import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_page.dart';
import 'account/account_transition_journal.dart';
import 'account/bookshelf_generation_manifest.dart';
import 'account/bookshelf_sync_outbox.dart';
import 'account/cloud_restore_result.dart';
import 'account/cloud_write_session.dart';
import 'account/media_cleanup_gate.dart';
import 'auth_service.dart';
import 'book_image_service.dart';
import 'media_mutation_lock.dart';
import 'media_workflow.dart';
import 'storage_service.dart';

/// Phase 5 (stately-rising-jongga) — "내 책장" CRUD service.
///
/// **Source of Truth**: lokales Storage (kl_bookshelf_v1).
/// Firestore sync best-effort (Phase 1 Pattern).
class BookshelfService {
  static final math.Random _rng = math.Random.secure();

  /// Prozess-monotoner Zähler — garantiert Eindeutigkeit auch bei mehreren
  /// Aufrufen innerhalb derselben Millisekunde.
  static int _seq = 0;

  // ── ID-Generierung ─────────────────────────────────────────────────

  /// Zeit-basierte kurze ID: epochMs(36) + Sequenz + 4 Zeichen Random.
  /// Sortierbar; der monotone [_seq]-Zähler macht Kollisionen unmöglich,
  /// der Random-Tail deckt den (theoretischen) Mehr-Isolate-Fall ab.
  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final seq = (_seq++).toRadixString(36);
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(
      4,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
    return 'p_${ts}_${seq}_$tail';
  }

  // ── Local Read/Write ──────────────────────────────────────────────

  static List<BookPage> getAllLocal() {
    final raw = _readRawTolerant();
    final pages = <BookPage>[];
    for (final entry in raw.entries) {
      try {
        pages.add(
          BookPage.fromJson(
            entry.key,
            (entry.value as Map).cast<String, dynamic>(),
          ),
        );
      } on Object {
        // Tolerant UI reads skip malformed nested entries.
      }
    }
    pages.sort((a, b) => b.capturedAtIso.compareTo(a.capturedAtIso));
    return pages;
  }

  static BookPage? getById(String id) {
    final raw = _readRawTolerant();
    final entry = raw[id];
    if (entry == null) return null;
    try {
      return BookPage.fromJson(id, (entry as Map).cast<String, dynamic>());
    } on Object {
      return null;
    }
  }

  static Future<void> save(BookPage page) async {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      await _saveLocal(page);
      return;
    }
    var localWriteAttempted = false;
    await BookshelfRevivalWorkflow(_productionSyncQueue).run(
      uid: uid,
      ids: {page.id},
      saveLocal: () =>
          _saveLocal(page, beforeWrite: () => localWriteAttempted = true),
      readStrictLiveIds: () => _readRaw().keys.toSet(),
      localWriteWasAttempted: () => localWriteAttempted,
    );
  }

  static Future<BookPage> saveWithPendingImage(
    BookPage page,
    PendingMediaLease lease,
  ) async {
    late BookPage persisted;
    final workflow = BookMediaSaveWorkflow(
      store: await BookImageService.store,
      persist: (reference) async {
        persisted = page.copyWith(localThumbnailPath: reference.encoded);
        await save(persisted);
      },
    );
    await workflow.save(lease);
    return persisted;
  }

  static Future<void> delete(
    String id, {
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    final uid = AuthService.cloudBackupUid;
    var localWriteAttempted = false;
    Future<void> deleteLocal() => MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final removed = raw.remove(id);
      localWriteAttempted = true;
      await _writeRawStrict(raw);
      if (removed is Map) {
        final page = BookPage.fromJson(id, removed.cast<String, dynamic>());
        try {
          await _collectGarbage(selectedSessions, [
            page.localThumbnailPath,
            ...page.words.map((word) => word.imagePath),
          ]);
        } on Object {
          // The strict model delete already committed. Startup reconciliation
          // safely retries media GC when the platform store is available.
        }
      }
    });
    if (uid == null) {
      await deleteLocal();
      return;
    }
    await BookshelfDeletionWorkflow(_productionSyncQueue).run(
      uid: uid,
      ids: {id},
      deleteLocal: deleteLocal,
      readStrictLiveIds: () => _readRaw().keys.toSet(),
      localWriteWasAttempted: () => localWriteAttempted,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────

  static Map<String, dynamic> _readRaw() {
    final raw = _prefsString();
    if (raw.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Malformed bookshelf storage.');
    }
    final result = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Malformed bookshelf entry.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static Map<String, dynamic> _readRawTolerant() {
    try {
      return _readRaw();
    } on Object {
      return const {};
    }
  }

  static String _prefsString() {
    // Storage hat keinen generischen getter; greife direkt auf SharedPreferences.
    // Da Storage._prefs private ist, verwenden wir eine eigene kleine
    // get/set Schicht via Reflection nicht möglich → wir bauen einen
    // Helper als Erweiterung der Bookshelf-Klasse selbst.
    return Storage.bookshelfRawJson;
  }

  static Future<void> _writeRawStrict(Map<String, dynamic> data) async {
    await Storage.setBookshelfRawJsonStrict(jsonEncode(data));
  }

  static Future<void> _saveLocal(
    BookPage page, {
    void Function()? beforeWrite,
  }) {
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      raw[page.id] = page.toLocalJson();
      beforeWrite?.call();
      await _writeRawStrict(raw);
    });
  }

  static Future<void> _collectGarbage(
    CloudWriteSessionController sessions,
    Iterable<String?> encodedRefs,
  ) async {
    final session = sessions.current;
    await collectGarbageWithSession(
      sessions: sessions,
      uid: session?.uid ?? AuthService.cloudBackupUid,
      session: session,
      provenLocalOnly:
          session == null &&
          !sessions.hasBeenActivated &&
          AuthService.cloudBackupUid == null,
      prepare: () async {},
      delete: () => _collectGarbageUnfenced(encodedRefs),
    );
  }

  static Future<CloudWriteResult> collectGarbageWithSession({
    required CloudWriteSessionController sessions,
    String? uid,
    CloudWriteSession? session,
    AccountTransitionJournal? journal,
    AccountTransitionJournalReader? readJournal,
    bool provenLocalOnly = false,
    required Future<void> Function() prepare,
    required Future<void> Function() delete,
  }) {
    final journalReader =
        readJournal ??
        (journal == null
            ? const SharedPreferencesAccountTransitionJournalReader().call
            : () async => journal);
    return MediaCleanupGate(sessions).run(
      uid: uid,
      session: session,
      readJournal: journalReader,
      provenLocalOnly: provenLocalOnly,
      prepare: prepare,
      delete: delete,
    );
  }

  static bool _isCurrentSession(
    CloudWriteSessionController sessions,
    CloudWriteSession session,
  ) {
    try {
      sessions.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }

  static Future<void> _collectGarbageUnfenced(
    Iterable<String?> encodedRefs,
  ) async {
    final snapshot = ManagedMediaReferenceSnapshot.fromJson(
      bookshelfJson: Storage.bookshelfRawJson,
      customPacksJson: Storage.customPacksRawJson,
    );
    if (!snapshot.isComplete) return;
    final references = encodedRefs
        .map(ManagedMediaRef.tryParse)
        .whereType<ManagedMediaRef>()
        .toSet();
    if (references.isEmpty) return;
    final store = await BookImageService.store;
    for (final reference in references) {
      await store.deleteIfUnreferenced(reference, snapshot);
    }
  }

  // ── Firestore best-effort ──────────────────────────────────────────

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final BookshelfSyncQueue _productionSyncQueue = BookshelfSyncQueue(
    store: const SharedPreferencesBookshelfSyncOutboxStore(),
    tokenFactory: _newGenerationId,
    attempt: _attemptPendingSync,
  );

  static Future<CloudWriteResult> _attemptPendingSync(
    BookshelfSyncPending pending,
  ) async {
    if (AuthService.cloudBackupUid != pending.uid) {
      return CloudWriteResult.blocked;
    }
    final db = _db;
    if (db == null) return CloudWriteResult.blocked;
    final entries = _portableLocalEntries();
    return syncGenerationWithSession(
      sessions: cloudWriteSessionController,
      uid: pending.uid,
      generationId: _newGenerationId(),
      operationId: pending.operationId,
      entries: entries,
      deletedIds: pending.tombstonesAbsentFrom(entries.keys),
      revivedIds: pending.revivedIds,
      allowParentOnlyLegacy: pending.allowParentOnlyLegacy,
      repository: _FirestoreBookshelfGenerationRepository(db),
    );
  }

  static Future<void> resumePendingSync() async {
    final uid = AuthService.cloudBackupUid;
    if (uid != null) {
      await _productionSyncQueue.reconcilePrepared(uid, _readRaw().keys);
    }
    await _productionSyncQueue.drain();
  }

  static Future<void> recordValidatedParentOnlyLegacyRestore({
    required String uid,
    required String restoredJson,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) async {
    if (session.mode != CloudWriteMode.reconciling) {
      throw StateError(
        'Parent-only legacy approval requires a reconciling session.',
      );
    }
    sessions.assertCurrent(session);
    if (session.uid != uid) {
      throw StateError('Validated bookshelf restore UID does not match.');
    }
    if (Storage.bookshelfRawJson != restoredJson) {
      throw StateError('Validated bookshelf restore no longer matches local.');
    }
    validateParentOnlyLegacyRestore(restoredJson);
    await BookshelfParentOnlyLegacyApprovalWorkflow(
      _productionSyncQueue,
    ).run(uid: uid, session: session, sessions: sessions);
  }

  static void validateParentOnlyLegacyRestore(String restoredJson) {
    _portableEntriesFromJson(restoredJson);
  }

  static Map<String, Map<String, dynamic>> _portableLocalEntries() =>
      _portableEntriesFromJson(Storage.bookshelfRawJson);

  static Map<String, Map<String, dynamic>> _portableEntriesFromJson(
    String rawJson,
  ) {
    if (rawJson.isEmpty) return {};
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Malformed bookshelf storage.');
    }
    final entries = <String, Map<String, dynamic>>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Malformed bookshelf entry.');
      }
      final page = BookPage.fromJson(
        entry.key as String,
        (entry.value as Map).cast<String, dynamic>(),
      );
      entries[entry.key as String] = page.toFirestoreJson();
    }
    return entries;
  }

  static String _newGenerationId() {
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
      36,
    );
    final random = List.generate(
      12,
      (_) => _rng.nextInt(36).toRadixString(36),
    ).join();
    return 'g_${micros}_$random';
  }

  /// Uploads the locally owned bookshelf only for the exact session that
  /// completed a first anonymous-to-durable link. The cloud owner is derived
  /// from [session], never supplied independently by a caller.
  static Future<CloudWriteResult> uploadLocalGenerationForFirstDurableLink({
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    String? generationId,
    BookshelfGenerationRepository? repository,
  }) async {
    final db = _db;
    final selectedRepository =
        repository ??
        (db == null ? null : _FirestoreBookshelfGenerationRepository(db));
    if (selectedRepository == null) return CloudWriteResult.blocked;
    final entries = _portableLocalEntries();
    return syncGenerationWithSession(
      sessions: sessions,
      uid: session.uid,
      expectedSession: session,
      generationId: generationId ?? _newGenerationId(),
      entries: entries,
      repository: selectedRepository,
    );
  }

  static Future<CloudWriteResult> syncGenerationWithSession({
    required CloudWriteSessionController sessions,
    required String uid,
    CloudWriteSession? expectedSession,
    required String generationId,
    String? operationId,
    required Map<String, Map<String, dynamic>> entries,
    Set<String> deletedIds = const {},
    Set<String> revivedIds = const {},
    bool allowParentOnlyLegacy = false,
    required BookshelfGenerationRepository repository,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = expectedSession ?? fence.readySnapshot(uid);
    if (snapshot == null) return CloudWriteResult.blocked;
    final initial = fence.verify(snapshot, uid: uid);
    if (initial != CloudWriteResult.completed) return initial;
    try {
      final result = await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: uid,
        generationId: generationId,
        operationId: operationId,
        entries: entries,
        deletedIds: deletedIds,
        revivedIds: revivedIds,
        allowParentOnlyLegacy: allowParentOnlyLegacy,
        beforeWrite: () => sessions.assertCurrent(snapshot),
      );
      if (!_isCurrentSession(sessions, snapshot)) {
        return CloudWriteResult.stale;
      }
      return result.status == BookshelfGenerationWriteStatus.activated
          ? CloudWriteResult.completed
          : CloudWriteResult.blocked;
    } on StateError {
      if (!_isCurrentSession(sessions, snapshot)) {
        return CloudWriteResult.stale;
      }
      rethrow;
    }
  }

  static Future<BookshelfRemoteSnapshot> readRemoteWithRepository({
    required String uid,
    required BookshelfGenerationRepository repository,
  }) {
    return BookshelfGenerationSync.read(repository, uid);
  }

  static Future<bool> restoreRemote(String uid) async {
    final expectedSession = CloudWriteFence(
      cloudWriteSessionController,
    ).readySnapshot(uid);
    if (expectedSession == null) return false;
    final result = await restoreRemoteForSession(
      uid: uid,
      expectedSession: expectedSession,
      sessions: cloudWriteSessionController,
    );
    return result == CloudWriteResult.completed;
  }

  static Future<CloudWriteResult> restoreRemoteForSession({
    required String uid,
    required CloudWriteSession expectedSession,
    required CloudWriteSessionController sessions,
    BookshelfGenerationRepository? repository,
  }) async => (await restoreRemoteForSessionWithResult(
    uid: uid,
    expectedSession: expectedSession,
    sessions: sessions,
    repository: repository,
  )).status;

  /// Restores a bookshelf generation with the exact source session and reports
  /// whether the remote source contained any restorable entries or tombstones.
  static Future<CloudRestoreComponentResult> restoreRemoteForSessionWithResult({
    required String uid,
    required CloudWriteSession expectedSession,
    required CloudWriteSessionController sessions,
    BookshelfGenerationRepository? repository,
  }) async {
    final db = _db;
    final selectedRepository =
        repository ??
        (db == null ? null : _FirestoreBookshelfGenerationRepository(db));
    if (selectedRepository == null) {
      return const CloudRestoreComponentResult(
        status: CloudWriteResult.blocked,
        hasRemoteData: false,
      );
    }
    final fence = CloudWriteFence(sessions);
    final initial = fence.verify(expectedSession, uid: uid);
    if (initial != CloudWriteResult.completed) {
      return CloudRestoreComponentResult(status: initial, hasRemoteData: false);
    }
    try {
      final snapshot = await readRemoteWithRepository(
        uid: uid,
        repository: selectedRepository,
      );
      final afterRead = fence.verify(expectedSession, uid: uid);
      if (afterRead != CloudWriteResult.completed) {
        return CloudRestoreComponentResult(
          status: afterRead,
          hasRemoteData: false,
        );
      }
      final hasRemoteData =
          snapshot.entries.isNotEmpty || snapshot.tombstoneIds.isNotEmpty;
      final local = Map<String, dynamic>.from(_readRaw());
      for (final id in snapshot.tombstoneIds) {
        local.remove(id);
      }
      for (final entry in snapshot.entries.entries) {
        local.putIfAbsent(
          entry.key,
          () => BookPage.fromPortableJson(entry.key, entry.value).toLocalJson(),
        );
      }
      sessions.assertCurrent(expectedSession);
      await _writeRawStrict(local);
      final completed = fence.verify(expectedSession, uid: uid);
      return CloudRestoreComponentResult(
        status: completed,
        hasRemoteData: completed == CloudWriteResult.completed && hasRemoteData,
      );
    } on StateError {
      final current = fence.verify(expectedSession, uid: uid);
      if (current != CloudWriteResult.completed) {
        return CloudRestoreComponentResult(
          status: current,
          hasRemoteData: false,
        );
      }
      rethrow;
    }
  }

  static Future<bool> restoreRemoteWithRepository({
    required String uid,
    required BookshelfGenerationRepository repository,
  }) async {
    final snapshot = await readRemoteWithRepository(
      uid: uid,
      repository: repository,
    );
    final local = Map<String, dynamic>.from(_readRaw());
    for (final id in snapshot.tombstoneIds) {
      local.remove(id);
    }
    for (final entry in snapshot.entries.entries) {
      local.putIfAbsent(
        entry.key,
        () => BookPage.fromPortableJson(entry.key, entry.value).toLocalJson(),
      );
    }
    await _writeRawStrict(local);
    return true;
  }

  // Retained as a narrow writer-fence seam for the existing race tests.
  // Production bookshelf writes use [syncGenerationWithSession].
  static Future<CloudWriteResult> saveWithSession(
    BookPage page, {
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<void> Function() prepare,
    required Future<void> Function() write,
  }) {
    return CloudWriteFence(
      sessions,
    ).run(uid: uid, prepare: prepare, action: write);
  }

  static Future<CloudWriteResult> deleteWithSession(
    String id, {
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<void> Function() prepare,
    required Future<void> Function() delete,
  }) {
    return CloudWriteFence(
      sessions,
    ).run(uid: uid, prepare: prepare, action: delete);
  }
}

class _FirestoreBookshelfGenerationRepository
    implements BookshelfGenerationRepository {
  const _FirestoreBookshelfGenerationRepository(this.firestore);

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _manifest(String uid) =>
      _user(uid).collection('sync_metadata').doc('bookshelf_active');

  DocumentReference<Map<String, dynamic>> _record(
    String uid,
    String generationId,
    String recordId,
  ) => _user(uid)
      .collection('sync_generations')
      .doc(generationId)
      .collection('bookshelf')
      .doc(recordId);

  @override
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid) async {
    final snapshot = await _manifest(
      uid,
    ).get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    return !snapshot.exists || data == null
        ? null
        : BookshelfGenerationManifest.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>?> readGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
  }) async {
    final snapshot = await _record(
      uid,
      generationId,
      recordId,
    ).get(const GetOptions(source: Source.server));
    return snapshot.data();
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyParent(String uid) async {
    final snapshot = await _user(
      uid,
    ).get(const GetOptions(source: Source.server));
    final source = snapshot.data()?['bookshelf_json'];
    if (source == null || (source is String && source.trim().isEmpty)) {
      return {};
    }
    if (source is! String) {
      throw const FormatException('Invalid legacy bookshelf parent.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Invalid legacy bookshelf parent.');
    }
    return _portableMap(decoded);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyEntries(
    String uid,
  ) async {
    final snapshot = await _user(
      uid,
    ).collection('bookshelf').get(const GetOptions(source: Source.server));
    return {
      for (final document in snapshot.docs)
        document.id: _portableDocument(document.data()),
    };
  }

  @override
  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  }) {
    final reference = _record(uid, generationId, recordId);
    final requested = BookshelfGenerationRecord.fromJson(data);
    return firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final currentData = current.data();
      if (current.exists && currentData != null) {
        final existing = BookshelfGenerationRecord.fromJson(currentData);
        if (existing.id == requested.id &&
            existing.revision == requested.revision &&
            existing.deleted == requested.deleted &&
            existing.canonicalHash == requested.canonicalHash) {
          return;
        }
        throw StateError('Bookshelf generation records are immutable.');
      }
      transaction.set(reference, {
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) {
    final reference = _manifest(uid);
    return firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final currentData = current.data();
      if (current.exists && currentData != null) {
        final active = BookshelfGenerationManifest.fromJson(currentData);
        if (active.hasSameContent(manifest)) {
          return true;
        }
        if (active.generationId == manifest.generationId ||
            active.revision == manifest.revision) {
          return false;
        }
        if (active.revision != expectedRevision) return false;
      } else if (expectedRevision != 0) {
        return false;
      }
      transaction.set(reference, {
        ...manifest.toJson(),
        'activated_at': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  static Map<String, Map<String, dynamic>> _portableMap(Map source) {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in source.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid legacy bookshelf entry.');
      }
      result[entry.key as String] = _portableDocument(
        (entry.value as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }
    return result;
  }

  static Map<String, dynamic> _portableDocument(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source)
      ..remove('localThumbnailPath')
      ..remove('updatedAt')
      ..remove('updated_at');
    final words = result['words'];
    if (words is List) {
      result['words'] = words.map((word) {
        if (word is! Map) {
          throw const FormatException('Invalid legacy bookshelf word.');
        }
        return Map<String, dynamic>.from(
          word.map((key, value) => MapEntry(key.toString(), value)),
        )..remove('imagePath');
      }).toList();
    }
    return result;
  }
}
