import 'dart:convert';
import 'dart:math' as math;

import '../models/book_page.dart';
import '../models/custom_pack.dart';
import 'storage_service.dart';

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
