import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/a1_hanok_construction_catalog.dart';

void main() {
  group('A1 Hanok construction catalog', () {
    test(
      'fixes one cumulative visual state for every step from 0 through 16',
      () {
        expect(kA1HanokConstructionStates, hasLength(17));
        expect(
          kA1HanokConstructionStates.map((state) => state.step),
          orderedEquals(List<int>.generate(17, (index) => index)),
        );
        expect(
          kA1HanokConstructionStates.map((state) => state.id),
          orderedEquals(const [
            '00_empty_site',
            '01_site_setout',
            '02_plan_layout',
            '03_foundation_gidan',
            '04_cornerstones_choseok',
            '05_timber_preparation',
            '06_columns',
            '07_beams_changbang',
            '08_purlins_sangnyang',
            '09_rafters_roof_frame',
            '10_roof_base',
            '11_choga_roof',
            '12_wall_frame_sujang',
            '13_earth_walls',
            '14_ondol_maru',
            '15_changho_finish',
            '16_landscape_move_in',
          ]),
        );
        expect(kA1HanokConstructionStates.first.grantId, isNull);
        expect(
          kA1HanokConstructionStates.skip(1).map((state) => state.grantId),
          orderedEquals(const [
            'hanok_a1_01_site_setout',
            'hanok_a1_02_plan_layout',
            'hanok_a1_03_foundation_gidan',
            'hanok_a1_04_cornerstones_choseok',
            'hanok_a1_05_timber_preparation',
            'hanok_a1_06_columns',
            'hanok_a1_07_beams_changbang',
            'hanok_a1_08_purlins_sangnyang',
            'hanok_a1_09_rafters_roof_frame',
            'hanok_a1_10_roof_base',
            'hanok_a1_11_choga_roof',
            'hanok_a1_12_wall_frame_sujang',
            'hanok_a1_13_earth_walls',
            'hanok_a1_14_ondol_maru',
            'hanok_a1_15_changho_finish',
            'hanok_a1_16_landscape_move_in',
          ]),
        );
      },
    );

    test('keeps state zero on the approved base and 01-16 in one leaf', () {
      expect(
        kA1HanokConstructionStates.first.assetPath,
        'assets/illustrations/personal_hanok_v2/map/site_base_light.png',
      );
      for (final state in kA1HanokConstructionStates.skip(1)) {
        expect(
          state.assetPath,
          'assets/illustrations/personal_hanok_v2/a1/states/${state.id}.webp',
        );
      }
    });

    test('fails closed instead of clamping an impossible projection step', () {
      expect(() => a1HanokConstructionStateForStep(-1), throwsRangeError);
      expect(() => a1HanokConstructionStateForStep(17), throwsRangeError);
    });

    test('retains at most previous, current, and next under 32 MiB', () {
      expect(
        a1HanokDecodeWindowForStep(0).map((state) => state.step),
        orderedEquals([0, 1]),
      );
      expect(
        a1HanokDecodeWindowForStep(8).map((state) => state.step),
        orderedEquals([7, 8, 9]),
      );
      expect(
        a1HanokDecodeWindowForStep(16).map((state) => state.step),
        orderedEquals([15, 16]),
      );
      for (var step = 0; step <= 16; step += 1) {
        expect(
          a1HanokDecodeWindowBytesForStep(step),
          lessThanOrEqualTo(kA1HanokDecodedMemoryMaxBytes),
        );
      }
    });

    test('renderer source cannot import legacy or parallel progression', () {
      final source = File(
        'lib/widgets/sori/a1_hanok_construction_map.dart',
      ).readAsStringSync();
      for (final forbidden in const [
        'personal_hanok.dart',
        'hanok_stage_service.dart',
        'pack_progress_service.dart',
        'vocab_pack_service.dart',
        'LevelRatios',
        'Gye',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
      expect(source, contains('HanokExperienceProjection'));
      expect(source, contains('a1ConstructionStep'));
    });
  });
}
