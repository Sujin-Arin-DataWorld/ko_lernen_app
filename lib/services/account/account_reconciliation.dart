import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../models/course_mastery.dart';
import '../../models/pack_progress.dart';
import '../cloud_sync.dart';
import '../cloud_sync_service.dart';
import '../course_progress_service.dart';
import '../custom_pack_service.dart';
import '../firestore_progress_service.dart';
import '../pack_progress_service.dart';
import '../storage_service.dart';
import 'account_failure_diagnostics.dart';
import 'account_transition_journal.dart';
import 'cloud_read_result.dart';
import 'cloud_write_session.dart';
import 'reconciliation_errors.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'reconciliation_errors.dart';

@immutable
class AccountReconciliationSnapshot {
  AccountReconciliationSnapshot({
    required Map<String, Object?> fields,
    required this.srsCards,
    required this.customPacks,
    required this.packProgress,
    this.courseMastery,
    this.packRevisions = const {},
    this.packMembershipRevision,
    this.localSrsGeneration,
    this.localCustomPackGeneration,
    this.localPackProgressGeneration,
    this.localCourseMasteryGeneration,
  }) : fields = _withoutReservedCourseFields(fields);

  static final empty = AccountReconciliationSnapshot(
    fields: {},
    srsCards: {},
    customPacks: {},
    packProgress: {},
    courseMastery: null,
    packRevisions: {},
    packMembershipRevision: null,
    localSrsGeneration: null,
    localCustomPackGeneration: null,
    localPackProgressGeneration: null,
    localCourseMasteryGeneration: null,
  );

  final Map<String, Object?> fields;
  final Map<String, Map<String, Object?>> srsCards;
  final Map<String, Map<String, Object?>> customPacks;
  final Map<String, PackProgress> packProgress;
  final CourseMasterySnapshot? courseMastery;
  final Map<String, int?> packRevisions;
  final int? packMembershipRevision;
  final String? localSrsGeneration;
  final String? localCustomPackGeneration;
  final String? localPackProgressGeneration;
  final String? localCourseMasteryGeneration;

  static CloudReadResult<AccountReconciliationSnapshot> decodeCloudDocument(
    Map<String, dynamic> document, {
    Map<String, PackProgress> packProgress = const {},
    Map<String, int?> packRevisions = const {},
    int? packMembershipRevision,
  }) {
    final courseResult = _decodeCourseMastery(document['course_mastery_json']);
    if (!courseResult.isPresent) {
      return const CloudReadResult.invalid();
    }
    final srsResult = _decodeSrs(document['srs_json']);
    if (!srsResult.isPresent) {
      return switch (srsResult.state) {
        CloudReadState.absent => CloudReadResult.present(
          AccountReconciliationSnapshot(
            fields: _ordinaryFields(document),
            srsCards: const {},
            customPacks: const {},
            packProgress: packProgress,
            courseMastery: courseResult.value,
            packRevisions: packRevisions,
            packMembershipRevision: packMembershipRevision,
          ),
        ),
        CloudReadState.tooLarge => const CloudReadResult.tooLarge(),
        _ => const CloudReadResult.invalid(),
      };
    }
    final customResult = CustomPackService.decodePortableRemote(
      document['custom_packs_json'],
    );
    if (customResult.state == CloudReadState.invalid) {
      return const CloudReadResult.invalid();
    }
    if (customResult.state == CloudReadState.tooLarge) {
      return const CloudReadResult.tooLarge();
    }
    return CloudReadResult.present(
      AccountReconciliationSnapshot(
        fields: _ordinaryFields(document),
        srsCards: srsResult.value!,
        customPacks: customResult.value ?? const {},
        packProgress: packProgress,
        courseMastery: courseResult.value,
        packRevisions: packRevisions,
        packMembershipRevision: packMembershipRevision,
      ),
    );
  }

  Map<String, dynamic> toCloudDocument() => {
    ..._withoutReservedCourseFields(fields),
    'srs_json': jsonEncode(srsCards),
    'custom_packs_json': jsonEncode(customPacks),
    if (courseMastery != null)
      'course_mastery_json': jsonEncode(courseMastery!.toJson()),
  };

  static CloudReadResult<CourseMasterySnapshot?> _decodeCourseMastery(
    Object? value,
  ) {
    if (value == null || value == '') {
      return const CloudReadResult.present(null);
    }
    if (value is! String) {
      return const CloudReadResult.invalid();
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const CloudReadResult.invalid();
      return CloudReadResult.present(
        CourseMasterySnapshot.decodeAndMigrate(
          decoded.map((key, item) => MapEntry(key.toString(), item)),
        ),
      );
    } catch (_) {
      return const CloudReadResult.invalid();
    }
  }

