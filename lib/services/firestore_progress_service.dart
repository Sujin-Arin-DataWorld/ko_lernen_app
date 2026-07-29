import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pack_progress.dart';
import 'auth_service.dart';

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

  /// 단일 팩 진행도 fetch. null = 미존재 / 오류.
  static Future<PackProgress?> loadPack(String packId) async {
    final ref = _packsCollection();
    if (ref == null) return null;
    try {
      final snap = await ref.doc(packId).get();
      if (!snap.exists) return null;
      return PackProgress.fromJson(packId, snap.data() ?? {});
    } catch (_) {
      return null;
    }
  }

  /// 단일 팩 진행도 저장 (merge). 실패는 silently ignored.
  static Future<void> savePack(PackProgress p) async {
    final ref = _packsCollection();
    if (ref == null) return;
    try {
      final payload = Map<String, dynamic>.from(p.toJson());
      payload['updatedAt'] = FieldValue.serverTimestamp();
      await ref.doc(p.packId).set(payload, SetOptions(merge: true));
    } catch (_) {
      // best-effort
    }
  }

  /// 배치 저장 — 마이그레이션 / 다중 팩 동시 update 용.
  static Future<void> saveMany(Iterable<PackProgress> progresses) async {
    final ref = _packsCollection();
    final db = _db;
    if (ref == null || db == null) return;
    try {
      final batch = db.batch();
      for (final p in progresses) {
        final payload = Map<String, dynamic>.from(p.toJson());
        payload['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(ref.doc(p.packId), payload, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {
      // best-effort
    }
  }
}
