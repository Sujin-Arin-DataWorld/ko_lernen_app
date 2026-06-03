import 'dart:convert';
import 'dart:math' as math;

import '../models/book_page.dart';
import '../models/custom_pack.dart';
import 'storage_service.dart';

/// Ergebnis von [CustomPackService.quickAdd].
enum WordbookAddResult { added, alreadyExists, failed }

/// Phase 5.1 (stately-rising-jongga) — CustomPack CRUD service.
///
/// Lokal-only — Firestore sync 는 v1 에서 미구현 (사용자 1대 기기 가정).
/// Cloud sync 가 필요해지면 BookshelfService 의 best-effort 패턴 그대로 추가.
class CustomPackService {
  static final math.Random _rng = math.Random.secure();

  /// 시간 기반 짧은 ID — BookshelfService 와 동일 패턴.
  static String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(
      4,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
    return 'cp_${ts}_$tail';
  }

  static List<CustomPack> getAll() {
    final raw = _readRaw();
    return raw.entries
        .map((e) => CustomPack.fromJson(
              e.key,
              (e.value as Map).cast<String, dynamic>(),
            ))
        .toList()
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
  }

  static CustomPack? getById(String id) {
    final raw = _readRaw();
    final entry = raw[id];
    if (entry == null) return null;
    return CustomPack.fromJson(id, (entry as Map).cast<String, dynamic>());
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
    final pack = getById(packId);
    if (pack == null) return null;
    final updated = pack.copyWith(words: [...pack.words, word]);
    await save(updated);
    return updated;
  }

  /// 여러 단어 일괄 추가 (CSV 가져오기). 갱신된 팩 반환.
  static Future<CustomPack?> addWords(
      String packId, List<ExtractedWord> words) async {
    if (words.isEmpty) return getById(packId);
    final pack = getById(packId);
    if (pack == null) return null;
    final updated = pack.copyWith(words: [...pack.words, ...words]);
    await save(updated);
    return updated;
  }

  /// index 위치 단어 교체 → 저장.
  static Future<CustomPack?> updateWord(
      String packId, int index, ExtractedWord word) async {
    final pack = getById(packId);
    if (pack == null || index < 0 || index >= pack.words.length) {
      return pack;
    }
    final words = List<ExtractedWord>.from(pack.words);
    words[index] = word;
    final updated = pack.copyWith(words: words);
    await save(updated);
    return updated;
  }

  /// index 위치 단어 삭제 → 저장.
  static Future<CustomPack?> deleteWord(String packId, int index) async {
    final pack = getById(packId);
    if (pack == null || index < 0 || index >= pack.words.length) {
      return pack;
    }
    final words = List<ExtractedWord>.from(pack.words)..removeAt(index);
    final updated = pack.copyWith(words: words);
    await save(updated);
    return updated;
  }

  /// 단어장 이름 변경 → 저장.
  static Future<CustomPack?> rename(String packId, String name) async {
    final pack = getById(packId);
    if (pack == null) return null;
    final updated = pack.copyWith(name: name);
    await save(updated);
    return updated;
  }

  static Future<void> save(CustomPack pack) async {
    final raw = Map<String, dynamic>.from(_readRaw());
    raw[pack.id] = pack.toJson();
    await _writeRaw(raw);
  }

  static Future<void> delete(String id) async {
    final raw = Map<String, dynamic>.from(_readRaw());
    raw.remove(id);
    await _writeRaw(raw);
  }

  // ── helpers ────────────────────────────────────────────────────────

  static Map<String, dynamic> _readRaw() {
    final raw = Storage.customPacksRawJson;
    if (raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return const {};
    }
  }

  static Future<void> _writeRaw(Map<String, dynamic> data) async {
    await Storage.setCustomPacksRawJson(jsonEncode(data));
  }
}