  static CloudReadResult<Map<String, Map<String, Object?>>> _decodeSrs(
    Object? value,
  ) {
    if (value == null || value == '') {
      return const CloudReadResult.present({});
    }
    if (value is! String) {
      return const CloudReadResult.invalid();
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const CloudReadResult.invalid();
      final cards = <String, Map<String, Object?>>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String ||
            (entry.key as String).trim().isEmpty ||
            entry.value is! Map) {
          return const CloudReadResult.invalid();
        }
        final card = (entry.value as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final ease = card['e'];
        final interval = card['i'];
        final next = card['n'];
        final reviews = card['r'];
        final nextDate = next is String ? DateTime.tryParse(next) : null;
        if (ease is! num ||
            !ease.toDouble().isFinite ||
            ease < 1.3 ||
            ease > 3.5 ||
            interval is! int ||
            interval < 0 ||
            reviews is! int ||
            reviews < 0 ||
            nextDate == null) {
          return const CloudReadResult.invalid();
        }
        cards[entry.key as String] = Map<String, Object?>.from(card);
      }
      return CloudReadResult.present(cards);
    } catch (_) {
      return const CloudReadResult.invalid();
    }
  }

  static Map<String, Object?> _ordinaryFields(Map<String, dynamic> document) {
    final result = Map<String, Object?>.from(document)
      ..remove('srs_json')
      ..remove('custom_packs_json')
      ..remove('course_mastery_json')
      ..remove('sync_revision')
      ..remove('reconciliation_operation_id')
      ..remove('reconciliation_payload_hash')
      ..remove('updated_at');
    return result;
  }

  bool get isEmpty =>
      fields.isEmpty &&
      srsCards.isEmpty &&
      customPacks.isEmpty &&
      packProgress.isEmpty &&
      courseMastery == null;

  @override
  bool operator ==(Object other) =>
      other is AccountReconciliationSnapshot &&
      _deepEquals(fields, other.fields) &&
      _deepEquals(srsCards, other.srsCards) &&
      _deepEquals(customPacks, other.customPacks) &&
      _packMapsEqual(packProgress, other.packProgress) &&
      _deepEquals(courseMastery?.toJson(), other.courseMastery?.toJson());

  @override
  int get hashCode => Object.hash(
    _stableHash(fields),
    _stableHash(srsCards),
    _stableHash(customPacks),
    _stableHash({
      for (final entry in packProgress.entries) entry.key: entry.value.toJson(),
    }),
    _stableHash(courseMastery?.toJson()),
  );
}

enum AccountReconciliationConflictKind {
  srsCardHistory,
  customPackId,
  packProgress,
  courseMasteryPlacement,
  courseMasteryVersion,
  courseMasteryEvidence,
  courseMasteryCheckpoint,
  courseMasteryProgression,
  documentField,
}

@immutable
class AccountReconciliationConflict {
  const AccountReconciliationConflict({required this.kind, required this.id});

  final AccountReconciliationConflictKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is AccountReconciliationConflict &&
      other.kind == kind &&
      other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

class AccountReconciliationMergeResult {
  const AccountReconciliationMergeResult({
    required this.merged,
    required this.conflicts,
  });

  final AccountReconciliationSnapshot? merged;
  final List<AccountReconciliationConflict> conflicts;
}

class AccountReconciliationMerger {
  const AccountReconciliationMerger._();

  static AccountReconciliationMergeResult merge({
    required AccountReconciliationSnapshot local,
    required AccountReconciliationSnapshot remote,
    required Map<String, PackCatalogEntry> catalog,
    CourseMasteryReconciliationMerger? courseMasteryMerger,
  }) {
    final conflicts = <AccountReconciliationConflict>[];
    final fields = _mergeFields(
      _withoutReservedCourseFields(local.fields),
      _withoutReservedCourseFields(remote.fields),
      conflicts,
    );
    final srs = _mergeIdentityMaps(
      local.srsCards,
      remote.srsCards,
      kind: AccountReconciliationConflictKind.srsCardHistory,
      conflicts: conflicts,
    );
    final customPacks = _mergeIdentityMaps(
      local.customPacks,
      remote.customPacks,
      kind: AccountReconciliationConflictKind.customPackId,
      conflicts: conflicts,
    );
    final packResult = PackProgressService.mergeForReconciliation(
      local: local.packProgress,
      remote: remote.packProgress,
      catalog: catalog,
    );
    for (final id in packResult.invalidPackIds) {
      conflicts.add(
        AccountReconciliationConflict(
          kind: AccountReconciliationConflictKind.packProgress,
          id: id,
        ),
      );
    }
    CourseMasterySnapshot? courseMastery;
    if (local.courseMastery != null || remote.courseMastery != null) {
      if (courseMasteryMerger == null) {
        conflicts.add(
          const AccountReconciliationConflict(
            kind: AccountReconciliationConflictKind.courseMasteryVersion,
            id: 'merger',
          ),
        );
      } else {
        final courseResult = courseMasteryMerger(
          local: local.courseMastery,
          remote: remote.courseMastery,
        );
        courseMastery = courseResult.snapshot;
        for (final conflict in courseResult.conflicts) {
          conflicts.add(
            AccountReconciliationConflict(
              kind: _accountCourseConflictKind(conflict.kind),
              id: conflict.id,
            ),
          );
        }
      }
    }
    conflicts.sort((left, right) {
      final kind = left.kind.index.compareTo(right.kind.index);
      return kind != 0 ? kind : left.id.compareTo(right.id);
    });
    if (conflicts.isNotEmpty) {
      return AccountReconciliationMergeResult(
        merged: null,
        conflicts: conflicts,
      );
    }
    return AccountReconciliationMergeResult(
      merged: AccountReconciliationSnapshot(
        fields: fields,
        srsCards: srs,
        customPacks: customPacks,
        packProgress: packResult.merged!,
        courseMastery: courseMastery,
        packRevisions: remote.packRevisions,
        packMembershipRevision: remote.packMembershipRevision,
        localSrsGeneration: local.localSrsGeneration,
        localCustomPackGeneration: local.localCustomPackGeneration,
        localPackProgressGeneration: local.localPackProgressGeneration,
        localCourseMasteryGeneration: local.localCourseMasteryGeneration,
      ),
      conflicts: const [],
    );
  }

  static AccountReconciliationConflictKind _accountCourseConflictKind(
    CourseMasteryMergeConflictKind kind,
  ) => switch (kind) {
    CourseMasteryMergeConflictKind.placement =>
      AccountReconciliationConflictKind.courseMasteryPlacement,
    CourseMasteryMergeConflictKind.version =>
      AccountReconciliationConflictKind.courseMasteryVersion,
    CourseMasteryMergeConflictKind.evidence =>
      AccountReconciliationConflictKind.courseMasteryEvidence,
    CourseMasteryMergeConflictKind.checkpoint =>
      AccountReconciliationConflictKind.courseMasteryCheckpoint,
    CourseMasteryMergeConflictKind.progression =>
      AccountReconciliationConflictKind.courseMasteryProgression,
  };

