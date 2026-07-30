// Phase 3 (stately-rising-jongga) — HanokStage / computeStage boundary tests.
//
// Pinst die 12 Stage-Übergänge an die korrekten Prozent-Cutoffs aus Plan §5.1.
// Falls jemand die Cutoffs nachher ändert (z.B. dancheong = A2 100% statt B1 0%),
// schlägt der jeweilige Test sofort fehl und dokumentiert die Absicht.

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/hanok_stage.dart';

void main() {
  group('computeStage — A1 phase', () {
    test('A1 < 25% → empty', () {
      expect(_compute(a1: 0.0), HanokStage.empty);
      expect(_compute(a1: 0.10), HanokStage.empty);
      expect(_compute(a1: 0.249), HanokStage.empty);
    });

    test('A1 25-50% → foundation', () {
      expect(_compute(a1: 0.25), HanokStage.foundation);
      expect(_compute(a1: 0.40), HanokStage.foundation);
      expect(_compute(a1: 0.499), HanokStage.foundation);
    });

    test('A1 50-75% → pillars', () {
      expect(_compute(a1: 0.50), HanokStage.pillars);
      expect(_compute(a1: 0.65), HanokStage.pillars);
      expect(_compute(a1: 0.749), HanokStage.pillars);
    });

    test('A1 75-99% → beams', () {
      expect(_compute(a1: 0.75), HanokStage.beams);
      expect(_compute(a1: 0.85), HanokStage.beams);
      expect(_compute(a1: 0.999), HanokStage.beams);
    });
  });

  group('computeStage — A2 phase (A1 = 100%)', () {
    test('A2 < 25% → thatchRoof', () {
      expect(_compute(a1: 1.0, a2: 0.0), HanokStage.thatchRoof);
      expect(_compute(a1: 1.0, a2: 0.249), HanokStage.thatchRoof);
    });

    test('A2 25-75% → tileRoofPartial', () {
      expect(_compute(a1: 1.0, a2: 0.25), HanokStage.tileRoofPartial);
      expect(_compute(a1: 1.0, a2: 0.50), HanokStage.tileRoofPartial);
      expect(_compute(a1: 1.0, a2: 0.749), HanokStage.tileRoofPartial);
    });

    test('A2 75-99% → tileRoofComplete', () {
      expect(_compute(a1: 1.0, a2: 0.75), HanokStage.tileRoofComplete);
      expect(_compute(a1: 1.0, a2: 0.99), HanokStage.tileRoofComplete);
    });
  });

  group('computeStage — B1 phase (A2 = 100%)', () {
    test('B1 < 25% → dancheong', () {
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.0),
        HanokStage.dancheong,
      );
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.249),
        HanokStage.dancheong,
      );
    });

    test('B1 25-50% → gate', () {
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.25),
        HanokStage.gate,
      );
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.499),
        HanokStage.gate,
      );
    });

    test('B1 50-99% → windows', () {
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.5),
        HanokStage.windows,
      );
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 0.99),
        HanokStage.windows,
      );
    });
  });

  group('computeStage — B2 phase (B1 = 100%)', () {
    test('B2 < 50% → sideBuilding', () {
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 1.0, b2: 0.0),
        HanokStage.sideBuilding,
      );
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 1.0, b2: 0.49),
        HanokStage.sideBuilding,
      );
    });

    test('B2 50-100% → jongga', () {
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 1.0, b2: 0.5),
        HanokStage.jongga,
      );
      expect(
        _compute(a1: 1.0, a2: 1.0, b1: 1.0, b2: 1.0),
        HanokStage.jongga,
      );
    });
  });

  group('computeStage — cascade semantics', () {
    test('A1 incomplete blocks higher stages even if A2 high', () {
      // User skipped ahead to A2 (50%) but A1 not done → still in A1-phase.
      final stage = _compute(a1: 0.80, a2: 0.50, b1: 0.30, b2: 0.0);
      expect(stage, HanokStage.beams);
    });

    test('A2 incomplete blocks B1', () {
      final stage = _compute(a1: 1.0, a2: 0.80, b1: 0.99);
      expect(stage, HanokStage.tileRoofComplete);
    });

    test('out-of-range inputs clamp safely', () {
      expect(_compute(a1: -0.5), HanokStage.empty);
      expect(_compute(a1: 1.5), HanokStage.thatchRoof);
      expect(
        _compute(a1: 2.0, a2: 2.0, b1: 2.0, b2: 2.0),
        HanokStage.jongga,
      );
    });
  });

  group('HanokStage enum helpers', () {
    test('assetSlug stable across all stages', () {
      const expected = {
        HanokStage.empty: 'empty',
        HanokStage.foundation: 'foundation',
        HanokStage.pillars: 'pillars',
        HanokStage.beams: 'beams',
        HanokStage.thatchRoof: 'thatch',
        HanokStage.tileRoofPartial: 'tile_partial',
        HanokStage.tileRoofComplete: 'tile_complete',
        HanokStage.dancheong: 'dancheong',
        HanokStage.gate: 'gate',
        HanokStage.windows: 'windows',
        // stage_sidebuilding_light.png 실파일명과 일치 (구 'side_building'은 404 오타).
        HanokStage.sideBuilding: 'sidebuilding',
        HanokStage.jongga: 'jongga',
      };
      for (final entry in expected.entries) {
        expect(entry.key.assetSlug, entry.value);
      }
    });

    test('ordinal increases monotonically', () {
      for (var i = 1; i < HanokStage.values.length; i++) {
        expect(
          HanokStage.values[i].ordinal,
          greaterThan(HanokStage.values[i - 1].ordinal),
        );
      }
    });

    test('toJsonValue / fromJsonValue round-trip', () {
      for (final s in HanokStage.values) {
        expect(HanokStage.fromJsonValue(s.toJsonValue()), s);
      }
    });

    test('fromJsonValue with unknown → empty (safe default)', () {
      expect(HanokStage.fromJsonValue('garbage'), HanokStage.empty);
      expect(HanokStage.fromJsonValue(null), HanokStage.empty);
    });
  });
}

HanokStage _compute({
  double a1 = 0.0,
  double a2 = 0.0,
  double b1 = 0.0,
  double b2 = 0.0,
}) =>
    computeStage(a1Ratio: a1, a2Ratio: a2, b1Ratio: b1, b2Ratio: b2);
