import 'package:flutter/foundation.dart';

import 'cloud_write_session.dart';

enum ReconciliationCheckpoint {
  remoteRead,
  merged,
  remoteWritten,
  localWritten,
  completed,
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
  });

  static const currentVersion = 1;

  final int version;
  final CloudWriteSession session;
  final String? reconciliationOperationId;
  final ReconciliationCheckpoint? reconciliationCheckpoint;
  final int? remoteRevision;

  factory AccountTransitionJournal.fromSession(
    CloudWriteSession session, {
    String? reconciliationOperationId,
    ReconciliationCheckpoint? reconciliationCheckpoint,
    int? remoteRevision,
  }) {
    return AccountTransitionJournal(
      version: currentVersion,
      session: session,
      reconciliationOperationId: reconciliationOperationId,
      reconciliationCheckpoint: reconciliationCheckpoint,
      remoteRevision: remoteRevision,
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
    );
  }

  AccountTransitionJournal copyWith({
    ReconciliationCheckpoint? reconciliationCheckpoint,
    int? remoteRevision,
  }) {
    return AccountTransitionJournal(
      version: version,
      session: session,
      reconciliationOperationId: reconciliationOperationId,
      reconciliationCheckpoint:
          reconciliationCheckpoint ?? this.reconciliationCheckpoint,
      remoteRevision: remoteRevision ?? this.remoteRevision,
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
    if (operationId != null) {
      json['reconciliationOperationId'] = operationId;
    }
    if (checkpoint != null) {
      json['reconciliationCheckpoint'] = checkpoint.name;
    }
    if (revision != null) {
      json['remoteRevision'] = revision;
    }
    return json;
  }

  static bool _validOperationId(String value) =>
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value);
}
