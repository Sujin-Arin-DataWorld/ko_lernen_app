import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show Timestamp, GeoPoint, DocumentReference;
import 'package:flutter/foundation.dart';

import '../../models/learner_level.dart';
import 'account_reconciliation.dart';
import 'account_reconciliation_field_policy.dart';

enum AccountSwitchResolutionSide { device, cloud }

/// Absence of a receipt is never, by itself, proof that no write was attempted.
enum AccountSwitchCommitEvidence {
  notObserved,
  sameOperationObserved,
  unavailable,
}

typedef AccountSwitchCommitEvidenceReader =
    Future<AccountSwitchCommitEvidence> Function({required String operationId});

enum AccountSwitchResolutionPreviewStatus {
  ready,
  resumeRequired,
  blocked,
  stale,
  unavailable,
}

enum AccountSwitchResolutionOutcome { completed, blocked, stale, unavailable }

/// Presentation data plus an opaque capability issued by the account owner.
/// The binding is never display text, a serialization format, or authority
/// that a caller can manufacture by copying the four visible fields.
@immutable
class AccountSwitchResolutionPreview {
  const AccountSwitchResolutionPreview({
    required this.devicePlacementLevel,
    required this.cloudPlacementLevel,
    required this.deviceCompletedUnitCount,
    required this.cloudCompletedUnitCount,
    required this.canChooseDevice,
    required this.canChooseCloud,
    required this.binding,
  });

  final String devicePlacementLevel;
  final String cloudPlacementLevel;
  final int deviceCompletedUnitCount;
  final int cloudCompletedUnitCount;
  final bool canChooseDevice;
  final bool canChooseCloud;
  final Object binding;
}

@immutable
class AccountSwitchResolutionPreviewResult {
  const AccountSwitchResolutionPreviewResult(this.status, {this.preview});

  final AccountSwitchResolutionPreviewStatus status;
  final AccountSwitchResolutionPreview? preview;
}

/// Read-only inputs. Production readers must not migrate or write local state.
@immutable
class AccountSwitchResolutionInputs {
  const AccountSwitchResolutionInputs({
    required this.device,
    required this.cloud,
    required this.catalogFingerprint,
    required this.remoteRevision,
  });

  final AccountReconciliationSnapshot device;
  final AccountReconciliationSnapshot cloud;
  final String catalogFingerprint;
  final int? remoteRevision;
}

typedef AccountSwitchResolutionInputsReader =
    Future<AccountSwitchResolutionInputs> Function();

typedef AccountSwitchResolutionCandidateBuilder =
    AccountReconciliationSnapshot? Function({
      required AccountSwitchResolutionInputs inputs,
      required AccountSwitchResolutionSide side,
    });

/// Durable consent carries fingerprints, never a copy of private learning text.
/// The containing journal supplies the exact UID, session and operation owner.
@immutable
class AccountSwitchResolutionConsent {
  AccountSwitchResolutionConsent({
    required this.side,
    required this.selectedPlacementLevel,
    required this.catalogFingerprint,
    required this.deviceFingerprint,
    required this.cloudFingerprint,
    required this.candidateFingerprint,
    required Map<String, String> deviceComponents,
    required Map<String, String> cloudComponents,
    required Map<String, String> candidateComponents,
    Map<String, String> cloudFences = const {},
  }) : deviceComponents = Map.unmodifiable(deviceComponents),
       cloudComponents = Map.unmodifiable(cloudComponents),
       candidateComponents = Map.unmodifiable(candidateComponents),
       cloudFences = Map.unmodifiable(cloudFences);

  final AccountSwitchResolutionSide side;
  final String selectedPlacementLevel;
  final String catalogFingerprint;
  final String deviceFingerprint;
  final String cloudFingerprint;
  final String candidateFingerprint;
  final Map<String, String> deviceComponents;
  final Map<String, String> cloudComponents;
  final Map<String, String> candidateComponents;
  final Map<String, String> cloudFences;

