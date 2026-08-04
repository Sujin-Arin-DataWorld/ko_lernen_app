import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_catalog.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';

void main() {
  group('PersonalHanokProjection', () {
    test('keeps the legacy courtyard before the B1 gate threshold', () {
      final projection = PersonalHanokProjection.from(
        const LevelRatios(a1: 1, a2: 1, b1: .249, b2: 1),
      );

      expect(projection.usesCompoundMap, isFalse);
      expect(projection.legacyStage, HanokStage.dancheong);
      expect(projection.unlocked, isEmpty);
    });

    test('unlocks the estate in the approved construction order', () {
      final gate = _projection(b1: .25);
      final haengrang = _projection(b1: .5);
      final sarangchae = _projection(b1: 1);
      final anchae = _projection(b1: 1, b2: .25);
      final daecheong = _projection(b1: 1, b2: .5);
      final sadang = _projection(b1: 1, b2: .75);
      final complete = _projection(b1: 1, b2: 1);

      expect(gate.unlocked, {PersonalHanokMilestone.sotdaeulmun});
      expect(
        haengrang.unlocked,
        containsAll(<PersonalHanokMilestone>[
          PersonalHanokMilestone.sotdaeulmun,
          PersonalHanokMilestone.haengrangchae,
        ]),
      );
      expect(sarangchae.isUnlocked(PersonalHanokMilestone.sarangchae), isTrue);
      expect(anchae.isUnlocked(PersonalHanokMilestone.anchae), isTrue);
      expect(daecheong.isUnlocked(PersonalHanokMilestone.daecheongmaru), isTrue);
      expect(sadang.isUnlocked(PersonalHanokMilestone.sadang), isTrue);
      expect(complete.isConstructionComplete, isTrue);
      expect(
        complete.isUnlocked(PersonalHanokMilestone.rearGarden),
        isTrue,
      );
    });

    test('does not skip prerequisite level completion for an inconsistent ratio', () {
      final projection = PersonalHanokProjection.from(
        const LevelRatios(a1: 1, a2: .99, b1: 1, b2: 1),
      );

      expect(projection.usesCompoundMap, isFalse);
      expect(projection.unlocked, isEmpty);
    });

    test('construction unlocks are monotonic for a valid learning path', () {
      final checkpoints = <PersonalHanokProjection>[
        _projection(b1: .25),
        _projection(b1: .5),
        _projection(b1: 1),
        _projection(b1: 1, b2: .25),
        _projection(b1: 1, b2: .5),
        _projection(b1: 1, b2: .75),
        _projection(b1: 1, b2: 1),
      ];

      for (var index = 1; index < checkpoints.length; index++) {
        expect(
          checkpoints[index].unlocked,
          containsAll(checkpoints[index - 1].unlocked),
        );
      }
    });
  });

  group('PersonalHanokCatalog', () {
    test('contains only the isolated personal-v2 art family', () {
      for (final layer in kPersonalHanokLayers) {
        expect(layer.assetPath, startsWith(kPersonalHanokAssetRoot));
        expect(layer.assetPath, isNot(contains('/gye/')));
        expect(layer.assetPath, isNot(contains('/hanok_compound/')));
      }
    });

    test('renders pond below bridge in the canonical layer order', () {
      final pond = layerForMilestone(PersonalHanokMilestone.rearPond);
      final bridge = layerForMilestone(PersonalHanokMilestone.rearBridge);

      expect(pond.zIndex, lessThan(bridge.zIndex));
    });

    test('defines a noninteractive Gye road without a personal milestone', () {
      final road = zoneFor(PersonalHanokZone.gyeRoad);

      expect(road.isInteractive, isFalse);
      expect(road.requires, isNull);
    });
  });
}

PersonalHanokProjection _projection({double b1 = 0, double b2 = 0}) {
  return PersonalHanokProjection.from(
    LevelRatios(a1: 1, a2: 1, b1: b1, b2: b2),
  );
}
