import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'auth_service.dart';
import 'pack_completion_record.dart';
import 'storage_service.dart';

final class PackCompletionIdentity {
  const PackCompletionIdentity({
    required this.configured,
    required this.initialized,
    this.uid,
    this.anonymous = false,
  });
  final bool configured, initialized, anonymous;
  final String? uid;
}

/// Local generation and account binding. The marker is never exported.
abstract final class PackCompletionOwner {
  static bool authenticationInitialized = false;
  @visibleForTesting
  static PackCompletionIdentity Function()? identityForTesting;

  static PackCompletionIdentity _identity() =>
      identityForTesting?.call() ??
      PackCompletionIdentity(
        configured: Firebase.apps.isNotEmpty,
        initialized: authenticationInitialized,
        uid: AuthService.current?.uid,
        anonymous: AuthService.isAnonymous,
      );

  static const blockingKeys = <String>{
    'kl_account_switch_journal_v1',
    'kl_account_switch_reconciliation_v1',
    'kl_account_deletion_journal_v1',
    'kl_account_deletion_feedback_activation_v1',
    'kl_cloud_backup_deletion_journal_v1',
    'kl_migration_journal_v1',
    'kl_migration_backup_v1',
  };

  static Future<String> confirm({String? acceptedOwner}) async {
    final prefs = await SharedPreferences.getInstance();
    await Storage.reloadForPackCompletion(prefs);
    if (blockingKeys.any(prefs.containsKey)) {
      throw const PackCompletionPendingException();
    }
    final identity = _identity();
    if (identity.configured && !identity.initialized && identity.uid == null) {
      throw const PackCompletionPendingException();
    }
    final raw = prefs.get(PackCompletionRecord.ownerKey);
    Map<String, dynamic> marker;
    if (raw == null) {
      if (acceptedOwner != null ||
          prefs.containsKey(PackCompletionRecord.key)) {
        throw const PackCompletionPendingException();
      }
      marker = {
        'version': 1,
        'generation': const Uuid().v4(),
        'uid': identity.uid,
        'mode': identity.uid != null
            ? 'bound'
            : identity.configured
            ? 'guest'
            : 'local',
        'guestOrigin': identity.uid == null,
      };
      await _write(prefs, marker);
    } else {
      if (raw is! String) {
        throw const FormatException('Invalid completion owner.');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded.length != 5 ||
          !const {
            'version',
            'generation',
            'uid',
            'mode',
            'guestOrigin',
          }.containsAll(decoded.keys) ||
          decoded['version'] != 1 ||
          decoded['generation'] is! String ||
          !RegExp(
            r'^[a-f0-9-]{36}$',
          ).hasMatch(decoded['generation'] as String) ||
          (decoded['uid'] != null &&
              (decoded['uid'] is! String ||
                  (decoded['uid'] as String).isEmpty)) ||
          !const ['bound', 'guest', 'local'].contains(decoded['mode']) ||
          decoded['guestOrigin'] is! bool ||
          (decoded['uid'] == null && decoded['guestOrigin'] != true)) {
        throw const FormatException('Invalid completion owner.');
      }
      marker = decoded;
      if (marker['uid'] != null) {
        if (marker['mode'] != 'bound' || marker['uid'] != identity.uid) {
          throw const PackCompletionPendingException();
        }
      } else if (identity.uid != null) {
        // Only the first anonymous bootstrap can associate a guest generation.
        if (!identity.initialized ||
            !identity.anonymous ||
            marker['mode'] == 'bound' ||
            marker['guestOrigin'] != true) {
          throw const PackCompletionPendingException();
        }
        marker = {...marker, 'mode': 'bound', 'uid': identity.uid};
        await _write(prefs, marker);
      } else if (marker['mode'] == 'bound' ||
          (marker['mode'] == 'local' && identity.configured) ||
          (marker['mode'] == 'guest' && !identity.configured)) {
        throw const PackCompletionPendingException();
      }
    }
    final accepted = acceptedOwner ?? PackCompletionStorage.record?.owner;
    if (accepted != null) {
      final binding = jsonDecode(accepted);
      if (binding is! Map ||
          binding.length != 2 ||
          !const {'generation', 'uid'}.containsAll(binding.keys) ||
          binding['generation'] != marker['generation'] ||
          (binding['uid'] != null && binding['uid'] != marker['uid']) ||
          (binding['uid'] == null &&
              marker['uid'] != null &&
              marker['guestOrigin'] != true)) {
        throw const PackCompletionPendingException();
      }
      return accepted;
    }
    return jsonEncode({
      'generation': marker['generation'],
      'uid': marker['uid'],
    });
  }

  static Future<void> _write(
    SharedPreferences prefs,
    Map<String, dynamic> marker,
  ) async {
    final raw = jsonEncode(marker);
    try {
      await prefs.setString(PackCompletionRecord.ownerKey, raw);
    } on Object {
      // Native equality below, never the transport reply, confirms association.
    }
    await Storage.reloadForPackCompletion(prefs);
    if (prefs.get(PackCompletionRecord.ownerKey) != raw) {
      throw const PackCompletionPendingException();
    }
  }
}
