import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'account/cloud_read_result.dart';
import 'account/cloud_write_session.dart';

const int _defaultAccountDocumentLimit = 1024 * 1024;

class CloudSyncDocument {
  const CloudSyncDocument.missing() : exists = false, data = null;

  const CloudSyncDocument.present(this.data)
    : exists = true,
      assert(data != null);

  final bool exists;
  final Map<String, dynamic>? data;
}

typedef CloudSyncDocumentReader =
    Future<CloudSyncDocument> Function(String uid);

enum CloudSyncCasStatus { committed, revisionConflict }

class CloudSyncCasResult {
  const CloudSyncCasResult.committed(this.revision)
    : status = CloudSyncCasStatus.committed;

  const CloudSyncCasResult.revisionConflict()
    : status = CloudSyncCasStatus.revisionConflict,
      revision = null;

  final CloudSyncCasStatus status;
  final int? revision;
}

typedef CloudSyncCasWriter =
    Future<CloudSyncCasResult> Function({
      required String uid,
      required Map<String, dynamic> data,
      required int? expectedRevision,
      required String operationId,
      required CloudWriteSession session,
      required CloudWriteSessionController sessions,
    });

typedef CloudSyncReconciliationValidator =
    Future<bool> Function({
      required String uid,
      required Map<String, dynamic> data,
      required int expectedRevision,
      required String operationId,
      required CloudWriteSession session,
      required CloudWriteSessionController sessions,
    });

/// Typed account-document boundary used by reconciliation.
///
/// The legacy [CloudSync] facade remains responsible for ready-session
/// backup/restore. This adapter supplies lossless remote states and CAS writes
/// without mutable process-wide test hooks.
class CloudSyncService {
  const CloudSyncService._();

  static Future<CloudReadResult<Map<String, dynamic>>> readAccountDocument({
    required String uid,
    CloudSyncDocumentReader? reader,
    int maxBytes = _defaultAccountDocumentLimit,
  }) async {
    if (uid.trim().isEmpty || maxBytes < 1) {
      return const CloudReadResult.invalid();
    }

    late CloudSyncDocument document;
    try {
      document = await (reader ?? _readFirestoreDocument)(uid);
    } catch (_) {
      return const CloudReadResult.unavailable();
    }
    if (!document.exists) {
      return const CloudReadResult.absent();
    }
    final data = document.data;
    if (data == null) {
      return const CloudReadResult.invalid();
    }

    final revision = data['sync_revision'];
    if (revision != null && (revision is! int || revision < 0)) {
      return const CloudReadResult.invalid();
    }
    try {
      if (utf8
              .encode(jsonEncode(data, toEncodable: _firestoreJsonValue))
              .length >
          maxBytes) {
        return const CloudReadResult.tooLarge();
      }
    } catch (_) {
      return const CloudReadResult.invalid();
    }
    return CloudReadResult.present(
      Map<String, dynamic>.from(data),
      revision: revision as int?,
    );
  }

  static Future<CloudSyncCasResult> writeReconciledAccountDocument({
    required String uid,
    required Map<String, dynamic> data,
    required int? expectedRevision,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    CloudSyncCasWriter? writer,
  }) {
    if (session.mode != CloudWriteMode.reconciling) {
      return Future.value(const CloudSyncCasResult.revisionConflict());
    }
    try {
      sessions.assertCurrent(session);
    } on StateError {
      return Future.value(const CloudSyncCasResult.revisionConflict());
    }
    return (writer ?? _writeFirestoreDocument)(
      uid: uid,
      data: data,
      expectedRevision: expectedRevision,
      operationId: operationId,
      session: session,
      sessions: sessions,
    );
  }

  static Future<bool> validateReconciledAccountDocument({
    required String uid,
    required Map<String, dynamic> data,
    required int expectedRevision,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    CloudSyncDocumentReader? reader,
  }) async {
    if (uid.trim().isEmpty ||
        session.mode != CloudWriteMode.reconciling ||
        session.uid != uid) {
      return false;
    }
    try {
      sessions.assertCurrent(session);
    } on StateError {
      return false;
    }
    final document = await (reader ?? _readFirestoreDocument)(uid);
    try {
      sessions.assertCurrent(session);
    } on StateError {
      return false;
    }
    final currentData = document.data;
    return document.exists &&
        currentData != null &&
        currentData['sync_revision'] == expectedRevision &&
        currentData['reconciliation_operation_id'] == operationId &&
        currentData['reconciliation_payload_hash'] == _payloadHash(data);
  }

  static Future<CloudSyncDocument> _readFirestoreDocument(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!snapshot.exists) {
      return const CloudSyncDocument.missing();
    }
    final data = snapshot.data();
    return data == null
        ? const CloudSyncDocument.present({})
        : CloudSyncDocument.present(data);
  }

  static Future<CloudSyncCasResult> _writeFirestoreDocument({
    required String uid,
    required Map<String, dynamic> data,
    required int? expectedRevision,
    required String operationId,
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
  }) {
    final firestore = FirebaseFirestore.instance;
    final reference = firestore.collection('users').doc(uid);
    final payloadHash = _payloadHash(data);
    return firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final currentData = current.data();
      if (currentData?['reconciliation_operation_id'] == operationId &&
          currentData?['reconciliation_payload_hash'] == payloadHash) {
        final revision = currentData?['sync_revision'];
        return revision is int
            ? CloudSyncCasResult.committed(revision)
            : const CloudSyncCasResult.revisionConflict();
      }
      final currentRevision = current.exists && currentData != null
          ? currentData['sync_revision']
          : null;
      if (currentRevision != expectedRevision) {
        return const CloudSyncCasResult.revisionConflict();
      }
      sessions.assertCurrent(session);
      if (session.mode != CloudWriteMode.reconciling || session.uid != uid) {
        return const CloudSyncCasResult.revisionConflict();
      }
      final nextRevision = (expectedRevision ?? 0) + 1;
      transaction.set(reference, {
        ...data,
        'sync_revision': nextRevision,
        'reconciliation_operation_id': operationId,
        'reconciliation_payload_hash': payloadHash,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return CloudSyncCasResult.committed(nextRevision);
    });
  }

  static Object? _firestoreJsonValue(Object? value) {
    if (value is Timestamp) {
      return value.microsecondsSinceEpoch;
    }
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) {
      return value.path;
    }
    throw UnsupportedError('Unsupported remote value.');
  }

  static String _payloadHash(Map<String, dynamic> data) => sha256
      .convert(
        utf8.encode(
          jsonEncode(_canonicalize(data), toEncodable: _firestoreJsonValue),
        ),
      )
      .toString();

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()),
        );
      return {
        for (final entry in entries)
          entry.key.toString(): _canonicalize(entry.value),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}
