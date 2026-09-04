import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §MOTION-2(J6) — `SoriPulse` is an idle, infinitely-repeating animation
/// once active (`lib/widgets/sori/motion.dart`), so `pumpAndSettle()` on any
/// test that can render one hangs or times out. This is an explicit
/// file-list ratchet (not an import heuristic) over the known sites that
/// render `SoriStageCatalogScreen(`/`SoriStageShell(` and can therefore host
/// an active continue-hero pulse — each must use
/// `test/support/sori_stage_pump.dart`'s `pumpSoriStage`/`pumpUntilFound`
/// instead of `tester.pumpAndSettle()`.
void main() {
  const trackedFiles = <String, String>{
    'continue_hero': 'test/sori_stage_catalog_continue_hero_test.dart',
    'reward_flow': 'test/sori_stage_catalog_reward_flow_test.dart',
    'lazy_load': 'test/sori_stage_catalog_lazy_load_test.dart',
    'visual_evidence': 'test/sori_stage_visual_evidence_test.dart',
    'shell_test': 'test/sori_stage_shell_test.dart',
    'responsive_accessibility':
        'test/sori_stage_responsive_accessibility_test.dart',
    'cell_aspect_ratio_cache':
        'test/sori_stage_cell_aspect_ratio_cache_test.dart',
    'ux_preview_app': 'test/ux_preview_app_test.dart',
    // §LAYOUT-1(J10)/§LAYOUT-2(J12): new catalog-rendering guards.
    'catalog_header_gap': 'test/sori_stage_catalog_header_gap_test.dart',
    'illustrated_card_overflow_guard':
        'test/illustrated_card_overflow_guard_test.dart',
  };

  const ceilings = <String, int>{
    'continue_hero': 0,
    'reward_flow': 0,
    'lazy_load': 0,
    // §LAYOUT-4(J14): SoriStageHanokScreen has no SoriPulse (that's a
    // catalog continue-hero-only widget) — its post-drag settle after
    // `tester.drag(CustomScrollView, ...)` is the same proven-safe
    // `pumpAndSettle()` `sori_stage_hanok_fold_test.dart` already uses for
    // an identical 600dp drag. This 1 site is that drag-settle, not a
    // latent SoriPulse hang.
    'visual_evidence': 1,
    'shell_test': 0,
    'responsive_accessibility': 0,
    'cell_aspect_ratio_cache': 0,
    // ux_preview_app_test.dart doesn't construct SoriStageCatalogScreen(/
    // SoriStageShell( directly (outside the auto-detect rule below) — it's
    // tracked anyway because a dev-preview screen can still embed one
    // indirectly. Its 2 existing pumpAndSettle() sites are a latent risk,
    // not a live bug today; converting them is optional (measured, not 0).
    'ux_preview_app': 2,
    'catalog_header_gap': 0,
    'illustrated_card_overflow_guard': 0,
  };

  test('tracked SoriStage screens keep pumpAndSettle() at or below their ceiling', () {
    final failures = <String>[];
    for (final entry in trackedFiles.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) {
        failures.add('${entry.value}: file missing');
        continue;
      }
      final clean = _blankStringsAndComments(file.readAsStringSync());
      final count = 'pumpAndSettle('.allMatches(clean).length;
      final ceiling = ceilings[entry.key]!;
      if (count > ceiling) {
        failures.add(
          '${entry.value}: $count pumpAndSettle( calls (ceiling $ceiling) — '
          'use test/support/sori_stage_pump.dart (pumpSoriStage/'
          'pumpUntilFound) instead; an active SoriPulse never settles.',
        );
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test(
    'every test file that renders SoriStageCatalogScreen(/SoriStageShell( is tracked',
    () {
      final tracked = trackedFiles.values.toSet();
      final untracked = <String>[];
      for (final file
          in Directory('test')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final path = _relativePath(file);
        final clean = _blankStringsAndComments(file.readAsStringSync());
        final rendersTrackedScreen =
            clean.contains('SoriStageCatalogScreen(') ||
            clean.contains('SoriStageShell(');
        if (rendersTrackedScreen && !tracked.contains(path)) {
          untracked.add(path);
        }
      }

      expect(
        untracked,
        isEmpty,
        reason:
            'New file(s) render SoriStageCatalogScreen(/SoriStageShell( '
            'without being added to this guard\'s trackedFiles map — add '
            'them so an untracked file can\'t reintroduce a hanging '
            'pumpAndSettle().\n${untracked.join('\n')}',
      );
    },
  );
}

String _relativePath(File file) => file.path.replaceAll('\\', '/');

String _blankStringsAndComments(String source) {
  final output = source.split('');
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      final limit = end < 0 ? source.length : end;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final end = source.indexOf('*/', index + 2);
      final limit = end < 0 ? source.length : end + 2;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    final quote = source[index];
    if (quote == "'" || quote == '"') {
      var cursor = index + 1;
      while (cursor < source.length) {
        if (source[cursor] == r'\') {
          cursor += 2;
          continue;
        }
        if (source[cursor] == quote) {
          cursor++;
          break;
        }
        cursor++;
      }
      for (var blank = index; blank < cursor; blank++) {
        output[blank] = ' ';
      }
      index = cursor;
      continue;
    }
    index++;
  }
  return output.join();
}