  static Map<String, Map<String, Object?>> _mergeIdentityMaps(
    Map<String, Map<String, Object?>> local,
    Map<String, Map<String, Object?>> remote, {
    required AccountReconciliationConflictKind kind,
    required List<AccountReconciliationConflict> conflicts,
  }) {
    final ids = {...local.keys, ...remote.keys}.toList()..sort();
    final merged = <String, Map<String, Object?>>{};
    for (final id in ids) {
      final left = local[id];
      final right = remote[id];
      if (left != null && right != null && !_deepEquals(left, right)) {
        conflicts.add(AccountReconciliationConflict(kind: kind, id: id));
        continue;
      }
      merged[id] = Map<String, Object?>.from(left ?? right!);
    }
    return merged;
  }

  static Map<String, Object?> _mergeFields(
    Map<String, Object?> local,
    Map<String, Object?> remote,
    List<AccountReconciliationConflict> conflicts,
  ) {
    final keys = {...local.keys, ...remote.keys}.toList()..sort();
    final result = <String, Object?>{};
    for (final key in keys) {
      final hasLocal = local.containsKey(key);
      final hasRemote = remote.containsKey(key);
      if (!hasLocal) {
        result[key] = _canonicalFieldValue(remote[key]);
      } else if (!hasRemote) {
        result[key] = _canonicalFieldValue(local[key]);
      } else {
        result[key] = _mergeFieldValue(key, local[key], remote[key], conflicts);
      }
    }
    return result;
  }

  static Object? _mergeFieldValue(
    String path,
    Object? local,
    Object? remote,
    List<AccountReconciliationConflict> conflicts,
  ) {
    final canonicalLocal = _canonicalFieldValue(local);
    final canonicalRemote = _canonicalFieldValue(remote);
    if (_deepEquals(canonicalLocal, canonicalRemote)) return canonicalLocal;
    if (canonicalLocal is num && canonicalRemote is num) {
      return canonicalLocal >= canonicalRemote
          ? canonicalLocal
          : canonicalRemote;
    }
    if (canonicalLocal is Map && canonicalRemote is Map) {
      return _mergeFields(
        canonicalLocal.map((key, value) => MapEntry(key.toString(), value)),
        canonicalRemote.map((key, value) => MapEntry(key.toString(), value)),
        conflicts,
      );
    }
    if (canonicalLocal is List && canonicalRemote is List) {
      final values = <Object?>[...canonicalLocal];
      for (final value in canonicalRemote) {
        if (!values.any((existing) => _deepEquals(existing, value))) {
          values.add(value);
        }
      }
      values.sort(
        (left, right) => _stableText(left).compareTo(_stableText(right)),
      );
      return values;
    }
    if (canonicalLocal is String && canonicalRemote is String) {
      final leftInstant = _canonicalInstant(canonicalLocal);
      final rightInstant = _canonicalInstant(canonicalRemote);
      if (leftInstant != null && rightInstant != null) {
        return DateTime.parse(leftInstant).isAfter(DateTime.parse(rightInstant))
            ? leftInstant
            : rightInstant;
      }
    }
    conflicts.add(
      AccountReconciliationConflict(
        kind: AccountReconciliationConflictKind.documentField,
        id: path,
      ),
    );
    return canonicalLocal;
  }
}

abstract interface class AccountTransitionJournalStore {
  Future<AccountTransitionJournal?> read();
  Future<void> write(AccountTransitionJournal journal);
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  });
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  });
}

class SharedPreferencesAccountTransitionJournalStore
    implements AccountTransitionJournalStore {
  SharedPreferencesAccountTransitionJournalStore(this.preferences);

  static const key = AccountTransitionJournal.storageKey;
  static Future<void> _mutationTail = Future<void>.value();

  final SharedPreferences preferences;

  @override
  Future<AccountTransitionJournal?> read() => _serialized(_readUnlocked);

  @override
  Future<void> write(AccountTransitionJournal journal) =>
      _serialized(() => _writeUnlocked(journal));

  @override
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) => _serialized(() async {
    final current = await _readUnlocked();
    if (!_sameJournal(current, expected) || !isCurrent()) return false;
    await _writeUnlocked(next);
    return true;
  });

  Future<bool> deleteIfCurrent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) => _serialized(() async {
    final current = await _readUnlocked();
    if (!_sameJournal(current, expected) || !isCurrent()) return false;
    final removed = await preferences.remove(key);
    if (!removed && preferences.containsKey(key)) {
      throw StateError('Account transition journal delete failed.');
    }
    return removed || !preferences.containsKey(key);
  });

  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) => _serialized(() async {
    final current = await _readUnlocked();
    if (current != null) return _sameJournal(current, expected);
    if (!isCurrent()) return false;
    await _writeUnlocked(expected);
    return true;
  });

  Future<AccountTransitionJournal?> _readUnlocked() async {
    await preferences.reload();
    final raw = preferences.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid account transition journal.');
    }
    return AccountTransitionJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> _writeUnlocked(AccountTransitionJournal journal) async {
    final written = await preferences.setString(
      key,
      jsonEncode(journal.toJson()),
    );
    if (!written) {
      throw StateError('Account transition journal write failed.');
    }
  }

  static Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static bool _sameJournal(
    AccountTransitionJournal? left,
    AccountTransitionJournal right,
  ) => left != null && jsonEncode(left.toJson()) == jsonEncode(right.toJson());
}

class LocalAccountReconciliationStore {
  const LocalAccountReconciliationStore._();