  Map<String, Object> toJson() {
    validate();
    return {
      'version': 1,
      'side': side.name,
      'selectedPlacementLevel': selectedPlacementLevel,
      'catalogFingerprint': catalogFingerprint,
      'deviceFingerprint': deviceFingerprint,
      'cloudFingerprint': cloudFingerprint,
      'candidateFingerprint': candidateFingerprint,
      'deviceComponents': deviceComponents,
      'cloudComponents': cloudComponents,
      'candidateComponents': candidateComponents,
      'cloudFences': cloudFences,
    };
  }

  factory AccountSwitchResolutionConsent.fromJson(Object? raw) {
    if (raw is! Map || raw['version'] != 1) {
      throw const FormatException('Invalid switch resolution consent.');
    }
    String text(String key) {
      final value = raw[key];
      if (value is! String) {
        throw const FormatException('Invalid consent field.');
      }
      return value;
    }

    Map<String, String> hashes(String key) {
      final value = raw[key];
      if (value is! Map || value.length > 2048) {
        throw const FormatException('Invalid consent component map.');
      }
      return value.map((key, value) {
        if (key is! String || value is! String) {
          throw const FormatException('Invalid consent component.');
        }
        return MapEntry(key, value);
      });
    }

    final side = AccountSwitchResolutionSide.values
        .where((v) => v.name == raw['side'])
        .firstOrNull;
    if (side == null) {
      throw const FormatException('Invalid consent side.');
    }
    final value = AccountSwitchResolutionConsent(
      side: side,
      selectedPlacementLevel: text('selectedPlacementLevel'),
      catalogFingerprint: text('catalogFingerprint'),
      deviceFingerprint: text('deviceFingerprint'),
      cloudFingerprint: text('cloudFingerprint'),
      candidateFingerprint: text('candidateFingerprint'),
      deviceComponents: hashes('deviceComponents'),
      cloudComponents: hashes('cloudComponents'),
      candidateComponents: hashes('candidateComponents'),
      cloudFences: hashes('cloudFences'),
    );
    value.validate();
    return value;
  }

  void validate() {
    if (LearnerLevel.fromCode(selectedPlacementLevel)?.code !=
            selectedPlacementLevel ||
        ![
          catalogFingerprint,
          deviceFingerprint,
          cloudFingerprint,
          candidateFingerprint,
        ].every(_validHash)) {
      throw const FormatException(
        'Invalid resolution fingerprint or placement.',
      );
    }
    for (final map in [
      deviceComponents,
      cloudComponents,
      candidateComponents,
      cloudFences,
    ]) {
      if (map.length > 2048 ||
          map.entries.any(
            (e) =>
                !RegExp(r'^[a-zA-Z0-9._-]{1,96}$').hasMatch(e.key) ||
                !_validHash(e.value),
          )) {
        throw const FormatException(
          'Invalid resolution component fingerprint.',
        );
      }
    }
    if (deviceComponents.isEmpty ||
        cloudComponents.isEmpty ||
        candidateComponents.isEmpty) {
      throw const FormatException('Missing resolution component fingerprints.');
    }
    if (AccountSwitchResolutionFingerprint.hash(deviceComponents) !=
            deviceFingerprint ||
        AccountSwitchResolutionFingerprint.hash(cloudComponents) !=
            cloudFingerprint ||
        AccountSwitchResolutionFingerprint.hash(candidateComponents) !=
            candidateFingerprint) {
      throw const FormatException(
        'Resolution component binding is inconsistent.',
      );
    }
  }

  static bool _validHash(String value) =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

  bool acceptsComponents(
    AccountReconciliationSnapshot snapshot, {
    required bool device,
  }) {
    final current = AccountSwitchResolutionFingerprint.components(snapshot);
    final original = device ? deviceComponents : cloudComponents;
    final keys = {
      ...original.keys,
      ...candidateComponents.keys,
      ...current.keys,
    };
    return keys.every(
      (key) =>
          current[key] == original[key] ||
          current[key] == candidateComponents[key],
    );
  }

