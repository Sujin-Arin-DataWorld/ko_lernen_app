import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../data/profanity_denylist.dart';
import '../models/gye.dart';
import 'account/cloud_write_session.dart';
import 'age_gate_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class GyeLeaveMembership {
  const GyeLeaveMembership({
    required this.uid,
    required this.role,
    this.nickname = '',
    this.membershipId = 'legacy',
  });

  final String uid;
  final String role;
  final String nickname;
  final String membershipId;
}

class GyeLeaveCoordinator {
  const GyeLeaveCoordinator({
    required this.currentUid,
    required this.loadMembership,
    required this.commitLeave,
  });

  final String currentUid;
  final Future<GyeLeaveMembership?> Function(String gyeId) loadMembership;
  final Future<void> Function(String gyeId, GyeLeaveMembership membership)
  commitLeave;

  Future<void> leave(String gyeId) async {
    final membership = await loadMembership(gyeId);
    if (membership == null || membership.uid != currentUid) {
      throw const GyeException(GyeError.network);
    }
    if (membership.role == GyeRole.owner.name) {
      throw const GyeException(GyeError.ownerCannotLeave);
    }
    await commitLeave(gyeId, membership);
  }
}

/// 계(契) CRUD + 입장 코드. Firestore `gye/{code}` (코드 = 문서 ID = gyeId).
///
/// `SharedPackService` 패턴을 따름: nullable `_db`(웹 Firebase 미설정 안전),
/// 6자리 bearer 코드, 충돌 재시도. 실패는 [GyeException]으로 표면화.
/// 멤버십 인덱스는 `users/{uid}.gyeIds`(array) 캐시 — collectionGroup 불필요.
/// plan §7.2/7.3.
/// A rate limiter whose counters belong to one exact cloud-write session.
///
/// Reacquiring the same UID creates a new epoch and therefore a fresh bucket.
class GyeActionRateLimiter {
  GyeActionRateLimiter({
    required this.limit,
    this.window = const Duration(minutes: 1),
  });

  final int limit;
  final Duration window;
  CloudWriteSession? _session;
  final List<DateTime> _attempts = <DateTime>[];

  bool canAttempt(CloudWriteSession session, DateTime now) {
    _prepare(session, now);
    return _attempts.length < limit;
  }

  void record(CloudWriteSession session, DateTime now) {
    _prepare(session, now);
    _attempts.add(now);
  }

  bool tryAcquire(CloudWriteSession session, DateTime now) {
    if (!canAttempt(session, now)) {
      return false;
    }
    record(session, now);
    return true;
  }