  static Future<AccountReconciliationSnapshot> load({
    CourseProgressService? courseProgress,
  }) async {
    final srsGeneration = _hashText(Storage.srsRawJson);
    final customPackGeneration =
        CustomPackService.localReconciliationGeneration;
    final customPacks = CustomPackService.readLocalForReconciliation();
    if (!customPacks.isPresent) {
      throw const FormatException('Invalid local custom-pack data.');
    }
    final packProgress = PackProgressService.getAll();
    final packProgressGeneration = _packProgressGeneration(packProgress);
    final hasLocalCourseInput =
        Storage.courseMasterySnapshotRawJson.trim().isNotEmpty ||
        Storage.legacyCourseMasteryRawJson.trim().isNotEmpty ||
        Storage.dedicatedCoursePlacementLevelCode != null ||
        Storage.courseUnitId != null;
    final courseCapture = hasLocalCourseInput
        ? await (courseProgress ?? CourseProgressService.shared)
              .captureForCloudReconciliation()
        : const CourseMasteryLocalCapture(
            snapshot: null,
            canonicalGeneration: '',
          );
    final payload = await CloudSync.buildBackupPayload(
      courseMasteryCapture: courseCapture,
    );
    final result = AccountReconciliationSnapshot.decodeCloudDocument(
      payload,
      packProgress: packProgress,
    );
    if (!result.isPresent || result.value == null) {
      throw const FormatException('Invalid local reconciliation data.');
    }
    final snapshot = result.value!;
    return AccountReconciliationSnapshot(
      fields: snapshot.fields,
      srsCards: snapshot.srsCards,
      customPacks: customPacks.value!,
      packProgress: snapshot.packProgress,
      courseMastery: snapshot.courseMastery,
      packRevisions: snapshot.packRevisions,
      packMembershipRevision: snapshot.packMembershipRevision,
      localSrsGeneration: srsGeneration,
      localCustomPackGeneration: customPackGeneration,
      localPackProgressGeneration: packProgressGeneration,
      localCourseMasteryGeneration: courseCapture.canonicalGeneration,
    );
  }

  static Future<void> write(
    AccountReconciliationSnapshot snapshot, {
    required CloudWriteSession session,
    required CloudWriteSessionController sessions,
    CourseProgressService? courseProgress,
  }) async {
    await CustomPackService.writeReconciledPortable(
      snapshot.customPacks,
      expectedGeneration: snapshot.localCustomPackGeneration,
      beforeWrite: () {
        _assertCurrent(session, sessions);
        _assertCompositeGeneration(snapshot);
      },
    );
    final ordinaryFields = snapshot.toCloudDocument()
      ..remove('srs_json')
      ..remove('custom_packs_json')
      ..remove('course_mastery_json');
    await CloudSync.applyReconciledRestorePayload(
      ordinaryFields,
      uid: session.uid,
      session: session,
      sessions: sessions,
    );
    _assertCurrent(session, sessions);
    _assertSrsGeneration(snapshot);
    await Storage.setSrsRawJsonStrict(jsonEncode(snapshot.srsCards));
    if (snapshot.courseMastery case final courseMastery?) {
      _assertCurrent(session, sessions);
      await (courseProgress ?? CourseProgressService.shared)
          .applyReconciledSnapshot(
            courseMastery,
            expectedGeneration: snapshot.localCourseMasteryGeneration,
            assertCurrentWrite: () => _assertCurrent(session, sessions),
          );
    }
    _assertCurrent(session, sessions);
    _assertPackProgressGeneration(snapshot);
    await Storage.setAllPackProgressJsonStrict({
      for (final entry in snapshot.packProgress.entries)
        entry.key: entry.value.toJson(),
    });
    _assertCurrent(session, sessions);
  }

