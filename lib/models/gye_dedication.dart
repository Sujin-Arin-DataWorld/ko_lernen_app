import 'package:flutter/foundation.dart';

import 'gye.dart';

enum GyeDedicationState { active, withdrawn }

/// A member's read-only exhibit in a shared Gye courtyard.
///
/// This is deliberately not an ownership record. The server only persists a
/// cosmetic projection, while the member's private collection and room
/// placements remain unchanged.
@immutable
class GyeDedication {
  static const int currentSchemaVersion = 1;
  static const int maxSlots = 10;

  const GyeDedication({
    required this.uid,
    required this.membershipId,
    required this.joinedAtEpoch,
    required this.state,
    required this.decorationSlug,
    required this.slotIndex,
    required this.revision,
    required this.lastOperationId,
  });

  final String uid;
  final String membershipId;

  /// The immutable member-document timestamp copied by the callable into the
  /// public exhibit. Legacy active documents intentionally have no epoch and
  /// may render for compatibility, but can never become the current user's
  /// compare-and-set record.
  final GyeMembershipEpoch? joinedAtEpoch;
  final GyeDedicationState state;
  final String? decorationSlug;
  final int? slotIndex;
  final int revision;
  final String lastOperationId;

  bool get isActive => state == GyeDedicationState.active;
  bool get isWithdrawn => state == GyeDedicationState.withdrawn;

  /// Parses a complete public record without treating a tombstone as a visual
  /// exhibit. Legacy active documents had no [state]; current active records
  /// may declare `state: 'active'`, while a withdrawn document retains only
  /// its monotonic compare-and-set revision.
  static GyeDedication? tryParse(
    String documentId,
    Map<dynamic, dynamic> source,
  ) {
    final schemaVersion = source['schemaVersion'];
    final uid = source['uid'];
    final membershipId = source['membershipId'];
    final decorationSlug = source['decorationSlug'];
    final slotIndex = source['slotIndex'];
    final revision = source['revision'];
    final lastOperationId = source['lastOperationId'];
    if (schemaVersion != currentSchemaVersion ||
        uid is! String ||
        membershipId is! String ||
        revision is! int ||
        lastOperationId is! String ||
        uid != documentId ||
        !_isSafeIdentifier(uid) ||
        !_isSafeMembershipId(membershipId) ||
        !_isSafeIdentifier(lastOperationId) ||
        revision < 0) {
      return null;
    }

    final legacyActive = !source.containsKey('state');
    final declaredActive = source['state'] == 'active';
    if (legacyActive || declaredActive) {
      if (decorationSlug is! String ||
          slotIndex is! int ||
          !kGyeDedicationSlugs.contains(decorationSlug) ||
          slotIndex < 0 ||
          slotIndex >= maxSlots ||
          revision < 1) {
        return null;
      }
      final joinedAtEpoch = legacyActive
          ? null
          : GyeMembershipEpoch.tryFromParts(
              source['joinedAtSeconds'],
              source['joinedAtNanos'],
            );
      if (!legacyActive && joinedAtEpoch == null) {
        return null;
      }
      return GyeDedication(
        uid: uid,
        membershipId: membershipId,
        joinedAtEpoch: joinedAtEpoch,
        state: GyeDedicationState.active,
        decorationSlug: decorationSlug,
        slotIndex: slotIndex,
        revision: revision,
        lastOperationId: lastOperationId,
      );
    }

    final joinedAtEpoch = GyeMembershipEpoch.tryFromParts(
      source['joinedAtSeconds'],
      source['joinedAtNanos'],
    );
    if (source['state'] != 'withdrawn' ||
        !source.containsKey('decorationSlug') ||
        !source.containsKey('slotIndex') ||
        decorationSlug != null ||
        slotIndex != null ||
        joinedAtEpoch == null ||
        // A first active exhibit begins at revision one, so a public
        // withdrawal tombstone must advance it at least once more.
        revision < 2) {
      return null;
    }
    return GyeDedication(
      uid: uid,
      membershipId: membershipId,
      joinedAtEpoch: joinedAtEpoch,
      state: GyeDedicationState.withdrawn,
      decorationSlug: decorationSlug,
      slotIndex: slotIndex,
      revision: revision,
      lastOperationId: lastOperationId,
    );
  }

  static bool _isSafeIdentifier(String value) =>
      value.isNotEmpty &&
      value.length <= 128 &&
      value.trim() == value &&
      !value.contains('/');

  static bool _isSafeMembershipId(String value) =>
      value.length >= 16 &&
      value.length <= 64 &&
      value.trim() == value &&
      !value.contains('/');

  @override
  bool operator ==(Object other) =>
      other is GyeDedication &&
      other.uid == uid &&
      other.membershipId == membershipId &&
      other.joinedAtEpoch == joinedAtEpoch &&
      other.state == state &&
      other.decorationSlug == decorationSlug &&
      other.slotIndex == slotIndex &&
      other.revision == revision &&
      other.lastOperationId == lastOperationId;

  @override
  int get hashCode => Object.hash(
    uid,
    membershipId,
    joinedAtEpoch,
    state,
    decorationSlug,
    slotIndex,
    revision,
    lastOperationId,
  );
}

/// The only cosmetic items the P4b exhibit accepts. Keep this list aligned
/// with `kDecorationRewardPool`; the catalog test guards that contract.
const Set<String> kGyeDedicationSlugs = <String>{
  'decoration_chaekgado',
  'decoration_seoan',
  'decoration_munbangsau',
  'decoration_sagunja_maehwa',
  'decoration_soban',
  'decoration_gat_buchae',
  'decoration_sagunja_nan',
  'decoration_jagae_mungap',
  'decoration_pyeonaek',
  'decoration_sagunja_guk',
  'decoration_sagunja_juk',
};
