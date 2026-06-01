import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_page.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Phase 5 (stately-rising-jongga) — "내 책장" CRUD service.
///
/// **Source of Truth**: lokales Storage (kl_bookshelf_v1).
/// Firestore sync best-effort (Phase 1 Pattern).
class BookshelfService {
  static final math.Random _rng = math.Random.secure();

  // ── ID-Generierung ─────────────────────────────────────────────────

  /// Zeit-basierte kurze ID: epochMs(36) + 4 Zeichen Random.
  /// Sortierbar; collision-free in praktischer Anwendung.
  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(
      4,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
    return 'p_${ts}_$tail';
  }

  // ── Local Read/Write ──────────────────────────────────────────────

  static List<BookPage> getAllLocal() {
    final raw = _readRaw();
    return raw.entries
        .map(
          (e) => BookPage.fromJson(
            e.key,
            (e.value as Map).cast<String, dynamic>(),
          ),
        )
        .toList()
      ..sort((a, b) => b.capturedAtIso.compareTo(a.capturedAtIso));
  }

  static BookPage? getById(String id) {
    final raw = _readRaw();
    final entry = raw[id];
    if (entry == null) return null;
    return BookPage.fromJson(id, (entry as Map).cast<String, dynamic>());
  }

  static Future<void> save(BookPage page) async {
    final raw = Map<String, dynamic>.from(_readRaw());
    raw[page.id] = page.toLocalJson();
    await _writeRaw(raw);
    // best-effort Firestore sync
    // ignore: discarded_futures, unawaited_futures
    _saveToFirestore(page);
  }

  static Future<void> delete(String id) async {
    final raw = Map<String, dynamic>.from(_readRaw());
    raw.remove(id);
    await _writeRaw(raw);
    // ignore: discarded_futures, unawaited_futures
    _deleteFromFirestore(id);
  }

  // ── Internal helpers ──────────────────────────────────────────────

  static Map<String, dynamic> _readRaw() {
    final raw = _prefsString();
    if (raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
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

  static Future<void> _writeRaw(Map<String, dynamic> data) async {
    await Storage.setBookshelfRawJson(jsonEncode(data));
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
    } catch (_) {
      // silent
    }
  }

  static Future<void> _deleteFromFirestore(String id) async {
    final col = _collection();
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (_) {
      // silent
    }
  }
}
