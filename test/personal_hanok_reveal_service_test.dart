import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/personal_hanok_reveal_service.dart';

void main() {
  group('PersonalHanokRevealPlan', () {
    test(
      'baselines existing completed estates instead of replaying history',
      () {
        final plan = PersonalHanokRevealPlan.forProjection(
          projection: _projection(b1: 1, b2: 1),
          snapshot: const PersonalHanokRevealSnapshot.uninitialized(),
        );

        expect(plan.shouldInitialize, isTrue);
        expect(
          plan.milestonesToPersist,
          orderedEquals(kPersonalHanokMilestoneOrder),
        );
        expect(plan.reveals, isEmpty);
      },
    );

    test('queues only the newly unlocked milestones in construction order', () {
      final plan = PersonalHanokRevealPlan.forProjection(
        projection: _projection(b1: 1, b2: 1),
        snapshot: const PersonalHanokRevealSnapshot.initialized({
          PersonalHanokMilestone.sotdaeulmun,
          PersonalHanokMilestone.haengrangchae,
        }),
      );

      expect(plan.shouldInitialize, isFalse);
      expect(plan.milestonesToPersist, isEmpty);
      expect(
        plan.reveals,
        orderedEquals(const <PersonalHanokMilestone>[
          PersonalHanokMilestone.sarangchae,
          PersonalHanokMilestone.anchae,
          PersonalHanokMilestone.daecheongmaru,
          PersonalHanokMilestone.sadang,
          PersonalHanokMilestone.rearGarden,
        ]),
      );
    });

    test('never tries to reveal a milestone that is not in the projection', () {
      final plan = PersonalHanokRevealPlan.forProjection(
        projection: _projection(b1: .5),
        snapshot: const PersonalHanokRevealSnapshot.initialized({}),
      );

      expect(
        plan.reveals,
        orderedEquals(const <PersonalHanokMilestone>[
          PersonalHanokMilestone.sotdaeulmun,
          PersonalHanokMilestone.haengrangchae,
        ]),
      );
    });
  });
}

PersonalHanokProjection _projection({required double b1, double b2 = 0}) =>
    PersonalHanokProjection.from(LevelRatios(a1: 1, a2: 1, b1: b1, b2: b2));
