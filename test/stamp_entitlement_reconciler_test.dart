import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/stamp_entitlement_reconciler.dart';

PackProgress _cleared(String packId) => PackProgress(
  packId: packId,
  level: 'A2',
  status: PackStatus.cleared,
  wordsLearned: 10,
  wordsTotal: 10,
  bossAccuracy: 1,
  attempts: 1,
  clearedAtIso: '2026-08-25T00:00:00Z',
);

void main() {
  test(
    'preserves existing stamps and adds only current entitlements',
    () async {
      final earned = <String>{'lotus'};
      final progress = <String, PackProgress>{
        'a2_education': _cleared('a2_education'),
        'a2_bank_counter': _cleared('a2_bank_counter'),
        'a1_food': _cleared('a1_food'),
      };

      final first = await StampEntitlementReconciler.reconcile(
        progress: progress,
        existingSlugs: earned,
        persistSlug: (slug) async => earned.add(slug),
        progressIsQuarantined: false,
      );
      expect(
        first.addedSlugs,
        containsAll(['munbangsau', 'yeopjeon', 'soban']),
      );
      expect(earned, contains('lotus'));

      final second = await StampEntitlementReconciler.reconcile(
        progress: progress,
        existingSlugs: earned,
        persistSlug: (slug) async => earned.add(slug),
        progressIsQuarantined: false,
      );
      expect(second.addedSlugs, isEmpty);
    },
  );

  test('quarantined progress never guesses an entitlement', () async {
    final persisted = <String>[];
    final result = await StampEntitlementReconciler.reconcile(
      progress: {'a2_education': _cleared('a2_education')},
      existingSlugs: const ['lotus'],
      persistSlug: (slug) async => persisted.add(slug),
      progressIsQuarantined: true,
    );
    expect(result.skippedQuarantinedProgress, isTrue);
    expect(result.addedSlugs, isEmpty);
    expect(persisted, isEmpty);
  });
}
