import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/book_page.dart';
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
    await MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      raw[page.id] = page.toLocalJson();
      await _writeRawStrict(raw);
    });
    // best-effort Firestore sync
    // ignore: discarded_futures, unawaited_futures
    _saveToFirestore(page);
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

  static Future<void> delete(String id) async {
    await MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final removed = raw.remove(id);
      await _writeRawStrict(raw);
      if (removed is Map) {
        final page = BookPage.fromJson(id, removed.cast<String, dynamic>());
        try {
          await _collectGarbage([
            page.localThumbnailPath,
            ...page.words.map((word) => word.imagePath),
          ]);
        } on Object {
          // The strict model delete already committed. Startup reconciliation
          // safely retries media GC when the platform store is available.
        }
      }
    });
    // ignore: discarded_futures, unawaited_futures
    _deleteFromFirestore(id);
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

  static Future<void> _collectGarbage(Iterable<String?> encodedRefs) async {
    final snapshot = ManagedMediaReferenceSnapshot.fromJson(
      bookshelfJson: Storage.bookshelfRawJson,
      customPacksJson: Storage.customPacksRawJson,
    );
    if (!snapshot.isComplete) {
      return;
    }
    final references = encodedRefs
        .map(ManagedMediaRef.tryParse)
        .whereType<ManagedMediaRef>()
        .toSet();
    if (references.isEmpty) {
      return;
    }
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

  static CollectionReference<Map<String, dynamic>>? _collection() {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) return null;
    return db.collection('users').doc(uid).collection('bookshelf');
  }

  static Future<void> _saveToFirestore(BookPage page) async {
    final col = _collection();
    if (col == null) return;
    try {
      final payload = Map<String, dynamic>.from(page.toFirestoreJson());
      payload['updatedAt'] = FieldValue.serverTimestamp();
      await col.doc(page.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      // best-effort — 로컬이 source of truth. 단 침묵 실패는 디버깅 불가라 로깅.
      debugPrint('BookshelfService: Firestore save skipped — $e');
    }
  }

  static Future<void> _deleteFromFirestore(String id) async {
    final col = _collection();
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (e) {
      debugPrint('BookshelfService: Firestore delete skipped — $e');
    }
  }
}
