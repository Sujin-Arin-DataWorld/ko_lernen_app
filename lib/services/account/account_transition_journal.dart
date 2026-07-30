import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'cloud_write_session.dart';

enum ReconciliationCheckpoint {
  remoteRead,
  merged,
  remoteWritten,
  localWritten,
  completed,
}

enum AccountReplacementPhase {
  targetVerified,
  prepared,
  attached,
  reconciling,
  reconciled,
  cleanupPending,
}

/// Versioned, non-secret state that can safely resume an account transition.
@immutable
class AccountTransitionJournal {
  const AccountTransitionJournal({
    required this.version,
    required this.session,
    this.reconciliationOperationId,
    this.reconciliationCheckpoint,
    this.remoteRevision,
    this.reconciliationLocalCustomPackBaseIds,
    this.replacementProvider,
    this.replacementTargetUid,
    this.replacementRequestKey,
    this.replacementPhase,
    this.replacementOperationId,
    this.replacementOperationVersion,
  });

  static const currentVersion = 1;
  static const storageKey = 'kl_account_transition_journal_v1';
  static const maxLocalCustomPackBaseIds = 512;
  static const maxLocalCustomPackBaseIdBytes = 256;
  static const maxLocalCustomPackBaseIdsBytes = 64 * 1024;

  final int version;
  final CloudWriteSession session;
  final String? reconciliationOperationId;
  final ReconciliationCheckpoint? reconciliationCheckpoint;
  final int? remoteRevision;
  final Set<String>? reconciliationLocalCustomPackBaseIds;
  final String? replacementProvider;
  final String? replacementTargetUid;
  final String? replacementRequestKey;
  final AccountReplacementPhase? replacementPhase;
  final String? replacementOperationId;
  final int? replacementOperationVersion;

  factory AccountTransitionJournal.fromSession(
    CloudWriteSession session, {
    String? reconciliationOperationId,
    ReconciliationCheckpoint? reconciliationCheckpoint,
    int? remoteRevision,
    Set<String>? reconciliationLocalCustomPackBaseIds,
    String? replacementProvider,
    String? replacementTargetUid,
    String? replacementRequestKey,
    AccountReplacementPhase? replacementPhase,
    String? replacementOperationId,
    int? replacementOperationVersion,
  }) {
    return AccountTransitionJournal(
      version: currentVersion,
      session: session,
      reconciliationOperationId: reconciliationOperationId,
      reconciliationCheckpoint: reconciliationCheckpoint,
      remoteRevision: remoteRevision,
      reconciliationLocalCustomPackBaseIds:
          reconciliationLocalCustomPackBaseIds == null
          ? null
          : _parseLocalCustomPackBaseIds(
              reconciliationLocalCustomPackBaseIds.toList(),
            ),
      replacementProvider: replacementProvider,
      replacementTargetUid: replacementTargetUid,
      replacementRequestKey: replacementRequestKey,
      replacementPhase: replacementPhase,
      replacementOperationId: replacementOperationId,
      replacementOperationVersion: replacementOperationVersion,
    );
  }

  factory AccountTransitionJournal.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final uid = json['uid'];
    final epoch = json['epoch'];
    final mode = json['mode'];
    final operationId = json['reconciliationOperationId'];
    final checkpoint = json['reconciliationCheckpoint'];
    final remoteRevision = json['remoteRevision'];
    final localCustomPackBaseIds = _parseLocalCustomPackBaseIds(
      json['reconciliationLocalCustomPackBaseIds'],
    );
    final replacementProvider = json['replacementProvider'];
    final replacementTargetUid = json['replacementTargetUid'];
    final replacementRequestKey = json['replacementRequestKey'];
    final rawReplacementPhase = json['replacementPhase'];
    final replacementOperationId = json['replacementOperationId'];
    final replacementOperationVersion = json['replacementOperationVersion'];
    if (version is! int || version != currentVersion) {
      throw FormatException('Unsupported account transition journal version.');
    }
    if (uid is! String || uid.trim().isEmpty) {
      throw FormatException('Account transition journal has no UID.');
    }
    if (epoch is! int || epoch < 1) {
      throw FormatException('Account transition journal has an invalid epoch.');
    }
    if (mode is! String) {
      throw FormatException('Account transition journal has no mode.');
    }

    final parsedMode = CloudWriteMode.values.where(
      (value) => value.name == mode,
    );
    if (parsedMode.isEmpty) {
      throw FormatException('Account transition journal has an invalid mode.');
    }
    if (operationId != null &&
        (operationId is! String || !_validOperationId(operationId))) {
      throw FormatException(
        'Account transition journal has an invalid operation ID.',
      );
    }
    final parsedCheckpoint = checkpoint == null
        ? null
        : ReconciliationCheckpoint.values
              .where((value) => value.name == checkpoint)
              .firstOrNull;
    if (checkpoint != null && parsedCheckpoint == null) {
      throw FormatException(
        'Account transition journal has an invalid checkpoint.',
      );
    }
    if (remoteRevision != null &&
        (remoteRevision is! int || remoteRevision < 0)) {
      throw FormatException(
        'Account transition journal has an invalid remote revision.',
      );
    }
    final parsedReplacementPhase = rawReplacementPhase == null
        ? null
        : AccountReplacementPhase.values
              .where((value) => value.name == rawReplacementPhase)
              .firstOrNull;
    final hasReplacementMetadata =
        replacementProvider != null ||
        replacementTargetUid != null ||
        replacementRequestKey != null ||
        rawReplacementPhase != null ||
        replacementOperationId != null ||
        replacementOperationVersion != null;
    if (hasReplacementMetadata &&
        (replacementProvider is! String ||
            !const {'google', 'apple'}.contains(replacementProvider) ||
            replacementTargetUid is! String ||
            !_validUid(replacementTargetUid) ||
            replacementRequestKey is! String ||
            !_validOperationId(replacementRequestKey) ||
            parsedReplacementPhase == null ||
            (replacementOperationId != null &&
                (replacementOperationId is! String ||
                    !_validOperationId(replacementOperationId))) ||
            (replacementOperationVersion != null &&
                (replacementOperationVersion is! int ||
                    replacementOperationVersion < 0)) ||
            ((replacementOperationId == null) !=
                (replacementOperationVersion == null)))) {
      throw FormatException(
        'Account transition journal has invalid replacement metadata.',
      );
    }

