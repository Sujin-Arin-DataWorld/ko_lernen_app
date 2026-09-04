import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §LAYOUT-4(J14) — `docs/screenshots/` is UI-root visual evidence, not a
/// CI comparison gate (see `test/sori_stage_visual_evidence_test.dart` and
/// AGENTS.md's "UI 루트 증거" bullet). This is a lightweight directory scan,
/// not a golden-file diff: it only confirms each captured root still has at
/// least one non-empty PNG on disk with the
/// `sori-stage-<root>-<width>[-<state>].png` naming convention, so a
/// careless rename/delete can't silently drop a root's evidence from the
/// repository.
///
/// `games` (the catalog's other tab) shares the same pipeline and naming
/// convention as `today`/`learn`/`hanok`/`gye` but has no dedicated capture
/// in this PR — the brief's evidence count is exactly 7 PNGs across those
/// four roots (today x1, learn x2, hanok x2, gye x2); adding an 8th `games`
/// PNG would contradict that count. `games` stays in [roots] for naming
/// validation but is intentionally excluded from [requiredRoots] rather
/// than silently expected and always failing.
void main() {
  test(
    'every captured UI root has at least one non-empty evidence PNG on disk',
    () {
      final directory = Directory('docs/screenshots');
      expect(
        directory.existsSync(),
        isTrue,
        reason: '${directory.path} is missing.',
      );

      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.png'))
          .toList();

      const roots = ['today', 'learn', 'games', 'hanok', 'gye'];
      const requiredRoots = ['today', 'learn', 'hanok', 'gye'];
      final namePattern = RegExp(
        r'^sori-stage-(today|learn|games|hanok|gye)-\d+(-[a-z]+)?\.png$',
      );

      final byRoot = <String, List<File>>{for (final root in roots) root: []};
      final malformed = <String>[];

      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final match = namePattern.firstMatch(name);
        if (match == null) {
          malformed.add(name);
          continue;
        }
        byRoot[match.group(1)!]!.add(file);
      }

      expect(
        malformed,
        isEmpty,
        reason:
            "These docs/screenshots/*.png files don't follow the "
            '`sori-stage-<root>-<width>[-<state>].png` naming convention: '
            '${malformed.join(', ')}',
      );

      final missingRoots = <String>[];
      final emptyFiles = <String>[];
      for (final root in requiredRoots) {
        final rootFiles = byRoot[root]!;
        if (rootFiles.isEmpty) {
          missingRoots.add(root);
          continue;
        }
        for (final file in rootFiles) {
          if (file.lengthSync() == 0) {
            emptyFiles.add(file.path);
          }
        }
      }
      // `games` has no required capture (see doc comment above), but any PNG
      // that does exist under that name still gets the empty-file check.
      for (final file in byRoot['games']!) {
        if (file.lengthSync() == 0) {
          emptyFiles.add(file.path);
        }
      }

      expect(
        missingRoots,
        isEmpty,
        reason:
            'These UI roots have no docs/screenshots/*.png evidence: '
            '${missingRoots.join(', ')}',
      );
      expect(
        emptyFiles,
        isEmpty,
        reason: 'These evidence PNGs are 0 bytes: ${emptyFiles.join(', ')}',
      );
    },
  );
}
