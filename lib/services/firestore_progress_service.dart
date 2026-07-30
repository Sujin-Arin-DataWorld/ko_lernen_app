import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pack_progress.dart';
import 'account/cloud_read_result.dart';
import 'account/cloud_write_session.dart';
import 'auth_service.dart';

class FirestorePackDocument {
  const FirestorePackDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class FirestorePackSnapshot {
  const FirestorePackSnapshot({
    required this.progress,
    required this.revisions,
    this.membershipRevision,
  });

  final Map<String, PackProgress> progress;
  final Map<String, int?> revisions;
  final int? membershipRevision;
}

class FirestorePackMembership {
  const FirestorePackMembership({
    required this.revision,
    required this.packIds,
  });

  final int revision;

  /// Best-effort idempotency metadata. [revision], which every writer advances,
  /// is the authoritative collection-membership generation.
  final Set<String> packIds;

  FirestorePackMembership afterWriting(Iterable<String> writtenPackIds) =>
      FirestorePackMembership(
        revision: revision + 1,
        packIds: {...packIds, ...writtenPackIds},
      );
}

typedef FirestorePackReader =
    Future<List<FirestorePackDocument>> Function(String uid);
typedef FirestorePackMembershipReader =
    Future<FirestorePackMembership?> Function(String uid);
typedef FirestoreSinglePackReader =
    Future<FirestorePackDocument?> Function(String uid, String packId);

enum FirestorePackCasStatus { committed, revisionConflict }

class FirestorePackCasResult {
  const FirestorePackCasResult.committed(
    this.revisions, {
    required int membershipRevision,
    required this.membershipPackIds,
  }) : assert(membershipRevision >= 0),
       membershipRevision = membershipRevision,
       status = FirestorePackCasStatus.committed;

  const FirestorePackCasResult.revisionConflict()
    : status = FirestorePackCasStatus.revisionConflict,
      revisions = const {},
      membershipRevision = null,
      membershipPackIds = const {};

  final FirestorePackCasStatus status;
  final Map<String, int> revisions;
  final int? membershipRevision;
  final Set<String> membershipPackIds;
}

typedef FirestorePackCasWriter =
    Future<FirestorePackCasResult> Function({
      required String uid,
      required Iterable<PackProgress> progresses,
      required Map<String, int?> expectedRevisions,
      required int? expectedMembershipRevision,
      required Set<String> expectedMembershipPackIds,
      required String operationId,
      required CloudWriteSession session,
      required CloudWriteSessionController sessions,
    });

/// Firestore CRUD for `users/{uid}/packs/{packId}` (Phase 1).
///
/// **로컬 SoT 원칙**: 학습 중에는 `Storage` (SharedPreferences) 가 source of
/// truth. 이 서비스는 백업·복원 채널이다. UI 가 작업 후 `savePack()` 을
/// best-effort 로 호출, 실패해도 로컬은 영향 받지 않음.
///
/// **Web 가드**: Firebase 가 초기화 안 된 환경 (Web ohne Config) 에서는
/// 모든 메서드가 조용히 no-op 또는 빈 결과 반환 — `AuthService` 와 동일
/// 패턴.
class FirestoreProgressService {
  static const int defaultReadLimitBytes = 512 * 1024;

  static FirestorePackReader firestorePackReader(FirebaseFirestore firestore) =>
      (uid) => _readFirestorePacks(firestore, uid);

  static FirestorePackMembershipReader firestoreMembershipReader(
    FirebaseFirestore firestore,
  ) =>
      (uid) => _readMembershipOnce(firestore, uid);

  static FirestorePackCasWriter firestoreCasWriter({
    required FirebaseFirestore firestore,
    required String fenceUid,
  }) {
    return ({
      required uid,
      required progresses,
      required expectedRevisions,
      required expectedMembershipRevision,
      required expectedMembershipPackIds,
      required operationId,
      required session,
      required sessions,
    }) => _writeFirestorePacks(
      firestore: firestore,
      uid: uid,
      fenceUid: fenceUid,
      progresses: progresses,
      expectedRevisions: expectedRevisions,
      expectedMembershipRevision: expectedMembershipRevision,
      expectedMembershipPackIds: expectedMembershipPackIds,
      operationId: operationId,
      session: session,
      sessions: sessions,
    );
  }