  static void _assertCompositeGeneration(
    AccountReconciliationSnapshot snapshot,
  ) {
    _assertSrsGeneration(snapshot);
    if (snapshot.localCustomPackGeneration != null &&
        CustomPackService.localReconciliationGeneration !=
            snapshot.localCustomPackGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
    _assertPackProgressGeneration(snapshot);
    _assertCourseMasteryGeneration(snapshot);
  }

  static void _assertSrsGeneration(AccountReconciliationSnapshot snapshot) {
    if (snapshot.localSrsGeneration != null &&
        _hashText(Storage.srsRawJson) != snapshot.localSrsGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
  }

  static void _assertPackProgressGeneration(
    AccountReconciliationSnapshot snapshot,
  ) {
    if (snapshot.localPackProgressGeneration != null &&
        _packProgressGeneration(PackProgressService.getAll()) !=
            snapshot.localPackProgressGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
  }

  static void _assertCourseMasteryGeneration(
    AccountReconciliationSnapshot snapshot,
  ) {
    if (snapshot.localCourseMasteryGeneration != null &&
        Storage.courseMasterySnapshotRawJson !=
            snapshot.localCourseMasteryGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
  }

  static void _assertCurrent(
    CloudWriteSession session,
    CloudWriteSessionController sessions,
  ) {
    if (session.mode != CloudWriteMode.reconciling) {
      throw const LocalReconciliationSessionConflict();
    }
    try {
      sessions.assertCurrent(session);
    } on StateError {
      throw const LocalReconciliationSessionConflict();
    }
  }
}

Map<String, Object?> _withoutReservedCourseFields(
  Map<String, Object?> fields,
) => Map.unmodifiable(
  Map<String, Object?>.from(fields)..remove('course_mastery_json'),
);

class LocalReconciliationSessionConflict implements Exception {
  const LocalReconciliationSessionConflict();
}

enum ReconciliationWriteStatus { committed, revisionConflict }

class ReconciliationWriteResult {
  const ReconciliationWriteResult.committed({required this.revision})
    : status = ReconciliationWriteStatus.committed;

  const ReconciliationWriteResult.revisionConflict()
    : status = ReconciliationWriteStatus.revisionConflict,
      revision = null;

  final ReconciliationWriteStatus status;
  final int? revision;
}

typedef AccountRemoteReader =
    Future<CloudReadResult<AccountReconciliationSnapshot>> Function();
typedef AccountLocalReader = FutureOr<AccountReconciliationSnapshot> Function();
typedef AccountRemoteWriter =
    Future<ReconciliationWriteResult> Function(
      AccountReconciliationSnapshot snapshot, {
      required int? expectedRevision,
      required String operationId,
    });
typedef AccountLocalWriter =
    Future<void> Function(
      AccountReconciliationSnapshot snapshot, {
      required CloudWriteSession session,
      required CloudWriteSessionController sessions,
    });

enum AccountReconciliationStatus {
  completed,
  blocked,
  unavailable,
  invalid,
  tooLarge,
  stale,
}

class AccountReconciliationResult {
  const AccountReconciliationResult(
    this.status, {
    this.snapshot,
    this.conflicts = const [],
  });

  final AccountReconciliationStatus status;
  final AccountReconciliationSnapshot? snapshot;
  final List<AccountReconciliationConflict> conflicts;
}

/// Resumable reconciliation runner. Payloads never enter the durable journal;
/// only operation identity, checkpoint, session, and revision are persisted.
class AccountReconciliationCoordinator {
  const AccountReconciliationCoordinator({
    required this.sessions,
    required this.journalStore,
    required this.readRemote,
    required this.loadLocal,
    required this.writeRemote,
    required this.writeLocal,
    this.courseMasteryMerger,
    this.maxCasAttempts = 3,
  }) : assert(maxCasAttempts > 0);

  final CloudWriteSessionController sessions;
  final AccountTransitionJournalStore journalStore;
  final AccountRemoteReader readRemote;
  final AccountLocalReader loadLocal;
  final AccountRemoteWriter writeRemote;
  final AccountLocalWriter writeLocal;
  final CourseMasteryReconciliationMerger? courseMasteryMerger;
  final int maxCasAttempts;

  Future<AccountReconciliationResult> reconcile({
    required CloudWriteSession session,
    required String operationId,
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    if (!_isCurrent(session) || !_validOperationId(operationId)) {
      _diag(
        'guard.blocked',
        detail:
            'current=${_isCurrent(session)} '
            'validOpId=${_validOperationId(operationId)}',
      );
      return const AccountReconciliationResult(
        AccountReconciliationStatus.blocked,
      );
    }

    late AccountTransitionJournal journal;
    try {
      final existing = await journalStore.read();
      if (!_isCurrent(session)) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.stale,
        );
      }
      if (existing != null) {
        if (existing.session != session ||
            existing.reconciliationOperationId != operationId) {
          _diag(
            'journal.mismatch',
            detail:
                'sessionMatch=${existing.session == session} '
                'opIdMatch=${existing.reconciliationOperationId == operationId}',
          );
          return const AccountReconciliationResult(
            AccountReconciliationStatus.blocked,
          );
        }
        if (existing.reconciliationCheckpoint ==
            ReconciliationCheckpoint.completed) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.completed,
          );
        }
        journal = existing;
      } else {
        journal = AccountTransitionJournal.fromSession(
          session,
          reconciliationOperationId: operationId,
        );
        final restored = await journalStore.restoreIfAbsent(
          expected: journal,
          isCurrent: () => _isCurrent(session),
        );
        if (!restored || !_isCurrent(session)) {
          throw StateError('Reconciliation session is stale.');
        }
      }
    } catch (error) {
      _diag('journal.read.unavailable', error: error);
      return const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    }

    for (var attempt = 0; attempt < maxCasAttempts; attempt += 1) {
      if (!_isCurrent(session)) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.stale,
        );
      }
      late CloudReadResult<AccountReconciliationSnapshot> remoteResult;
      try {
        remoteResult = await readRemote();
      } catch (error) {
        _diag('readRemote.threw', error: error);
        return const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      }
      if (!_isCurrent(session)) {
        _diag('readRemote.stale');
        return const AccountReconciliationResult(
          AccountReconciliationStatus.stale,
        );
      }
      final failedRead = _failedReadResult(remoteResult.state);
      if (failedRead != null) {
        _diag('readRemote.state', detail: 'state=${remoteResult.state.name}');
        return failedRead;
      }

      final remote = remoteResult.value ?? AccountReconciliationSnapshot.empty;
      final remoteReadJournal = journal.copyWith(
        reconciliationCheckpoint: ReconciliationCheckpoint.remoteRead,
        remoteRevision: remoteResult.revision,
      );
      try {
        await _writeJournal(journal, remoteReadJournal, session);
        journal = remoteReadJournal;
      } catch (_) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      }

