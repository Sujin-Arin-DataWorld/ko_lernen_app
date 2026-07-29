import 'package:flutter/foundation.dart';

import 'cloud_write_session.dart';

/// Versioned, non-secret state that can safely resume an account transition.
@immutable
class AccountTransitionJournal {
  const AccountTransitionJournal({
    required this.version,
    required this.session,
  });

  static const currentVersion = 1;

  final int version;
  final CloudWriteSession session;

  factory AccountTransitionJournal.fromSession(CloudWriteSession session) {
    return AccountTransitionJournal(version: currentVersion, session: session);
  }

  factory AccountTransitionJournal.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final uid = json['uid'];
    final epoch = json['epoch'];
    final mode = json['mode'];
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

    return AccountTransitionJournal(
      version: version,
      session: CloudWriteSession(
        uid: uid,
        epoch: epoch,
        mode: parsedMode.first,
      ),
    );
  }

  /// Deliberately emits only durable coordination metadata, never credentials.
  Map<String, Object> toJson() {
    return {
      'version': version,
      'uid': session.uid,
      'epoch': session.epoch,
      'mode': session.mode.name,
    };
  }
}
