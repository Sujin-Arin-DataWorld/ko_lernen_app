import 'package:flutter/foundation.dart';

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
    required this.decorationSlug,
    required this.slotIndex,
    required this.revision,
    required this.lastOperationId,
  });

  final String uid;
  final String membershipId;
  final String decorationSlug;
  final int slotIndex;
  final int revision;
  final String lastOperationId;

  /// Parses only a complete, current wire shape. Bad remote data never makes
  /// its way into a shared visual layer.
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
        decorationSlug is! String ||
        slotIndex is! int ||
        revision is! int ||
        lastOperationId is! String ||
        uid != documentId ||
        !_isSafeIdentifier(uid) ||
        !_isSafeIdentifier(membershipId) ||
        !_isSafeIdentifier(lastOperationId) ||
        !kGyeDedicationSlugs.contains(decorationSlug) ||
        slotIndex < 0 ||
        slotIndex >= maxSlots ||
        // A public document exists only for an active exhibit. Revision zero
        // is reserved for the absent-document compare-and-set state used
        // after withdrawal, so accepting it here would fabricate an exhibit.
        revision < 1) {
      return null;
    }
    return GyeDedication(
      uid: uid,
      membershipId: membershipId,
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

  @override
  bool operator ==(Object other) =>
      other is GyeDedication &&
      other.uid == uid &&
      other.membershipId == membershipId &&
      other.decorationSlug == decorationSlug &&
      other.slotIndex == slotIndex &&
      other.revision == revision &&
      other.lastOperationId == lastOperationId;

  @override
  int get hashCode => Object.hash(
    uid,
    membershipId,
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
