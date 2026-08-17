import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/a1_hanok_construction_catalog.dart';

void main() {
  test('locks the 17 cumulative A1 states and approved grant IDs', () {
    expect(kA1HanokConstructionStates, hasLength(17));
    expect(kA1HanokConstructionStates.first.id, '00_empty_site');
    expect(
      kA1HanokConstructionStates.first.assetPath,
      kA1HanokEmptySiteAsset,
    );
    expect(kA1HanokConstructionStates.first.grantId, isNull);
    expect(kA1HanokConstructionStates.last.id, '16_landscape_move_in');

    const grants = [
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
    ];
    for (var step = 1; step <= 16; step++) {
      final state = a1HanokConstructionState(step);
      expect(state.step, step);
      expect(state.grantId, grants[step - 1]);
      expect(state.revealAssetId, 'hanok_a1_state_${state.id}');
      expect(state.assetPath, startsWith(kA1HanokRuntimeStateRoot));
      expect(state.fileName, endsWith('.webp'));
    }
  });

  test('keeps the decode window at previous/current/next only', () {
    expect(a1HanokResidentSteps(0), [0, 1]);
    expect(a1HanokResidentSteps(8), [7, 8, 9]);
    expect(a1HanokResidentSteps(16), [15, 16]);
    expect(a1HanokResidentSteps(6), hasLength(lessThanOrEqualTo(3)));
    expect(
      a1HanokWorstCaseResidentBytes(),
      lessThanOrEqualTo(kA1HanokDecodedMemoryMaxBytes),
    );
    expect(a1HanokWorstCaseResidentBytes(), 21233664);
  });

  test('caps decode hints at the 1536 master width and fail-closes range', () {
    expect(
      a1HanokDecodeCacheWidth(displayWidth: 390, devicePixelRatio: 2),
      780,
    );
    expect(
      a1HanokDecodeCacheWidth(displayWidth: 1024, devicePixelRatio: 3),
      kA1HanokCanvasWidth,
    );
    expect(
      a1HanokDecodeCacheWidth(displayWidth: 600, devicePixelRatio: 1),
      600,
    );
    expect(
      () => a1HanokConstructionState(-1),
      throwsRangeError,
    );
    expect(
      () => a1HanokConstructionState(17),
      throwsRangeError,
    );
    expect(
      () => a1HanokResidentSteps(17),
      throwsRangeError,
    );
  });

  test('eviction targets cover non-resident catalog and stale resident widths', () {
    final targets = a1HanokEvictionTargets(
      currentStep: 8,
      seenCacheWidths: {600, 780},
      currentCacheWidth: 780,
    );
    final residents = {
      for (final step in a1HanokResidentSteps(8))
        a1HanokConstructionState(step).assetPath,
    };
    final catalog = [
      for (final state in kA1HanokConstructionStates) state.assetPath,
    ];
    final nonResidents = catalog.where((path) => !residents.contains(path)).toList();
    expect(residents, hasLength(3));
    expect(nonResidents, hasLength(14));
    expect(targets, hasLength(14 * 3 + 3));

    final raw = targets.whereType<AssetImage>().map((p) => p.assetName).toSet();
    expect(raw, unorderedEquals(nonResidents));
    expect(raw.intersection(residents), isEmpty);

    for (final path in nonResidents) {
      expect(
        targets.whereType<ResizeImage>().where((provider) {
          final inner = provider.imageProvider;
          return inner is AssetImage &&
              inner.assetName == path &&
              (provider.width == 600 || provider.width == 780);
        }),
        hasLength(2),
      );
    }
    for (final path in residents) {
      final stale = targets.whereType<ResizeImage>().where((provider) {
        final inner = provider.imageProvider;
        return inner is AssetImage && inner.assetName == path;
      }).toList();
      expect(stale, hasLength(1));
      expect(stale.single.width, 600);
    }
  });

  test('catalog and renderer stay free of pack, XP, Gye, and legacy authority', () {
    const paths = [
      'lib/data/a1_hanok_construction_catalog.dart',
      'lib/widgets/sori/a1_hanok_construction_map.dart',
    ];
    final forbiddenImport = RegExp(
      r'''import ['"][^'"]*(personal_hanok_catalog|personal_hanok_map|hanok_stage|pack_progress|gye_|level_ratios|course_mastery|vocab_pack)''',
      caseSensitive: false,
    );
    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(forbiddenImport.hasMatch(source), isFalse, reason: path);
    }
  });
}
