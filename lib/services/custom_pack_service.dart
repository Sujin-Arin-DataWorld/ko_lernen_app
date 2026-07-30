import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../models/book_page.dart';
import '../models/custom_pack.dart';
import 'account/cloud_read_result.dart';
import 'account/cloud_write_session.dart';
import 'account/media_cleanup_gate.dart';
import 'auth_service.dart';
import 'book_image_service.dart';
import 'media_mutation_lock.dart';
import 'storage_service.dart';

/// Ergebnis von [CustomPackService.quickAdd].
enum WordbookAddResult { added, alreadyExists, failed }

class LocalCustomPackGenerationConflict implements Exception {
  const LocalCustomPackGenerationConflict();
}

/// Phase 5.1 (stately-rising-jongga) — CustomPack CRUD service.
///
/// Lokal-only — Firestore sync 는 v1 에서 미구현 (사용자 1대 기기 가정).
/// Cloud sync 가 필요해지면 BookshelfService 의 best-effort 패턴 그대로 추가.
class CustomPackService {
  static const int defaultRemoteReadLimitBytes = 512 * 1024;

  static final math.Random _rng = math.Random.secure();

  /// Prozess-monotoner Zähler — siehe [BookshelfService.generateId].
  static int _seq = 0;

  static String mediaWorkflowId(
    String packId,
    int? index,
    ExtractedWord? original,
  ) {
    if (index == null || original == null) {
      return 'word:$packId:new';
    }
    final canonical = jsonEncode(original.toLocalJson());
    final fingerprint = sha256.convert(utf8.encode(canonical));
    return 'word:$packId:$index:$fingerprint';
  }

  /// 시간 기반 짧은 ID — BookshelfService 와 동일 패턴.
  /// epochMs(36) + Sequenz + 4 Zeichen Random: [_seq] garantiert
  /// Eindeutigkeit auch bei Aufrufen innerhalb derselben Millisekunde.
  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final seq = (_seq++).toRadixString(36);
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(
      4,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
    return 'cp_${ts}_${seq}_$tail';
  }

  static List<CustomPack> getAll() {
    final raw = _readRawTolerant();
    final packs = <CustomPack>[];
    for (final entry in raw.entries) {
      try {
        packs.add(
          CustomPack.fromJson(
            entry.key,
            (entry.value as Map).cast<String, dynamic>(),
          ),
        );
      } on Object {
        // Tolerant UI reads skip malformed nested entries.
      }
    }
    packs.sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
    return packs;
  }