  bool acceptsLocalFields(Map<String, Object?> fields) {
    final current = AccountSwitchResolutionFingerprint.components(
      AccountReconciliationSnapshot(
        fields: fields,
        srsCards: {},
        customPacks: {},
        packProgress: {},
      ),
    );
    final keys = {
      ...deviceComponents.keys,
      ...candidateComponents.keys,
      ...current.keys,
    }.where((key) => key.startsWith('field.'));
    return keys.every(
      (key) =>
          current[key] == deviceComponents[key] ||
          current[key] == candidateComponents[key],
    );
  }
}

/// Hashes are durable bindings only; none are diagnostic or presentation data.
abstract final class AccountSwitchResolutionFingerprint {
  static Object? _canonical(Object? value) {
    if (value is Timestamp) {
      return value.microsecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is Iterable) {
      return value.map(_canonical).toList();
    }
    return value;
  }

  static String hash(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();
  static Map<String, String> components(
    AccountReconciliationSnapshot snapshot,
  ) {
    final result = <String, String>{};
    void visit(Object? value, String path) {
      if (value is Map && value.isNotEmpty) {
        for (final entry in value.entries) {
          visit(entry.value, '$path/${entry.key}');
        }
      } else if (value is List && value.every((item) => item is String)) {
        // These backup arrays are set-like inventories; native restore adds
        // entries one at a time. Ordered grammar history is a JSON string.
        result['field.${hash('$path/type')}'] = hash('string-set');
        for (final item in value) {
          result['field.${hash('$path/item/$item')}'] = hash(true);
        }
      } else {
        result['field.${hash(path)}'] = hash(value);
      }
    }

    final ordinary = Map<String, Object?>.from(snapshot.fields);
    final hasStudyHistory = ordinary.containsKey('study_log_json');
    final studyHistory = ordinary.remove('study_log_json');
    visit(ordinary, 'fields');
    if (hasStudyHistory) {
      // The strict native writer commits one whole date list at a time. Each
      // date must match its original or exact candidate set; arbitrary JSON
      // and ordered grammar histories keep their opaque, atomic binding.
      final dates =
          jsonDecode(
                AccountReconciliationFieldPolicy.mergeStudyLog(
                  null,
                  studyHistory,
                ),
              )
              as Map<String, dynamic>;
      for (final entry in dates.entries) {
        result['field.${hash('fields/study_log_json/${entry.key}')}'] = hash(
          entry.value,
        );
      }
    }
    result.addAll({
      'srs': hash(snapshot.srsCards),
      'custom': hash(snapshot.customPacks),
      'packs': hash({
        for (final e in snapshot.packProgress.entries) e.key: e.value.toJson(),
      }),
      'courseMastery': hash(snapshot.courseMastery?.toJson()),
      'world': hash(snapshot.ilduWorldState?.toJson()),
    });
    return result;
  }

  static String snapshot(AccountReconciliationSnapshot value) =>
      hash(components(value));
  static Map<String, String> fences(
    AccountReconciliationSnapshot value,
    int? revision,
  ) => {
    'root': hash(revision),
    'packs': hash({
      'revisions': value.packRevisions,
      'membership': value.packMembershipRevision,
      'ids': value.packMembershipIds == null
          ? null
          : (value.packMembershipIds!.toList()..sort()),
      'legacy': value.legacyPackDocuments,
    }),
  };
  static String exact(AccountSwitchResolutionInputs inputs) => hash({
    'device': components(inputs.device),
    'cloud': components(inputs.cloud),
    // A sheet's confirmation remains sensitive to the original wire strings,
    // even when durable partial-apply checks use validated semantic dates.
    'deviceFields': inputs.device.fields,
    'cloudFields': inputs.cloud.fields,
    'catalog': inputs.catalogFingerprint,
    'fences': fences(inputs.cloud, inputs.remoteRevision),
    'localGenerations': [
      inputs.device.localSrsGeneration,
      inputs.device.localCustomPackGeneration,
      inputs.device.localPackProgressGeneration,
      inputs.device.localCourseMasteryGeneration,
      inputs.device.localIlDuWorldGeneration,
    ],
  });
}
