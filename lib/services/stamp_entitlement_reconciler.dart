import '../models/pack_progress.dart';
import '../widgets/sori/dancheong_stamp.dart';
import 'storage_service.dart';

class StampReconciliationResult {
  const StampReconciliationResult({
    required this.addedSlugs,
    required this.skippedQuarantinedProgress,
  });

  final List<String> addedSlugs;
  final bool skippedQuarantinedProgress;

  int get addedCount => addedSlugs.length;
}

/// 완료 팩에서 현재 도장 자격을 다시 계산하는 추가형·멱등형 보정기.
///
/// 기존 획득값은 절대 제거하지 않는다. 손상 진행도가 격리된 실행에서는 완료
/// 여부를 추측하지 않고, 저장된 도장 목록을 그대로 둔다.
class StampEntitlementReconciler {
  StampEntitlementReconciler._();

  static Future<StampReconciliationResult> reconcile({
    required Map<String, PackProgress> progress,
    Iterable<String>? existingSlugs,
    Future<void> Function(String slug)? persistSlug,
    bool? progressIsQuarantined,
  }) async {
    final quarantined =
        progressIsQuarantined ?? Storage.packProgressIsQuarantined;
    if (quarantined) {
      return const StampReconciliationResult(
        addedSlugs: [],
        skippedQuarantinedProgress: true,
      );
    }

    final earned = (existingSlugs ?? Storage.earnedStamps).toSet();
    final completed = progress.values.where((item) => item.isCleared).toList()
      ..sort((a, b) => a.packId.compareTo(b.packId));
    final added = <String>[];
    for (final item in completed) {
      final slug = motifForPackId(item.packId).spec.slug;
      if (earned.add(slug)) {
        added.add(slug);
        await (persistSlug ?? Storage.addEarnedStamp)(slug);
      }
    }
    return StampReconciliationResult(
      addedSlugs: List.unmodifiable(added),
      skippedQuarantinedProgress: false,
    );
  }
}