      late AccountReconciliationSnapshot local;
      try {
        local = await loadLocal();
      } on FormatException catch (error) {
        _diag('loadLocal.invalid', error: error);
        return const AccountReconciliationResult(
          AccountReconciliationStatus.invalid,
        );
      } catch (error) {
        _diag('loadLocal.unavailable', error: error);
        return const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      }
      if (!_isCurrent(session)) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.stale,
        );
      }
      final currentLocalCustomPackIds = local.customPacks.keys.toSet();
      var localCustomPackBaseIds = journal.reconciliationLocalCustomPackBaseIds;
      if (localCustomPackBaseIds == null) {
        localCustomPackBaseIds = currentLocalCustomPackIds;
        try {
          final localBaseJournal = journal.copyWith(
            reconciliationLocalCustomPackBaseIds: localCustomPackBaseIds,
          );
          await _writeJournal(journal, localBaseJournal, session);
          journal = localBaseJournal;
        } catch (_) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
      }
      final deletedLocalCustomPackIds = localCustomPackBaseIds.difference(
        currentLocalCustomPackIds,
      );
      if (deletedLocalCustomPackIds.isNotEmpty) {
        final conflicts =
            deletedLocalCustomPackIds
                .map(
                  (id) => AccountReconciliationConflict(
                    kind: AccountReconciliationConflictKind.customPackId,
                    id: id,
                  ),
                )
                .toList()
              ..sort((left, right) => left.id.compareTo(right.id));
        _diag(
          'localCustomPack.deleted.blocked',
          detail: 'count=${conflicts.length}',
        );
        return AccountReconciliationResult(
          AccountReconciliationStatus.blocked,
          conflicts: conflicts,
        );
      }
      if (!localCustomPackBaseIds.containsAll(currentLocalCustomPackIds)) {
        localCustomPackBaseIds = {
          ...localCustomPackBaseIds,
          ...currentLocalCustomPackIds,
        };
        try {
          final expandedBaseJournal = journal.copyWith(
            reconciliationLocalCustomPackBaseIds: localCustomPackBaseIds,
          );
          await _writeJournal(journal, expandedBaseJournal, session);
          journal = expandedBaseJournal;
        } catch (_) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
      }
      final merge = AccountReconciliationMerger.merge(
        local: local,
        remote: remote,
        catalog: catalog,
        courseMasteryMerger: courseMasteryMerger,
      );
      if (merge.merged == null) {
        _diag(
          'merge.blocked',
          detail: _summarizeConflicts(merge.conflicts),
        );
        return AccountReconciliationResult(
          AccountReconciliationStatus.blocked,
          conflicts: merge.conflicts,
        );
      }
      final merged = merge.merged!;
      final mergedJournal = journal.copyWith(
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        remoteRevision: remoteResult.revision,
      );
      try {
        await _writeJournal(journal, mergedJournal, session);
        journal = mergedJournal;
      } catch (_) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      }

      final needsLocalWrite = merged != local;
      if (merged != remote || needsLocalWrite) {
        if (!_isCurrent(session)) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.stale,
          );
        }
        late ReconciliationWriteResult writeResult;
        try {
          writeResult = await writeRemote(
            merged,
            expectedRevision: remoteResult.revision,
            operationId: operationId,
          );
        } catch (error) {
          _diag('writeRemote.threw', error: error);
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
        if (!_isCurrent(session)) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.stale,
          );
        }
        if (writeResult.status == ReconciliationWriteStatus.revisionConflict) {
          continue;
        }
        final remoteWrittenJournal = journal.copyWith(
          reconciliationCheckpoint: ReconciliationCheckpoint.remoteWritten,
          remoteRevision: writeResult.revision,
        );
        try {
          await _writeJournal(journal, remoteWrittenJournal, session);
          journal = remoteWrittenJournal;
        } catch (_) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
      }

      if (needsLocalWrite) {
        if (!_isCurrent(session)) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.stale,
          );
        }
        try {
          await writeLocal(merged, session: session, sessions: sessions);
        } on LocalCustomPackGenerationConflict {
          _diag('writeLocal.customPackConflict.retry');
          continue;
        } on LocalReconciliationGenerationConflict {
          _diag('writeLocal.generationConflict.retry');
          continue;
        } on LocalReconciliationSessionConflict catch (error) {
          _diag('writeLocal.sessionConflict.stale', error: error);
          return const AccountReconciliationResult(
            AccountReconciliationStatus.stale,
          );
        } catch (error) {
          _diag('writeLocal.threw', error: error);
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
        if (!_isCurrent(session)) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.stale,
          );
        }
        final localWrittenJournal = journal.copyWith(
          reconciliationCheckpoint: ReconciliationCheckpoint.localWritten,
        );
        try {
          await _writeJournal(journal, localWrittenJournal, session);
          journal = localWrittenJournal;
        } catch (_) {
          return const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );
        }
      }

      final completedJournal = journal.copyWith(
        reconciliationCheckpoint: ReconciliationCheckpoint.completed,
      );
      try {
        await _writeJournal(journal, completedJournal, session);
        journal = completedJournal;
      } catch (_) {
        return const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      }
      return AccountReconciliationResult(
        AccountReconciliationStatus.completed,
        snapshot: merged,
      );
    }
    _diag('cas.exhausted.blocked', detail: 'attempts=$maxCasAttempts');
    return const AccountReconciliationResult(
      AccountReconciliationStatus.blocked,
    );
  }

  /// 진단 전용 — 조정 러너의 각 조기 반환 지점을 `klAccount:` 로그로 남긴다.
  /// 반환값(상태)은 절대 바꾸지 않는다. 이게 있기 전까지는 실패한 하위 단계
  /// (원격 읽기/쓰기 거부, 로컬 파싱 실패, 병합 충돌)가 코디네이터에서 하나의
  /// 불투명한 `reconciliationPending` 으로 뭉개져 원인 판별이 불가능했다.
  void _diag(String step, {Object? error, String? detail}) =>
      AccountFailureDiagnostics.log(
        'link.reconcile.$step',
        error,
        detail: detail,
      );

  /// 충돌을 **종류(enum)와 개수**로만 요약한다 — 충돌 id 에는 사용자가 지은
  /// 커스텀 팩 이름 등이 섞일 수 있어 로그에 원문을 남기지 않는다.
  static String _summarizeConflicts(
    List<AccountReconciliationConflict> conflicts,
  ) {
    if (conflicts.isEmpty) return 'conflicts=none';
    final kinds = <String>{for (final c in conflicts) c.kind.name}.toList()
      ..sort();
    return 'conflicts=${conflicts.length}:${kinds.join('/')}';
  }

  bool _isCurrent(CloudWriteSession session) {
    if (session.mode != CloudWriteMode.reconciling) return false;
    try {
      sessions.assertCurrent(session);
      return true;
    } on StateError {
      return false;
    }
  }

  Future<void> _writeJournal(
    AccountTransitionJournal expected,
    AccountTransitionJournal next,
    CloudWriteSession session,
  ) async {
    if (!_isCurrent(session)) {
      throw StateError('Reconciliation session is stale.');
    }
    final written = await journalStore.writeIfCurrent(
      expected: expected,
      next: next,
      isCurrent: () => _isCurrent(session),
    );
    if (!written) {
      throw StateError('Reconciliation journal changed.');
    }
    if (!_isCurrent(session)) {
      throw StateError('Reconciliation session is stale.');
    }
  }

  static AccountReconciliationResult? _failedReadResult(CloudReadState state) {
    return switch (state) {
      CloudReadState.present || CloudReadState.absent => null,
      CloudReadState.unavailable => const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      ),
      CloudReadState.invalid => const AccountReconciliationResult(
        AccountReconciliationStatus.invalid,
      ),
      CloudReadState.tooLarge => const AccountReconciliationResult(
        AccountReconciliationStatus.tooLarge,
      ),
    };
  }

  static bool _validOperationId(String value) =>
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value);
}