  /// Lazy getter — Firestore 초기화 실패 시 null.
  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static CollectionReference<Map<String, dynamic>>? _packsCollection() {
    final db = _db;
    final uid = AuthService.cloudBackupUid;
    if (db == null || uid == null) return null;
    return db.collection('users').doc(uid).collection('packs');
  }

  /// 모든 팩 진행도 (cleared 여부 + 통계) load. Empty map = 미존재 또는 offline.
  static Future<Map<String, PackProgress>> loadAll() async {
    final ref = _packsCollection();
    if (ref == null) return {};
    try {
      final snap = await ref.get();
      return {
        for (final doc in snap.docs)
          doc.id: PackProgress.fromJson(doc.id, doc.data()),
      };
    } catch (_) {
      // 네트워크 / 권한 오류 — 로컬 SoT 유지, 백업만 실패.
      return {};
    }
  }

  /// Typed reconciliation read. A query error is never reported as absence.
  static Future<CloudReadResult<FirestorePackSnapshot>> loadAllTyped({
    required String uid,
    FirestorePackReader? reader,
    FirestorePackMembershipReader? membershipReader,
    int maxBytes = defaultReadLimitBytes,
  }) async {
    if (uid.trim().isEmpty || maxBytes < 1) {
      return const CloudReadResult.invalid();
    }
    final membershipBefore = await _readMembershipForTypedRead(
      uid: uid,
      reader: reader,
      membershipReader: membershipReader,
    );
    if (membershipBefore.state == CloudReadState.unavailable) {
      return const CloudReadResult.unavailable();
    }
    if (membershipBefore.state == CloudReadState.invalid ||
        membershipBefore.state == CloudReadState.tooLarge) {
      return const CloudReadResult.invalid();
    }
    late List<FirestorePackDocument> documents;
    try {
      documents =
          await (reader ?? firestorePackReader(FirebaseFirestore.instance))(
            uid,
          );
    } catch (_) {
      return const CloudReadResult.unavailable();
    }
    final membership = await _readMembershipForTypedRead(
      uid: uid,
      reader: reader,
      membershipReader: membershipReader,
    );
    if (membership.state == CloudReadState.unavailable) {
      return const CloudReadResult.unavailable();
    }
    if (membership.state == CloudReadState.invalid ||
        membership.state == CloudReadState.tooLarge) {
      return const CloudReadResult.invalid();
    }
    if (!_sameMembershipReads(membershipBefore, membership)) {
      return const CloudReadResult.unavailable();
    }
    if (membership.state == CloudReadState.present &&
        !_sameIds(
          membership.value!.packIds,
          documents.map((document) => document.id).toSet(),
        )) {
      return const CloudReadResult.invalid();
    }
    if (documents.isEmpty) {
      if (membership.state != CloudReadState.present) {
        return switch (membership.state) {
          CloudReadState.absent => const CloudReadResult.absent(),
          CloudReadState.unavailable => const CloudReadResult.unavailable(),
          CloudReadState.invalid => const CloudReadResult.invalid(),
          CloudReadState.tooLarge => const CloudReadResult.tooLarge(),
          CloudReadState.present => throw StateError('unreachable'),
        };
      }
      return CloudReadResult.present(
        FirestorePackSnapshot(
          progress: const {},
          revisions: const {},
          membershipRevision: membership.value!.revision,
        ),
      );
    }

    final progress = <String, PackProgress>{};
    final revisions = <String, int?>{};
    final sizePayload = <Object?>[];
    try {
      for (final document in documents) {
        if (document.id.trim().isEmpty ||
            progress.containsKey(document.id) ||
            !_validPackJson(document.data)) {
          return const CloudReadResult.invalid();
        }
        final revision = document.data['sync_revision'];
        if (revision != null && (revision is! int || revision < 0)) {
          return const CloudReadResult.invalid();
        }
        final data = Map<String, dynamic>.from(document.data)
          ..remove('updatedAt')
          ..remove('sync_revision')
          ..remove('reconciliation_operation_id');
        sizePayload.add({'id': document.id, 'data': data});
        progress[document.id] = PackProgress.fromJson(document.id, data);
        revisions[document.id] = revision as int?;
      }
      if (utf8.encode(jsonEncode(sizePayload)).length > maxBytes) {
        return const CloudReadResult.tooLarge();
      }
    } catch (_) {
      return const CloudReadResult.invalid();
    }
    return CloudReadResult.present(
      FirestorePackSnapshot(
        progress: progress,
        revisions: revisions,
        membershipRevision: membership.value?.revision,
      ),
    );
  }

