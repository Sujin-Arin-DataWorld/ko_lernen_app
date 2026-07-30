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
  });

  final Map<String, PackProgress> progress;
  final Map<String, int?> revisions;
}

typedef FirestorePackReader =
    Future<List<FirestorePackDocument>> Function(String uid);
typedef FirestoreSinglePackReader =
    Future<FirestorePackDocument?> Function(String uid, String packId);

enum FirestorePackCasStatus { committed, revisionConflict }

class FirestorePackCasResult {
  const FirestorePackCasResult.committed(this.revisions)
    : status = FirestorePackCasStatus.committed;

  const FirestorePackCasResult.revisionConflict()
    : status = FirestorePackCasStatus.revisionConflict,
      revisions = const {};

  final FirestorePackCasStatus status;
  final Map<String, int> revisions;
}

typedef FirestorePackCasWriter =
    Future<FirestorePackCasResult> Function({
      required String uid,
      required Iterable<PackProgress> progresses,
      required Map<String, int?> expectedRevisions,
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
    int maxBytes = defaultReadLimitBytes,
  }) async {
    if (uid.trim().isEmpty || maxBytes < 1) {
      return const CloudReadResult.invalid();
    }
    late List<FirestorePackDocument> documents;
    try {
      documents = await (reader ?? _readFirestorePacks)(uid);
    } catch (_) {
      return const CloudReadResult.unavailable();
    }
    if (documents.isEmpty) {
      return const CloudReadResult.absent();
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
      FirestorePackSnapshot(progress: progress, revisions: revisions),
    );
  }

  static Future<FirestorePackCasResult> saveManyReconciled({
    required String uid,
    required Iterable<PackProgress> progresses,
    required Map<String, int?> expectedRevisions,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    FirestorePackCasWriter? writer,
  }) {
    if (session.mode != CloudWriteMode.reconciling || session.uid != uid) {
      return Future.value(const FirestorePackCasResult.revisionConflict());
    }
    try {
      sessions.assertCurrent(session);
    } on StateError {
      return Future.value(const FirestorePackCasResult.revisionConflict());
    }
    return (writer ?? _writeFirestorePacks)(
      uid: uid,
      progresses: progresses,
      expectedRevisions: expectedRevisions,
      operationId: operationId,
      session: session,
      sessions: sessions,
    );
  }

  static Future<List<FirestorePackDocument>> _readFirestorePacks(
    String uid,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('packs')
        .get();
    return [
      for (final document in snapshot.docs)
        FirestorePackDocument(id: document.id, data: document.data()),
    ];
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
    required String uid,
    required Iterable<PackProgress> progresses,
    required Map<String, int?> expectedRevisions,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('packs');
    final values = progresses.toList();
    return firestore.runTransaction((transaction) async {
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final progress in values) {
        snapshots[progress.packId] = await transaction.get(
          collection.doc(progress.packId),
        );
      }
      final revisions = <String, int>{};
      for (final progress in values) {
        final snapshot = snapshots[progress.packId]!;
        final current = snapshot.data();
        if (current?['reconciliation_operation_id'] == operationId) {
          final revision = current?['sync_revision'];
          if (revision is! int ||
              current == null ||
              !_containsProgress(current, progress.toJson())) {
            return const FirestorePackCasResult.revisionConflict();
          }
          revisions[progress.packId] = revision;
          continue;
        }
        final currentRevision = snapshot.exists && current != null
            ? current['sync_revision']
            : null;
        if (currentRevision != expectedRevisions[progress.packId]) {
          return const FirestorePackCasResult.revisionConflict();
        }
      }
      sessions.assertCurrent(session);
      if (session.mode != CloudWriteMode.reconciling || session.uid != uid) {
        return const FirestorePackCasResult.revisionConflict();
      }
      for (final progress in values) {
        if (revisions.containsKey(progress.packId)) {
          continue;
        }
        final nextRevision = (expectedRevisions[progress.packId] ?? 0) + 1;
        transaction.set(collection.doc(progress.packId), {
          ...progress.toJson(),
          'sync_revision': nextRevision,
          'reconciliation_operation_id': operationId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        revisions[progress.packId] = nextRevision;
      }
      return FirestorePackCasResult.committed(revisions);
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
    CollectionReference<Map<String, dynamic>>? ref;
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
        ref = db.collection('users').doc(uid).collection('packs');
        payload = Map<String, dynamic>.from(p.toJson())
          ..['updatedAt'] = FieldValue.serverTimestamp()
          ..['sync_revision'] = FieldValue.increment(1)
          ..['reconciliation_operation_id'] = FieldValue.delete();
      },
      write: () async {
        final collection = ref;
        final data = payload;
        if (collection != null && data != null) {
          await collection.doc(p.packId).set(data, SetOptions(merge: true));
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
    WriteBatch? batch;
    try {
      return await CloudWriteFence(sessions).run(
        uid: uid,
        prepare: () async {
          final db = _db;
          if (db == null) {
            return;
          }
          final ref = db.collection('users').doc(uid).collection('packs');
          final pendingBatch = db.batch();
          for (final p in progresses) {
            final payload = Map<String, dynamic>.from(p.toJson());
            payload['updatedAt'] = FieldValue.serverTimestamp();
            payload['sync_revision'] = FieldValue.increment(1);
            payload['reconciliation_operation_id'] = FieldValue.delete();
            pendingBatch.set(
              ref.doc(p.packId),
              payload,
              SetOptions(merge: true),
            );
          }
          batch = pendingBatch;
        },
        action: () async {
          await batch?.commit();
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
}
