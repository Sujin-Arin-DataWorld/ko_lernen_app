import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_page.dart';
import '../models/custom_pack.dart';
import 'auth_service.dart';
import 'custom_pack_service.dart';

/// Phase 5.2 (2026-06-02) — 커스텀 단어팩 친구 공유.
///
/// 흐름:
///   1. [sharePack] — 팩을 Firestore `shared_packs/{code}` 에 올리고 6자리
///      코드 반환. 코드 자체가 bearer-capability (rules: 인증 사용자 read 허용).
///   2. [redeem] — 친구가 코드 입력 → 문서 read → 로컬 [CustomPackService] 로
///      새 id 부여하여 import.
///
/// 모든 네트워크 실패/미인증/만료/없음은 [SharedPackException] 으로 표면화 →
/// UI 가 사용자에게 안내. 로컬 데이터는 절대 손상시키지 않음.
class SharedPackService {
  static final math.Random _rng = math.Random.secure();
  static const String _collectionPath = 'shared_packs';

  /// 혼동되는 글자(O,0,I,1,L) 제외.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const Duration _ttl = Duration(days: 30);

  /// 공유 가능한 최대 단어 수 (firestore.rules 와 동일하게 유지).
  static const int maxWords = 100;

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String _generateCode() => List.generate(
    _codeLength,
    (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)],
  ).join();

  /// 팩을 업로드하고 공유 코드를 반환. 실패 시 [SharedPackException] throw.
  static Future<String> sharePack(CustomPack pack) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw const SharedPackException(SharedPackError.network);
    }
    if (pack.words.isEmpty) {
      throw const SharedPackException(SharedPackError.empty);
    }
    final col = db.collection(_collectionPath);
    final words = pack.words
        .take(maxWords)
        .map((word) => word.toPortableJson())
        .toList();
    try {
      // 코드 충돌 회피 — 최대 5회 재시도.
      for (var attempt = 0; attempt < 5; attempt++) {
        final code = _generateCode();
        final ref = col.doc(code);
        final existing = await ref.get();
        if (existing.exists) {
          continue;
        }
        await ref.set({
          'schema': 1,
          'name': pack.displayName(),
          'words': words,
          'wordCount': words.length,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().toUtc().add(_ttl)),
        });
        return code;
      }
    } catch (_) {
      throw const SharedPackException(SharedPackError.network);
    }
    // 5회 모두 충돌 (사실상 불가능).
    throw const SharedPackException(SharedPackError.network);
  }

  /// 코드로 공유 팩을 가져와 로컬에 저장하고 [CustomPack] 반환.
  /// 실패 시 [SharedPackException] throw.
  static Future<CustomPack> redeem(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const SharedPackException(SharedPackError.notFound);
    }
    final db = _db;
    if (db == null) {
      throw const SharedPackException(SharedPackError.network);
    }

    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await db.collection(_collectionPath).doc(code).get();
    } catch (_) {
      throw const SharedPackException(SharedPackError.network);
    }
    if (!snap.exists) {
      throw const SharedPackException(SharedPackError.notFound);
    }
    final data = snap.data() ?? const {};

    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp &&
        expiresAt.toDate().isBefore(DateTime.now().toUtc())) {
      throw const SharedPackException(SharedPackError.expired);
    }

    final words = ((data['words'] as List?) ?? const [])
        .map(
          (e) => ExtractedWord.fromPortableJson(
            (e as Map).cast<String, dynamic>(),
          ).copyWith(clearSaved: true),
        )
        .toList();
    if (words.isEmpty) {
      throw const SharedPackException(SharedPackError.empty);
    }

    final rawName = (data['name'] as String?)?.trim() ?? '';
    final pack = CustomPack(
      id: CustomPackService.generateId(),
      name: rawName.isEmpty ? code : rawName,
      sourcePageId: '',
      words: words,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    await CustomPackService.save(pack);
    return pack;
  }
}

enum SharedPackError { network, notFound, expired, empty }

class SharedPackException implements Exception {
  final SharedPackError error;
  const SharedPackException(this.error);

  @override
  String toString() => 'SharedPackException($error)';
}