/// Concrete composition of the root account document and pack subcollection.
///
/// The adapter is immutable and uses the services' regular per-call seams.
/// Task 10 can supply local persistence and the durable journal without
/// introducing mutable global hooks.
class FirebaseAccountReconciliationRemote {
  const FirebaseAccountReconciliationRemote({
    required this.rootReader,
    required this.packReader,
    required this.membershipReader,
    required this.rootWriter,
    required this.packWriter,
    required this.compositeReader,
  });

  factory FirebaseAccountReconciliationRemote.firestore({
    required FirebaseFirestore firestore,
    required String fenceUid,
  }) {
    return FirebaseAccountReconciliationRemote(
      rootReader: CloudSyncService.firestoreDocumentReader(firestore),
      packReader: FirestoreProgressService.firestorePackReader(firestore),
      membershipReader: FirestoreProgressService.firestoreMembershipReader(
        firestore,
      ),
      rootWriter: CloudSyncService.firestoreCasWriter(
        firestore: firestore,
        fenceUid: fenceUid,
      ),
      packWriter: FirestoreProgressService.firestoreCasWriter(
        firestore: firestore,
        fenceUid: fenceUid,
      ),
      compositeReader: CloudSyncService.firestoreCompositeReader(firestore),
    );
  }

  final CloudSyncDocumentReader rootReader;
  final FirestorePackReader packReader;
  final FirestorePackMembershipReader membershipReader;
  final CloudSyncCasWriter rootWriter;
  final FirestorePackCasWriter packWriter;
  final CloudSyncCompositeReader compositeReader;
}

class FirebaseAccountReconciliationAdapter {
  const FirebaseAccountReconciliationAdapter({
    required this.uid,
    String? fenceUid,
    required this.session,
    required this.sessions,
    this.remote,
  }) : fenceUid = fenceUid ?? uid;

  final String uid;
  final String fenceUid;
  final CloudWriteSession session;
  final CloudWriteSessionController sessions;
  final FirebaseAccountReconciliationRemote? remote;

  Future<CloudReadResult<AccountReconciliationSnapshot>> readRemote() async {
    final root = await CloudSyncService.readAccountDocument(
      uid: uid,
      reader: remote?.rootReader,
    );
    if (root.state == CloudReadState.unavailable) {
      return const CloudReadResult.unavailable();
    }
    if (root.state == CloudReadState.invalid) {
      return const CloudReadResult.invalid();
    }
    if (root.state == CloudReadState.tooLarge) {
      return const CloudReadResult.tooLarge();
    }

    final packs = await FirestoreProgressService.loadAllTyped(
      uid: uid,
      reader: remote?.packReader,
      membershipReader: remote?.membershipReader,
    );
    if (packs.state == CloudReadState.unavailable) {
      return const CloudReadResult.unavailable();
    }
    if (packs.state == CloudReadState.invalid) {
      return const CloudReadResult.invalid();
    }
    if (packs.state == CloudReadState.tooLarge) {
      return const CloudReadResult.tooLarge();
    }
    if (root.state == CloudReadState.absent &&
        packs.state == CloudReadState.absent) {
      return const CloudReadResult.absent();
    }

    final packSnapshot = packs.value;
    final decoded = root.state == CloudReadState.absent
        ? CloudReadResult.present(
            AccountReconciliationSnapshot(
              fields: const {},
              srsCards: const {},
              customPacks: const {},
              packProgress: packSnapshot?.progress ?? const {},
              packRevisions: packSnapshot?.revisions ?? const {},
              packMembershipRevision: packSnapshot?.membershipRevision,
            ),
          )
        : AccountReconciliationSnapshot.decodeCloudDocument(
            root.value!,
            packProgress: packSnapshot?.progress ?? const {},
            packRevisions: packSnapshot?.revisions ?? const {},
            packMembershipRevision: packSnapshot?.membershipRevision,
          );
    if (!decoded.isPresent) return decoded;
    return CloudReadResult.present(decoded.value!, revision: root.revision);
  }

