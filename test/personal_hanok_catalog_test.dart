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
      expect(
        daecheong.isUnlocked(PersonalHanokMilestone.daecheongmaru),
        isTrue,
      );
      expect(sadang.isUnlocked(PersonalHanokMilestone.sadang), isTrue);
      expect(complete.isConstructionComplete, isTrue);
      expect(complete.isUnlocked(PersonalHanokMilestone.rearGarden), isTrue);
    });

    test(
      'does not skip prerequisite level completion for an inconsistent ratio',
      () {
        final projection = PersonalHanokProjection.from(
          const LevelRatios(a1: 1, a2: .99, b1: 1, b2: 1),
        );

        expect(projection.usesCompoundMap, isFalse);
        expect(projection.unlocked, isEmpty);
      },
    );

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

    test('keeps the pond and bridge in one final rear-garden composition', () {
      final garden = layerForMilestone(PersonalHanokMilestone.rearGarden);

      expect(garden.id, 'rear_garden');
      expect(garden.assetPath, endsWith('landscape/rear_garden.png'));
    });

    test('anchors every place target to its rendered construction layer', () {
      for (final definition in kPersonalHanokZones) {
        if (!definition.isInteractive) {
          continue;
        }
        final required = definition.requires;
        expect(required, isNotNull, reason: definition.zone.name);
        final painted = layerForMilestone(required!).visualBounds;
        expect(painted, isNotNull, reason: definition.zone.name);
        expect(
          definition.bounds.overlaps(painted!),
          isTrue,
          reason: '${definition.zone.name} bounds must track its art',
        );
        for (final target in definition.hitRegions) {
          expect(
            target.overlaps(painted),
            isTrue,
            reason: '${definition.zone.name} target must reach its art',
          );
        }
      }
    });

    test('defines a noninteractive Gye road without a personal milestone', () {
      final road = zoneFor(PersonalHanokZone.gyeRoad);

      expect(road.isInteractive, isFalse);
      expect(road.requires, isNull);
    });

    test('keeps interactive hit regions disjoint across places', () {
      final interactive = kPersonalHanokZones
          .where((definition) => definition.isInteractive)
          .toList(growable: false);

      for (var firstIndex = 0; firstIndex < interactive.length; firstIndex++) {
        for (
          var secondIndex = firstIndex + 1;
          secondIndex < interactive.length;
          secondIndex++
        ) {
          final first = interactive[firstIndex];
          final second = interactive[secondIndex];
          for (final firstRegion in first.hitRegions) {
            for (final secondRegion in second.hitRegions) {
              expect(
                firstRegion.overlaps(secondRegion),
                isFalse,
                reason:
                    '${first.zone.name} must not steal taps from '
                    '${second.zone.name}',
              );
            }
          }
        }
      }
    });
  });
}

PersonalHanokProjection _projection({double b1 = 0, double b2 = 0}) {
  return PersonalHanokProjection.from(
    LevelRatios(a1: 1, a2: 1, b1: b1, b2: b2),
  );
}