  /// Strict portable custom-pack decoder for account reconciliation.
  ///
  /// Unlike the legacy tolerant local UI read, malformed, unavailable, and
  /// absent data remain distinguishable at this boundary.
  static CloudReadResult<Map<String, Map<String, Object?>>>
  decodePortableRemote(
    Object? value, {
    int maxBytes = defaultRemoteReadLimitBytes,
  }) {
    if (value == null) {
      return const CloudReadResult.absent();
    }
    if (value is! String || maxBytes < 1) {
      return const CloudReadResult.invalid();
    }
    if (utf8.encode(value).length > maxBytes) {
      return const CloudReadResult.tooLarge();
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        return const CloudReadResult.invalid();
      }
      final result = <String, Map<String, Object?>>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String ||
            (entry.key as String).trim().isEmpty ||
            entry.value is! Map) {
          return const CloudReadResult.invalid();
        }
        final data = (entry.value as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (data['name'] is! String ||
            data['sourcePageId'] is! String ||
            data['words'] is! List ||
            data['createdAt'] is! String) {
          return const CloudReadResult.invalid();
        }
        final pack = CustomPack.fromPortableJson(entry.key as String, data);
        if (pack.id != entry.key) {
          return const CloudReadResult.invalid();
        }
        result[pack.id] = Map<String, Object?>.from(pack.toPortableJson());
      }
      return CloudReadResult.present(result);
    } catch (_) {
      return const CloudReadResult.invalid();
    }
  }

  static CloudReadResult<Map<String, Map<String, Object?>>>
  readLocalForReconciliation({int maxBytes = defaultRemoteReadLimitBytes}) {
    final value = Storage.customPacksRawJson;
    if (value.trim().isEmpty) {
      return const CloudReadResult.present({});
    }
    if (utf8.encode(value).length > maxBytes) {
      return const CloudReadResult.tooLarge();
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        return const CloudReadResult.invalid();
      }
      final result = <String, Map<String, Object?>>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String ||
            (entry.key as String).trim().isEmpty ||
            entry.value is! Map) {
          return const CloudReadResult.invalid();
        }
        final pack = CustomPack.fromJson(
          entry.key as String,
          (entry.value as Map).cast<String, dynamic>(),
        );
        result[pack.id] = Map<String, Object?>.from(pack.toPortableJson());
      }
      return CloudReadResult.present(result);
    } catch (_) {
      return const CloudReadResult.invalid();
    }
  }

  static String get localReconciliationGeneration =>
      sha256.convert(utf8.encode(Storage.customPacksRawJson)).toString();

  static Future<void> writeReconciledPortable(
    Map<String, Map<String, Object?>> portable, {
    String? expectedGeneration,
    void Function()? beforeWrite,
    Future<void> Function(Map<String, dynamic> output)? writer,
  }) {
    return MediaMutationLock.run(() async {
      beforeWrite?.call();
      if (expectedGeneration != null &&
          localReconciliationGeneration != expectedGeneration) {
        throw const LocalCustomPackGenerationConflict();
      }
      final existingRaw = _readRaw();
      final output = <String, dynamic>{};
      final ids = portable.keys.toList()..sort();
      for (final id in ids) {
        final incoming = CustomPack.fromPortableJson(
          id,
          Map<String, dynamic>.from(portable[id]!),
        );
        final existing = _packFromRaw(existingRaw, id);
        final samePortable =
            existing != null &&
            jsonEncode(existing.toPortableJson()) ==
                jsonEncode(incoming.toPortableJson());
        output[id] = samePortable
            ? existing.toLocalJson()
            : incoming.toLocalJson();
      }
      await (writer ?? _writeRawStrict)(output);
    });
  }

  static CustomPack? getById(String id) {
    final raw = _readRawTolerant();
    final entry = raw[id];
    if (entry == null) return null;
    try {
      return CustomPack.fromJson(id, (entry as Map).cast<String, dynamic>());
    } on Object {
      return null;
    }
  }

  /// 책장 페이지에서 새 팩 생성 + 저장. 새 팩의 id 반환.
  static Future<CustomPack> createFromPage({
    required BookPage page,
    required String name,
  }) async {
    final pack = CustomPack.fromBookPage(
      id: generateId(),
      name: name,
      page: page,
    );
    await save(pack);
    return pack;
  }

  /// 빈 "나만의 단어장" 생성 + 저장. 새 팩 반환.
  static Future<CustomPack> createEmpty({required String name}) async {
    final pack = CustomPack.manual(id: generateId(), name: name);
    await save(pack);
    return pack;
  }

  /// Feste ID des "Schnellspeicher"-Packs — überall im Lern-Flow per
  /// [quickAdd] befüllt. Feste ID = kein Storage-Key nötig (find-or-create).
  static const String quickPackId = 'cp_quick_v1';

  /// "Dieses Wort in meine Wortliste" — universeller Schnell-Hinzufüger.
  /// Legt den Schnellspeicher-Pack bei Bedarf an, dedupliziert per
  /// koreanischem String (kein Spam beim mehrfachen Tippen).
  static Future<WordbookAddResult> quickAdd({
    required String defaultPackName,
    required ExtractedWord word,
  }) async {
    if (word.korean.trim().isEmpty) return WordbookAddResult.failed;
    try {
      var pack = getById(quickPackId);
      if (pack == null) {
        pack = CustomPack.manual(id: quickPackId, name: defaultPackName);
        await save(pack);
      }
      if (pack.words.any((w) => w.korean == word.korean)) {
        return WordbookAddResult.alreadyExists;
      }
      await addWord(quickPackId, word);
      return WordbookAddResult.added;
    } catch (_) {
      return WordbookAddResult.failed;
    }
  }

  /// 단어 추가 → 저장. 갱신된 팩 반환 (없으면 null).
  static Future<CustomPack?> addWord(String packId, ExtractedWord word) async {
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      if (pack == null) {
        return null;
      }
      final updated = pack.copyWith(words: [...pack.words, word]);
      raw[packId] = updated.toLocalJson();
      await _writeRawStrict(raw);
      return updated;
    });
  }

  /// 여러 단어 일괄 추가 (CSV 가져오기). 갱신된 팩 반환.
  static Future<CustomPack?> addWords(
    String packId,
    List<ExtractedWord> words,
  ) async {
    if (words.isEmpty) return getById(packId);
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      if (pack == null) {
        return null;
      }
      final updated = pack.copyWith(words: [...pack.words, ...words]);
      raw[packId] = updated.toLocalJson();
      await _writeRawStrict(raw);
      return updated;
    });
  }

  /// index 위치 단어 교체 → 저장.
  static Future<CustomPack?> updateWord(
    String packId,
    int index,
    ExtractedWord word, {
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      if (pack == null || index < 0 || index >= pack.words.length) {
        return pack;
      }
      final oldReference = pack.words[index].imagePath;
      final words = List<ExtractedWord>.from(pack.words);
      words[index] = word;
      final updated = pack.copyWith(words: words);
      raw[packId] = updated.toLocalJson();
      await _writeRawStrict(raw);
      await _collectGarbageBestEffort(selectedSessions, [oldReference]);
      return updated;
    });
  }

  /// index 위치 단어 삭제 → 저장.
  static Future<CustomPack?> deleteWord(
    String packId,
    int index, {
    required ExtractedWord expectedOriginal,
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      if (pack == null || index < 0 || index >= pack.words.length) {
        throw StateError('The deleted word no longer exists.');
      }
      if (jsonEncode(pack.words[index].toLocalJson()) !=
          jsonEncode(expectedOriginal.toLocalJson())) {
        throw StateError('The deleted word changed before deletion.');
      }
      final removedReference = pack.words[index].imagePath;
      final words = List<ExtractedWord>.from(pack.words)..removeAt(index);
      final updated = pack.copyWith(words: words);
      raw[packId] = updated.toLocalJson();
      await _writeRawStrict(raw);
      await _collectGarbageBestEffort(selectedSessions, [removedReference]);
      return updated;
    });
  }

  /// 단어장 이름 변경 → 저장.
  static Future<CustomPack?> rename(String packId, String name) async {
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      if (pack == null) {
        return null;
      }
      final updated = pack.copyWith(name: name);
      raw[packId] = updated.toLocalJson();
      await _writeRawStrict(raw);
      return updated;
    });
  }

  static Future<void> save(
    CustomPack pack, {
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    await MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final previous = _packFromRaw(raw, pack.id);
      raw[pack.id] = pack.toLocalJson();
      await _writeRawStrict(raw);
      if (previous != null) {
        await _collectGarbageBestEffort(
          selectedSessions,
          previous.words.map((word) => word.imagePath),
        );
      }
    });
  }

  static Future<void> delete(
    String id, {
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    await MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final previous = _packFromRaw(raw, id);
      raw.remove(id);
      await _writeRawStrict(raw);
      if (previous != null) {
        await _collectGarbageBestEffort(
          selectedSessions,
          previous.words.map((word) => word.imagePath),
        );
      }
    });
  }

  static Future<CustomPack?> addWordWithPendingImage(
    String packId,
    ExtractedWord word,
    PendingMediaLease lease,
  ) async {
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      final store = await BookImageService.store;
      if (pack == null) {
        await store.discard(lease);
        return null;
      }
      final ManagedMediaPromotion promotion;
      try {
        promotion = await store.promote(lease);
      } on Object {
        try {
          await store.discard(lease);
        } on Object {
          // Pending TTL reconciliation retries cleanup.
        }
        rethrow;
      }
      var persisted = false;
      try {
        final updated = pack.copyWith(
          words: [
            ...pack.words,
            word.copyWithEditable(imagePath: promotion.reference.encoded),
          ],
        );
        raw[packId] = updated.toLocalJson();
        await _writeRawStrict(raw);
        persisted = true;
        await store.finalizeAfterPersistence(promotion);
        return updated;
      } on PreferenceOutcomeUnknownException {
        // The durable pack may contain either version. Keep the promoted copy
        // and pending lease so neither possible model references deleted media.
        rethrow;
      } on Object {
        if (!persisted) {
          await store.rollback(promotion);
          try {
            await store.discard(promotion.lease);
          } on Object {
            // Pending TTL reconciliation retries cleanup.
          }
        }
        rethrow;
      }
    });
  }

  static Future<CustomPack?> updateWordWithMedia({
    required String packId,
    required int index,
    required ExtractedWord expectedOriginal,
    required ExtractedWord word,
    PendingMediaLease? pendingLease,
    bool removePhoto = false,
    CloudWriteSessionController? sessions,
  }) async {
    final selectedSessions = sessions ?? cloudWriteSessionController;
    return MediaMutationLock.run(() async {
      final raw = Map<String, dynamic>.from(_readRaw());
      final pack = _packFromRaw(raw, packId);
      final store = await BookImageService.store;
      if (pack == null || index < 0 || index >= pack.words.length) {
        if (pendingLease != null) {
          await store.discard(pendingLease);
        }
        throw StateError('The edited word no longer exists.');
      }
      if (jsonEncode(pack.words[index].toLocalJson()) !=
          jsonEncode(expectedOriginal.toLocalJson())) {
        if (pendingLease != null) {
          await store.discard(pendingLease);
        }
        throw StateError('The edited word changed before media was saved.');
      }
      final oldReference = ManagedMediaRef.tryParse(
        pack.words[index].imagePath,
      );
      ManagedMediaPromotion? promotion;
      var persisted = false;
      try {
        if (pendingLease != null) {
          promotion = await store.promote(pendingLease);
        }
        final nextReference =
            promotion?.reference ?? (removePhoto ? null : oldReference);
        final words = List<ExtractedWord>.from(pack.words);
        words[index] = word.copyWithEditable(
          imagePath: nextReference?.encoded,
          clearImage: nextReference == null,
        );
        final updated = pack.copyWith(words: words);
        raw[packId] = updated.toLocalJson();
        await _writeRawStrict(raw);
        persisted = true;
        if (promotion != null) {
          await store.finalizeAfterPersistence(promotion);
        }
        if (oldReference != null && oldReference != nextReference) {
          try {
            await _runMediaGc(
              selectedSessions,
              () => store.deleteIfUnreferenced(
                oldReference,
                _referenceSnapshot(),
              ),
            );
          } on Object {
            // Startup reconciliation retries old-file GC.
          }
        }
        return updated;
      } on PreferenceOutcomeUnknownException {
        // A refresh could not prove whether the old or edited word is durable.
        // Preserve old, promoted, and pending media for reconciliation.
        rethrow;
      } on Object {
        if (promotion != null && !persisted) {
          await store.rollback(promotion);
          try {
            await store.discard(promotion.lease);
          } on Object {
            // Pending TTL reconciliation retries cleanup.
          }
        } else if (promotion == null && pendingLease != null) {
          try {
            await store.discard(pendingLease);
          } on Object {
            // Pending TTL reconciliation retries cleanup.
          }
        }
        rethrow;
      }
    });
  }

  // ── helpers ────────────────────────────────────────────────────────

  static Map<String, dynamic> _readRaw() {
    final raw = Storage.customPacksRawJson;
    if (raw.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Malformed custom-pack storage.');
    }
    final result = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Malformed custom-pack entry.');
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

  static CustomPack? _packFromRaw(Map<String, dynamic> raw, String id) {
    final entry = raw[id];
    if (entry is! Map) {
      return null;
    }
    return CustomPack.fromJson(id, entry.cast<String, dynamic>());
  }

  static Future<void> _writeRawStrict(Map<String, dynamic> data) async {
    await Storage.setCustomPacksRawJsonStrict(jsonEncode(data));
  }

  static ManagedMediaReferenceSnapshot _referenceSnapshot() =>
      ManagedMediaReferenceSnapshot.fromJson(
        bookshelfJson: Storage.bookshelfRawJson,
        customPacksJson: Storage.customPacksRawJson,
      );

  static Future<void> _collectGarbage(
    CloudWriteSessionController sessions,
    Iterable<String> encodedRefs,
  ) async {
    await _runMediaGc(sessions, () => _collectGarbageUnfenced(encodedRefs));
  }

  static Future<void> _collectGarbageUnfenced(
    Iterable<String> encodedRefs,
  ) async {
    final snapshot = _referenceSnapshot();
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

  static Future<void> _runMediaGc(
    CloudWriteSessionController sessions,
    Future<void> Function() action,
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
      delete: action,
    );
  }

  static Future<CloudWriteResult> collectGarbageWithSession({
    required CloudWriteSessionController sessions,
    String? uid,
    CloudWriteSession? session,
    AccountTransitionJournalReader? readJournal,
    bool provenLocalOnly = false,
    required Future<void> Function() prepare,
    required Future<void> Function() delete,
  }) {
    return MediaCleanupGate(sessions).run(
      uid: uid,
      session: session,
      readJournal:
          readJournal ??
          const SharedPreferencesAccountTransitionJournalReader().call,
      provenLocalOnly: provenLocalOnly,
      prepare: prepare,
      delete: delete,
    );
  }

  static Future<void> _collectGarbageBestEffort(
    CloudWriteSessionController sessions,
    Iterable<String> encodedRefs,
  ) async {
    try {
      await _collectGarbage(sessions, encodedRefs);
    } on Object {
      // The strict model write already committed. Startup reconciliation can
      // safely retry GC; callers must not retry a committed mutation.
    }
  }
}