  Future<ReconciliationWriteResult> writeRemote(
    AccountReconciliationSnapshot snapshot, {
    required int? expectedRevision,
    required String operationId,
    CloudSyncCasWriter? rootWriter,
    FirestorePackCasWriter? packWriter,
    CloudSyncCompositeValidator? compositeValidator,
  }) async {
    final rootData = snapshot.toCloudDocument();
    final rootResult = await CloudSyncService.writeReconciledAccountDocument(
      uid: uid,
      fenceUid: fenceUid,
      data: rootData,
      expectedRevision: expectedRevision,
      operationId: operationId,
      session: session,
      sessions: sessions,
      writer: rootWriter ?? remote?.rootWriter,
    );
    if (rootResult.status == CloudSyncCasStatus.revisionConflict) {
      return const ReconciliationWriteResult.revisionConflict();
    }
    final packResult = await FirestoreProgressService.saveManyReconciled(
      uid: uid,
      fenceUid: fenceUid,
      progresses: snapshot.packProgress.values,
      expectedRevisions: snapshot.packRevisions,
      expectedMembershipRevision: snapshot.packMembershipRevision,
      operationId: operationId,
      session: session,
      sessions: sessions,
      writer: packWriter ?? remote?.packWriter,
    );
    if (packResult.status == FirestorePackCasStatus.revisionConflict) {
      return const ReconciliationWriteResult.revisionConflict();
    }
    final committedRootRevision = rootResult.revision;
    if (committedRootRevision == null) {
      return const ReconciliationWriteResult.revisionConflict();
    }
    final committedMembershipRevision = packResult.membershipRevision;
    if (committedMembershipRevision == null) {
      return const ReconciliationWriteResult.revisionConflict();
    }
    final compositeIsCurrent = compositeValidator == null
        ? await CloudSyncService.validateReconciledAccountComposite(
            uid: uid,
            fenceUid: fenceUid,
            data: rootData,
            expectedRevision: committedRootRevision,
            expectedMembershipRevision: committedMembershipRevision,
            expectedMembershipPackIds: packResult.membershipPackIds,
            operationId: operationId,
            session: session,
            sessions: sessions,
            reader: remote?.compositeReader,
          )
        : await compositeValidator(
            uid: uid,
            data: rootData,
            expectedRevision: committedRootRevision,
            expectedMembershipRevision: committedMembershipRevision,
            expectedMembershipPackIds: packResult.membershipPackIds,
            operationId: operationId,
            session: session,
            sessions: sessions,
          );
    if (!compositeIsCurrent) {
      return const ReconciliationWriteResult.revisionConflict();
    }
    return ReconciliationWriteResult.committed(revision: committedRootRevision);
  }

  AccountReconciliationCoordinator coordinator({
    required AccountTransitionJournalStore journalStore,
    CourseMasteryReconciliationMerger? courseMasteryMerger,
    AccountLocalReader? loadLocal,
    AccountLocalWriter? writeLocal,
  }) {
    return AccountReconciliationCoordinator(
      sessions: sessions,
      journalStore: journalStore,
      readRemote: readRemote,
      loadLocal: loadLocal ?? LocalAccountReconciliationStore.load,
      writeRemote: writeRemote,
      writeLocal: writeLocal ?? LocalAccountReconciliationStore.write,
      courseMasteryMerger: courseMasteryMerger,
    );
  }
}

bool _packMapsEqual(
  Map<String, PackProgress> left,
  Map<String, PackProgress> right,
) {
  if (left.length != right.length || !left.keys.every(right.containsKey)) {
    return false;
  }
  return left.entries.every(
    (entry) => _deepEquals(entry.value.toJson(), right[entry.key]!.toJson()),
  );
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right) || left == right) return true;
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (!_deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return false;
}

int _stableHash(Object? value) => _stableText(value).hashCode;

String _hashText(String value) => sha256.convert(utf8.encode(value)).toString();

String _packProgressGeneration(Map<String, PackProgress> progress) => _hashText(
  _stableText({
    for (final entry in progress.entries) entry.key: entry.value.toJson(),
  }),
);

String _stableText(Object? value) {
  final canonical = _canonicalFieldValue(value);
  if (canonical == null) return '0:null';
  if (canonical is bool) return canonical ? '1:true' : '1:false';
  if (canonical is num) return '2:${canonical.toString()}';
  if (canonical is String) return '3:${jsonEncode(canonical)}';
  if (canonical is List) {
    return '4:[${canonical.map(_stableText).join(',')}]';
  }
  if (canonical is Map) {
    final entries = canonical.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return '5:{${entries.map((entry) => '${jsonEncode(entry.key.toString())}:${_stableText(entry.value)}').join(',')}}';
  }
  return '9:${canonical.runtimeType}:${canonical.toString()}';
}

/// int64 경계를 **double 리터럴**로 표현한 값.
///
/// dart2js 는 JS number(IEEE-754 double)로 정확히 표현할 수 없는 정수 리터럴을
/// 거부한다. int 최댓값 2^63-1 이 정확히 그 경우라 `flutter build web` 이 깨졌다:
///   Error: The integer literal 9223372036854775807 can't be represented
///          exactly in JavaScript.
///
/// 2^63 은 2의 거듭제곱이라 double 로 정확히 표현된다. 그래서 상한을
/// "2^63 미만"으로 바꾼다 — double 도메인에서는 두 조건이 동치다. 2^63 미만의
/// 가장 큰 double 은 2^63-1024 이고, 2^63-1 은 애초에 double 로 표현되지 않아
/// 기존 리터럴도 비교 시점에 2^63 으로 반올림되고 있었다.
const double _int64LowerBoundInclusive = -9223372036854775808.0; // -2^63
const double _int64UpperBoundExclusive = 9223372036854775808.0; //  2^63

Object? _canonicalFieldValue(Object? value) {
  if (value is double) {
    if (value.isFinite &&
        value >= _int64LowerBoundInclusive &&
        value < _int64UpperBoundExclusive &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    return value;
  }
  if (value is String) {
    final instant = _canonicalInstant(value);
    return instant ?? value;
  }
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalFieldValue(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalFieldValue).toList();
  }
  return value;
}

String? _canonicalInstant(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T.+(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc().toIso8601String();
}
