import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gye.dart';
import 'auth_service.dart';
import 'gye_service.dart';
import 'storage_service.dart';

int uniqueActiveGyeMemberCount({
  required String currentUid,
  required Iterable<Iterable<GyeMember>> memberships,
}) {
  final unique = <String>{};
  for (final group in memberships) {
    for (final member in group) {
      if (member.uid != currentUid &&
          member.uid.isNotEmpty &&
          member.status == GyeMemberStatus.active) {
        unique.add(member.uid);
      }
    }
  }
  return unique.length;
}

typedef GyeIdsLoader = Future<List<String>> Function();
typedef GyeMembersLoader = Future<List<GyeMember>> Function(String gyeId);

class GyeMemberQuestResult {
  const GyeMemberQuestResult({
    required this.count,
    required this.verifiedOnline,
  });
  final int count;
  final bool verifiedOnline;
}

/// Refreshes the friend quest from authoritative active membership documents.
/// Only the deduplicated numeric result is persisted.
abstract final class GyeMemberQuestService {
  static Future<GyeMemberQuestResult> refreshOrCached({
    String? currentUid,
    GyeIdsLoader? loadGyeIds,
    GyeMembersLoader? loadMembers,
  }) async {
    final uid = currentUid ?? AuthService.current?.uid;
    if (uid == null || uid.isEmpty) {
      return GyeMemberQuestResult(
        count: Storage.gyeUniqueMemberCount,
        verifiedOnline: false,
      );
    }
    try {
      final ids = await (loadGyeIds ?? GyeService.myGyeIds)();
      final groups = <List<GyeMember>>[];
      for (final id in ids.toSet()) {
        groups.add(await (loadMembers ?? _loadMembers)(id));
      }
      final count = uniqueActiveGyeMemberCount(
        currentUid: uid,
        memberships: groups,
      );
      await Storage.setGyeUniqueMemberCount(count);
      return GyeMemberQuestResult(count: count, verifiedOnline: true);
    } catch (_) {
      return GyeMemberQuestResult(
        count: Storage.gyeUniqueMemberCount,
        verifiedOnline: false,
      );
    }
  }

  static Future<List<GyeMember>> _loadMembers(String gyeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('gye')
        .doc(gyeId)
        .collection('members')
        .get();
    return snapshot.docs
        .map((doc) => GyeMember.fromDoc(doc.id, doc.data()))
        .toList(growable: false);
  }
}
