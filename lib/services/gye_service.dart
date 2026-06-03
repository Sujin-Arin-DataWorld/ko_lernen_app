import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/profanity_denylist.dart';
import '../models/gye.dart';
import 'auth_service.dart';

/// 계(契) CRUD + 입장 코드. Firestore `gye/{code}` (코드 = 문서 ID = gyeId).
///
/// `SharedPackService` 패턴을 따름: nullable `_db`(웹 Firebase 미설정 안전),
/// 6자리 bearer 코드, 충돌 재시도. 실패는 [GyeException]으로 표면화.
/// 멤버십 인덱스는 `users/{uid}.gyeIds`(array) 캐시 — collectionGroup 불필요.
/// plan §7.2/7.3.
class GyeService {
  static final math.Random _rng = math.Random.secure();
  static const String _collection = 'gye';

  /// 혼동되는 글자(O,0,I,1,L) 제외 — SharedPackService와 동일.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int codeLength = 6;

  static const int maxMembers = 10; // 계장 + 9
  static const int maxGyePerUser = 3;
  static const int maxNameLen = 20;
  static const int maxNicknameLen = 12;

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ── 순수 헬퍼 (테스트 가능) ─────────────────────────────────────────────
  static String generateCode() => List.generate(
        codeLength,
        (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)],
      ).join();

  static bool isValidCodeFormat(String code) {
    final c = code.trim().toUpperCase();
    if (c.length != codeLength) {
      return false;
    }
    for (final ch in c.split('')) {
      if (!_codeAlphabet.contains(ch)) {
        return false;
      }
    }
    return true;
  }

  /// 이름/닉네임 검증(길이 + 욕설). 통과 시 trim 문자열, 실패 시 throw.
  static String validatedName(String raw, int maxLen, GyeError tooLong) {
    final v = raw.trim();
    if (v.isEmpty || v.length > maxLen) {
      throw GyeException(tooLong);
    }
    if (containsProfanity(v)) {
      throw const GyeException(GyeError.profanity);
    }
    return v;
  }

  // ── Firestore ──────────────────────────────────────────────────────────
  /// 내가 속한 계 id 목록 (`users/{uid}.gyeIds` 캐시).
  static Future<List<String>> myGyeIds() async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return const [];
    }
    try {
      final snap = await db.collection('users').doc(uid).get();
      return (snap.data()?['gyeIds'] as List?)?.cast<String>() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// 계 생성 → 메타 + 본인 멤버(계장) 문서. 코드 충돌 시 최대 5회 재시도.
  static Future<GyeMeta> createGye({
    required String name,
    required String nickname,
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw const GyeException(GyeError.network);
    }
    final cleanName = validatedName(name, maxNameLen, GyeError.invalidName);
    final cleanNick =
        validatedName(nickname, maxNicknameLen, GyeError.invalidNickname);
    if ((await myGyeIds()).length >= maxGyePerUser) {
      throw const GyeException(GyeError.tooManyGye);
    }
    try {
      for (var attempt = 0; attempt < 5; attempt++) {
        final code = generateCode();
        final ref = db.collection(_collection).doc(code);
        if ((await ref.get()).exists) {
          continue;
        }
        final meta = GyeMeta(
          id: code,
          name: cleanName,
          code: code,
          ownerId: uid,
        );
        final batch = db.batch();
        batch.set(ref, meta.toCreateJson());
        batch.set(
          ref.collection('members').doc(uid),
          GyeMember(uid: uid, nickname: cleanNick, role: GyeRole.owner)
              .toCreateJson(),
        );
        batch.set(
          db.collection('users').doc(uid),
          {
            'gyeIds': FieldValue.arrayUnion([code]),
          },
          SetOptions(merge: true),
        );
        await batch.commit();
        return meta;
      }
      throw const GyeException(GyeError.network); // 5회 충돌 (사실상 불가능)
    } on GyeException {
      rethrow;
    } catch (_) {
      throw const GyeException(GyeError.network);
    }
  }

  /// 코드로 계 입장. 이미 멤버면 그대로 메타 반환.
  static Future<GyeMeta> joinGye({
    required String code,
    required String nickname,
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw const GyeException(GyeError.network);
    }
    final id = code.trim().toUpperCase();
    if (!isValidCodeFormat(id)) {
      throw const GyeException(GyeError.notFound);
    }
    final cleanNick =
        validatedName(nickname, maxNicknameLen, GyeError.invalidNickname);

    final mine = await myGyeIds();
    final alreadyMine = mine.contains(id);
    if (!alreadyMine && mine.length >= maxGyePerUser) {
      throw const GyeException(GyeError.tooManyGye);
    }

    final ref = db.collection(_collection).doc(id);
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        throw const GyeException(GyeError.notFound);
      }
      final meta = GyeMeta.fromDoc(id, snap.data()!);
      final memberRef = ref.collection('members').doc(uid);
      final already = (await memberRef.get()).exists;
      if (!already && meta.memberCount >= maxMembers) {
        throw const GyeException(GyeError.full);
      }
      if (!already) {
        final batch = db.batch();
        batch.set(
          memberRef,
          GyeMember(uid: uid, nickname: cleanNick).toCreateJson(),
        );
        // 참고: memberCount는 increment(동시 가입 시 근사) — rules + CF가 보강.
        batch.update(ref, {'memberCount': FieldValue.increment(1)});
        batch.set(
          db.collection('users').doc(uid),
          {
            'gyeIds': FieldValue.arrayUnion([id]),
          },
          SetOptions(merge: true),
        );
        await batch.commit();
      }
      return meta;
    } on GyeException {
      rethrow;
    } catch (_) {
      throw const GyeException(GyeError.network);
    }
  }

  /// 계 메타 1건 읽기 (없으면 null).
  static Future<GyeMeta?> fetchGye(String id) async {
    final db = _db;
    if (db == null) {
      return null;
    }
    try {
      final snap = await db.collection(_collection).doc(id).get();
      if (!snap.exists) {
        return null;
      }
      return GyeMeta.fromDoc(id, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  /// 계 탈퇴 — 본인 멤버 문서 제거 + memberCount 감소 + 캐시 정리.
  /// (계장 탈퇴/위임은 후속 단계에서.)
  static Future<void> leaveGye(String id) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return;
    }
    final ref = db.collection(_collection).doc(id);
    try {
      final batch = db.batch();
      batch.delete(ref.collection('members').doc(uid));
      batch.update(ref, {'memberCount': FieldValue.increment(-1)});
      batch.set(
        db.collection('users').doc(uid),
        {
          'gyeIds': FieldValue.arrayRemove([id]),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (_) {
      // best-effort
    }
  }
}

enum GyeError {
  network,
  notFound,
  full,
  tooManyGye,
  invalidName,
  invalidNickname,
  profanity,
}

class GyeException implements Exception {
  final GyeError error;
  const GyeException(this.error);

  @override
  String toString() => 'GyeException($error)';
}
