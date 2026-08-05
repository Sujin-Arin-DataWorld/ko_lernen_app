import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
  });

  test(
    'baselines the local construction ledger once and keeps its order',
    () async {
      expect(
        Storage.personalHanokMilestoneRevealSnapshot.isInitialized,
        isFalse,
      );

      await Storage.initializePersonalHanokMilestoneReveals(<String>[
        'sotdaeulmun',
        'haengrangchae',
        'sotdaeulmun',
      ]);

      final baseline = Storage.personalHanokMilestoneRevealSnapshot;
      expect(baseline.isInitialized, isTrue);
      expect(baseline.seen, <String>['sotdaeulmun', 'haengrangchae']);

      // An existing learner must not have the quiet first-visit baseline
      // overwritten by a later projection.
      await Storage.initializePersonalHanokMilestoneReveals(<String>[
        'sarangchae',
      ]);
      expect(Storage.personalHanokMilestoneRevealSnapshot.seen, <String>[
        'sotdaeulmun',
        'haengrangchae',
      ]);
    },
  );

  test('records a newly viewed construction layer idempotently', () async {
    await Storage.markPersonalHanokMilestoneRevealSeen('anchae');
    await Storage.markPersonalHanokMilestoneRevealSeen('anchae');
    await Storage.markPersonalHanokMilestoneRevealSeen('rearGarden');

    final afterReveal = Storage.personalHanokMilestoneRevealSnapshot;
    expect(afterReveal.isInitialized, isTrue);
    expect(afterReveal.seen, <String>['anchae', 'rearGarden']);
  });
}