    return AccountTransitionJournal(
      version: version,
      session: CloudWriteSession(
        uid: uid,
        epoch: epoch,
        mode: parsedMode.first,
      ),
      reconciliationOperationId: operationId as String?,
      reconciliationCheckpoint: parsedCheckpoint,
      remoteRevision: remoteRevision as int?,
      reconciliationLocalCustomPackBaseIds: localCustomPackBaseIds,
      replacementProvider: replacementProvider as String?,
      replacementTargetUid: replacementTargetUid as String?,
      replacementRequestKey: replacementRequestKey as String?,
      replacementPhase: parsedReplacementPhase,
      replacementOperationId: replacementOperationId as String?,
      replacementOperationVersion: replacementOperationVersion as int?,
    );
  }

  AccountTransitionJournal copyWith({
    String? reconciliationOperationId,
    ReconciliationCheckpoint? reconciliationCheckpoint,
    int? remoteRevision,
    Set<String>? reconciliationLocalCustomPackBaseIds,
    CloudWriteSession? session,
    AccountReplacementPhase? replacementPhase,
    String? replacementOperationId,
    int? replacementOperationVersion,
  }) {
    final selectedLocalCustomPackBaseIds =
        reconciliationLocalCustomPackBaseIds ??
        this.reconciliationLocalCustomPackBaseIds;
    return AccountTransitionJournal(
      version: version,
      session: session ?? this.session,
      reconciliationOperationId:
          reconciliationOperationId ?? this.reconciliationOperationId,
      reconciliationCheckpoint:
          reconciliationCheckpoint ?? this.reconciliationCheckpoint,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      reconciliationLocalCustomPackBaseIds:
          selectedLocalCustomPackBaseIds == null
          ? null
          : _parseLocalCustomPackBaseIds(
              selectedLocalCustomPackBaseIds.toList(),
            ),
      replacementProvider: replacementProvider,
      replacementTargetUid: replacementTargetUid,
      replacementRequestKey: replacementRequestKey,
      replacementPhase: replacementPhase ?? this.replacementPhase,
      replacementOperationId:
          replacementOperationId ?? this.replacementOperationId,
      replacementOperationVersion:
          replacementOperationVersion ?? this.replacementOperationVersion,
    );
  }

  /// Deliberately emits only durable coordination metadata, never credentials.
  Map<String, Object> toJson() {
    final json = <String, Object>{
      'version': version,
      'uid': session.uid,
      'epoch': session.epoch,
      'mode': session.mode.name,
    };
    final operationId = reconciliationOperationId;
    final checkpoint = reconciliationCheckpoint;
    final revision = remoteRevision;
    final localCustomPackBaseIds = reconciliationLocalCustomPackBaseIds;
    final replacementPhaseValue = replacementPhase;
    if (operationId != null) {
      json['reconciliationOperationId'] = operationId;
    }
    if (checkpoint != null) {
      json['reconciliationCheckpoint'] = checkpoint.name;
    }
    if (revision != null) {
      json['remoteRevision'] = revision;
    }
    if (localCustomPackBaseIds != null) {
      final validated = _parseLocalCustomPackBaseIds(
        localCustomPackBaseIds.toList(),
      )!;
      json['reconciliationLocalCustomPackBaseIds'] = validated.toList()..sort();
    }
    if (replacementProvider != null) {
      json['replacementProvider'] = replacementProvider!;
      json['replacementTargetUid'] = replacementTargetUid!;
      json['replacementRequestKey'] = replacementRequestKey!;
      json['replacementPhase'] = replacementPhaseValue!.name;
      if (replacementOperationId != null) {
        json['replacementOperationId'] = replacementOperationId!;
        json['replacementOperationVersion'] = replacementOperationVersion!;
      }
    }
    return json;
  }

  static Set<String>? _parseLocalCustomPackBaseIds(Object? value) {
    if (value == null) return null;
    if (value is! List || value.length > maxLocalCustomPackBaseIds) {
      throw FormatException(
        'Account transition journal has invalid custom-pack base IDs.',
      );
    }
    var totalBytes = 0;
    final ids = <String>{};
    for (final item in value) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException(
          'Account transition journal has invalid custom-pack base IDs.',
        );
      }
      final bytes = utf8.encode(item).length;
      totalBytes += bytes;
      if (bytes > maxLocalCustomPackBaseIdBytes ||
          totalBytes > maxLocalCustomPackBaseIdsBytes ||
          !ids.add(item)) {
        throw FormatException(
          'Account transition journal has invalid custom-pack base IDs.',
        );
      }
    }
    final sorted = ids.toList()..sort();
    if (utf8.encode(jsonEncode(sorted)).length >
        maxLocalCustomPackBaseIdsBytes) {
      throw FormatException(
        'Account transition journal has invalid custom-pack base IDs.',
      );
    }
    return Set.unmodifiable(ids);
  }

  static bool _validOperationId(String value) =>
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value);

  static bool _validUid(String value) =>
      value.trim().isNotEmpty &&
      value.length <= 128 &&
      !RegExp(r'[\u0000-\u001f\u007f]').hasMatch(value);
}