  static Future<FirestorePackCasResult> saveManyReconciled({
    required String uid,
    String? fenceUid,
    required Iterable<PackProgress> progresses,
    required Map<String, int?> expectedRevisions,
    required int? expectedMembershipRevision,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    FirestorePackCasWriter? writer,
  }) {
    final expectedFenceUid = fenceUid ?? uid;
    if (session.mode != CloudWriteMode.reconciling ||
        session.uid != expectedFenceUid) {
      return Future.value(const FirestorePackCasResult.revisionConflict());
    }
    try {
      sessions.assertCurrent(session);
    } on StateError {
      return Future.value(const FirestorePackCasResult.revisionConflict());
    }
    final values = progresses.toList();
    final targetIds = values.map((progress) => progress.packId).toSet();
    final expectedMembershipPackIds = expectedRevisions.keys.toSet();
    if (targetIds.length != values.length ||
        !targetIds.containsAll(expectedMembershipPackIds)) {
      return Future.value(const FirestorePackCasResult.revisionConflict());
    }
    final selectedWriter =
        writer ??
        ({
          required uid,
          required progresses,
          required expectedRevisions,
          required expectedMembershipRevision,
          required expectedMembershipPackIds,
          required operationId,
          required session,
          required sessions,
        }) => _writeFirestorePacks(
          firestore: FirebaseFirestore.instance,
          uid: uid,
          fenceUid: expectedFenceUid,
          progresses: progresses,
          expectedRevisions: expectedRevisions,
          expectedMembershipRevision: expectedMembershipRevision,
          expectedMembershipPackIds: expectedMembershipPackIds,
          operationId: operationId,
          session: session,
          sessions: sessions,
        );
    return selectedWriter(
      uid: uid,
      progresses: values,
      expectedRevisions: expectedRevisions,
      expectedMembershipRevision: expectedMembershipRevision,
      expectedMembershipPackIds: expectedMembershipPackIds,
      operationId: operationId,
      session: session,
      sessions: sessions,
    );
  }

  static Future<List<FirestorePackDocument>> _readFirestorePacks(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('packs')
        .get();
    return [
      for (final document in snapshot.docs)
        FirestorePackDocument(id: document.id, data: document.data()),
    ];
  }

  static Future<CloudReadResult<FirestorePackMembership>>
  _readMembershipForTypedRead({
    required String uid,
    required FirestorePackReader? reader,
    required FirestorePackMembershipReader? membershipReader,
  }) async {
    final selected =
        membershipReader ?? (reader == null ? _readMembership : null);
    if (selected == null) {
      return const CloudReadResult.absent();
    }
    try {
      final membership = await selected(uid);
      if (membership == null) {
        return const CloudReadResult.absent();
      }
      if (membership.revision < 0 ||
          membership.packIds.any((id) => id.trim().isEmpty)) {
        return const CloudReadResult.invalid();
      }
      return CloudReadResult.present(membership);
    } catch (error) {
      return error is FormatException
          ? const CloudReadResult.invalid()
          : const CloudReadResult.unavailable();
    }
  }

  static Future<FirestorePackMembership?> _readMembership(String uid) =>
      _readMembershipOnce(FirebaseFirestore.instance, uid);