  void _prepare(CloudWriteSession session, DateTime now) {
    if (_session != session) {
      _session = session;
      _attempts.clear();
    }
    _attempts.removeWhere((attempt) => now.difference(attempt) >= window);
  }
}

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

  static String generateMembershipId() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// On-device self-attestation only. This is not verified identity or
  /// cryptographic proof of age.
  static void validateAgeEligibility() {
    if (!AgeGateService.isGyeAllowed) {
      throw const GyeException(GyeError.ageRestricted);
    }
  }

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<CloudWriteResult> _runWrite(
    CloudWriteSessionController sessions,
    String uid,
    Future<void> Function() action, {
    CloudWriteSession? snapshot,
  }) {
    final fence = CloudWriteFence(sessions);
    if (snapshot == null) {
      return fence.run(uid: uid, action: action);
    }
    return fence.runWithSnapshot(snapshot: snapshot, uid: uid, action: action);
  }

  static CloudWriteSession? _readySnapshot(
    CloudWriteSessionController sessions,
    String uid,
  ) {
    return CloudWriteFence(sessions).readySnapshot(uid);
  }

  static Stream<T> _bindStream<T>(
    CloudWriteSessionController sessions,
    String uid,
    Stream<T> source,
  ) {
    return CloudWriteFence(sessions).bindStream(uid: uid, source: source);
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
    return myGyeIdsForSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      load: () async {
        final snap = await db.collection('users').doc(uid).get();
        return (snap.data()?['gyeIds'] as List?)?.cast<String>() ?? const [];
      },
    );
  }

  @visibleForTesting
  static Future<List<String>> myGyeIdsForSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<List<String>> Function() load,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = fence.readySnapshot(uid);
    if (snapshot == null) {
      return const [];
    }
    try {
      final ids = await load();
      return fence.verify(snapshot, uid: uid) == CloudWriteResult.completed
          ? ids
          : const [];
    } catch (_) {
      return const [];
    }
  }

  /// 계 생성 → 메타 + 본인 멤버(계장) 문서. 코드 충돌 시 최대 5회 재시도.
  static Future<GyeMeta> createGye({
    required String name,
    required String nickname,
  }) async {
    validateAgeEligibility();
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw const GyeException(GyeError.network);
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      throw const GyeException(GyeError.network);
    }
    final cleanName = validatedName(name, maxNameLen, GyeError.invalidName);
    final cleanNick = validatedName(
      nickname,
      maxNicknameLen,
      GyeError.invalidNickname,
    );
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
          weeklyGoalPacks: 10, // 기본 주간 공동목표 (두레판·롤오버 구동)
        );
        final batch = db.batch();
        batch.set(ref, meta.toCreateJson());
        batch.set(
          ref.collection('members').doc(uid),
          GyeMember(
            uid: uid,
            membershipId: generateMembershipId(),
            nickname: cleanNick,
            role: GyeRole.owner,
            level: Storage.xpLevel,
            streakDays: Storage.streakDays,
          ).toCreateJson(),
        );
        batch.set(db.collection('users').doc(uid), {
          'gyeIds': FieldValue.arrayUnion([code]),
        }, SetOptions(merge: true));
        final write = await _runWrite(
          cloudWriteSessionController,
          uid,
          batch.commit,
          snapshot: session,
        );
        if (write != CloudWriteResult.completed) {
          throw const GyeException(GyeError.network);
        }
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
    validateAgeEligibility();
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      throw const GyeException(GyeError.network);
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      throw const GyeException(GyeError.network);
    }
    final id = code.trim().toUpperCase();
    if (!isValidCodeFormat(id)) {
      throw const GyeException(GyeError.notFound);
    }
    final cleanNick = validatedName(
      nickname,
      maxNicknameLen,
      GyeError.invalidNickname,
    );

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
          GyeMember(
            uid: uid,
            membershipId: generateMembershipId(),
            nickname: cleanNick,
            level: Storage.xpLevel,
            streakDays: Storage.streakDays,
          ).toCreateJson(),
        );
        // 참고: memberCount는 increment(동시 가입 시 근사) — rules + CF가 보강.
        batch.update(ref, {'memberCount': FieldValue.increment(1)});
        batch.set(db.collection('users').doc(uid), {
          'gyeIds': FieldValue.arrayUnion([id]),
        }, SetOptions(merge: true));
        final write = await _runWrite(
          cloudWriteSessionController,
          uid,
          batch.commit,
          snapshot: session,
        );
        if (write != CloudWriteResult.completed) {
          throw const GyeException(GyeError.network);
        }
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
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return null;
    }
    return fetchGyeForSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      load: () async {
        final snap = await db.collection(_collection).doc(id).get();
        if (!snap.exists) {
          return null;
        }
        return GyeMeta.fromDoc(id, snap.data()!);
      },
    );
  }

  @visibleForTesting
  static Future<GyeMeta?> fetchGyeForSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<GyeMeta?> Function() load,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = fence.readySnapshot(uid);
    if (snapshot == null) {
      return null;
    }
    try {
      final meta = await load();
      return fence.verify(snapshot, uid: uid) == CloudWriteResult.completed
          ? meta
          : null;
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
      throw const GyeException(GyeError.network);
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      throw const GyeException(GyeError.network);
    }
    try {
      await GyeLeaveCoordinator(
        currentUid: uid,
        loadMembership: (gyeId) async {
          final snap = await db
              .collection(_collection)
              .doc(gyeId)
              .collection('members')
              .doc(uid)
              .get();
          if (!snap.exists) {
            return null;
          }
          return GyeLeaveMembership(
            uid: uid,
            role: snap.data()?['role'] as String? ?? GyeRole.member.name,
            nickname: snap.data()?['nickname'] as String? ?? '',
            membershipId: snap.data()?['membershipId'] as String? ?? 'legacy',
          );
        },
        commitLeave: (gyeId, membership) async {
          final ref = db.collection(_collection).doc(gyeId);
          final batch = db.batch();
          batch.set(ref.collection('departures').doc(uid), {
            'uid': uid,
            'membershipId': membership.membershipId,
            'nickname': membership.nickname,
            'state': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
          batch.delete(ref.collection('members').doc(uid));
          batch.update(ref, {'memberCount': FieldValue.increment(-1)});
          batch.set(db.collection('users').doc(uid), {
            'gyeIds': FieldValue.arrayRemove([gyeId]),
          }, SetOptions(merge: true));
          final write = await _runWrite(
            cloudWriteSessionController,
            uid,
            batch.commit,
            snapshot: session,
          );
          if (write != CloudWriteResult.completed) {
            throw const GyeException(GyeError.network);
          }
        },
      ).leave(id);
    } on GyeException {
      rethrow;
    } catch (_) {
      throw const GyeException(GyeError.network);
    }
  }

  /// 계 메타 실시간 스트림 (없으면 null).
  static Stream<GyeMeta?> metaStream(String id) {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return Stream.value(null);
    }
    return _bindStream(
      cloudWriteSessionController,
      uid,
      db
          .collection(_collection)
          .doc(id)
          .snapshots()
          .map((s) => s.exists ? GyeMeta.fromDoc(id, s.data()!) : null),
    );
  }

  /// 피드 실시간 스트림 (최근 [limit]개, 최신순).
  static Stream<List<GyeFeedEvent>> feedStream(String id, {int limit = 20}) {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return Stream.value(const []);
    }
    return _bindStream(
      cloudWriteSessionController,
      uid,
      db
          .collection(_collection)
          .doc(id)
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (q) => q.docs
                .map((d) => GyeFeedEvent.fromDoc(d.id, d.data()))
                .toList(),
          ),
    );
  }

  /// 내가 속한 계 메타 목록 (입장 후 다시 들어가기용).
  static Future<List<GyeMeta>> myGyeMetas() async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return const [];
    }
    return myGyeMetasForSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      loadIds: () async {
        final snap = await db.collection('users').doc(uid).get();
        return (snap.data()?['gyeIds'] as List?)?.cast<String>() ?? const [];
      },
      loadMeta: (id) async {
        final snap = await db.collection(_collection).doc(id).get();
        return snap.exists ? GyeMeta.fromDoc(id, snap.data()!) : null;
      },
    );
  }

  @visibleForTesting
  static Future<List<GyeMeta>> myGyeMetasForSession({
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<List<String>> Function() loadIds,
    required Future<GyeMeta?> Function(String id) loadMeta,
  }) async {
    final fence = CloudWriteFence(sessions);
    final snapshot = fence.readySnapshot(uid);
    if (snapshot == null) {
      return const [];
    }
    try {
      final ids = await loadIds();
      if (fence.verify(snapshot, uid: uid) != CloudWriteResult.completed) {
        return const [];
      }
      final out = <GyeMeta>[];
      for (final id in ids) {
        final meta = await loadMeta(id);
        if (fence.verify(snapshot, uid: uid) != CloudWriteResult.completed) {
          return const [];
        }
        if (meta != null) {
          out.add(meta);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// 멤버 실시간 스트림.
  static Stream<List<GyeMember>> membersStream(String id) {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return Stream.value(const []);
    }
    return _bindStream(
      cloudWriteSessionController,
      uid,
      db
          .collection(_collection)
          .doc(id)
          .collection('members')
          .snapshots()
          .map(
            (q) =>
                q.docs.map((d) => GyeMember.fromDoc(d.id, d.data())).toList(),
          ),
    );
  }

  /// 멤버 신고 — `reports`에 append. 본인 신고 불가. 실패 시 false.
  /// (검토·자동 suspend는 3e/3f CF·운영 — 여기선 신고 접수만.)
  static Future<bool> reportMember({
    required String gyeId,
    required String targetUid,
    required GyeReportReason reason,
    String note = '',
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null || uid == targetUid) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () => db
            .collection(_collection)
            .doc(gyeId)
            .collection('reports')
            .doc(
              GyeReport.documentIdFor(targetUid: targetUid, reporterUid: uid),
            )
            .set(
              GyeReport(
                id: '',
                reporterUid: uid,
                targetUid: targetUid,
                reason: reason,
                note: note.trim(),
              ).toCreateJson(),
            ),
        snapshot: session,
      );
      return result == CloudWriteResult.completed;
    } catch (_) {
      return false;
    }
  }

  /// 현재 사용자 uid (UI에서 본인 식별용).
  static String? get currentUid => AuthService.current?.uid;

  /// 클라 레이트 가드 — 분당 10개(인메모리). 일일 100개는 3e CF에서 강화.
  static final GyeActionRateLimiter _stickerRateLimiter = GyeActionRateLimiter(
    limit: 10,
  );

  /// 스티커 전송 — 피드에 이벤트(type: sticker, payload.stickerCode) append.
  /// 레이트 초과/실패 시 false.
  static Future<bool> sendSticker({
    required String gyeId,
    required int code,
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    final now = DateTime.now();
    if (!_stickerRateLimiter.canAttempt(session, now)) {
      return false;
    }
    final ref = db.collection(_collection).doc(gyeId);
    var nickname = '';
    try {
      final m = await ref.collection('members').doc(uid).get();
      nickname = m.data()?['nickname'] as String? ?? '';
    } catch (_) {
      // 닉네임 없이도 전송은 진행
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () async {
          await ref
              .collection('feed')
              .add(
                GyeFeedEvent(
                  id: '',
                  type: GyeFeedType.sticker,
                  actorUid: uid,
                  actorNickname: nickname,
                  payload: {'stickerCode': code},
                ).toCreateJson(),
              );
        },
        snapshot: session,
      );
      if (result != CloudWriteResult.completed) {
        return false;
      }
      _stickerRateLimiter.record(session, now);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 피드 반응 — 특정 피드 이벤트(targetEventId)에 스티커로 답한다.
  /// 일반 스티커와 동일하게 feed에 append하되 `payload.targetEventId`를 달아
  /// 클라이언트가 해당 이벤트 아래에 묶어 렌더한다(자유 텍스트 X = 모더레이션
  /// 안전). 스티커 레이트 가드 공유. 레이트 초과/실패 시 false.
  static Future<bool> sendReaction({
    required String gyeId,
    required String targetEventId,
    required int code,
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null || targetEventId.isEmpty) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    final now = DateTime.now();
    if (!_stickerRateLimiter.canAttempt(session, now)) {
      return false;
    }
    final ref = db.collection(_collection).doc(gyeId);
    var nickname = '';
    try {
      final m = await ref.collection('members').doc(uid).get();
      nickname = m.data()?['nickname'] as String? ?? '';
    } catch (_) {
      // 닉네임 없이도 전송 진행
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () async {
          await ref
              .collection('feed')
              .add(
                GyeFeedEvent(
                  id: '',
                  type: GyeFeedType.sticker,
                  actorUid: uid,
                  actorNickname: nickname,
                  payload: {
                    'stickerCode': code,
                    'targetEventId': targetEventId,
                  },
                ).toCreateJson(),
              );
        },
        snapshot: session,
      );
      if (result != CloudWriteResult.completed) {
        return false;
      }
      _stickerRateLimiter.record(session, now);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 주 단위 dedup 키 — 같은 주의 all-in은 하나의 피드 문서로 수렴.
  /// (CF weekly_goal_rollover가 매주 월요일 기여도 리셋 → 주 경계와 일치.)
  static String _weekKey(DateTime now) {
    // Auf Montag ausgerichtet — weekly_goal_rollover läuft '0 0 * * 1' (Mo),
    // damit deckt sich die Dedup-Woche mit dem Contribution-Reset (sonst
    // Jan-1-Bucket ≠ Wochengrenze → echte 2. all-in würde verschluckt).
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mm = monday.month.toString().padLeft(2, '0');
    final dd = monday.day.toString().padLeft(2, '0');
    return '${monday.year}-$mm-$dd';
  }

  /// 전원 기여 챌린지 달성 → 피드에 1회 기록 (D-4).
  /// **결정적 doc id**(`allin_<주키>`)로 set: 여러 멤버 클라가 동시에 감지해도
  /// 첫 작성만 create(허용), 나머지는 update라 rules가 거부 → **중복 0**.
  /// best-effort: 실패(이미 존재·권한)해도 조용히 무시. 화면 burst와 별개.
  static Future<void> markAllInAchieved(String gyeId) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return;
    }
    final docId = 'allin_${_weekKey(DateTime.now())}';
    final ref = db.collection(_collection).doc(gyeId);
    var nickname = '';
    try {
      final m = await ref.collection('members').doc(uid).get();
      nickname = m.data()?['nickname'] as String? ?? '';
    } catch (_) {
      // 닉네임 없이도 진행
    }
    try {
      // create-only: 문서가 이미 있으면 set은 update가 되어 rules가 거부 → dedup.
      await _runWrite(
        cloudWriteSessionController,
        uid,
        () => ref
            .collection('feed')
            .doc(docId)
            .set(
              GyeFeedEvent(
                id: docId,
                type: GyeFeedType.allInChallenge,
                actorUid: uid,
                actorNickname: nickname,
              ).toCreateJson(),
            ),
        snapshot: session,
      );
    } catch (_) {
      // 이미 기록됨(다른 멤버가 먼저) 또는 권한 → 무시. burst는 화면이 담당.
    }
  }

  /// 마일스톤 이벤트(퀘스트 완료·레벨업 등)를 내 모든 계 피드에 broadcast.
  /// 학습 성취가 계원에게 보이게 → 축하 스티커 유도 (2픽 피드 풍부화).
  /// best-effort: 한 계 실패해도 나머지 진행. 계 없으면 no-op.
  static Future<void> broadcastFeed(
    GyeFeedType type,
    Map<String, dynamic> payload,
  ) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return;
    }
    for (final gid in await myGyeIds()) {
      try {
        final ref = db.collection(_collection).doc(gid);
        final m = await ref.collection('members').doc(uid).get();
        final nickname = m.data()?['nickname'] as String? ?? '';
        final result = await _runWrite(
          cloudWriteSessionController,
          uid,
          () async {
            await ref
                .collection('feed')
                .add(
                  GyeFeedEvent(
                    id: '',
                    type: type,
                    actorUid: uid,
                    actorNickname: nickname,
                    payload: payload,
                  ).toCreateJson(),
                );
          },
          snapshot: session,
        );
        if (result != CloudWriteResult.completed) {
          return;
        }
      } catch (_) {
        // 한 계 실패해도 나머지 진행
      }
    }
  }

  /// 레벨이 올랐으면 계 피드에 levelUp broadcast (lastGyeLevel 비교로 중복 방지).
  /// 순환(storage→gye) 회피 위해 storage가 아닌 여기서 pull — persist 등에서 호출.
  static Future<void> syncLevelUp() async {
    final cur = Storage.xpLevel;
    if (cur > Storage.lastGyeLevel) {
      await broadcastFeed(GyeFeedType.levelUp, {'level': cur});
      await Storage.setLastGyeLevel(cur);
    }
  }

  /// 내 멤버 문서에 level/streak denormalize (프로필 카드용, best-effort).
  /// 계 화면 진입 시 호출 — rules가 본인 멤버 문서 수정 허용(status 제외).
  static Future<void> syncMyMemberStats() async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return;
    }
    final stats = {'level': Storage.xpLevel, 'streakDays': Storage.streakDays};
    for (final gid in await myGyeIds()) {
      try {
        final result = await _runWrite(
          cloudWriteSessionController,
          uid,
          () => db
              .collection(_collection)
              .doc(gid)
              .collection('members')
              .doc(uid)
              .set(stats, SetOptions(merge: true)),
          snapshot: session,
        );
        if (result != CloudWriteResult.completed) {
          return;
        }
      } catch (_) {
        // best-effort — 한 계 실패해도 나머지 진행
      }
    }
  }

  /// 응원 레이트 — 분당 10개(인메모리).
  static final GyeActionRateLimiter _cheerRateLimiter = GyeActionRateLimiter(
    limit: 10,
  );

  /// 응원 보내기 — 정형 격려(cheerCode 1~5)를 계 피드에 append (3픽 리텐션 훅).
  /// 자유 텍스트가 아니라 코드라 모더레이션 안전. 레이트 초과/실패 시 false.
  static Future<bool> sendCheer({
    required String gyeId,
    required String targetUid,
    required String targetNickname,
    required int cheerCode,
  }) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    final now = DateTime.now();
    if (!_cheerRateLimiter.canAttempt(session, now)) {
      return false;
    }
    final ref = db.collection(_collection).doc(gyeId);
    var nickname = '';
    try {
      final m = await ref.collection('members').doc(uid).get();
      nickname = m.data()?['nickname'] as String? ?? '';
    } catch (_) {
      // 닉네임 없이도 전송 진행
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () async {
          await ref
              .collection('feed')
              .add(
                GyeFeedEvent(
                  id: '',
                  type: GyeFeedType.cheer,
                  actorUid: uid,
                  actorNickname: nickname,
                  payload: {
                    'targetUid': targetUid,
                    'targetNickname': targetNickname,
                    'cheerCode': cheerCode,
                  },
                ).toCreateJson(),
              );
        },
        snapshot: session,
      );
      if (result != CloudWriteResult.completed) {
        return false;
      }
      _cheerRateLimiter.record(session, now);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── 차단 (Play UGC 정책: 사용자 주도 콘텐츠 숨김) ─────────────────────
  // 저장 위치: users/{me}.blockedUids (array) — 본인만 read/write(기존 rules),
  // 크로스기기 동기. 차단한 사용자의 피드 이벤트(스티커·응원 포함)는
  // 클라이언트에서 숨긴다 (filterBlocked). 신고(reportMember)와 독립.

  /// 사용자 차단. 본인 차단 불가. 실패 시 false.
  static Future<bool> blockUser(String targetUid) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null || uid == targetUid) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () => db.collection('users').doc(uid).set({
          'blockedUids': FieldValue.arrayUnion([targetUid]),
        }, SetOptions(merge: true)),
        snapshot: session,
      );
      return result == CloudWriteResult.completed;
    } catch (_) {
      return false;
    }
  }

  /// 차단 해제. 실패 시 false.
  static Future<bool> unblockUser(String targetUid) async {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return false;
    }
    final session = _readySnapshot(cloudWriteSessionController, uid);
    if (session == null) {
      return false;
    }
    try {
      final result = await _runWrite(
        cloudWriteSessionController,
        uid,
        () => db.collection('users').doc(uid).set({
          'blockedUids': FieldValue.arrayRemove([targetUid]),
        }, SetOptions(merge: true)),
        snapshot: session,
      );
      return result == CloudWriteResult.completed;
    } catch (_) {
      return false;
    }
  }

  /// 내가 차단한 uid 집합 (실시간). Firebase 미설정 시 빈 집합 스트림.
  static Stream<Set<String>> blockedUidsStream() {
    final uid = AuthService.current?.uid;
    final db = _db;
    if (uid == null || db == null) {
      return Stream.value(const <String>{});
    }
    return _bindStream(
      cloudWriteSessionController,
      uid,
      db
          .collection('users')
          .doc(uid)
          .snapshots()
          .map(
            (d) => ((d.data()?['blockedUids'] as List?) ?? const [])
                .whereType<String>()
                .toSet(),
          ),
    );
  }

  /// 차단 필터 — 차단한 사용자의 피드 이벤트 + 그를 향한/그가 보낸 응원 숨김.
  /// 순수 함수 (단위테스트 대상).
  static List<GyeFeedEvent> filterBlocked(
    List<GyeFeedEvent> events,
    Set<String> blocked,
  ) {
    if (blocked.isEmpty) {
      return events;
    }
    return events
        .where(
          (e) =>
              !blocked.contains(e.actorUid) &&
              !blocked.contains(e.payload['targetUid'] as String? ?? ''),
        )
        .toList();
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
  ageRestricted,
  ownerCannotLeave,
}

class GyeException implements Exception {
  final GyeError error;
  const GyeException(this.error);

  @override
  String toString() => 'GyeException($error)';
}