  static Future<FirestorePackMembership?> _readMembershipOnce(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final snapshot = await _membershipDocument(firestore, uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    final revision = data['revision'];
    final rawIds = data['pack_ids'];
    if (revision is! int || revision < 0 || rawIds is! List) {
      throw const FormatException('Invalid pack membership manifest.');
    }
    final ids = <String>{};
    for (final value in rawIds) {
      if (value is! String || value.trim().isEmpty || !ids.add(value)) {
        throw const FormatException('Invalid pack membership manifest.');
      }
    }
    return FirestorePackMembership(revision: revision, packIds: ids);
  }

  static bool _validPackJson(Map<String, dynamic> data) {
    final status = data['status'];
    return data['level'] is String &&
        (status is String &&
            PackStatus.values.any((value) => value.name == status)) &&
        data['wordsLearned'] is int &&
        data['wordsTotal'] is int &&
        data['bossAccuracy'] is num &&
        data['attempts'] is int &&
        (data['clearedAt'] == null || data['clearedAt'] is String);
  }

  static Future<FirestorePackCasResult> _writeFirestorePacks({
    required FirebaseFirestore firestore,
    required String uid,
    required String fenceUid,
    required Iterable<PackProgress> progresses,
    required Map<String, int?> expectedRevisions,
    required int? expectedMembershipRevision,
    required Set<String> expectedMembershipPackIds,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) {
    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('packs');
    final membershipRef = _membershipDocument(firestore, uid);
    final values = progresses.toList();
    return firestore.runTransaction((transaction) async {
      final membershipSnapshot = await transaction.get(membershipRef);
      final membershipData = membershipSnapshot.data();
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final progress in values) {
        snapshots[progress.packId] = await transaction.get(
          collection.doc(progress.packId),
        );
      }
      if (membershipData?['reconciliation_operation_id'] == operationId) {
        final revision = membershipData?['revision'];
        final ids = _manifestIds(membershipData);
        if (revision is! int ||
            ids == null ||
            !_sameIds(ids, values.map((value) => value.packId).toSet())) {
          return const FirestorePackCasResult.revisionConflict();
        }
        final revisions = <String, int>{};
        for (final progress in values) {
          final current = snapshots[progress.packId]?.data();
          final packRevision = current?['sync_revision'];
          if (current == null ||
              current['reconciliation_operation_id'] != operationId ||
              packRevision is! int ||
              !_containsProgress(current, progress.toJson())) {
            return const FirestorePackCasResult.revisionConflict();
          }
          revisions[progress.packId] = packRevision;
        }
        return FirestorePackCasResult.committed(
          revisions,
          membershipRevision: revision,
          membershipPackIds: ids,
        );
      }
      final currentMembershipRevision = membershipSnapshot.exists
          ? (membershipData?['revision'])
          : null;
      if (currentMembershipRevision != expectedMembershipRevision) {
        return const FirestorePackCasResult.revisionConflict();
      }
      if (membershipSnapshot.exists) {
        final currentMembershipPackIds = _manifestIds(membershipData);
        if (currentMembershipPackIds == null ||
            !_sameIds(currentMembershipPackIds, expectedMembershipPackIds)) {
          return const FirestorePackCasResult.revisionConflict();
        }
      }
      final revisions = <String, int>{};
      for (final progress in values) {
        final snapshot = snapshots[progress.packId]!;
        final current = snapshot.data();
        final currentRevision = snapshot.exists && current != null
            ? current['sync_revision']
            : null;
        if (currentRevision != expectedRevisions[progress.packId]) {
          return const FirestorePackCasResult.revisionConflict();
        }
      }
      sessions.assertCurrent(session);
      if (session.mode != CloudWriteMode.reconciling ||
          session.uid != fenceUid) {
        return const FirestorePackCasResult.revisionConflict();
      }
      for (final progress in values) {
        final nextRevision = (expectedRevisions[progress.packId] ?? 0) + 1;
        transaction.set(collection.doc(progress.packId), {
          ...progress.toJson(),
          'sync_revision': nextRevision,
          'reconciliation_operation_id': operationId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        revisions[progress.packId] = nextRevision;
      }
      transaction.set(membershipRef, {
        'revision': (expectedMembershipRevision ?? 0) + 1,
        'pack_ids': values.map((value) => value.packId).toList()..sort(),
        'reconciliation_operation_id': operationId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return FirestorePackCasResult.committed(
        revisions,
        membershipRevision: (expectedMembershipRevision ?? 0) + 1,
        membershipPackIds: values.map((value) => value.packId).toSet(),
      );
    });
  }

  /// 단일 팩 진행도 fetch. null = 미존재 / 오류.
  static Future<PackProgress?> loadPack(String packId) async {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) return null;
    final result = await loadPackTyped(uid: uid, packId: packId);
    return result.isPresent ? result.value : null;
  }

  static Future<CloudReadResult<PackProgress>> loadPackTyped({
    required String uid,
    required String packId,
    FirestoreSinglePackReader? reader,
    int maxBytes = defaultReadLimitBytes,
  }) async {
    if (packId.trim().isEmpty) {
      return const CloudReadResult.invalid();
    }
    final result = await loadAllTyped(
      uid: uid,
      maxBytes: maxBytes,
      reader: (_) async {
        final document = await (reader ?? _readFirestorePack)(uid, packId);
        return document == null ? const [] : [document];
      },
    );
    return switch (result.state) {
      CloudReadState.present => CloudReadResult.present(
        result.value!.progress[packId]!,
        revision: result.value!.revisions[packId],
      ),
      CloudReadState.absent => const CloudReadResult.absent(),
      CloudReadState.unavailable => const CloudReadResult.unavailable(),
      CloudReadState.invalid => const CloudReadResult.invalid(),
      CloudReadState.tooLarge => const CloudReadResult.tooLarge(),
    };
  }

  static Future<FirestorePackDocument?> _readFirestorePack(
    String uid,
    String packId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('packs')
        .doc(packId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return FirestorePackDocument(id: snapshot.id, data: data);
  }

  /// 단일 팩 진행도 저장 (merge). 실패는 silently ignored.
  static Future<void> savePack(PackProgress p) async {
    await savePackWithResult(p);
  }

  static Future<CloudWriteResult> savePackWithResult(PackProgress p) async {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      return CloudWriteResult.blocked;
    }
    FirebaseFirestore? firestore;
    Map<String, dynamic>? payload;
    return savePackWithSession(
      p,
      sessions: cloudWriteSessionController,
      uid: uid,
      prepare: () async {
        final db = _db;
        if (db == null) {
          return;
        }
        firestore = db;
        payload = Map<String, dynamic>.from(p.toJson())
          ..['updatedAt'] = FieldValue.serverTimestamp()
          ..['sync_revision'] = FieldValue.increment(1)
          ..['reconciliation_operation_id'] = FieldValue.delete();
      },
      write: () async {
        final db = firestore;
        final data = payload;
        if (db != null && data != null) {
          final collection = db
              .collection('users')
              .doc(uid)
              .collection('packs');
          final membershipRef = _membershipDocument(db, uid);
          await db.runTransaction((transaction) async {
            final membershipSnapshot = await transaction.get(membershipRef);
            final current = _membershipFromData(
              membershipSnapshot.data(),
              exists: membershipSnapshot.exists,
            );
            final next = current.afterWriting([p.packId]);
            transaction.set(
              collection.doc(p.packId),
              data,
              SetOptions(merge: true),
            );
            transaction.set(membershipRef, {
              'revision': next.revision,
              'pack_ids': next.packIds.toList()..sort(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        }
      },
    );
  }

  static Future<CloudWriteResult> savePackWithSession(
    PackProgress p, {
    required CloudWriteSessionController sessions,
    required String uid,
    required Future<void> Function() prepare,
    required Future<void> Function() write,
  }) async {
    try {
      return await CloudWriteFence(
        sessions,
      ).run(uid: uid, prepare: prepare, action: write);
    } catch (_) {
      return CloudWriteResult.blocked;
    }
  }

  /// 배치 저장 — 마이그레이션 / 다중 팩 동시 update 용.
  static Future<void> saveMany(Iterable<PackProgress> progresses) async {
    await saveManyWithResult(progresses);
  }

  static Future<CloudWriteResult> saveManyWithResult(
    Iterable<PackProgress> progresses,
  ) async {
    final uid = AuthService.cloudBackupUid;
    if (uid == null) {
      return CloudWriteResult.blocked;
    }
    return saveManyWithSession(
      progresses,
      sessions: cloudWriteSessionController,
      uid: uid,
    );
  }

  static Future<CloudWriteResult> saveManyWithSession(
    Iterable<PackProgress> progresses, {
    required CloudWriteSessionController sessions,
    required String uid,
  }) async {
    final values = progresses.toList();
    FirebaseFirestore? firestore;
    try {
      return await CloudWriteFence(sessions).run(
        uid: uid,
        prepare: () async {
          final db = _db;
          if (db == null) {
            return;
          }
          firestore = db;
        },
        action: () async {
          final db = firestore;
          if (db == null || values.isEmpty) return;
          final ref = db.collection('users').doc(uid).collection('packs');
          final membershipRef = _membershipDocument(db, uid);
          await db.runTransaction((transaction) async {
            final membershipSnapshot = await transaction.get(membershipRef);
            final current = _membershipFromData(
              membershipSnapshot.data(),
              exists: membershipSnapshot.exists,
            );
            final next = current.afterWriting(
              values.map((value) => value.packId),
            );
            for (final p in values) {
              final payload = Map<String, dynamic>.from(p.toJson());
              payload['updatedAt'] = FieldValue.serverTimestamp();
              payload['sync_revision'] = FieldValue.increment(1);
              payload['reconciliation_operation_id'] = FieldValue.delete();
              transaction.set(
                ref.doc(p.packId),
                payload,
                SetOptions(merge: true),
              );
            }
            transaction.set(membershipRef, {
              'revision': next.revision,
              'pack_ids': next.packIds.toList()..sort(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        },
      );
    } catch (_) {
      return CloudWriteResult.blocked;
    }
  }

  static bool _containsProgress(
    Map<String, dynamic> current,
    Map<String, dynamic> expected,
  ) {
    for (final entry in expected.entries) {
      if (current[entry.key] != entry.value) return false;
    }
    return true;
  }

  static DocumentReference<Map<String, dynamic>> _membershipDocument(
    FirebaseFirestore firestore,
    String uid,
  ) => firestore
      .collection('users')
      .doc(uid)
      .collection('sync_metadata')
      .doc('pack_progress');

  static Set<String>? _manifestIds(Map<String, dynamic>? data) {
    final rawIds = data?['pack_ids'];
    if (rawIds is! List) return null;
    final ids = <String>{};
    for (final value in rawIds) {
      if (value is! String || value.trim().isEmpty || !ids.add(value)) {
        return null;
      }
    }
    return ids;
  }

  static FirestorePackMembership _membershipFromData(
    Map<String, dynamic>? data, {
    required bool exists,
  }) {
    if (!exists || data == null) {
      return const FirestorePackMembership(revision: 0, packIds: {});
    }
    final revision = data['revision'];
    final ids = _manifestIds(data);
    if (revision is! int || revision < 0 || ids == null) {
      throw const FormatException('Invalid pack membership manifest.');
    }
    return FirestorePackMembership(revision: revision, packIds: ids);
  }

  static bool _sameMembership(
    FirestorePackMembership? left,
    FirestorePackMembership? right,
  ) =>
      left?.revision == right?.revision &&
      (left == null || right == null || _sameIds(left.packIds, right.packIds));

  static bool _sameMembershipReads(
    CloudReadResult<FirestorePackMembership> left,
    CloudReadResult<FirestorePackMembership> right,
  ) =>
      left.state == right.state &&
      (left.state != CloudReadState.present ||
          _sameMembership(left.value, right.value));

  static bool _sameIds(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}
